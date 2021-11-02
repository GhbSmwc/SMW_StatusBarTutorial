;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine writes a string (sequence of tile numbers in this sense)
;to OAM (horizontally).
;
;To be used for “normal sprites” only, as in sprites part of the 12/22
;sprite slots, not the code that just write to OAM directly like
;sprite status bar patches.
;
;
;Input:
;-!Scratchram_CharacterTileTable to !Scratchram_CharacterTileTable+(NumberOfChar-1):
; The string to display.
;-Y index: The OAM index (increments of 4)
; -$02: X position
; -$03: Y position
; -$04: Number of tiles to write
; -$05: Properties
;Output:
; Y index: The OAM index after writing the last tile character.
;Destroyed:
;$06: Used for displacement to write each character. This is also the "width" of
;the string, in pixels.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteStringAsSpriteOAM:
	RTL