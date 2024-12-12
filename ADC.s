;#include <xc.inc>
;
;global ADC_Setup, ADC_Read, Right_Shift 
;global Final_Moisture_H, Final_Moisture_L, Final_Temp_H, Final_Temp_L, Final_Light_H, Final_Light_L    
;    
;psect	adc_code, class=CODE
;    
;; these are data allocations for the sensor results + converted results
;psect	sensor_data, class=RAM
;Moisture_H: ds 1    ; have to split into low and high byte of the result - cause it's a 12 bit value
;Moisture_L: ds 1
;Thermistor_H:	ds 1
;Thermistor_L:	ds 1
;Photodiode_H:	ds 1
;Photodiode_L:	ds 1
;Final_Temp_H:	ds 1	; stores converted result (high byte)
;Final_Temp_L:	ds 1	; stores converted result (low byte)
;Final_Moisture_H:   ds 1
;Final_Moisture_L:   ds 1
;Final_Light_H:	ds 1
;Final_Light_L:	ds 1
;Temp_Reg_H: ds 1    ; temp values
;Temp_Reg_L: ds 1
;ADC_Result_H:	ds 1	; for values from ADRESH and ADRESL
;ADC_Result_L:	ds 1  
;shift_n:    ds 1
;   
;ADC_Setup:
;    bcf	ANSEL0	; ANSEL0 set AN0 to analog
;    bcf	ANSEL1  ; ANSEL1 set AN1 to analog
;    bcf	ANSEL2  ; ANSEL2 set AN2 to analog
;    bsf	TRISA, PORTA_RA0_POSN, A    ; pin RA0==AN0 input
;    bsf	TRISA, PORTA_RA1_POSN, A    ; AN1 set as input
;    bsf	TRISA, PORTA_RA2_POSN, A    ; AN2 set as input
;    
;    movlw   0x30	; sets V_Ref to 4.096V (11)
;    movwf   ADCON1, A ; sets -ve V_Ref to 0V
;    movlw   0xF6	; configure ADCON2 for acquisition time and conversion clock (right justfied output)
;    movwf   ADCON2, A ; Fosc/64 clock and acquisition times
;
;    ;bsf??ADCON0, 0 ; turns ADON bit to 0 which means the converter is operating
;    return
;    
;Select_Channel:
;    andlw   0XC3    ; clears the bits in the channel (1100 0011) --> these are the channel select bits, so prepares to set a new channel	
;    iorlw   WREG
;    movwf   ADCON0, A	; gets specific channel config
;    bsf	ADCON0, 0, A   ; sets ADON bit 0 to 1 which makes sure ADC is on
;    return
;	
;ADC_Read:
;    bsf	GO  ; Start conversion by setting GO bit in ADCON0
;adc_loop:
;    btfsc   GO	; check to see if finished
;    bra	adc_loop
;
;    movff   ADRESH, ADC_Result_H
;    movff   ADRESL, ADC_Result_L
;    return
;
;Read_Sensors:
;    movlw 0x01    ; AN0 channel
;    call    Select_Channel
;    call    ADC_Read
;    movff   ADC_Result_H, Moisture_H	; stores the high byte
;    movff   ADC_Result_L, Moisture_L	; stores the low byte
;
;    movlw   0x05    ; AN1 channel
;    call    Select_Channel
;    call    ADC_Read
;    movff   ADC_Result_H, Thermistor_H
;    movff   ADC_Result_L, Thermistor_L
;
;    movlw   0x09    ; AN2 channel
;    call    Select_Channel
;    call    ADC_Read
;    movff   ADC_Result_H, Photodiode_H
;    movff   ADC_Result_L, Photodiode_L
;    return
;
;Right_Shift:
;    ; dividing by 2^n --> for temperature n=12, for moisture n=
;    movwf   shift_n, A ; move the shift count into reg
;shift_loop:
;    bcf	STATUS, 0, A
;    rrcf    Temp_Reg_H, 1   ; shift the high byte
;    rrcf    Temp_Reg_L, 1   ; shift low byte
;    decfsz  shift_n, F, A	; decrement shift count
;    bra	shift_loop  ; repeat until shift count = 0
;    return
;	
;Convert_Temperature:
;    ; getting the ADC result of the temp first --> this is is 12 bit val
;    movf    Thermistor_H, W, A ; load high byte
;    movwf   Temp_Reg_H, A	; store in temp reg
;    movf    Thermistor_L, W, A
;    movwf   Temp_Reg_L, A
;
;    movlw   12
;    call    Right_Shift	; divides ADC value by 4096 (2^12) --> ADC/4096
;
;    movlw   1
;    subwf   Temp_Reg_H, 1  ; 1 - (ADC/4096) stored in Temp_Reg
;    movlw   1
;    subwf   Temp_Reg_L, 1
;
;    rlcf    Temp_Reg_H, 1   ; multiplying Temp_Reg by 2 --> by doing a left shift store back in Temp_Reg
;    rlcf    Temp_Reg_L, 1
;
;    movlw   1
;    subwf   Temp_Reg_H, 1   ; 659 - Temp_Reg
;    movlw   1
;    subwf   Temp_Reg_L, 1
;
;    movlw   759
;    mulwf   Temp_Reg_H, 1   ; multiplying Temp_Reg by 759 --> Temp_Reg/0.00132 ~ 759*Temp_Reg
;    movlw   759
;    mulwf   Temp_Reg_L, 1
;
;    movf    Temp_Reg_H, W
;    movwf   Final_Temp_H
;    movf    Temp_Reg_L, W
;    movwf   Final_Temp_L
;
;    return
;	
;Convert_Moisture:
;    movf    Moisture_H, W	; load high byte
;    movwf   Temp_Reg_H	; store in Temp_Reg_H
;    movf    Moisture_L, W          
;    movwf   Temp_Reg_L            
;
;    movlw   100	; move 100 into W reg
;    mulwf   Temp_Reg_H	; multiply ADC value by 100
;    movlw   100
;    mulwf   Temp_Reg_L
;
;    movlw   12	; divide by 2^12
;    call    Right_Shift
;
;    movf    Temp_Reg_L, W
;    movwf   Final_Moisture_L
;    movf    Temp_Reg_H, W
;    movwf   Final_Moisture_H	; stores as percentage
;
;    return
;
;Convert_Photodiode:
;    movf    Photodiode_H, W ; load high byte
;    movwf   Temp_Reg_H	; store in Temp_Reg_H
;    movf    Photodiode_L, W          
;    movwf   Temp_Reg_L            
;
;    movlw   100	; move 100 into W reg
;    mulwf   Temp_Reg_H	; multiply ADC value by 100
;    movlw   100
;    mulwf   Temp_Reg_L
;
;    movlw   12
;    call    Right_Shift	; divides moisture level by 4096 (2^12)
;
;    movf    Temp_Reg_L, W
;    movwf   Final_Light_L
;    movf    Temp_Reg_H, W
;    movwf   Final_Light_H   ; stores as percentage
;
;    return
;   
;end
