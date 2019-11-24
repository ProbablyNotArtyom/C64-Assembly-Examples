/*
Example of a char cycler effect for the Commodore 64
Coded by Scan/Desire
Compile using Kick Assembler
Made with the help of consulting http://lodev.org/cgtutor/plasma.html
Pseudo-random number generator from http://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
For the full effect, see the "C64, Hear 64" demo from Desire: https://www.youtube.com/watch?v=ftEYcJDlFjg#t=6m55s
 */
.const w=40
.const h=25
.const multicolor=true

basic:
:BasicUpstart2(start)

.pc = * "Entrypoint"
start:
				// Initialize stuff
				jsr $ff81
				jsr $ff84
				jsr $ff8a

				jsr generatecharset // trashes memory area where speedcode will be generated later
				jsr generatespeedcode

				sei
				// Initialize colors and screen data
				.if (multicolor) {
					lda #CYAN
				} else {
					lda #BLUE
				}
				sta $d021
				lda #BLUE
				sta $d023
				lda #LIGHT_BLUE
				sta $d022
				ldx #$00
				stx $d020
!:				lda screendata,x
				sta $0400,x
				lda screendata+$100,x
				sta $0500,x
				lda screendata+$200,x
				sta $0600,x
				lda screendata+$300,x
				sta $0700,x
				.if (multicolor) {
					lda #BLACK | %00001000
				} else {
					lda #BLACK
				}
				sta $d800,x
				sta $d900,x
				sta $da00,x
				sta $db00,x
				inx
				bne !-

				lda $d018			// set character bank ($2000)
				and #%11110000
				ora #%00001000
				sta $d018

				lda $d016			// enable multicolor charset
				ora #%00010000
				sta $d016

				// Wait for rasterline 255
frame:			lda #$ff
!:				cmp $d012
				bne !-

				// Increase all screen values by 1
		        jsr incall
				jmp frame


.memblock "Speedcode generator"
.const dstlo = $20
.const dsthi = dstlo+1
// This generates a lot of INC $xxxx opcodes, for every position on the screen
generatespeedcode:
				lda #<incall
				sta dstlo
				lda #>incall
				sta dsthi
				lda #$00
				sta scrlo
				lda #$04
				sta scrhi

nextopcode:		ldy #$00
				lda #INC_ABS
				sta (dstlo),y
				iny
				lda scrlo
				sta (dstlo),y
				iny
				lda scrhi
				sta (dstlo),y
				lda dstlo
				clc
				adc #$3
				bcc !+
				inc dsthi
!:				sta dstlo
				inc scrlo
				bne !+
				inc scrhi
!:				lda scrhi
				cmp #$07
				bne nextopcode
				lda scrlo
				cmp #$e8
				bne nextopcode
				ldy #$00
				lda #RTS
				sta (dstlo),y
				rts

scrlo:			.byte 0
scrhi:			.byte 0

.memblock "Characterset generator"
.const chrsrclo = $20
.const chrsrchi = chrsrclo+1
.const chrdstlo = chrsrchi+1
.const chrdsthi = chrdstlo+1

/*
  This routine creates the gradient character set. first another subroutine is called which will create chars
  from being completely empty to completely full. Then this copies (and inverts) the gradient to complete the whole charset, so
  this reads as empty->full->empty->full->repeat.
*/
generatecharset:
				jsr generate64chars
				ldx #$00
!:				lda $2000,x
				sta $2400,x
				eor #$ff
				sta $2200,x
				sta $2600,x
				lda $2100,x
				sta $2500,x
				eor #$ff
				sta $2300,x
				sta $2700,x
				dex
				bne !-
				rts

generate64chars:
				// this generates an array 0-63, randomly ordered but always starts with 0
				jsr generateintarray
				// this will generate a unique random sequence of the numbers
				ldx #63
!:				jsr getrangednum
				beq !-
				sta randomarray,x
				dex
				bne !-
				// blank out 1st character
				ldy #$07
				lda #$00
!:				sta $2000,y
				dey
				bpl !-

				// initialize pointers
				lda #$00
				sta chrsrclo
				lda #$20
				sta chrsrchi
				sta chrdsthi
				lda #$08
				sta chrdstlo

nextchar:		ldx arraycount
				cpx #64
				bne !+
				rts

// This will take a number from the random ordered array and sets a corresponding pixel in the 8x8 char matrix
!:				lda randomarray,x
				pha
				and #%00000111
				sta chrrow
				pla
				lsr
				lsr
				lsr
				tay
				lda #$00
				sec
!:				rol
				dey
				bpl !-
				sta ormask
				ldy chrrow
				lda (chrsrclo),y
				ora ormask
				sta (chrsrclo),y

				// copy current character to next
				ldy #$07
!:				lda (chrsrclo),y
				sta (chrdstlo),y
				dey
				bpl !-

				// move current pointer to next char
				lda chrdstlo
				sta chrsrclo
				lda chrdsthi
				sta chrsrchi
				lda chrdstlo
				clc
				adc #$08
				sta chrdstlo
				bcc !+
				inc chrdsthi
!:				inc arraycount
				jmp nextchar

arraycount:		.byte 0
chrrow:			.byte 0
ormask:			.byte 0

// Generates an array of integers of 0-63
generateintarray:
				ldx #63
!:				txa
				sta intarray,x
				dex
				bpl !-
				rts

// Picks a random number from the list of integers which is not already been used
getrangednum:
alreadyused:	jsr getrndnum
				and #$3f
				tay
				lda intarray,y
				bmi alreadyused
				eor #%10000000
				sta intarray,y	// mark as used
				and #%01111111
				rts

// Codebase stuff ;)
getrndnum:		lda seed
        		beq doEor
         		asl
         		bcc noEor
doEor:    		eor #$1d
noEor:  		sta seed
				rts

seed:			.byte 0

//
.function charcyclegen(x,y,w,h) {
		// This creates a complex charcycle pattern
		//.return (40 * sin(sqrt(pow(x - w / 2, 2) + pow(y - h / 2, 2)) / 2)) + 4 * sin((x + y)) + (62 * cos((x + y) / 5));
		.return (128.0 + (128.0 * sin(x / 2.0)) + 128.0 + (128.0 * cos(y / 3.0)) + 128.0 + (128.0 * cos(sqrt(((x - w / 2.0)* (x - w / 2.0) + (y - h / 2.0) * (y - h / 2.0))) / 4.0)) + 128.0 + (128.0 * sin(sqrt((x * x + y * y)) / 6.0))) / 4;

		// This creates a checkerboard-like effect
		//.return (x ^ y) * 2;
}

.memblock "Screen data"
screendata:
.for (var y = 0; y < h; y++) {
	.for (var x = 0; x < w; x++) {
		.byte charcyclegen(x,y,w,h)
	}
}

.pc = * "Speedcode"
incall:
intarray:
.label randomarray = *+64
