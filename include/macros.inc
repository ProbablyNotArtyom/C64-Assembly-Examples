
#if !__C64__
#define	__C64__
.encoding "petscii_upper"
#endif

//-----------------------------------------------------
// Macros

.macro waitx(Cycles) {

	.var LC=5
	.var LoopCount=max(1, floor((Cycles-1)/LC))
	.if((LoopCount>1) && (Cycles - (LoopCount*LC+1)==1)) { .eval LoopCount-- }
	.var ExtraCycles=max(0, Cycles - (LoopCount*LC+1))
	.var ExtraBytes=max(0, ceil(ExtraCycles/2))


	.var P_LC=6
	.var P_LoopCount=max(1, floor(Cycles/P_LC))
	.if ((P_LoopCount>1) && (Cycles - (P_LoopCount*P_LC)==1)) { .eval P_LoopCount-- }
	.var P_ExtraCycles=max(0, Cycles - (P_LoopCount*P_LC))
	.var P_ExtraBytes=max(0, ceil(P_ExtraCycles/2))

	.var Relocate=false

	.var IsPageCrossed=(((<*)>=$fb) && ((<*)<=$fd))
	.if(IsPageCrossed) {
		.var adr=*+ExtraBytes
		.if((ExtraBytes<P_ExtraBytes) && (((<adr)<$fb) || ((<adr)>$fd))) {
			.eval Relocate=true
		} else {
			.eval LoopCount=P_LoopCount
			.eval ExtraCycles=P_ExtraCycles
			.eval ExtraBytes=P_ExtraBytes
		}
	} else {
		.var adr=*+P_ExtraBytes
		.if((P_ExtraBytes<ExtraBytes) && (((<adr)>=$fb) && ((<adr)<=$fd))) {
			.eval LoopCount=P_LoopCount
			.eval ExtraCycles=P_ExtraCycles
			.eval ExtraBytes=P_ExtraBytes
			.eval Relocate=true
		}
	}

	.if(ceil(Cycles/2) <= (5+ExtraBytes)) {
		wait(Cycles)
		} else {
		.if(Relocate) { wait(ExtraCycles) }
		ldx #LoopCount
		dex
		bne *-1
		.if(!Relocate) { wait(ExtraCycles) }
	}
}

.macro wait(Cycles) {
	.if(Cycles>0) {
		.if(Cycles<2) .error "Can't delay 1 cycle"
		.if((Cycles & 1)==0) { nop } else { bit $00 } 	// Delay 2 or 3 cycles
		.for(var i=1; i<floor(Cycles/2); i++) { nop } 	// Remaining even amount
	}
}

//=========================================================
// Stuff for loading in graphics data

.macro LoadSpriteFromPicture(filename) {
	.var picture = LoadPicture(filename, List().add($000000, $ffffff,$6c6c6c,$959595))
	.for (var y=0; y<21; y++)
		.for (var x=0; x<3; x++)
			.byte picture.getMulticolorByte(x,y)
	.byte 0
}

.macro LoadSpritesFromPicture(filename, bgcolor, color0, color1, color2) {
    .var picture  = LoadPicture(filename, List().add(bgcolor, color0, color1, color2))
    .var xsprites = floor(picture.width  / [ 3 * 8 ])
    .var ysprites = floor(picture.height / 21)

    .for (var ysprite = 0; ysprite < ysprites; ysprite++) {
        .for (var xsprite = 0; xsprite < xsprites; xsprite++) {
            .for (var i = 0; i < [3 * 21]; i++) .byte picture.getMulticolorByte([[xsprite * 3]  + mod(i, 3)], [[ysprite * 21] + floor(i / 3)])
            .byte 0
        }
    }
}

.macro equalCharPack(filename, screenAdr, charsetAdr) {
	.var charMap = Hashtable()
	.var charNo = 0
	.var screenData = List()
	.var charsetData = List()
	.var pic = LoadPicture(filename)

	// Graphics should fit in 8x8 Single collor / 4 x 8 Multi collor blocks
	.var PictureSizeX = pic.width/8
	.var PictureSizeY = pic.height/8

	.for (var charY=0; charY<PictureSizeY; charY++) {
		.for (var charX=0; charX<PictureSizeX; charX++) {
			.var currentCharBytes = List()
			.var key = ""
			.for (var i=0; i<8; i++) {
				.var byteVal = pic.getSinglecolorByte(charX, charY*8 + i)
				.eval key = key + toHexString(byteVal) + ","
				.eval currentCharBytes.add(byteVal)
			}
			.var currentChar = charMap.get(key)
			.if (currentChar == null) {
				.eval currentChar = charNo
				.eval charMap.put(key, charNo)
				.eval charNo++
				.for (var i=0; i<8; i++) {
					.eval charsetData.add(currentCharBytes.get(i))
				}
			}
			.eval screenData.add(currentChar)
		}
	}
	.pc = screenAdr "screen"
	.fill screenData.size(), screenData.get(i)
	.pc = charsetAdr "charset"
	.fill charsetData.size(), charsetData.get(i)
}

//=========================================================
// Setting up registers

// set_memory_map(kernal, basic, charrom, io) : configures port $01
//    kernal  - if true, enable the kernal ROM ($E000-$EFFF)
//    basic   - if true, enable the basic ROM ($A000-$BFFF)
//    charrom - if true, enable the character ROM ($D000-$DFFF)
//    io      - if true, enable the system I/O area ($D000-$DFFF)
.macro set_memory_map(kernal, basic, charrom, io) {
	.var regval = $30
	.if (!charrom && io) .eval regval = regval + %00000100
	.if (charrom && io) .error "set_memory_map() : CHARROM and IO cannot both be enabled!"
	.if (!charrom && !io) {
		.if (kernal || basic) .error "set_memory_map() : Cannot show RAM at $D000-$DFFF without showing all RAM"
	} else {
		.if (kernal && basic) .eval regval = regval + %00000011
		.if (kernal && !basic) .eval regval = regval + %00000010
		.if (!kernal && !basic) .eval regval = regval + %00000001
		.if (!kernal && basic) .error "set_memory_map() : BASIC cannot be mapped in without KERNAL!"
	}

	lda #regval
	sta $01
}

// get_screen_line(base, line) : returns the address of a line of the display
//    base  - the base address of the screen (usually $400)
//    line  - the line number to query
.function get_screen_line(base, line) {
	.if (line >= 25 || line < 0) .error "get_screen_line() : line " + toIntString(line) + " does not exist on display"
	.return (base + (40*line))
}

.macro set_screen_char_base(screen, charset) {
	lda #[[screen & $3fff] / 64] | [[charset & $3fff] / 1024]
	sta $d018
}

.macro ClearScreen(screen, clearByte) {
	lda #clearByte
	ldx #0
!loop:
	sta screen, x
	sta screen + $100, x
	sta screen + $200, x
	sta screen + $300, x
	inx
	bne !loop-
}

.macro ClearColorRam(clearByte) {
	lda #clearByte
	ldx #0
!loop:
	sta $D800, x
	sta $D800 + $100, x
	sta $D800 + $200, x
	sta $D800 + $300, x
	inx
	bne !loop-
}

.macro ClearColorRamLine(clearByte, line) {
	.var base = get_screen_line($D800, line)-1
	lda #clearByte
	ldx #40
!loop:
	sta base, x
	dex
	bne !loop-
}

.macro ClearScreenLine(screen, clearByte, line) {
	.var base = get_screen_line(screen, line)-1
	lda #clearByte
	ldx #40
!loop:
	sta base, x
	dex
	bne !loop-
}

// 0: $0000-$3fff   1: $4000-$7fff
// 2: $8000-$bfff   3: $c000-$ffff
.macro SetVICBank(bank) {
	lda $DD00
	and #%11111100
	ora #bank
	sta $DD00
}

.macro SetBorderColor(color) {
	lda #color
	sta $d020
}

.macro SetBackgroundColor(color) {
	lda #color
	sta $d021
}

.macro SetMultiColor1(color) {
	lda #color
	sta $d022
}

.macro SetMultiColor2(color) {
	lda #color
	sta $d023
}

.macro SetMultiColorMode() {
	lda	$d016
	ora	#16
	sta	$d016
}

.macro SetScrollMode() {
	lda $D016
	eor #%00001000
	sta $D016
}

.macro copyCharset(SRC, DEST) {
	ldy #7
!:	ldx #0
src_hi:
    lda SRC,x
dst_hi:
    sta DEST,x
    dex
    bne src_hi
    inc src_hi+2
    inc dst_hi+2
    dey
    bpl !-
}

.macro copyMap(WIDTH, HEIGHT, SRC, DEST) {
	ldx #$00
!:	.for (var i=0; i<HEIGHT; i++) {
		lda SRC+(i*WIDTH),x
		sta DEST+(i*40),x
	}
	inx
	cpx #WIDTH
	bne !-
}

.macro copyMapCutoff(WIDTH, HEIGHT, SRC, DEST, XCUTOFF) {
	ldx #$00
!:	.for (var i=0; i<HEIGHT; i++) {
		lda SRC+(i*WIDTH),x
		sta DEST+(i*40),x
	}
	inx
	cpx #XCUTOFF
	bne !-
}

//=========================================================
