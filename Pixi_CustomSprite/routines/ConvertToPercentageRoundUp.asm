	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;A variant of ConvertToPercentage, rounds up.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		?ConvertToPercentageRoundUp:
			%ConvertToPercentageRoundDown()
			REP #$20
			LDA $04				;\If remainder 0 (result is exact integer), don't increment
			BEQ ?.NoRoundUp			;/
			?.RoundUp
			INC $00				;>Quotient+1
			LDA !Scratchram_PercentageFixedPointPrecision
			TAX
			LDA.l ?.PercentageFixedPointScaling,x	;>The "Maximum", which is 100, 1000 (100.x), or 10000 (100.xx)
			LDY #$00				;>Default Y=$00 (not rounded)
			CMP $00					;\If not rounded up to maximum, leave Y=$00
			BNE ?.NoRoundToMax			;/
			LDY #$02				;>Otherwise indicate a round up to 100 with Y=$02
			?.NoRoundToMax
			?.NoRoundUp
			SEP #$20
			RTL
			
			?.PercentageFixedPointScaling
				dw 100		;>Integer not scaled at all
				dw 1000		;>Scaled by 1/10 to display the tenths place
				dw 10000	;>Scaled by 1/100 to display the hundredths place.