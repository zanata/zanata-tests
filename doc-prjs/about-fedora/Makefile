# Small podir project with translations

SLUG=about-fedora
NAME="About Fedora"
DESC="Fedora document About Fedora"
VERS=master f13 f11
VER_DIRS=$(addsuffix /.git,$(VERS))
URL=git://git.fedorahosted.org/git/docs/$(SLUG).git
PRJ_TYPE=podir

download_all: $(VER_DIRS)

$(SLUG):
	git clone --bare $(URL) $(SLUG)

$(VER_DIRS): %/.git: $(SLUG)
	git clone -b $* $(SLUG) $*
	if [ -x /usr/bin/publican ]; then \
	    if [ -e $*/publican.cfg ];then \
		sed -e "s/brand:.*//" $*/publican.cfg > $*/publican.cfg.stripped ;\
		cd $*; publican update_pot --config $*/publican.cfg.stripped; \
		publican update_po --config $*/publican.cfg.stripped  --langs=`find . -maxdepth 1 -mindepth 1 -type d ! -name "pot" ! -name "\.git" | xargs | sed -e 's/ /,/g'` ;\
	    fi;\
	fi

clean:
	rm -fr ${VERS}

