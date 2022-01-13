;This is a test sprite to write a string of text (characters).
;This is useful for displaying numbers.
;
;
;extra_byte_1: Display type:
; -$00 = One number ("X")
; -$01 = Two numbers ("X/Y")
; -$02 = Percentage ("XXX%", "XXX.X%", or "XXX.XX%")
; -$03 = Timer (MM:SS.CC (8 tiles on the timer itself))
; -$04 = Timer (HH:MM:SS.CC (11 tiles on the timer itself))
;extra_byte_2: Percentage precision (if extra_byte_1 is $02):
; -$00 = whole percentage ("XXX%")
; -$01 = 1/10th of a percentage ("XXX.X%")
; -$02 = 1/100th of a percentage ("XXX.XX%")
;extra_byte_3: Cap at 100, allow-round-to-zero, allow-round-to-100 flags (if extra_byte_1 is $02):
; -Bitwise format: %00000HZC
; --C = Cap to 100 flag. 0 = no, 1 = yes (any value greater than 100% will display 100%).
; --Z = Allow rounding to 0:
;    0 = no, The X in the rule of [0 < X < 5*10**(-Precision)] would be replaced with (1*10**(-Precision))
;     Essentially:
;      Precision = 0: [0% < X < 0.5%] will display 1%
;      Precision = 1: [0% < X < 0.05%] will display 0.1%
;      Precision = 2: [0% < X < 0.005%] will display 0.01%
;    1 = yes
; --H = Allow rounding to 100:
;    0 = no, the X in the rule of [100-(5*10**(-Precision-1)) < X < 100] would be replaced with (100 - (1*10**(-Precision))
;     Essentially:
;      Precision = 0 [99.5% <= X < 100%] will display 99%
;      Precision = 1 [99.95% <= X < 100%] will display 99.9%
;      Precision = 2 [99.995% <= X < 100%] will display 99.99%
;    1 = yes.

;It makes use of the RAM defined as "!Scratchram_CharacterTileTable"
;And writes them to OAM.

incsrc "../StatusBarRoutinesDefines/Defines.asm"
incsrc "../SharedSub_Defines/SubroutineDefs.asm"

!Default_RAMToDisplay = $60
;^[2 bytes] Displays the decimal number of this RAM when displaying X or X/Y.
;^[4 bytes] A frame counter when set to display a timer.
!Default_RAMToDisplay2 = $62
;^[2 bytes] Second number to display, if enabled by !NumberDisplayType
;^[Not used] when using the timer display.

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
	LDA !extra_byte_1,x
	CMP #$02
	BEQ .PercentageDisplayMode
	CMP #$03
	BNE +
	JMP .TimerDisplayMode
	+
	.OneOrTwoDigitsMode
		;PHX				;>Preserve sprite index
		PHY				;>Preserve sprite OAM index
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
		PHX
		LDX $15E9|!addr
		LDA !extra_byte_1,x
		PLX
		CMP #$00			;>Compare with A, not X.
		BEQ ..SkipSecondNumber
		
		..SecondNumber
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
		..SkipSecondNumber
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
		;PLX				;>Restore sprite index
		LDX $15E9|!addr
		JMP .DrawBodyOfSprite
	.PercentageDisplayMode
		;PHX		;>Preserve sprite slot index
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
			LDX $15E9|!addr
			LDA !extra_byte_2,x
			STA !Scratchram_PercentageFixedPointPrecision
			JSL !ConvertToPercentage			;>$00-$03: Percentage (fixed point)
			LDX $15E9|!addr
		;Cap at 100
			LDA !extra_byte_3,x
			AND.b #%00000001
			BEQ ..NoCap
			..Cap
				PHY					;>Preserve rouding flag
				REP #$30
				LDA !extra_byte_2,x
				AND #$00FF
				ASL
				TAY
				LDA PercentageMaximums,y
				TAY
				...HighWord
					LDA $02		;>If highword is any nonzero value, then the 32-bit is greater than 65536 ($00010000), which is guaranteed to be over 100/1000/10000.
					BNE ...Cap100
				...LowWord
					TYA
					CMP $00
					BCS ...Under100
				...Cap100
					TYA
					STA $00
				...Under100
				SEP #$30
				PLY					;>Restore rounding flag
			..NoCap
		;Round away from 0 and 100
			LDX $15E9|!addr					;>Not sure if changing the index 8/16bit mode would destroy this, but here just in case.
			LDA !extra_byte_3,x
			AND.b #%00000010
			BNE +
			
			CPY #$01					;\Avoid rounding to 0
			BNE +						;|
			REP #$20					;|
			LDA #$0001					;|
			STA $00						;|
			STZ $02						;|
			SEP #$20					;/
			+
			
			LDA !extra_byte_3,x
			AND.b #%00000100
			BNE +
			
			CPY #$02					;\Avoid rounding to 100
			BNE +						;|
			REP #$20					;|
			DEC $00						;|
			STZ $02						;|
			SEP #$20					;/
			+
		;Display the number
			JSL !SixteenBitHexDecDivision
			;Since we are dealing with OAM, and at the start of each frame, it clears the OAM (Ypos = $F0),
			;we don't need to clear a space since it is already done.
			LDX $15E9|!addr
			LDA !extra_byte_2,x
			LDX #$00
			CMP #$00			;>Compare with A, not X.
			BEQ ..DisplayWhole100
			CMP #$01
			BEQ ..DisplayOneTenths
			CMP #$02
			BEQ ..DisplayOneHundredths
			
			..DisplayWhole100
				JSL !SupressLeadingZeros
				BRA +
			..DisplayOneTenths
				LDA #$0D
				STA $09
				JSL !SupressLeadingZerosPercentageLeaveLast2
				BRA +
			..DisplayOneHundredths
				LDA #$0D
				STA $09
				JSL !SupressLeadingZerosPercentageLeaveLast3
			+
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
			LDX $15E9|!addr
			;PLX				;>Restore sprite slot index
			JML .DrawBodyOfSprite
		;Display timer
		.TimerDisplayMode
			PHY							;>Preserve OAM Y index
			LDA $00							;\Preserve OAM XY position relative to screen
			PHA							;|
			LDA $01							;|
			PHA							;/
			REP #$20
			LDA !Default_RAMToDisplay
			STA $00
			LDA !Default_RAMToDisplay+2
			STA $02
			SEP #$20
			JSL !Frames2Timer
			..Hours
				LDX $15E9|!addr
				LDA !extra_byte_1,x
				CMP #$03
				BEQ ..Minutes
				
				LDA !Scratchram_Frames2TimeOutput
				JSL !EightBitHexDec
				PHA					;STX $XXXXXX does not work.
				TXA
				STA !Scratchram_CharacterTileTable
				PLA
				STA !Scratchram_CharacterTileTable+1
				...ColonAfterHour
					LDA #$0E
					STA !Scratchram_CharacterTileTable+2
				
			..Minutes
				LDA !Scratchram_Frames2TimeOutput+1
				JSL !EightBitHexDec
				PHA					;STX $XXXXXX does not work.
				TXA
				STA !Scratchram_CharacterTileTable
				PLA
				STA !Scratchram_CharacterTileTable+1
				...ColonAfterMinutes
					LDA #$0E
					STA !Scratchram_CharacterTileTable+2
			..Seconds
				LDA !Scratchram_Frames2TimeOutput+2
				JSL !EightBitHexDec
				PHA
				TXA
				STA !Scratchram_CharacterTileTable+3
				PLA
				STA !Scratchram_CharacterTileTable+4
			..DecimalPoint
				LDA #$0D
				STA !Scratchram_CharacterTileTable+5
			..CentiSeconds
				LDA !Scratchram_Frames2TimeOutput+3
				JSL !EightBitHexDec
				PHA
				TXA
				STA !Scratchram_CharacterTileTable+6
				PLA
				STA !Scratchram_CharacterTileTable+7
			..PrepareOAM
				PLA				;\Get back OAM XY pos
				STA $01				;|
				PLA				;|
				STA $00				;/
				PLY				;>Get back the Y index of OAM
				...XYPos
					LDA #$08
					STA $03
					LDX #$08
					JSL !GetStringXPositionCentered
					LDA $01					;\Y position
					CLC					;|
					ADC #$10				;/
					STA $03					;>$03 = Y pos
				..NumberOfTiles
					LDA #$07
					STA $04
				..Properties
					LDA.b #%00110001
					STA $05
				..TableGraphic
					LDA.b #GraphicTable		;\conversion table from numbers to graphic numbers
					STA $06				;|
					LDA.b #GraphicTable>>8		;|
					STA $07				;|
					LDA.b #GraphicTable>>16		;|
					STA $08				;/
				JSL !WriteStringAsSpriteOAM
			..Done
				LDX $15E9|!addr
	.DrawBodyOfSprite
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
PercentageMaximums:
	dw 100		;>Index $00 ($00): 100%
	dw 1000		;>Index $01 ($02): 100.0%
	dw 10000	;>Index $02 ($04): 100.00%
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
	db $8E				;>Index $0E = for the ":" graphic