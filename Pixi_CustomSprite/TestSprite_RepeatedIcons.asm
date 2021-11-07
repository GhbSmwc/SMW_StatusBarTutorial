;This is a test sprite to display a number of things as repeated icons.
;
;NOTE! If too many tiles are drawn, exceeding the maximum set by the
;sprite memory header (in "Change Properties in Sprite Header (in hex)"),
;tile wraparound can occur, starting with the last tile written (any tile
;that has the highest Y OAM index).

incsrc "../StatusBarRoutinesDefines/Defines.asm"
incsrc "../SharedSub_Defines/SubroutineDefs.asm"


!Default_RAMToDisplay = $60
;^[1 byte] Displays the number of filled icons
!Default_RAMToDisplay2 = $61
;^[1 byte] Displays the total (or maximum) of icons.

;Repeated icons tile data.
 !RepeatIconEmpty = $90
 !RepeatIconFull = $91
 !RepeatIconProperties = %00110001
  ;^YXPPCCCT
;Other settings
 !IconDisplacementX = $08
 !IconDisplacementY = $00
  ;^Displacement for each icon (8-bit signed), in pixels. Negative is going (filling) left or up, positive is right or down.
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
			LDA !Default_RAMToDisplay
			CMP #$09
			BEQ ++
			INC A
			STA !Default_RAMToDisplay
			++
			BRA +
		..Down
			LDA !Default_RAMToDisplay
			BEQ ++
			DEC A
			STA !Default_RAMToDisplay
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
			LDA !Default_RAMToDisplay2
			CMP #$09
			BEQ ++
			INC A
			STA !Default_RAMToDisplay2
			++
			BRA +
		..Left
			LDA !Default_RAMToDisplay2
			BEQ ++
			DEC A
			STA !Default_RAMToDisplay2
			++
	+
	.SkipFreeze
	JSR DrawSprite
	PLB
	RTS
	
DrawSprite:
	JSR Graphics
	RTS
	
Graphics:
	%GetDrawInfo()		;>We need: Y: OAM index, $00 and $01: Position. It does not mess with any other data in $02-$0F. Like I said, don't push, then call this without pulling in between pushing and calling GetDrawInfo.
		LDA !Default_RAMToDisplay2
		BEQ .NoRepeatingIcons
	;Draw repeated icons
		PHX
		;Center repeating icons
			LDA $00				;\X position
			CLC				;|
			ADC #$04			;|
			STA $02				;/
			LDA $01				;\Y position
			CLC				;|
			ADC #$10			;|
			STA $03				;/
			LDA #!IconDisplacementX		;\Displacement between each icon
			STA $04				;|
			LDA #!IconDisplacementY		;|
			STA $05				;/
			LDA !Default_RAMToDisplay2	;\max number of icons
			STA $06				;/
			JSL !CenterRepeatingIcons	;>Center
		;Draw repeating icons
			LDA #!RepeatIconEmpty		;\Empty and full tile numbers
			STA $06				;|
			LDA #!RepeatIconFull		;|
			STA $07				;/
			LDA #!RepeatIconProperties	;\YXPPCCCT
			STA $08				;/
			;LDA #!IconDisplacementX		;\Displacement between each icon
			;STA $04				;|
			;LDA #!IconDisplacementY		;|
			;STA $05				;/
			LDA !Default_RAMToDisplay	;\How many filled
			STA $09				;/
			LDA !Default_RAMToDisplay2	;\How much maxed
			STA $0A				;/
			JSL !WriteRepeatedIconsAsOAM
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
		LDA !Default_RAMToDisplay2	;>Max number of characters. Since we write a static 16x16 tile and repeated icons, that is [TotalIcons + 1 - 1], we don't need a DEC.
		LDY #$FF			;>We write both 8x8 and 16x16.
		%FinishOAMWrite()
	;Graphics done.
	RTS
