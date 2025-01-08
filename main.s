#include <xc.inc>
;-----------------------------------------
; External and Global variables
;-----------------------------------------
extrn	Arrow_to_Temperature, Arrow_to_Light, Arrow_to_Moisture ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_Clear, LCD_Send_Byte_D
extrn	Read_Line1, Read_Line2,	Read_Line3, Read_Arrow, Move_Line1, Move_Line2, Write_Line1, Write_Line2, Write_Line3, Write_Arrow
extrn	Final_Moisture_H, Final_Moisture_L, Final_Temp_H, Final_Temp_L, Final_Light_H, Final_Light_L    
extrn	ADC_Setup, ADC_Read, Right_Shift, Read_Sensors

global	counter, current_line, delay_count, myArray 
global	FirstLine, FirstLine_l, SecondLine, SecondLine_l, ThirdLine, ThirdLine_l, Arrow, Arrow_l 
global	Display_Menu
    
;-----------------------------------------
; Holding space for constants
;-----------------------------------------
psect	udata_acs		    ; reserve data space in access ram
counter:	ds 1		    ; reserve one byte for a counter variable
delay_count:	ds  1		    ; reserve one byte for counter in the delay routine
current_line:	ds  1		    ; current line of menu

psect	udata
;-----------------------------------------
; Sensor Constants
;-----------------------------------------
moisture_l_L:	ds 1	; lower limit of ideal range for moisture percentage
moisture_l_H:	ds 1
moisture_u_L:	ds 1	; upper limit of ideal range moisture percentage
moisture_u_H:	ds 1
light_l_L:  ds 1
light_l_H:  ds 1
light_u_L:  ds 1
light_u_H:  ds 1
temp_l_L:   ds 1
temp_l_H:   ds 1
temp_u_L:   ds 1
temp_u_H:   ds 1
delay1:	ds 1
Temp_ASCII_H:	ds 1
Temp_ASCII_L:	ds 1
Temp_ASCII: ds 1
    
psect	udata_bank4		    ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80		    ;reserve 128 bytes for message data
;-----------------------------------------
; Loading the Messages
;-----------------------------------------
psect	data    
FirstLine:
	db	'T', 'E', 'M', 'P', 'E', 'R', 'A', 'T', 'U', 'R', 'E',0x0a
	FirstLine_l   EQU	12	; length of data
	align	2
	
SecondLine:
	db	'L', 'L', 'i', 'g', 'h', 't',0x0a
	SecondLine_l	EQU 7		; length of second message
	align	2
	
	
ThirdLine:
	db	'M', 'o', 'i', 's', 't', 'u', 'r', 'e', 0x0a
	ThirdLine_l   EQU	9	; length of data
	align	2

Arrow:
	db	' ','<','-','-', 0x0a		; currently just an indicator, not an arrow
	Arrow_l	EQU 5
	align	2

;-----------------------------------------
; Setup Section
;-----------------------------------------
psect	code, abs	
rst: 	org 0x0
 	goto	setup

int:	org	0x008
	goto	ISR
	    
setup:	
	bcf	CFGS		; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	
	movlw	0xFF
	movwf	TRISD, A	; sets PORTD as the input
	
	bsf TRISE, 0, A	; configuring the LEDs to PORT E
	bsf TRISE, 1, A	; configuring the LEDs to PORT E
	bsf TRISE, 2, A	; configuring the LEDs to PORT E
	bsf TRISE, 3, A	; configuring the LEDs to PORT E
	bsf TRISE, 4, A	; configuring the LEDs to PORT E
	
	clrf	current_line, A
	
	movlw	2
	movwf	current_line, A	    ; FOR TESTING ONLY
	
	movlw	0x87		; 1 for bit 7 to turn on the timer and 111 for bits 0-2 1:256 prescale value (page 186 in the datasheet)
	movwf	T0CON, A	; or is it TIMER0, bit 0 = T0PS0
	
	movlw	0xFF              ; Preload high byte (TMR0H)??
	movwf	TMR0H, A
	movlw	0xFC              ; Preload low byte (TMR0L) ??
	movwf	TMR0L, A
	
	bsf	INTCON, 5, A	; bit 5 = TMR0IE - enables/disables the TMR0 overflow interrupt
	bsf	INTCON, 7, A	; bit 7 = GIE = global interrupt enabled in the Interrupt Control Register
				; if it's open, no current flows to the microprocessor, disables all interrupts
				; if it's closed and at least one of the masks is also closed, current flows to pic18, enables all un-masked interrupts
	bsf	INTCON, 6, A	; bit 6 = PEIE - enable peripheral interrupts - located in the INTCON sfr
	
	call	ADC_Setup
	call	Read_Sensors
	call	Set_Ranges
	
	call	LCD_Setup	; setup LCD
	goto	main_loop

;-----------------------------------------
; Interrupt Service Routine
;-----------------------------------------
ISR:
        btfss	INTCON, 2, A	; bit 2 = TMR0IF - checks if Timer0 interrupt occurred
	retfie                  ; Return if no interrupt

	; Reset Timer0 preload for 1 ms
	movlw	0xFF              ; Preload high byte (TMR0H)
	movwf	TMR0H, A
	movlw	0xFC              ; Preload low byte (TMR0L)
	movwf	TMR0L, A

	movf	PORTD, W, A        ; Read PORTC

	btfsc	PORTD, 0, A	    ; RD0
	call	Arrow_to_Temperature	; Move arrow to temperature line

	btfsc	PORTD, 1, A	    ; RD1
	call	Arrow_to_Light	; Move arrow to light line

	btfsc	PORTD, 2, A	    ; RD2
	call	Arrow_to_Moisture   ; Move arrow to moisture line
	
	btfsc	PORTD, 3, A	    ; RD3
	call	Select_Lines	;Move arrow to moisture line

	bcf	INTCON, 2, A	    ; bit 2 = TMR0IF - Clear Timer0 interrupt flag
	retfie			    ; Return from interrupt
	
;-----------------------------------------
; Display Routine - Checking for Line 3
;-----------------------------------------
main_loop:
	;call	LCD_Clear
	call	Display_Menu
	call	Delay
	goto	main_loop
	
Display_Menu:
	movf	current_line, W, A
	sublw	2
	btfsc	STATUS, 2, A
	call	Second_Menu
	
	call	First_Menu
	return
	
;-----------------------------------------
; Display Routine Line 1
;-----------------------------------------
First_Menu:
	call	Move_Line1
	call	Read_Line1
	
display_loop:
        tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	display_loop		; keep going until finished

	call	Write_Line1	    ; write first message
	
	movf    current_line, W, A     ; Move current_line value to W
	sublw   1                   ; Subtract W from 1 (checking if current_line == 1)
	btfss   STATUS, 2, A          ; Skip next instruction if not zero
	call	Arrow_Line1
	
	call	Move_Line2	    ; Move cursor to second line
	call	Read_Line2
	bra	display_loop2
	
Arrow_Line1:
	call	Read_Arrow
	call	display_loop_arrow1
	return
	
display_loop_arrow1:
        tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	display_loop_arrow1		; keep going until finished
	
	call    Write_Arrow         ; Call if current_line == 1
	return
	
;-----------------------------------------
; Display Routine Line 2
;-----------------------------------------

display_loop2:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz	counter, A
	bra	display_loop2
	
	call	Write_Line2
	
	movf    current_line, W, A     ; Move current_line value to W
	sublw   1                   ; Subtract W from 1 (checking if current_line == 1)
	btfsc   STATUS, 2, A           ; Skip next instruction if not zero
	call    Arrow_Line2         ; Call if current_line == 1
	
	goto	$
	
Arrow_Line2:
	call	Read_Arrow
	call	display_loop_arrow2
	return
	
display_loop_arrow2:
        tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	display_loop_arrow2		; keep going until finished
	
	call    Write_Arrow   
	return
	
;-----------------------------------------
; Display Routine Line 3
;-----------------------------------------
Second_Menu:
	;call	LCD_Clear	    ; clears the LCD
	call	Move_Line1	    ; Move cursor to first line
	call	Read_Line3
	
display_loop3:
	tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	display_loop3		; keep going until finished

	call	Write_Line3		; write first message
	
	movf    current_line, W, A     ; Move current_line value to W
	sublw   2			; Subtract W from 3 (checking if current_line == 3)
	btfsc   STATUS, 2, A		; Skip next instruction if not zero
	call	Arrow_Line3
	
	goto	$

Arrow_Line3:
	call	Read_Arrow
	call	display_loop_arrow3
	return
	
display_loop_arrow3:
        tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	display_loop_arrow3		; keep going until finished
	
	call    Write_Arrow   
	return

;-----------------------------------------
; Converting Byte Values to Hex
;-----------------------------------------
Byte_to_Hex:
    swapf   WREG, W
    andlw   0x0F
    call    Nibble_to_ASCII
    movwf   Temp_ASCII_H
    
    movf    WREG, W
    andlw   0x0F
    call    Nibble_to_ASCII
    movwf   Temp_ASCII_L
     
Nibble_to_ASCII:
    addlw   0
    movwf   Temp_ASCII
    
    movlw   9
    subwf   Temp_ASCII, W
    btfss   STATUS, 0
    goto    Letter
    
    return 
    
Letter:
    addlw   7
    movwf   Temp_ASCII
    
    return 
	
;-----------------------------------------
; Select Measurements to Display
;-----------------------------------------
Select_Lines:
    movf    current_line, W, A
    sublw   0
    btfsc   STATUS, 2
    call    Display_Temperature
   
    movf    current_line, W, A
    sublw   1
    btfsc   STATUS, 2
    call    Display_Light
   
    movf    current_line, W, A
    sublw   2
    btfsc   STATUS, 2
    call    Display_Moisture
   
Display_Temperature:
    call    LCD_Clear
    call    Move_Line1
    movf    Final_Temp_H, W
    ;call    Convert_To_ASCII    ; Convert high byte to ASCII
    call    LCD_Send_Byte_D

    movf    Final_Temp_L, W
    ;call    Convert_To_ASCII    ; Convert low byte to ASCII
    call    LCD_Send_Byte_D
    return

Display_Moisture:
    call    LCD_Clear
    call    Move_Line1
    movf    Final_Moisture_H, W
    ;call    Convert_to_ASCII
    call    LCD_Send_Byte_D
   
    movf    Final_Moisture_L, W
    ;call    Convert_to_ASCII
    call    LCD_Send_Byte_D
   
    return
    
Display_Light:
    call    LCD_Clear  
    call    Move_Line1
    movf    Final_Light_H, W
    ;call    Convert_to_ASCII
    call    LCD_Send_Byte_D
   
    movf    Final_Light_L, W
    ;call    Convert_to_ASCII
    call    LCD_Send_Byte_D
   
    return
	
;-----------------------------------------
; Ideal Ranges for Sensors - LED Flashes
;-----------------------------------------
Set_Ranges:
    movlw   0x00    ; set lower limit for temp 21 degrees C - HIGH BYTE
    movwf   temp_l_H
    movlw   0x15    ; set lower limit for temp 21 degrees C - LOW BYTE
    movwf   temp_l_L
   
    movlw   0x00    ; set upper limit for temp 29 degrees C - HIGH BYTE
    movwf   temp_u_H
    movlw   0x1D    ; set upper limit for temp 29 degrees C - LOW BYTE
    movwf   temp_u_L
   
    movlw   0x1B    ; set upper limit for lux 7000lux - HIGH BYTE
    movwf   light_u_H
    movlw   0x58    ; set upper limit for lux 7000lux - LOW BYTE
    movwf   light_u_L
   
    movlw   0x13    ; set lower limit for lux 5000lux - HIGH BYTE
    movwf   light_l_H
    movlw   0x88    ; set lower limit for lux 5000lux - LOW BYTE
    movwf   light_l_L
   
    movlw   0x00    ; set upper limit for moisture level 80% - HIGH BYTE
    movwf   moisture_u_L
    movlw   0x50    ; set upper limit for moisture level 80% - LOW BYTE
    movwf   moisture_u_H
   
    movlw   0x00    ; set lower limit for moisture level 41% - HIGH BYTE
    movwf   moisture_l_H
    movlw   0x29    ; set lower limit for moisture level 41% - LOW BYTE
    movwf   moisture_l_L
    return
;-----------------------------------------
; Comparisons
;-----------------------------------------	
Temp_Compare:
    movf    Final_Temp_H, W ; if high byte = lower limit, continue
    sublw   temp_l_H	; subtract temp from lower limit
    btfss   STATUS, 2	; if set then the two bytes are equal, if not set then continue
    btfsc   STATUS, 0	; if set then final temp < lower limit, if clear then
    call    Limit
   
    movf    Final_Temp_L, W
    sublw   temp_l_L
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    movf    temp_u_H, W
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    movf    temp_u_L, W
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    call    End_Compare
    return
   
Moisture_Compare:
    movf    Final_Moisture_H, W
    sublw   moisture_l_H
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    movf    Final_Moisture_L, W
    sublw   moisture_l_L
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    movf    moisture_u_H, W
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    movf    moisture_l_L, W
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    call    End_Compare
    return

Photodiode_Compare:
    movf    Final_Light_H, W
    sublw   light_l_H
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
     btfsc   STATUS, 0
    call    Limit
   
    call    End_Compare
    return
   
    movf    Final_Light_L, W
    sublw   light_l_L
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    movf    light_u_H, W
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    movf    light_u_L, W
    btfss   STATUS, 2
    btfsc   STATUS, 0
    call    Limit
   
    call    End_Compare
    return
  
Limit:
    call    Activate_LEDs
    call    End_Compare
    return

End_Compare:
    return
   
Activate_LEDs:
    movlw   0x0F
    xorwf   PORTE, F
    call    Delay
    
    return
    
;-----------------------------------------
; Delays
;-----------------------------------------
delay:	decfsz	delay_count, A	    ; decrement until zero
	bra	Delay
	return
Delay:
    movlw   0xFF
    movwf   delay1
    return
Delay_Loop:
    decfsz  delay1, F
    goto    Delay_Loop
    return
    
	end	rst
