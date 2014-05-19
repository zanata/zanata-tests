sub_vers=$(shell $(1) -name '*.rpm')

SLUG=tar
NAME="GNU Tar"
DESC="GNU Tar provides the ability to create tar archives, as well as various other kinds of manipulation. For example, you can use Tar on previously created archives to extract files, to store additional files, or to update or list files which were already stored. "
VERS=1.26 1.27 1.27.1
URL=git://git.fedorahosted.org/git/docs/$(SLUG).git
PRJ_TYPE=podir

all: vers

vers: $(addsuffix /po,$(VERS))

%/po: tar-%.tar.bz2
	tar xjvf $<
	mv tar-$* $*

tar-%.tar.bz2:
	wget http://ftp.gnu.org/gnu/tar/$@

clean:
	rm -fr $(VERS)

