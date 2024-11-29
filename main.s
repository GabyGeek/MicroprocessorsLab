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
    
    ; First Line
    movlw   0x80            ; Move cursor to first line
    call    LCD_Send_Byte_I
    lfsr    2, FirstLine    ; Load first line address
    movlw   FirstLine_l     ; Load length
    call    LCD_Write_Message
    
    ; Check if arrow goes on first line
    movf    current_line, W, A
    sublw   1
    bnz     print_second_line
    movlw   0x80
    call    LCD_Send_Byte_I
    movf    Arrow, W, A     ; Load arrow value correctly
    call    LCD_Send_Byte_D
    
print_second_line:
    movlw   0xC0            ; Move cursor to second line
    call    LCD_Send_Byte_I
    lfsr    2, SecondLine   ; Load second line address
    movlw   SecondLine_l    ; Load length
    call    LCD_Write_Message
    
    ; Check if arrow goes on second line
    movf    current_line, W, A
    sublw   2
    bnz     print_third_line
    movlw   0xC0
    call    LCD_Send_Byte_I
    movf    Arrow, W, A     ; Load arrow value correctly
    call    LCD_Send_Byte_D
    
print_third_line:
    movlw   0x94            ; Move cursor to third line
    call    LCD_Send_Byte_I
    lfsr    2, ThirdLine    ; Load third line address
    movlw   ThirdLine_l     ; Load length
    call    LCD_Write_Message
    
    ; Check if arrow goes on third line
    movf    current_line, W, A
    sublw   3
    bnz     menu_done
    movlw   0x94
    call    LCD_Send_Byte_I
    movf    Arrow, W, A     ; Load arrow value correctly
    call    LCD_Send_Byte_D
    
menu_done:
    return

	
; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	end	rst