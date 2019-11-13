
	#import "../main.asm"

.var Screen = $2000
.var Color  = $0400

.const KOALA_TEMPLATE = "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
.var picture = LoadBinary("Atilla.prg", KOALA_TEMPLATE)

//---------------------------------------

*=$0801 "Basic"
BasicUpstart2(init)
*=$4000 "Program"

init:
	lda #$38
	sta VIC_VIDEO_ADR
	lda #$d8
	sta VIC_CTRL2
	lda #$3b
	sta VIC_CTRL1
	lda #0
	sta VIC_BORDERCOLOR
	lda #picture.getBackgroundColor()
	sta VIC_BG_COLOR0
	ldx #0
!loop:
	.for (var i=0; i<4; i++) {
		lda colorRam+i*$100,x
		sta $d800+i*$100,x
	}
	inx
	bne !loop-
	jmp *

//---------------------------------------

bitmap:
*=$0c00;
	.fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$1c00; colorRam:
	.fill picture.getColorRamSize(), picture.getColorRam(i)
*=$2000;
	.fill picture.getBitmapSize(), picture.getBitmap(i)
