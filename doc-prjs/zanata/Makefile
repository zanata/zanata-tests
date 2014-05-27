# Large properties project with single document and translations.

PRJ_TYPE:=properties
SLUG:=zanata
NAME:="Zanata Server"
DESC:="This project currently contains strings for the Zanata website, but not for the web editor. "
VERS:=master
VER_TASKS:=$(addsuffix /.git/,$(VERS))
REPO_TYPE:=git
URL:=git://github.com/$(SLUG)/$(SLUG).git
INCLUDES:="**/src/main/resources/messages.properties"

include ../common.mk

$(VER_TASKS): $(VER_DIRS)

