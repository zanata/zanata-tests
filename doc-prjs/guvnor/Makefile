# Medium utf8properties project with translations
PRJ_TYPE:=utf8properties
SLUG:=guvnor
NAME:="Guvnor"
DESC:="Guvnor is the web application and repository to govern Drools and jBPM assets."
VERS:=master 6.0.x 5.6.x
VER_DIRS:=$(addsuffix /,$(VERS))
VER_TASKS:=$(addsuffix .git/,$(VER_DIRS))
URL:=git://github.com/droolsjbpm/$(SLUG).git
INCLUDES:="**/src/main/**/*Constants.properties"

include ../common.mk
$(SLUG):
	git clone --bare $(URL) $(SLUG)

$(VER_TASKS): %/.git/: $(SLUG)
	git clone -b $* $(SLUG) $*


