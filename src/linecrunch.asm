
	#import "../main.asm"

//---------------------------------------

.var	from 	= $32
.var	to   	= (sine256_end - sine256)

//---------------------------------------

*=$0801 "Basic"
BasicUpstart2(init)
*=$810 "Program"

init:
	lda #$00    // set garbage
	sta $3fff
	lda #from
	sta ofset   // set ofset
	sei         // disable interrupt
	lda #$7f    // disable timer interrupt
	sta $dc0d
	lda #1      // enable raster interrupt
	sta VIC_IMR
	lda #<irq   // set irq vector
	sta $0314
	lda #>irq
	sta $0315
	lda #0      // to evoke our irq routine on 0th line
	sta VIC_HLINE
	cli         // enable interrupt
	rts

//---------------------------------------

irq:
	lda #COLOR_LIGHTBLUE
	sta $d021
	ldx	ofset
	lda sine256,x
	tax
l2:	ldy VIC_HLINE   // moving 1st bad line
l1:	cpy VIC_HLINE
	beq l1      // wait for begin of next line
	dey         // iy - bad line
	tya
	and #$07    // clear higher 5 bits
	ora #$10    // set text mode
	sta VIC_CTRL1
	dex
	bne l2

	lda #COLOR_BLUE
	sta $d021
	inc VIC_IRR   // acknowledge the raster interrupt
	inc ofset   // down
	lda ofset
	cmp #to
	bne !+
	lda #from
	sta ofset
!:	jmp $ea31   // do standard irq routine

//---------------------------------------
sine256:
.for(var pad = from; pad > 0; pad--) .byte 00 			// Pad the start of the lookup table

.byte 51,52,53,55,57,59,62,65,68,71,74,78,82,85,89,93
.byte 97,100,104,107,111,114,117,120,122,124,126,128,129,130,131,131
.byte 131,131,130,129,128,127,126,124,122,120,118,116,114,112,110,108
.byte 106,104,102,101,100,98,98,97,97,97,97,98,99,100,101,103
.byte 105,108,110,113,116,120,123,127,130,134,138,142,146,149,153,157
.byte 160,163,166,169,171,174,175,177,178,179,179,179,179,179,178,176
.byte 174,172,170,167,165,161,158,155,151,147,143,139,135,131,128,124
.byte 120,117,113,110,107,105,102,100,98,97,96,95,94,94,94,94
.byte 95,96,97,98,100,101,103,105,107,109,111,114,116,118,120,121
.byte 123,125,126,127,128,128,128,128,128,127,126,125,123,121,119,117
.byte 114,111,108,105,101,98,94,91,87,83,80,76,73,69,66,63
.byte 61,58,56,54
sine256_end:

//---------------------------------------

ofset: .byte $00
