#######################################
# Definition

VER_DIRS?=$(addsuffix /,$(VERS))

ifeq ($(PRJ_TYPE),podir)
VER_TASKS?=$(addsuffix /pot/,$(VERS))
endif

#######################################
# Rules
download_all: $(VER_TASKS)

clean:
	rm -fr $(VER_DIRS)

ifeq ($(REPO_TYPE),git)
$(SLUG):
	git clone --bare $(URL) $(SLUG)

$(VER_DIRS): %/: $(SLUG)
	git clone -b $* $(SLUG) $*

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

