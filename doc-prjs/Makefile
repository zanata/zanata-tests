SUBDIRS:=$(sort $(dir $(wildcard */Makefile)))
TARGETS:=download-all clean

SUBDIR_TARGETS:=$(foreach t,$(TARGETS),$(addsuffix $t,$(SUBDIRS)))

.PHONY: all $(TARGETS) $(SUBDIR_TARGETS)

all: download-all

$(TARGETS) : % : $(addsuffix %,$(SUBDIRS))
	@echo 'Target "$*" built'

$(SUBDIR_TARGETS):
	make -C $(@D) $(@F:.%=%)

