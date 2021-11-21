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
;-Have a copy of the defines placed at the same locations as this patch.
;-Insert this patch

;Don't touch:
	incsrc "StatusBarRoutinesDefines/Defines.asm"

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
 !SpriteStatusBarPatchTest_Mode = 0
  ;^0 = 16-bit numerical digit display
  ; 1 = same as above but for displaying 2 numbers ("200/300", for example)
  ; 2 = repeated icons display
  

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

;Main code:
if !Setting_RemoveOrInstall == 0
	org $00A2E6				;>$00A2E6 is the code that runs at the end of the frame, after ALL sprite tiles are written.
	autoclean JML DrawHUD
else
	if read4($00A2E6) != $028AB122			;22 B1 8A 02 -> JSL.L CODE_028AB1
		autoclean read3($00A2E6+1)
	endif
	org $00A2E6
	JSL $028AB1
endif

if !Setting_RemoveOrInstall != 0
	freecode
	DrawHUD:
		PHB		;\In case if you are going to use tables using 16-bit addressing
		PHK		;|
		PLB		;/
		;Draw HUD code here
		.Done		;>We are done here.
			SEP #$30
			PLB
			JML $00A2EA		;>Continue onwards
endif