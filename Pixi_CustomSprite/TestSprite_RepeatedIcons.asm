;This is a test sprite to display a number of things as repeated icons.
;
;NOTE! If too many tiles are drawn, exceeding the maximum set by the
;sprite memory header (in "Change Properties in Sprite Header (in hex)"),
;tile wraparound can occur, starting with the last tile written (any tile
;that has the highest Y OAM index). I recommend using
;"No More Sprite Tile limits" or use SA-1.
;
;Displacement for each icon (8-bit signed), in pixels. Negative is going (filling) left or up, positive is right or down.
; extra_byte_1: Horizontal displacement
; extra_byte_2: Vertical displacement
;

incsrc "../StatusBarRoutinesDefines/Defines.asm"
incsrc "../SharedSub_Defines/SubroutineDefs.asm"


;Sprite table for displaying:
 !SpriteTable_HowManyFilled = !1504
 !SpriteTable_HowManyTotal = !1510

;Repeated icons tile data.
 !RepeatIconEmpty_TileNumb = $90
 !RepeatIconEmpty_TileProp = %00110001 ;>YXPPCCCT
 !RepeatIconFull_TileNumb = $91
 !RepeatIconFull_TileProp = %00110001 ;>YXPPCCCT
print "INIT ",pc
	RTL

print "MAIN ",pc
	PHB : PHK : PLB
	JSR SpriteCode
	PLB
	RTL

SpriteCode:
	PHB : PHK : PLB
	LDA $9D
	BNE .SkipFreeze
	
	.ControllerChangeNumberVert
		LDA $16
		BIT.b #%00001000
		BNE ..Up
		BIT.b #%00000100
		BNE ..Down
		BRA +
	
		..Up
			LDA !SpriteTable_HowManyFilled,x
			CMP #$09
			BEQ ++
			INC A
			STA !SpriteTable_HowManyFilled,x
			++
			BRA +
		..Down
			LDA !SpriteTable_HowManyFilled,x
			BEQ ++
			DEC A
			STA !SpriteTable_HowManyFilled,x
			++
	+
	.ControllerChangeNumberHoriz
		LDA $16
		BIT.b #%00000001
		BNE ..Right
		BIT.b #%00000010
		BNE ..Left
		BRA +
		
		..Right
			LDA !SpriteTable_HowManyTotal,x
			CMP #$09
			BEQ ++
			INC A
			STA !SpriteTable_HowManyTotal,x
			++
			BRA +
		..Left
			LDA !SpriteTable_HowManyTotal,x
			BEQ ++
			DEC A
			STA !SpriteTable_HowManyTotal,x
			++
	+
	.MaxCheck
		LDA !SpriteTable_HowManyTotal,x
		CMP !SpriteTable_HowManyFilled,x
		BCS ..NotExceed
		STA !SpriteTable_HowManyFilled,x
		..NotExceed
	.SkipFreeze
	JSR DrawSprite
	PLB
	RTS
	
DrawSprite:
	JSR Graphics
	RTS
	
Graphics:
	%GetDrawInfo()		;>We need: Y: OAM index, $00 and $01: Position. It does not mess with any other data in $02-$0F. Like I said, don't push, then call this without pulling in between pushing and calling GetDrawInfo.
		LDA !SpriteTable_HowManyTotal,x
		BEQ .NoRepeatingIcons
	;Draw repeated icons
		PHX
		;Center repeating icons
		;To have the center point correctly position, here is the calculation
		;-Assume both have an origin at the top-left corner
		;-To obtain the horizontal midpoint of both, just divide by 2: 16x16: 8px from left, 8x8: 4px from the left.
		;-Take the half-horizontal position of the body of sprite, subtract by half-horizontal of the icon.
		;Therefore the formula is:
		;IconCenterPlacement = (WidthOfBody/2) - (WidthOfEachIcon/2)
		;Where:
		;WidthOfBody = The width, in pixels, of the body of the sprite (the egg part of the sprite in this example)
		;WidthOfIcons = the width of each icon, in pixels.
		;
		;In this example, WidthOfBody = 16, WidthOfIcons = 8:
		;4 = (16/2) - (8/2)
		;4 = 8 - 4
		;
		;Scratch RAM $00 contains the sprite's origin X position relative to the screen, we then take that, add
		;by IconCenterPlacement (4 in this example), and write it to $02, which will be the X position for the 
		;!CenterRepeatingIcons subroutine.
		;
		;Now note: If you are using an existing sprite, its origin may not always be the top-left of the bounding
		;box of the sprite (such as thwomps).
			LDA $00					;\X position, the body of the sprite is 16x16, and each icon is 8x8.
			CLC					;|
			ADC #$04				;|
			STA $02					;/
			LDA $01					;\Y position
			CLC					;|
			ADC #$10				;|
			STA $03					;/
			LDA !extra_byte_1,x			;\Displacement between each icon
			STA $04					;|
			LDA !extra_byte_2,x			;|
			STA $05					;/
			LDA !SpriteTable_HowManyTotal,x		;\max number of icons
			STA $06					;/
			%CenterRepeatingIcons()			;>Center
		;Draw repeating icons
			LDA #!RepeatIconEmpty_TileNumb		;\Empty and full tile numbers and properties
			STA $06					;|
			LDA #!RepeatIconEmpty_TileProp		;|
			STA $07					;|
			LDA #!RepeatIconFull_TileNumb		;|
			STA $08					;|
			LDA #!RepeatIconFull_TileProp		;|
			STA $09					;/
			LDA !SpriteTable_HowManyFilled,x	;\How many filled
			STA $0A					;/
			LDA !SpriteTable_HowManyTotal,x		;\How much maxed
			STA $0B					;/
			%WriteRepeatedIconsAsOAM()
			PLX
		.NoRepeatingIcons
	;Draw the body of sprite
		LDA $00			;\X position
		STA $0300|!addr,y	;/
		LDA $01			;\Y position
		STA $0301|!addr,y	;/
		LDA #$00		;\Tile number
		STA $0302|!addr,y	;/
		LDA.b #%00000001	;\YXPPCCCT
		ORA $64			;|
		STA $0303|!addr,y	;/
		PHY			;\Manually set the size
		TYA			;|
		LSR #2			;|
		TAY			;|
		LDA $0460|!addr,y	;|
		ORA.b #%00000010	;|
		STA $0460|!addr,y	;|
		PLY			;/
	;Finish OAM writing
		LDA !SpriteTable_HowManyTotal,x		;>Max number of characters. Since we write a static 16x16 tile and repeated icons, that is [TotalIcons + 1 - 1], we don't need a DEC.
		LDY #$FF				;>We write both 8x8 and 16x16.
		%FinishOAMWrite()
	;Graphics done.
	RTS
