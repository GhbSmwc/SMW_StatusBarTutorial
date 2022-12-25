	incsrc "../StatusBarRoutinesDefines/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine writes an 8x8 string (sequence of tile numbers in this sense)
;to OAM (horizontally). Note that this only writes 8x8s.
;
;To be used for “normal sprites” only, as in sprites part of the 12/22
;sprite slots, not the code that just write to OAM directly like
;sprite status bar patches.
;
;
;Input:
;-!Scratchram_CharacterTileTable to !Scratchram_CharacterTileTable+(NumberOfChar-1):
; The string to display. Will be written directly to $0302,y
;-Y index: The OAM index (increments of 4)
;-$02: X position, relative to screen border (you can take $00/$01, offset it (add by some number), and write on here).
;-$03: Y position, same as above.
;-$04: Number of tiles to write, minus 1 ("100" is 3 characters, so this RAM should be #$02).
;-$05: Properties (YXPPCCCT), will apply to all characters.
;-$06 to $08 (3 bytes): 24-bit address location of the table for converting characters to graphics (such as numbers). Each byte in table lays out as follows:
;--$00 to $09 are number tiles, which are for 0-9 digit graphics.
;--$0A = "/"
;--$0B = "%"
;--$0C = "!"
;--$0D = "."
;--$0E = ":"
; Note that all characters must be on the same page!
;Output:
;-Y index: The OAM index after writing the last tile character.
;
;Here's is how it works: It simply takes each byte in !Scratchram_CharacterTileTable
;and write them into OAM. Note that control characters (spaces, and newline) are not implemented
;which means you have to call this multiple times for each "word". Thankfully it is extremely
;unlikely you need to do this.
;
;This routine is mainly useful for displaying numbers.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?WriteStringAsSpriteOAM:
	PHX
	;JSL ?ConvertStringChars moved to as a code here since it is called once.
		PHY
		LDX $04
		?.LoopConvert
			;this converts string to graphic tile numbers. NOTE: does not work if graphics are in different GFX pages.
			LDA !Scratchram_CharacterTileTable,x
			TAY
			LDA [$06],y
			STA !Scratchram_CharacterTileTable,x
			BRA ?..Next
			
			?..Next
				DEX
				BPL ?.LoopConvert
		PLY
	
	LDX #$00	;>Initialize loop count
	?.LoopWrite
			
		?..Write
			LDA $02					;\X position, plus displacement
			STA $0300|!addr,y			;/
			LDA $03					;\Y position
			STA $0301|!addr,y			;/
			LDA !Scratchram_CharacterTileTable,x	;\Tile number
			STA $0302|!addr,y			;/
			LDA $05					;\Properties
			STA $0303|!addr,y			;/
			?...OAMExtendedBits
				PHY			;\Set tile size to 8x8.
				TYA			;|
				LSR #2			;|
				TAY			;|
				LDA $0460|!addr,y	;|
				AND.b #%11111101	;|
				STA $0460|!addr,y	;|
				PLY			;/
		?..CharacterPosition
			LDA $02					;\Next character is 8 pixels foward.
			CLC					;|
			ADC #$08				;|
			STA $02					;/
		?..Next
			INY
			INY
			INY
			INY
			INX
			CPX $04
			BEQ ?.LoopWrite
			BCC ?.LoopWrite
	PLX
	RTL