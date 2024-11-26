#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data
myList:	    ds 0x80
myThree:    ds 0x80

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
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup UART
	goto	start
	
	; ******* Main programme ****************************************
start: 	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(FirstLine)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(FirstLine)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(FirstLine)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	FirstLine_l	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop		; keep going until finished
	
	; Write first message to UART
	movlw	FirstLine_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message

	; Write first message to LCD
	movlw	FirstLine_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
	; Move cursor to second line
	movlw	0xC0		
	call	LCD_Send_Byte_I
	movlw	10		; Introducing delay cause maybe the cursor is going too quick
	movwf	delay_count	;	and missing the first character??
	call	delay
	
	; Prepare and write the second line
	lfsr	0, myList
	movlw	low highword(SecondLine)
	movwf	TBLPTRU, A
	movlw	high(SecondLine)
	movwf	TBLPTRH, A
	movlw	low(SecondLine)
	movwf	TBLPTRL, A
	movlw	SecondLine_l
	movwf	counter, A

loop2:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz	counter, A
	bra	loop2
	
	; Write second message to LCD
	movlw	mySecondTable_l
	addlw	0xff
	lfsr	2, myList    ; load address of the second message
	call	LCD_Write_Message   ; write second message to the LCD
	
	; Move cursor to third line
	movlw   0x94        ; Command to move to start of third line
	call    LCD_Send_Byte_I
	movlw   10          ; Introducing delay cause maybe the cursor is going too quick
	movwf   delay_count ; and missing the first character??
	call    delay
	
	lfsr	0, myThree
	movlw	low highword(ThirdLine)
	movwf	TBLPTRU, A
	movlw	high(ThirdLine)
	movwf	TBLPTRH, A
	movlw	low(ThirdLine)
	movwf	TBLPTRL, A
	movlw	ThirdLine_l
	movwf	counter, A
	
loop3:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz	counter, A
	bra	loop3
	
	; Write second message to LCD
	movlw	ThirdLine_l
	addlw	0xff
	lfsr	2, myThree    ; load address of the second message
	call	LCD_Write_Message   ; write second message to the LCD
    
	goto	$		; goto current line in code

	; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	end	rst