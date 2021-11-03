;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine writes a string (sequence of tile numbers in this sense)
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
;-$02: X position
;-$03: Y position
;-$04: Number of tiles to write, minus 1 ("100" is 3 characters, so this RAM should be #$02).
;-$05: Properties
;-$06 to $09 (3 bytes): 24-bit address location of the table for converting numbers to number graphics
;Output:
;-Y index: The OAM index after writing the last tile character.
;-$0A: Used for displacement (in pixels) to write each character. When this routine is finished,
; it represent the length of the string from the start (not in how many characters, how many pixels)
;
;Here's is how it works: It simply takes each byte in !Scratchram_CharacterTileTable
;and write them into OAM. Note that control characters (spaces, and newline) are not implemented
;which means you have to call this multiple times for each "word". Thankfully it is extremely
;unlikely you need to do this.
;
;This routine is mainly useful for displaying numbers.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteStringAsSpriteOAM:
	PHY
	LDX $04
	.LoopConvert
		LDA !Scratchram_CharacterTileTable,x
		TAY
		LDA [$06],y
		STA !Scratchram_CharacterTileTable,x
		
		..Next
		DEX
		BPL .LoopConvert
	PLY
	
	LDA $02		;\Initialize displacement
	STA $0A		;/
	LDX #$00	;>Initialize loop count
	.LoopWrite
			
		..Write
			LDA $0A					;\X position, plus displacement
			STA $0300|!addr,y			;/
			LDA $03					;\Y position
			STA $0301|!addr,y			;/
			LDA !Scratchram_CharacterTileTable,x	;\Tile number
			STA $0302|!addr,y			;/
			LDA $05					;\Properties
			STA $0303|!addr,y			;/
			...OAMExtendedBits
				PHY			;\Set tile size to 8x8.
				TYA			;|
				LSR #2			;|
				TAY			;|
				LDA $0460|!addr,y	;|
				AND.b #%11111101	;|
				STA $0460|!addr,y	;|
				PLY			;/
		..CharacterPosition
			LDA $0A					;\Next character is 8 pixels foward.
			CLC					;|
			ADC #$08				;|
			STA $0A					;/
		..Next
			INY
			INY
			INY
			INY
			INX
			CPX $04
			BEQ .LoopWrite
			BCC .LoopWrite
	RTL