;This is a test sprite to write a string of text (characters).
;This is useful for displaying numbers.

;It makes use of the RAM defined as "!Scratchram_CharacterTileTable"
;And writes them to OAM.

incsrc "../StatusBarRoutinesDefines/Defines.asm"
incsrc "../SharedSub_Defines/SubroutineDefs.asm"

;Display setting
!NumberDisplayType = 1
 ;^0 = 1 number
 ; 1 = 2 numbers (X/Y)
 ; 2 = percentage
;Percentage display settings
 !Default_PercentagePrecision = 0
  ;^0 = show whole number precisions, 1 = 1/10 of a percentage, 2 = 1/100. Not to be confused
  ; with !Scratchram_PercentageFixedPointPrecision.
  
 !CapAt100 = 1
  ;^0 = allow percentage to display values greater than 100, 1 = cap at 100.

 !AvoidRounding0 = 1
  ;^0 = allow rounding towards 0%, 1 = round to 1%, 0.1%, or 0.01%.
 !AvoidRounding100 = 1
  ;^0 = allow rounding towards 100%, 1 = round to 99%, 99.9% or 99.99%.

!Default_RAMToDisplay = $60
;^[2 bytes] Displays the decimal number of this RAM.
!Default_RAMToDisplay2 = $62
;^[2 bytes] Second number to display, if enabled by !NumberDisplayType

;character tile properties (applies to all characters). See GraphicTable for each character.
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
	;Controls that adjust the number
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
	;Handle graphics
		JSR DrawSprite
	;And done.
	PLB
	RTS
	
DrawSprite:
	JSR Graphics
	RTS
	
Graphics:
	%GetDrawInfo()		;>We need: Y: OAM index, $00 and $01: Position. It does not mess with any other data in $02-$0F. Like I said, don't push, then call this without pulling in between pushing and calling GetDrawInfo.
	;Draw the number string
	if or(equal(!NumberDisplayType, 0), equal(!NumberDisplayType, 1))
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
		if !NumberDisplayType != 0
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
	else
		PHX		;>Preserve sprite slot index
		PHY		;>Preserve sprite OAM index
		LDA $00		;\Preserve OAM XY pos
		PHA		;|
		LDA $01		;|
		PHA		;/
		;First, get the percentage
			REP #$20
			LDA !Default_RAMToDisplay
			STA !Scratchram_PercentageQuantity
			LDA !Default_RAMToDisplay2
			STA !Scratchram_PercentageMaxQuantity
			SEP #$20
			LDA.b #!Default_PercentagePrecision
			STA !Scratchram_PercentageFixedPointPrecision
			JSL !ConvertToPercentage
		;Cap at 100
			if !CapAt100 != 0
				.CheckExceed100
					REP #$30
					LDX.w #(10**(!Default_PercentagePrecision+2))
					;Check the high word of the XXXX (RAM_00-RAM_03 = $XXXXYYYY)
						LDA $02			;\Any nonzero digits in the high word would mean at least
						BNE ..Cap100		;/65536 ($00010000), which is guaranteed over 100/1000/10000.
					;Check low word
						TXA
						CMP $00			;\Max compares with RAM_00
						BCS ..Under		;/If Max >= RAM_00 or RAM_00 is lower, don't set it to max.
					
					..Cap100
						TXA
						STA $00
					..Under
					SEP #$30
			endif
		;Round away from 0 and 100
			if !AvoidRounding0 != 0
				CPY #$01
				BNE +
				REP #$20
				LDA #$0001
				STA $00
				STZ $02
				SEP #$20
				+
			endif
			if !AvoidRounding100 != 0
				CPY #$02
				BNE +
				REP #$20
				LDA.w #(10**(!Default_PercentagePrecision+2)-1)		;>99%, 99.9%, or 99.99%.
				STA $00
				STZ $02
				SEP #$20
				+
			endif
		;Display the number
			JSL !SixteenBitHexDecDivision
			;Since we are dealing with OAM, and at the start of each frame, it clears the OAM (Ypos = $F0),
			;we don't need to clear a space since it is already done.
			if !Default_PercentagePrecision == 0
				LDX #$00
				JSL !SupressLeadingZeros
			elseif !Default_PercentagePrecision == 1
				LDA #$0D
				STA $09
				LDX #$00
				JSL !SupressLeadingZerosPercentageLeaveLast2
			elseif !Default_PercentagePrecision == 2
				LDA #$0D
				STA $09
				LDX #$00
				JSL !SupressLeadingZerosPercentageLeaveLast3
			endif
			;X = number of characters
			LDA #$0B					;\Percent symbol
			STA !Scratchram_CharacterTileTable,x		;/
			INX
			PLA				;\Restore OAM XY
			STA $01				;|
			PLA				;|
			STA $00				;/
			PLY				;>Restore sprite OAM index
		;Center X position
			LDA #$08				;\Center to sprite
			STA $03					;/
			JSL !GetStringXPositionCentered		;>$02 = center X pos
		;Y position
			LDA $01					;\Y position
			CLC					;|
			ADC #$10				;/
			STA $03					;>$03 = Y pos
			STX $04				;>Number of tiles
		;Tile table
			LDA.b #GraphicTable		;\conversion table from numbers to graphic numbers
			STA $06				;|
			LDA.b #GraphicTable>>8		;|
			STA $07				;|
			LDA.b #GraphicTable>>16		;|
			STA $08				;/
			LDA.b #!DigitProperties		;\Properties
			STA $05				;/
		;Write to OAM
			DEX
			STX $04
			JSL !WriteStringAsSpriteOAM
			PLX				;>Restore sprite slot index
	endif
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
	db $8B				;>Index $0B = for the "%" graphic
	db $8C				;>Index $0C = for the "!" graphic
	db $8D				;>Index $0D = for the "." graphic