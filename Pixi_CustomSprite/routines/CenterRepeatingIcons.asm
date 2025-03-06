;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Center repeating icons. This is for "WriteRepeatedIconsAsOAM" To
;find the midpoint between the XY position of the first and last
;icon. This is needed to center this around a given point.
;
;Formula:
;
; PositionOfFirstIcon(X, Y) = ((Input_Center_X - ((TotalIcons-1)*X_displacement)/2), (Input_Center_Y - ((TotalIcons-1)*Y_displacement)/2))
;
;Which is processed in this order for optimization purposes:
;
; XOrYPositionOfFirstIcon = ((((TotalIcons-1)*Displacement)/2) * -1) + InputCenter
;
;InputCenter = Given center point as the input.
;TotalIcons = Total number of icons (max).
;Displacement = (signed) displacement between each icon.
;
;Input:
; - $02: X position of the point to center with (signed, you can take $00/$01,
;   offset it (add by some number), and write on here), relative to screen border.
; - $03: Same as above but Y position
; - $04: X Displacement for each icon (signed)
; - $05: Y Displacement for each icon (signed)
; - $06: Max/total number of icons.
;Output:
; - $02: X position for the repeated icons to be centered (signed).
; - $03: same as above but for Y.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?CenterRepeatingIcons:
	PHY
	LDY #$01
	?.Loop
		LDA $06				;\No icons = no using this formula
		BEQ ?.Done			;/
		DEC A				;>(TotalIcons-1)
		?..Multiplying			;>...Multiply by displacement
		if !sa1 == 0
			STA $4202		;>Multiplicand A
			LDA $0004|!dp,y		;>Displacement
			BPL ?...Positive
			?...Negative			;>TotalIcons (positive) * Displacement (negative)
				EOR #$FF
				INC A
				STA $4203		;>Multiplicand B
				JSR ?.WaitCalculation
				REP #$20
				LDA $4216		;>Product
				LSR			;
				SEP #$20		;
				;We skip EOR INC since double-negative cancels out
				BRA ?..WriteOutput
			?...Positive			;>TotalIcons (positive) * Displacement (positive)
				STA $4203		;>Multiplicand B
				JSR ?.WaitCalculation
				REP #$20
				LDA $4216		;>Product
				LSR			;>/2
				SEP #$20		;\*-1
				EOR #$FF		;|
				INC A			;/
		else
			PHX
			LDX #$00			;\Multiply mode
			STX $2250			;/
			PLX
			STA $2251			;\Multiplicand A (total icons, unsigned)
			STZ $2252			;/
			LDA $0004|!dp,y			;\Multiplicand B (displacement, signed)
			BMI ?...NegativeMultiplicandB
			
			?...PositiveMultiplicandB
				STA $2253
				STZ $2254		;>Upon writing this byte, it should calculate in 5 cycles.
				BRA ?...SignedHandlerDone
			?...NegativeMultiplicandB
				STA $2253
				LDA #$FF
				STA $2254		;>Upon writing this byte, it should calculate in 5 cycles.
			?...SignedHandlerDone
			NOP				;\Wait 5 cycles
			BRA $00				;/
			LDA $2306			;>Product (SA-1 multiplication are signed)
			BPL ?...Positive
			?...Negative			;>TotalIcons (positive) * Displacement (negative)
				EOR #$FF		;\Negative number divided by positive 2, then times -1
				INC A			;|Since we already inverted the number in the process of dividing by 2
				LSR			;|we don't need to convert it back (this is unoptimized since last two inverters cancel out: EOR #$FF : INC A : LSR : EOR #$FF INC A : EOR #$FF INC A)
				;EOR #$FF		;|(LSR shifts the bit to the right, and that alone would not correctly take a negative number and divide by 2)
				;INC A			;/
				BRA ?..WriteOutput
			?...Positive			;>TotalIcons (positive) * Displacement (positive)
				LSR			;>/2
				EOR #$FF		;\*-1
				INC A			;/
		endif
		?..WriteOutput
			CLC			;\+InputCenter
			ADC $02|!dp,y		;/
			STA $02|!dp,y		;>Output
			DEY
			BPL ?.Loop
	
	?.Done
	PLY
	RTL
	if !sa1 == 0
		?.WaitCalculation:	;>The register to perform multiplication and division takes 8/16 cycles to complete.
		RTS
	endif