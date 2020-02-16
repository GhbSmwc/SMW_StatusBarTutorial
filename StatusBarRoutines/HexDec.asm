incsrc "../StatusBarRoutinesDefines/Defines.asm"
;Routines list:
;HexDec routines:
; -EightBitHexDec
; -EightBitHexDec3Digits
; -SixteenBitHexDecDivision
; -MathDiv
; -Convert32bitIntegerToDecDigits
; -MathDiv32_16
;Leading zeroes remover:
; -RemoveLeadingZeroes16Bit
; -RemoveLeadingZeroes32Bit
;Overworld:
; -SixteenBitHexDecDivisionToOWB
; -ThirtyTwoBitHexDecDivisionToOWB
;Leading zeroes remover:
; -SupressLeadingZeros
; -ConvertToRightAligned
; -ConvertToRightAlignedFormat2
;Aligned digit to OWB digits:
; -Convert16BitAlignedDigitToOWB
;Write to status bar or overworld border:
; -WriteStringDigitsToHUD
; -WriteStringDigitsToHUDFormat2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;HexDec routines.
;Converts a given number to binary-coded-decimal
;(unpacked) digits.
;For testing purposes, insert this file to Uberasm Tool's
;libary folder.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Functions like this:
	;Divide the given number by 10 using euclidean division with remainder
	;(since a division register/routine isn't used, repeated subtraction is
	;used instead to emulate division w/ remainder).
	;The remainder is the 1s place, and the quotient is the 10s place.
	;
	;Input: A = 8-bit value (0-255)
	;Output:
	; A = 1s place
	; X = 10s place
	;
	;To display 3-digits (include the 100s place), after getting the ones place
	;written, use TXA, and then call the routine again. After that, X is the 100s
	;place and A is the 10s place.
	; Example:
	;  LDA <RAMtoDisplay>
	;  JSL HexDec_EightBitHexDec
	;  STA <StatusBarOnesPlace>
	;  TXA
	;  JSL HexDec_EightBitHexDec
	;  STA <StatusBarTensPlace>
	;  TXA					;>Again, STX $xxxxxx don't exist.
	;  STA <StatusBarHundredsPlace>
	; Note that this is slow with big numbers (200-255 the slowest),
	; as since it will subtract by 10 repeatedly and ONLY by 10 to get the ones place,
	; example using 255:
	;  A=255 SubtractionBy10_InXIndex: 0
	;  A=245 SubtractionBy10_InXIndex: 1
	;  A=235 SubtractionBy10_InXIndex: 2
	;  ...(22 loops later)...
	;  A=15 SubtractionBy10_InXIndex = 24
	;  A=5  SubtractionBy10_InXIndex = 25 -> A = 1s place (5), X = 10s place (25, out of 0-9 range)
	; Routine called again with X -> A:
	;  A=25 SubtractionBy10_InXIndex = 0
	;  A=15 SubtractionBy10_InXIndex = 1
	;  A=5  SubtractionBy10_InXIndex = 2  -> A = 10s place (5), X = 100s place (2)
	; As a result, a total of 27 repeated loops (25 total loops to get the 1s place
	; 2 loops to get the 10s and 100s)
	; Consider using [EightBitHexDec3Digits] below here.
	EightBitHexDec:
		LDX #$00
		.Loops
			CMP #$0A
			BCC .Return
			SBC #$0A			;>A #= A MOD 10
			INX				;>X #= floor(A/10)
			BRA .Loops
		.Return
			RTL
	
	;This is a bit faster than calling [EightBitHexDec] twice. Done by subtracting by 100
	;repeatedly first, then 10s, and after that, the ones are done.
	; Y = 100s
	; X = 10s
	; A = 1s
	;
	;Example: A=$FF (255):
	; 255 -> 155 -> 55 Subtracted 2 times, so 100s place is 2 (goes into Y).
	; 55 -> 45 -> 35 -> 25 -> 15 -> 5 Subtracted 5 times, so 10s place is 5 (in X).
	; 5 is already the ones place for A.
	;As a result, a total of 7 repeated loops (2 for 100s, plus 5 for the 10s), vs 27
	;of calling [EightBitHexDec] twice.
	EightBitHexDec3Digits:
		LDX #$00			;\Start the counter at 0.
		LDY #$00			;/
		.LoopSub100
			CMP.b #100		;\Y counts how many 100s until A cannot be subtracted by 100 anymore
			BCC .LoopSub10		;/
			SBC.b #100		;>Subtract and...
			INY			;>Count how many 100s.
			BRA .LoopSub100		;>Keep counting until less than 100
		.LoopSub10
			CMP.b #10		;\X counts how many 10s until A cannot be subtracted by 10 anymore
			BCC .Return		;/A will automatically be the 1s place.
			SBC.b #10		;>Subtract and...
			INX			;>Count how many 10s
			BRA .LoopSub10		;>Keep counting until less than 10.
		.Return
			RTL
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;16-bit hex to 4 (or 5)-digit decimal subroutine (using right-2-left
	;division).
	;Input:
	; $00-$01 = the value you want to display
	;Output:
	; !Scratchram_16bitHexDecOutput to !Scratchram_16bitHexDecOutput+4 = a digit 0-9 per byte table
	; (used for 1-digit per 8x8 tile):
	; +$00 = ten thousands
	; +$01 = thousands
	; +$02 = hundreds
	; +$03 = tens
	; +$04 = ones
	;
	;!Scratchram_16bitHexDecOutput is address $02 for normal ROM and $04 for SA-1.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
		SixteenBitHexDecDivision:
			if !sa1 == 0
				PHX
				PHY

				LDX #$04	;>5 bytes to write 5 digits.

				.Loop
				REP #$20	;\Dividend (in 16-bit)
				LDA $00		;|
				STA $4204	;|
				SEP #$20	;/
				LDA.b #10	;\base 10 Divisor
				STA $4206	;/
				JSR .Wait	;>wait
				REP #$20	;\quotient so that next loop would output
				LDA $4214	;|the next digit properly, so basically the value
				STA $00		;|in question gets divided by 10 repeatedly. [Value/(10^x)]
				SEP #$20	;/
				LDA $4216	;>Remainder (mod 10 to stay within 0-9 per digit)
				STA $02,x	;>Store tile

				DEX
				BPL .Loop

				PLY
				PLX
				RTL

				.Wait
				JSR ..Done		;>Waste cycles until the calculation is done
				..Done
				RTS
			else
				PHX
				PHY

				LDX #$04

				.Loop
				REP #$20			;>16-bit XY
				LDA.w #10			;>Base 10
				STA $02				;>Divisor (10)
				SEP #$20			;>8-bit XY
				JSL MathDiv			;>divide
				LDA $02				;>Remainder (mod 10 to stay within 0-9 per digit)
				STA.b !Scratchram_16bitHexDecOutput,x	;>Store tile

				DEX
				BPL .Loop

				PLY
				PLX
				RTL
			endif


		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; unsigned 16bit / 16bit Division
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Arguments
		; $00-$01 : Dividend
		; $02-$03 : Divisor
		; Return values
		; $00-$01 : Quotient
		; $02-$03 : Remainder
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		MathDiv:	REP #$20
				ASL $00
				LDY #$0F
				LDA.w #$0000
		-		ROL A
				CMP $02
				BCC +
				SBC $02
		+		ROL $00
				DEY
				BPL -
				STA $02
				SEP #$20
				RTL

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;32-bit hex-dec (using right-2-left division)
	;input:
	;-$00-$03 = the 32-bit number, in little endian, example:
	; $11223344 ([$44,$33,$22,$11]) should output 287454020.
	;
	;output:
	;-[!Scratchram_32bitHexDecOutput] to [!Scratchram_32bitHexDecOutput+(!MaxNumberOfDigits-1)]:
	; Contains value 0-9 on every byte, in decreasing significant digits (last byte is always
	; the 1s place). Formula to get what RAM of a given digit:
	;
	; !Scratchram_32bitHexDecOutput+(!MaxNumberOfDigits-1)-(DigitIndex)
	;
	; Where DigitIndex is an integer ranging from 0 to !MaxNumberOfDigits-1, representing what digit with 0
	; being the ones, 2 being 10s, and so on:
	; DigitValue = 0: 1s place (ex. w/ 6 digits: $7F8453)
	; DigitValue = 1: 10s place (ex. w/ 6 digits: $7F8452)
	; DigitValue = 2: 100s place (ex. w/ 6 digits: $7F8451)
	; DigitValue = 3: 1000s place (ex. w/ 6 digits: $7F8450)
	; [...]
	; DigitValue = 5: 100000s place (ex. w/ 6 digits: $7F844E)
	;
	;Overwritten
	;-$04 to $05: because remainder of the division.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			Convert32bitIntegerToDecDigits:
			LDX.b #!MaxNumberOfDigits-1
			
			.Loop
			LDA.b #10				;\divide by 10 (the radix)
			STA $04					;|
			STZ $05					;/
			JSL MathDiv32_16			;>divide.
			LDA $04					;\write remainder digit (obviously shouldn't exceed 255)
			STA !Scratchram_32bitHexDecOutput,x	;/
			
			..Next
			DEX					;\loop until all digits are written
			BPL .Loop				;/
			RTL
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Unsigned 32bit / 16bit Division
	; By Akaginite (ID:8691), fixed the overflow
	; bitshift by GreenHammerBro (ID:18802)
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Arguments
	; $00-$03 : Dividend
	; $04-$05 : Divisor
	; Return values
	; $00-$03 : Quotient
	; $04-$05 : Remainder
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	MathDiv32_16:	REP #$20
			ASL $00
			ROL $02
			LDY #$1F
			LDA.w #$0000
	-		ROL A
			BCS +
			CMP $04
			BCC ++
	+		SBC $04
			SEC
	++		ROL $00
			ROL $02
			DEY
			BPL -
			STA $04
			SEP #$20
			RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Leading zeroes remover.
;Writes $FC on all leading zeroes (except the 1s place),
;Therefore, numbers will have leading spaces instead.
;
;Example: 00123 ([$00, $00, $01, $02, $03]) becomes
; __123 ([$FC, $FC, $01, $02, $03])
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;16-bit version, use with [SixteenBitHexDecDivision]
		RemoveLeadingZeroes16Bit:
		LDX #$00				;>Start at the leftmost digit
		
		.Loop
		LDA !Scratchram_16bitHexDecOutput,x			;\if current digit non-zero, don't omit trailing zeros for the rest of the number string.
		BNE .NonZero				;/
		LDA #!StatusBarBlankTile				;\blank tile to replace leading zero
		STA !Scratchram_16bitHexDecOutput,x			;/
		INX					;>next digit
		CPX.b #$04				;>last digit to check. So that it can display a single 0.
		BCC .Loop				;>if not done yet, continue looping.
		
		.NonZero
		RTL
	;32-bit version, use with [Convert32bitIntegerToDecDigits]
		RemoveLeadingZeroes32Bit:
		LDX #$00				;>Start at the leftmost digit
		
		.Loop
		LDA !Scratchram_32bitHexDecOutput,x	;\if current digit non-zero, don't omit trailing zeros for the rest of the number string.
		BNE .NonZero				;/
		LDA #!StatusBarBlankTile				;\blank tile to replace leading zero
		STA !Scratchram_32bitHexDecOutput,x	;/
		INX					;>next digit
		CPX.b #!MaxNumberOfDigits-1		;>last digit to check. So that it can display a single 0.
		BCC .Loop				;>if not done yet, continue looping.
		
		.NonZero
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Overworld digit converter.
;
;Converts decimal digits to OW graphic digits:
;StatusBar tile numb:	OWB tile numb:		Description:
;Tile $00		Tile $22		Digit tile ("0")
;Tile $01		Tile $23		Digit tile ("1")
;Tile $02		Tile $24		Digit tile ("2")
;Tile $03		Tile $25		Digit tile ("3")
;Tile $04		Tile $26		Digit tile ("4")
;Tile $05		Tile $27		Digit tile ("5")
;Tile $06		Tile $28		Digit tile ("6")
;Tile $07		Tile $29		Digit tile ("7")
;Tile $08		Tile $2A		Digit tile ("8")
;Tile $09		Tile $2B		Digit tile ("9")
;Tile $FC		Tile $1F		Blank tile
;Tile $29		Tile $91		Slash tile ("/")
;Note that the displaying of symbols are on page 1, not page 0, and the palette of the OWB is palette 6.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Convert 16-bit number to OWB digits.
	;Usage with other routines:
	;	JSL SixteenBitHexDecDivision
	;	JSL RemoveLeadingZeroes16Bit		;>Omit this if you want to display leading zeroes
	;	JSL SixteenBitHexDecDivisionToOWB
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		SixteenBitHexDecDivisionToOWB:
		LDX #$04
		
		.Loop
		LDA !Scratchram_16bitHexDecOutput,x
		CMP #!StatusBarBlankTile
		BEQ ..Blank
		
		..Digit
		CLC
		ADC #$22
		BRA ..Write
		
		..Blank
		LDA #$1F
		
		..Write
		STA !Scratchram_16bitHexDecOutput,x
		DEX
		BPL .Loop
		RTL
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Convert 32-bit number to OWB digits.
	;Usage with other routines:
	;	JSL SixteenBitHexDecDivision
	;	JSL RemoveLeadingZeroes32Bit		;>Omit this if you want to display leading zeroes
	;	JSL SixteenBitHexDecDivisionToOWB
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		ThirtyTwoBitHexDecDivisionToOWB:
		LDX.b #!MaxNumberOfDigits-1
		
		.Loop
		LDA !Scratchram_32bitHexDecOutput,x
		CMP #!StatusBarBlankTile
		BEQ ..Blank
		
		..Digit
		CLC
		ADC #$22
		BRA ..Write
		
		..Blank
		LDA #$1F
		
		..Write
		STA !Scratchram_32bitHexDecOutput,x
		DEX
		BPL .Loop
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Leading zeroes remover, to convert numbers to left/right-aligned display.
;Before using these routines, make sure you manually write all the tiles to tile $FC on where you are going to
;place your display space, as these routines alone DO NOT clear any tiles, else you'll left with duplicate or
;"ghost" tiles that are meant to disappear when the digits shifts.
;
;An example with left-aligned is "10", when changed into a 9, it ends up displaying "90" because the 1s wasn't
;cleared.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Suppress Leading zeros via left-aligned positioning
	;
	;This routines takes a 16-bit unsigned integer (works up to 5 digits),
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
	;  -X = the location within the table to place the string in. X=$00 means the starting byte.
	; Output:
	;  -!Scratchram_CharacterTileTable = A table containing a string of numbers with
	;   unnecessary spaces and zeroes stripped out.
	;  -X = the location to place string AFTER the numbers. Also use for
	;   indicating the last digit (or any tile) number for how many tiles to
	;   be written to the status bar, overworld border, etc.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	SupressLeadingZeros:
		LDY #$00				;>Start looking at the leftmost (highest) digit
		LDA #$00				;\When the value is 0, display it as single digit as zero
		STA !Scratchram_CharacterTileTable,x	;/(gets overwritten should nonzero input exist)

		.Loop
		LDA.w !Scratchram_16bitHexDecOutput|!dp,Y		;\If there is a leading zero, move to the next digit to check without moving the position to
		BEQ ..NextDigit				;/place the tile in the table
		
		..FoundDigit
		LDA.w !Scratchram_16bitHexDecOutput|!dp,Y		;\Place digit
		STA !Scratchram_CharacterTileTable,x	;/
		INX					;>Next string position in table
		INY					;\Next digit
		CPY #$05				;|
		BCC ..FoundDigit			;/
		RTL
		
		..NextDigit
		INY			;>1 digit to the right
		CPY #$05		;\Loop until no digits left (minimum is 1 digit)
		BCC .Loop		;/
		INX			;>Next item in table
		RTL
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Convert left-aligned to right-aligned.
	;
	;Use this routine after calling SupressLeadingZeros and before calling
	;WriteStringDigitsToHUD. Note: Be aware that the math of handling the address
	;does NOT account to changing the bank byte (address $XX****), so be aware of
	;having status bar tables that crosses bank borders ($7EFFFF, then $7F0000,
	;as an made-up example, but its unlikely though). This routine basically takes
	;a given RAM address stored in $00-$02, subtract by how many tiles (minus 1), then
	;$00-$02 is now the left tile position.
	;
	;Input:
	; -$00-$02 = 24-bit address location to write to status bar tile number.
	; -If tile properties are edit-able:
	; --$03-$05 = Same as $00-$02 but tile properties.
	; -X = The number of characters to write, ("123" would have X = 3)
	;Output:
	; -$00-$02 and $03-$05 are subtracted by [(NumberOfCharacters-1)*!StatusbarFormat]
	;  so that the last character is always at a fixed location and as the number
	;  of characters increase, the string would extend leftwards. Therefore,
	;  $00-$02 and $03-$05 before calling this routine contains the ending address
	;  which the last character will be written.
	;
	;Note:
	; -ConvertToRightAligned is designed for [TTTTTTTT, TTTTTTTT,...], [YXPCCCTT, YXPCCCTT,...]
	; -ConvertToRightAlignedFormat2 is designed for [TTTTTTTT, YXPCCCTT, TTTTTTTT, YXPCCCTT...]
	; -This routine is meant to be used when displaying 2 numbers (For example: 123/456). Since
	;  when displaying a single number, using HexDec and removing leading zeroes (turns them
	;into leading spaces) is automatically right-aligned, using this routine is pointless.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ConvertToRightAligned:
		TXA
		DEC
		TAY					;>Transfer status bar leftmost position to Y
		BRA +
	ConvertToRightAlignedFormat2:
		TXA
		DEC
		ASL
		TAY					;>Transfer status bar leftmost position to Y
		+
		REP #$21				;\-(NumberOfTiles-1)...
		AND #$00FF				;|
		EOR #$FFFF				;|
		INC A					;/
		ADC $00					;>...+LastTilePos (we are doing LastTilePos - (NumberOfTiles-1))
		STA $00					;>Store difference in $00-$01
		SEP #$20				;\Handle bank byte
	;	LDA $02					;|
	;	SBC #$00				;|
	;	STA $02					;/
		
		if !StatusBar_UsingCustomProperties != 0
			TYA
			DEC
			ASL
			REP #$21				;\-(NumberOfTiles-1)
			AND #$00FF				;|
			EOR #$FFFF				;|
			INC A					;/
			ADC $03					;>+LastTilePos (we are doing LastTilePos - (NumberOfTiles-1))
			STA $03					;>Store difference in $00-$01
			SEP #$20				;\Handle bank byte
	;		LDA $05					;|
	;		SBC #$00				;|
	;		STA $05					;/
		endif
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Aligned digit to OWB digits
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Convert 16-bit number that has its leading zeroes suppressed (also left-aligned)
	;to OWB digits
	;Input:
	;X = Number of characters in the string
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Convert16BitAlignedDigitToOWB:
		PHX
		DEX
		.Loop
		LDA !Scratchram_CharacterTileTable,x
		CMP #$0A
		BCC .Digits
		CMP #!StatusBarBlankTile
		BEQ .Blank
		CMP #$29
		BEQ .Slash
		
		.Slash
		LDA #$91
		BRA .Write
		
		.Blank
		LDA #$1F
		BRA .Write
		
		.Digits
		CLC
		ADC #$22
		
		.Write
		STA !Scratchram_CharacterTileTable,x
		
		..Next
		DEX
		BPL .Loop
		PLX
		RTL
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Convert 32-bit number that has its leading zeroes suppressed (also left-aligned)
	;to OWB digits
	;Input:
	;X = Number of characters in the string
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Convert32BitAlignedDigitToOWB:
		PHX
		DEX
		.Loop
		LDA !Scratchram_CharacterTileTable,x
		CMP #$0A
		BCC .Digits
		CMP #!StatusBarBlankTile
		BEQ .Blank
		CMP #$29
		BEQ .Slash
		
		.Slash
		LDA #$91
		BRA .Write
		
		.Blank
		LDA #$1F
		BRA .Write
		
		.Digits
		CLC
		ADC #$22
		
		.Write
		STA !Scratchram_CharacterTileTable,x
		
		..Next
		DEX
		BPL .Loop
		PLX
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Misc routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Write aligned digits to Status bar/OWB+
	;
	;Input:
	; -$00-$02 = 24-bit address location to write to status bar tile number.
	; -If tile properties are edit-able:
	; --$03-$05 = Same as $00-$02 but tile properties.
	; --$06 = the tile properties, for all tiles.
	; -X = The number of characters to write, ("123" would have X = 3)
	;
	;Note:
	; -WriteStringDigitsToHUD is designed for [TTTTTTTT, TTTTTTTT,...], [YXPCCCTT, YXPCCCTT,...]
	; -WriteStringDigitsToHUDFormat2 is designed for [TTTTTTTT, YXPCCCTT, TTTTTTTT, YXPCCCTT...]
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	WriteStringDigitsToHUD:
		DEX
		TXY
		
		.Loop
		LDA !Scratchram_CharacterTileTable,x
		STA [$00],y
		if !StatusBar_UsingCustomProperties != 0
			LDA $06
			STA [$03],y
		endif
		DEX
		DEY
		BPL .Loop
		RTL
	WriteStringDigitsToHUDFormat2:
		DEX
		TXA				;\SSB and OWB+ uses a byte pair format.
		ASL				;|
		TAY				;/
		
		.Loop
		LDA !Scratchram_CharacterTileTable,x
		STA [$00],y
		if !StatusBar_UsingCustomProperties != 0
			LDA $06
			STA [$03],y
		endif
		DEX
		DEY #2
		BPL .Loop
		RTL