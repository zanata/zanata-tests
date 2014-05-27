# Large properties project with single document and translations.

PRJ_TYPE:=properties
SLUG:=zanata
NAME:="Zanata Server"
DESC:="This project currently contains strings for the Zanata website, but not for the web editor. "
VERS:=master
VER_DIRS:=$(addsuffix /,$(VERS))
VER_TASKS:=$(addsuffix .git/,$(VER_DIRS))
URL:=git://github.com/$(SLUG)/$(SLUG).git
INCLUDES:="**/src/main/resources/messages.properties"

include ../common.mk
$(SLUG):
	git clone --bare $(URL) $(SLUG)

$(VER_DIRS): %/: $(SLUG)
	git clone -b $* $(SLUG) $*

$(VER_TASKS): $(VER_DIRS)

