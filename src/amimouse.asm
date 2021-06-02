
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"
	#import "../include/irq.inc"
	.encoding "screencode_upper"

//-----------------------------------------------------

.var Screen 	= $0400
.var Color 		= $D800

//-----------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(start)
*=$810 "Program"

start:
	sei
	ClearScreen($400, ' ')
	ldx #0
!:	lda sprites,x
	sta $0340,x
	inx
	bpl !-

	ldx #13
	stx $07f8
	inx
	stx $07f9
	lda #3
	sta VIC_sprite_enable
	lda #0
	sta y
	sta x
	sta x+1
	sta buttons

	lda #$35
	sta $01
	lda #<irq
	sta sysvec_IRQ
	lda #>irq
	sta sysvec_IRQ+1

	lda #<(8*63-1)
	sta CIA1_TA
	lda #>(8*63-1)
	sta CIA1_TA+1
	lda #$7f
	sta CIA1_ICR
	lda #$81
	sta CIA1_ICR
	lda CIA1_ICR

	lda #$ea
	sta VIC_raster     // raster irq
	lda #$1b
	sta VIC_config1

	lda #$01
	sta VIC_irq_mask
	sta VIC_irq_state
	sta irqf

    // The main wait loop
    // Just waste time until an IRQ
	cli
!:	jmp !-

//-----------------------------------------------------
// Make sense of the input strobes
// Then update the sprite coordinates

mouse:
	clc
	lda dx
	adc x
	sta x
	lda dx
	and #$80
	beq *+4
	lda #$ff
	adc x+1
	tax

	beq mxok
	bmi !++
	cpx #2
	bcs !+       // limit to 319
	lda x
	cmp #<320
	bcc	mxok
!:	lda #<319
	ldx #>319
	bne !++
!:	ldx #0
	tax
!:	sta x
mxok:
	stx x+1
	clc
	lda dy
	adc y
	cmp #200
	bcc myok
	bit dy
	bmi !+
	lda #199
	.byte $2c
!:	lda #0
myok:
	sta y
	clc
	lda y
	adc #50-1
	sta VIC_sprite0_y
	sta VIC_sprite1_y
	clc
	lda x
	adc #24-1
	sta VIC_sprite0_x
	sta VIC_sprite1_x
	lda x+1
	adc #0
	beq msxok
	lda #3
msxok:
	sta VIC_sprite_hi_x

	/* Check for left click */
	lda #' '
	bit buttons
	bpl !+
	lda #12
!:	sta $0400

	/* Check for right click */
	lda #' '
	bit buttons
	bvs !+
	lda #18
!:	sta $0401

	/* Check for middle click */
	lda buttons
	and #$20
	bne !+
	lda #13
	.byte $2c
!:	lda #' '
	sta $0402

	lda x+1
	lsr
	lda x
	ror
	lsr 2
	sta xchar
	lda y
	lsr 3
	sta ychar
	rts

//-----------------------------------------------------
// IRQ handler for sampling the mouse

irqf:	.byte 1
irq:	pha
		lda VIC_irq_state
		and #1
		bne raster
timer:	lda CIA1_ICR
		and #1
		and irqf
		beq exit

		stx ax+1
		sty ay+1

		ldx CIA1
		txa
		and #$0a    // .... x.x.
		tay
		lsr       // fc=0 here
		ora #0      // 0000 oxox
		sty *-1
		tay
		lda xmove,y
		bpl xok     // valid change

dx0:	lda #0
		bit xmove+1
		beq xok2
		asl
		clc

xok:	sta dx0+1
xok2:	adc dx
		sta dx
		txa
		and #$05    // .... .y.y
		tay
		asl
		ora #0      // 0000 yoyo
		sty *-1
		tay
		lda ymove,y
		bpl yok
dy0:	lda #0
		bit xmove+1
		beq yok2
		asl
yok:	sta dy0+1
yok2:	clc
		adc dy
		sta dy

ax:		ldx #0
ay:		ldy #0
exit:	pla
		rti


raster:
	/* Read the pulse signals and parse the button states */
	sta VIC_irq_state
	eor irqf
	sta irqf
	bne !+
	lda #$c0		// init pot read
	sta CIA1_DDRA
	asl				// #$80
	sta CIA1
	lda #$fa
	sta VIC_raster
	bne exit

!:	stx ax+1
	sty ay+1

	lda dx
	and #$7f
	cmp #$40
	bcc !+
	ora #$80
!:	sta dx

	lda dy
	and #$7f
	cmp #$40
	bcc !+
	ora #$80
!:	sta dy

	/* parse buttons */
	ldx $d419				// potx
	ldy $d41a				// poty

	lda #0
	sta CIA1_DDRA

	cpy #$80
	ror
	cpx #$80
	ror
	eor #$c0
	sta buttons

	lda CIA1
	and #$10
	eor #$10
	cmp #$10
	ror buttons

	jsr mouse

	lda #$ea
	sta VIC_raster
	bit CIA1_ICR
	lda #0
	sta dx
	sta dy
	jmp ax

//-----------------------------------------------------
// Lookup tables

sprites:
	.byte $00, $00, $00, $40, $00, $00, $60, $00
	.byte $00, $70, $00, $00, $78, $00, $00, $7c
	.byte $00, $00, $7e, $00, $00, $7f, $00, $00
	.byte $7f, $80, $00, $7f, $c0, $00, $7f, $80
	.byte $00, $7e, $00, $00, $7e, $00, $00, $66
	.byte $00, $00, $43, $00, $00, $03, $00, $00
	.byte $01, $80, $00, $01, $80, $00, $00, $c0
	.byte $00, $00, $c0, $00, $00, $00, $00, $02
	.byte $c0, $00, $00, $e0, $00, $00, $f0, $00
	.byte $00, $f8, $00, $00, $fc, $00, $00, $fe
	.byte $00, $00, $ff, $00, $00, $ff, $80, $00
	.byte $ff, $c0, $00, $ff, $e0, $00, $ff, $e0
	.byte $00, $ff, $80, $00, $ff, $00, $00, $ff
	.byte $00, $00, $e7, $80, $00, $c7, $80, $00
	.byte $03, $c0, $00, $03, $c0, $00, $01, $e0
	.byte $00, $01, $e0, $00, $00, $e0, $00, $1c

xmove:
	.byte $00, $01, $7f, $00, $7f, $80, $80, $01
	.byte $01, $80, $80, $7f

ymove:
	.byte $00, $7f, $01, $00, $01, $80, $80, $7f
	.byte $7f, $80, $80, $01, $00, $01, $7f, $00

//-----------------------------------------------------
// RAM Variables

dx:			.byte 0		// relative movement
dy:			.byte 0		// -''-
dz:			.byte 0		// scroll wheel
buttons:	.byte 0		// l r m 4 5 . . .

x:			.byte 0, 0	// absolute coords
y:			.byte 0

xchar:		.byte 0		// char coords
ychar:		.byte 0
