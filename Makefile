BASEDIR := ./
BINDIR := bin
SRCDIR := ./src
INCDIR := ./include

AS = kickass
ASSFLAGS = -symbolfiledir ../bin/syms -symbolfile -libdir $(INCDIR)

SOURCES := $(shell find ./src -name '*.asm')
OUTPUTS := $(patsubst $(SRCDIR)/%.asm, $(BINDIR)/%.prg, $(SOURCES))
RUN_OUTPUTS := $(foreach target, $(SOURCES), run-$(target))

########################################

.PHONY: all clean run
all: clean $(OUTPUTS)

clean:
	rm -rf $(BINDIR)/*
	rm -f $(FILNAME)

$(OUTPUTS): clean
	$(AS) $(patsubst $(BINDIR)%, $(SRCDIR)%, $(@:%.prg=%.asm)) $(ASSFLAGS) -o $@
