# Large xliff project with multiple documents and translations

PRJ_TYPE:=xliff
SLUG:=spacewalk
NAME:="Spacewalk"
DESC:="Spacewalk is an open source Linux systems management solution."
VERS:=master SPACEWALK-2.1 SPACEWALK-2.0
VER_TASKS:=$(addsuffix java/,$(VERS))
REPO_TYPE:=git
URL:=git://git.fedorahosted.org/git/$(SLUG).git

include ../common.mk

$(VER_TASKS): $(VER_DIRS)

