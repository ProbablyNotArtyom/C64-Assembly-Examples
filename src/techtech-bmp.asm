
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"
	#import "../include/irq.inc"
	.encoding "screencode_upper"

//-----------------------------------------------------

.var Screen 			= $0400
.var Color 				= $D800

.var rirq_count 		= $20
.var offset		 		= $21

.const addr_init 		= $1000
.const addr_bmp 		= $2000
.const addr_scr 		= $0C00
.const addr_color 		= $810

//-----------------------------------------------------

.const BMPDAT			= "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
.var picture			= LoadBinary("Atilla.prg", BMPDAT)

//-------------------------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(setup)
*=addr_init "Program"

setup:
	sei

	:mov16 #irq0 : sysvec_IRQ
	:mov16 #__waitpoint : sysvec_NMI

	lda #$38
	sta VIC_memory_config
	lda #$3B
	sta VIC_config1
	lda #$00
	sta VIC_border_color
	lda #picture.getBackgroundColor()
	sta VIC_bg_color0
	ldx #$00
!:
	.for (var i=0; i<4; i++) {
		lda addr_color+i*$100,x
		sta $d800+i*$100,x
	}
	inx
	bne !-

	lda #$04
	sta VIC_raster
	lda #$01
	sta offset
	sta rirq_count
	lda #$35
	sta $01
	cli

	jmp *

irq0:
	:irq_entry
	:mov16 #irq0 : sysvec_IRQ
	inc rirq_count
	lda rirq_count
	beq !++
	and #%00111111
	tax
	lda sine256,x
!:	ora #16
	sta VIC_config2
!:	:irq_exit
	lsr VIC_irq_state
	inc VIC_raster
	inc VIC_raster
	rti

__waitpoint:
	:irq_exit
	rti

//-----------------------------------------------------

sine256:
	.for (var i=0; i<256; i++)
		.byte round(3.5+3.5*sin(toRadians(i*360/64)))

//-----------------------------------------------------

*=addr_scr;
	.fill picture.getScreenRamSize(), picture.getScreenRam(i)
	.print "Bitmap Screen Size = $" + toHexString(picture.getScreenRamSize())

*=addr_color;
	.fill picture.getColorRamSize(), picture.getColorRam(i)
	.print "Bitmap Color RAM Size = $" + toHexString(picture.getColorRamSize())

*=addr_bmp;
	.fill picture.getBitmapSize(), picture.getBitmap(i)
	.print "Bitmap Bitmap Size = $" + toHexString(picture.getBitmapSize())
