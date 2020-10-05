CRUNCH = false

BASEDIR := $(PWD)
BINDIR := bin
SRCDIR := src
INCDIR := include

AS = kickass
ASSFLAGS = -symbolfiledir ../bin/syms -symbolfile -libdir $(INCDIR)

REBUILD := $(shell find $(BASEDIR)/$(INCDIR) -name '*.inc')
SOURCES := $(shell find $(BASEDIR)/$(SRCDIR) -name '*.asm')
OUTPUTS := $(patsubst $(BASEDIR)/$(SRCDIR)/%.asm, ./$(BINDIR)/%.prg, $(SOURCES))
RUN_OUTPUTS := $(foreach target, $(OUTPUTS:./%=%), run-$(target))

########################################

.PHONY: all clean run
all: $(OUTPUTS)

clean:
	rm -rf $(BINDIR)/*
	rm -f $(FILNAME)

.SECONDEXPANSION:
$(OUTPUTS): $$(patsubst $$(BINDIR)/%.prg, $$(BASEDIR)/$$(SRCDIR)/%.asm, $$@) $(REBUILD)
	$(AS) $(patsubst $(BINDIR)%, $(BASEDIR)/$(SRCDIR)%, $(@:%.prg=%.asm)) $(ASSFLAGS) -o $@
ifeq ("$(CRUNCH)","true")
	exomizer sfx sys $@ -o $@
endif

$(RUN_OUTPUTS): $$(subst run-,,$$@)
	./run.sh $(subst run-,,$@)
