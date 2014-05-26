# Small gettext project with translation and msgctxt

PRJ_TYPE:=gettext
SLUG:=ibus-chewing
NAME:="IBus Chewing"
DESC:="ibus-chewing is a Traditional Chinese input method"
VERS:=master
VER_DIRS:=$(addsuffix /,$(VERS))
VER_TASKS:=$(addsuffix po/$(SLUG).pot,$(VER_DIRS))
URL:=git://github.com/definite/$(SLUG).git

include ../common.mk

$(SLUG):
	git clone --bare $(URL) $(SLUG)

$(VER_DIRS): %/: $(SLUG)
	git clone -b $* $(SLUG) $*

$(VER_TASKS) : %/po/$(SLUG).pot: $(VER_DIRS)
	cd $*/po; xgettext --no-location --language=C --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 -s --package-name=ibus-chewing --package-version=master -o $(SLUG).pot ../src/*.c ../src/*.gob


