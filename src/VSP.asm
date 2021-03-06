
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"

//-----------------------------------------------------

.const addr_init		= $0820
.const addr_scr			= $0400

.const raster_trigger	= 45
.const raster_update	= 10

.var COLORS_COUNT		= 256
.var MAP_COUNT			= 112
.var CHARSET_COUNT		= 2048
.var MAP_WIDTH			= 29
.var MAP_HEIGHT			= 5

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
	lda #%00011011
	sta VIC_config1
	lda #%11010111
    sta VIC_config2

	lda #$00
	sta	$dc0e
	sta	$dd0f
	sta	$dc0e
	sta $dd0f

	// Insert custom graphics
	set_screen_char_base(addr_scr, $3800)
	ClearScreen(addr_scr, 102)
	ClearColorRam(COLOR_GRAY1)
	SetBorderColor(COLOR_BLACK)
    SetBackgroundColor(COLOR_BLACK)
    SetMultiColor1(COLOR_BLUE)
	SetMultiColor2(COLOR_WHITE)
	copyCharset(charset, $3800)

	.for(var i=0; i<6; i++) {
		copyMap(MAP_WIDTH, MAP_HEIGHT, map, $400+(i*4)+(i*40*MAP_HEIGHT))
	}

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
	and #%00000111
	ora #%11010000
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
	and #%00111111
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

!:	lda #%00110001
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

	lda #%00011011
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

map:
	.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.byte $20,$86,$a3,$c6,$86,$a3,$c6,$87,$a7,$c7,$86,$a3,$c6,$83,$84,$85,$87,$a7,$c7,$80,$81,$82,$86,$a3,$c6,$c3,$c4,$c5,$20
	.byte $20,$a6,$20,$e6,$a6,$20,$e6,$20,$a6,$20,$a6,$e4,$e5,$a6,$a4,$a5,$20,$a6,$20,$a0,$a1,$a2,$a6,$20,$e6,$a6,$e3,$e6,$20
	.byte $20,$c0,$20,$c0,$e0,$e1,$e2,$20,$c0,$20,$c0,$20,$c0,$c0,$20,$c0,$20,$c0,$20,$20,$c0,$20,$e0,$e1,$e2,$c0,$20,$c0,$20
	.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20

charset:
	.byte $3c,$66,$6e,$6e,$60,$62,$3c,$00,$18,$3c,$66,$7e,$66,$66,$66,$00	// 0
	.byte $7c,$66,$66,$7c,$66,$66,$7c,$00,$3c,$66,$60,$60,$60,$66,$3c,$00	// 16
	.byte $78,$6c,$66,$66,$66,$6c,$78,$00,$7e,$60,$60,$78,$60,$60,$7e,$00	// 32
	.byte $7e,$60,$60,$78,$60,$60,$60,$00,$3c,$66,$60,$6e,$66,$66,$3c,$00	// 48
	.byte $66,$66,$66,$7e,$66,$66,$66,$00,$3c,$18,$18,$18,$18,$18,$3c,$00	// 64
	.byte $1e,$0c,$0c,$0c,$0c,$6c,$38,$00,$66,$6c,$78,$70,$78,$6c,$66,$00	// 80
	.byte $60,$60,$60,$60,$60,$60,$7e,$00,$63,$77,$7f,$6b,$63,$63,$63,$00	// 96
	.byte $66,$76,$7e,$7e,$6e,$66,$66,$00,$3c,$66,$66,$66,$66,$66,$3c,$00	// 112
	.byte $7c,$66,$66,$7c,$60,$60,$60,$00,$3c,$66,$66,$66,$66,$3c,$0e,$00	// 128
	.byte $7c,$66,$66,$7c,$78,$6c,$66,$00,$3c,$66,$60,$3c,$06,$66,$3c,$00	// 144
	.byte $7e,$18,$18,$18,$18,$18,$18,$00,$66,$66,$66,$66,$66,$66,$3c,$00	// 160
	.byte $66,$66,$66,$66,$66,$3c,$18,$00,$63,$63,$63,$6b,$7f,$77,$63,$00	// 176
	.byte $66,$66,$3c,$18,$3c,$66,$66,$00,$66,$66,$66,$3c,$18,$18,$18,$00	// 192
	.byte $7e,$06,$0c,$18,$30,$60,$7e,$00,$3c,$30,$30,$30,$30,$30,$3c,$00	// 208
	.byte $0c,$12,$30,$7c,$30,$62,$fc,$00,$3c,$0c,$0c,$0c,$0c,$0c,$3c,$00	// 224
	.byte $00,$18,$3c,$7e,$18,$18,$18,$18,$00,$10,$30,$7f,$7f,$30,$10,$00	// 240
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$18,$18,$18,$18,$00,$00,$18,$00	// 256
	.byte $66,$66,$66,$00,$00,$00,$00,$00,$66,$66,$ff,$66,$ff,$66,$66,$00	// 272
	.byte $18,$3e,$60,$3c,$06,$7c,$18,$00,$62,$66,$0c,$18,$30,$66,$46,$00	// 288
	.byte $3c,$66,$3c,$38,$67,$66,$3f,$00,$06,$0c,$18,$00,$00,$00,$00,$00	// 304
	.byte $0c,$18,$30,$30,$30,$18,$0c,$00,$30,$18,$0c,$0c,$0c,$18,$30,$00	// 320
	.byte $00,$66,$3c,$ff,$3c,$66,$00,$00,$00,$18,$18,$7e,$18,$18,$00,$00	// 336
	.byte $00,$00,$00,$00,$00,$18,$18,$30,$00,$00,$00,$7e,$00,$00,$00,$00	// 352
	.byte $00,$00,$00,$00,$00,$18,$18,$00,$00,$03,$06,$0c,$18,$30,$60,$00	// 368
	.byte $3c,$66,$6e,$76,$66,$66,$3c,$00,$18,$18,$38,$18,$18,$18,$7e,$00	// 384
	.byte $3c,$66,$06,$0c,$30,$60,$7e,$00,$3c,$66,$06,$1c,$06,$66,$3c,$00	// 400
	.byte $06,$0e,$1e,$66,$7f,$06,$06,$00,$7e,$60,$7c,$06,$06,$66,$3c,$00	// 416
	.byte $3c,$66,$60,$7c,$66,$66,$3c,$00,$7e,$66,$0c,$18,$18,$18,$18,$00	// 432
	.byte $3c,$66,$66,$3c,$66,$66,$3c,$00,$3c,$66,$66,$3e,$06,$66,$3c,$00	// 448
	.byte $00,$00,$18,$00,$00,$18,$00,$00,$00,$00,$18,$00,$00,$18,$18,$30	// 464
	.byte $0e,$18,$30,$60,$30,$18,$0e,$00,$00,$00,$7e,$00,$7e,$00,$00,$00	// 480
	.byte $70,$18,$0c,$06,$0c,$18,$70,$00,$3c,$66,$06,$0c,$18,$00,$18,$00	// 496
	.byte $00,$00,$00,$ff,$ff,$00,$00,$00,$08,$1c,$3e,$7f,$7f,$1c,$3e,$00	// 512
	.byte $18,$18,$18,$18,$18,$18,$18,$18,$00,$00,$00,$ff,$ff,$00,$00,$00	// 528
	.byte $00,$00,$ff,$ff,$00,$00,$00,$00,$00,$ff,$ff,$00,$00,$00,$00,$00	// 544
	.byte $00,$00,$00,$00,$ff,$ff,$00,$00,$30,$30,$30,$30,$30,$30,$30,$30	// 560
	.byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$00,$00,$00,$e0,$f0,$38,$18,$18	// 576
	.byte $18,$18,$1c,$0f,$07,$00,$00,$00,$18,$18,$38,$f0,$e0,$00,$00,$00	// 592
	.byte $c0,$c0,$c0,$c0,$c0,$c0,$ff,$ff,$c0,$e0,$70,$38,$1c,$0e,$07,$03	// 608
	.byte $03,$07,$0e,$1c,$38,$70,$e0,$c0,$ff,$ff,$c0,$c0,$c0,$c0,$c0,$c0	// 624
	.byte $ff,$ff,$03,$03,$03,$03,$03,$03,$00,$3c,$7e,$7e,$7e,$7e,$3c,$00	// 640
	.byte $00,$00,$00,$00,$00,$ff,$ff,$00,$36,$7f,$7f,$7f,$3e,$1c,$08,$00	// 656
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$00,$00,$00,$07,$0f,$1c,$18,$18	// 672
	.byte $c3,$e7,$7e,$3c,$3c,$7e,$e7,$c3,$00,$3c,$7e,$66,$66,$7e,$3c,$00	// 688
	.byte $18,$18,$66,$66,$18,$18,$3c,$00,$06,$06,$06,$06,$06,$06,$06,$06	// 704
	.byte $08,$1c,$3e,$7f,$3e,$1c,$08,$00,$18,$18,$18,$ff,$ff,$18,$18,$18	// 720
	.byte $c0,$c0,$30,$30,$c0,$c0,$30,$30,$18,$18,$18,$18,$18,$18,$18,$18	// 736
	.byte $00,$00,$03,$3e,$76,$36,$36,$00,$ff,$7f,$3f,$1f,$0f,$07,$03,$01	// 752
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0	// 768
	.byte $00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00	// 784
	.byte $00,$00,$00,$00,$00,$00,$00,$ff,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0	// 800
	.byte $cc,$cc,$33,$33,$cc,$cc,$33,$33,$03,$03,$03,$03,$03,$03,$03,$03	// 816
	.byte $00,$00,$00,$00,$cc,$cc,$33,$33,$ff,$fe,$fc,$f8,$f0,$e0,$c0,$80	// 832
	.byte $03,$03,$03,$03,$03,$03,$03,$03,$18,$18,$18,$1f,$1f,$18,$18,$18	// 848
	.byte $00,$00,$00,$00,$0f,$0f,$0f,$0f,$18,$18,$18,$1f,$1f,$00,$00,$00	// 864
	.byte $00,$00,$00,$f8,$f8,$18,$18,$18,$00,$00,$00,$00,$00,$00,$ff,$ff	// 880
	.byte $00,$00,$00,$1f,$1f,$18,$18,$18,$18,$18,$18,$ff,$ff,$00,$00,$00	// 896
	.byte $00,$00,$00,$ff,$ff,$18,$18,$18,$18,$18,$18,$f8,$f8,$18,$18,$18	// 912
	.byte $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0	// 928
	.byte $07,$07,$07,$07,$07,$07,$07,$07,$ff,$ff,$00,$00,$00,$00,$00,$00	// 944
	.byte $ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff	// 960
	.byte $03,$03,$03,$03,$03,$03,$ff,$ff,$00,$00,$00,$00,$f0,$f0,$f0,$f0	// 976
	.byte $0f,$0f,$0f,$0f,$00,$00,$00,$00,$18,$18,$18,$f8,$f8,$00,$00,$00	// 992
	.byte $f0,$f0,$f0,$f0,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$0f,$0f,$0f,$0f	// 1008
	.byte $08,$3b,$2a,$2a,$2a,$3a,$1b,$0e,$00,$00,$00,$00,$40,$c0,$80,$c0	// 1024
	.byte $08,$3b,$2a,$2a,$6a,$eb,$b9,$ec,$0e,$3a,$2a,$2a,$3a,$2a,$3a,$2e	// 1040
	.byte $ab,$aa,$aa,$c1,$00,$00,$00,$00,$40,$b0,$ac,$a9,$6b,$2a,$2b,$69	// 1056
	.byte $00,$03,$0e,$0a,$3a,$2a,$3a,$2e,$01,$3a,$2a,$3a,$01,$00,$00,$00	// 1072
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1088
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1104
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1120
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1136
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1152
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1168
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1184
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1200
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1216
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1232
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1248
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1264
	.byte $0f,$07,$03,$01,$00,$00,$00,$00,$91,$e2,$b7,$fe,$7f,$df,$77,$1d	// 1280
	.byte $bc,$e4,$b0,$d0,$c0,$c0,$40,$00,$7b,$aa,$aa,$aa,$b3,$c0,$00,$00	// 1296
	.byte $01,$46,$ee,$fb,$df,$41,$00,$00,$a8,$a4,$d0,$40,$d0,$f4,$fc,$7d	// 1312
	.byte $3b,$3e,$3b,$3e,$3f,$1f,$3f,$1f,$7f,$aa,$aa,$aa,$ea,$2e,$3a,$2e	// 1328
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1344
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1360
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1376
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1392
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1408
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1424
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1440
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1456
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1472
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1488
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1504
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1520
	.byte $37,$1d,$17,$05,$17,$05,$11,$04,$1d,$37,$15,$07,$15,$05,$11,$04	// 1536
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$03,$0e,$3a,$2a,$3a,$2a,$3a,$2e	// 1552
	.byte $00,$c0,$80,$b3,$ae,$aa,$ea,$3b,$30,$ec,$ab,$aa,$aa,$aa,$ee,$3a	// 1568
	.byte $40,$b0,$ac,$a8,$ab,$ea,$2e,$3a,$50,$ab,$aa,$ab,$d0,$00,$00,$00	// 1584
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1600
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1616
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1632
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1648
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1664
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1680
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1696
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1712
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1728
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1744
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1760
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1776
	.byte $37,$1d,$17,$15,$05,$04,$01,$00,$00,$00,$40,$c0,$77,$55,$11,$44	// 1792
	.byte $37,$1d,$57,$d5,$54,$44,$10,$40,$0c,$04,$00,$00,$00,$00,$00,$00	// 1808
	.byte $00,$00,$00,$c0,$bb,$ef,$ff,$40,$2e,$3b,$2e,$bb,$fe,$ff,$fe,$7f	// 1824
	.byte $2e,$3b,$3e,$3b,$3e,$1f,$3e,$1f,$00,$00,$00,$00,$00,$00,$00,$00	// 1840
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1856
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1872
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1888
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1904
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1920
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1936
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1952
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1968
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 1984
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 2000
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 2016
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	// 2032
