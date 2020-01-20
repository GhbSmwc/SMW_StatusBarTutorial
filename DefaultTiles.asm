;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SA-1 address
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	!dp = $0000
	!addr = $0000
	!sa1 = 0
	!gsu = 0

	if read1($00FFD6) == $15
		sfxrom
		!dp = $6000
		!addr = !dp
		!gsu = 1
	elseif read1($00FFD5) == $23
		sa1rom
		!dp = $3000
		!addr = $6000
		!sa1 = 1
	endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Default tile editor, in hex-edit patch form.
;Despite already exists a tool in the tools section:
; https://www.smwcentral.net/?p=section&a=details&id=4580
;Its HIGHLY user-unfriendly, no file navigation UI and you couldn't
;select/copy/paste text, making it extremely tedious.
;
;Note: Default tiles contains placeholder tiles when you remove a
;counter, so make sure you not only disable them via a define, you
;also need to edit and write $FC in the default tile numbers in the
;table below the defines.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Info display positon and rather or not you want them or not. This only includes the
;changing tiles and not static tiles like the coin, the "X", bonus star symbols. These
;are the default tiles in the table below.
	!DisplayName		= 1
	!NamePosition		= $0EF9|!addr

	!DisplayLives		= 1
	!LivesPosition		= $0F16|!addr
	
	!DisplayYoshiCoins	= 1
	!YoshiCoinsPosition	= $0EFF|!addr

	!DisplayBonusStars	= 2			;>0 = no, 1 = small 8x8 digits, 2 = 8x16 digits
	!BonusStarsPosition	= $0F1E|!addr		;>Note: this is the small bonus stars position placed on the bottom half of the number.
	!BonusStarsPosition1	= $0F03|!addr		;>This is the top position of the large numbers.

	!DisplayTime		= 1			;>Note: timer not shown but will still function and kill the player
	!TimePosition		= $0F25|!addr
	
	!DisplayCoin		= 1
	!CoinPosition		= $0F13|!addr
	
	!DisplayScore		= 0			;>To completely remove the scoring system, consider using this patch: https://www.smwcentral.net/?p=section&a=details&id=20270
	!ScorePosition		= $0F29|!addr

;Default tiles. These are what the tiles will appear if they are not written by a routine.
;Format: db $<Hex tile number>, %YXPCCCTT.
	org $008C81
		;Top 4 tiles of the item box
			db $3A, %00111000	;>Position: (14,01) (($0E,$01)) RAM: N/A
			db $3B, %00111000	;>Position: (15,01) (($0F,$01)) RAM: N/A
			db $3B, %00111000	;>Position: (16,01) (($10,$01)) RAM: N/A
			db $3A, %01111000	;>Position: (17,01) (($11,$01)) RAM: N/A
	org $008C89
		;Top RAM-editable row:
			db $30, %00101000	;>Position: (02,02) (($02,$02)) RAM: $0EF9
			db $31, %00101000	;>Position: (03,02) (($03,$02)) RAM: $0EFA
			db $32, %00101000	;>Position: (04,02) (($04,$02)) RAM: $0EFB
			db $33, %00101000	;>Position: (05,02) (($05,$02)) RAM: $0EFC
			db $34, %00101000	;>Position: (06,02) (($06,$02)) RAM: $0EFD
			db $FC, %00111000	;>Position: (07,02) (($07,$02)) RAM: $0EFE
			db $FC, %00111100	;>Position: (08,02) (($08,$02)) RAM: $0EFF
			db $FC, %00111100	;>Position: (09,02) (($09,$02)) RAM: $0F00
			db $FC, %00111100	;>Position: (10,02) (($0A,$02)) RAM: $0F01
			db $FC, %00111100	;>Position: (11,02) (($0B,$02)) RAM: $0F02
			db $FC, %00111000	;>Position: (12,02) (($0C,$02)) RAM: $0F03
			db $FC, %00111000	;>Position: (13,02) (($0D,$02)) RAM: $0F04
			db $4A, %00111000	;>Position: (14,02) (($0E,$02)) RAM: $0F05
			db $FC, %00111000	;>Position: (15,02) (($0F,$02)) RAM: $0F06
			db $FC, %00111000	;>Position: (16,02) (($10,$02)) RAM: $0F07
			db $4A, %01111000	;>Position: (17,02) (($11,$02)) RAM: $0F08
			db $FC, %00111000	;>Position: (18,02) (($12,$02)) RAM: $0F09
			db $3D, %00111100	;>Position: (19,02) (($13,$02)) RAM: $0F0A
			db $3E, %00111100	;>Position: (20,02) (($14,$02)) RAM: $0F0B
			db $3F, %00111100	;>Position: (21,02) (($15,$02)) RAM: $0F0C
			db $FC, %00111000	;>Position: (22,02) (($16,$02)) RAM: $0F0D
			db $FC, %00111000	;>Position: (23,02) (($17,$02)) RAM: $0F0E
			db $FC, %00111000	;>Position: (24,02) (($18,$02)) RAM: $0F0F
			db $2E, %00111100	;>Position: (25,02) (($19,$02)) RAM: $0F10
			db $26, %00111000	;>Position: (26,02) (($1A,$02)) RAM: $0F11
			db $FC, %00111000	;>Position: (27,02) (($1B,$02)) RAM: $0F12
			db $FC, %00111000	;>Position: (28,02) (($1C,$02)) RAM: $0F13
			db $00, %00111000	;>Position: (29,02) (($1D,$02)) RAM: $0F14
		;Bottom RAM-editable row:
			db $26, %00111000	;>Position: (03,03) (($03,$03)) RAM: $0F15
			db $FC, %00111000	;>Position: (04,03) (($04,$03)) RAM: $0F16
			db $00, %00111000	;>Position: (05,03) (($05,$03)) RAM: $0F17
			db $FC, %00111000	;>Position: (06,03) (($06,$03)) RAM: $0F18
			db $FC, %00111000	;>Position: (07,03) (($07,$03)) RAM: $0F19
			db $FC, %00111000	;>Position: (08,03) (($08,$03)) RAM: $0F1A
			db $64, %00101000	;>Position: (09,03) (($09,$03)) RAM: $0F1B
			db $26, %00111000	;>Position: (10,03) (($0A,$03)) RAM: $0F1C
			db $FC, %00111000	;>Position: (11,03) (($0B,$03)) RAM: $0F1D
			db $FC, %00111000	;>Position: (12,03) (($0C,$03)) RAM: $0F1E
			db $FC, %00111000	;>Position: (13,03) (($0D,$03)) RAM: $0F1F
			db $4A, %00111000	;>Position: (14,03) (($0E,$03)) RAM: $0F20
			db $FC, %00111000	;>Position: (15,03) (($0F,$03)) RAM: $0F21
			db $FC, %00111000	;>Position: (16,03) (($10,$03)) RAM: $0F22
			db $4A, %01111000	;>Position: (17,03) (($11,$03)) RAM: $0F23
			db $FC, %00111000	;>Position: (18,03) (($12,$03)) RAM: $0F24
			db $FE, %00111100	;>Position: (19,03) (($13,$03)) RAM: $0F25
			db $FE, %00111100	;>Position: (20,03) (($14,$03)) RAM: $0F26
			db $00, %00111100	;>Position: (21,03) (($15,$03)) RAM: $0F27
			db $FC, %00111000	;>Position: (22,03) (($16,$03)) RAM: $0F28
			db $FC, %00111000	;>Position: (23,03) (($17,$03)) RAM: $0F29
			db $FC, %00111000	;>Position: (24,03) (($18,$03)) RAM: $0F2A
			db $FC, %00111000	;>Position: (25,03) (($19,$03)) RAM: $0F2B
			db $FC, %00111000	;>Position: (26,03) (($1A,$03)) RAM: $0F2C
			db $FC, %00111000	;>Position: (27,03) (($1B,$03)) RAM: $0F2D
			db $FC, %00111000	;>Position: (28,03) (($1C,$03)) RAM: $0F2E
			db $00, %00111000	;>Position: (29,03) (($1D,$03)) RAM: $0F2F
	org $008CF7
		;Bottom 4 tiles of the item box
			db $3A, %10111000	;>Position: (14,04) (($0E,$04)) RAM: N/A
			db $3B, %10111000	;>Position: (15,04) (($0F,$04)) RAM: N/A
			db $3B, %10111000	;>Position: (16,04) (($10,$04)) RAM: N/A
			db $3A, %11111000	;>Position: (17,04) (($11,$04)) RAM: N/A
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Stuff you should probably shouldn't edit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org $008FC8
		if !DisplayName != 0
			LDA.W $0DB3|!addr
			BEQ $0B
			LDX.B #$04
			
			CODE_008FCF:
			LDA.W $008DF5,X   
			STA.W !NamePosition,X
			DEX
			BPL CODE_008FCF
		else
			NOP #16
		endif
	
	org $008F49
		if !DisplayLives != 0
			LDA $0DBE|!addr
			INC
			JSR $9045
			TXY
			BNE +
			LDX #$FC
			+
			STX.w !LivesPosition
			STA.w !LivesPosition+1
		else
			nop #18
		endif
	org $008FD8
		if !DisplayYoshiCoins != 0
			CODE_008FD8: LDA.W $1422|!addr                   ;\
			CODE_008FDB: CMP.B #$05                          ;| only handle yoshi coins if less than all 5 have been collected
			CODE_008FDD: BCC CODE_008FE1                     ;/
			CODE_008FDF: LDA.B #$00                          ;\
			CODE_008FE1: DEC A                               ;|
			CODE_008FE2: STA $00                             ;/ loop
			CODE_008FE4: LDX.B #$00                          ;\
			CODE_008FE6: LDY.B #$FC                          ;|
			CODE_008FE8: LDA $00                             ;|
			CODE_008FEA: BMI CODE_008FEE                     ;| show yoshi coin if that coin has been collected, otherwise show blank
			CODE_008FEC: LDY.B #$2E                          ;|
			CODE_008FEE: TYA                                 ;|
			CODE_008FEF: STA.W !YoshiCoinsPosition,x         ;/
			CODE_008FF2: DEC $00                             ;\
			CODE_008FF4: INX                                 ;| Prime for next run of loop, unless we're done
			CODE_008FF5: CPX.B #$04                          ;|
			CODE_008FF7: BNE CODE_008FE6                     ;/
		else
			RTS
		endif
	org $008F8F
		if !DisplayBonusStars == 0
			JMP $008FC5
		elseif !DisplayBonusStars == 1
		
		elseif !DisplayBonusStars == 2
			CODE_008F8F: LDA.W $0F48|!addr,X                      ;\
			CODE_008F92: STA $02                                  ;/ bonus stars for character = $02
			CODE_008F94: LDX.B #$09                               ;\
			CODE_008F96: LDY.B #$10                               ;| handles something
			CODE_008F98: JSR.W $009051                            ;/
			CODE_008F9B: LDX.B #$00                               ; Loop-like thing- basically just handling when to put spaces and when to not on the bonus stars
			CODE_008F9D: LDA.W $0F1E|!addr,X                      ;\ if there is no tens digit present, ignore this
			CODE_008FA0: BNE CODE_008FAF                          ;/
			CODE_008FA2: LDA.B #$FC                               ;\
			CODE_008FA4: STA.W $0F1E|!addr,X                      ;| if there are no bonus stars in the ones place, then just make that space empty
			CODE_008FA7: STA.W !BonusStarsPosition1,X             ;/
			CODE_008FAA: INX                                      ;|
			CODE_008FAB: CPX.B #$01                               ;| unless X = 01, rerun this loop with a extra tile displacement 
			CODE_008FAD: BNE CODE_008F9D                          ;/
			CODE_008FAF: LDA.W $0F1E|!addr,X                      ;|
			CODE_008FB2: ASL                                      ;|
			CODE_008FB3: TAY                                      ;/ Y = Index to bonus star tiles
			CODE_008FB4: LDA.W $8E06,Y                            ;\
			CODE_008FB7: STA.W !BonusStarsPosition1,X             ;|
			CODE_008FBA: LDA.W $008E07,Y                          ;|
			CODE_008FBD: STA.W $0F1E|!addr,X                      ;/ load correct tiles for bonus star counter
			CODE_008FC0: INX                                      ;\
			CODE_008FC1: CPX.B #$02                               ;|
			CODE_008FC3: BNE CODE_008FAF                          ;/ do it again if X isn't 02 now
		endif
	org $008E6F
		if !DisplayTime != 0
			LDA.W $0F31|!addr
			STA.W !TimePosition
			LDA.W $0F32|!addr
			STA.W !TimePosition+1
			LDA.W $0F33|!addr
			STA.W !TimePosition+2
		else
			nop #18
		endif
		
	org $008F73
		if !DisplayCoin != 0
			CODE_008F73: LDA.W $0DBF|!addr         ; \ Get amount of coins in decimal 
			CODE_008F76: JSR.W $009045             ; /  
			CODE_008F79: TXY                       ; \ 
			CODE_008F7A: BNE CODE_008F7E           ;  |If 10s is 0, replace with space 
			CODE_008F7C: LDX.B #$FC                ;  | 
			CODE_008F7E: STA.W !CoinPosition+1       ; \ Write coins to status bar 
			CODE_008F81: STX.W !CoinPosition         ; /  
		else
			nop #17
		endif