# Small gettext project with translation and msgctxt

PRJ_TYPE:=gettext
SLUG:=ibus-chewing
NAME:="IBus Chewing"
DESC:="ibus-chewing is a Traditional Chinese input method"
VERS:=master
VER_TASKS:=$(addsuffix /po/$(SLUG).pot,$(VERS))
REPO_TYPE:=git
URL:=git://github.com/definite/$(SLUG).git
SRC_DIR:=po
TRANS_DIR:=po

include ../common.mk

$(VER_TASKS) : %/po/$(SLUG).pot: $(VER_DIRS)
	cd $*/po; xgettext --no-location --language=C --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 -s --package-name=ibus-chewing --package-version=master -o $(SLUG).pot ../src/*.c ../src/*.gob

