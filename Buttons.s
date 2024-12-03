#include <xc.inc>

global	Keypad_Setup, Keypad_Read, Error_Check, button
    
psect	udata_acs   ; reserve data space in access ram
row: ds	    1
col: ds	    1
button: ds	1
cnt_ms:	ds 1   ; reserve 1 byte for ms counter
cnt_l:	ds 1   ; reserve 1 byte for variable cnt_l
cnt_h:	ds 1   ; reserve 1 byte for variable cnt_h


psect	keypad_code,class=CODE
    
Keypad_Setup:
	banksel PADCFG1
	bsf	    REPU
	clrf    LATE, A
	banksel 0
    
	movlw   0x0F
	movwf   TRISE, A 
	movlw   1
	call    delay_ms
    
	return 
    
Keypad_Read: 
	; reading column
	movlw   0x00
	movwf   PORTE, A
	movff   PORTE, col
	movlw   1
	call    delay_ms
    
	; reading row
	movlw   0xF0
	movwf   TRISE, A
	movlw   1
	call    delay_ms
    
	movwf   PORTE, A
	movff   PORTE, row
 
    
	;finding button
	movff   row, WREG
	iorwf   col, W, A
	movwf   button, A
	movlw   0x0F
	movwf   TRISE, A
    
	movff   button, WREG
	;call   Error_Check
	return
    
Error_Check:
	movlw   0xFF ;ascii code for null 
	cpfseq  button, A
	retlw   0xFF

;Delay Routines
delay_ms:		    ; delay given in ms in W
	movwf	cnt_ms, A
lp2:	movlw	250	    ; 1 ms delay
	call	delay_x4us	
	decfsz	cnt_ms, A
	bra	lp2
	return
	
delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	cnt_l, A	; now need to multiply by 16
	swapf   cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	cnt_l, W, A ; move low nibble to W
	movwf	cnt_h, A	; then to cnt_h
	movlw	0xf0	    
	andwf	cnt_l, F, A ; keep high nibble in cnt_l
	call	delay
	return

delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lp1:	decf 	cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lp1		; carry, then loop again
	return			; carry reset so return


    end
    