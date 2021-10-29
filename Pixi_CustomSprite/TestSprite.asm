incsrc "../StatusBarRoutinesDefines/Defines.asm"

;NOTE: work-in-progress.

print "INIT ",pc
	RTL

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
	%GetDrawInfo()		;>We need: Y: OAM index, $00 and $01: Position. It does not mess with any other data in $02-$0F. Like I said, don't push, then call this without pulling in between pushing and calling GetDrawInfo.
	
	LDA $00
	STA $0300,y	; X position
	LDA $01
	STA $0301,y	; Y position
	LDA #$80
	STA $0302,y	; Tile number
	LDA.b #%00110011
	STA $0303,y	; Properties
	
	LDA #$00
	LDY #$00
	JSL $01B7B3|!BankB          ; Call the routine that draws the sprite (finish OAM write), A = number of OAM slots to write - 1, Y = size ($00 = 8x8, $01 = 16x16, $80-$FF = manually write $0460).
	RTS