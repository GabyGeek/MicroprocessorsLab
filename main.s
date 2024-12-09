#include <xc.inc>
;-----------------------------------------
; External and Global variables
;-----------------------------------------
extrn	Move_Up, Move_Down, Select_Line, Button_Int  ; external subroutines
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

int:	org	0x008
	goto	ISR
	    
setup:	
	bcf	CFGS		; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	
	movlw	0xFF
	movwf	TRISC, A	; sets PORTC as the input
	
	clrf	current_line, A
	
	movlw	0x07		; 1:256 prescale value (page 186 in the datasheet)
	movwf	T0CON, A	; or is it TIMER0, bit 0 = T0PS0
	
	movlw 0xF0              ; Preload high byte (TMR0H)??
	movwf TMR0H, A
	movlw 0x60              ; Preload low byte (TMR0L) ??
	movwf TMR0L, A
	
	bsf	INTCON, 5, A	; bit 5 = TMR0IE - enables/disables the TMR0 overflow interrupt
	bsf	INTCON, 7, A	; bit 7 = GIE = global interrupt enabled in the Interrupt Control Register
				; if it's open, no current flows to the microprocessor, disables all interrupts
				; if it's closed and at least one of the masks is also closed, current flows to pic18, enables all un-masked interrupts
	bsf	INTCON, 6, A	; bit 6 = PEIE - enable peripheral interrupts - located in the INTCON sfr
	
	call	Check_Buttons
	call	LCD_Setup	; setup LCD
	goto	Display_Menu

;-----------------------------------------
; Interrupt Service Routine
;-----------------------------------------
ISR:
        btfss INTCON, 2, A	; bit 2 = TMR0IF - checks if Timer0 interrupt occurred
	retfie                  ; Return if no interrupt

	; Reset Timer0 preload for 1 ms
	movlw 0xF0              ; Preload high byte (TMR0H)
	movwf TMR0H, A
	movlw 0x60              ; Preload low byte (TMR0L)
	movwf TMR0L, A

	; Check buttons (polling PORTC pins 0?2)
	movf PORTC, W, A        ; Read PORTC
	andlw 0x07              ; Mask out unused bits (only RC0-RC2)

	movlw 0x01              ; Check RC0
	andwf PORTC, W, A
	btfsc STATUS, 2, A      ; Skip if not pressed
	call Move_Up            ; Call Move_Up if RC0 is pressed

	movlw 0x02              ; Check RC1
	andwf PORTC, W, A
	btfsc STATUS, 2, A      ; Skip if not pressed
	call Move_Down          ; Call Move_Down if RC1 is pressed

	movlw 0x04              ; Check RC2
	andwf PORTC, W, A
	btfsc STATUS, 2, A      ; Skip if not pressed
	call Select_Line        ; Call Select_Line if RC2 is pressed

	bcf INTCON, 2, A	; bit 2 = TMR0IF - Clear Timer0 interrupt flag
	retfie                  ; Return from interrupt
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