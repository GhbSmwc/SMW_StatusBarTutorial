;Timer display code.
;To be inserted as "level".
;
;To use this:
;-Copy the folder containing the defines and paste it in uberasm tool's main directory (where the .exe is at).
; Make sure the defines are matching across patches and also pixi.
;-Make sure SpriteHUDTest.asm's !SpriteStatusBarPatchTest_Mode is set to display a timer.
	incsrc "../StatusBarRoutinesDefines/Defines.asm"
	
!Freeram_SpriteStatusBarPatchTest_ValueToRepresent = $60
 ;^This MUST match with the one in SpriteHUDTest.asm
main:
	.TimerChanger
		LDA $9D
		ORA $13D4|!addr
		BNE ..Frozen
		REP #$20
		LDA !Freeram_SpriteStatusBarPatchTest_ValueToRepresent
		CLC
		ADC #$0001
		STA !Freeram_SpriteStatusBarPatchTest_ValueToRepresent
		LDA !Freeram_SpriteStatusBarPatchTest_ValueToRepresent+2
		ADC #$0000
		STA !Freeram_SpriteStatusBarPatchTest_ValueToRepresent+3
		SEP #$20
		..Frozen
	RTL