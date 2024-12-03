#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_Clear, LCD_Send_Byte_D
extrn	Keypad_Setup, Keypad_Read, Error_Check
    
    
global	current_line, delay_count, Display_Menu, myArray, counter
global	FirstLine, FirstLine_l, SecondLine, SecondLine_l, ThirdLine, ThirdLine_l
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
current_line: 	ds 1; Holds the selected menu index (1-3)
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data    
	; ******* LINES ON THE LCD*****
FirstLine:
	db	'T', 'E', 'M', 'P', 'E', 'R', 'A', 'T', 'U', 'R', 'E',0x0a
	FirstLine_l   EQU	12	; length of data
	align	2
	
SecondLine:
	db	'L', 'I', 'G', 'H', 'T',0 x0a
	SecondLine_l	EQU 6	; length of second message
	align	2
	
ThirdLine:
	db	'M', 'O', 'I', 'S', 'T', 'U', 'R', 'E', 0x0a
	ThirdLine_l	EQU 9	; length of third line
	align   2
	
Initial_Display:
	db  'T', 'E', 'M', 'P', '=', '0', ',', ' ', 'M', 'O', 'I', 'S', 'T', '=', '1', ',', ' ', 'L', 'I', 'G', 'H', 'T', '=', '2', 0x0a
	InitialDisplay_l EQU 23 ; length of initial display message
	align   2
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	
	bcf    CFGS    
	bsf    EEPGD
	call   UART_Setup
	call   LCD_Setup
	call   Keypad_Setup
	call   Display_Menu     ; initial display  
	
	    
	movlw   high(InitialDisplay) ;show initial display message (buttons corresponding to what)
	movwf   FSR2H
	movlw   low(InitialDisplay)
	movwf   FSR2L
	movlw   InitialDisplay_l
	call    LCD_Write_Message
    
    
	movlw   100             ; delay so person can read it
	movwf   delay_count
	call    delay
    
	call    LCD_Clear       ; clear display 
    
	banksel TRISB
	movlw   0xFF
	movwf   TRISB, A
    
	goto    start
	; ******* Main programme ****************************************
start:
Main_Loop:  
	call	Keypad_Read
	movf    button, W, A	   ;loading in key input from buttons. to w reg
	
	movlw	0xEE               ; example value for '1'
	subwf	WREG, W
	btfsc	STATUS, Z          ; if it matches '1'
	goto	Display_Line1

	movlw	0xED               ; example value for '2'
	subwf	WREG, W
	btfsc	STATUS, Z          ; if it matches '2'
	goto	Display_Line2

	movlw	0xEB               ; eample value for '3'
	subwf	WREG, W
	btfsc	STATUS, Z          ; if it matches '3'
	goto	Display_Line3

	goto	Main_Loop           ; if no match, continue loop

Display_Line1:
	movlw	high(FirstLine)
	movwf	FSR2H
	movlw	low(FirstLine)
	movwf	FSR2L
	movlw	FirstLine_l
	call	LCD_Write_Message
	goto	Main_Loop

Display_Line2:
	movlw	high(SecondLine)
	movwf	FSR2H
	movlw	low(SecondLine)
	movwf	FSR2L
	movlw	SecondLine_l
	call	LCD_Write_Message
	goto	Main_Loop

Display_Line3:
	movlw	high(ThirdLine)
	movwf	FSR2H
	movlw	low(ThirdLine)
	movwf	FSR2L
	movlw	ThirdLine_l
	call	LCD_Write_Message
	goto	Main_Loop

	end	rst	

delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	end	rst