#include <xc.inc>

global ADC_Setup, ADC_Read, Right_Shift, Read_Sensors
global Final_Moisture_H, Final_Moisture_L, Final_Temp_H, Final_Temp_L, Final_Light_H, Final_Light_L    
    
psect	adc_code, class=CODE
    
; these are data allocations for the sensor results + converted results
psect	sensor_data, class=RAM
Moisture_H: ds 1    ; have to split into low and high byte of the result - cause it's a 12 bit value
Moisture_L: ds 1
Thermistor_H:	ds 1
Thermistor_L:	ds 1
Photodiode_H:	ds 1
Photodiode_L:	ds 1
Final_Temp_H:	ds 1	; stores converted result (high byte)
Final_Temp_L:	ds 1	; stores converted result (low byte)
Final_Moisture_H:   ds 1
Final_Moisture_L:   ds 1
Final_Light_H:	ds 1
Final_Light_L:	ds 1
Temp_Reg_H: ds 1    ; temp values
Temp_Reg_L: ds 1
ADC_Result_H:	ds 1	; for values from ADRESH and ADRESL
ADC_Result_L:	ds 1  
shift_n:    ds 1
   
ADC_Setup:
    bcf	ANSEL0	; ANSEL0 set AN0 to analog
    bcf	ANSEL1  ; ANSEL1 set AN1 to analog
    bcf	ANSEL2  ; ANSEL2 set AN2 to analog
    bsf	TRISA, PORTA_RA0_POSN, A    ; pin RA0==AN0 input
    bsf	TRISA, PORTA_RA1_POSN, A    ; AN1 set as input
    bsf	TRISA, PORTA_RA2_POSN, A    ; AN2 set as input
    
    movlw   0x30	; sets V_Ref to 4.096V (11)
    movwf   ADCON1, A ; sets -ve V_Ref to 0V
    movlw   0xF6	; configure ADCON2 for acquisition time and conversion clock (right justfied output)
    movwf   ADCON2, A ; Fosc/64 clock and acquisition times

    ;bsf??ADCON0, 0 ; turns ADON bit to 0 which means the converter is operating
    return
    
Select_Channel:
    andlw   0XC3    ; clears the bits in the channel (1100 0011) --> these are the channel select bits, so prepares to set a new channel	
    iorlw   WREG
    movwf   ADCON0, A	; gets specific channel config
    bsf	ADCON0, 0, A   ; sets ADON bit 0 to 1 which makes sure ADC is on
    return
	
ADC_Read:
    bsf	GO  ; Start conversion by setting GO bit in ADCON0
adc_loop:
    btfsc   GO	; check to see if finished
    bra	adc_loop

    movff   ADRESH, ADC_Result_H
    movff   ADRESL, ADC_Result_L
    return

Read_Sensors:
    movlw 0x01    ; AN0 channel
    call    Select_Channel
    call    ADC_Read
    movff   ADC_Result_H, Thermistor_H	; stores the high byte
    movff   ADC_Result_L, Thermistor_L	; stores the low byte

    movlw   0x05    ; AN1 channel
    call    Select_Channel
    call    ADC_Read
    movff   ADC_Result_H, Photodiode_H
    movff   ADC_Result_L, Photodiode_L

    movlw   0x09    ; AN2 channel
    call    Select_Channel
    call    ADC_Read
    movff   ADC_Result_H, Moisture_H
    movff   ADC_Result_L, Moisture_L
    return

Right_Shift:
    ; dividing by 2^n --> for temperature n=12, for moisture n=
    movwf   shift_n, A ; move the shift count into reg
shift_loop:
    bcf	STATUS, 0, A
    rrcf    Temp_Reg_H, 1   ; shift the high byte
    rrcf    Temp_Reg_L, 1   ; shift low byte
    decfsz  shift_n, F, A	; decrement shift count
    bra	shift_loop  ; repeat until shift count = 0
    return
	
    
psect	udata
mul_10_H:   ds 1
mul_10_L:   ds 1
remainder_H:	ds 1
remainder_L:	ds 1
compare_H:  ds 1
compare_L:  ds 1
temp_scaled_H:	ds 1
temp_scaled_L:	ds 1
loop_count: ds 1
Temp_Result_H:	ds 1
Temp_Result_L:	ds 1
loop_counter_H:	ds 1
loop_counter_L:	ds 1
    
Constants:
    movlw   0x6A    ; high byte of 27040
    movwf   Temp_Result_H
    movlw   0x10    ; low byte of 27040
    movwf   Temp_Result_L
    
    return
     
Load_ADC_Temperature_Results:
    movf    Thermistor_H, W
    movwf   Temp_Reg_H
    movf    Thermistor_L, W
    movlw   Temp_Reg_L
    
    clrf    mul_10_H	; intialise to 0
    clrf    mul_10_L
    
    movlw   0x0A    ; loop to add ADC result 10 times (multiplying by 10)
    movwf   loop_count
 
Multiply_Loop:
    movf    Temp_Reg_L, W
    addwf   mul_10_L, F
    movf    Temp_Reg_H, W
    addwfc  mul_10_H, F
    decfsz  loop_count, F
    goto    Multiply_Loop
    
    return
 
Subtract:
    movf    mul_10_L, W	; 27040 - ADC(10)
    subwf   Temp_Result_L, F
    movf    mul_10_H, W
    subwf   Temp_Result_H, F
    
    movf    Temp_Result_H, W
    movwf   remainder_H
    movf    Temp_Result_L, W
    movwf   remainder_L
    
    return
    
Divide_528:
    clrf    temp_scaled_H
    clrf    temp_scaled_L
    
    clrf    loop_counter_H
    clrf    loop_counter_L
    
Divide_Loop:
    movlw   0x02    ; HIGH BYTE of 528
    movwf   compare_H
    movlw   0x10    ; LOW BYTE of 528
    movwf   compare_L
    
    movf    remainder_L, W  ; compare if the remainder >= 528
    sublw   compare_L
    btfss   STATUS, 0	; if no difference then division has no remainder
    goto    Divide_No_Subtract
    
    movlw   0x02
    subwf   remainder_H, F  ; subtract 528 from remainder
    movlw   0x10
    subwf   remainder_L, F
    
    incf    temp_scaled_L, F
    movlw   0x00
    subwf   temp_scaled_H, W
    btfsc   STATUS, 0
    incf    temp_scaled_H, F
    
    goto    Divide_Loop
    
Divide_No_Subtract:
    movf    temp_scaled_H, W
    movwf   Final_Temp_H
    movf    temp_scaled_L, W
    movwf   Final_Temp_L
    
    return 
  
 
Convert_Moisture:
    movf    Moisture_H, W	; load high byte
    movwf   Temp_Reg_H	; store in Temp_Reg_H
    movf    Moisture_L, W          
    movwf   Temp_Reg_L            

    movlw   5		;move 100 into W reg
    mulwf   Temp_Reg_H	; multiply ADC value by 100
    movlw   5
    mulwf   Temp_Reg_L

    movlw   7	; divide by 2^12
    call    Right_Shift

    movlw   34
    addwf   Temp_Reg_H
    movlw   34
    addwf   Temp_Reg_L

    movf    Temp_Reg_L, W
    movwf   Final_Moisture_L
    movf    Temp_Reg_H, W
    movwf   Final_Moisture_H	; stores as percentage

    return

Convert_Photodiode:
    movf    Photodiode_H, W ; load high byte
    movwf   Temp_Reg_H	; store in Temp_Reg_H
    movf    Photodiode_L, W          
    movwf   Temp_Reg_L            

    movlw   3	; move 100 into W reg
    mulwf   Temp_Reg_H	; multiply ADC value by 100
    movlw   3
    mulwf   Temp_Reg_L

    movf    Temp_Reg_L, W
    movwf   Final_Light_L
    movf    Temp_Reg_H, W
    movwf   Final_Light_H   ; stores as percentage

    return
   
end
