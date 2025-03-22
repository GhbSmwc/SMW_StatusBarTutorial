incsrc "../StatusBarRoutinesDefines/Defines.asm"
incsrc "../StatusBarRoutinesDefines/StatusBarDefines.asm"

!NumberOfDigitsDisplayed = 5							;>How many digits, enter 1-5 (pointless if you enter less than 3).

;Don't touch
	!StatusBar_TestDisplayElement_Pos_Tile_BottomLine = !StatusBar_TestDisplayElement_Pos_Tile+(32*!StatusbarFormat)
	!StatusBar_TestDisplayElement_Pos_Prop_BottomLine = !StatusBar_TestDisplayElement_Pos_Prop+(32*!StatusbarFormat)

	main:
	.NumberDisplayTest
	;Clear the tiles. To prevent leftover "ghost" tiles that should've
	;disappear when the number of digits decreases (so when "10" becomes "9",
	;won't display "90"). Also setup tile properties when enabled.
		LDX.b #(!NumberOfDigitsDisplayed-1)*!StatusbarFormat
		-
		LDA #!StatusBarBlankTile
		STA !StatusBar_TestDisplayElement_Pos_Tile,x
		STA !StatusBar_TestDisplayElement_Pos_Tile_BottomLine,x
		if !StatusBar_UsingCustomProperties != 0
			LDA.b #!StatusBar_TileProp
			STA !StatusBar_TestDisplayElement_Pos_Prop,x
			STA !StatusBar_TestDisplayElement_Pos_Prop_BottomLine,x
		endif
		DEX #!StatusbarFormat
		BPL -
	;Number to string.
		;Process HexDec
			REP #$20						;\Convert a given number to decimal digits.
			LDA !Freeram_ValueDisplay1_2Bytes			;|
			STA $00							;|
			SEP #$20						;|
			JSL HexDec_SixteenBitHexDecDivision			;/
		;Remove leading zeroes and have it as a character table
			LDX #$00					;>Start at character position 0.
			JSL HexDec_SupressLeadingZeros			;>Write the digits (without leading zeroes) starting at position 0.
		;Prevent writing too much characters.
			CPX.b #!NumberOfDigitsDisplayed+1		;\Failsafe to avoid writing more characters than intended would write onto tiles
			BCS ..TooMuchDigits				;/not being cleared from the previous code.
		;Convert to 8x16 digits
			JSL HexDec_StringTo8x16Char
			
	;Write to status bar
		;Top half
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
			PHX
			if !StatusbarFormat == $01
				JSL HexDec_WriteStringDigitsToHUD
			else
				JSL HexDec_WriteStringDigitsToHUDFormat2
			endif
			PLX
		;Bottom half (since we are done with the top line, we can just transfer !Scratchram_CharacterTileTable_Line2 to
		;!Scratchram_CharacterTileTable without need of a near-identical routine to WriteStringDigitsToHUD )
			LDA.b #!StatusBar_TestDisplayElement_Pos_Tile_BottomLine : STA $00
			LDA.b #!StatusBar_TestDisplayElement_Pos_Tile_BottomLine>>8 : STA $01
			LDA.b #!StatusBar_TestDisplayElement_Pos_Tile_BottomLine>>16 : STA $02
			if !StatusBar_UsingCustomProperties != 0
				LDA.b #!StatusBar_TestDisplayElement_Pos_Prop_BottomLine : STA $03
				LDA.b #!StatusBar_TestDisplayElement_Pos_Prop_BottomLine>>8 : STA $04
				LDA.b #!StatusBar_TestDisplayElement_Pos_Prop_BottomLine>>16 : STA $05
				LDA.b #!StatusBar_TileProp
				STA $06
			endif
			PHX
			TXA
			DEC
			PHB
			REP #$30
				LDX.w #!Scratchram_CharacterTileTable_Line2
				LDY.w #!Scratchram_CharacterTileTable
				MVN (!Scratchram_CharacterTileTable_Line2>>16),(!Scratchram_CharacterTileTable>>16)
			SEP #$30
			PLB
			PLX
			wdm
			if !StatusbarFormat == $01
				JSL HexDec_WriteStringDigitsToHUD
			else
				JSL HexDec_WriteStringDigitsToHUDFormat2
			endif
	..TooMuchDigits
	RTL