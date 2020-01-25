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
		LDX #$00
	.Loops
		CMP #$0A
		BCC .Return
		SBC #$0A			;>A #= A MOD 10
		INX				;>X #= floor(A/10)
		BRA .Loops
	.Return
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;16-bit hex to 4 (or 5)-digit decimal subroutine
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
		
	SixteenBitHexDec:
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