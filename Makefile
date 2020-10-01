CRUNCH = true

BASEDIR := $(PWD)
BINDIR := $(BASEDIR)/bin
SRCDIR := $(BASEDIR)/src
INCDIR := $(BASEDIR)/include

AS = kickass
ASSFLAGS = -symbolfiledir ../bin/syms -symbolfile -libdir $(INCDIR)

REBUILD := $(shell find $(INCDIR) -name '*.inc')
SOURCES := $(shell find $(SRCDIR) -name '*.asm')
OUTPUTS := $(patsubst $(SRCDIR)/%.asm, $(BINDIR)/%.prg, $(SOURCES))
RUN_OUTPUTS := $(foreach target, $(SOURCES), run-$(target))

########################################

.PHONY: all clean run
all: $(OUTPUTS)

clean:
	rm -rf $(BINDIR)/*
	rm -f $(FILNAME)

.SECONDEXPANSION:
$(OUTPUTS): $$(patsubst $$(BINDIR)/%.prg, $$(SRCDIR)/%.asm, $$@) $(REBUILD)
	$(AS) $(patsubst $(BINDIR)%, $(SRCDIR)%, $(@:%.prg=%.asm)) $(ASSFLAGS) -o $@
ifeq ("$(CRUNCH)","true")
	exomizer sfx sys $@ -o $@
endif
