	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	?SupressLeadingZerosPercentageLeaveLast3:
		;XXX.XX%
		LDY #$00
		
		?.Loop
			CPY #$02					;\Avoid skipping the last three digits
			BCS ?..FoundDigit				;/
			LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\If there is a leading zero, move to the next digit to check without moving the position to
			BEQ ?..NextDigit					;/place the tile in the table
		
			?..FoundDigit
				LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\Place digit
				STA !Scratchram_CharacterTileTable,x		;/
				INX						;>Next string position in table
				INY						;\Write next digit
				CPY #$03					;|
				BCC ?..FoundDigit				;/
				LDA $09						;\Write decimal point (".")
				STA !Scratchram_CharacterTileTable,x		;/
				INX
				LDA !Scratchram_16bitHexDecOutput+$03		;\Write tenths place.
				STA !Scratchram_CharacterTileTable,x		;/
				INX
				LDA !Scratchram_16bitHexDecOutput+$04		;\Write hundredths place.
				STA !Scratchram_CharacterTileTable,x		;/
				INX
				RTL
		
			?..NextDigit
				INY			;>1 digit to the right
				CPY #$03		;\Loop until no digits left (minimum is 1 digit)
				BCC ?.Loop		;/
				INX			;>Next item in table
				RTL