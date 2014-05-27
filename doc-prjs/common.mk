#######################################
# Definition

VER_DIRS?=$(addsuffix /,$(VERS))

ifeq ($(PRJ_TYPE),podir)
VER_TASKS?=$(addsuffix /pot/,$(VERS))
else
VER_TASKS?=$(VER_DIRS)
endif

ifeq ($(REPO_TYPE),tar)
ifeq ($(TARBALL_SUFFIX),tar.gz)
    TAR_OPTS:=zxvfm
endif
ifeq ($(TARBALL_SUFFIX),tar.bz2)
    TAR_OPTS:=jxvfm
endif
endif

PRJ_SLUG?=$(SLUG)

#######################################
# Rules
download_all: $(VER_TASKS)

clean:
	rm -fr $(VER_DIRS)

ifeq ($(REPO_TYPE),git)
$(PRJ_SLUG):
	git clone --bare $(URL) $(PRJ_SLUG)

$(VER_DIRS): %/: $(PRJ_SLUG)
	git clone -b $* $(PRJ_SLUG) $*

endif

ifeq ($(REPO_TYPE),tar)
$(VER_DIRS): %/ : $(TARBALLS)
	tar $(TAR_OPTS) $<
	mv $(PRJ_SLUG)-$* $*

endif


ifeq ($(PRJ_TYPE),podir)
$(VER_TASKS): %/pot/: %/

endif

# publican no longer required, as the revnumber in older projects 
# are no longer valid.
# 	
# if [ -x /usr/bin/publican ]; then
#    if [ -e $*/publican.cfg ];then 
#       sed -e "s/brand:.*//" $*/publican.cfg > $*/publican.cfg.stripped
#       cd $*; publican update_pot --config publican.cfg.stripped
#       publican update_po --config publican.cfg.stripped  --langs=`find . -maxdepth 1 -mindepth 1 -type d ! -name "pot" ! -name "\.git" | xargs | sed -e 's/ /,/g'`
#    fi
# fi

