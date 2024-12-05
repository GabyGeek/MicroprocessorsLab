#include <xc.inc>
;-----------------------------------------
; External and Global variables
;-----------------------------------------
extrn	Check_Buttons, Move_Up, Move_Down, Select_Line, Button_Int  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_Clear
extrn	Read_Line1, Read_Line2,	Read_Arrow, Move_Line1, Move_Line2, Write_Line1, Write_Line2, Write_Arrow

global	counter, current_line, delay_count, myArray, FirstLine, FirstLine_l, SecondLine, SecondLine_l, Arrow, Arrow_l, Display_Menu
    
;-----------------------------------------
; Holding space for constants
;-----------------------------------------
psect	udata_acs		    ; reserve data space in access ram
counter:	ds 1		    ; reserve one byte for a counter variable
delay_count:	ds  1		    ; reserve one byte for counter in the delay routine
current_line:	ds  1		    ; current line of menu (0x80 = line 1, 0xC0 = line 2, diff = 0x40) 
    
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
	
Arrow:
	db	'<','-','-', 0x0a		; currently just an indicator, not an arrow
	Arrow_l	EQU 4
	align	2

;-----------------------------------------
; Setup Section
;-----------------------------------------
psect	code, abs	
rst: 	org 0x0
 	goto	setup

int_hi:	org	0x0008
	goto	Button_Int
	    
setup:	
	bcf	CFGS		; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	
	movlw	0xFF
	movwf	TRISA, A	; sets PORTA as the input
	
	movlw	0		; TESTING THE ARROW
	movwf	current_line	; TESTING THE ARROW
	
	call	LCD_Setup	; setup LCD
	goto	Display_Menu

;-----------------------------------------
; Interrupt Service Routine
;-----------------------------------------

;-----------------------------------------
; Display Routine
;-----------------------------------------
Display_Menu:
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
; Delay
;-----------------------------------------
delay:	decfsz	delay_count, A	    ; decrement until zero
	bra	delay
	return

	end	rst