;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine draws repeated icons (like this: ■ ■ ■ □ □ □, which
;represents 3/6)
;
;Input:
;-Y index: The OAM index
;-$02: X position, relative to screen border (you can take $00/$01, offset it (add by some number), and write on here).
;-$03: Y position, same as above.
;-Displacement of each icon, in pixels. Both of these are signed and also represents the
; direction of the line of repeated icons. As a side note, you can even have diagonal repeated icons.
;--$04: Horizontal. Positive ($00 to $7F) would extend and fill to the right, negative ($80 to $FF)
;  extends to the left.
;--$05: Vertical. Positive ($00 to $7F) would extend and fill downwards, negative ($80 to $FF)
;  extend upwards.
;-$06: "Empty" icon tile number
;-$07: "Empty" icon tile properties (YXPPCCCT)
;-$08: "Full" icon tile number
;-$09: "Full" icon tile properties (YXPPCCCT)
;-$0A: How many icons are filled
;-$0B: How many total icons there are (max total).
;
;
;Output:
;-Y index: The OAM index after writing all the icons
;-$02: Gets displaced by $07 for each icon written.
;-$03: Gets displaced by $08 for each icon written.
;Destroyed:
;-$0A: Will be [max(0, NumberOfFilledIcons-Total)] when routine is finished, used as a countdown on how many full tiles to write.
;-$0B: Will be #$00 when routine is finished, used as a countdown on how many left to write.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	?WriteRepeatedIconsAsOAM:
	
	?.Loop
		LDA $0B			;\If no more total tiles left, we are done.
		BEQ ?.Done		;/
		
		LDA $02			;\Write each icon displaced (XY pos)
		STA $0300|!addr,y	;|
		LDA $03			;|
		STA $0301|!addr,y	;/
		
		?.FullOrEmpty
			LDA $0A				;\No more full tiles left, write empty
			BEQ ?..Empty			;/
			?..Full
				DEC $0A			;>Deduct number of full tiles
				LDA $08			;\Full tile number
				STA $0302|!addr,y	;/
				LDA $09			;>Full properties
				BRA ?..WriteTileProps
			?..Empty
				LDA $06			;\Empty tile number
				STA $0302|!addr,y	;/
				LDA $07			;>Empty properties
			?..WriteTileProps
				STA $0303|!addr,y	;>Tile properties
		?.OAMExtendedBits
			PHY			;\Set tile size to 8x8.
			TYA			;|
			LSR #2			;|
			TAY			;|
			LDA $0460|!addr,y	;|
			AND.b #%11111101	;|
			STA $0460|!addr,y	;|
			PLY			;/
		
		?..Next
			LDA $02			;\Displacement for next tile.
			CLC			;|
			ADC $04			;|
			STA $02			;|
			LDA $03			;|
			CLC			;|
			ADC $05			;|
			STA $03			;/
			
			INY			;\Next OAM index
			INY			;|
			INY			;|
			INY			;/
			
			DEC $0B			;>Remaining total number of icons to write -1.
			BRA ?.Loop
		
		?.Done
		RTL