
#if !__C64__
#define	__C64__
.encoding "petscii_upper"
#endif

//-----------------------------------------------------
// Color defines

.enum {
	COLOR_BLACK,
	COLOR_WHITE,
	COLOR_RED,
	COLOR_CYAN,
	COLOR_VIOLET,
	COLOR_GREEN,
	COLOR_BLUE,
	COLOR_YELLOW,
	COLOR_ORANGE,
	COLOR_BROWN,
	COLOR_LIGHTRED,
	COLOR_GRAY1,
	COLOR_GRAY2,
	COLOR_LIGHTGREEN,
	COLOR_LIGHTBLUE,
	COLOR_GRAY3
}

//-----------------------------------------------------
// Vectors

.const vec_IRQ			= $0314
.const vec_BRK			= $0316
.const vec_NMI			= $0318

.const sysvec_IRQ		= $FFFE
.const sysvec_BRK		= $FFFC
.const sysvec_NMI		= $FFFA

//-----------------------------------------------------
// VIC

.const VIC					= $D000
.const VIC_sprite0_x		= $D000
.const VIC_sprite0_y		= $D001
.const VIC_sprite1_x		= $D002
.const VIC_sprite1_y		= $D003
.const VIC_sprite2_x		= $D004
.const VIC_sprite2_y		= $D005
.const VIC_sprite3_x		= $D006
.const VIC_sprite3_y		= $D007
.const VIC_sprite4_x		= $D008
.const VIC_sprite4_y		= $D009
.const VIC_sprite5_x		= $D00A
.const VIC_sprite5_y		= $D00B
.const VIC_sprite6_x		= $D00C
.const VIC_sprite6_y		= $D00D
.const VIC_sprite7_x		= $D00E
.const VIC_sprite7_y		= $D00F
.const VIC_sprite_hi_x		= $D010
.const VIC_sprite_enable	= $D015
.const VIC_sprite_expand_y	= $D017
.const VIC_sprite_expand_x	= $D01D
.const VIC_sprite_mcm_mode	= $D01C
.const VIC_sprite_priority	= $D01B

.const VIC_sprite_mcolor0	= $D025
.const VIC_sprite_mcolor1	= $D026

.const VIC_sprite0_color	= $D027
.const VIC_sprite1_color	= $D028
.const VIC_sprite2_color	= $D029
.const VIC_sprite3_color	= $D02A
.const VIC_sprite4_color	= $D02B
.const VIC_sprite5_color	= $D02C
.const VIC_sprite6_color	= $D02D
.const VIC_sprite7_color	= $D02E

.const VIC_config1			= $D011
.const VIC_config2			= $D016

.const VIC_raster			= $D012

.const VIC_lightpen_x		= $D013
.const VIC_lightpen_y		= $D014

.const VIC_memory_config	= $D018

.const VIC_irq_state		= $D019		// Interrupt request register
.const VIC_irq_mask			= $D01A		// Interrupt mask register

.const VIC_border_color		= $D020
.const VIC_bg_color0		= $D021
.const VIC_bg_color1		= $D022
.const VIC_bg_color2		= $D023
.const VIC_bg_color3		= $D024

//-----------------------------------------------------
// SID

.const SID					= $D400
.const SID_S1Lo				= $D400
.const SID_S1Hi				= $D401
.const SID_PB1Lo			= $D402
.const SID_PB1Hi			= $D403
.const SID_Ctl1				= $D404
.const SID_AD1				= $D405
.const SID_SUR1				= $D406

.const SID_S2Lo				= $D407
.const SID_S2Hi				= $D408
.const SID_PB2Lo			= $D409
.const SID_PB2Hi			= $D40A
.const SID_Ctl2				= $D40B
.const SID_AD2				= $D40C
.const SID_SUR2				= $D40D

.const SID_S3Lo				= $D40E
.const SID_S3Hi				= $D40F
.const SID_PB3Lo			= $D410
.const SID_PB3Hi			= $D411
.const SID_Ctl3				= $D412
.const SID_AD3				= $D413
.const SID_SUR3				= $D414

.const SID_FltLo			= $D415
.const SID_FltHi			= $D416
.const SID_FltCtl			= $D417
.const SID_Amp				= $D418
.const SID_ADConv1			= $D419
.const SID_ADConv2			= $D41A
.const SID_Noise			= $D41B
.const SID_Read3			= $D41C

//-----------------------------------------------------
// CIA 1 & 2

.const CIA1					= $DC00
.const CIA1_PRA				= $DC00		// Port A
.const CIA1_PRB				= $DC01		// Port B
.const CIA1_DDRA			= $DC02		// Data direction register for port A
.const CIA1_DDRB			= $DC03		// Data direction register for port B
.const CIA1_TA				= $DC04		// 16-bit timer A
.const CIA1_TB				= $DC06		// 16-bit timer B
.const CIA1_TOD10			= $DC08		// Time-of-day tenths of a second
.const CIA1_TODSEC			= $DC09		// Time-of-day seconds
.const CIA1_TODMIN			= $DC0A		// Time-of-day minutes
.const CIA1_TODHR			= $DC0B		// Time-of-day hours
.const CIA1_SDR				= $DC0C		// Serial data register
.const CIA1_ICR				= $DC0D		// Interrupt control register
.const CIA1_CRA				= $DC0E		// Control register for timer A
.const CIA1_CRB				= $DC0F		// Control register for timer B

.const CIA2					= $DD00
.const CIA2_PRA				= $DD00
.const CIA2_PRB				= $DD01
.const CIA2_DDRA			= $DD02
.const CIA2_DDRB			= $DD03
.const CIA2_TA				= $DD04
.const CIA2_TB				= $DD06
.const CIA2_TOD10			= $DD08
.const CIA2_TODSEC			= $DD09
.const CIA2_TODMIN			= $DD0A
.const CIA2_TODHR			= $DD0B
.const CIA2_SDR				= $DD0C
.const CIA2_ICR				= $DD0D
.const CIA2_CRA				= $DD0E
.const CIA2_CRB				= $DD0F

//-----------------------------------------------------

.function _16bit_nextArgument(arg) {
	.if (arg.getType() == AT_IMMEDIATE)
	.return CmdArgument(arg.getType(),>arg.getValue())
	.return CmdArgument(arg.getType(),arg.getValue()+1)
}

.pseudocommand inc16 arg {
	inc arg
	bne over
	inc _16bit_nextArgument(arg)
over:
}

.pseudocommand dec16 arg {
	lda arg
	bne !+
	dec _16bit_nextArgument(arg)
!:	dec arg
}

.pseudocommand mov16 src : tar {
	lda src
	sta tar
	lda _16bit_nextArgument(src)
	sta _16bit_nextArgument(tar)
}

.pseudocommand add16 arg1 : arg2 : tar {
.if (tar.getType()==AT_NONE) .eval tar=arg1
	lda arg1
	adc arg2
	sta tar
	lda _16bit_nextArgument(arg1)
	adc _16bit_nextArgument(arg2)
	sta _16bit_nextArgument(tar)
}
