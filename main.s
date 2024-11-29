#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_Clear, LCD_Send_Byte_D, ReadLine1, ReadLine2, ReadLine3
extrn	Check_Buttons, Move_Up, Move_Down, Select_Line
    
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
	db	'L', 'i', 'g', 'h', 't',0x0a
	SecondLine_l	EQU 6	; length of second message
	align	2
	
ThirdLine:
	db	'M', 'o', 'i', 's', 't', 'u', 'r', 'e', 0x0a
	ThirdLine_l	EQU 9	; length of third line
	align 2
	
Arrow:
	db	0x7E
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf    CFGS    
	bsf    EEPGD
	call   UART_Setup
	call   LCD_Setup

	clrf   current_line, A     ; Start from the first line
	call   Display_Menu     ; Initial display
	
	banksel	TRISB
	movlw	0xFF
	movwf	TRISB, A
	
	goto   start
	
	; ******* Main programme ****************************************
start:
	call	Check_Buttons
	goto	start
	
Display_Menu:
	call    LCD_Clear
	movlw   0x80            ; Move cursor to the first line
	call    LCD_Send_Byte_I
	
	; Print the first line
	call	ReadLine1
	
loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop		; keep going until finished

	; Write first message to LCD
	movlw	FirstLine_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	call	LCD_Clear


	; Print arrow if current line is 1
	movf    current_line, W, A
	sublw   1
	bnz     skip_arrow_1
	
	movlw   0x80            ; Move cursor to the start of first line
	call    LCD_Send_Byte_I
	
	movlw   Arrow           ; Print arrow symbol
	call    LCD_Send_Byte_D
	
skip_arrow_1:
	movlw   0xC0            ; Move cursor to the second line
	call    LCD_Send_Byte_I	
	
	call	ReadLine2

loop2:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz	counter, A
	bra	loop2
	
	; Write second message to LCD
	movlw	SecondLine_l
	addlw	0xff
	lfsr	2, myArray    ; load address of the second message
	call	LCD_Write_Message   ; write second message to the LCD

	; Print arrow if current line is 2
	movf    current_line, W, A
	sublw   2
	bnz     skip_arrow_2
	
	movlw   0xC0            ; Move cursor to the start of second line
	call    LCD_Send_Byte_I
	
	movlw   Arrow		; Printing the arrow?
	call    LCD_Send_Byte_D
	
skip_arrow_2:
	movlw   0x94            ; Move cursor to the third line
	call    LCD_Send_Byte_I
	
	call	ReadLine3
	
loop3:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz	counter, A
	bra	loop3
	
	; Write third line of the messge to LCD
	movlw	ThirdLine_l
	addlw	0xff
	lfsr	2, myArray    ; load address of the second message
	call	LCD_Write_Message   ; write second message to the LCD
	
	; Print arrow if current line is 3
	movf    current_line, W, A
	sublw   3
	bnz     skip_arrow_3
	movlw   0x94            ; Move cursor to the start of third line
	call    LCD_Send_Byte_I
	movlw   Arrow
	call    LCD_Send_Byte_D
skip_arrow_3:
	return
	
; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	end	rst