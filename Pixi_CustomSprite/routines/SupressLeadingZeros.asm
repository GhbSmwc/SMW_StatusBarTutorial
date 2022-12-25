	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Suppress Leading zeros via left-aligned positioning
	;
	;This routine takes a 16-bit unsigned integer (works up to 5 digits),
	;suppress leading zeros and moves the digits so that the first non-zero
	;digit number is located where X is indexed to. Example: the number 00123
	;with X = $00:
	;
	; [0] [0] [1] [2] [3]
	;
	; Each bracketed item is a byte storing a digit. The X above means the X
	; index position.
	; After this routine is done, they are placed in an address defined
	; as "!Scratchram_CharacterTileTable" like this:
	;
	;              X
	; [1] [2] [3] [*] [*]...
	;
	; [*] Means garbage and/or unused data. X index is now set to $03, shown
	; above.
	;
	;Usage:
	; Input:
	;  -!Scratchram_16bitHexDecOutput to !Scratchram_16bitHexDecOutput+4 = a 5-digit 0-9 per byte (used for
	;   1-digit per 8x8 tile, using my 4/5 hexdec routine; ordered from high to low digits)
	;  -X = the starting location within the table to place the string in. X=$00 means the starting byte.
	; Output:
	;  -!Scratchram_CharacterTileTable = A table containing a string of numbers with
	;   unnecessary spaces and zeroes stripped out.
	;  -X = the location to place string AFTER the numbers (increments every character written). Also use
	;   for indicating the last digit (or any tile) number for how many tiles to be written to the status
	;   bar, overworld border, etc.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	?SupressLeadingZeros:
		LDY #$00				;>Start looking at the leftmost (highest) digit
		LDA #$00				;\When the value is 0, display it as single digit as zero
		STA !Scratchram_CharacterTileTable,x	;/(gets overwritten should nonzero input exist)

		?.Loop
			LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\If there is a leading zero, move to the next digit to check without moving the position to
			BEQ ?..NextDigit					;/place the tile in the table
		
			?..FoundDigit
				LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\Place digit
				STA !Scratchram_CharacterTileTable,x	;/
				INX					;>Next string position in table
				INY					;\Next digit
				CPY #$05				;|
				BCC ?..FoundDigit			;/
				RTL
		
			?..NextDigit
				INY			;>1 digit to the right
				CPY #$05		;\Loop until no digits left (minimum is 1 digit)
				BCC ?.Loop		;/
				INX			;>Next item in table
				RTL