
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"
	#import "../include/irq.inc"

//-----------------------------------------------------

.const addr_init		= $1000
.const addr_bmp			= $2000
.const addr_scr			= $0C00
.const addr_color		= $810

.const bitmap_filname	= "Atilla.prg";
.const raster_trigger	= 45;
.const raster_update	= 10;

//-----------------------------------------------------

.const BMPDAT			= "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
.var picture			= LoadBinary(bitmap_filname, BMPDAT)

//-----------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(init)
*=addr_init "Program"

init:
	sei         // disable interrupt
	ldx #$FF
	txs

	lda #$00
	sta $3FFF
	lda #%00101111
	sta $00
	lda #%00100101
	sta $01

	lda #$7f    // disable timer interrupt
	sta $dc0d
	sta $dd0d
	lda #$00
	sta VIC_irq_mask

	lda #<irq1
	sta sysvec_IRQ
	lda #>irq1
	sta sysvec_IRQ+1
	lda #$01
	sta VIC_irq_mask
	lda #raster_update
	sta VIC_raster
	lda #$3b
	sta VIC_config1
	lda #$D7
    sta VIC_config2

	lda #$00
	sta	$dc0e
	sta	$dd0f
	sta	$dc0e
	sta $dd0f

	lda #$38
	sta VIC_memory_config
	lda #$00
	sta VIC_border_color
	lda #picture.getBackgroundColor()
	sta VIC_bg_color0
	ldx #$00
!:
	.for (var i=0; i<4; i++) {
		lda addr_color+i*$100,x
		sta $d800+i*$100,x
	}
	inx
	bne !-

	cli
	ldy #$00
loop:
	lda raster_stable
	beq loop
	sty raster_stable

	inc temp1
	ldx temp1
	lda bigSine,x
	sta vsp_hscroll
	lda bigSine_h,x
	sta vsp_hscroll_h

	lda vsp_hscroll_h
	beq !+
	lda vsp_hscroll
	cmp #48
	bne !+
	lda #$00
	sta vsp_hscroll
	sta vsp_hscroll_h
!:	jmp loop

//-----------------------------------------------------

irq1:
	pha
	tya
	pha
	txa
	pha

	/* Do fine scrolling */
	lda vsp_hscroll
	and #$07
	ora #$D0
	sta VIC_config2

	lda vsp_hscroll_h
	bne !+

	/* vsp_scroll offset is less than 256 */
	lda vsp_hscroll
	lsr
	lsr
	lsr
	sta x_offset
	jmp irq1_end

	/* vsp_scroll offset larger than a byte */
!:	lda vsp_hscroll
	and #$3F
	tax
	lda coarseTbl_upper,x
	sta x_offset

irq1_end:
	lda #<irq2
	ldx #>irq2
	ldy #raster_trigger
	sta sysvec_IRQ
	stx sysvec_IRQ+1
	sty VIC_raster
	lsr VIC_irq_state

	pla
	tax
	pla
	tay
	pla
	rti

.align $100
irq2:
	pha
	tya
	pha
	txa
	pha

	inc raster_stable
	lda #<irq3
	ldx #>irq3
	sta sysvec_IRQ
	stx sysvec_IRQ+1

	inc VIC_raster
	lda #$01
	sta VIC_irq_state

	/* Begin the raster stabilisation code */
	tsx
	cli
	/* These nops never really finish due to the raster IRQ triggering again */
	.for (var i = 0; i < 14; i++) nop

.align $100
irq3:
	txs
	ldx #$08
!:	dex
	bne !-
	bit $ea

	lda VIC_raster
	cmp VIC_raster
	beq !+

!:	lda #$11
	sta VIC_config1

	.for (var i = 0; i < 8; i++) nop
	bit $ea

	lda #39
	sec
	sbc x_offset
	lsr				// Divide by 2
	sta noptbl+1	// Modify the opcode to branch for us
	clv				// Force the branch to happen
	bcc noptbl		// Branch into the table

noptbl:
	bvc *
	.for (var i = 0; i <= 28; i++) nop

	lda #%00111011
	dec VIC_config1
	sta VIC_config1

	lda #<irq1
	ldx #>irq1
	ldy #$00
	sta sysvec_IRQ
	stx sysvec_IRQ+1
	sty VIC_raster
	lsr VIC_irq_state

	pla
	tax
	pla
	tay
	pla
	rti

//-----------------------------------------------------

coarseTbl_upper:
	.for (var i = 32; i < 39; i++)
		.byte i, i, i, i, i, i, i, i
	.for (var i = 0; i < 24; i++)
		.byte i, i, i, i, i, i, i, i

bigSine:
        .byte $00, $00, $03, $06, $0C, $12, $1A, $24, $2E, $39, $45, $52, $5F, $6D, $7B, $89
        .byte $96, $A4, $B1, $BD, $C9, $D4, $DE, $E7, $EE, $F5, $FA, $FE, $01, $02, $02, $01
        .byte $FF, $FC, $F8, $F3, $ED, $E6, $DF, $D7, $CF, $C7, $BF, $B7, $AF, $A8, $A1, $9A
        .byte $94, $8F, $8B, $87, $84, $82, $81, $81, $81, $82, $84, $86, $89, $8C, $8F, $93
        .byte $96, $9A, $9E, $A1, $A4, $A6, $A8, $AA, $AA, $AA, $A9, $A8, $A5, $A2, $9E, $99
        .byte $94, $8E, $87, $80, $78, $70, $68, $60, $58, $50, $49, $42, $3B, $36, $31, $2D
        .byte $2B, $29, $28, $29, $2B, $2F, $33, $39, $40, $49, $52, $5C, $68, $74, $81, $8E
        .byte $9C, $A9, $B7, $C5, $D2, $E0, $EC, $F8, $02, $0C, $15, $1C, $22, $27, $2A, $2B
        .byte $2B, $2A, $27, $22, $1C, $15, $0C, $02, $F8, $EC, $E0, $D2, $C5, $B7, $A9, $9C
        .byte $8E, $81, $74, $68, $5C, $52, $49, $40, $39, $33, $2F, $2B, $29, $28, $29, $2B
        .byte $2D, $31, $36, $3B, $42, $49, $50, $58, $60, $68, $70, $78, $80, $87, $8E, $94
        .byte $99, $9E, $A2, $A5, $A8, $A9, $AA, $AA, $AA, $A8, $A6, $A4, $A1, $9E, $9A, $96
        .byte $93, $8F, $8C, $89, $86, $84, $82, $81, $81, $81, $82, $84, $87, $8B, $8F, $94
        .byte $9A, $A1, $A8, $AF, $B7, $BF, $C7, $CF, $D7, $DF, $E6, $ED, $F3, $F8, $FC, $FF
        .byte $01, $02, $02, $01, $FE, $FA, $F5, $EE, $E7, $DE, $D4, $C9, $BD, $B1, $A4, $96
        .byte $89, $7B, $6D, $5F, $52, $45, $39, $2E, $24, $1A, $12, $0C, $06, $03, $00, $00
bigSine_h:
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01
        .byte $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

//-----------------------------------------------------

raster_stable: 		.byte $00
temp1:				.byte $00
x_offset:			.byte $00

vsp_hscroll:		.byte $00
vsp_hscroll_h:		.byte $00

//-----------------------------------------------------

*=addr_scr;
	.fill picture.getScreenRamSize(), picture.getScreenRam(i)
	.print "Bitmap Screen Size = $" + toHexString(picture.getScreenRamSize())
*=addr_color;
	.fill picture.getColorRamSize(), picture.getColorRam(i)
	.print "Bitmap Color RAM Size = $" + toHexString(picture.getColorRamSize())
*=addr_bmp;
	.fill picture.getBitmapSize(), picture.getBitmap(i)
	.print "Bitmap Bitmap Size = $" + toHexString(picture.getBitmapSize())
