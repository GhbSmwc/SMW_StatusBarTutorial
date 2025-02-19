;>bytes 7
;To be used as "Level" for uberasm tool 2.0+.

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
;EXB 7: Event to trigger when timer hits 0:
;       - $00 = do nothing
;       - $01 = Lose life
;       - $02 = Fling player upwards
;
;here's an example of a countdown timer in MM:SS.CC,
;of 1 minute and 30 seconds before killing the player:
; Level_Timer.asm:01 00 (1518) (0000) 01

;Don't touch
	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	incsrc "../StatusBarRoutinesDefines/StatusBarDefines.asm"

	init:
	;These initializes the timer value
	LDY #$00							;\EXB 1
	LDA ($00),y							;/
	REP #$20
	BNE .FrameCountStartAtSomeNumber
	.FrameCounterStartAtZero
		LDA #$0000
		STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes
		STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2
		SEP #$20
		RTL
	.FrameCountStartAtSomeNumber
		LDY #$02						;\EXB 3-4
		LDA ($00),y						;/
		STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes
		LDY #$04						;\EXN 5-6
		LDA ($00),y						;/
		STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2
		SEP #$20
		RTL

	main:
	
	if !CPUMode != 0
		%invoke_sa1(mainSA1)
		RTL
		mainSA1:
	endif
	
	.Timer
		LDA $9D									;\Freeze timer if game is frozen in any way.
		ORA $13D4|!addr								;|
		BNE ..DisplayTimer							;/
		LDY #$00								;\EXB 1
		LDA ($00),y								;/
		BNE ..Decrement
		
		..Increment
			wdm
			PHB
			PHK
			PLB
			LDY #$01							;\EXB 2
			LDA ($00),y							;/
			ASL #2
			TAX
			REP #$20							;\Increment timer
			LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes		;|
			CLC								;|
			ADC #$0001							;|
			STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes		;|
			LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2	;|
			ADC #$0000							;|
			STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2	;/
			..Cap
				LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes
				SEC
				SBC TimerMax,x
				LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2
				SBC TimerMax+2,x
				SEP #$20
				BCC ...NotMaxed
			
				...Maxed
					REP #$20
					LDA TimerMax,x
					STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes
					LDA TimerMax+2,x
					STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2
					SEP #$20
				...NotMaxed
			PLB
			BRA ..DisplayTimer
		..Decrement
			REP #$20							;\Decrement frame counter
			LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes		;|Skip if timer is already 0 and triggered a code.
			ORA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2	;|
			BEQ ..DisplayTimer						;/
			LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes		;\Decrement frame counter to 0.
			SEC								;|
			SBC #$0001							;|
			STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes		;|
			LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2	;|
			SBC #$0000							;|
			STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2	;|
			BCS ...NoUnderflow						;|\Failsafe
			LDA #$0000							;||
			STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes		;||
			STA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2	;|/
			
			...NoUnderflow							;/
			
			LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes			;\Check again, AFTER subtracting by 1, so that the code executes only once.
			ORA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2		;|
			BNE ...NotDecrementedToZero						;/
			SEP #$20
			JSL TimerZero			;>Code to execute once.
			...NotDecrementedToZero
	
		..DisplayTimer
			REP #$20									;
			LDA $00										;\Preserve extra bytes address
			PHA										;/
			LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes				;|Get timer format
			STA $00										;|
			LDA !StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes+2			;|
			STA $02										;|
			SEP #$20									;|
			JSL HexDec_Frames2Timer								;/
				;Outputs:
				;!Scratchram_Frames2TimeOutput+0: Hour
				;!Scratchram_Frames2TimeOutput+1: Minutes
				;!Scratchram_Frames2TimeOutput+2: Seconds
				;!Scratchram_Frames2TimeOutput+3: Centiseconds
			REP #$20
			PLA										;\Restore extra bytes address
			STA $00										;/
			SEP #$20
			LDY #$01
			LDA ($00),y
			BNE +
			JMP ...MinutesSecondsCentiseconds
			+
			CMP #$01
			BNE +
			JMP ...HoursMinutesSecondsCentiseconds
			+
			...TwoSignificantUnitsOnly
				LDA #$78						;\Colon (overwritten to be a period if less than a minute)
				STA !Default_TestElement_Pos_Tile+(2*!StatusbarFormat)	;/
			
				LDA !Scratchram_Frames2TimeOutput+0	;\If hours nonzero, show HH:MM
				BNE ....HoursMinutes			;/
				LDA !Scratchram_Frames2TimeOutput+1	;\If less than hour and at least minute long, show MM:SS
				BNE ....MinutesSeconds			;/
				
				....SecondsCentiseconds			;>If less than minute long, show SS.CC
					LDA !Scratchram_Frames2TimeOutput+2
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(1*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(0*!StatusbarFormat)
					
					LDA #$24
					STA !Default_TestElement_Pos_Tile+(2*!StatusbarFormat)
					
					LDA !Scratchram_Frames2TimeOutput+3
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(4*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(3*!StatusbarFormat)
					RTL
				....HoursMinutes
					LDA !Scratchram_Frames2TimeOutput+0
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(1*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(0*!StatusbarFormat)
					
					LDA !Scratchram_Frames2TimeOutput+1
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(4*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(3*!StatusbarFormat)
					RTL
				....MinutesSeconds
					LDA !Scratchram_Frames2TimeOutput+1
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(1*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(0*!StatusbarFormat)
					
					LDA !Scratchram_Frames2TimeOutput+2
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(4*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(3*!StatusbarFormat)
					RTL
			...MinutesSecondsCentiseconds
				;Minutes
					LDA !Scratchram_Frames2TimeOutput+1
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(1*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(0*!StatusbarFormat)
				;Colon symbol
					LDA #$78
					STA !Default_TestElement_Pos_Tile+(2*!StatusbarFormat)
				;Seconds
					LDA !Scratchram_Frames2TimeOutput+2
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(4*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(3*!StatusbarFormat)
				;Period symbol
					LDA #$24
					STA !Default_TestElement_Pos_Tile+(5*!StatusbarFormat)
				;Centiseconds
					LDA !Scratchram_Frames2TimeOutput+3
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(7*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(6*!StatusbarFormat)
				RTL
			...HoursMinutesSecondsCentiseconds
				;Hours
					LDA !Scratchram_Frames2TimeOutput+0
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(1*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(0*!StatusbarFormat)
				;Colon symbol
					LDA #$78
					STA !Default_TestElement_Pos_Tile+(2*!StatusbarFormat)
				;Minutes
					LDA !Scratchram_Frames2TimeOutput+1
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(4*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(3*!StatusbarFormat)
				;Colon symbol
					LDA #$78
					STA !Default_TestElement_Pos_Tile+(5*!StatusbarFormat)
				;Seconds
					LDA !Scratchram_Frames2TimeOutput+2
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(7*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(6*!StatusbarFormat)
				;Period symbol
					LDA #$24
					STA !Default_TestElement_Pos_Tile+(8*!StatusbarFormat)
				;Centiseconds
					LDA !Scratchram_Frames2TimeOutput+3
					JSL HexDec_EightBitHexDec
					STA !Default_TestElement_Pos_Tile+(10*!StatusbarFormat)
					TXA
					STA !Default_TestElement_Pos_Tile+(9*!StatusbarFormat)
				RTL
	RTL
	
	TimerZero:
	LDY #$06
	LDA ($00),y
	BEQ .DoNothing
	ASL
	TAX
	JMP (.EventJumpTable-2,x)
	
	.DoNothing
	RTL
	
	.EventJumpTable
		dw .KillPlayer		;>Index 1 ($02)
		dw .FlingPlayer		;>Index 2 ($04)
		
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