
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"
	#import "../include/irq.inc"

//-------------------------------------------------------------------

.const SCREEN		= $400

.var current_y		= $20
.var line_offset	= $21

//-------------------------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(setup)
*=$0900 "Program"

setup:
	sei

	/* Wait for new frame */
!:	bit VIC_config1
	bpl !-
!:	bit VIC_config1
	bmi !-

	lda #$FF	// Set garbage byte
	sta $3FFF
	lda #$FF	// Enable all sprites
	sta VIC_sprite_enable

	/* Set sprite x-positions  */
	ldx #14
	clc
	lda #$F0
!:	sta VIC_sprite0_x,x
	sbc #24
	:dex #2
	bpl !-

	/* Set sprite y-positions  */
	ldx #14
	lda #$40
!:	sta VIC_sprite0_y,x
	:dex #2
	bpl !-

	/* Set sprite pointers */
	lda #[spriteDat/64]
	ldx #7
!:	sta [SCREEN+VIC_sprite0_offset],x
	dex
	bpl !-

l0:	{
		/* Calculate offsets */
		jsr calc

		/* Wait for sprite y-position */
		lda #$40
	!:	cmp VIC_raster
		bne !-

		/* Wait a few cycles to make the d017-stretch work */
		ldx #4
	!:	dex
		bne !-

		ldx #$00
	l1:	{
			/* $FF will stretch, 0 will step one line of graphics in the sprite */
			lda stretchDat,x
			sta VIC_sprite_expand_y

			/* Step d011 each line to avoid badlines */
			sec
			lda VIC_config1
			sbc #7
			ora #$18
			sta VIC_config1

			/* Waste 9 cycles so that each iteration is exactly 44 cycles */
			/* (1 rastertime w/ all sprites) */
			wait(9)

			/* Revert back for next line */
			inc VIC_sprite_expand_y

			inx
			cpx #100
			bne l1
		}
		/* Restore display mode */
		lda #$1B
		sta VIC_config1
		jmp l0
	}

calc:				// Setup the stretch lookup table
	ldy #$00
	sty current_y
	lda #$FF		// First clear the table
!:	sta stretchDat,y
	iny
	bne !-

	lda #$00		// Increase the starting value
	inc *-1
	asl
	sta line_offset

	ldy #$00		// This loop will insert 16 0:s into the table..
					// At those positions the sprites will not stretch
c0:	lda line_offset
	clc
	adc #10
	sta line_offset
	bpl !+
	eor #$FF
!:	:lsr #4			// Divide by 16
	sec
	adc current_y
	sta current_y
	tax
	lda #$00
	sta stretchDat,x
	iny
	cpy #20
	bcc c0
	rts

//-------------------------------------------------------------------

	.align 64		// Align to a valid spriteptr address
spriteDat:
    .byte $00, $00, $00, $00, $10, $00, $00, $38
    .byte $00, $00, $54, $00, $00, $ee, $00, $01
    .byte $55, $00, $03, $bb, $80, $05, $55, $40
    .byte $0e, $ee, $e0, $15, $55, $50, $3b, $bb
    .byte $b8, $15, $55, $50, $0e, $ee, $e0, $05
    .byte $55, $40, $03, $bb, $80, $01, $55, $00
    .byte $00, $ee, $00, $00, $54, $00, $00, $38
    .byte $00, $00, $10, $00, $00, $00, $00, $02

	.align 256		// Align the table to a new page, this way lda stretchDat,x always takes 4 cycles.
stretchDat:
	.fill 256, $00	// Reserve 256 bytes for the table
