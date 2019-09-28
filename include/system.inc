//  Color defines
.var	COLOR_BLACK			= $00
.var	COLOR_WHITE			= $01
.var	COLOR_RED			= $02
.var	COLOR_CYAN			= $03
.var	COLOR_VIOLET		= $04
.var	COLOR_GREEN			= $05
.var	COLOR_BLUE			= $06
.var	COLOR_YELLOW		= $07
.var	COLOR_ORANGE		= $08
.var	COLOR_BROWN			= $09
.var	COLOR_LIGHTRED		= $0A
.var	COLOR_GRAY1			= $0B
.var	COLOR_GRAY2			= $0C
.var	COLOR_LIGHTGREEN	= $0D
.var	COLOR_LIGHTBLUE		= $0E
.var	COLOR_GRAY3			= $0F

.function _16bit_nextArgument(arg) {
	.if (arg.getType()==AT_IMMEDIATE)
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
