#include <xc.inc>
    
extrn	current_line, delay_count
extrn	Display_Menu, LCD_Clear
global	Check_Buttons, Move_Up, Move_Down, Select_Line
    
Check_Buttons:
    btfsc   PORTD, 0, A		; If bit 0 of PORTB is clear, skip the command
    call    Move_Up
    
    btfsc   PORTD, 1, A
    call    Move_Down
    
    btfsc   PORTD, 2, A
    call    Select_Line
    
    return
    
Move_Up:
   ; if on line 2, make current line 0
   movlw    0
   movwf    current_line, A
   movlw    0XFF		    ; delay for debouncing of the button
   movwf    delay_count, A
   call	    delay
   return

Move_Down:
    ; if on line 1, make current line 1
   movlw    1
   movwf    current_line, A
   movlw    0xFF		    ; delay for debouncing of the button
   movwf    delay_count, A
   call	    delay
   return

    
Select_Line:
    ;call LCD_Clear		; Currently just clears the LCD display
   movlw    2
   movwf    current_line, A
   movlw    0XFF		    ; delay for debouncing of the button
   movwf    delay_count, A
   call	    delay
   return

delay:	decfsz	delay_count, A	    ; decrement until zero
	bra	delay
	return

