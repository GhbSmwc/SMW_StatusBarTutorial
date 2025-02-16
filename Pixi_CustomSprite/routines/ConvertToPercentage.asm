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
			%ConvertToPercentageRoundDown()
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