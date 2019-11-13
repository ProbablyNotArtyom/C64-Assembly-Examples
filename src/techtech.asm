
	#import "../main.asm"
	.encoding "screencode_upper"

.var	Screen 	= $0400
.var	Color 	= $D800

.var	rirq_count 		= $20
.var	offset		 	= $21

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
*=$810 "Program"

setup:
	sei
	lda #$00
	sta VIC_BG_COLOR0
	lda #$01
	sta VIC_BG_COLOR1
	sta VIC_BG_COLOR2
	sta VIC_BG_COLOR3
	lda #$01
	sta VIC_BORDERCOLOR

	ldx #$00
!:	lda #$01
	sta Color,x
	sta Color+$100,x
	sta Color+$200,x
	sta Color+$300,x
	inx
	bne !-

	lda #<$0400
	sta $80
	lda #>$0400
	sta $81
	ldx #$00
	ldy #$00
!:	lda txt,y
	sta ($80),y
	iny
	cpy #80
	bne !-
	ldy #$00
	sec
	add16 $80 : #79
	inx
	cpx #13
	bne !-

	lda #<irq0
	sta $FFFE
	lda #>irq0
	sta $FFFF
	lda #<__waitpoint
	sta $FFFA
	lda #>__waitpoint
	sta $FFFB

	lda #$16
	sta VIC_VIDEO_ADR
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
!:	ora #$00
	sta $d016
!:	pla
	tax
	pla
	tay
	pla
	lsr VIC_CTRL1
	inc VIC_HLINE
	inc VIC_HLINE
	rti

__waitpoint:
	rti

txt:
	.byte 	$e0, $E0, $60, $E0, $60, $E0, $60, $E0, $60, $E0
	.byte 	$60, $E0, $60, $E0, $60, $E0, $60, $E0, $60, $E0
	.byte 	$60, $E0, $60, $E0, $60, $E0, $60, $E0, $60, $E0
	.byte 	$60, $E0, $60, $E0, $60, $E0, $E0, $E0, $E0, $E0
	.byte	$e0, $60, $E0, $60, $E0, $60, $E0, $60, $E0, $60
	.byte	$e0, $60, $E0, $60, $E0, $60, $E0, $60, $E0, $60
	.byte	$e0, $60, $E0, $60, $E0, $60, $E0, $60, $E0, $60
	.byte	$e0, $60, $E0, $60, $E0, $60, $E0, $E0, $E0, $E0

sine256:
	.byte   $04, $04, $04, $05, $05, $05, $05, $06
	.byte   $06, $06, $06, $07, $07, $07, $07, $07
	.byte   $07, $07, $07, $07, $07, $07, $06, $06
	.byte   $06, $06, $05, $05, $05, $05, $04, $04
	.byte   $04, $03, $03, $02, $02, $02, $02, $01
	.byte   $01, $01, $01, $00, $00, $00, $00, $00
	.byte   $00, $00, $00, $00, $00, $00, $01, $01
	.byte   $01, $01, $02, $02, $02, $02, $03, $03
