# Medium project with translation and plurals
SLUG=tar
NAME="GNU Tar"
DESC="GNU Tar provides the ability to create tar archives"
VERS=1.26 1.27 1.27.1
TARBALLS:=$(foreach v, $(VERS), tar-$(v).tar.bz2)
URL=http://ftp.gnu.org/gnu/tar/
PRJ_TYPE=podir

download_all: $(addsuffix /,$(VERS))

%/: tar-%.tar.bz2
	tar xjvf $<
	mv tar-$* $*

$(TARBALLS):
	wget $(URL)$@

clean:
	rm -fr $(VERS)

