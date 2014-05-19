SLUG=about-fedora
NAME="About Fedora"
DESC="Fedora document About Fedora"
VERS=master f13 f11
URL=git://git.fedorahosted.org/git/docs/$(SLUG).git
PRJ_TYPE=podir

all: download_vers

download_vers: $(addsuffix /publican.cfg.stripped,$(VERS))

$(SLUG):
	git clone --bare $(URL) $(SLUG)

%/.git: $(SLUG)
	git clone -b $* $(SLUG) $*

%/publican.cfg.stripped: %/.git
	sed -e "s/brand:.*//" $(<D)/publican.cfg > $@
	# cd $*; publican update_pot --config $(@F)
	# cd $*; publican update_po --config $(@F) --langs=`find . -maxdepth 1 -mindepth 1 -type d ! -name "pot" ! -name "\.git" | xargs | sed -e 's/ /,/g'` 

clean:
	rm -fr ${VERS}
