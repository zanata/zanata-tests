# Medium gettext project with translation and plurals

PRJ_TYPE:=gettext
SLUG:=tar
NAME:="GNU Tar"
DESC:="GNU Tar provides the ability to create tar archives"
VERS:=1.26 1.27 1.27.1
REPO_TYPE:=tar
TARBALL_SUFFIX:=tar.bz2
TARBALLS:=$(foreach v, $(VERS), $(SLUG)-$(v).$(TARBALL_SUFFIX))
URL:=http://ftp.gnu.org/gnu/$(SLUG)/

include ../common.mk

$(TARBALLS): $(SLUG)-%.$(TARBALL_SUFFIX) :
	wget $(URL)$@


