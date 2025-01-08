#include <xc.inc>
    
extrn	current_line, delay_count
extrn	Display_Menu, LCD_Clear
global	Arrow_to_Temperature, Arrow_to_Light, Arrow_to_Moisture

Arrow_to_Temperature:
   movlw    0
   movwf    current_line, A
   movlw    0XFF		    ; delay for debouncing of the button
   movwf    delay_count, A
   call	    delay
   return

Arrow_to_Light:
   movlw    1
   movwf    current_line, A
   movlw    0xFF		    ; delay for debouncing of the button
   movwf    delay_count, A
   call	    delay
   return

Arrow_to_Moisture:
   movlw    2
   movwf    current_line, A
   movlw    0xFF		    ; delay for debouncing of the button
   movwf    delay_count, A
   call	    delay
   return

delay:	decfsz	delay_count, A	    ; decrement until zero
	bra	delay
	return

