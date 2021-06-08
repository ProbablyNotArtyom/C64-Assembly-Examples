
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"

//-----------------------------------------------------

.var from		= $33
.var to			= $FA

//-----------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(init)
*=$810 "Program"

init:
	lda #0
	sta dir		// direction
	lda #$ff	// set garbage
	sta $3fff
	lda #from
	sta offset   // set offset
	sei         // disable interrupt
	lda #$7f    // disable timer interrupt
	sta CIA1_ICR
	lda #1      // enable raster interrupt
	sta VIC_irq_mask
	lda #<irq   // set irq vector
	sta vec_IRQ
	lda #>irq
	sta vec_IRQ+1
	lda #0      // to evoke our irq routine on 0th line
	sta VIC_raster
	cli         // enable interrupt
	rts

//-----------------------------------------------------

irq:
	ldx offset
l2:	ldy VIC_raster		// Moving 1st bad line
l1:	cpy VIC_raster
	beq l1				// Wait for begin of next line
	dey   				// IY - bad line
	tya
	and #$07			// Clear higher 5 bits
	ora #$10			// Set text mode
	sta VIC_config1
	dex
	bne l2
	inc VIC_irq_state   // Acknowledge the raster interrupt
	jsr next_y
	jmp SYS_ISR			// Do standard irq routine

//-----------------------------------------------------
offset: .byte from
dir:   .byte 0
//-----------------------------------------------------

next_y:
	lda dir		// Change offset of screen
	bne !++
	inc offset	// Down
	lda offset
	cmp #to
	bne !+
	sta dir
!:	rts
!:	dec offset
	lda offset
	cmp #from
	bne !--
	lda #0
	sta dir
	rts

//-----------------------------------------------------
