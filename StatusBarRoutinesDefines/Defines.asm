;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Defines to setup for SA-1 hybrid support.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	if defined("sa1") == 0
		if read1($00FFD5) == $23
			!sa1 = 1
			sa1rom
		else
			!sa1 = 0
		endif
	endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Other (don't touch)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Digit table location.
	;For these routines:
	;-SixteenBitHexDecDivision
	;-RemoveLeadingZeroes16Bit
	;-SupressLeadingZeros
	;This is due to the fact that the digit table
	;position varies as the 16-bit HexDec routine
	;uses the SNES registers for non SA-1, or
	;uses a division routine which the outputs are
	;at $00-$03.
		!Scratchram_16bitHexDecOutput = $02
		if !sa1 != 0
			!Scratchram_16bitHexDecOutput = $04
		endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Defines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Status bar types and base address
		!StatusbarFormat = $02
		;^Number of grouped bytes per 8x8 tile:
		; $01 = Minimalist/SMB3 [TTTTTTTT, TTTTTTTT]...[YXPCCCTT, YXPCCCTT]
		; $02 = Super status bar/Overworld border plus [TTTTTTTT YXPCCCTT, TTTTTTTT YXPCCCTT]...
		;
		;For use on making status bar codes that have hybrid format support.
		
		!StatusBar_UsingCustomProperties           = 1
		;^0 = Change only the tile numbers, 1 = allow changing the tile properties.
		; Set this to 0 if you don't want to edit the tile properties for status bar, OWB+,
		; and stripe image. When set to 1, some subroutines in HexDec require inputs relating
		; to properties (you can just CTRL+F "!StatusBar_UsingCustomProperties"), otherwise
		; they will not use them at all.
		
		;So far, as of writing this, all status bar patches SMWC allow editing the tile properties.
		;Also note that this does not have hybrid-support (using vanilla status bar, which didn't
		;allow property editing, and using stripe/OWB+ which allows property editing) unless you
		;create 2 versions of subroutines with one utilizing the tile properties and the other not.
	;Status bar starting addresses.
		;RAM address of the first TTTTTTTT byte.
			if !sa1 == 0
				!FreeramFromAnotherPatch_StatusBarTileStart = $7FA000
			else
				!FreeramFromAnotherPatch_StatusBarTileStart = $404000
			endif
		;RAM address of the first YXPCCCTT byte.
			if !sa1 == 0
				!FreeramFromAnotherPatch_StatusBarPropStart = $7FA001
			else
				!FreeramFromAnotherPatch_StatusBarPropStart = $404001
			endif
	;Overworld border starting addresses
		;RAM address of the first TTTTTTTT byte.
			if !sa1 == 0
				!FreeramFromAnotherPatch_OWBorderTileStart = $7FEC00
			else
				!FreeramFromAnotherPatch_OWBorderTileStart = $41EC00
			endif
		;RAM address of the first YXPCCCTT byte.
			if !sa1 == 0
				!FreeramFromAnotherPatch_OWBorderPropStart = $7FEC01
			else
				!FreeramFromAnotherPatch_OWBorderPropStart = $41EC01
			endif
	;Status bar and OWB tiles:
		;Status bar tiles numbers for various symbols
			!StatusBarSlashCharacterTileNumb = $29		;>Slash tile number (status bar, now OWB!)
			!StatusBarBlankTile = $FC			;>Don't change! just in case if you installed a status bar patch that relocated the blank tile.
			!StatusBarDotTile = $24
			!StatusBarPercentTile = $2A
		;Overworld border tiles for various symbols
			!OverWorldBorderSlashCharacterTileNumb = $91
			!OverWorldBorderBlankTile = $1F
			!OverWorldBorderDotTile = $93
			!OverWorldBorderPercentTile = $92
	;32-bit Number display
		;For [Convert32bitIntegerToDecDigits]
			!Setting_32bitHexDec_MaxNumberOfDigits = 10
			;^Number of digits to be stored (fixed) to be allowed to display up to. Use values 1-10
			; because maximum 32-bit unsigned integer is 4,294,967,295.
		
			if !sa1 == 0
				!Scratchram_32bitHexDecOutput = $7F844E
			else
				!Scratchram_32bitHexDecOutput = $404140
			endif
			;^[bytes_used = !Setting_32bitHexDec_MaxNumberOfDigits] The output
			; formatted each byte is each digit 0-9.

	;For [WriteStringDigitsToHUD]
		if !sa1 == 0
			!Scratchram_CharacterTileTable = $7F844A
		else
			!Scratchram_CharacterTileTable = $40414A
		endif
		;^[X bytes] A table containing strings of "characters"
		; (more specifically digits). The number of bytes used
		; is the highest number of characters you would write
		; in your entire game.
		; For example:
		; -If you want to display a 5-digit 16-bit number 65535,
		;  that will be 5 bytes.
		; -If you want to display [10000/10000], that will be
		;  11 bytes (2 numbers up to 5 digits, plus 1 because
		;  "/"; 5 + 5 + 1 = 11)
		; -For 32-bit hexdec:
		; --For displaying a left-aligned number will be !Setting_32bitHexDec_MaxNumberOfDigits
		; --For X/Y display: (!Setting_32bitHexDec_MaxNumberOfDigits*2)+1
	;For 32-bit timer frame to Hours:Minutes:Seconds:Centiseconds format.
		if !sa1 == 0
			!Scratchram_Frames2TimeOutput = $7F846A
		else
			!Scratchram_Frames2TimeOutput = $40416A
		endif
		;^[4 bytes], the output in HH:MM:SS.CC format:
		; !Scratchram_Frames2TimeOutput+0 = hour
		; !Scratchram_Frames2TimeOutput+1 = minutes
		; !Scratchram_Frames2TimeOutput+2 = seconds
		; !Scratchram_Frames2TimeOutput+3 = centiseconds (display 00-99)
	;For percentage converter and displays
		if !sa1 == 0
			!Scratchram_PercentageQuantity = $7F846E
		else
			!Scratchram_PercentageQuantity = $40416E
		endif
		;^[2 bytes] The quantity
		if !sa1 == 0
			!Scratchram_PercentageMaxQuantity = $7F8470
		else
			!Scratchram_PercentageMaxQuantity = $404170
		endif
		;^[2 bytes] The max quantity.
		if !sa1 == 0
			!Scratchram_PercentageFixedPointPrecision = $7F8472
		else
			!Scratchram_PercentageFixedPointPrecision = $404172
		endif
		;^[1 byte] Determines how many digits of display via percentage fixed point:
		;  $00 = XXX%. Overflows if over 65535%.
		;  $01 = XXX.X%, an integer, scaled by 1/10 (example: 503 as an integer stored is 50.3%).
		;        Overflows if over 6553.5%
		;  $02 = XXX.XX%. Same as above but scaled by 1/100. Overflows if over 655.35%.
		;
		;Overflows, as in if you use the 16-bit hexdec. But very unlikely your hack allows
		;percentages over 100.
		!TileNumb_PercentSymbol = $2A
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;OAM settings for sprite HUD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Starting OAM slot to use:
		!Setting_HUDStartingSpriteOAMToUse = 4
		 ;^Starting slot number to use (increments of 1) for checking, not to be confused with index (which increments by 4). Use only values 0-127 ($00-$7F).