	incsrc "../StatusBarRoutinesDefines/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine calculates where to position the string horizontally
;to be centered (text align) to a given reference point. Mainly
;useful for having numbers centered with the body of the sprite.
;
;NOTE: This ALWAYS places each tile 8 pixels away from each tile.
;
;Here is how it works:
; Formula to get the X position of the centered string:
;  StringXPos = (SpriteXPos + OffsetToCenter) - ((NumbOfChar*8)/2)
; Which becomes this because this is procedural programming:
;  (((NumbOfChar*8)/2) * -1) + (SpriteXPos + OffsetToCenter)
; We can reduce 8/2 into 4/1 (results in just multiplying by 4):
;  ((NumbOfChar*4) * -1) + (SpriteXPos + OffsetToCenter)
;Here are what the variables mean:
; - $00 = SpriteXPos (sprite's OAM tile X position, relative to screen border)
; - OffsetToCenter = (signed) how many pixels to the "apparent" center of sprite.
;   Most things have their origin XY position at the top and left edge of their "bounding box". In this case
;   SpriteXPos is the leftmost pixel of the sprite. Since the body of this sprite is 16x16, we need to go right
;   8 pixels, which is halfway between X=0 and X=16.
; - NumbOfChar = X index
;
;To be called after "SuppressLeadingZeros" subroutine (or its variants).
;
;Input:
; - X index: How many characters.
; - $00: Sprite OAM X position, obtained from calling getdrawinfo.
; - $03: X position of the point the string to be centered with, relative to the sprite's origin
;   (this routine takes $00, add by whats in $03, and stores to $02)
;Output:
; - $02: X position of the string, for "WriteStringAsSpriteOAM" subroutine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?GetStringXPositionCentered:
	TXA
	;ASL #3			;>Multiply by 2^3 (which is 8)
	;LSR			;\Divide by 2... Wait a minute! Code optimization! Multiplying by 8/2 can be reduced to 4/1. This means we only need to ASL 2 times (2^2 = 4) since a leftshift then a rightshift will cancel each other out.
	ASL #2			;/
	EOR #$FF		;\Multiply by -1, which inverts the sign
	INC A			;/
	CLC			;\Add with the center point position
	ADC $00			;/
	CLC			;\Plus OffsetToCenter
	ADC $03			;/
	STA $02			;>X position of string
	RTL