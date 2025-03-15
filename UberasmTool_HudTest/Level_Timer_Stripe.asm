;>bytes 7
;To be used as "Level" for uberasm tool 2.0+.
;This displays a timer on the layer 3 stripe image.

;Extra bytes information:
;EXB 1: $00 = Increment, $01 decrement (do something when timer hits 0).
;EXB 2: Display mode:
;       - $00 = MM:SS.CC
;       - $01 = HH:MM:SS.CC
;       - $02 = Display only 2 most significant units
;               - If timer is less than a minute, display "SS.CC"
;               - If timer is between a minute and hour long, display "MM:SS"
;               - Otherwise display "HH:MM"
;EXB 3-6: Starting frame value when countdown is being used (4 bytes, little endian).
;         See "Readme_Files/JS_FrameToTimer.html" to convert to frames.
;EXB 7: Effect number/Event to trigger when timer hits 0. Must be a range of 0-127 ($00-$7F):
;       - $00 = do nothing
;       - $01 = Lose life
;       - $02 = Fling player upwards
;       - Any higher values, you must edit and add code below "EventJumpTable". A value
;         pointing anything beyond the last item in the table causes glitch/crash.
;
;Example of a countdown timer in MM:SS.CC,
;of 1 minute and 30 seconds before killing the player:
; Level_Timer.asm:01 00 (1518) (0000) 01

;Don't touch
	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	incsrc "../StatusBarRoutinesDefines/StatusBarDefines.asm"
	%require_uber_ver(2, 0)

	init:
	;These initializes the timer value
	LDY #$00							;\EXB 1
	LDA ($00),y							;/
	REP #$20
	BNE .FrameCountStartAtSomeNumber
	.FrameCounterStartAtZero
		LDA #$0000
		STA !Freeram_ValueDisplay1_4Bytes
		STA !Freeram_ValueDisplay1_4Bytes+2
		SEP #$20
		RTL
	.FrameCountStartAtSomeNumber
		LDY #$02						;\EXB 3-4
		LDA ($00),y						;/
		STA !Freeram_ValueDisplay1_4Bytes
		LDY #$04						;\EXN 5-6
		LDA ($00),y						;/
		STA !Freeram_ValueDisplay1_4Bytes+2
		SEP #$20
		RTL

	main:
	
	if !CPUMode != 0
		%invoke_sa1(mainSA1)
		JMP MainSnes
		mainSA1:
	endif
	
	.Timer
		LDA $9D						;\Freeze timer if game is frozen in any way.
		ORA $13D4|!addr					;|
		BNE ..DisplayTimer				;/
		LDY #$00					;\EXB 1
		LDA ($00),y					;/
		BNE ..Decrement
		
		..Increment
			PHB
			PHK
			PLB
			LDY #$01				;\EXB 2
			LDA ($00),y				;/
			ASL #2
			TAX
			REP #$20				;\Increment timer
			LDA !Freeram_ValueDisplay1_4Bytes	;|
			CLC					;|
			ADC #$0001				;|
			STA !Freeram_ValueDisplay1_4Bytes	;|
			LDA !Freeram_ValueDisplay1_4Bytes+2	;|
			ADC #$0000				;|
			STA !Freeram_ValueDisplay1_4Bytes+2	;/
			..Cap
				LDA !Freeram_ValueDisplay1_4Bytes
				SEC
				SBC TimerMax,x
				LDA !Freeram_ValueDisplay1_4Bytes+2
				SBC TimerMax+2,x
				SEP #$20
				BCC ...NotMaxed
			
				...Maxed
					REP #$20
					LDA TimerMax,x
					STA !Freeram_ValueDisplay1_4Bytes
					LDA TimerMax+2,x
					STA !Freeram_ValueDisplay1_4Bytes+2
					SEP #$20
				...NotMaxed
			PLB
			BRA ..DisplayTimer
		..Decrement
			REP #$20				;\Decrement frame counter
			LDA !Freeram_ValueDisplay1_4Bytes	;|Skip if timer is already 0 and triggered a code.
			ORA !Freeram_ValueDisplay1_4Bytes+2	;|
			BEQ ..DisplayTimer			;/
			LDA !Freeram_ValueDisplay1_4Bytes	;\Decrement frame counter to 0.
			SEC					;|
			SBC #$0001				;|
			STA !Freeram_ValueDisplay1_4Bytes	;|
			LDA !Freeram_ValueDisplay1_4Bytes+2	;|
			SBC #$0000				;|
			STA !Freeram_ValueDisplay1_4Bytes+2	;|
			BCS ...NoUnderflow			;|\Failsafe
			LDA #$0000				;||
			STA !Freeram_ValueDisplay1_4Bytes	;||
			STA !Freeram_ValueDisplay1_4Bytes+2	;|/
			
			...NoUnderflow				;/
			
			LDA !Freeram_ValueDisplay1_4Bytes	;\Check again, AFTER subtracting by 1, so that the code executes only once.
			ORA !Freeram_ValueDisplay1_4Bytes+2	;|
			BNE ...NotDecrementedToZero		;/
			SEP #$20
			JSL TimerZero			;>Code to execute once.
			...NotDecrementedToZero
	
		..DisplayTimer
			;Note: I have to write it to a string buffer !Scratchram_CharacterTileTable, then write it to a stripe image
			;because I don't really like juggling with the X register being used for both EightBitHexDec's 10s place digit (8-bit)
			;and as a stripe image (16-bit).
			REP #$20					;
			LDA $00						;\Preserve extra bytes address
			PHA						;/
			LDA !Freeram_ValueDisplay1_4Bytes		;|Get timer format
			STA $00						;|
			LDA !Freeram_ValueDisplay1_4Bytes+2		;|
			STA $02						;|
			SEP #$20					;|
			JSL HexDec_Frames2Timer				;/
				;Outputs:
				;!Scratchram_Frames2TimeOutput+0: Hour
				;!Scratchram_Frames2TimeOutput+1: Minutes
				;!Scratchram_Frames2TimeOutput+2: Seconds
				;!Scratchram_Frames2TimeOutput+3: Centiseconds
				wdm
			REP #$20
			PLA										;\Restore extra bytes address
			STA $00										;/
			SEP #$20									;\Determine what format to display
			LDY #$01									;|
			LDA ($00),y									;|
			BNE +										;|
			JMP ...MinutesSecondsCentiseconds						;|
			+										;|
			CMP #$01									;|
			BNE +										;|
			JMP ...HoursMinutesSecondsCentiseconds						;|
			+										;/
			...TwoSignificantUnitsOnly							;>"XX:XX" or "XX.XX". Always 5 characters long ($04-$05: #$0004)
				LDA #$78								;\Colon (overwritten to be a period if less than a minute)
				STA !Scratchram_CharacterTileTable+2					;/
			
				LDA !Scratchram_Frames2TimeOutput+0					;\If hours nonzero, show HH:MM
				BNE ....HoursMinutes							;/
				LDA !Scratchram_Frames2TimeOutput+1					;\If less than hour and at least minute long, show MM:SS
				BNE ....MinutesSeconds							;/
				
				....SecondsCentiseconds							;>If less than minute long, show SS.CC
					LDA !Scratchram_Frames2TimeOutput+2
					JSL HexDec_EightBitHexDec					;>A: 1s, X: 10s
					STA !Scratchram_CharacterTileTable+1
					TXA
					STA !Scratchram_CharacterTileTable+0
					
					LDA #$24							;\Decimal point
					STA !Scratchram_CharacterTileTable+2				;/
					
					LDA !Scratchram_Frames2TimeOutput+3
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+4
					TXA
					STA !Scratchram_CharacterTileTable+3
					REP #$20
					LDA.w #5-1				;>TwoSignificantUnitsOnly is always 4 digits and one separator (":" and "."), totaling 5 characters
					JMP ...TransferStringToStripe
				....HoursMinutes
					LDA !Scratchram_Frames2TimeOutput+0
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+1
					TXA
					STA !Scratchram_CharacterTileTable+0
					
					LDA !Scratchram_Frames2TimeOutput+1
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+4
					TXA
					STA !Scratchram_CharacterTileTable+3
					REP #$20
					LDA.w #5-1				;>TwoSignificantUnitsOnly is always 4 digits and one separator (":" and "."), totaling 5 characters
					JMP ...TransferStringToStripe
				....MinutesSeconds
					LDA !Scratchram_Frames2TimeOutput+1
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+1
					TXA
					STA !Scratchram_CharacterTileTable+0
					
					LDA !Scratchram_Frames2TimeOutput+2
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+4
					TXA
					STA !Scratchram_CharacterTileTable+3
					REP #$20
					LDA.w #5-1				;>TwoSignificantUnitsOnly is always 4 digits and one separator (":" and "."), totaling 5 characters
					JMP ...TransferStringToStripe
			...MinutesSecondsCentiseconds				;>"MM:SS.CC"
				;Minutes
					LDA !Scratchram_Frames2TimeOutput+1
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+1
					TXA
					STA !Scratchram_CharacterTileTable+0
				;Colon symbol
					LDA #$78
					STA !Scratchram_CharacterTileTable+2
				;Seconds
					LDA !Scratchram_Frames2TimeOutput+2
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+4
					TXA
					STA !Scratchram_CharacterTileTable+3
				;Period symbol
					LDA #$24
					STA !Scratchram_CharacterTileTable+5
				;Centiseconds
					LDA !Scratchram_Frames2TimeOutput+3
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+7
					TXA
					STA !Scratchram_CharacterTileTable+6
					REP #$20
					LDA.w #8-1				;>"MM:SS.CC" is 8 characters.
					JMP ...TransferStringToStripe
			...HoursMinutesSecondsCentiseconds			;>"HH:MM:SS.CC"
				;Hours
					LDA !Scratchram_Frames2TimeOutput+0
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+1
					TXA
					STA !Scratchram_CharacterTileTable+0
				;Colon symbol
					LDA #$78
					STA !Scratchram_CharacterTileTable+2
				;Minutes
					LDA !Scratchram_Frames2TimeOutput+1
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+4
					TXA
					STA !Scratchram_CharacterTileTable+3
				;Colon symbol
					LDA #$78
					STA !Scratchram_CharacterTileTable+5
				;Seconds
					LDA !Scratchram_Frames2TimeOutput+2
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+7
					TXA
					STA !Scratchram_CharacterTileTable+6
				;Period symbol
					LDA #$24
					STA !Scratchram_CharacterTileTable+8
				;Centiseconds
					LDA !Scratchram_Frames2TimeOutput+3
					JSL HexDec_EightBitHexDec
					STA !Scratchram_CharacterTileTable+0
					TXA
					STA !Scratchram_CharacterTileTable+9
					REP #$20
					LDA.w #11-1				;>"HH:MM:SS.CC" is 11 characters.
			...TransferStringToStripe
				STA $04
				STA $09						;>Save character count for later
				SEP #$20
				LDA.b #!Layer3Stripe_TestDisplayElement_PosX
				STA $00
				LDA.b #!Layer3Stripe_TestDisplayElement_PosY
				STA $01
				LDA #$05
				STA $02
				STZ $03
				if !CPUMode != 0
					RTL
					MainSnes:
				endif
				JSL HexDec_SetupStripe				;X (16-bit): Index of stripe
				REP #$20			;\$00-$02: Address of of open stripe data (tile data's TTTTTTTT).
				TXA				;|$03-$05: Address of of open stripe data (tile data's YXPCCCTT).
				CLC				;|
				ADC.w #$7F837D+4		;|Take X, the stripe index, add by #$7F8381
				STA $00				;|and store it at $00, since we are doing "Indirect Long" 
				INC				;|
				STA $03				;|
				SEP #$30			;|
				LDA #$7F			;|
				STA $02				;|
				STA $05				;/
				LDA.b #!StatusBar_TileProp	;\Props (WriteStringDigitsToHUD uses $06 to write)
				STA $06				;/
				REP #$20			;\Number of characters
				LDA $09				;|
				SEP #$20			;|
				INC				;|
				TAX				;/
				JSL HexDec_WriteStringDigitsToHUDFormat2
				RTL
	
	TimerZero:
	LDY #$06
	LDA ($00),y			;A = a number representing each event
	BEQ .DoNothing			;>If nothing, don't trigger any event
	ASL				;>Times 2 because each event address to jump to is 2-bytes long.
	TAX				;>Put it in the X index register
	JMP (.EventJumpTable-2,x)	;>Direct indirect to get an address stored at an address (anything inside the parenthesis or brackets means get address in address), depending on X. Label-2 because we want Event 1 to map to the first listed address.
	
	.DoNothing
	RTL
	
	.EventJumpTable
		;Events to trigger when countdown timer hits zero.
		;You can have up to 127 events (because each item here takes up 2 bytes, and the indexing (which is the number of bytes offset from the first item)
		;is 8-bit (which ranges from 0-255), gets multiplied by 2 (now byte indexes above 127 is an overflow) to correctly point to the correct position
		;corresponding to the items below here). You probably wouldn't need that many events anyway.
		dw .KillPlayer		;>Event 1 (Byte Index = $02)
		dw .FlingPlayer		;>Event 2 (Byte Index = $04)
		
	.KillPlayer
		JSL $00F606
		RTL
	.FlingPlayer
		LDA #$80
		STA $7D
		RTL
	
	TimerMax:
	dw $4BBF, $0003 ;$00034BBF (00:59:59.98) MM:SS.CC
	dw $96FF, $0149 ;$014996FF (99:59:59.98) HH:MM:SS.CC
	dw $96FF, $0149 ;$014996FF (99:59:59.98) 2 significant units only