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
;-Y index: The OAM index after writing the last tile character.
;-$06: Used for displacement (in pixels) to write each character. When this routine is finished,
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
	RTL