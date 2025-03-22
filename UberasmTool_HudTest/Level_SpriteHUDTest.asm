;To be used as "Level" for uberasm tool 2.0+.
;Note: Don't forget to insert the graphics (ExGFX/ExGFX82_Sprite_SP4.bin)
;This test various subroutines to display things on the sprite OAM.

;Don't touch:
	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	incsrc "../StatusBarRoutinesDefines/StatusBarDefines.asm"

;Settings you can modify
	!SpriteStatusBarPatchTest_Mode = 2
		;^0 = 16-bit numerical digits display
		; 1 = 16-bit displaying 2 numbers ("200/300", for example)
		; 2 = 32-bit numerical digits display
		; 3 = 32-bit displaying 2 numbers.
		; 4 = Percentage. Displays a percentage of ValueToRepresent out of SecondValueToRepresent.
		; 5 = Timer display (MM:SS.CC), NOTE: This only DISPLAYS the timer, you need to have a code that increment/decrements the value every frame. See readme.
		; 6 = Timer display (HH:MM:SS.CC), same rule as above.
		; 7 = repeated icons display
	;Percentage display settings.
		!SpriteStatusBarPatchTest_PercentagePrecision = 2
			;^Number of digits after the decimal point when displaying the percentage, Use only values 0-2.
		!SpriteStatusBarPatchTest_PercentageDisplayCap = 1
			;^0 = Allow displaying numbers greater than 100%.
			; 1 = If a percentage is exceeding 100%, then display 100%
			;Number display settings (1, 2-number display, and percentage).
	!SpriteStatusBarPatchTest_NumberDisplayProperties = %00110101
		;^Properties (YXPPCCCT). Note: Will apply to all characters in the string.
	;Positions settings
		!SpriteStatusBarPatchTest_PositionMode = 1
			;^0 = Fixed on-screen, left-aligned
			; 1 = Fixed on-screen, right-aligned
			; 2 = Relative to Mario (centered)
			;Positions, relative to top-left of screen. Note: when using repeated icons display, it is the first tile drawn in the
			;direction of the X and Y displacement. Meaning if you have a displacement of ($F8,$F8), it would be the
			;bottom-rightmost of the line of icons.
		if !SpriteStatusBarPatchTest_PositionMode == 0
			;Position for left-aligned
				!SpriteStatusBarPatchTest_DisplayXPos = $0000
				!SpriteStatusBarPatchTest_DisplayYPos = $FFFF		;>Please note that Y position will appear 1px lower than this value.
		elseif !SpriteStatusBarPatchTest_PositionMode == 1
			;Position for right-aligned
				!SpriteStatusBarPatchTest_DisplayXPos = $00F8
				!SpriteStatusBarPatchTest_DisplayYPos = $FFFF		;>Please note that Y position will appear 1px lower than this value.
		endif
		;Same as above but for relative to Mario when !SpriteStatusBarPatchTest_PositionMode == 2
			!SpriteStatusBarPatchTest_DisplayXPosPlayer = $0000		;>This will be the center position.
			!SpriteStatusBarPatchTest_DisplayYPosPlayer = $FFFF		;>Please note that Y position will appear 1px lower than this value.
	;Repeated icons settings
		;Displacement between each icons. These are 8-bit signed.
		;A positive number would place each tile from left to right or top to bottom, negative is in reverse,
		;A value of +/-8 means each tile will be written next to another tile.
		;This will also alter the "fill direction". For example, an X displacement of $F8 (-8) will cause the
		;repeated icons meter to fill from right to left as the value stored in !Freeram_ValueDisplay1_1Byte increases.
		!SpriteStatusBarPatchTest_RepeatIcons_XDisp = $08
		!SpriteStatusBarPatchTest_RepeatIcons_YDisp = $00
	;Tile number and properties to use:
		!SpriteStatusBarPatchTest_RepeatIcons_EmptyNumb = $90
		!SpriteStatusBarPatchTest_RepeatIcons_EmptyProp = %00110001 ;YXPPCCCT.
		!SpriteStatusBarPatchTest_RepeatIcons_FullNumb = $91
		!SpriteStatusBarPatchTest_RepeatIcons_FullProp = %00110001
	;Misc
		!TwoNumberCapping = 0
			;^When displaying 2 numbers or percentage:
			; 0 = Allow first number to be greater than second number.
			; 1 = First number cannot be greater than second number.
			; Not to be confused with !SpriteStatusBarPatchTest_PercentageDisplayCap
			; and the repeated icons' not displaying values greater than max, since
			; those are only the display is capped while the actual number may be
			; higher.
	

;SA-1 handling (don't touch) :
	;SA-1
		!dp = $0000
		!addr = $0000
		!bank = $800000
		!sa1 = 0
		!gsu = 0

		if read1($00FFD6) == $15
			sfxrom
			!dp = $6000
			!addr = !dp
			!bank = $000000
			!gsu = 1
		elseif read1($00FFD5) == $23
			sa1rom
			!dp = $3000
			!addr = $6000
			!bank = $000000
			!sa1 = 1
		endif
;Timer max (also don't touch), based on if you want the hours or not. Include this for uberasm tool
	!MaxTimer = $00034BBF
	if !SpriteStatusBarPatchTest_Mode == 6
		!MaxTimer = $014996FF
	endif
;Main code:
end:
DrawHUD:
	if !CPUMode != 0
		%invoke_sa1(.MainCode)
		RTL
	endif
	.MainCode
		if !SpriteStatusBarPatchTest_Mode <= 4
			;Number display:
			;x
			;x/y
			;x%
			..ControllerValueTest
				LDA $15
				BIT.b #%00001000
				BNE ...Up
				BIT.b #%00000100
				BNE ...Down
				if or(or(equal(!SpriteStatusBarPatchTest_Mode, 1), equal(!SpriteStatusBarPatchTest_Mode, 3)), equal(!SpriteStatusBarPatchTest_Mode, 4))
					BIT.b #%00000010
					BNE ...Left
					BIT.b #%00000001
					BNE ...Right
				endif
				BRA ...Done
				
				...Up
					if or(or(equal(!SpriteStatusBarPatchTest_Mode, 0), equal(!SpriteStatusBarPatchTest_Mode, 1)), equal(!SpriteStatusBarPatchTest_Mode, 4))
						REP #$20
						LDA !Freeram_ValueDisplay1_2Bytes
						CMP #$FFFF
						BEQ ...Done
						INC
						STA !Freeram_ValueDisplay1_2Bytes
						BRA ...Done
					elseif and(greaterequal(!SpriteStatusBarPatchTest_Mode, 2), lessequal(!SpriteStatusBarPatchTest_Mode, 3))
						REP #$20
						LDA !Freeram_ValueDisplay1_4Bytes
						SEC
						SBC #$FFFF
						LDA !Freeram_ValueDisplay1_4Bytes+2
						SBC #$FFFF
						BCS ...Done
						LDA !Freeram_ValueDisplay1_4Bytes
						CLC
						ADC #$0001
						STA !Freeram_ValueDisplay1_4Bytes
						LDA !Freeram_ValueDisplay1_4Bytes+2
						ADC #$0000
						STA !Freeram_ValueDisplay1_4Bytes+2
						BRA ...Done
					endif
				...Down
					if or(or(equal(!SpriteStatusBarPatchTest_Mode, 0), equal(!SpriteStatusBarPatchTest_Mode, 1)), equal(!SpriteStatusBarPatchTest_Mode, 4))
						REP #$20
						LDA !Freeram_ValueDisplay1_2Bytes
						BEQ ...Done
						DEC
						STA !Freeram_ValueDisplay1_2Bytes
					elseif and(greaterequal(!SpriteStatusBarPatchTest_Mode, 2), lessequal(!SpriteStatusBarPatchTest_Mode, 3))
						REP #$20
						LDA !Freeram_ValueDisplay1_4Bytes
						ORA !Freeram_ValueDisplay1_4Bytes+2
						BEQ ...Done
						LDA !Freeram_ValueDisplay1_4Bytes
						SEC
						SBC #$0001
						STA !Freeram_ValueDisplay1_4Bytes
						LDA !Freeram_ValueDisplay1_4Bytes+2
						SBC #$0000
						STA !Freeram_ValueDisplay1_4Bytes+2
					endif
				if or(or(equal(!SpriteStatusBarPatchTest_Mode, 1), equal(!SpriteStatusBarPatchTest_Mode, 3)), equal(!SpriteStatusBarPatchTest_Mode, 4))
					BRA ...Done
					...Left
						if or(or(equal(!SpriteStatusBarPatchTest_Mode, 1), equal(!SpriteStatusBarPatchTest_Mode, 3)), equal(!SpriteStatusBarPatchTest_Mode, 4))
							REP #$20
							LDA !Freeram_ValueDisplay2_2Bytes
							BEQ ...Done
							DEC
							STA !Freeram_ValueDisplay2_2Bytes
							BRA ...Done
						elseif !SpriteStatusBarPatchTest_Mode == 3
							REP #$20
							LDA !Freeram_ValueDisplay2_4Bytes
							ORA !Freeram_ValueDisplay2_4Bytes+2
							BEQ ...Done
							LDA !Freeram_ValueDisplay2_4Bytes
							SEC
							SBC #$0001
							STA !Freeram_ValueDisplay2_4Bytes
							LDA !Freeram_ValueDisplay2_4Bytes+2
							SBC #$0000
							STA !Freeram_ValueDisplay2_4Bytes+2
							BRA ...Done
						endif
					...Right
						if or(or(equal(!SpriteStatusBarPatchTest_Mode, 1), equal(!SpriteStatusBarPatchTest_Mode, 3)), equal(!SpriteStatusBarPatchTest_Mode, 4))
							REP #$20
							LDA !Freeram_ValueDisplay2_2Bytes
							CMP #$FFFF
							BEQ ...Done
							INC
							STA !Freeram_ValueDisplay2_2Bytes
							BRA ...Done
						elseif !SpriteStatusBarPatchTest_Mode == 3
							REP #$20
							LDA !Freeram_ValueDisplay2_4Bytes
							SEC
							SBC #$FFFF
							LDA !Freeram_ValueDisplay2_4Bytes+2
							SBC #$FFFF
							BCS ...Done
							LDA !Freeram_ValueDisplay2_4Bytes
							CLC
							ADC #$0001
							STA !Freeram_ValueDisplay2_4Bytes
							LDA !Freeram_ValueDisplay2_4Bytes+2
							ADC #$0000
							STA !Freeram_ValueDisplay2_4Bytes+2
						endif
				endif
				...Done
					if or(or(equal(!SpriteStatusBarPatchTest_Mode, 1), equal(!SpriteStatusBarPatchTest_Mode, 3)), equal(!SpriteStatusBarPatchTest_Mode, 4))
						if !TwoNumberCapping != 0
							REP #$20
							if !SpriteStatusBarPatchTest_Mode != 3
								;16-bit max value handler
								LDA !Freeram_ValueDisplay2_2Bytes
								CMP !Freeram_ValueDisplay1_2Bytes
								BCS ....MaxNotExceed
								STA !Freeram_ValueDisplay1_2Bytes
								....MaxNotExceed
							else
								;32-bit max value handler
								LDA !Freeram_ValueDisplay2_4Bytes	;\Max - Current: Carry set if no underflow (Max >= Current), otherwise carry clear.
								SEC					;|
								SBC !Freeram_ValueDisplay1_4Bytes	;|
								LDA !Freeram_ValueDisplay2_4Bytes+2	;|
								SBC !Freeram_ValueDisplay1_4Bytes+2	;/
								BCS ....MaxNotExceed
								LDA !Freeram_ValueDisplay2_4Bytes	;\Max exceeded, set current to max.
								STA !Freeram_ValueDisplay1_4Bytes	;|
								LDA !Freeram_ValueDisplay2_4Bytes+2	;|
								STA !Freeram_ValueDisplay1_4Bytes+2	;/
								....MaxNotExceed
							endif
						endif
					endif
					SEP #$20
		elseif and(greaterequal(!SpriteStatusBarPatchTest_Mode, 5), lessequal(!SpriteStatusBarPatchTest_Mode, 6))
			;Timer counting up
			LDA $9D								;\If fozen, don't count
			ORA $13D4|!addr							;|
			BNE ..Frozen							;/
			REP #$20							;
			LDA !Freeram_ValueDisplay1_4Bytes				;\Increment timer
			CLC								;|
			ADC #$0001							;|
			STA !Freeram_ValueDisplay1_4Bytes				;|
			LDA !Freeram_ValueDisplay1_4Bytes+2				;|
			ADC #$0000							;|
			STA !Freeram_ValueDisplay1_4Bytes+2				;/
			
			..Cap
				LDA !Freeram_ValueDisplay1_4Bytes
				SEC
				SBC.w #!MaxTimer
				LDA !Freeram_ValueDisplay1_4Bytes+2
				SBC.w #!MaxTimer>>16
				SEP #$20
				BCC ...NotMaxed
			
				...Maxed
					REP #$20
					LDA.w #!MaxTimer
					STA !Freeram_ValueDisplay1_4Bytes
					LDA.w #!MaxTimer>>16
					STA !Freeram_ValueDisplay1_4Bytes+2
					SEP #$20
				...NotMaxed
			..Frozen
			
		elseif !SpriteStatusBarPatchTest_Mode == 7 ;Repeated icons
			..ControllerValueTest
				LDA $16
				BIT.b #%00001000
				BNE ...Up
				BIT.b #%00000100
				BNE ...Down
				BIT.b #%00000010
				BNE ...Left
				BIT.b #%00000001
				BNE ...Right
				BRA ...Done
				
				...Up
					LDA !Freeram_ValueDisplay1_1Byte
					CMP #$0A
					BEQ ...Done
					INC
					STA !Freeram_ValueDisplay1_1Byte
					BRA ...Done
				...Down
					LDA !Freeram_ValueDisplay1_1Byte
					BEQ ...Done
					DEC
					STA !Freeram_ValueDisplay1_1Byte
					BRA ...Done
				...Left
					LDA !Freeram_ValueDisplay2_1Byte
					BEQ ...Done
					DEC
					STA !Freeram_ValueDisplay2_1Byte
					BRA ...Done
				...Right
					LDA !Freeram_ValueDisplay2_1Byte
					CMP #$0A
					BEQ ...Done
					INC
					STA !Freeram_ValueDisplay2_1Byte
					BRA ...Done
				...Done
					if !TwoNumberCapping != 0
						LDA !Freeram_ValueDisplay2_1Byte
						CMP !Freeram_ValueDisplay1_1Byte
						BCS ....MaxNotExceed
						STA !Freeram_ValueDisplay1_1Byte
						....MaxNotExceed
					endif
				
		endif
	PHB		;\In case if you are going to use tables using 16-bit addressing
	PHK		;|
	PLB		;/
	;Draw HUD code here
		if !SpriteStatusBarPatchTest_Mode < 4
			;Number display:
			;X
			;X/Y
			
			;First number
				if !SpriteStatusBarPatchTest_Mode <= 1
					REP #$20
					LDA !Freeram_ValueDisplay1_2Bytes
					STA $00
					SEP #$20
					JSL HexDec_SixteenBitHexDecDivision				;>Convert to decimal digits
					LDX #$00							;>Start the string position
					JSL HexDec_SupressLeadingZeros					;>Rid out the leading zeroes (X = number of characters/tiles written)
				elseif and(greaterequal(!SpriteStatusBarPatchTest_Mode, 2), lessequal(!SpriteStatusBarPatchTest_Mode, 3))
					REP #$20
					LDA !Freeram_ValueDisplay1_4Bytes
					STA $00
					LDA !Freeram_ValueDisplay1_4Bytes+2
					STA $02
					SEP #$20
					JSL HexDec_ThirtyTwoBitHexDecDivision
					LDX #$00
					JSL HexDec_SupressLeadingZeros32Bit
				endif
			;Second number
				if !SpriteStatusBarPatchTest_Mode == 1
					LDA #$0A							;\#$0A will be converted to the "/" graphic in the digit table
					STA !Scratchram_CharacterTileTable,x				;/
					INX								;>That (above) counts as a character.
					PHX								;>Push X because it gets modified by the HexDec routine.
					REP #$20							;\Convert a given number to decimal digits.
					LDA !Freeram_ValueDisplay2_2Bytes				;|
					STA $00								;|
					SEP #$20							;|
					JSL HexDec_SixteenBitHexDecDivision				;/
					PLX								;>Restore.
					JSL HexDec_SupressLeadingZeros					;>Remove leading zeroes of the second number.
				elseif !SpriteStatusBarPatchTest_Mode == 3
					LDA #$0A							;\#$0A will be converted to the "/" graphic in the digit table
					STA !Scratchram_CharacterTileTable,x				;/
					INX								;>That (above) counts as a character.
					PHX								;>Push X because it gets modified by the HexDec routine.
					REP #$20							;\Convert a given number to decimal digits.
					LDA !Freeram_ValueDisplay2_4Bytes				;|
					STA $00								;|
					LDA !Freeram_ValueDisplay2_4Bytes+2				;|
					STA $02								;|
					SEP #$20							;|
					JSL HexDec_ThirtyTwoBitHexDecDivision				;/
					PLX								;>Restore.
					JSL HexDec_SupressLeadingZeros32Bit				;>Remove leading zeroes of the second number.
				endif
			;OAM setup
				LDA.b #DigitTable			;\Supply the table
				STA $07					;|
				LDA.b #DigitTable>>8			;|
				STA $08					;|
				LDA.b #DigitTable>>16			;|
				STA $09					;/
				DEX					;\$04-$05 Number of tiles to write -1
				STX $04					;|
				STZ $05					;/
				LDA.b #!SpriteStatusBarPatchTest_NumberDisplayProperties	;\Properties (YXPPCCCT)
				STA $06								;/
				if !SpriteStatusBarPatchTest_PositionMode < 2
					if !SpriteStatusBarPatchTest_PositionMode == 0
						REP #$20						;\XY position
						LDA #!SpriteStatusBarPatchTest_DisplayXPos		;|
						STA $00							;|
						LDA #!SpriteStatusBarPatchTest_DisplayYPos		;|\Y position is shifted down for some reason...
						STA $02							;|/
						SEP #$20						;/
					else
						;Right-aligned
						;To obtain the X position of the string of the leftmost character we do this:
						; XPosition = !SpriteStatusBarPatchTest_DisplayXPos - ((NumberOfTiles-1)*8)
						;Which handles it this way for optimization purposes:
						; XPosition = -((NumberOfTiles-1)*8) + !SpriteStatusBarPatchTest_DisplayXPos
						REP #$20
						LDA $04							;>Number of characters (-1 needed so that the rightmost character is on where the position was defined (included, not excluded) and not 8 pixels to the left)
						ASL #3							;>Multiply by 8
						EOR #$FFFF						;\Times -1
						INC							;/
						CLC							;\Add by given X position to be right-aligned
						ADC #!SpriteStatusBarPatchTest_DisplayXPos		;/
						STA $00
						LDA #!SpriteStatusBarPatchTest_DisplayYPos		;\Y position
						STA $02							;/
						SEP #$20
					endif
				else
					REP #$20						;\Position based on Mario's on-screen position
					LDA $7E							;|
					CLC							;|
					ADC.w #!SpriteStatusBarPatchTest_DisplayXPosPlayer+$08	;|
					STA $00							;|
					PHX							;|
					INX							;|
					JSL OAMBasedHUD_GetStringXPositionCentered16Bit		;|
					PLX							;|
					REP #$20						;|
					LDA $80							;|
					CLC							;|
					ADC.w #!SpriteStatusBarPatchTest_DisplayYPosPlayer	;|
					STA $02							;|
					SEP #$20						;/
				endif
			;Write to OAM
				JSL OAMBasedHUD_WriteStringAsSpriteOAM_OAMOnly
		elseif !SpriteStatusBarPatchTest_Mode == 4 ;Percentage display
			.PercentageDisplay
			;Display a percentage
				REP #$20
				LDA !Freeram_ValueDisplay1_2Bytes
				STA !Scratchram_PercentageQuantity
				LDA !Freeram_ValueDisplay2_2Bytes
				STA !Scratchram_PercentageMaxQuantity
				SEP #$20
				LDA #!SpriteStatusBarPatchTest_PercentagePrecision
				STA !Scratchram_PercentageFixedPointPrecision
				JSL HexDec_ConvertToPercentage
				if !SpriteStatusBarPatchTest_PercentageDisplayCap != 0
					..CapAt100
						REP #$30
						LDX.w #(10**(!SpriteStatusBarPatchTest_PercentagePrecision+2))
						...HighWordCheck ;Check the high word of the XXXX (RAM_00-RAM_03 = $XXXXYYYY)
							LDA $02			;\Any nonzero digits in the high word would mean at least
							BNE ..Cap100		;/65536 ($00010000), which is guaranteed over 100/1000/10000.
						...LowWordCheck
							TXA
							CMP $00			;\Max compares with RAM_00
							BCS ..Under		;/If Max >= RAM_00 or RAM_00 is lower, don't set it to max.
					..Cap100
						TXA
						STA $00
					..Under
					SEP #$30
				endif
			.RoundAwayFromEndpoint
				;Avoid displaying 0% and 100% misleadingly if close to them.
				CPY #$00
				BEQ ..Normal
				CPY #$01
				BEQ ..RoundTo1Percent
				CPY #$02
				BCS ..RoundTo99Percent		;>Just in case somehow Y is a value $03 or more
				
				..RoundTo1Percent
					REP #$20
					LDA.w #1
					STA $00
					STZ $02
					SEP #$20
					BRA ..Normal
				..RoundTo99Percent
					REP #$20
					LDA.w #(10**(!SpriteStatusBarPatchTest_PercentagePrecision+2)-1)		;>99%, 99.9%, or 99.99%.
					STA $00
					STZ $02
					SEP #$20
				..Normal
			.Display ;Write to OAM
				JSL HexDec_SixteenBitHexDecDivision
				;Since we are dealing with OAM, and at the start of each frame, it clears the OAM (Ypos = $F0),
				;we don't need to clear a space since it is already done.
				LDX #$00
				if !SpriteStatusBarPatchTest_PercentagePrecision == 0
					JSL HexDec_SupressLeadingZeros
				elseif !SpriteStatusBarPatchTest_PercentagePrecision == 1
					LDA #$0D						;\Decimal symbol
					STA $09							;/
					JSL HexDec_SupressLeadingZerosPercentageLeaveLast2
				elseif !SpriteStatusBarPatchTest_PercentagePrecision == 2
					LDA #$0D						;\Decimal symbol
					STA $09							;/
					JSL HexDec_SupressLeadingZerosPercentageLeaveLast3
				endif
				;X = number of characters
				LDA #$0B					;\Percent symbol
				STA !Scratchram_CharacterTileTable,x		;/
				INX
				;XY position
					if !SpriteStatusBarPatchTest_PositionMode < 2
						if !SpriteStatusBarPatchTest_PositionMode == 0
							REP #$20
							LDA #!SpriteStatusBarPatchTest_DisplayXPos
							STA $00
							LDA #!SpriteStatusBarPatchTest_DisplayYPos
							STA $02
							SEP #$20
						else
							;Right-aligned
							;To obtain the X position of the string of the leftmost character we do this:
							; XPosition = !SpriteStatusBarPatchTest_DisplayXPos - ((NumberOfTiles-1)*8)
							;Which handles it this way for optimization purposes:
							; XPosition = -((NumberOfTiles-1)*8) + !SpriteStatusBarPatchTest_DisplayXPos
							TXA
							DEC
							REP #$20
							AND #$00FF
							;LDA $04							;>Number of characters (-1 needed so that the rightmost character is on where the position was defined (included, not excluded) and not 8 pixels to the left)
							ASL #3							;>Multiply by 8
							EOR #$FFFF						;\Times -1
							INC							;/
							CLC							;\Add by given X position to be right-aligned
							ADC #!SpriteStatusBarPatchTest_DisplayXPos		;/
							STA $00
							LDA #!SpriteStatusBarPatchTest_DisplayYPos		;\Y position
							STA $02							;/
							SEP #$20
						endif
					else
						REP #$20
						LDA $7E
						CLC
						ADC #!SpriteStatusBarPatchTest_DisplayXPosPlayer+$08
						STA $00
						LDA $80
						CLC
						ADC #!SpriteStatusBarPatchTest_DisplayYPosPlayer
						STA $02
						SEP #$20
						JSL OAMBasedHUD_GetStringXPositionCentered16Bit
					endif
				;Number of chars
					DEX
					STX $04
					STZ $05
				;YXPPCCCT
					LDA.b #!SpriteStatusBarPatchTest_NumberDisplayProperties
					STA $06
				;Tile table
					LDA.b #DigitTable			;\Supply the table
					STA $07					;|
					LDA.b #DigitTable>>8			;|
					STA $08					;|
					LDA.b #DigitTable>>16			;|
					STA $09					;/
				;And done
					JSL OAMBasedHUD_WriteStringAsSpriteOAM_OAMOnly
		elseif or(equal(!SpriteStatusBarPatchTest_Mode, 5), equal(!SpriteStatusBarPatchTest_Mode, 6)) ;Timer mode (MM:SS.CC/HH:MM:SS.CC)
			;Don't touch these
			;Note to self: NunberOfTiles = $08+!Timer_HourCharacterCount
			;Also needed to calculate the right-aligned version
			!Timer_HourCharacterCount = 0
			!Timer_XPosition = !SpriteStatusBarPatchTest_DisplayXPos
			if !SpriteStatusBarPatchTest_Mode == 6
				!Timer_HourCharacterCount = 3
			endif
			if !SpriteStatusBarPatchTest_PositionMode == 1
				!Timer_XPosition = !SpriteStatusBarPatchTest_DisplayXPos-(($08+!Timer_HourCharacterCount-1)*8)
			endif
			REP #$20
			LDA !Freeram_ValueDisplay1_4Bytes
			STA $00
			LDA !Freeram_ValueDisplay1_4Bytes+2
			STA $02
			SEP #$20
			JSL HexDec_Frames2Timer
			.Hours
				if !SpriteStatusBarPatchTest_Mode == 6
					LDA !Scratchram_Frames2TimeOutput
					JSL HexDec_EightBitHexDec
					PHA					;STX $XXXXXX does not work.
					TXA
					STA !Scratchram_CharacterTileTable
					PLA
					STA !Scratchram_CharacterTileTable+1
					..ColonAfterHour
					LDA #$0E
					STA !Scratchram_CharacterTileTable+2
				endif
			.Minutes
				LDA !Scratchram_Frames2TimeOutput+1
				JSL HexDec_EightBitHexDec
				PHA					;STX $XXXXXX does not work.
				TXA
				STA !Scratchram_CharacterTileTable+!Timer_HourCharacterCount
				PLA
				STA !Scratchram_CharacterTileTable+1+!Timer_HourCharacterCount
				..ColonAfterMinutes
					LDA #$0E
					STA !Scratchram_CharacterTileTable+2+!Timer_HourCharacterCount
			.Seconds
				LDA !Scratchram_Frames2TimeOutput+2
				JSL HexDec_EightBitHexDec
				PHA
				TXA
				STA !Scratchram_CharacterTileTable+3+!Timer_HourCharacterCount
				PLA
				STA !Scratchram_CharacterTileTable+4+!Timer_HourCharacterCount
			.DecimalPoint
				LDA #$0D
				STA !Scratchram_CharacterTileTable+5+!Timer_HourCharacterCount
			.CentiSeconds
				LDA !Scratchram_Frames2TimeOutput+3
				JSL HexDec_EightBitHexDec
				PHA
				TXA
				STA !Scratchram_CharacterTileTable+6+!Timer_HourCharacterCount
				PLA
				STA !Scratchram_CharacterTileTable+7+!Timer_HourCharacterCount
			.WriteToOAM
				..Positions
					if !SpriteStatusBarPatchTest_PositionMode < 2
						REP #$20						;\XY position
						LDA #!Timer_XPosition					;|
						STA $00							;|
						LDA #!SpriteStatusBarPatchTest_DisplayYPos		;|\Y position is shifted down for some reason...
						STA $02							;|/
						SEP #$20						;/
					else
						LDX #$08+!Timer_HourCharacterCount	;MM:SS.CC is 8 characters
						REP #$20
						LDA $7E
						CLC
						ADC.w #!SpriteStatusBarPatchTest_DisplayXPosPlayer+$08
						STA $00
						JSL OAMBasedHUD_GetStringXPositionCentered16Bit
						REP #$20
						LDA $80
						CLC
						ADC.w #!SpriteStatusBarPatchTest_DisplayYPosPlayer
						STA $02
						SEP #$20
					endif
				..NumberOfTiles
					;MM:SS.CC is 8 characters, -1 which is why $07 is used 
					LDA #$07+!Timer_HourCharacterCount
					STA $04
					STZ $05
				..Properties
					LDA #!SpriteStatusBarPatchTest_NumberDisplayProperties
					STA $06
				..GraphicTable
					LDA.b #DigitTable			;\Supply the table
					STA $07					;|
					LDA.b #DigitTable>>8			;|
					STA $08					;|
					LDA.b #DigitTable>>16			;|
					STA $09					;/
				JSL OAMBasedHUD_WriteStringAsSpriteOAM_OAMOnly
		elseif !SpriteStatusBarPatchTest_Mode == 7 ;Repeated icons
			LDA #!SpriteStatusBarPatchTest_RepeatIcons_XDisp	;\Displacement for each tile
			STA $04							;|
			LDA #!SpriteStatusBarPatchTest_RepeatIcons_YDisp	;|
			STA $05							;/
			if !SpriteStatusBarPatchTest_PositionMode < 2
				REP #$20						;\Positions
				LDA #!SpriteStatusBarPatchTest_DisplayXPos		;|
				STA $00							;|
				LDA #!SpriteStatusBarPatchTest_DisplayYPos		;|
				STA $02							;|
				SEP #$20						;/
			else
				REP #$20
				LDA $7E							;\Positions
				CLC							;|
				ADC.w #!SpriteStatusBarPatchTest_DisplayXPosPlayer+4	;|
				STA $00							;|
				LDA $80							;|
				CLC							;|
				ADC #$FFF8						;|
				STA $02							;/
				SEP #$20
				LDA !Freeram_ValueDisplay2_1Byte			;\Number of icons
				STA $06							;/
				JSL OAMBasedHUD_CenterRepeatingIcons_OAMOnly
			endif
			LDA #!SpriteStatusBarPatchTest_RepeatIcons_EmptyNumb	;\Tile numbers to use
			STA $06							;|
			LDA.b #!SpriteStatusBarPatchTest_RepeatIcons_EmptyProp	;|
			STA $07							;|
			LDA #!SpriteStatusBarPatchTest_RepeatIcons_FullNumb	;|
			STA $08							;|
			LDA.b #!SpriteStatusBarPatchTest_RepeatIcons_FullProp	;|
			STA $09							;/
			LDA !Freeram_ValueDisplay1_1Byte				;\Number of filled tiles and how many total
			STA $0A								;|
			LDA !Freeram_ValueDisplay2_1Byte				;|
			STA $0B								;/
			JSL OAMBasedHUD_WriteRepeatedIconsAsOAM_OAMOnly				;>Write.
		endif
	.Done		;>We are done here.
		SEP #$30
		PLB
		RTL
if lessequal(!SpriteStatusBarPatchTest_Mode, 6) ;If !SpriteStatusBarPatchTest_Mode is a number display
	DigitTable:
		db $80				;>Index $00 = for the "0" graphic
		db $81				;>Index $01 = for the "1" graphic
		db $82				;>Index $02 = for the "2" graphic
		db $83				;>Index $03 = for the "3" graphic
		db $84				;>Index $04 = for the "4" graphic
		db $85				;>Index $05 = for the "5" graphic
		db $86				;>Index $06 = for the "6" graphic
		db $87				;>Index $07 = for the "7" graphic
		db $88				;>Index $08 = for the "8" graphic
		db $89				;>Index $09 = for the "9" graphic
		db $8A				;>Index $0A = for the "/" graphic
		db $8B				;>Index $0B = for the "%" graphic
		db $8C				;>Index $0C = for the "!" graphic
		db $8D				;>Index $0D = for the "." graphic
		db $8E				;>Index $0E = for the ":" graphic
endif