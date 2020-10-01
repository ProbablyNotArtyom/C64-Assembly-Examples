
#if !__C64__
#define	__C64__
.encoding "petscii_upper"
#endif

//-----------------------------------------------------
// Kernal stuff

.const CHKIN				= $FFC6
.const CKOUT				= $FFC9
.const CHKOUT				= $FFC9
.const CLRCH				= $FFCC
.const CLRCHN				= $FFCC
.const BASIN				= $FFCF
.const CHRIN				= $FFCF
.const BSOUT				= $FFD2
.const CHROUT				= $FFD2
.const SETMSG				= $FF90
.const SECOND				= $FF93
.const TKSA					= $FF96
.const MEMTOP				= $FF99
.const MEMBOT				= $FF9C
.const SCNKEY				= $FF9F
.const SETTMO				= $FFA2
.const ACPTR				= $FFA5
.const CIOUT				= $FFA8
.const UNTLK				= $FFAB
.const UNLSN				= $FFAE
.const LISTEN				= $FFB1
.const TALK					= $FFB4
.const READST				= $FFB7
.const SETLFS				= $FFBA
.const SETNAM				= $FFBD
.const OPEN					= $FFC0
.const CLOSE				= $FFC3
.const STOP					= $FFE1
.const GETIN				= $FFE4
.const CLALL				= $FFE7
.const UDTIM				= $FFEA

.const VARTAB				= $2D			// Pointer to start of BASIC variables
.const MEMSIZE				= $37			// Pointer to highest BASIC RAM location (+1)
.const TXTPTR				= $7A			// Pointer into BASIC source code
.const TIME					= $A0			// 60 HZ clock
.const FNAM_LEN				= $B7			// Length of filename
.const SECADR				= $B9			// Secondary address
.const DEVNUM				= $BA			// Device number
.const FNAM					= $BB			// Pointer to filename
.const KEY_COUNT			= $C6			// Number of keys in input buffer
.const RVS					= $C7			// Reverse flag
.const CURS_FLAG			= $CC			// 1 -> cursor off
.const CURS_BLINK			= $CD			// Blink counter
.const CURS_CHAR			= $CE			// Character under the cursor
.const CURS_STATE			= $CF			// Cursor blink state
.const SCREEN_PTR			= $D1			// Pointer to current char in text screen
.const CURS_X				= $D3			// Cursor column
.const CURS_Y				= $D6			// Cursor row
.const CRAM_PTR				= $F3			// Pointer to current char in color RAM
.const FREKZP				= $FB			// Five unused bytes

.const BASIC_BUF			= $200			// Location of command-line
.const BASIC_BUF_LEN		= 89 			// Maximum length of command-line

.const CHARCOLOR			= $286
.const CURS_COLOR			= $287			// Color under the cursor
.const PALFLAG				= $2A6			// $01 -> PAL, $00 -> NTSC

.const KBDREPEAT			= $28a
.const KBDREPEATRATE		= $28b
.const KBDREPEATDELAY		= $28c
.const RESTOR				= $FF8A
.const VECTOR				= $FF8D

//-----------------------------------------------------
