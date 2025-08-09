	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Same as above, but this is for fixed-point numbers.
	;Input for fixed-point numbers:
	; - $09: Character number for decimal point, for status bar (by default), it
	;   must be #$24 for sprite OAM prior calling WriteStringAsSpriteOAM, it
	;   must be #$0D.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	?SuppressLeadingZerosPercentageLeaveLast2:
		;XXX.X% (XXXX.X%)
		LDY #$00
		?.Loop
			CPY #$03					;\Avoid skipping the last two digits (force to write the last two digits, ones and tenths)
			BCS ?..FoundDigit				;/
			LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\If there is a leading zero, move to the next digit to check without moving the position to
			BEQ ?..NextDigit					;/place the tile in the table
		
			?..FoundDigit
				LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\Place digit
				STA !Scratchram_CharacterTileTable,x		;/
				INX						;>Next string position in table
				INY						;\Write next digit
				CPY #$04					;|
				BCC ?..FoundDigit				;/
				LDA $09						;\Write decimal point (".")
				STA !Scratchram_CharacterTileTable,x		;/
				INX
				LDA !Scratchram_16bitHexDecOutput+$04		;\Write tenths place.
				STA !Scratchram_CharacterTileTable,x		;/
				INX
				RTL
		
			?..NextDigit
				INY			;>1 digit to the right
				CPY #$04		;\Loop until no digits left (minimum is 1 digit)
				BCC ?.Loop		;/
				INX			;>Next item in table
				RTL