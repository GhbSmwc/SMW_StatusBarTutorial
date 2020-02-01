;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;HexDec routines.
;Converts a given number to binary-coded-decimal
;(unpacked) digits.
;For testing purposes, insert this file to Uberasm Tool's
;libary folder.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EightBitHexDec:
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
		LDX #$00
	.Loops
		CMP #$0A
		BCC .Return
		SBC #$0A			;>A #= A MOD 10
		INX				;>X #= floor(A/10)
		BRA .Loops
	.Return
		RTL
	
EightBitHexDec3Digits:
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
; !HexDecDigitTable to !HexDecDigitTable+4 = a digit 0-9 per byte table
; (used for 1-digit per 8x8 tile):
; +$00 = ten thousands
; +$01 = thousands
; +$02 = hundreds
; +$03 = tens
; +$04 = ones
;
;!HexDecDigitTable is address $02 for normal ROM and $04 for SA-1.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	if read1($00FFD5) == $23	;\can be omitted if pre-included
		!sa1 = 1
		sa1rom
	else
		!sa1 = 0
	endif				;/

	!HexDecDigitTable = $02
	if !sa1 != 0
		!HexDecDigitTable = $04
	endif
		
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
			STA.b !HexDecDigitTable,x	;>Store tile

			DEX
			BPL .Loop

			PLY
			PLX
			RTL
		endif

	if !sa1 != 0
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
	endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;32-bit hex-dec (using right-2-left division)
;input:
;-$00-$03 = the 32-bit number, in little endian, example:
; $11223344 ([$44,$33,$22,$11]) should output 287454020.
;
;output:
;-!Scratchram_32bitHexDecOutput to (!Scratchram_32bitHexDecOutput+!MaxNumberOfDigits)-1:
; Contains value 0-9 on every byte, in big endian digits (last byte is the ones place).
; Formula to get what RAM of a given digit:
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
!MaxNumberOfDigits = 9
;^Number of digits to be stored. Up to 10 because maximum
; 32-bit unsigned integer is 4,294,967,295.

!Scratchram_32bitHexDecOutput = $7F844E
;^[bytes_used = !MaxNumberOfDigits] The output
; formatted each byte is each digit 0-9.
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