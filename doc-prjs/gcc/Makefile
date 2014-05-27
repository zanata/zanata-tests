# Large gettext project with translation and plurals and multiple files.

PRJ_TYPE:=gettext
SLUG:=gcc
NAME:="GNU Complier Collection"
DESC:="The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Java, Ada, and Go, as well as libraries for these languages (libstdc++, libgcj,...). "
VERS:=4.9.0 4.8.3
TARBALLS:=$(foreach v, $(VERS), $(SLUG)-$(v).tar.gz)
VER_DIRS:=$(addsuffix /,$(VERS))
VER_TASKS:=$(addsuffix gcc/,$(VER_DIRS))
URL:=ftp://mirror.aarnet.edu.au/pub/gnu/$(SLUG)/
include ../common.mk

$(VER_TASKS) : $(VER_DIRS)

$(VER_DIRS): %/ : $(SLUG)-%.tar.gz
	tar xzvf $<
	mv $(SLUG)-$* $*

$(TARBALLS): $(SLUG)-%.tar.gz:
	wget $(URL)$(SLUG)-$*/$@


