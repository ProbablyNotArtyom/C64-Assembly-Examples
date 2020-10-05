
#importonce

#if !__C64__
#define	__C64__
.encoding "petscii_upper"
#endif

#import "../include/system.inc"

//-----------------------------------------------------
// Pseudos for managing interrupts

.pseudocommand irq_entry {
	pha
	tya
	pha
	txa
	pha
}

.pseudocommand irq_exit {
	pla
	tax
	pla
	tay
	pla
}
