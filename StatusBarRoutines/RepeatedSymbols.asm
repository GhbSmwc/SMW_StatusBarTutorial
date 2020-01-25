!StatusbarFormat = $01			;>$01 = [TTTTTTTT, TTTTTTTT,...], $02 = [TTTTTTTT, YXPCCCTT, TTTTTTTT, YXPCCCTT...]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Write repeated symbols.
;This will write an array of repeated tiles with
;n of them being "full" and the rest "empty".
;Input:
; $00 (8-bit): the amount filled
; $01 (8-bit): the total amount (or maximum)
; $02 (8-bit): 8x8 tile number for empty
; $03 (8-bit): 8x8 tile number for full
; $04-$06 (24-bit): The status bar address of where to write,
;Output: 
; RAM_In_Addr04 to [RAM_In_Addr04 + ((ValueIn01-1) * !StatusbarFormat)] The
;  repeated tiles in question.
;Overwritten:
; $00-$01: will be 0 as they're being used to count
;  how many tiles left to write.
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
	DEC $00			;>Decrement how much full tiles left.
	BRA ..Next
	
	..Empty
	LDA $02			;\Write empty tile
	STA [$04],y		;/
	
	..Next
	INY #!StatusbarFormat	;>Next status bar tile
	DEC $01			;>Decrement how many of all tiles are left.
	BNE .Loop
	
	.Done
	RTL
WriteRepeatedSymbolsLeftwards:
	LDA $01
	DEC
	if !StatusbarFormat == $02
		ASL
	endif
	TAY
	
	.Loop
	LDA $01			;\If no tiles left, done.
	BEQ .Done		;/
	LDA $00			;\If no full tiles, write empty.
	BEQ ..Empty		;/
	
	..Full
	LDA $03			;\Write full tile
	STA [$04],y		;/
	DEC $00			;>Decrement how much full tiles left.
	BRA ..Next
	
	..Empty
	LDA $02			;\Write empty tile
	STA [$04],y		;/
	
	..Next
	DEY #!StatusbarFormat	;>Next status bar tile
	DEC $01			;>Decrement how many of all tiles are left.
	BNE .Loop
	
	.Done
	RTL