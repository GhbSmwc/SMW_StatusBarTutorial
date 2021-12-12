;This is a test sprite to write a string of text (characters).
;This is useful for displaying numbers.

;It makes use of the RAM defined as "!Scratchram_CharacterTileTable"
;And writes them to OAM.

incsrc "../StatusBarRoutinesDefines/Defines.asm"
incsrc "../SharedSub_Defines/SubroutineDefs.asm"

!TwoNumbers = 1
;^0 = 1 number
; 1 = 2 numbers (X/Y)

!Default_RAMToDisplay = $60
;^[2 bytes] Displays the decimal number of this RAM.
!Default_RAMToDisplay2 = $62
;^[2 bytes] Second number to display, if enabled by !TwoNumbers

;Digit tiles. See GraphicTable for each digit tile number.
 !DigitProperties = %00110001
  ;^YXPPCCCT

;Slash symbol
 !TileNumber_SlashSymbol = $8A		;>Tile number
 !TileProp_SlashSymbol = %00110001	;>YXPPCCCT

;NOTE: work-in-progress.


;Plan: We handle the stuff as "strings", then when writing to OAM,
;we need:
;
;NumbOfChar, as we need the total number of tiles, -1, for finish OAM write ($01B7B3 or %FinishOAMWrite())
;
;The width of string. We assume each character are 8px width. We can get NumbOfChar, and multiply that by 8
;as needed for alignment.
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
		LDA $15
		BIT.b #%00001000
		BNE ..Up
		BIT.b #%00000100
		BNE ..Down
		BRA +
	
		..Up
			REP #$20
			LDA !Default_RAMToDisplay
			CMP #$FFFF
			BEQ ++
			INC A
			STA !Default_RAMToDisplay
			++
			SEP #$20
			BRA +
		..Down
			REP #$20
			LDA !Default_RAMToDisplay
			BEQ ++
			DEC A
			STA !Default_RAMToDisplay
			++
			SEP #$20
	+
	.ControllerChangeNumberHoriz
		LDA $15
		BIT.b #%00000001
		BNE ..Right
		BIT.b #%00000010
		BNE ..Left
		BRA +
		
		..Right
			REP #$20
			LDA !Default_RAMToDisplay2
			CMP #$FFFF
			BEQ ++
			INC A
			STA !Default_RAMToDisplay2
			++
			SEP #$20
			BRA +
		..Left
			REP #$20
			LDA !Default_RAMToDisplay2
			BEQ ++
			DEC A
			STA !Default_RAMToDisplay2
			++
			SEP #$20
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
	;Draw the number string
		PHX				;>Preserve sprite index
		PHY
		LDA $00				;\Preserve XY position in $00-$01
		PHA				;|
		LDA $01				;|
		PHA				;/
		REP #$20			;\Since $00-$01 is used as an input for hexdec
		LDA !Default_RAMToDisplay	;|
		STA $00				;|
		SEP #$20			;/
		JSL !SixteenBitHexDecDivision	
		LDX #$00			;>Start the string at position 0 for suppressing leading zeroes in string
		JSL !SupressLeadingZeros	;We have the string at !Scratchram_CharacterTileTable and we have X acting as how many characters/sprite tiles so far written.
		if !TwoNumbers != 0
			;Draw the second number "X/Y", the "/Y" part.
			;"/" symbol
				LDA #$0A
				STA !Scratchram_CharacterTileTable,x
				INX
			;Second number
				PHX					;>Preserve string character position
				REP #$20
				LDA !Default_RAMToDisplay2
				STA $00
				SEP #$20
				JSL !SixteenBitHexDecDivision
				PLX					;>Restore string character position
				JSL !SupressLeadingZeros
		endif
		PLA				;\Restore XY position
		STA $01				;|
		PLA				;|
		STA $00				;/
		PLY				;We need the Y index for OAM indexing
		LDA #$08			;\Center X position (this egg sprite is 16px wide, with origin position at the top-left edge, add 8 from there and you'll be at the midpoint)
		STA $03				;/
		JSL !GetStringXPositionCentered	;>$02 is now the X position of the string centered.
		LDA $01				;\Y position
		CLC				;|
		ADC #$10			;|
		STA $03				;/
		TXA				;\Number of characters, minus 1.
		DEC A				;|
		STA $04				;/
		LDA.b #!DigitProperties		;\Properties
		STA $05				;/
		LDA.b #GraphicTable		;\conversion table from numbers to graphic numbers
		STA $06				;|
		LDA.b #GraphicTable>>8		;|
		STA $07				;|
		LDA.b #GraphicTable>>16		;|
		STA $08				;/
		JSL !WriteStringAsSpriteOAM	;>Write to OAM, we also have Y as the OAM index.
		PLX				;>Restore sprite index
	
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
		LDA $04				;>Number of characters, minus 1.
		INC A				;>...Plus a 16x16 sprite
		LDY #$FF			;>We write both 8x8 and 16x16.
		%FinishOAMWrite()
	;Graphics done.
	RTS
GraphicTable:
	db $80				;>Index $00 = for the "0" graphic
	db $81				;>Index $01 = for the "1" graphic
	db $82				;>Index $02 = for the "2" graphic
	db $83				;>Index $03 = for the "3" graphic
	db $84				;>Index $04 = for the "4" graphic
	db $85				;>Index $05 = for the "5" graphic
	db $86				;>Index $06 = for the "6" graphic
	db $87				;>Index $07 = for the "7" graphic
	db $88				;>Index $08 = for the "8" graphic
	db $89				;>Index $09 = for the "9" graphic
	db $8A				;>Index $0A = for the "/" graphic
