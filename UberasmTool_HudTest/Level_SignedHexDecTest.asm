;This ASM file demonstrates the display of two's complement signed numbers.
;Note: This does not support leading spaces between the sign and the non-leading zero digit, edit yourself if you somehow want this.

;Don't touch these unless you know what you're doing
	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	incsrc "../StatusBarRoutinesDefines/StatusBarDefines.asm"

;You can modify these
	!NumberOfDigitsDisplayed_SixteenBit = 5
	!NumberOfDigitsDisplayed_ThirtyTwoBit = 10

	!SuppressLeadingZeroes = 2
		;^This only applies to 16-bit numbers or more:
		; 0 = No, keep leading zeroes
		; 1 = Yes, and left-aligned
		; 2 = Yes, and right-aligned

	!ShowPostiveSign = 0
		;^0 = Don't display a plus sign when positive
		; 1 = Display when positive

	!NumberDisplayType = 3
		;^0 = 8-bit 2-digit
		; 1 = 8-bit 3-digit
		; 2 = 16-bit, Number of digits = !NumberOfDigitsDisplayed_SixteenBit
		; 3 = 32-bit, Number of digits = !NumberOfDigitsDisplayed_ThirtyTwoBit

;Don't touch these
	!NumberOfTilesUsed = 3 ;A signed character and 2 digits
	if !NumberDisplayType == 1
		!NumberOfTilesUsed = 4 ;Signed character and 3 digits
	elseif !NumberDisplayType == 2
		!NumberOfTilesUsed = !NumberOfDigitsDisplayed_SixteenBit+1 ;5 digits, plus sign character
	else
		!NumberOfTilesUsed = !NumberOfDigitsDisplayed_ThirtyTwoBit+1 ;1-10 digits, plus sign character
	endif
	
	!RAMToRead = !Freeram_ValueDisplay1_1Byte
	!NumberSize = 0 ;8-bit
	if !NumberDisplayType == 2
		!RAMToRead = !Freeram_ValueDisplay1_2Bytes
		!NumberSize = 1 ;16-bit
	elseif !NumberDisplayType == 3
		!RAMToRead = !Freeram_ValueDisplay1_4Bytes
		!NumberSize = 2 ;32-bit
	endif
	
	!StatusBarPos_ClearLocation_Tile = !StatusBar_TestDisplayElement_Pos_Tile
	!StatusBarPos_ClearLocation_Prop = !StatusBar_TestDisplayElement_Pos_Prop
	if !SuppressLeadingZeroes == 2
		!StatusBarPos_ClearLocation_Tile = !StatusBar_TestDisplayElement_RightAlignedText_Pos_Tile-((!NumberOfTilesUsed-1)*!StatusbarFormat)
		!StatusBarPos_ClearLocation_Prop = !StatusBar_TestDisplayElement_RightAlignedText_Pos_Prop-((!NumberOfTilesUsed-1)*!StatusbarFormat)
	endif
;Code
main:
	PHB
	PHK
	PLB
	;Controller number test
		LDA $15				;>%byetUDLR
		if !NumberSize == 0
			LSR #2				;>%00byetUD
			AND.b #%00000011		;>%000000UD
		else
			LSR				;>%0byetUDL
			AND.b #%00000110		;>%00000UD0
		endif
		TAY
		if !NumberSize == 0
			LDA !RAMToRead
			CLC
			ADC ControllerIncrementDecrement,y
			STA !RAMToRead
		else
			REP #$20
			LDA !RAMToRead
			CLC
			ADC ControllerIncrementDecrement,y
			STA !RAMToRead
			if !NumberSize == 2
				LDA !RAMToRead+2
				ADC ControllerIncrementDecrementHighWord,y
				STA !RAMToRead+2
			endif
			SEP #$20
		endif
	;Clear tiles and properties
		LDX.b #(!NumberOfTilesUsed-1)*2
		-
		LDA #!StatusBarBlankTile
		STA !StatusBarPos_ClearLocation_Tile,x
		if !StatusBar_UsingCustomProperties
			LDA #!StatusBar_TileProp
			STA !StatusBarPos_ClearLocation_Prop,x
		endif
		DEX #!StatusbarFormat
		BPL -
	
	if !NumberSize == 0
		;8-bits here
		LDA !RAMToRead
		if !NumberDisplayType == 0
			JSL HexDec_EightBitHexDec2DigitsSigned
			STA !StatusBar_TestDisplayElement_Pos_Tile+(2*2)
			TXA
			STA !StatusBar_TestDisplayElement_Pos_Tile+(1*2)
			LDA NumberSignSymbols,y
			STA !StatusBar_TestDisplayElement_Pos_Tile+(0*2)
		elseif !NumberDisplayType == 1
			JSL HexDec_EightBitHexDec3DigitsSigned
			STA !StatusBar_TestDisplayElement_Pos_Tile+(3*2)
			TXA
			STA !StatusBar_TestDisplayElement_Pos_Tile+(2*2)
			TYA
			STA !StatusBar_TestDisplayElement_Pos_Tile+(1*2)
			LDY $00
			LDA NumberSignSymbols,y
			STA !StatusBar_TestDisplayElement_Pos_Tile+(0*2)
		endif
	else
		;16-bits or more (stored into scratch RAM as an input prior calling signed HexDec)
		wdm
		REP #$20
		LDA !RAMToRead
		STA $00
		if !NumberSize == 2
			LdA !RAMToRead+2
			STA $02
		endif
		SEP #$20
		if !NumberSize == 1
			JSL HexDec_SixteenBitHexDecDivisionSigned
			.StatusBarWrite
				if !SuppressLeadingZeroes == 0
					;Leading zeroes, fixed location
					LDA NumberSignSymbols,y
					STA !StatusBar_TestDisplayElement_Pos_Tile
					
					if !StatusbarFormat == $01
						LDX.b #(!NumberOfDigitsDisplayed_SixteenBit-1)
						-
						LDA.b !Scratchram_16bitHexDecOutput+$04-(!NumberOfDigitsDisplayed_SixteenBit-1),x
						STA !StatusBar_TestDisplayElement_Pos_Tile+!StatusbarFormat,x
						DEX
						BPL -
					else
						LDX.b #((!NumberOfDigitsDisplayed_SixteenBit-1)*2)
						LDY.b #(!NumberOfDigitsDisplayed_SixteenBit-1)
						-
						LDA.w !Scratchram_16bitHexDecOutput+$04-(!NumberOfDigitsDisplayed_SixteenBit-1)|!dp,y
						STA !StatusBar_TestDisplayElement_Pos_Tile+!StatusbarFormat,x
						DEY
						DEX #2
						BPL -
					endif
				else
					;No leading zeroes, aligned
					.WriteToString
						LDX #$00					;>Start of string
						CPY #$01					;\If sign is zero, skip writing the sign character
						BEQ ..NoSign					;/
						if !ShowPostiveSign == 0
							CPY #$02
							BEQ ..NoSign
						endif
						LDA NumberSignSymbols,y				;\Otherwise if negative or positive, insert sign character
						STA !Scratchram_CharacterTileTable,x		;|
						INX						;/
						..NoSign
						JSL HexDec_SuppressLeadingZeros
						CPX.b #!NumberOfTilesUsed+1			;\Failsafe to avoid writing more characters than intended would write onto tiles
						BCS .TooMuchChar				;/not being cleared from the previous code.
						if !SuppressLeadingZeroes == 1
							LDA.b #!StatusBar_TestDisplayElement_Pos_Tile : STA $00
							LDA.b #!StatusBar_TestDisplayElement_Pos_Tile>>8 : STA $01
							LDA.b #!StatusBar_TestDisplayElement_Pos_Tile>>16 : STA $02
							if !StatusBar_UsingCustomProperties != 0
								LDA.b #!StatusBar_TestDisplayElement_Pos_Prop : STA $03
								LDA.b #!StatusBar_TestDisplayElement_Pos_Prop>>8 : STA $04
								LDA.b #!StatusBar_TestDisplayElement_Pos_Prop>>16 : STA $05
								LDA.b #!StatusBar_TileProp
								STA $06
							endif
						elseif !SuppressLeadingZeroes == 2
							LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Tile : STA $00		;\Set address to write at a given status bar position.
							LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Tile>>8 : STA $01		;|
							LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Tile>>16 : STA $02		;/
							if !StatusBar_UsingCustomProperties != 0
								LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Prop : STA $03	;\Set address to write at a given status bar position.
								LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Prop>>8 : STA $04	;|
								LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Prop>>16 : STA $05	;/
								LDA.b #!StatusBar_TileProp
								STA $06
							endif
							if !StatusbarFormat == $01							;\These offset the write position based on how many
								JSL HexDec_ConvertToRightAligned					;|characters so that it is right-aligned.
							else
								JSL HexDec_ConvertToRightAlignedFormat2					;|$00-$02 will now contain the location of the leftmost tile.
							endif										;/
						endif
						if !StatusbarFormat == $01
							JSL HexDec_WriteStringDigitsToHUD
						else
							JSL HexDec_WriteStringDigitsToHUDFormat2
						endif
						.TooMuchChar
				endif
		elseif !NumberSize == 2
			;32-bits
			JSL HexDec_ThirtyTwoBitHexDecDivisionSigned
			if !SuppressLeadingZeroes == 0
				;Leading zeroes, fixed location
				LDA NumberSignSymbols,y
				STA !StatusBar_TestDisplayElement_Pos_Tile
				
				if !StatusbarFormat == $01
					LDX.b #(!NumberOfDigitsDisplayed_ThirtyTwoBit-1)
					-
					LDA !Scratchram_32bitHexDecOutput+(!Setting_32bitHexDec_MaxNumberOfDigits-1)-(!NumberOfDigitsDisplayed_ThirtyTwoBit-1),x
					STA !StatusBar_TestDisplayElement_Pos_Tile+!StatusbarFormat,x
					DEX
					BPL -
				else
					LDX #((!NumberOfDigitsDisplayed_ThirtyTwoBit-1)*2)
					LDY #(!NumberOfDigitsDisplayed_ThirtyTwoBit-1)
					-
					PHX
					TYX						;>Sigh, LDA $xxxxxx,y does not exist.
					LDA !Scratchram_32bitHexDecOutput+(!Setting_32bitHexDec_MaxNumberOfDigits-1)-(!NumberOfDigitsDisplayed_ThirtyTwoBit-1),x
					PLX
					STA !StatusBar_TestDisplayElement_Pos_Tile+!StatusbarFormat,x
					DEY
					DEX #2
					BPL -
				endif
			else
				;No leading zeroes, aligned
				.WriteToString
					LDX #$00					;>Start of string
					CPY #$01					;\If sign is zero, skip writing the sign character
					BEQ ..NoSign					;/
					if !ShowPostiveSign == 0
						CPY #$02
						BEQ ..NoSign
					endif
					LDA NumberSignSymbols,y				;\Otherwise if negative or positive, insert sign character
					STA !Scratchram_CharacterTileTable,x		;|
					INX						;/
					..NoSign
					JSL HexDec_SuppressLeadingZeros32Bit
					CPX.b #!NumberOfTilesUsed+1			;\Failsafe to avoid writing more characters than intended would write onto tiles
					BCS .TooMuchChar				;/not being cleared from the previous code.
					if !SuppressLeadingZeroes == 1
						LDA.b #!StatusBar_TestDisplayElement_Pos_Tile : STA $00
						LDA.b #!StatusBar_TestDisplayElement_Pos_Tile>>8 : STA $01
						LDA.b #!StatusBar_TestDisplayElement_Pos_Tile>>16 : STA $02
						if !StatusBar_UsingCustomProperties != 0
							LDA.b #!StatusBar_TestDisplayElement_Pos_Prop : STA $03
							LDA.b #!StatusBar_TestDisplayElement_Pos_Prop>>8 : STA $04
							LDA.b #!StatusBar_TestDisplayElement_Pos_Prop>>16 : STA $05
							LDA.b #!StatusBar_TileProp
							STA $06
						endif
					elseif !SuppressLeadingZeroes == 2
						LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Tile : STA $00		;\Set address to write at a given status bar position.
						LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Tile>>8 : STA $01		;|
						LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Tile>>16 : STA $02		;/
						if !StatusBar_UsingCustomProperties != 0
							LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Prop : STA $03	;\Set address to write at a given status bar position.
							LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Prop>>8 : STA $04	;|
							LDA.b #!StatusBar_TestDisplayElement_RightAlignedText_Pos_Prop>>16 : STA $05	;/
							LDA.b #!StatusBar_TileProp
							STA $06
						endif
						if !StatusbarFormat == $01							;\These offset the write position based on how many
							JSL HexDec_ConvertToRightAligned					;|characters so that it is right-aligned.
						else
							JSL HexDec_ConvertToRightAlignedFormat2					;|$00-$02 will now contain the location of the leftmost tile.
						endif										;/
					endif
					if !StatusbarFormat == $01
						JSL HexDec_WriteStringDigitsToHUD
					else
						JSL HexDec_WriteStringDigitsToHUDFormat2
					endif
				.TooMuchChar
			endif
		endif
	endif
	PLB
	RTL
	
	NumberSignSymbols:
	db !StatusBarMinusSymbol
	db !StatusBarBlankTile
	if !ShowPostiveSign
		db !StatusBarPlusSymbol
	else
		db !StatusBarBlankTile
	endif
	ControllerIncrementDecrement:
	if !NumberSize == 0
		db $00 ;>%00000000 ($00)
		db $FF ;>%00000001 ($01)
		db $01 ;>%00000010 ($02)
		db $00 ;>%00000011 ($03)
	else
		dw $0000 ;>%00000000 ($00)
		dw $FFFF ;>%00000010 ($02)
		dw $0001 ;>%00000100 ($04)
		dw $0000 ;>%00000110 ($06)
		if !NumberSize == 2
			ControllerIncrementDecrementHighWord:
				dw $0000 ;>%00000000 ($00)
				dw $FFFF ;>%00000010 ($02)
				dw $0000 ;>%00000100 ($04)
				dw $0000 ;>%00000110 ($06)
		endif
	endif