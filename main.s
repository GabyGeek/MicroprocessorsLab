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

int:	org	0x008
	goto	ISR
	    
setup:	
	bcf	CFGS		; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	
	movlw	0xFF
	movwf	TRISC, A	; sets PORTA as the input
	
	clrf	current_line
	
	bsf	INTCON, GIE	; global interrupt enabled in the Interrupt Control Register
				; if it's open, no current flows to the microprocessor, disables all interrupts
				; if it's closed and at least one of the masks is also closed, current flows to pic18, enables all un-masked interrupts
	bsf	INTCON, PEIE	; enable peripheral interrupts - located in the INTCON sfr
	bsf	INTCON, IOCIE	; enable interrupt-on-change for port c
	
	movlw 0x07              ; Enable IOC for pins RC0, RC1, RC2
	movwf IOCAP, A          ; Positive edge-triggered interrupts (use IOCAN for negative)
	
	call	Check_Buttons
	call	LCD_Setup	; setup LCD
	goto	Display_Menu

;-----------------------------------------
; Interrupt Service Routine
;-----------------------------------------
ISR:
	btfss   INTCON, IOCIF	; check if the interrupt flag (IF) on IOC (port C) has been raised => interrupt occurred
	retfie			; return if no interrupt
	
	movf	PORTC, W	; read PORT C
	andlw	0x07		; check which bits haven't been used
	
	btfsc	STATUS, 2	; 2 is the zero bit. 1 if the result of an arithmetic or logic operation is zero. Skips if no button pressed
	retfie			
	
	movlw	0x01		; Checks RC0
	andwf	PORTC, W
	btfsc	STATUS, 2	; checks if the arithmetic logic above results in a 1. If not, skips the below command
	call	Move_Up
	
	movlw	0x02		; Checks RC1
	andwf	PORTC, W
	btfsc	STATUS, 2
	call	Move_Down
	
	movlw	0x04		; Checks RC2
	andwf	PORTC, W
	btfsc	STATUS, 2
	call	Select_Line
	
	bcf	INTCON, IOCIF	; clears the IOC interrupt flag
	retfie			; return from interrupt
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