# Large gettext project with translation and plurals and multiple files.

PRJ_TYPE:=gettext
SLUG:=gcc
NAME:="GNU Complier Collection"
DESC:="The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Java, Ada, and Go, as well as libraries for these languages (libstdc++, libgcj,...). "
VERS:=4.9.0 4.8.3
TARBALL_SUFFIX:=tar.gz
TARBALLS:=$(foreach v, $(VERS), $(SLUG)-$(v).$(TARBALL_SUFFIX))
REPO_TYPE:=tar
URL:=ftp://mirror.aarnet.edu.au/pub/gnu/$(SLUG)/
include ../common.mk

$(TARBALLS): $(SLUG)-%.${TARBALL_SUFFIX}:
	wget $(URL)$(SLUG)-$*/$@


