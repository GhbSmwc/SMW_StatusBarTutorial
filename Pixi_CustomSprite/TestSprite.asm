incsrc "../StatusBarRoutinesDefines/Defines.asm"

;NOTE: work-in-progress.


print "MAIN ",pc
	PHB : PHK : PLB
	JSR SpriteCode
	PLB
	RTL

SpriteCode:
	PHB : PHK : PLB
	JSR DrawSprite
	PLB
	RTS
	
DrawSprite:
	JSR Graphics
	RTS
	
Graphics:
	;%GetDrawInfo()		;>We need: Y: OAM index, $00 and $01: Position. It does not mess with any other data in $02-$0F. Like I said, don't push, then call this without pulling in between pushing and calling GetDrawInfo.
	
	;JSL $01B7B3|!BankB          ; Call the routine that draws the sprite (finish OAM write).
	RTS