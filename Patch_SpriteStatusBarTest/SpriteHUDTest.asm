;This is the patch version that draws a OAM-based status bar.

;Note: Don't forget to insert the graphics (ExGFX/ExGFX82_Sprite_SP4.bin)

;This patch is based on:
;-The mega man X HP bar by anonimzwx (https://www.smwcentral.net/?p=section&a=details&id=13994 )
;-The DKR status bar by Ladida, WhiteYoshiEgg, and lx5 (https://www.smwcentral.net/?p=section&a=details&id=24026 )
;and also the suggestion by lx5: https://discord.com/channels/161245277179609089/161247652946771969/827647409429151816

;And yes, this may conflict with some sprite HUD patches because $00A2E6 is somewhat a common address to use.

;You'd think this can be converted to just an uberasm tool code, but this is wrong. Uberasm tool code runs in between after transferring OAM
;RAM ($0200-$041F and $0420-$049F) to SNES register (the code at $008449 does this) and before calling $7F8000 (clears OAM slots), so
;therefore, writing OAM on uberasm tool will get cleared before drawn.

;To use:
;-have the shared subroutines patch, and defines ready. I've laid out the instructions here: Readme_Files/GettingSharedSubToWork.html
;-Have a copy of the defines (both the folders of the status bar routines defines and the shared subroutines) placed at the same locations as this patch.
;-Insert this patch

;Don't touch:
	incsrc "StatusBarRoutinesDefines/Defines.asm"
	incsrc "SharedSub_Defines/SubroutineDefs.asm"

;Defines:
;Remove or install?:
 !Setting_RemoveOrInstall = 1
  ;^0 = remove this patch (if not installed in the first place, won't do anything)
  ; 1 = install this patch
;Ram:
 !Freeram_SpriteStatusBarPatchTest_ValueToRepresent = $60
  ;^[2 bytes] for 16-bit numerical digit display
  ;^[1 byte] for repeated icons display (how many filled)
 !Freeram_SpriteStatusBarPatchTest_SecondValueToRepresent = $62
  ;^[2 bytes] for 16-bit numerical digit display
  ;^[1 byte] for repeated icons display (how many total icons)
;Settings
 !SpriteStatusBarPatchTest_Mode = 1
  ;^0 = 16-bit numerical digit display
  ; 1 = same as above but for displaying 2 numbers ("200/300", for example)
  ; 2 = repeated icons display
 ;Positions settings
  !SpriteStatusBarPatchTest_PositionMode = 1
   ;^0 = Fixed on-screen
   ; 1 = Relative to Mario
  ;Positions, relative to top-left of screen or Mario
   !SpriteStatusBarPatchTest_DisplayXPos = $0000
    ;^Note: If set to relative to player, this will be the center position.
   !SpriteStatusBarPatchTest_DisplayYPos = $FFF8

;SA-1 handling (don't touch):
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

if !Setting_RemoveOrInstall == 0
	if read4($00A2E6) != $028AB122			;22 B1 8A 02 -> JSL.L CODE_028AB1
		autoclean read3($00A2E6+1)
	endif
	org $00A2E6
	JSL $028AB1
else
	org $00A2E6				;>$00A2E6 is the code that runs at the end of the frame, after ALL sprite tiles are written.
	autoclean JML DrawHUD
endif

;Main code:
if !Setting_RemoveOrInstall != 0
	freecode
	DrawHUD:
		PHB		;\In case if you are going to use tables using 16-bit addressing
		PHK		;|
		PLB		;/
		;Draw HUD code here
			if or(equal(!SpriteStatusBarPatchTest_Mode, 0), equal(!SpriteStatusBarPatchTest_Mode, 1))
				REP #$20
				LDA !Freeram_SpriteStatusBarPatchTest_ValueToRepresent
				STA $00
				SEP #$20
				JSL !SixteenBitHexDecDivision		;>Convert to decimal digits
				LDX #$00				;>Start the string position
				JSL !SupressLeadingZeros		;>Rid out the leading zeroes (X = number of characters/tiles written)
				if !SpriteStatusBarPatchTest_Mode == 1
					LDA #$0A							;\#$0A will be converted to the "/" graphic in the digit table
					STA !Scratchram_CharacterTileTable,x				;/
					INX								;>That (above) counts as a character.
					PHX								;>Push X because it gets modified by the HexDec routine.
					REP #$20							;\Convert a given number to decimal digits.
					LDA !Freeram_SpriteStatusBarPatchTest_SecondValueToRepresent	;|
					STA $00								;|
					SEP #$20							;|
					JSL !SixteenBitHexDecDivision					;/
					PLX								;>Restore.
					JSL !SupressLeadingZeros					;>Remove leading zeroes of the second number.
				endif
				LDA.b #DigitTable			;\Supply the table
				STA $07					;|
				LDA.b #DigitTable>>8			;|
				STA $08					;|
				LDA.b #DigitTable>>16			;|
				STA $09					;/
				DEX					;\Number of tiles to write -1
				STX $04					;|
				STZ $05					;/
				LDA.b #%00110101			;\Properties (YXPPCCCT)
				STA $06					;/
				if !SpriteStatusBarPatchTest_PositionMode == 0
					REP #$20				;\XY position
					LDA #$0000				;|
					STA $00					;|
					LDA #$FFFF				;|\Y position is shifted down for some reason...
					STA $02					;|/
					SEP #$20				;/
				elseif !SpriteStatusBarPatchTest_PositionMode == 1
					REP #$20
					LDA $7E
					CLC
					ADC.w #!SpriteStatusBarPatchTest_DisplayXPos+$04
					STA $00
					JSL !GetStringXPositionCentered16Bit
					REP #$20
					LDA $80
					CLC
					ADC.w #!SpriteStatusBarPatchTest_DisplayYPos
					STA $02
					SEP #$20
				endif
				JSL !WriteStringAsSpriteOAM_OAMOnly
			endif
		
		.Done		;>We are done here.
			SEP #$30
			PLB
			JML $00A2EA		;>Continue onwards
endif


if or(equal(!SpriteStatusBarPatchTest_Mode, 0), equal(!SpriteStatusBarPatchTest_Mode, 1))
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
endif
