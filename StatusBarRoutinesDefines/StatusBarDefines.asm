;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SA-1 handling (don't touch here)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Only include this if there is no SA-1 detection, such as including this
;in a (seperate) patch.
if defined("sa1") == 0
	!dp = $0000
	!addr = $0000
	!sa1 = 0
	!gsu = 0

	if read1($00FFD6) == $15
		sfxrom
		!dp = $6000
		!addr = !dp
		!gsu = 1
	elseif read1($00FFD5) == $23
		sa1rom
		!dp = $3000
		!addr = $6000
		!sa1 = 1
	endif
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
		!UsingCustomStatusBar = 1
			;^0 = Using vanilla SMW status bar
			; 1 = Using any layer 3 custom status bar.
			; These are needed for determining what coordinate system.
	;Status bar tile data starting addresses
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
		;Misc
			!TileNumb_PercentSymbol = $2A
	;Below here, defines revolving around XY positions are positions (in units of tiles) to place the display element
	;(XY position must be an integer).
	; - X=0 is the leftmost position, increases when going rightwards. X=31 ($1F) would normally be at the right edge of the screen
	; - Y=0 is the topmost position, increases when going downwards. Y=27 would normally be at the bottom of the screen in theory if
	;   the status bar patch allow numbering all rows of the layer.
	;
	;As always, a number without a prefix are decimal, unless you prefix them with a dollar sign ("$")
	;to tell the compiler asar that they're hex.
	
	;Position to display most things onto the HUD for various elements (numbers, repeated icons, etc.)
		!StatusBar_TestDisplayElement_PosX = 0
		!StatusBar_TestDisplayElement_PosY = 0
	;Position to display right-aligned numbers (This is the position of the rightmost tile, a position entered here will take this
	;position and anything to the left)
		!StatusBar_TestDisplayRightAlignedNumber_PosX = 31
		!StatusBar_TestDisplayRightAlignedNumber_PosY = 0
	;RAM to display its amount. The number of bytes used on each of these are obvious. Also obvious to avoid running multiple ASM
	;files for a level using the same RAM at the same time.
		;For 8-bit counters
			!StatusBar_TestDisplayElement_RAMToDisplay1_1Byte = $60
			!StatusBar_TestDisplayElement_RAMToDisplay2_1Byte = $61
		;16-bit counters
			!StatusBar_TestDisplayElement_RAMToDisplay1_2Bytes = $60
			!StatusBar_TestDisplayElement_RAMToDisplay2_2Bytes = $62
		;32-bit counters
			!StatusBar_TestDisplayElement_RAMToDisplay1_4Bytes = $60
			!StatusBar_TestDisplayElement_RAMToDisplay2_4Bytes = $0F3A|!addr
		;Counting animations
			!StatusBar_TestDisplayElement_CountAnimation1_1Byte = $61 ;>The "adder", which decrements itself by 1 per frame and adds !StatusBar_TestDisplayElement_RAMToDisplay1_1Byte by 1 each frame
			!StatusBar_TestDisplayElement_CountAnimation2_1Byte = $62 ;>The "subtractor", which decrements itself by 1 per frame and subtracts !StatusBar_TestDisplayElement_RAMToDisplay1_1Byte by 1 each frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Don't edit unless you know what you're doing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Patched status bar. Feel free to use this.
		function PatchedStatusBarXYToAddress(x, y, StatusBarTileDataBaseAddr, format) = StatusBarTileDataBaseAddr+(x*format)+(y*32*format)
		;You don't have to do STA $7FA000+StatusBarXYToByteOffset(0, 0, $02) when you can do STA PatchedStatusBarXYToAddress(0, 0, $7FA000, $02)
		
		macro CheckValidPatchedStatusBarPos(x,y)
			assert and(greaterequal(<x>, 0), lessequal(<x>, 31)), "Invalid position on the patched status bar"
		endmacro
	
	;Vanilla SMW status bar. Again, feel free to use this.
		function VanillaStatusBarXYToAddress(x,y, SMWStatusBar0EF9) = (select(equal(y,2), SMWStatusBar0EF9+(x-2), SMWStatusBar0EF9+$1C+(x-3)))
		
		macro CheckValidVanillaStatusBarPos(x,y)
			assert or(and(equal(<y>, 2), and(greaterequal(<x>, 2), lessequal(<x>, 29))), and(equal(<y>, 3), and(greaterequal(<x>, 3), lessequal(<x>, 29)))), "Invalid position on the vanilla status bar"
		endmacro
		
		if !sa1 == 0
			!RAM_0EF9 = $0EF9
		else
			!RAM_0EF9 = $400EF9
		endif
	!Default_TestElement_Pos_Tile = VanillaStatusBarXYToAddress(!StatusBar_TestDisplayElement_PosX, !StatusBar_TestDisplayElement_PosY, !RAM_0EF9)
	if !UsingCustomStatusBar != 0
		!Default_TestElement_Pos_Tile = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayElement_PosX, !StatusBar_TestDisplayElement_PosY, !FreeramFromAnotherPatch_StatusBarTileStart, !StatusbarFormat)
		!Default_TestElement_Pos_Prop = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayElement_PosX, !StatusBar_TestDisplayElement_PosY, !FreeramFromAnotherPatch_StatusBarPropStart, !StatusbarFormat)
		
		!Default_TestElement_RightAlignedText_Pos_Tile = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayRightAlignedNumber_PosX, !StatusBar_TestDisplayRightAlignedNumber_PosY, !FreeramFromAnotherPatch_StatusBarTileStart, !StatusbarFormat)
		!Default_TestElement_RightAlignedText_Pos_Prop = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayRightAlignedNumber_PosX, !StatusBar_TestDisplayRightAlignedNumber_PosY, !FreeramFromAnotherPatch_StatusBarPropStart, !StatusbarFormat)
	endif