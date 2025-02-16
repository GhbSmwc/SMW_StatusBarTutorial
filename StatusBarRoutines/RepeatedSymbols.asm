incsrc "../StatusBarRoutinesDefines/Defines.asm"
incsrc "../StatusBarRoutinesDefines/StatusBarDefines.asm"
;Routines listed
; - Horizontal (can be used on stripe image)
; -- WriteRepeatedSymbols
; -- WriteRepeatedSymbolsLeftwards
; -- WriteRepeatedSymbolsFormat2
; -- WriteRepeatedSymbolsLeftwardsFormat2
; - Vertical (don't use these for stripe image)
; -- WriteRepeatedSymbolsWriteVertically
; -- WriteRepeatedSymbolsWriteVerticallyFormat2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Input:
; -$00 (1 byte): the amount filled
; -$01 (1 byte): the total amount (or maximum)
; -$02 (1 byte): Tile number for empty
; -$03 (1 byte): Tile number for full
; -$04-$06 (3 bytes): The status bar address of tiles to write (leftmost tile position,
;  for both rightwards and leftwards).
; -If you have !StatusBar_UsingCustomProperties set to 1, the following will be used:
; --$07 (1 byte): Tile properties for empty
; --$08 (1 byte): Tile properties for full
; --$09-$0B (3 bytes): The status bar address of tile properties to write

;Output:
; -$00: How many extra fills if exceeding max, otherwise 0; FillsLeft = max(AmountFilled - TotalAmount, 0)
; -$01: will be 0 as they're being used to count how many tiles left to write.
; -RAM_In_Addr04 to [RAM_In_Addr04 + ((ValueIn01-1) * !StatusbarFormat)] The
;  repeated tiles in question.
; -RAM_In_Addr09 to [RAM_In_Addr09 + ((ValueIn01-1) * !StatusbarFormat)] The
;   repeated tile properties in question.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteRepeatedSymbols:
	LDY #$00
	
	.Loop
		LDA $01			;\If no tiles left, done.
		BEQ .Done		;/
		LDA $00			;\If no full tiles, write empty.
		BEQ ..Empty		;/
	
		..Full
			LDA $03			;\Write full tile
			STA [$04],y		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $08			;\Write full tile properties
				STA [$09],y		;/
			endif
			DEC $00			;>Decrement how much full tiles left.
			BRA ..Next
	
		..Empty
			LDA $02			;\Write empty tile
			STA [$04],y		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $07			;\Write empty tile properties
				STA [$09],y		;/
			endif
		..Next
			INY 			;>Next status bar tile
			DEC $01			;>Decrement how many total tiles are left.
			BNE .Loop
	
	.Done
		RTL
WriteRepeatedSymbolsLeftwards:
	LDA $01				;\Get index of rightmost icon and start there
	DEC				;|
	if !StatusbarFormat == $02	;|
		ASL			;|
	endif				;|
	TAY				;/
	
	.Loop
		LDA $01			;\If no tiles left, done.
		BEQ .Done		;/
		LDA $00			;\If no full tiles, write empty.
		BEQ ..Empty		;/
	
		..Full
			LDA $03			;\Write full tile
			STA [$04],y		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $08			;\Write full tile properties
				STA [$09],y		;/
			endif
			DEC $00			;>Decrement how much full tiles left.
			BRA ..Next
		..Empty
			LDA $02			;\Write empty tile
			STA [$04],y		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $07			;\Write empty tile properties
				STA [$09],y		;/
			endif
		..Next
			DEY 			;>Next status bar tile
			DEC $01			;>Decrement how many total tiles are left.
			BNE .Loop
	.Done
		RTL
WriteRepeatedSymbolsFormat2:
	LDY #$00
	
	.Loop
		LDA $01			;\If no tiles left, done.
		BEQ .Done		;/
		LDA $00			;\If no full tiles, write empty.
		BEQ ..Empty		;/
	
		..Full
			LDA $03			;\Write full tile
			STA [$04],y		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $08			;\Write full tile properties
				STA [$09],y		;/
			endif
			DEC $00			;>Decrement how much full tiles left.
			BRA ..Next
	
		..Empty
			LDA $02			;\Write empty tile
			STA [$04],y		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $07			;\Write empty tile properties
				STA [$09],y		;/
			endif
		..Next
			INY #2			;>Next status bar tile
			DEC $01			;>Decrement how many total tiles are left.
			BNE .Loop
	.Done
		RTL
WriteRepeatedSymbolsLeftwardsFormat2:
	LDA $01			;\Get index of rightmost icon and start there
	DEC			;|
	ASL			;|
	TAY			;/
	
	.Loop
		LDA $01			;\If no tiles left, done.
		BEQ .Done		;/
		LDA $00			;\If no full tiles, write empty.
		BEQ ..Empty		;/
	
		..Full
			LDA $03			;\Write full tile
			STA [$04],y		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $08			;\Write full tile properties
				STA [$09],y		;/
			endif
			DEC $00			;>Decrement how much full tiles left.
			BRA ..Next
		..Empty
			LDA $02			;\Write empty tile
			STA [$04],y		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $07			;\Write empty tile properties
				STA [$09],y		;/
			endif
		..Next
			DEY #2			;>Next status bar tile
			DEC $01			;>Decrement how many total tiles are left.
			BNE .Loop
	.Done
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Input:
; -$00 (1 byte): the amount filled
; -$01 (1 byte): the total amount (or maximum)
; -$02 (1 byte): Tile number for empty
; -$03 (1 byte): Tile number for full
; -$04-$06 (3 bytes): The status bar address of tile numbers to write (position of the first tile
;  that fills up when increasing).
; -Not used if !StatusBar_UsingCustomProperties == 0:
;  --$07 (1 byte): Tile properties for empty
;  --$08 (1 byte): Tile properties for full
;  --$09-$0B (3 bytes): Same as $04-$06 but for tile properties.
; -$0C (1 byte): Direction, only use these values: $00 = upwards, $01 = downwards
;Output:
; -$00: How many extra fills if exceeding max, otherwise 0; FillsLeft = max(AmountFilled - TotalAmount, 0)
; -$01: will be 0 as they're being used to count how many tiles left to write.
; -[RAM_In_Addr04]-(X*32*!StatusbarFormat) where X increases from 0 to NumberOfTiles-1
;  for upwards, [RAM_In_Addr04]+(X*32*!StatusbarFormat) where X increases from 0 to
;  NumberOfTiles-1 for downwards:
;  the tiles written to the status bar
; -Not used if !StatusBar_UsingCustomProperties == 0:
; --[RAM_In_Addr09]-(X*32*!StatusbarFormat) where X increases from 0 to NumberOfTiles-1
;   for upwards, [RAM_In_Addr09]+(X*32*!StatusbarFormat) where X increases from 0 to
;   NumberOfTiles-1 for downwards: the tile properties written to status bar
; -$04-$06 (3 bytes): The address after writing the last tile (as if writing the amount
;  of tiles plus 1), can be used for writing a tile where the last tile is written.
; -$09-$0B (2 bytes): Same as above.
;
;NOTE: this only works with status bars having a row of 32 8x8 tiles, rows are lined up vertically,
;and each row being contiguous to each other. Else your tiles won't line up vertically.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteRepeatedSymbolsWriteVertically:
	.Loop
		LDA $01			;\If no tiles left, done.
		BEQ .Done		;/
		LDA $00			;\If no full tiles, write empty.
		BEQ ..Empty		;/
		..Full
			LDA $03			;\Write full tile
			STA [$04]		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $08			;\Write full tile properties
				STA [$09]		;/
			endif
			DEC $00			;>Decrement how much full tiles left.
			BRA ..Next
		..Empty
			LDA $02			;\Write empty tile
			STA [$04]		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $07			;\Write empty tile properties
				STA [$09]		;/
			endif
		..Next
			LDX $0C							;\Offset
			REP #$20						;|
			LDA $04							;|
			CLC							;|
			ADC .WriteRepeatedIconsVerticallyUpDownDisplacement,x	;|
			STA $04							;|
			if !StatusBar_UsingCustomProperties != 0
				LDA $09							;|
				CLC							;|
				ADC .WriteRepeatedIconsVerticallyUpDownDisplacement,x	;|
				STA $09							;|
			endif
			SEP #$20						;/
			
			DEC $01			;>Decrement how many total tiles are left.
			BNE .Loop
	.Done
		RTL
	.WriteRepeatedIconsVerticallyUpDownDisplacement
		dw -32		;>RAM $0A = $00
		dw 32		;>RAM $0A = $02
WriteRepeatedSymbolsWriteVerticallyFormat2:
	.Loop
		LDA $01			;\If no tiles left, done.
		BEQ .Done		;/
		LDA $00			;\If no full tiles, write empty.
		BEQ ..Empty		;/
		..Full
			LDA $03			;\Write full tile
			STA [$04]		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $08			;\Write full tile properties
				STA [$09]		;/
			endif
			DEC $00			;>Decrement how much full tiles left.
			BRA ..Next
		..Empty
			LDA $02			;\Write empty tile
			STA [$04]		;/
			if !StatusBar_UsingCustomProperties != 0
				LDA $07			;\Write empty tile properties
				STA [$09]		;/
			endif
		..Next
			LDX $0C								;\Offset
			REP #$20							;|
			LDA $04								;|
			CLC								;|
			ADC .WriteRepeatedIconsVerticallyUpDownDisplacementFormat2,x	;|
			STA $04								;|
			if !StatusBar_UsingCustomProperties != 0
				LDA $09								;|
				CLC								;|
				ADC .WriteRepeatedIconsVerticallyUpDownDisplacementFormat2,x	;|
				STA $09								;|
			endif
			SEP #$20						;/
			
			DEC $01			;>Decrement how many total tiles are left.
			BNE .Loop
	.Done
		RTL
	.WriteRepeatedIconsVerticallyUpDownDisplacementFormat2
		dw -64		;>RAM $0A = $00
		dw 64		;>RAM $0A = $02