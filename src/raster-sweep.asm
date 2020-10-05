
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"

//-----------------------------------------------------

.var Screen 			= $0400
.var Color 				= $D800

.var rirq_count 		= $20
.var next_rirq_hi 		= $21
.var next_rirq 			= $22

//-----------------------------------------------------

.macro IRQ_SET(irqvec, rasterline) {
	ldx #<irqvec
	ldy #>irqvec
	stx sysvec_IRQ
	sty sysvec_IRQ+1
	lda rasterline
	sta VIC_raster
}

.macro IRQ_SET_IMMEDIATE(irqvec, rasterline) {
	ldx #<irqvec
	ldy #>irqvec
	stx sysvec_IRQ
	sty sysvec_IRQ+1
	lda #rasterline
	sta VIC_raster
}

//-----------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(setup)
*=$810 "Program"

setup:
	sei
	lda #$0e
	sta VIC_bg_color0
	sta VIC_bg_color1
	sta VIC_bg_color2
	sta VIC_bg_color3
	lda #$35
	sta $01

	lda #<irq0
	sta sysvec_IRQ
	lda #>irq0
	sta sysvec_IRQ+1
	lda #<__waitpoint		// Make the RESTORE key not crash everything
	sta sysvec_NMI
	lda #>__waitpoint
	sta sysvec_NMI+1
	ldx #$00
	stx $DC0E
	inx
	stx VIC_irq_mask
	lda #$6B
	sta VIC_config1
	lda #$01
	sta VIC_raster
	sta next_rirq
	lda #$01
	sta rirq_count
	cli
	jmp *

irq0:
	pha
	tya
	pha
	txa
	pha

	ldx #<irq1
	ldy #>irq1
	stx sysvec_IRQ
	sty sysvec_IRQ+1
	lda #$00
	sta VIC_raster
	lsr VIC_irq_state

	lda #$08
	lda #COLOR_LIGHTBLUE
	sta VIC_config2
	wait(8)
	sta VIC_border_color
__irq_return:
	pla
	tax
	pla
	tay
	pla
__waitpoint:
	rti

irq1:
	pha
	tya
	pha
	txa
	pha

	ldx #<irq0
	ldy #>irq0
	stx sysvec_IRQ
	sty sysvec_IRQ+1
	lda next_rirq
	sta VIC_raster
	lsr VIC_irq_state

	lda rirq_count
	cmp #$00
	inc rirq_count
	ldx rirq_count
	lda sine256,x
	bne !+
	lda #$01
!:	sta next_rirq
	lda #$18
	ldx #COLOR_BLACK
	sta VIC_config2
	stx VIC_border_color
	pla
	tax
	pla
	tay
	pla

	rti

//-----------------------------------------------------

sine256:
	.for (var i=0; i<256; i++) {
		.byte round(127.5+127.5 * (
			sin(toRadians(360*i/128)) * cos(toRadians(360*i/64))
		))
	}
