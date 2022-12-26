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
	;Status bar type
		!StatusbarFormat = $02
		;^Number of grouped bytes per 8x8 tile:
		; $01 = Minimalist/SMB3 [TTTTTTTT, TTTTTTTT]...[YXPCCCTT, YXPCCCTT]
		; $02 = Super status bar/Overworld border plus [TTTTTTTT YXPCCCTT, TTTTTTTT YXPCCCTT]...
		;
		;For use on making status bar codes that have hybrid format support.
		
		!StatusBar_UsingCustomProperties           = 0
		;^Set this to 0 if you are using the vanilla SMW status bar or any status bar patches
		; that doesn't enable editing the tile properties, otherwise set this to 1 (you may
		; have to edit "!Default_GraphicalBarProperties" in order for it to work though.).
		; This define is needed to prevent writing what it assumes tile properties into invalid
		; RAM addresses.
		
	;Status bar and OWB tiles:
		;Status bar tiles
			!StatusBarSlashCharacterTileNumb = $29		;>Slash tile number (status bar, now OWB!)
			!StatusBarBlankTile = $FC			;>Don't change! just in case
			;^Tile number for where there is no characters to be written for each 8x8 space.
		;Overworld border tiles
			!OverWorldBorderSlashCharacterTileNumb = $91
			!OverWorldBorderBlankTile = $1F
	;For [Convert32bitIntegerToDecDigits]
		!MaxNumberOfDigits = 9
		;^Number of digits to be stored (fixed). Use values 1-10 because maximum
		; 32-bit unsigned integer is 4,294,967,295.
	
		if !sa1 == 0
			!Scratchram_32bitHexDecOutput = $7F844E
		else
			!Scratchram_32bitHexDecOutput = $404000
		endif
		;^[bytes_used = !MaxNumberOfDigits] The output
		; formatted each byte is each digit 0-9.

	;For [WriteStringDigitsToHUD]
		if !sa1 == 0
			!Scratchram_CharacterTileTable = $7F844A
		else
			!Scratchram_CharacterTileTable = $40400A
		endif
		;^[X bytes] A table containing strings of "characters"
		; (more specifically digits). The number of bytes used
		; is how many characters you would write.
		; For example:
		; -If you want to display a 5-digit 16-bit number 65535,
		;  that will be 5 bytes.
		; -If you want to display [10000/10000], that will be
		;  11 bytes (there are 5 digits on each 10000, plus 1
		;  because "/"; 5 + 5 + 1 = 11)
	;For 32-bit timer frame to Hours:Minutes:Seconds:Centiseconds format.
		if !sa1 == 0
			!Scratchram_Frames2TimeOutput = $7F8454
		else
			!Scratchram_Frames2TimeOutput = $404015
		endif
		;^[4 bytes], the output in HH:MM:SS.CC format:
		; !Scratchram_Frames2TimeOutput+0 = hour
		; !Scratchram_Frames2TimeOutput+1 = minutes
		; !Scratchram_Frames2TimeOutput+2 = seconds
		; !Scratchram_Frames2TimeOutput+3 = centiseconds (display 00-99)
	;For percentage converter and displays
		if !sa1 == 0
			!Scratchram_PercentageQuantity = $7F844E
		else
			!Scratchram_PercentageQuantity = $404019
		endif
		;^[2 bytes] The quantity
		if !sa1 == 0
			!Scratchram_PercentageMaxQuantity = $7F8450
		else
			!Scratchram_PercentageMaxQuantity = $40401B
		endif
		;^[2 bytes] The max quantity.
		if !sa1 == 0
			!Scratchram_PercentageFixedPointPrecision = $7F8452
		else
			!Scratchram_PercentageFixedPointPrecision = $40401D
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