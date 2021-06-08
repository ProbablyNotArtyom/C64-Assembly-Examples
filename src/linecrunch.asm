
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"

//-----------------------------------------------------

.var offset = $F0


*=$0801 "Basic"
BasicUpstart2(init)
*=$810 "Program"

init:
	// set up IRQ and back to BASIC
	lda #$7f
	sta CIA1_ICR
	lda #$1b
	sta VIC_config1
	lda #$00
	sta VIC_raster
	lda #<irq
	sta vec_IRQ
	lda #>irq
	sta vec_IRQ+1
	lda #$01
	sta VIC_irq_mask

	lda #11
	sta offset

	rts

//-----------------------------------------------------

irq:
	lda #$01
	sta VIC_irq_state
	bit VIC_raster
	bvc eirq
	lda #$01
	sta VIC_raster
	nop
	nop
	nop
	inc VIC_config1

	ldx #11
!:	dex
	bne !-
	nop
	inc VIC_config1

	lda CIA1_ICR
	beq !+
	jmp $ea31

eirq:
	lda #$1B
	sta VIC_config1
	lda #$62
	sta VIC_raster
	inc offset
!:	jmp $febc

//-----------------------------------------------------
