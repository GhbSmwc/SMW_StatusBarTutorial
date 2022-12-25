	incsrc "../StatusBarRoutinesDefines/Defines.asm"
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
		?ConvertToPercentage:
			LDA !Scratchram_PercentageFixedPointPrecision
			ASL
			TAX
			;First, do [Quantity * 100]
				REP #$20
				LDA !Scratchram_PercentageQuantity
				STA $00
				LDA.l ?.PercentageFixedPointScaling,x
				STA $02
				SEP #$20
				JSR ?MathMul16_16	;>$04 to $07 = product
			;And we divide by maxquantity.
				REP #$20
				LDA $04
				STA $00
				LDA $06
				STA $02
				LDA !Scratchram_PercentageMaxQuantity
				STA $04
				SEP #$20
				JSR ?MathDiv32_16	;>$00-$03 quotient, $04-$05 remainder
			;After dividing, quotient, currently rounded down is our (raw) percentage value
			;The remainder can be used to determine should the percentage value be rounded up.
				LDY #$00		;>Default Y = $00
				?.RoundHalfUp
					?..GetHalfDenominatorPoint
						REP #$20
						LDA !Scratchram_PercentageMaxQuantity	;\Half the denominator
						LSR					;/
						BCC ?...NoRoundHalfPoint			
						
						?...RoundHalfWayPoint
							INC				;>Round halfpoint upwards
						
						?...NoRoundHalfPoint
				?.CheckQuotientShouldRoundUp
					;You may be wondering, why am I handling this 16-bit?
					;Well this is to prevent overflow if your hack allows
					;displaying greater than 100%.
					CMP $04			;>Remainder
					BEQ ?..RoundUp		;\If HalfPoint is >= Remainder (or Remainder is < HalfPoint), don't round up
					BCS ?..NoRoundUp		;/
					?..RoundUp
						LDA $00		;\Increment percentage value.
						CLC		;|
						ADC #$0001	;|
						STA $00		;|
						LDA $02		;|
						CLC		;|
						ADC #$0000	;|
						STA $02		;/
						
						?...CheckIfRoundedUpTo100
							LDA $00					;\If not representing 100 on 32 bits, leave Y=$00.
							CMP.l ?.PercentageFixedPointScaling,x	;|
							BNE ?..RoundDone				;|
							LDA $02					;|
							CMP #$0000				;|
							BNE ?..RoundDone				;/
							LDY #$02
							BRA ?..RoundDone
					?..NoRoundUp
						?...CheckIfRoundedDownTo0
							LDA $00			;\If 32-bit quotient is nonzero, then skip.
							ORA $02			;|
							BNE ?..RoundDone		;/
							LDA $04			;\If remainder is at least 1, then the percentage should be between (exclusively)
							BEQ ?..RoundDone		;/0 and 1%, however, here assumes the value would be in between (exclusive) 0 and 0.5%
							LDY #$01
					?..RoundDone
						SEP #$20
						RTL
			?.PercentageFixedPointScaling
				dw 100		;>Integer not scaled at all
				dw 1000		;>Scaled by 1/10 to display the tenths place
				dw 10000	;>Scaled by 1/100 to display the hundredths place.

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
	
		?MathMul16_16:	REP #$20
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
				RTS
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
	
		?MathMul16_16:	STZ $2250
				REP #$20
				LDA $00
				STA $2251
				ASL A
				LDA $02
				STA $2253
				BCS ?+
				LDA.w #$0000
		?+		BIT $02
				BPL ?+
				CLC
				ADC $00
		?+		CLC
				ADC $2308
				STA $06
				LDA $2306
				STA $04
				SEP #$20
				RTS
	endif

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
	?MathDiv32_16:	REP #$20
			ASL $00
			ROL $02
			LDY #$1F
			LDA.w #$0000
	?-		ROL A
			BCS ?+
			CMP $04
			BCC ?++
	?+		SBC $04
			SEC
	?++		ROL $00
			ROL $02
			DEY
			BPL ?-
			STA $04
			SEP #$20
			RTS