;List of routines:
;-WriteStringAsSpriteOAM
;-GetStringXPositionCentered
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
;-$02: X position, relative to screen border (you can take $00/$01, offset it (add by some number), and write on here).
;-$03: Y position, same as above.
;-$04: Number of tiles to write, minus 1 ("100" is 3 characters, so this RAM should be #$02).
;-$05: Properties (YXPPCCCT)
;-$06 to $09 (3 bytes): 24-bit address location of the table for converting characters to number graphics. Each byte in table lays out as follows:
;--$00 to $09 are number tiles, which are for 0-9 digit graphics.
;--$0A = "/"
; Note that all characters must be on the same page!
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
		;this converts string to graphic tile numbers. NOTE: does not work if graphics are in different GFX pages.
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine calculates where to position the string horizontally
;to be centered (text align) to a given reference point. Mainly
;useful for having numbers centered with the body of the sprite.
;
;Here is how it works:
; Formula to get the X position of the centered string:
;  StringXPos = (SpriteXPos + OffsetToCenter) - ((NumbOfChar*8)/2)
; Which becomes this because this is procedural programming:
;  (((NumbOfChar*8)/2) * -1) + (SpriteXPos + OffsetToCenter)
; We can reduce 8/2 into 4/1 (results in just multiplying by 4):
;  ((NumbOfChar*4) * -1) + (SpriteXPos + OffsetToCenter)
;Here are what the variables mean:
;-$00 = SpriteXPos (sprite's OAM tile X position, relative to screen border)
;-OffsetToCenter = (signed) how many pixels to the "apparent" center of sprite.
; Most things have their origin XY position at the top and left edge of their "bounding box". In this case
; SpriteXPos is the leftmost pixel of the sprite. Since the body of this sprite is 16x16, we need to go right
; 8 pixels, which is halfway between X=0 and X=16.
;-NumbOfChar = X index
;
;To be called after "SupressLeadingZeros" subroutine (or its variants).
;
;Input:
;-X index: How many characters.
;-$03: Offset displacement (signed) from the sprite's origin X position (Value in $00 + value in $03)
;Output:
;-$02: X position of the string, for "WriteStringAsSpriteOAM" subroutine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetStringXPositionCentered:
	TXA
	;ASL #3			;>Multiply by 2^3 (which is 8)
	;LSR			;\Divide by 2... Wait a minute! Code optimization! Multiplying by 8/2 can be reduced to 4/1. This means we only need to ASL 2 times (2^2 = 4) since a leftshift then a rightshift will cancel each other out.
	ASL #2			;/
	EOR #$FF		;\Multiply by -1, which inverts the sign
	INC A			;/
	CLC			;\Add with the sprite's X position
	ADC $00			;/
	CLC			;\Plus OffsetToCenter
	ADC #08			;/
	STA $02			;>X position of string
	RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine draws repeated icons (like this: ■ ■ ■ □ □ □, which
;represents 3/6)
;
;Input:
;-Y index: The OAM index
;-$02: X position, relative to screen border (you can take $00/$01, offset it (add by some number), and write on here).
;-$03: Y position, same as above.
;-$04: "Empty" icon
;-$05: "Full" icon
;-$06: Properties (YXPPCCCT)
;
;-Displacement of each icon, in pixels. Both of these are signed and also represents the
; direction of the line of repeated icons. As a side note, you can even have diagonal repeated icons.
;--$07: Horizontal. Positive ($00 to $7F) would extend to the right, negative ($80 to $FF)
;  extends to the left.
;--$08: Vertical. Positive ($00 to $7F) would extend downwards, negative ($80 to $FF)
;  extend upwards.
;-$09: How many tiles are filled
;-$0A: How many total tiles are filled.
;
;
;Output:
;-Y index: The OAM index after writing all the icons
;Destroyed:
;-$02: Gets displaced for each icon written.
;-$03: Gets displaced for each icon written.
;-$09: Will be [max(0, Total-NumberOfFilledIcons)] when routine is finished, used as a countdown on how many to write.
;-$0A: Will be #$00 when routine is finished, used as a countdown on how many left to write.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteRepeatedIconsAsOAM:
	
	.Loop
		LDA $0A
		BEQ .Done
		
		LDA $02			;\Write each icon displaced
		STA $0300|!addr,y	;|
		LDA $03			;|
		STA $0301|!addr,y	;/
		
		.FullOrEmpty
			LDA $09
			BEQ ..Empty
			..Full
				DEC $09
				LDA $05
				BRA ..WriteTileNumber
			..Empty
				LDA $04
			..WriteTileNumber
				STA $0302|!addr,y
		
		LDA $06			;\Properties
		STA $0303|!addr,y	;/
		.OAMExtendedBits
			PHY			;\Set tile size to 8x8.
			TYA			;|
			LSR #2			;|
			TAY			;|
			LDA $0460|!addr,y	;|
			AND.b #%11111101	;|
			STA $0460|!addr,y	;|
			PLY			;/
		
		..Next
			LDA $02			;\Displacement for next tile.
			CLC			;|
			ADC $07			;|
			STA $02			;|
			LDA $03			;|
			CLC			;|
			ADC $08			;|
			STA $03			;/
			
			INY			;\Next OAM index
			INY			;|
			INY			;|
			INY			;/
			
			DEC $0A
			BRA .Loop
		
		.Done
		RTL