#include <xc.inc>
    
global	Check_Buttons, Move_Up, Move_Down, Select_Line
    
Check_Buttons:
    btfsc   PORTB, 0		; If the port is clear,
    call    Move_Up
    
    btfsc   PORTB, 1
    call    Move_Down
    
    btfsc   PORTB, 2
    call    Select_Line
    
    return
    
Move_Up:
   decf	    current_line, F	; Decrement the current_line variable 
   btfss    STATUS, Z		; If current line < 0
   goto	    Display_Menu
   
   movlw   2
   movwf   current_line		; Loop to last line if < 0
   call    Display_Menu
   return

Move_Down:
    incf    current_line, F
    movlw   3
    subwf   current_line, W
    btfsc   STATUS, Z		; If current_line >= 3
    clrf    current_line	; Loop back to 0
    
    call    Display_Menu
    return

    
Select_Line:
    call LCD_Clear		; Currently just clears the LCD display
    return


