
	#import "../main.asm"
	.encoding "screencode_upper"

	.plugin "se.booze.kickass.CruncherPlugins"

//---------------------------------------

.var	Screen 			= $0400
.var	Color 			= $D800

.var	rirq_count 		= $20
.var	offset		 	= $21

.const addr_init =		$1000
.const addr_bmp = 		$2000
.const addr_scr = 		$0C00
.const addr_color = 	$810

//---------------------------------------

.const BMPDAT = 		"C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
.var picture = 			LoadBinary("Atilla.prg", BMPDAT)

//---------------------------------------

.macro IRQ_ENTER() {
	pha
	tya
	pha
	txa
	pha
}

.macro IRQ_SET(irqvec, rasterline) {
	ldx #<irqvec
	ldy #>irqvec
	stx $FFFE
	sty $FFFF
	lda rasterline
	sta VIC_HLINE
	lsr VIC_CTRL1
}

.macro IRQ_SET_IMMEDIATE(irqvec, rasterline) {
	ldx #<irqvec
	ldy #>irqvec
	stx $FFFE
	sty $FFFF
	lda #rasterline
	sta VIC_HLINE
	lsr VIC_CTRL1
}

.macro XWAIT(delay) {
	ldx #delay
!:	dex
	bne !-
}

.macro YWAIT(delay) {
	ldy #delay
!:	dey
	bne !-
}

//-----------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(setup)
*=addr_init "Program"

setup:
	sei

	lda #<irq0
	sta $FFFE
	lda #>irq0
	sta $FFFF
	lda #<__waitpoint
	sta $FFFA
	lda #>__waitpoint
	sta $FFFB

	lda #$38
	sta VIC_VIDEO_ADR
	lda #$3B
	sta VIC_CTRL1
	lda #$00
	sta VIC_BORDERCOLOR
	lda #picture.getBackgroundColor()
	sta VIC_BG_COLOR0
	ldx #$00
!:
	.for (var i=0; i<4; i++) {
		lda addr_color+i*$100,x
		sta $d800+i*$100,x
	}
	inx
	bne !-

	lda #$04
	sta VIC_HLINE
	lda #$01
	sta offset
	sta rirq_count
	lda #$35
	sta $01
	cli

!:	lda #$00
!:	cmp VIC_HLINE
	bne !-
	jmp !--

irq0:
	IRQ_ENTER()
	ldx #<irq0
	ldy #>irq0
	stx $FFFE
	sty $FFFF
	inc rirq_count
	lda rirq_count
	beq !++
	and #%00111111
	tax
	lda sine256,x
!:	and #$07
	ora #$10
	sta VIC_CTRL2
!:	pla
	tax
	pla
	tay
	pla
	lsr VIC_IRR
	inc VIC_HLINE
	inc VIC_HLINE
	rti

__waitpoint:
	rti

//---------------------------------------

sine256:
	.byte   $04, $04, $04, $05, $05, $05, $05, $06
	.byte   $06, $06, $06, $07, $07, $07, $07, $07
	.byte   $07, $07, $07, $07, $07, $07, $06, $06
	.byte   $06, $06, $05, $05, $05, $05, $04, $04
	.byte   $04, $03, $03, $02, $02, $02, $02, $01
	.byte   $01, $01, $01, $00, $00, $00, $00, $00
	.byte   $00, $00, $00, $00, $00, $00, $01, $01
	.byte   $01, $01, $02, $02, $02, $02, $03, $03

//---------------------------------------

*=addr_scr;
	.fill picture.getScreenRamSize(), picture.getScreenRam(i)
	.print "Bitmap Screen Size = $" + toHexString(picture.getScreenRamSize())

*=addr_color;
	.fill picture.getColorRamSize(), picture.getColorRam(i)
	.print "Bitmap Color RAM Size = $" + toHexString(picture.getColorRamSize())

*=addr_bmp;
	.fill picture.getBitmapSize(), picture.getBitmap(i)
	.print "Bitmap Bitmap Size = $" + toHexString(picture.getBitmapSize())
