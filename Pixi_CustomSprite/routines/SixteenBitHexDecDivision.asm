	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;16-bit hex to 4 (or 5)-digit decimal subroutine (using right-2-left
	;division).
	;Input:
	; - $00-$01 = the value you want to display
	;Output:
	; - !Scratchram_16bitHexDecOutput to !Scratchram_16bitHexDecOutput+4 = a digit 0-9 per byte table
	;   (used for 1-digit per 8x8 tile):
	; -- !Scratchram_16bitHexDecOutput+$00 = ten thousands
	; -- !Scratchram_16bitHexDecOutput+$01 = thousands
	; -- !Scratchram_16bitHexDecOutput+$02 = hundreds
	; -- !Scratchram_16bitHexDecOutput+$03 = tens
	; -- !Scratchram_16bitHexDecOutput+$04 = ones
	;
	;!Scratchram_16bitHexDecOutput is address $02 for normal ROM and $04 for SA-1.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		?SixteenBitHexDecDivision:
			if !sa1 == 0
				PHX
				PHY

				LDX #$04	;>5 bytes to write 5 digits.

				?.Loop
				REP #$20	;\Dividend (in 16-bit)
				LDA $00		;|
				STA $4204	;|
				SEP #$20	;/
				LDA.b #10	;\base 10 Divisor
				STA $4206	;/
				JSR ?.Wait	;>wait
				REP #$20	;\quotient so that next loop would output
				LDA $4214	;|the next digit properly, so basically the value
				STA $00		;|in question gets divided by 10 repeatedly. [Value/(10^x)]
				SEP #$20	;/
				LDA $4216	;>Remainder (mod 10 to stay within 0-9 per digit)
				STA $02,x	;>Store tile

				DEX
				BPL ?.Loop

				PLY
				PLX
				RTL

				?.Wait
				JSR ?..Done		;>Waste cycles until the calculation is done
				?..Done
				RTS
			else
				PHX
				PHY

				LDX #$04

				?.Loop
				REP #$20			;>16-bit XY
				LDA.w #10			;>Base 10
				STA $02				;>Divisor (10)
				SEP #$20			;>8-bit XY
				JSR ?MathDiv			;>divide
				LDA $02				;>Remainder (mod 10 to stay within 0-9 per digit)
				STA.b !Scratchram_16bitHexDecOutput,x	;>Store tile

				DEX
				BPL .Loop

				PLY
				PLX
				RTL
				
				
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
						RTS
			endif