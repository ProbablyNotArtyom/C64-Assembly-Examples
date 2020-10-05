
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"
	#import "../include/irq.inc"
	.encoding "screencode_upper"

//-----------------------------------------------------

.var Screen 			= $0400
.var Color 				= $D800

.var rirq_count 		= $20
.var _rirq_count 		= $21
.var offset 			= $22

//-------------------------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(setup)
*=$1000 "Program"

setup:
	sei
	lda #$35
	sta $01
	
	/* Just in case you're running a custom kernal...
	we make sure you get the full experience ;) */
	lda #COLOR_LIGHTBLUE
	sta VIC_border_color
	lda #COLOR_BLUE
	sta VIC_bg_color0
	
	ClearColorRam(COLOR_WHITE)
	
	:mov16 #irq0 : sysvec_IRQ
	ldx #$00
	stx $DC0E
	inx
	stx VIC_irq_mask
	lda #$1B
	sta VIC_config1
	lda #$1
	sta VIC_raster
	sta offset

	lda #$01
	sta rirq_count
	cli
	jmp *

irq0:
	:irq_entry
	:mov16 #irq1 : sysvec_IRQ

	lda #$08
	ldx #COLOR_GRAY1
	sta VIC_config2
	stx VIC_bg_color0
	dec VIC_border_color

	inc rirq_count
	ldx rirq_count

	lda sine256_Y,x
	sta VIC_raster
	
	lda anti_sine256_Y,x
	sta offset

	lsr VIC_irq_state
	:irq_exit
	rti

irq1:
	:irq_entry
	inc VIC_border_color
	lda #COLOR_BLUE
	sta VIC_bg_color0

	:mov16 #irq0 : sysvec_IRQ

	ldx offset
!:	ldy VIC_raster
!:	cpy VIC_raster
	beq !-
	dey

	lda sine256_X,x
	and #%00000111
	ora #%00001000
	sta VIC_config2

	dex
	bne !--

	lda #$1
	sta VIC_raster
	:irq_exit
	rti

//-----------------------------------------------------

sine256_X:
	.for (var i=0; i<256; i++)
		.byte round(3.5+3.5*sin(toRadians(i*360/64)))

sine256_Y:
	.for (var i=0; i<256; i++)
		.byte round(127.5+127.5*sin(toRadians(i*360/256)))
anti_sine256_Y:
	.for (var i=0; i<256; i++)
		.byte round(127.5+120.5*sin(toRadians(i*360/256)))

modsine256_Y:
	.for (var i=0; i<256; i++) {
		.byte round(127.5+127.5 *
			(
				sin(toRadians(360*i/128)) *
				cos(toRadians(360*i/64))
			)
		)
	}
