
	#define	__C64__
	.encoding "petscii_upper"

//-----------------------------------------------------

	.var	VIC_BORDERCOLOR = $D020
	.var	VIC_BG_COLOR0   = $D021
	.var	VIC_BG_COLOR1   = $D022
	.var	VIC_BG_COLOR2   = $D023
	.var	VIC_BG_COLOR3   = $D024

	.var	CHKIN          	=	$FFC6
	.var	CKOUT          	=	$FFC9
	.var	CHKOUT         	=	$FFC9
	.var	CLRCH          	=	$FFCC
	.var	CLRCHN         	=	$FFCC
	.var	BASIN          	=	$FFCF
	.var	CHRIN          	=	$FFCF
	.var	BSOUT          	=	$FFD2
	.var	CHROUT         	=	$FFD2
	.var	SETMSG       	=	$FF90
    .var	SECOND       	=	$FF93
    .var	TKSA         	=	$FF96
    .var	MEMTOP       	=	$FF99
    .var	MEMBOT       	=	$FF9C
    .var	SCNKEY       	=	$FF9F
    .var	SETTMO       	=	$FFA2
    .var	ACPTR        	=	$FFA5
    .var	CIOUT        	=	$FFA8
    .var	UNTLK        	=	$FFAB
    .var	UNLSN        	=	$FFAE
    .var	LISTEN       	=	$FFB1
    .var	TALK         	=	$FFB4
    .var	READST       	=	$FFB7
    .var	SETLFS       	=	$FFBA
    .var	SETNAM       	=	$FFBD
    .var	OPEN         	=	$FFC0
    .var	CLOSE        	=	$FFC3
	.var	STOP           	= 	$FFE1
	.var	GETIN          	= 	$FFE4
	.var	CLALL          	= 	$FFE7
	.var	UDTIM          	= 	$FFEA

	.var	VARTAB          =	$2D          // Pointer to start of BASIC variables
	.var	MEMSIZE         =	$37          // Pointer to highest BASIC RAM location (+1)
	.var	TXTPTR          =	$7A          // Pointer into BASIC source code
	.var	TIME            =	$A0          // 60 HZ clock
	.var	FNAM_LEN        =	$B7          // Length of filename
	.var	SECADR          =	$B9          // Secondary address
	.var	DEVNUM          =	$BA          // Device number
	.var	FNAM            =	$BB          // Pointer to filename
	.var	KEY_COUNT       =	$C6          // Number of keys in input buffer
	.var	RVS             =	$C7          // Reverse flag
	.var	CURS_FLAG       =	$CC          // 1 = cursor off
	.var	CURS_BLINK      =	$CD          // Blink counter
	.var	CURS_CHAR       =	$CE          // Character under the cursor
	.var	CURS_STATE      =	$CF          // Cursor blink state
	.var	SCREEN_PTR      =	$D1          // Pointer to current char in text screen
	.var	CURS_X          =	$D3          // Cursor column
	.var	CURS_Y          =	$D6          // Cursor row
	.var	CRAM_PTR        =	$F3          // Pointer to current char in color RAM
	.var	FREKZP          =	$FB          // Five unused bytes

	.var	BASIC_BUF       =	$200         // Location of command-line
	.var	BASIC_BUF_LEN   = 	89           // Maximum length of command-line

	.var	CHARCOLOR       =	$286
	.var	CURS_COLOR      =	$287         // Color under the cursor
	.var	PALFLAG         =	$2A6         // $01 = PAL, $00 = NTSC

	.var	KBDREPEAT       =	$28a
	.var	KBDREPEATRATE   =	$28b
	.var	KBDREPEATDELAY  =	$28c
	.var	RESTOR       	=	$FF8A
    .var	VECTOR       	= 	$FF8D

//-----------------------------------------------------

    #import "include/system.inc"
