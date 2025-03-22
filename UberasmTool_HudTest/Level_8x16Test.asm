;This ASM code demonstrates the function of 8x16 number graphic. This graphic is used by the bonus stars counter.
;Note that because each character occupies 2 8x8 tiles instead of 1 8x8, 2 lines are needed, and that is where
;!Scratchram_CharacterTileTable_Line2 is involved here to handle a second line. This only supports 1 or 2 16-bit
;numbers. W wouldn't want to include every variations of this else it would be too much.

;Notes:
; - In this ASM resource's default state, it only supports level layer 3 tiles. Sprite OAM tiles can only be 8x8
;   or 16x16. Technically the SNES does allow other dimensions, but will apply to all 128 slots rather than per
;   slot.
; -- Another problem with OAM is that if you're going for 16x16 pixel tiles to fit 8x16 pixel  characters, you
;    end up wasting tiles as the top-right and bottom-right of the 2x2 square cannot be used (else you have
;    garbage to the right of every character).
; -- If you are going for just 8x8 tiles with each character occupying 2 OAM slots placed vertically, well, its
;    roughly double the amount of OAM tiles (some of the top and bottom half of the number reuses previous
;    graphics, such as the top-half of "2" and "3" and the bottom half of "0" and "6") used and the tiles on the
;    8x8 editor compared to a single line of characters being 8x8s.
;

;Don't touch
	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	incsrc "../StatusBarRoutinesDefines/StatusBarDefines.asm"
;Settings you can modify
	!DisplayTwoNumbers = 0
		;^0 = 1 number
		; 1 = 2 numbers
	!NumberOfDigitsDisplayed = 5							;>How many digits, enter 1-5 (pointless if you enter less than 3).

;Don't touch unless you know what you're doing
	!StatusBar_TestDisplayElement_Pos_Tile_BottomLine = !StatusBar_TestDisplayElement_Pos_Tile+(32*!StatusbarFormat)
	!StatusBar_TestDisplayElement_Pos_Prop_BottomLine = !StatusBar_TestDisplayElement_Pos_Prop+(32*!StatusbarFormat)
	
	!StringLength = !NumberOfDigitsDisplayed
	if !DisplayTwoNumbers != 0
		!StringLength = (!NumberOfDigitsDisplayed*2)+1
	endif

	main:
	.NumberDisplayTest
	;Clear the tiles. To prevent leftover "ghost" tiles that should've
	;disappear when the number of digits decreases (so when "10" becomes "9",
	;won't display "90"). Also setup tile properties when enabled.
		LDX.b #(!StringLength-1)*!StatusbarFormat
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
		;First number
			REP #$20						;\Convert a given number to decimal digits.
			LDA !Freeram_ValueDisplay1_2Bytes			;|
			STA $00							;|
			SEP #$20						;|
			JSL HexDec_SixteenBitHexDecDivision			;/
			LDX #$00					;>Start at character position 0.
			JSL HexDec_SupressLeadingZeros			;>Write the digits (without leading zeroes) starting at position 0.
			if !DisplayTwoNumbers != 0
				;slash
					LDA #!StatusBarSlashCharacterTileNumb		;\Slash symbol.
					STA !Scratchram_CharacterTileTable,x		;/
					INX						;>Next character position.
				
				;Second number
					PHX							;>Push X because it gets modified by the HexDec routine.
					REP #$20						;\Convert a given number to decimal digits.
					LDA !Freeram_ValueDisplay2_2Bytes			;|
					STA $00							;|
					SEP #$20						;|
					JSL HexDec_SixteenBitHexDecDivision			;/
					PLX							;>Restore.
					JSL HexDec_SupressLeadingZeros				;>Write the digits (without leading zeroes) starting at after the slash symbol.
			endif
			CPX.b #!StringLength+1							;\Failsafe to avoid writing more characters than intended would write onto tiles
			BCS ..TooMuchDigits							;/not being cleared from the previous code.
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