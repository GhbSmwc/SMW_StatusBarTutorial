	incsrc "../StatusBarRoutinesDefines/Defines.asm"
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
	?EightBitHexDec:
		LDX #$00
		?.Loops
			CMP #$0A
			BCC ?.Return
			SBC #$0A			;>A #= A MOD 10
			INX				;>X #= floor(A/10)
			BRA ?.Loops
		?.Return
			RTL