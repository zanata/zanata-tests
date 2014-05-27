# Small File and properties project with translations

PRJ_TYPE:=file
SLUG:=freemind
NAME:="freemind Documentation"
DESC:="Documentation of freemind"
VERS:=software doc
software_INCLUDES:="**/Resources_en.properties"
software_PRJ_TYPE:=properties

PRJ_VERS:=1.0.0
# It needs to handle the download itself
REPO_TYPE:=custom

TARBALL_SUFFIX:=tar.gz
TARBALLS:=$(foreach v, $(PRJ_VERS), $(SLUG)-src-$(v).$(TARBALL_SUFFIX))
URL:=http://downloads.sourceforge.net/project/$(SLUG)/$(SLUG)/

include ../common.mk

$(VER_DIRS): freemind/
	cp -fR freemind/doc doc
	cp -fR freemind software

freemind/: $(TARBALLS)
	tar zxvfm $<

$(TARBALLS): $(SLUG)-src-%.$(TARBALL_SUFFIX) :
	wget $(URL)$*/$@

