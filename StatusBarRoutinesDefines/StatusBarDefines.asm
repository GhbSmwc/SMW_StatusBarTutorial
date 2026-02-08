includeonce
 ;^Prevent redefinition errors (this define file you're reading right now contains a function and asar cannot allow that to be redefined)
 ; This happens because the patch in "Patch_SpriteStatusBarTest/SpriteHUDTest.asm" includes this define file as well as sububroutines file
 ; which they themselves also include this define file, causing redefinition issues if "includeonce" is not being used.
 
;This define file is for HUD-related content. Things like where on the HUD to be written, sample RAM to display, and tiles to use.
;For routine-specific settings like what RAM to use for routine input/output values, see "Defines.asm" instead.
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
			;^Set this to 0 if you are only using vanilla status bar, status bar patches, and/or overworld border
			; plus patch that have tile properties automatically set proper. Otherwise set this to 1 (if you need
			; to set the tile properties).
			;
			; This define is needed as there are subroutines that either write only to tile numbers, or both tile
			; numbers and properties.
			
			;So far, as of writing this, all status bar patches SMWC allow editing the tile properties.
			;Also note that this does not have hybrid-support (using vanilla status bar, which didn't
			;allow property editing, and using stripe/OWB+ which allows property editing) unless you
			;create 2 versions of subroutines with one utilizing the tile properties and the other not.
			;
			;If using stripe image, this is needed to be set to 1 else invalid tile properties will be used,
			;resulting in garbage tiles appearing.
		!UsingCustomStatusBar = 1
			;^0 = Using vanilla SMW status bar
			; 1 = Using any layer 3 custom status bar.
			; These are needed for determining what coordinate system.
	;Status bar and OWB tiles:
	;Note: These are tile numbers and properties.
	;-Tile numbers refer to what tile within a page
	;-Tile properties are YXPCCCTT, in binary (notice the percent symbol prefix).
		;Status bar and Layer 3 stripe tiles for various symbols
			!StatusBarSlashCharacterTileNumb = $29		;>Slash tile number (status bar, now OWB!)
			!StatusBarBlankTile = $FC			;>Don't change! just in case if you installed a status bar patch that relocated the blank tile.
			!StatusBarDotTile = $24
			!StatusBarPercentTile = $2A
			!StatusBarPlusSymbol = $2B
			!StatusBarMinusSymbol = $27			;>A symbol used to display negative numbers (signed hexdec).
			!StatusBarColon = $78				;>Used by course clear and this ASM resource's timer
			;8x16 characters
				!StatusBar8x16TopSlash = $2C
				!StatusBar8x16BottomSlash = $2D
			
			!StatusBar_TileProp = %00111000
			
			!StatusBar_RepeatedSymbols_FullTile = $2E
			!StatusBar_RepeatedSymbols_FullProp = %00111000
			!StatusBar_RepeatedSymbols_EmptyTile = $26
			!StatusBar_RepeatedSymbols_EmptyProp = %00111000
		;Overworld border tiles for various symbols
			!OverWorldBorderSlashCharacterTileNumb = $91
			!OverWorldBorderBlankTile = $1F
			!OverWorldBorderDotTile = $93
			!OverWorldBorderPercentTile = $92
			!OverWorldBorderPlusSymbol = $15
			!OverWorldBorderMinusSymbol = $14
			
			
			!OverWorldBorder_TileProp = %00111001
		;Misc
			!TileNumb_PercentSymbol = $2A
	;Below here, defines involving XY positions are positions (in units of tiles) to place the display element
	;(XY position must be an integer).
	; - X=0 is the leftmost position, increases when going rightwards. X=31 ($1F) would normally be at the right edge of the screen
	; - Y=0 is the topmost position, increases when going downwards. Y=27 would normally be at the bottom of the screen in theory if
	;   the status bar patch allow numbering all rows of the layer.
	;
	;As always, a number without a prefix are decimal, unless you prefix them with a dollar sign ("$")
	;to tell the compiler asar that they're hex.
	;
	; The range of positions that are valid depends on what type of status bar you're using:
	; - Vanilla SMW: Y can only be 2-3. And...
	; -- When Y=2, X ranges 2-29.
	; -- When Y=3, X ranges 3-29.
	; - Super status bar patch: X:0-31, Y:0-4.
	; - SMB3 status bar: X:0-31, Y:0-3
	; - Minimalist status bar top OR bottom: X:0-31. Y is *ALWAYS* 0.
	; - Minimalist status bar double: X:0-31, Y:0-1. Y=0 for top row, Y=1 for bottom row.
	;
	; Entering a position outside of the valid range may result in using a RAM address that
	; is outside the status bar tile data (which may cause glitches or crash your game).
	; This may also occur even if you use a valid position, for display elements made up of
	; multiple tiles and those tiles extend beyond the first or last byte of the tile data
	; (such as a 2-digit counter placed so the 10s digit of the counter is on the bottom-
	; rightmost of the editable tile area, causing the 1s place to be written outside the
	; tile data range).
	;
	; This define ASM file does have an assert failsafe against invalid XY positions, but
	; it is not entirely foolproof due to each status bar types having different tile range
	; and display elements spans many number of tiles to be written down.
	
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
		;Position to display most things onto the HUD for various elements (numbers, horizontal repeated symbol, etc.)
			!StatusBar_TestDisplayElement_PosX = 0
			!StatusBar_TestDisplayElement_PosY = 0
		;Position to display repeated symbol vertically (this is the position of the first symbol to fill up)
			!StatusBar_TestDisplayElement_VerticalRepeatedIconsDownwards_PosX = 0 ;\Position of the top tile, fills downwards
			!StatusBar_TestDisplayElement_VerticalRepeatedIconsDownwards_PosY = 0 ;/
			
			!StatusBar_TestDisplayElement_VerticalRepeatedIconsUpwards_PosX = 0 ;\Position of the bottom tile, fills upwards
			!StatusBar_TestDisplayElement_VerticalRepeatedIconsUpwards_PosY = 4 ;/
		;Position to display right-aligned numbers (This is the position of the rightmost tile, a position entered here will take this
		;position and anything to the left)
			!StatusBar_TestDisplayRightAlignedNumber_PosX = 31
			!StatusBar_TestDisplayRightAlignedNumber_PosY = 0
	;Overworld border positioning stuff. Same rule as the status bar if you enter invalid
	;coordinates.
	;
	; When using overworld border plus, The X positioning functions exactly the same way
	; as using the super status bar patch, ranging 0-31. However the Y-positioning works
	; a little different. The Y position to address skips the intermediate rows between
	; the top and bottom areas that are controlled by RAM. For example: When OWB+'s
	; !Top_Lines is set to 5, then the top rows Y position would range from 0-4, and a
	; Y position of 5 would point to the first row of the bottom area. This means to
	; figure out the Y value of the bottom area, you calculate as follows:
	;
	;  EditableYPosition = TrueYPosition - 26 + !Top_Lines
	;
	; For example (having !Top_Lines set to 5), I want a counter on the top row of
	; bottom lines. I can literally just do this:
	;
	;  !Default_GraphicalBar_PosY_OverworldMap = 26-26+5, which is row 5 (rows 0-4 are top lines, 5-6 are bottom lines)
	
		;Position to display most things onto the OWB
			!OverworldBorder_TestDisplayElement_PosX = 0
			!OverworldBorder_TestDisplayElement_PosY = 0
		;Position to display right-aligned numbers
			!OverworldBorder_TestDisplayRightAlignedNumber_PosX = 31
			!OverworldBorder_TestDisplayRightAlignedNumber_PosY = 0
	;Stripe positions. Remember to have these settings:
	; - [check] Force Layer 3 tiles with priority above other layers and sprites
	; - [check] Enable advanced bypass settings for Layer 3
	; - [uncheck] CGADSUB for Layer 3
	; - [uncheck] Move layer 3 to subscreen
	; - Vertical scroll: None
	; - Horizontal scroll: None
	; - Initial Y position: 0
	; - Initial X position: 0
	;
	;Positions work the same with the status bar and overworld border plus patch.
	;
	;However, because the layer 3 tilemap can now be a 2x2 screen area, the range for X
	;and Y positions can now be 0-63. But there are caveats:
	; - Positions are handled per-screen internally, rather than absolute, as the subroutine
	;   "SetupStripe" converts them into per-screen relative. For example: Absolute position
	;   of (32,32) would be the bottom-right screen at its top-left corner (0,0). The
	;   positions you enter here are absolute and you still enter X:0-31 like you would for
	;   a status bar and overworld border patch, but the Y position can now range from 0-27.
	;
	; -- To add to above, any multi-tile writes crossing the screen border to the right will
	;    wrap to the left (to relative X=0) and down 1 row (Y+1). Crossing the screen border
	;    downwards or rightwards on the last row will end up on the "next screen" keeping
	;    the X position but on that new screen (the 4 screens are ordered from top-left,
	;    top-right, bottom-left, then bottom-right). Exceeding the last screen may cause
	;    graphic data corruption.
	; - The positions are with respect to the top-left of the layer, regardless of scrolling.
		;Positions of most stripe display counters
			!Layer3Stripe_TestDisplayElement_PosX = 1
			!Layer3Stripe_TestDisplayElement_PosY = 26
		;right-aligned stuff (as always, this is the position of the rightmost tile)
			!Layer3Stripe_TestDisplayRightAlignedNumber_PosX = 30
			!Layer3Stripe_TestDisplayRightAlignedNumber_PosY = 26
	
	;FreeRAM to display its amount, for both all meters on status bar, overworld borders, stripes, and sprites. The
	;number of bytes used on each of these are obvious. Also obvious to avoid running multiple ASM files for a level
	;using the same RAM at the same time.
	;
	;NOTE: If using SA-1, routines that involve writing a 3-byte address itself into scratch RAM for Direct Indirect
	;Long (instructions with"[$xx]") using 2 or fewer bytes (such as $60 instead of $7E0060) may not work.
	; - An example was "CountingAnimation16Bit". In this case, you should use "$60|!dp" and "$62|!dp" for
	;   !Freeram_ValueDisplay1_2Bytes and !Freeram_ValueDisplay2_2Bytes instead of "$60" and "$62". What's happening
	;   here is that SA-1 maps $60 to $003060 and $62 to $003062. Not having the "|$xx!dp" causes asar to interpret
	;   that as $60 to be $000060 and $62 to be $000062, which are incorrect.
		;For 8-bit counters (including repeated symbols)
			!Freeram_ValueDisplay1_1Byte = $60
			!Freeram_ValueDisplay2_1Byte = $61
		;16-bit counters
			!Freeram_ValueDisplay1_2Bytes = $60
			!Freeram_ValueDisplay2_2Bytes = $62
		;32-bit counters (Including frame counter)
			!Freeram_ValueDisplay1_4Bytes = $60
			!Freeram_ValueDisplay2_4Bytes = $0F3A|!addr
		;Counting animations
			!StatusBar_TestDisplayElement_CountAnimation1_1Byte = $61 ;>The "adder", which decrements itself by 1 per frame and adds !Freeram_ValueDisplay1_1Byte by 1 each frame
			!StatusBar_TestDisplayElement_CountAnimation2_1Byte = $62 ;>The "subtractor", which decrements itself by 1 per frame and subtracts !Freeram_ValueDisplay1_1Byte by 1 each frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Don't edit unless you know what you're doing
;Feel free to use these.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	if not(defined("FunctionGuard_StatusBarFunctionDefined"))
		;^This if statement prevents an issue where "includeonce" is "ignored" if two ASMs files
		; incsrcs to the same ASM file with a different path due to asar not being able to tell
		; if the incsrc'ed file is the same file: https://github.com/RPGHacker/asar/issues/287
		
		;Patched status bar.
			function PatchedStatusBarXYToAddress(x, y, StatusBarTileDataBaseAddr, format) = StatusBarTileDataBaseAddr+(x*format)+(y*32*format)
			;You don't have to do STA $7FA000+StatusBarXYToByteOffset(0, 0, $02) when you can do STA PatchedStatusBarXYToAddress(0, 0, $7FA000, $02)
			
			macro CheckValidPatchedStatusBarPos(x,y)
				assert and(greaterequal(<x>, 0), lessequal(<x>, 31)), "Invalid position on the patched status bar"
			endmacro
		
		;Vanilla SMW status bar.
			function VanillaStatusBarXYToAddress(x,y, SMWStatusBar0EF9) = (select(equal(y,2), SMWStatusBar0EF9+(x-2), SMWStatusBar0EF9+$1C+(x-3)))
			
			macro CheckValidVanillaStatusBarPos(x,y)
				assert or(and(equal(<y>, 2), and(greaterequal(<x>, 2), lessequal(<x>, 29))), and(equal(<y>, 3), and(greaterequal(<x>, 3), lessequal(<x>, 29)))), "Invalid position on the vanilla status bar"
			endmacro
			
			if !sa1 == 0
				!RAM_0EF9 = $0EF9
			else
				!RAM_0EF9 = $400EF9
			endif
		;Get YXPCCCTT
			function GetLayer3YXPCCCTT(Y,X,P,CCC,TT) = ((Y<<7)+(X<<6)+(P<<5)+(CCC<<2)+TT)
		;Mark that the macros and functions are now defined
			!FunctionGuard_StatusBarFunctionDefined = 1
	endif
	;Frames2Timer (this converts multiple units of time into total number of frames).
		function TimerToFrames(Hours, Minutes, Seconds, Frames) = (Hours*216000)+(Minutes*3600)+(Seconds*60)+Frames
	!StatusBar_TestDisplayElement_Pos_Tile = VanillaStatusBarXYToAddress(!StatusBar_TestDisplayElement_PosX, !StatusBar_TestDisplayElement_PosY, !RAM_0EF9)
	if !UsingCustomStatusBar != 0
		!StatusBar_TestDisplayElement_Pos_Tile = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayElement_PosX, !StatusBar_TestDisplayElement_PosY, !FreeramFromAnotherPatch_StatusBarTileStart, !StatusbarFormat)
		!StatusBar_TestDisplayElement_Pos_Prop = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayElement_PosX, !StatusBar_TestDisplayElement_PosY, !FreeramFromAnotherPatch_StatusBarPropStart, !StatusbarFormat)
		
		!StatusBar_TestDisplayElement_RightAlignedText_Pos_Tile = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayRightAlignedNumber_PosX, !StatusBar_TestDisplayRightAlignedNumber_PosY, !FreeramFromAnotherPatch_StatusBarTileStart, !StatusbarFormat)
		!StatusBar_TestDisplayElement_RightAlignedText_Pos_Prop = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayRightAlignedNumber_PosX, !StatusBar_TestDisplayRightAlignedNumber_PosY, !FreeramFromAnotherPatch_StatusBarPropStart, !StatusbarFormat)
		
		!StatusBar_TestDisplayElement_VerticalRepeatedIconsDownwards_Pos_Tile = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayElement_VerticalRepeatedIconsDownwards_PosX, !StatusBar_TestDisplayElement_VerticalRepeatedIconsDownwards_PosY, !FreeramFromAnotherPatch_StatusBarTileStart, !StatusbarFormat)
		!StatusBar_TestDisplayElement_VerticalRepeatedIconsDownwards_Pos_Prop = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayElement_VerticalRepeatedIconsDownwards_PosX, !StatusBar_TestDisplayElement_VerticalRepeatedIconsDownwards_PosY, !FreeramFromAnotherPatch_StatusBarPropStart, !StatusbarFormat)
		
		!StatusBar_TestDisplayElement_VerticalRepeatedIconsUpwards_Pos_Tile = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayElement_VerticalRepeatedIconsUpwards_PosX, !StatusBar_TestDisplayElement_VerticalRepeatedIconsUpwards_PosY, !FreeramFromAnotherPatch_StatusBarTileStart, !StatusbarFormat)
		!StatusBar_TestDisplayElement_VerticalRepeatedIconsUpwards_Pos_Prop = PatchedStatusBarXYToAddress(!StatusBar_TestDisplayElement_VerticalRepeatedIconsUpwards_PosX, !StatusBar_TestDisplayElement_VerticalRepeatedIconsUpwards_PosY, !FreeramFromAnotherPatch_StatusBarPropStart, !StatusbarFormat)
		
		!OverworldBorder_TestDisplayElement_Pos_Tile = PatchedStatusBarXYToAddress(!OverworldBorder_TestDisplayElement_PosX, !OverworldBorder_TestDisplayElement_PosY, !FreeramFromAnotherPatch_OWBorderTileStart, $02)
		!OverworldBorder_TestDisplayElement_Pos_Prop = PatchedStatusBarXYToAddress(!OverworldBorder_TestDisplayElement_PosX, !OverworldBorder_TestDisplayElement_PosY, !FreeramFromAnotherPatch_OWBorderPropStart, $02)
		
		!OverworldBorder_TestDisplayElement_RightAlignedText_Pos_Tile = PatchedStatusBarXYToAddress(!OverworldBorder_TestDisplayRightAlignedNumber_PosX, !OverworldBorder_TestDisplayRightAlignedNumber_PosY, !FreeramFromAnotherPatch_OWBorderTileStart, $02)
		!OverworldBorder_TestDisplayElement_RightAlignedText_Pos_Prop = PatchedStatusBarXYToAddress(!OverworldBorder_TestDisplayRightAlignedNumber_PosX, !OverworldBorder_TestDisplayRightAlignedNumber_PosY, !FreeramFromAnotherPatch_OWBorderPropStart, $02)
	endif