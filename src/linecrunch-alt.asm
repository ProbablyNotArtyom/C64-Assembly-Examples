
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"

//-----------------------------------------------------

.const SHOW_INVALID = true
.const USE_SINE		= false

.var sindex			= $FB
.var crunch_len		= $FC
.var y_save			= $FD

//-----------------------------------------------------

	*=$0801 "Basic"
	BasicUpstart2(init)
	*=$810 "Program"

init:
	sei
	set_memory_map(false, false, false, true)	// Disable everything but I/O
	lda #$1B
	sta VIC_config1

	:mov16 #irqa : sysvec_IRQ
	:mov16 #nmi : sysvec_NMI

	lda #$7F
	sta CIA1_ICR
	sta CIA2_ICR
	lda CIA1_ICR
	lda CIA2_ICR
	lda #1
	sta VIC_irq_mask

	ldx #$17		// Hide screen runoff by clearing some memory past the normal screen memory
	lda #$20
!:	sta $07e8,x
	dex
	bpl !-

	lsr VIC_irq_state
	cli

main:
	waitForNewFrame()
	inc sindex
	ldy sindex
	ldx sintbl,y
	txa
	:lsr #3
	sta crunch_len
	txa
	and #7
	eor #7			// linecrunch scrolls up, but increasing the yscroll scrolls down
					// therefore we must flip the yscroll to make it match
	sta y_save
	clc
	adc #($30-3)	// before linecrunching takes 3 rasterlines
	sta VIC_raster

	lda y_save
	ora #$50
	sta VIC_config1

.if (SHOW_INVALID) {
	lda #$18		// use the invalid textmode to "cover up" the linecrunch bug area
	sta VIC_config2
}
	jmp main


irqa:				// stable raster routine. not exactly necessary for linecrunch, but might as well :)
	tsx
	lda #<irqb
	sta sysvec_IRQ
	inc VIC_raster
	lsr VIC_irq_state
	cli
	.fill 40, NOP	// Insert 40 sequential NOPs into memory here

irqb:
	txs
	ldx #8			// loop to waste some cycles
!:	dex
	bne !-

	nop $ea
	lda VIC_raster
	cmp VIC_raster	// last cycle of CMP reads data from VIC_raster
	beq !+			// add extra cycle if still the same line

!:	ldx #9
!:	dex
	bne !-

	/* this is the part that actually performs the linecrunch */
	clc
	lda y_save
	ldx crunch_len

do_crunch:
	adc #1
	and #7
	ora #$50
	sta VIC_config1

	ldy #8			// waste a bunch of cycles
!:	dey				// notice that there is lots of time left in the rasterline for more effects!
	bne !-

	nop				// waste 7 more cycles
	nop
	nop $ea

	dex
	bpl do_crunch

.if (SHOW_INVALID) {
	and #%10111111	// disable invalid gfx mode
	sta VIC_config1
}
	lda #8
	sta VIC_config2
	lda #<irqa
	sta sysvec_IRQ
	lsr VIC_irq_state
nmi:
	rti

//-----------------------------------------------------

	.align $100

sintbl:
	.if (USE_SINE) {
		.for (var i=0; i<256; i++) {
			.byte round(
				(150.5+100.5 * (sin(toRadians(360*i/128)) * cos(toRadians(360*i/64))) / 2)
			)
		}
	} else {
		.for (var i=0; i<128; i++) .byte i*1.5
		.for (var i=128; i>0; i--) .byte i*1.5
	}
