incsrc "../StatusBarRoutinesDefines/Defines.asm"
;Routines list:
;General math routines:
; -MathDiv
; -MathDiv32_16
; -MathMul16_16
;HexDec routines:
; -EightBitHexDec
; -EightBitHexDec3Digits
; -SixteenBitHexDecDivision
; -Convert32bitIntegerToDecDigits
;Leading zeroes remover (leading spaces):
; -RemoveLeadingZeroes16Bit
; -RemoveLeadingZeroes32Bit
; -RemoveLeadingZeroes16BitLeaveLast2
; -RemoveLeadingZeroes16BitLeaveLast3
;Overworld:
; -SixteenBitHexDecDivisionToOWB
; -ThirtyTwoBitHexDecDivisionToOWB
;Leading zeroes remover (left or aligned digits):
; -SupressLeadingZeros
; -SupressLeadingZerosPercentageLeaveLast2
; -SupressLeadingZerosPercentageLeaveLast3
; -ConvertToRightAligned
; -ConvertToRightAlignedFormat2
;Aligned digit to OWB digits:
; -Convert16BitAlignedDigitToOWB
;Write to status bar or overworld border:
; -WriteStringDigitsToHUD
; -WriteStringDigitsToHUDFormat2
;Misc:
; -Frames2Timer
; -ConvertToPercentage
; -CountingAnimation16Bit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;General math routines.
;Due to the fact that registers have limitations and such.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
	if !sa1 == 0
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; 16bit * 16bit unsigned Multiplication
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Argusment
		; $00-$01 : Multiplicand
		; $02-$03 : Multiplier
		; Return values
		; $04-$07 : Product
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
		MathMul16_16:	REP #$20
				LDY $00
				STY $4202
				LDY $02
				STY $4203
				STZ $06
				LDY $03
				LDA $4216
				STY $4203
				STA $04
				LDA $05
				REP #$11
				ADC $4216
				LDY $01
				STY $4202
				SEP #$10
				CLC
				LDY $03
				ADC $4216
				STY $4203
				STA $05
				LDA $06
				CLC
				ADC $4216
				STA $06
				SEP #$20
				RTL
	else
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; 16bit * 16bit unsigned Multiplication SA-1 version
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Argusment
		; $00-$01 : Multiplicand
		; $02-$03 : Multiplier
		; Return values
		; $04-$07 : Product
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
		MathMul16_16:	STZ $2250
				REP #$20
				LDA $00
				STA $2251
				ASL A
				LDA $02
				STA $2253
				BCS +
				LDA.w #$0000
		+		BIT $02
				BPL +
				CLC
				ADC $00
		+		CLC
				ADC $2308
				STA $06
				LDA $2306
				STA $04
				SEP #$20
				RTL
	endif
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
	;32-bit hex-dec (using right-2-left division)
	;input:
	;-$00-$03 = the 32-bit number, in little endian, example:
	; $11223344 ([$44,$33,$22,$11]) should output 287454020.
	; Maximum value is 4,294,967,295.
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Leading zeroes remover.
;Writes $FC on all leading zeroes (except the 1s place),
;Therefore, numbers will have leading spaces instead.
;
;Example: 00123 ([$00, $00, $01, $02, $03]) becomes
; __123 ([$FC, $FC, $01, $02, $03])
;
;Call this routine after using: [Convert32bitIntegerToDecDigits]
;or [SixteenBitHexDecDivision].
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;16-bit version, use after [SixteenBitHexDecDivision]
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
	;16-bit version, use after [SixteenBitHexDecDivision]. This one leaves out the last two digits, this is so that
	;for displaying fixed-point numbers, will not wipe out the ones and tenths place for displaying a percentage of
	;XXX.X%.
		RemoveLeadingZeroes16BitLeaveLast2:
		LDX #$00				;>Start at the leftmost digit
		
		.Loop
		LDA !Scratchram_16bitHexDecOutput,x			;\if current digit non-zero, don't omit trailing zeros for the rest of the number string.
		BNE .NonZero				;/
		LDA #!StatusBarBlankTile				;\blank tile to replace leading zero
		STA !Scratchram_16bitHexDecOutput,x			;/
		INX					;>next digit
		CPX.b #$03				;>last digit to check. So that it can display a single 0.
		BCC .Loop				;>if not done yet, continue looping.
		
		.NonZero
		RTL
	;Same as before, but leaves the last 3 digits.
		RemoveLeadingZeroes16BitLeaveLast3:
		LDX #$00				;>Start at the leftmost digit
		
		.Loop
		LDA !Scratchram_16bitHexDecOutput,x			;\if current digit non-zero, don't omit trailing zeros for the rest of the number string.
		BNE .NonZero				;/
		LDA #!StatusBarBlankTile				;\blank tile to replace leading zero
		STA !Scratchram_16bitHexDecOutput,x			;/
		INX					;>next digit
		CPX.b #$02				;>last digit to check. So that it can display a single 0.
		BCC .Loop				;>if not done yet, continue looping.
		
		.NonZero
		RTL
	;32-bit version, use after [Convert32bitIntegerToDecDigits]
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
;Every time you use these subroutines, make sure you blank out the tiles manually (such as setting them to $FC)
;beforehand on where you are going to place your display, as these routines alone DO NOT clear any tiles.
;This means you'll end up with leftover "ghost" tiles that are meant to disappear when the string shortens: An
;example with left-aligned is "10", when changed into a 9, it ends up displaying "90".
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
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
	SupressLeadingZeros:
		LDY #$00				;>Start looking at the leftmost (highest) digit
		LDA #$00				;\When the value is 0, display it as single digit as zero
		STA !Scratchram_CharacterTileTable,x	;/(gets overwritten should nonzero input exist)

		.Loop
			LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\If there is a leading zero, move to the next digit to check without moving the position to
			BEQ ..NextDigit					;/place the tile in the table
		
			..FoundDigit
				LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\Place digit
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
	;Same as above, but this is for fixed-point numbers.
	;Input for fixed-point numbers:
	; -$09: Character number for decimal point, for status bar (by default), it
	;  must be #$24 for sprite OAM prior calling WriteStringAsSpriteOAM, it
	;  must be #$0D.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	SupressLeadingZerosPercentageLeaveLast2:
		;XXX.X% (XXXX.X%)
		LDY #$00
		.Loop
			CPY #$03					;\Avoid skipping the last two digits (force to write the last two digits, ones and tenths)
			BCS ..FoundDigit				;/
			LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\If there is a leading zero, move to the next digit to check without moving the position to
			BEQ ..NextDigit					;/place the tile in the table
		
			..FoundDigit
				LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\Place digit
				STA !Scratchram_CharacterTileTable,x		;/
				INX						;>Next string position in table
				INY						;\Write next digit
				CPY #$04					;|
				BCC ..FoundDigit				;/
				LDA $09						;\Write decimal point (".")
				STA !Scratchram_CharacterTileTable,x		;/
				INX
				LDA !Scratchram_16bitHexDecOutput+$04		;\Write tenths place.
				STA !Scratchram_CharacterTileTable,x		;/
				INX
				RTL
		
			..NextDigit
				INY			;>1 digit to the right
				CPY #$04		;\Loop until no digits left (minimum is 1 digit)
				BCC .Loop		;/
				INX			;>Next item in table
				RTL
	SupressLeadingZerosPercentageLeaveLast3:
		;XXX.XX%
		LDY #$00
		
		.Loop
			CPY #$02					;\Avoid skipping the last three digits
			BCS ..FoundDigit				;/
			LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\If there is a leading zero, move to the next digit to check without moving the position to
			BEQ ..NextDigit					;/place the tile in the table
		
			..FoundDigit
				LDA.w !Scratchram_16bitHexDecOutput|!dp,Y	;\Place digit
				STA !Scratchram_CharacterTileTable,x		;/
				INX						;>Next string position in table
				INY						;\Write next digit
				CPY #$03					;|
				BCC ..FoundDigit				;/
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
		
			..NextDigit
				INY			;>1 digit to the right
				CPY #$03		;\Loop until no digits left (minimum is 1 digit)
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
	;  into leading spaces) is automatically right-aligned, using this routine is pointless.
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
		CMP #!StatusBarSlashCharacterTileNumb
		BEQ .Slash
		
		.Slash
		LDA #!OverWorldBorderSlashCharacterTileNumb
		BRA .Write
		
		.Blank
		LDA #!OverWorldBorderBlankTile
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
	; -!Scratchram_CharacterTileTable-(!Scratchram_CharacterTileTable+N-1)
	;  the string to write to the status bar.
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

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Convert 32-bit frame counter to timer, By GreenHammerBro
	; This routine converts a 32-bit frame counter into 
	; hours:minutes:seconds.centiseconds format.
	;
	; Note: This assumes that the frame counter increments every 1/60th of a second.
	; The routine functions like this:
	; 1. FrameWithinSeconds = 32BitFrame MOD 60 ;>This will get a number 0-59 within a second (aka. jiffysecond)
	; 2. Seconds = Floor(32BitFrame/60) MOD 60 ;>This will get a number 0-59 within a minute.
	; 3. Minute = Floor(Seconds/60) MOD 60 ;>This will get a number 0-59 within an hour
	; 4. Hour = Floor(Minute/60) ;>This will get a number 0-255 for the hour
	; 5. To convert FrameWithinSeconds to CentiSeconds (uses cross-multiply):
	;
	;  CentiSeconds = RoundHalfUp(FrameWithinSeconds * 100/60)
	;
	; This is different from imamelia's timer, as each byte stored is in each unit and are
	; incremented individually (if frames hits 60, INC the seconds, if seconds hit 60, increment minute and so on).
	; Which that makes it hard if you want to have things that affect the timer like adding and subtracting.
	;
	; Template for making a user-friendly countdown timer:
	;	!StartTimerHour = 0
	;	!StartTimerMinute = 3
	;	!StartTimerSeconds = 30
	;
	;	REP #$20
	;	LDA.w #(!StartTimerHour*216000)+(!StartTimerMinute*3600)+(!StartTimerSeconds*60)
	;	STA !RAMToMeasure
	;	LDA.w #(!StartTimerHour*216000)+(!StartTimerMinute*3600)+(!StartTimerSeconds*60)>>16
	;	STA !RAMToMeasure+2
	;	SEP #$20
	;
	;Input:
	;-$00 to $03: the frame value (little endian!).
	;Output:
	;-!Scratchram_Frames2TimeOutput (4 bytes): timer in real world
	; units format:
	; -!Scratchram_Frames2TimeOutput+0 = hour
	; -!Scratchram_Frames2TimeOutput+1 = minutes
	; -!Scratchram_Frames2TimeOutput+2 = seconds
	; -!Scratchram_Frames2TimeOutput+3 = centiseconds (display 00 to 99 (actually 00-98 because 59/60 = 0.98[3]))
	;Overwritten:
	;-$00 to $05 was used by division routine
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Frames2Timer:
		LDX #$03
		
		.Loop
		CPX #$00					;\After writing the hours, don't overwrite the hours part.
		BEQ .ConvertFramesToCentiseconds		;/
		REP #$20					;\divide by 60
		LDA.w #60					;|
		STA $04						;|
		SEP #$20					;/
		JSL MathDiv32_16				;>$00 = quotient (increases every 60 units), $04 = remainder (counter loops 00-59)

		CPX #$01					;\allow hours to go above 59
		BNE .NonHours					;/
		
		LDA $00						;\Upon dividing minutes by 60, the quotient is the hour, however due to how the loop works,
		STA !Scratchram_Frames2TimeOutput		;/after dividing, it writes the remainder first, then take the quotient for the next loop of the next unit.
		
		.NonHours
		LDA $04						;\store looped value (frames, seconds and minutes loop 00-59)
		STA !Scratchram_Frames2TimeOutput,x		;/
		
		..Next
		DEX
		BRA .Loop
		
		.ConvertFramesToCentiseconds
		;simply put [Frames*100/60], highest [Frames*100 should be 5900] shouldn't overflow in unsigned 16-bit.
		if !sa1 == 0
			LDA !Scratchram_Frames2TimeOutput+3	;\Frames*100
			STA $4202				;|
			LDA.b #100				;|
			STA $4203				;/
			JSR WaitCalculation			;>Wait 12 cycles in total (8 is minimum needed)
			REP #$20
			LDA $4216				;>load product
			STA $4204				;>Product in dividend
			SEP #$20
			LDA.b #60				;\product divide by 60 (divisor)
			STA $4206				;/
			JSR WaitCalculation			;>Wait 12 cycles (16 is minimum needed)
			NOP #2					;>wait 4 cycles (16 cycles total)
			
			LDX $4214				;>quotient
			LDA $4216				;\if remainder is less than half the divisor, round down
		else
			STZ $2250				;\>multiply mode
			LDA !Scratchram_Frames2TimeOutput+3	;|Frames*100
			STA $2251				;|
			STZ $2252				;|
			LDA.b #100				;|
			STA $2253				;|
			STZ $2254				;/>this should start the calculation
			NOP					;\Wait 5 cycles
			BRA $00					;/
			REP #$20
			LDA $2306				;\backup the value in case of setting $2250 to divide
			STA $00					;/causes $2306 to lose its product
			LDX #$01				;\divide mode
			STX $2250				;/
			LDA $00					;\product divide by...
			STA $2251				;/
			SEP #$20
			LDA.b #60				;\60
			STA $2253				;/
			STZ $2254				;>this triggers the calculation to run
			NOP					;\Wait 5 cycles
			BRA $00					;/
			
			LDX $2306				;>Quotient
			LDA $2308
		endif
		CMP.b #30					;\If remainder less than half, then round downwards.
		BCC ..NoRound					;/
		
		..Round
		INX					;>round up quotient
		
		..NoRound
		TXA
		STA !Scratchram_Frames2TimeOutput+3
		RTL
		
		if !sa1 == 0
			WaitCalculation:	;>The register to perform multiplication and division takes 8/16 cycles to complete.
			RTS
		endif
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Convert fraction to percentage
	;Input:
	; !Scratchram_PercentageQuantity to !Scratchram_PercentageQuantity+1:
	;  The numerator of the fraction
	; !Scratchram_PercentageMaxQuantity to !Scratchram_PercentageMaxQuantity+1:
	;  The denominator of the fraction
	; !Scratchram_PercentageFixedPointPrecision:
	;  Precision, rather to convert the fraction to:
	;   $00 = out of 100 (display whole percentage).
	;   $01 = out of 1000 (display 1/10 precision (1 digit after decimal), can be converted to XXX.X% via fixed point)
	;   $02 = out of 10000 (display 1/100 precision (2 digits after decimal), can be converted to XXX.XX%, same as a above)
	;Output:
	; $00-$03: Percentage, using fixed-point notation (an integer here, then scaled by 1/(10**!Scratchram_PercentageFixedPointPrecision)),
	;          rounded 1/2 up to the nearest 1*10**(-!Scratchram_PercentageFixedPointPrecision). Using 32-bit unsigned integer to prevent
	;          potential overflow (mainly going beyond 65535) if your hack allows going higher than 100% and with higher
	;          !Scratchram_PercentageFixedPointPrecision precision. If the denominator is zero, will be 0% or 100% (division by zero).
	; Y register: Detect rounding to 0 or 100. Can be used to display 1% if exclusively between 0 and 1%
	;             and 99% if exclusively between 99 and 100%. This is useful for avoid misleading 0 and 100% displays when actually close
	;             to such numbers. This also applies to higher precision, but instead of by the ones place, it is actually the
	;             rightmost/last digit:
	;              Y=$00: no
	;              Y=$01: Rounded to 0 ([0 < X < 5*10**(-Precision)] would've round to 0% misleadingly)
	;              Y=$02: Rounded from 99 to 100 ([100-(5*10**(-Precision-1)) <= X < 100] would've round to 100% misleadingly)
	;Destroyed:
	; $06-$07: Needed to compare the remainder with half the denominator.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		ConvertToPercentage:
			LDA !Scratchram_PercentageFixedPointPrecision
			ASL
			TAX
			;First, do [Quantity * 100]
				REP #$20
				LDA !Scratchram_PercentageQuantity
				STA $00
				LDA.l .PercentageFixedPointScaling,x
				STA $02
				SEP #$20
				JSL MathMul16_16	;>$04 to $07 = product
			;And we divide by maxquantity.
				REP #$20
				LDA $04
				STA $00
				LDA $06
				STA $02
				LDA !Scratchram_PercentageMaxQuantity
				STA $04
				SEP #$20
				JSL MathDiv32_16	;>$00-$03 quotient, $04-$05 remainder
			;After dividing, quotient, currently rounded down is our (raw) percentage value
			;The remainder can be used to determine should the percentage value be rounded up.
				LDY #$00		;>Default Y = $00
				.RoundHalfUp
					..GetHalfDenominatorPoint
						REP #$20
						LDA !Scratchram_PercentageMaxQuantity	;\Half the denominator
						LSR					;/
						BCC ...NoRoundHalfPoint			
						
						...RoundHalfWayPoint
							INC				;>Round halfpoint upwards
						
						...NoRoundHalfPoint
				.CheckQuotientShouldRoundUp
					;You may be wondering, why am I handling this 16-bit?
					;Well this is to prevent overflow if your hack allows
					;displaying greater than 100%.
					CMP $04			;>Remainder
					BEQ ..RoundUp		;\If HalfPoint is >= Remainder (or Remainder is < HalfPoint), don't round up
					BCS ..NoRoundUp		;/
					..RoundUp
						LDA $00		;\Increment percentage value.
						CLC		;|
						ADC #$0001	;|
						STA $00		;|
						LDA $02		;|
						CLC		;|
						ADC #$0000	;|
						STA $02		;/
						
						...CheckIfRoundedUpTo100
							LDA $00					;\If not representing 100 on 32 bits, leave Y=$00.
							CMP.l .PercentageFixedPointScaling,x	;|
							BNE ..RoundDone				;|
							LDA $02					;|
							CMP #$0000				;|
							BNE ..RoundDone				;/
							LDY #$02
							BRA ..RoundDone
					..NoRoundUp
						...CheckIfRoundedDownTo0
							LDA $00			;\If 32-bit quotient is nonzero, then skip.
							ORA $02			;|
							BNE ..RoundDone		;/
							LDA $04			;\If remainder is at least 1, then the percentage should be between (exclusively)
							BEQ ..RoundDone		;/0 and 1%, however, here assumes the value would be in between (exclusive) 0 and 0.5%
							LDY #$01
					..RoundDone
						SEP #$20
						RTL
			.PercentageFixedPointScaling
				dw 100		;>Integer not scaled at all
				dw 1000		;>Scaled by 1/10 to display the tenths place
				dw 10000	;>Scaled by 1/100 to display the hundredths place.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Counting animation (uses "Mere display counting").
;
;Takes 2 numbers, "Actual" and "Gradual", and increments/decrements "Gradual"
;towards "Actual" at a rate (e.g per frame) proportional to the difference
;between actual and gradual (increments/decrements faster at greater differences).
;Calculated like this per execution of this routine (e.g per frame):
; To Increment (When Gradual is less than Actual):
;  Gradual += floor((Actual - Gradual)/Rate) + 1
; To decrement (when Gradual is greater than actual):
;  Gradual += floor((Gradual - Actual)/Rate) + 1
;
;Input:
;-$04-$06 (3 bytes): RAM address of the 16-bit number that is the "Actual"
; amount
;-$07-$09 (3 bytes): RAM address of the 16-bit number that is the "Gradual"
; which increases or decreases to the actual amount at a rate proportional how big the difference.
;-$0A (1 byte): The "change rate" per execution of this routine, higher
; number written here = slower.
;
;Output:
;RAM_stored_In_07: the updated display number
;
;Destroyed:
;$00-$03: Used for the division routine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CountingAnimation16Bit:
	REP #$20
	LDA [$04]
	CMP [$07]
	BEQ .NoChange
	BCS .ActualBigger
	
	.GradualBigger
		LDA [$07]						;\Difference (how far apart)
		SEC							;|
		SBC [$04]						;|
		STA $00							;/
		LDA $0A							;\The rate
		AND #$00FF						;|
		STA $02							;/
		JSL MathDiv						;When this routine finishes, A is 8-bit
		REP #$20
		INC $00
		LDA [$07]						;\Subtracting animation, subtracts faster
		SEC							;|the more far apart "Actual" and "Gradual" are.
		SBC $00							;|
		STA [$07]						;/
		BRA .NoChange
	.ActualBigger
		LDA [$04]						;\Difference (how far apart)
		SEC							;|
		SBC [$07]						;|
		STA $00							;/
		LDA $0A							;\The rate
		AND #$00FF						;|
		STA $02							;/
		JSL MathDiv						;When this routine finishes, A is 8-bit
		REP #$20
		INC $00
		LDA [$07]						;\Adding animation, subtracts faster
		CLC							;|the more far apart "Actual" and "Gradual" are.
		ADC $00							;|
		STA [$07]						;/
	.NoChange
	SEP #$20
	RTL