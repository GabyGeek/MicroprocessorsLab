#include <xc.inc>

global  LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_Send_Byte_D, LCD_Clear
global	Read_Line1, Read_Line2,	Read_Line3, Read_Arrow, Move_Line1, Move_Line2, Write_Line1, Write_Line2, Write_Line3, Write_Arrow
    
extrn	counter, delay_count, myArray, FirstLine, FirstLine_l, SecondLine, SecondLine_l, ThirdLine, ThirdLine_l, Arrow, Arrow_l

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage

	LCD_E	EQU 5	; LCD enable bit
    	LCD_RS	EQU 4	; LCD register select bit

psect	lcd_code,class=CODE
    
LCD_Setup:
	clrf    LATB, A
	movlw   11000000B	    ; RB0:5 all outputs
	movwf	TRISB, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00001111B	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	movlw	00000110B	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	return

LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter, A
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return

LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD
	return
	
	
;-----------------------------------------
; READING/WRITING/CLEARING the LCD
;-----------------------------------------
Read_Line1:
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(FirstLine)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(FirstLine)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(FirstLine)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	FirstLine_l	; bytes to read
	movwf 	counter, A		; our counter register
	return

Read_Line2:
	lfsr	0, myArray
	movlw	low highword(SecondLine)
	movwf	TBLPTRU, A
	movlw	high(SecondLine)
	movwf	TBLPTRH, A
	movlw	low(SecondLine)
	movwf	TBLPTRL, A
	movlw	SecondLine_l
	movwf	counter, A
	return
	
Read_Line3:
	lfsr	0, myArray
	movlw	low highword(ThirdLine)
	movwf	TBLPTRU, A
	movlw	high(ThirdLine)
	movwf	TBLPTRH, A
	movlw	low(ThirdLine)
	movwf	TBLPTRL, A
	movlw	ThirdLine_l
	movwf	counter, A
	return
	
Read_Arrow:
	lfsr	0, myArray
	movlw	low highword(Arrow)
	movwf	TBLPTRU, A
	movlw	high(Arrow)
	movwf	TBLPTRH, A
	movlw	low(Arrow)
	movwf	TBLPTRL, A
	movlw	Arrow_l
	movwf	counter, A
	return
	
Write_Line1:
	movlw	FirstLine_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	return
	
Write_Line2:
	movlw	SecondLine_l
	addlw	0xff
	lfsr	2, myArray    ; load address of the second message
	call	LCD_Write_Message   ; write second message to the LCD
	return

Write_Line3:
	movlw	ThirdLine_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	return	

Write_Arrow:
	movlw	Arrow_l
	addlw	0xff
	lfsr	2, myArray    ; load address of the second message
	call	LCD_Write_Message   ; write second message to the LCD
	return
	
Move_Line1:
	movlw	0x80		
	call	LCD_Send_Byte_I
	movlw	200		; Introducing delay cause maybe the cursor is going too quick
	movwf	delay_count,A	;	and missing the first character??
	call	delay
	return
	
Move_Line2:
	movlw	0xC0		
	call	LCD_Send_Byte_I
	movlw	10		; Introducing delay cause maybe the cursor is going too quick
	movwf	delay_count,A	;	and missing the first character??
	call	delay
	return

LCD_Clear:
	movlw	0x01		; Clear display command
	call	LCD_Send_Byte_I	; Send command to LCD
	movlw	10
	movwf	delay_count, A
	call	delay
	return
	
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return
	
    end