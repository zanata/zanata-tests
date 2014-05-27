# Medium gettext project with translation and plurals

PRJ_TYPE:=gettext
SLUG:=tar
NAME:="GNU Tar"
DESC:="GNU Tar provides the ability to create tar archives"
VERS:=1.26 1.27 1.27.1
TARBALLS:=$(foreach v, $(VERS), $(SLUG)-$(v).tar.bz2)
VER_DIRS:=$(addsuffix /,$(VERS))
VER_TASKS:=$(addsuffix po/$(SLUG).pot,$(VER_DIRS))
URL:=http://ftp.gnu.org/gnu/$(SLUG)/

include ../common.mk

$(VER_TASKS) : %/po/$(SLUG).pot: %/

$(VER_DIRS): %/ : $(SLUG)-%.tar.bz2
	tar xjvf $<
	mv $(SLUG)-$* $*

$(TARBALLS):
	wget $(URL)$@


