
	#import "../main.asm"

.var Screen = $2000
.var Color  = $0400


//---------------------------------------

*=$0801 "Basic"
BasicUpstart2(init)
*=$810 "Program"

init:
	lda #$FF    // set garbage
	sta $3fff
	sei         // disable interrupt
	
	lda #$35
	sta $01
	
	lda #$7f    // disable timer interrupt
	sta $dc0d
	lda #1      // enable raster interrupt
	sta $d01a
	lda #<irq   // set irq vector
	sta $FFFE
	lda #>irq
	sta $FFFF
	lda #48      // to evoke our irq routine on 0th line
	sta $d012
	cli         // enable interrupt

!:	jmp *
	
//---------------------------------------

irq: 
	pha
	tya
	pha
	txa
	pha
	
	inc ofset
	ldx ofset
	lda sin256,x
	sta vsp_ofset
	ldx #$2
l2:	ldy $d012   // moving 1st bad line
l1:	cpy $d012
	beq l1      // wait for begin of next line
	dey         // iy - bad line
	tya
	and #$07    // clear higher 5 bits
	ora #$10    // set text mode
	sta $d011
	dex
	bne l2
	
	lda #39
	sec
	sbc vsp_ofset
	lsr
	sta vsp_delay+1
	clv
	bcc vsp_delay
vsp_delay:
	bvc *
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
	lda #%00111011
	dec $d011
	inc $d011
	sta $d011
	
	lsr $d019   // acknowledge the raster interrupt
!:	pla
	tax
	pla
	tay
	pla
	rti

//---------------------------------------

sin256:
.byte 30,28,27,25,24,23,22,21,20,20,20,20,20,20,21,22
.byte 22,24,25,26,28,29,31,32,33,35,36,37,38,39,39,39
.byte 39,39,39,38,38,37,36,34,33,32,30,29,27,26,25,23
.byte 22,21,21,20,20,20,20,20,20,21,22,23,24,26,27,28
.byte 30,31,33,34,35,37,37,38,39,39,39,39,39,39,38,37
.byte 36,35,34,32,31,30,28,27,25,24,23,22,21,20,20,20
.byte 20,20,20,21,22,22,24,25,26,28,29,31,32,33,35,36
.byte 37,38,39,39,39,39,39,39,38,38,37,36,34,33,32,30
.byte 29,27,26,25,23,22,21,21,20,20,20,20,20,20,21,22
.byte 23,24,26,27,28,30,31,33,34,35,37,37,38,39,39,39
.byte 39,39,39,38,37,36,35,34,32,31,30,28,27,25,24,23
.byte 22,21,20,20,20,20,20,20,21,22,22,24,25,26,28,29
.byte 31,32,33,35,36,37,38,39,39,39,39,39,39,38,38,37
.byte 36,34,33,32,30,29,27,26,25,23,22,21,21,20,20,20
.byte 20,20,20,21,22,23,24,26,27,28,30,31,33,34,35,37
.byte 37,38,39,39,39,39,39,39,38,37,36,35,34,32,31,30

ofset: .byte $00
vsp_ofset: .byte $00
