# Small podir project with translations

PRJ_TYPE:=podir
SLUG:=about-fedora
NAME:="About Fedora"
DESC:="Fedora document About Fedora"
VERS:=master f13 f11
VER_DIRS:=$(addsuffix /,$(VERS))
VER_TASKS:=$(addsuffix pot/,$(VER_DIRS))
URL:=git://git.fedorahosted.org/git/docs/$(SLUG).git

include ../common.mk
$(SLUG):
	git clone --bare $(URL) $(SLUG)

$(VER_DIRS): %/: $(SLUG)
	git clone -b $* $(SLUG) $*

