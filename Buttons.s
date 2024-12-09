#include <xc.inc>
    
extrn	current_line
extrn	Display_Menu, LCD_Clear
global	Check_Buttons, Move_Up, Move_Down, Select_Line
    
Check_Buttons:
    btfsc   PORTC, 0, A		; If bit 0 of PORTB is clear, skip the command
    call    Move_Up
    
    btfsc   PORTC, 1, A
    call    Move_Down
    
    btfsc   PORTC, 2, A
    call    Select_Line
    
    return
    
Move_Up:
   ; if on line 2, make current line 0
   movlw    0
   movwf    current_line
   goto	    Display_Menu
   return

Move_Down:
    ; if on line 1, make current line 1
   movlw    1
   movwf    current_line
   goto	    Display_Menu
   return

    
Select_Line:
    call LCD_Clear		; Currently just clears the LCD display
    return


