
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"

//-----------------------------------------------------

.var from	= 33
.const offset = $F0		// Zeropage variable

//-----------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(init)
*=$810 "Program"

init:
	sei				// disable interrupt
	lda #$00		// set garbage byte
	sta $3fff
	lda #$7f		// disable timer interrupt
	sta $dc0d
	lda #1			// enable raster interrupt
	sta VIC_irq_mask
	lda #<irq		// set irq vector
	lda #>irq
	sta vec_IRQ
	sta vec_IRQ+1

	lda #from
	sta offset		// set offset

	lda #4			// to evoke our irq routine on 4th line
	sta VIC_raster
	cli				// enable interrupt
	jmp *

//-----------------------------------------------------

irq:
	lda #COLOR_LIGHTBLUE
	sta VIC_bg_color0
	ldx	offset
	lda sine256,x
	tax
l2:	ldy VIC_raster	// moving 1st bad line
l1:	cpy VIC_raster
	beq l1			// wait for begin of next line
	dey				// iy - bad line
	tya
	and #$07		// clear higher 5 bits
	ora #$10		// set text mode
	sta VIC_config1
	dex
	bne l2

	wait(34)
	lda #COLOR_BLUE
	sta VIC_bg_color0
	lsr VIC_irq_state	// acknowledge the raster interrupt
	inc offset
	jmp $ea31			// do standard irq routine

//-----------------------------------------------------

sine256:
	.for (var i=0; i<256; i++) {
		.byte round(150.5+100.5 * (
			sin(toRadians(360*i/128)) * cos(toRadians(360*i/64))
		))
	}

//-----------------------------------------------------
