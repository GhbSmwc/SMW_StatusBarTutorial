	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;A variant of ConvertToPercentage, rounds down.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		?ConvertToPercentageRoundDown:
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
				JSL %MathMul16_16()	;>$04 to $07 = product
			;And we divide by maxquantity.
				REP #$20
				LDA $04
				STA $00
				LDA $06
				STA $02
				LDA !Scratchram_PercentageMaxQuantity
				STA $04
				SEP #$20
				JSL %MathDiv32_16()	;>$00-$03 quotient, $04-$05 remainder
			;Check for if rounded to zero despite not being exactly zero
			?.RoundCheck
				LDY #$00
				REP #$20
				LDA $00			;\Quotient
				ORA $02			;/
				BNE ?..No		;>Quotient nonzero, then no changing Y
				LDA $04			;>Remainder
				BEQ ?..No		;>If Q=0 and R=0, then it is exactly zero.
				LDY #$01		;>Quotient being zero and remainder nonzero = between 0 and 1, therefore rounded to zero
				?..No
				SEP #$20
			RTL
			?.PercentageFixedPointScaling
				dw 100		;>Integer not scaled at all
				dw 1000		;>Scaled by 1/10 to display the tenths place
				dw 10000	;>Scaled by 1/100 to display the hundredths place.