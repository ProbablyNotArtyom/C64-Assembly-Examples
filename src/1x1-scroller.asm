
	#import "../include/system.inc"
	#import "../include/kernal.inc"
	#import "../include/macros.inc"
	.encoding "screencode_mixed"

//-----------------------------------------------------

/* Constants that modify effect behavior */
.const RASTER_TOP	= $C0			// Line to begin scroller section
.const RASTER_END	= $CB			// Line to begin scroller section
.const SCROLL_LINE	= 18			// Char line to display scroller
.const SPEED		= 2				// Speed multiplier

/* Constants */
.const LINEADDR		= get_screen_line($0400, SCROLL_LINE)
.const COLORADDR 	= get_screen_line($D800, SCROLL_LINE)

/* Zeropage variables */
.var x_offset		= $F0			// Current pixel offset
.var saved_border	= $F1
.var saved_bg		= $F2

//-----------------------------------------------------

*=$0801 "Basic"
BasicUpstart2(setup)
*=$0820 "Program"

setup:
	sei

	/* Save the runner's colors so we can restore them later */
	lda VIC_border_color
	sta saved_border
	lda VIC_bg_color0
	sta saved_bg

	/* Write color data */
	ClearScreenLine($0400, ' ', SCROLL_LINE)
	ClearColorRamLine(COLOR_WHITE, SCROLL_LINE)
	lda #COLOR_BLACK
	sta COLORADDR
	sta COLORADDR+38
	lda #COLOR_BLUE
	sta COLORADDR+1
	sta COLORADDR+37
	lda #COLOR_VIOLET
	sta COLORADDR+2
	sta COLORADDR+36
	lda #COLOR_LIGHTBLUE
	sta COLORADDR+3
	sta COLORADDR+35
	lda #COLOR_CYAN
	sta COLORADDR+4
	sta COLORADDR+34
	lda #COLOR_LIGHTGREEN
	sta COLORADDR+5
	sta COLORADDR+33

	lda #$1B
	sta VIC_config1
	lda #$7F
	sta CIA1_ICR
	lda #$01
	sta VIC_irq_mask

	/* Setup the IRQs */
	lda #<irq0
	ldx #>irq0
	sta vec_IRQ
	stx vec_IRQ+1

	lda #RASTER_TOP		// Set next raster IRQ
	sta VIC_raster

	cli
	jmp *

irq0:
	inc VIC_irq_state	// Acknowledge the IRQ
	{
		wait(11)
		lda #COLOR_BLACK
		sta VIC_border_color
		sta VIC_bg_color0
		/* Set charROM to lower/upper mode */
		lda #[[$0400 & $3fff] / 64] | [[$1800 & $3fff] / 1024]
		sta VIC_memory_config
	}
	lda #RASTER_END		// Set next raster IRQ
	sta VIC_raster
	lda x_offset		// Scroll section
	sta VIC_config2
	lda #<irq1			// Set the IRQ vector for the next IRQ
	ldx #>irq1
	sta vec_IRQ
	stx vec_IRQ+1
	jmp $ea7e			// Exit the kernal IRQ

irq1:
	inc VIC_irq_state	// Acknowledge the IRQ
	lda #$08			// No scroll section here
	sta VIC_config2
	{
		lda saved_border
		ldx saved_bg
		wait(30)
		sta VIC_border_color
		stx VIC_bg_color0
		/* Set charROM to upper/graphic mode */
		lda #[[$0400 & $3fff] / 64] | [[$1000 & $3fff] / 1024]
		sta VIC_memory_config
	}
	lda #RASTER_TOP		// Set next raster IRQ
	sta VIC_raster
	lda #<irq0
	ldx #>irq0
	sta vec_IRQ
	stx vec_IRQ+1
	jsr scroll
	jmp $ea7e			// Exit the kernal IRQ

scroll:
	lda x_offset
	sec
	sbc #SPEED			// Speed of scroll can be edited to how you want it, but don't go too mad :)
	and #$07			// We need this to make the variable x_offset into something smooth :)
	sta x_offset
	bcs scroll_e
	ldx #$00
!:	lda LINEADDR+1,x
	sta LINEADDR,x
	inx
	cpx #$28
	bne !-
!:	lda text:scrolltxt
	bne !+	 			// Implied cmp #$00
	lda #<scrolltxt
	ldy #>scrolltxt
	sta text
	sty text+1
	jmp !-
!:
	sta LINEADDR+$27
	inc text
	lda text
	bne scroll_e		// Implied cmp #$00
	inc text+1
scroll_e:
	rts

//-----------------------------------------------------

scrolltxt:
	.text "This is the 1x1 smooth scroller example from "
	.text "https://github.com/ProbablyNotArtyom/C64-Assembly-Examples.git"
	.text "                    "
	.text "This effect uses two raster interrupts that form the top and bottom lines of the scoller. "
	.text "Text data is streamed to the screen from elsewhere in memory. "
	.text "Once that text reaches its end, it wraps around and repeats oncemore..."
	.text "                    "
	.byte $00
