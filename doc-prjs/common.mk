download_all: $(VER_TASKS)

clean:
	rm -fr $(VER_DIRS)

ifeq ($(PRJ_TYPE), podir)
$(VER_TASKS): %/pot/: %/
	if [ -x /usr/bin/publican ]; then \
	    if [ -e $*/publican.cfg ];then \
	    sed -e "s/brand:.*//" $*/publican.cfg > $*/publican.cfg.stripped ;\
	    cd $*; publican update_pot --config $*/publican.cfg.stripped; \
	    publican update_po --config $*/publican.cfg.stripped  --langs=`find . -maxdepth 1 -mindepth 1 -type d ! -name "pot" ! -name "\.git" | xargs | sed -e 's/ /,/g'` ;\
	    fi;\
	fi
endif

