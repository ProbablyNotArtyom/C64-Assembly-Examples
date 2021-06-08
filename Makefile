CRUNCH := false
DEBUG := false

BASEDIR := $(PWD)
BINDIR := bin
SRCDIR := src
INCDIR := include

AS = kickass
ASSFLAGS = -libdir $(INCDIR)
ifeq ("$(DEBUG)","true")
ASSFLAGS += -symbolfiledir ../bin -symbolfile -vicesymbols -debug -debugdump -pseudoc3x
endif

REBUILD := $(shell find $(BASEDIR)/$(INCDIR) -name '*.inc')
SOURCES := $(shell find $(BASEDIR)/$(SRCDIR) -name '*.asm')
OUTPUTS := $(patsubst $(BASEDIR)/$(SRCDIR)/%.asm, ./$(BINDIR)/%.prg, $(SOURCES))
RUN_OUTPUTS := $(foreach target, $(OUTPUTS), run-$(notdir $(target)))
DISKNAME := samples.d64

########################################

.PHONY: all clean run
all: $(OUTPUTS)

clean:
	rm -rf $(BINDIR)/*
	rm -f $(FILNAME) $(DISKNAME)

disk: all
	rm -f $(DISKNAME)
	cc1541 -n disk -i 01 $(foreach prg, $(OUTPUTS), -w $(prg)) $(DISKNAME)

.SECONDEXPANSION:
$(OUTPUTS): $$(patsubst $$(BINDIR)/%.prg, $$(BASEDIR)/$$(SRCDIR)/%.asm, $$@) $(REBUILD)
	$(AS) $(patsubst $(BINDIR)%, $(BASEDIR)/$(SRCDIR)%, $(@:%.prg=%.asm)) $(ASSFLAGS) -o $@
ifeq ("$(CRUNCH)","true")
	exomizer sfx sys $@ -o $@
endif

$(RUN_OUTPUTS): $(BINDIR)/$$(subst run-,,$$@)
	./run.sh $^
