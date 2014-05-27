# Small File project with translations

PRJ_TYPE:=file
PRJ_SLUG:=freemind
SLUG:=$(PRJ_SLUG)-doc
NAME:="freemind Documentation"
DESC:="Documentation of freemind"
VERS:=1.0.0
REPO_TYPE:=tar
TARBALL_SUFFIX:=tar.gz
TARBALLS:=$(foreach v, $(VERS), $(PRJ_SLUG)-src-$(v).$(TARBALL_SUFFIX))
URL:=http://downloads.sourceforge.net/project/$(PRJ_SLUG)/$(PRJ_SLUG)/

include ../common.mk

$(TARBALLS): $(PRJ_SLUG)-src-%.$(TARBALL_SUFFIX) :
	wget $(URL)$*/$@

