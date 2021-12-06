;List of routines:
;-WriteStringAsSpriteOAM
;-GetStringXPositionCentered
;-WriteRepeatedIconsAsOAM
;-CenterRepeatingIcons
;-WriteStringAsSpriteOAM_OAMOnly
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
;-$05: Properties (YXPPCCCT), will apply to all characters.
;-$06 to $08 (3 bytes): 24-bit address location of the table for converting characters to number graphics. Each byte in table lays out as follows:
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
	LDX #$00	;>Initialize loop count
	.LoopWrite
			
		..Write
			LDA $02					;\X position, plus displacement
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
			LDA $02					;\Next character is 8 pixels foward.
			CLC					;|
			ADC #$08				;|
			STA $02					;/
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
;-$0A: How many tiles are filled
;-$0B: How many total tiles are filled (max total).
;
;
;Output:
;-Y index: The OAM index after writing all the icons
;-$02: Gets displaced by $07 for each icon written.
;-$03: Gets displaced by $08 for each icon written.
;Destroyed:
;-$0A: Will be [max(0, Total-NumberOfFilledIcons)] when routine is finished, used as a countdown on how many full tiles to write.
;-$0B: Will be #$00 when routine is finished, used as a countdown on how many left to write.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	WriteRepeatedIconsAsOAM:
	
	.Loop
		LDA $0B			;\If no more total tiles left, we are done.
		BEQ .Done		;/
		
		LDA $02			;\Write each icon displaced (XY pos)
		STA $0300|!addr,y	;|
		LDA $03			;|
		STA $0301|!addr,y	;/
		
		.FullOrEmpty
			LDA $0A				;\No more full tiles left, write empty
			BEQ ..Empty			;/
			..Full
				DEC $0A			;>Deduct number of full tiles
				LDA $08			;\Full tile number
				STA $0302|!addr,y	;/
				LDA $09			;>Full properties
				BRA ..WriteTileProps
			..Empty
				LDA $06			;\Empty tile number
				STA $0302|!addr,y	;/
				LDA $07			;>Empty properties
			..WriteTileProps
				STA $0303|!addr,y	;>Tile properties
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
			BRA .Loop
		
		.Done
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Center repeating icons. This is for "WriteRepeatedIconsAsOAM" To
;find the midpoint between the XY position of the first and last
;icon. This is needed to center this around a given point.
;
;Formula:
;
;XOrYPositionOfFirstIcon = InputCenter - (((TotalIcons-1)*Displacement)/2)
;
;Which is processed in this order:
;
;((((TotalIcons-1)*Displacement)/2) * -1) + InputCenter
;
;InputCenter = Given center point as the input.
;TotalIcons = Total number of icons (max).
;Displacement = (signed) displacement between each icon.
;
;Input:
;-$02: X position relative to screen border (you can take $00/$01, offset it (add by some number), and write on here).
;-$03: Same as above but Y position
;-$04: X Displacement for each icon (signed)
;-$05: Y Displacement for each icon (signed)
;-$06: Max/total number of icons.
;Output:
;-$02: X position for the repeated icons to be centered
;-$03: same as above but for Y.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CenterRepeatingIcons:
	PHY
	LDY #$01
	.Loop
		LDA $06				;\No icons = no using this formula
		BEQ .Done			;/
		DEC A				;>(TotalIcons-1)
		..Multiplying			;>...Multiply by displacement
		if !sa1 == 0
			STA $4202		;>Multiplicand A
			LDA $0004|!dp,y		;>Displacement
			BPL ...Positive
			...Negative			;>TotalIcons (positive) * Displacement (negative)
				EOR #$FF
				INC A
				STA $4203		;>Multiplicand B
				JSR .WaitCalculation
				REP #$20
				LDA $4216		;>Product
				LSR			;
				SEP #$20		;
				;We skip EOR INC since double-negative cancels out
				BRA ..WriteOutput
			...Positive			;>TotalIcons (positive) * Displacement (positive)
				STA $4203		;>Multiplicand B
				JSR .WaitCalculation
				REP #$20
				LDA $4216		;>Product
				LSR			;>/2
				SEP #$20		;\*-1
				EOR #$FF		;|
				INC A			;/
		else
			PHX
			LDX #$00			;\Multiply mode
			STX $2250			;/
			PLX
			STA $2251			;\Multiplicand A (total icons, unsigned)
			STZ $2252			;/
			LDA $0004|!dp,y			;\Multiplicand B (displacement, signed)
			BMI ...NegativeMultiplicandB
			
			...PositiveMultiplicandB
				STA $2253
				STZ $2254		;>Upon writing this byte, it should calculate in 5 cycles.
				BRA ...SignedHandlerDone
			...NegativeMultiplicandB
				STA $2253
				LDA #$FF
				STA $2254		;>Upon writing this byte, it should calculate in 5 cycles.
			...SignedHandlerDone
			NOP				;\Wait 5 cycles
			BRA $00				;/
			LDA $2306			;>Product (SA-1 multiplication are signed)
			BPL ...Positive
			...Negative			;>TotalIcons (positive) * Displacement (negative)
				EOR #$FF		;\Negative number divided by positive 2, then times -1
				INC A			;|Since we already inverted the number in the process of dividing by 2
				LSR			;|we don't need to convert it back (this is unoptimized since last two inverters cancel out: EOR #$FF : INC A : LSR : EOR #$FF INC A : EOR #$FF INC A)
				;EOR #$FF		;|(LSR shifts the bit to the right, and that alone would not correctly take a negative number and divide by 2)
				;INC A			;/
				BRA ..WriteOutput
			...Positive			;>TotalIcons (positive) * Displacement (positive)
				LSR			;>/2
				EOR #$FF		;\*-1
				INC A			;/
		endif
		..WriteOutput
			CLC			;\+InputCenter
			ADC $02|!dp,y		;/
			STA $02|!dp,y		;>Output
			DEY
			BPL .Loop
	
	.Done
	PLY
	RTL
	if !sa1 == 0
		.WaitCalculation:	;>The register to perform multiplication and division takes 8/16 cycles to complete.
		RTS
	endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Same as WriteStringAsSpriteOAM, but deals with just writing to OAM,
;not to be used for normal sprites.
;
;
;Input:
;-!Scratchram_CharacterTileTable to !Scratchram_CharacterTileTable+(NumberOfChar-1):
; The string to display. Will be written directly to $0200,y
;-Y Index: Which OAM slot to check, starting from !Setting_HUDStartingSpriteOAMToUse
;-$00 to $01: (16-bit) X position, relative to screen border
;-$02 to $03: (16-bit) Y position, relative to screen border
;-$04 to $05: Number of tiles to write, minus 1.
;-$06: Properties (YXPPCCCT), will apply to all characters.
;-$07 to $09 (3 bytes): 24-bit address location of the table for converting characters to number graphics. Each byte in table lays out as follows:
;--$00 to $09 are number tiles, which are for 0-9 digit graphics.
;--$0A = "/"
;Overwritten:
;$00 to $01: Displaced after each write of the tile.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteStringAsSpriteOAM_OAMOnly:
	PHB
	PHK
	PLB
	;Convert digits into sprite graphics
	PHY
	LDX $04
	.LoopConvert
		LDA !Scratchram_CharacterTileTable,x
		TAY
		LDA [$07],y
		STA !Scratchram_CharacterTileTable,x
		
		..Next
			DEX
			BPL .LoopConvert
	PLY
	;Is enough open slots available?
	REP #$10			;\Check if enough slots found. If there are less open slots then number of tiles to write
	LDX $04				;|don't write at all.
	PHX				;|
	INX				;|
	JSR FindNFreeOAMSlot		;|
	PLX				;|
	BCC +				;|
	JMP .Done			;/
	+
	LDX #$0000			;>Slot counter
	.WriteString
		LDY.w #!Setting_HUDStartingSpriteOAMToUse*4 ;>Start writing at the first slot specified.
		..OAMLoop
			;Is used?
			...CheckOAMUsed
				LDA $0201|!addr,y
				CMP #$F0
				BEQ ....NotUsed
				....Used
					INY #4
					BRA ...CheckOAMUsed
				....NotUsed
			;Screen and positions
			...CheckIfOnScreen
				REP #$20		;\Offscreen horizontally. If offscreen, go to next tile reusing the same OAM slot (avoid hogging slots for nothing)
				LDA $00			;|
				CMP #$FFF8+1		;|
				SEP #$20		;|
				BMI ...Next		;|
				REP #$20		;|
				CMP #$0100		;|
				SEP #$20		;|
				BPL ...Next		;/
				REP #$20		;\Same but vertically
				LDA $02			;|
				CMP #$FFF8+1		;|
				SEP #$20		;|
				BMI ...Next		;|
				REP #$20		;|
				CMP #$00E0		;|
				SEP #$20		;|
				BPL ...Next		;/
			...XPos
				LDA $00			;\Low 8 bits
				STA $0200|!addr,y	;/
				TYA			;\Y = slot, not index, temporally
				LSR #2			;|
				PHY			;|
				TAY			;/
				LDA $01			;\9th bit X position
				SEP #$20		;|
				AND.b #%00000001	;|
				STA $0420|!addr,y	;/
				PLY
			...YPos
				LDA $02
				STA $0201|!addr,y
			...TileNumber
				LDA !Scratchram_CharacterTileTable,x
				STA $0202|!addr,y
			...TileProps
				LDA $06
				STA $0203|!addr,y
			...NextTile
				INY #4			;Next OAM slot (go to the next if the OAM tile is onscreen)
			...Next
				REP #$20		;\Displace tile
				LDA $00			;|
				CLC			;|
				ADC #$0008		;|
				STA $00			;|
				SEP #$20		;/
				INX			;\Next character
				CPX $04			;/
				BCC ..OAMLoop		;>Loop until all characters written
	.Done
	PLB
	RTL
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Find if enough slots are open
;Input: $04 = Number of slots open to search for
;Output: Carry = Set if not enough slots found, Clear if enough slots found
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FindNFreeOAMSlot:
	PHY
	LDY.w #$0000					;>Open slot counter
	LDX.w #!GraphicalBar_OAMSlot*4			;>skip the first four slots
	.loop:						;>to avoid message box conflicts
		CPX #$0200				;\If all slots searched, there is not enough
		BEQ .notEnoughFound			;/open slots being found

		LDA $0201|!addr,x			;\If slot used, that isn't empty
		CMP #$F0				;|
		BNE ..notFree				;/
		
		..Free
		INY					;>Otherwise if it is unused, count it
		CPY $04					;\If we find n slots that are free, break
		BEQ .enoughFound			;/
		..notFree:
			INX #4				;\Check another slot
			BRA .loop			;/
	.notEnoughFound:
		SEC
		BRA .Done
	.enoughFound:
		CLC
	.Done
		PLY
		RTS