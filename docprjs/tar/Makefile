# Medium project with translation and plurals
SLUG=tar
NAME="GNU Tar"
DESC="GNU Tar provides the ability to create tar archives"
VERS=1.26 1.27 1.27.1
URL=http://ftp.gnu.org/gnu/tar/
PRJ_TYPE=podir

all: download_vers

download_vers: $(addsuffix /po,$(VERS))

%/po: tar-%.tar.bz2
	tar xjvf $<
	mv tar-$* $*

tar-%.tar.bz2:
	wget $(URL)$@

clean:
	rm -fr $(VERS)

