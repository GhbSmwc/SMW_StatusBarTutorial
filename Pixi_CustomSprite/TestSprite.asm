;This is a test sprite to write a string of text (characters).
;This is useful for displaying numbers.

;It makes use of the RAM defined as "!Scratchram_CharacterTileTable"
;And writes them to OAM.

incsrc "../StatusBarRoutinesDefines/Defines.asm"
incsrc "../SharedSub_Defines/SubroutineDefs.asm"

!Default_RAMToDisplay = $60
;^[2 bytes] Displays the decimal number of this RAM.

!DigitProperties = %00110001
;^YXPPCCCT

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
	
	.ControllerChangeNumber
	LDA $15
	BIT.b #%00001000
	BNE ..Up
	BIT.b #%00000100
	BNE ..Down
	BRA +
	
		..Up
			REP #$20
			LDA !Default_RAMToDisplay
			INC A
			STA !Default_RAMToDisplay
			SEP #$20
			BRA +
		..Down
			REP #$20
			LDA !Default_RAMToDisplay
			DEC A
			STA !Default_RAMToDisplay
			SEP #$20
	+
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
		PLA				;\Restore XY position
		STA $01				;|
		PLA				;|
		STA $00				;/
		JSL !SupressLeadingZeros	;We have the string at !Scratchram_CharacterTileTable and we have X acting as how many characters/sprite tiles so far written.
		PLY				;We need the Y index for OAM indexing
		;Handle X position. We can find the position of the string should be at:
		;StringXPos = (SpriteXPos + OffsetToCenter) - ((NumbOfChar*8)/2)
		;
		;With math trickery, we can make it easy to handle in 65c816 assembly in this order:
		;
		;(((NumbOfChar*8)/2) * -1) + (SpriteXPos + OffsetToCenter)
		;
		;Also, we can reduce the fraction: 8/2 -> 4/1, or just simply multiply by 4:
		;
		;((NumbOfChar*4) * -1) + (SpriteXPos + OffsetToCenter)
		;
		;-$00 = SpriteXPos (sprite's OAM tile X position, relative to screen border)
		;-OffsetToCenter = (signed) how many pixels to the "apparent" center of sprite.
		; Most things have their origin XY position at the top and left edge of their "bounding box". In this case
		; SpriteXPos is the leftmost pixel of the sprite. Since the body of this sprite is 16x16, we need to go right
		; 8 pixels, which is halfway between X=0 and X=16.
		;-NumbOfChar = X index
		;
			TXA
			;ASL #3			;>Multiply by 2^3 (which is 8)
			;LSR			;\Divide by 2... Wait a minute! Code optimization! Multiplying by 8/2 can be reduced to 4/1. This means we only need to ASL 2 times (2^2 = 4) since a leftshift then a rightshift will cancel each other out.
			ASL #2			;/
			EOR #$FF		;\Multiply by -1, which inverts the sign
			INC A			;/
			CLC			;\Add with the sprite's X position
			ADC $00			;/
			CLC			;\Plus OffsetToCenter
			ADC #08			;/
			STA $02			;>X position of string
			
			;LDA $00				;\X position
			;STA $02				;/
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
