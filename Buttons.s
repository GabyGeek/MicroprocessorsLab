#include <xc.inc>
    
extrn	current_line
extrn	Display_Menu, LCD_Clear
global  Move_Up, Move_Down, Select_Line, Button_Int
       
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


