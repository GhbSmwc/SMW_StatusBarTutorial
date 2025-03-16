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

	?MathDiv:	REP #$20
			ASL $00
			LDY #$0F
			LDA.w #$0000
	?-		ROL A
			CMP $02
			BCC ?+
			SBC $02
	?+		ROL $00
			DEY
			BPL ?-
			STA $02
			SEP #$20
			RTL