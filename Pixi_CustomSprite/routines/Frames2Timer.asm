	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Convert 32-bit frame counter to timer, By GreenHammerBro
	; This routine converts a 32-bit frame counter into 
	; hours:minutes:seconds.centiseconds format.
	;
	; Note: This assumes that the frame counter increments every 1/60th of a second.
	; The routine functions like this:
	; 1. FrameWithinSeconds = 32BitFrame MOD 60 ;>This will get a number 0-59 within a second (aka. jiffysecond)
	; 2. Seconds = Floor(32BitFrame/60) MOD 60 ;>This will get a number 0-59 within a minute.
	; 3. Minute = Floor(Seconds/60) MOD 60 ;>This will get a number 0-59 within an hour
	; 4. Hour = Floor(Minute/60) ;>This will get a number 0-255 for the hour
	; 5. To convert FrameWithinSeconds to CentiSeconds (uses cross-multiply):
	;
	;  CentiSeconds = RoundHalfUp(FrameWithinSeconds * 100/60)
	;
	; This is different from imamelia's timer, as each byte stored is in each unit and are
	; incremented individually (if frames hits 60, INC the seconds, if seconds hit 60, increment minute and so on).
	; Which that makes it hard if you want to have things that affect the timer like adding and subtracting.
	;
	; Template for making a user-friendly countdown timer:
	;	!StartTimerHour = 0
	;	!StartTimerMinute = 3
	;	!StartTimerSeconds = 30
	;
	;	REP #$20
	;	LDA.w #(!StartTimerHour*216000)+(!StartTimerMinute*3600)+(!StartTimerSeconds*60)
	;	STA !RAMToMeasure
	;	LDA.w #(!StartTimerHour*216000)+(!StartTimerMinute*3600)+(!StartTimerSeconds*60)>>16
	;	STA !RAMToMeasure+2
	;	SEP #$20
	;
	;Input:
	;-$00 to $03: the frame value (little endian!).
	;Output:
	;-!Scratchram_Frames2TimeOutput (4 bytes): timer in real world
	; units format:
	; -!Scratchram_Frames2TimeOutput+0 = hour
	; -!Scratchram_Frames2TimeOutput+1 = minutes
	; -!Scratchram_Frames2TimeOutput+2 = seconds
	; -!Scratchram_Frames2TimeOutput+3 = centiseconds (display 00 to 99 (actually 00-98 because 59/60 = 0.98[3]))
	;Overwritten:
	;-$00 to $05 was used by division routine
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	?Frames2Timer:
		LDX #$03
		
		?.Loop
		CPX #$00					;\After writing the hours, don't overwrite the hours part.
		BEQ ?.ConvertFramesToCentiseconds		;/
		REP #$20					;\divide by 60
		LDA.w #60					;|
		STA $04						;|
		SEP #$20					;/
		JSR ?MathDiv32_16				;>$00 = quotient (increases every 60 units), $04 = remainder (counter loops 00-59)

		CPX #$01					;\allow hours to go above 59
		BNE ?.NonHours					;/
		
		LDA $00						;\Upon dividing minutes by 60, the quotient is the hour, however due to how the loop works,
		STA !Scratchram_Frames2TimeOutput		;/after dividing, it writes the remainder first, then take the quotient for the next loop of the next unit.
		
		?.NonHours
		LDA $04						;\store looped value (frames, seconds and minutes loop 00-59)
		STA !Scratchram_Frames2TimeOutput,x		;/
		
		?..Next
		DEX
		BRA ?.Loop
		
		?.ConvertFramesToCentiseconds
		;simply put [Frames*100/60], highest [Frames*100 should be 5900] shouldn't overflow in unsigned 16-bit.
		if !sa1 == 0
			LDA !Scratchram_Frames2TimeOutput+3	;\Frames*100
			STA $4202				;|
			LDA.b #100				;|
			STA $4203				;/
			JSR ?WaitCalculation			;>Wait 12 cycles in total (8 is minimum needed)
			REP #$20
			LDA $4216				;>load product
			STA $4204				;>Product in dividend
			SEP #$20
			LDA.b #60				;\product divide by 60 (divisor)
			STA $4206				;/
			JSR ?WaitCalculation			;>Wait 12 cycles (16 is minimum needed)
			NOP #2					;>wait 4 cycles (16 cycles total)
			
			LDX $4214				;>quotient
			LDA $4216				;\if remainder is less than half the divisor, round down
		else
			STZ $2250				;\>multiply mode
			LDA !Scratchram_Frames2TimeOutput+3	;|Frames*100
			STA $2251				;|
			STZ $2252				;|
			LDA.b #100				;|
			STA $2253				;|
			STZ $2254				;/>this should start the calculation
			NOP					;\Wait 5 cycles
			BRA $00					;/
			REP #$20
			LDA $2306				;\backup the value in case of setting $2250 to divide
			STA $00					;/causes $2306 to lose its product
			LDX #$01				;\divide mode
			STX $2250				;/
			LDA $00					;\product divide by...
			STA $2251				;/
			SEP #$20
			LDA.b #60				;\60
			STA $2253				;/
			STZ $2254				;>this triggers the calculation to run
			NOP					;\Wait 5 cycles
			BRA $00					;/
			
			LDX $2306				;>Quotient
			LDA $2308
		endif
		CMP.b #30					;\If remainder less than half, then round downwards.
		BCC ?..NoRound					;/
		
		?..Round
		INX					;>round up quotient
		
		?..NoRound
		TXA
		STA !Scratchram_Frames2TimeOutput+3
		RTL
		
		if !sa1 == 0
			?WaitCalculation:	;>The register to perform multiplication and division takes 8/16 cycles to complete.
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