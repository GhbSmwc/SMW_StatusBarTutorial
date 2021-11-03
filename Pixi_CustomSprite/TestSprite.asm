;This is a test sprite to write a string of text (characters).
;This is useful for displaying numbers.

;It makes use of the RAM defined as "!Scratchram_CharacterTileTable"
;And writes them to OAM.

incsrc "../StatusBarRoutinesDefines/Defines.asm"
incsrc "../SharedSub_Defines/SubroutineDefs.asm"

!Default_RAMToDisplay = $60
;^[2 bytes] Displays the decimal number of this RAM.

!DigitProperties = %00110001
;^YXPPCCCT

;NOTE: work-in-progress.


;Plan: We handle the stuff as "strings", then when writing to OAM,
;we need:
;
;NumbOfChar, as we need the total number of tiles, -1, for finish OAM write ($01B7B3 or %FinishOAMWrite())
;
;The width of string. We assume each character are 8px width. We can get NumbOfChar, and multiply that by 8
;as needed for alignment.
print "INIT ",pc
	RTL

print "MAIN ",pc
	PHB : PHK : PLB
	JSR SpriteCode
	PLB
	RTL

SpriteCode:
	PHB : PHK : PLB
	JSR DrawSprite
	PLB
	RTS
	
DrawSprite:
	JSR Graphics
	RTS
	
Graphics:
	%GetDrawInfo()		;>We need: Y: OAM index, $00 and $01: Position. It does not mess with any other data in $02-$0F. Like I said, don't push, then call this without pulling in between pushing and calling GetDrawInfo.
	PHX
	PHY
	LDA $00				;\Preserve XY position in $00-$01
	PHA				;|
	LDA $01				;|
	PHA				;/
	REP #$20			;\Since $00-$01 is used as an input for hexdec
	LDA !Default_RAMToDisplay	;|
	STA $00				;|
	SEP #$20			;/
	JSL !SixteenBitHexDecDivision	
	LDX #$00			;>Start the string at position 0 for suppressing leading zeroes in string
	PLA				;\Restore XY position
	STA $01				;|
	PLA				;|
	STA $00				;/
	JSL !SupressLeadingZeros	;We have the string at !Scratchram_CharacterTileTable and we have X acting as how many characters/sprite tiles so far written.
	PLY				;We need the Y index for OAM indexing
	LDA $00				;\XY position
	STA $02				;|
	LDA $01				;|
	STA $03				;/
	TXA				;\Number of characters, minus 1.
	DEC A				;|
	STA $04				;/
	LDA.b #!DigitProperties		;\Properties
	STA $05				;/
	LDA.b #GraphicTable		;\conversion table from numbers to graphic numbers
	STA $06
	LDA.b #GraphicTable>>8
	STA $07
	LDA.b #GraphicTable>>16
	STA $08				;/
	JSL !WriteStringAsSpriteOAM
	PLX
	
	LDA $04
	LDY #$FF
	%FinishOAMWrite()
	RTS
GraphicTable:
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
