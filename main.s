#include <xc.inc>
;-----------------------------------------
; External and Global variables
;-----------------------------------------
extrn	Check_Buttons, Move_Up, Move_Down, Select_Line  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_Clear
extrn	Read_Line1, Read_Line2,	Read_Arrow, Move_Line1, Move_Line2, Write_Line1, Write_Line2, Write_Arrow
    

global	counter, current_line, delay_count, myArray, FirstLine, FirstLine_l, SecondLine, SecondLine_l, Arrow, Arrow_l, Display_Menu
;-----------------------------------------
; Holding space for constants
;-----------------------------------------
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:	ds  1    ; reserve one byte for counter in the delay routine
current_line:	ds  1	 ; current line of menu (0x80 = line 1, 0xC0 = line 2, diff = 0x40) 
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

    
;-----------------------------------------
; Loading the Messages
;-----------------------------------------
psect	data    
FirstLine:
	db	'T', 'E', 'M', 'P', 'E', 'R', 'A', 'T', 'U', 'R', 'E',0x0a
	FirstLine_l   EQU	12	; length of data
	align	2
	
SecondLine:
	db	'L', 'i', 'g', 'h', 't',0x0a
	SecondLine_l	EQU 6	; length of second message
	align	2
	
Arrow:
	db	0xFF, 0x0a  ; currently just an indicator, not an arrow
	Arrow_l	EQU 2
	align	2

;-----------------------------------------
; Main Program
;-----------------------------------------
psect	code, abs	
rst: 	org 0x0
 	goto	setup
	
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	
	movlw	0xFF
	movwf	TRISA, A	; sets PORTB as the input
	
	call	LCD_Setup	; setup LCD
	call	Initial_Menu	; inital display
	
Button_Loop:
	call	Check_Buttons
	bra	Button_Loop
    
Initial_Menu:
	call	Read_Line1
	call	Read_Arrow
	
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop		; keep going until finished

	call	Write_Line1	; write first message
	call	Write_Arrow
	call	Move_Line2	; Move cursor to second line
	call	Read_Line2

loop2:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz	counter, A
	bra	loop2
	
	call	Write_Line2
	call	Move_Line1
	
	bra	Display_Menu		; goto current line in code

Display_Menu:
	call	Read_Line1
	call	Read_Arrow
	
display_loop:
        tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	display_loop		; keep going until finished

	call	Write_Line1	; write first message
	
	movf    current_line, W     ; Move current_line value to W
	sublw   1                   ; Subtract W from 1 (checking if current_line == 1)
	btfss   STATUS, 2           ; Skip next instruction if not zero
	call    Write_Arrow         ; Call if current_line == 1
	
	call	Move_Line2	; Move cursor to second line
	call	Read_Line2

display_loop2:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz	counter, A
	bra	display_loop2
	
	call	Write_Line2
	
	movf    current_line, W     ; Move current_line value to W
	sublw   1                   ; Subtract W from 1 (checking if current_line == 1)
	btfsc   STATUS, 2           ; Skip next instruction if not zero
	call    Write_Arrow         ; Call if current_line == 1
	
	call	Move_Line1
	
	bra	Display_Menu		; goto current line in code
;-----------------------------------------
; Delay
;-----------------------------------------
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	end	rst