// This is an example effect bundled with Spindle
// www.linusakesson.net/software/spindle/
// Feel free to display the Spindle logo in your own demo, if you like.

	#import "../main.asm"

.var	Screen 	= $0400
.var	Color 	= $D800

.var	rirq_count 		= $20
.var	next_rirq_hi 	= $21
.var	next_rirq 		= $22

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
	sta $D012
	lsr $D019
}

.macro IRQ_SET_IMMEDIATE(irqvec, rasterline) {
	ldx #<irqvec
	ldy #>irqvec
	stx $FFFE
	sty $FFFF
	lda #rasterline
	sta $D012
	lsr $D019
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
	lda #$0e
	sta VIC_BG_COLOR0
	sta VIC_BG_COLOR1
	sta VIC_BG_COLOR2
	sta VIC_BG_COLOR3
	lda #$35
	sta $01

	lda #<irq0
	sta $FFFE
	lda #>irq0
	sta $FFFF
	lda #<__waitpoint
	sta $FFFA
	lda #>__waitpoint
	sta $FFFB
	ldx #$00
	stx $DC0E
	inx
	stx $D01A
	lda #%01011011
	sta $d011
	lda #$01
	sta $D012
	sta next_rirq
	lda #$01
	sta rirq_count
	cli
	jmp *

irq1:
	IRQ_ENTER()
	IRQ_SET(irq0, next_rirq)
	lda rirq_count
	cmp #$00
	beq !+

!:	inc rirq_count
	ldx rirq_count
	lda sine256,x
	bne !+
	lda #$01
!:	sta next_rirq
	lda #$18
	sta $d016
	lda #COLOR_BLACK
	sta $D020
	jmp __irq_return

irq0:
	IRQ_ENTER()
	IRQ_SET_IMMEDIATE(irq1, 0)
	lda #$08
	sta $d016
	lda #COLOR_LIGHTBLUE
	sta $d020
	jmp __irq_return

__irq_return:
	pla
	tax
	pla
	tay
	pla
__waitpoint:
	rti

sine256:
	.byte	$00, $03, $06, $09, $0D, $10, $13, $16
	.byte	$19, $1C, $1F, $22, $25, $29, $2C, $2F
	.byte	$32, $35, $38, $3B, $3E, $41, $44, $47
	.byte	$4A, $4D, $50, $53, $56, $59, $5C, $5F
	.byte	$62, $64, $67, $6A, $6D, $70, $73, $75
	.byte	$78, $7B, $7E, $80, $83, $86, $88, $8B
	.byte	$8E, $90, $93, $95, $98, $9A, $9D, $9F
	.byte	$A2, $A4, $A7, $A9, $AB, $AE, $B0, $B2
	.byte	$B4, $B7, $B9, $BB, $BD, $BF, $C1, $C3
	.byte	$C5, $C7, $C9, $CB, $CD, $CF, $D0, $D2
	.byte	$D4, $D6, $D7, $D9, $DB, $DC, $DE, $DF
	.byte	$E1, $E2, $E4, $E5, $E7, $E8, $E9, $EA
	.byte	$EC, $ED, $EE, $EF, $F0, $F1, $F2, $F3
	.byte	$F4, $F5, $F6, $F7, $F7, $F8, $F9, $F9
	.byte	$FA, $FB, $FB, $FC, $FC, $FD, $FD, $FD
	.byte	$FE, $FE, $FE, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FE, $FE
	.byte	$FE, $FD, $FD, $FD, $FC, $FC, $FB, $FB
	.byte	$FA, $F9, $F9, $F8, $F7, $F7, $F6, $F5
	.byte	$F4, $F3, $F2, $F1, $F0, $EF, $EE, $ED
	.byte	$EC, $EA, $E9, $E8, $E7, $E5, $E4, $E2
	.byte	$E1, $DF, $DE, $DC, $DB, $D9, $D7, $D6
	.byte	$D4, $D2, $D0, $CF, $CD, $CB, $C9, $C7
	.byte	$C5, $C3, $C1, $BF, $BD, $BB, $B9, $B7
	.byte	$B4, $B2, $B0, $AE, $AB, $A9, $A7, $A4
	.byte	$A2, $9F, $9D, $9A, $98, $95, $93, $90
	.byte	$8E, $8B, $88, $86, $83, $80, $7E, $7B
	.byte	$78, $75, $73, $70, $6D, $6A, $67, $64
	.byte	$62, $5F, $5C, $59, $56, $53, $50, $4D
	.byte	$4A, $47, $44, $41, $3E, $3B, $38, $35
	.byte	$32, $2F, $2C, $29, $25, $22, $1F, $1C
	.byte	$19, $16, $13, $10, $0D, $09, $06, $03
