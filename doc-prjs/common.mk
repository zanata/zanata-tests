#######################################
# Definition
#

TOP_DIR=$(shell sed -e 's|/zanata-tests/.*|/zanata-tests|'<<<$(realpath .))


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
# Function


#######################################
# Rules

ifdef SKIP_TARGET
download-all:

else
download-all: $(VER_TASKS)
endif
clean:
	rm -fr $(VER_DIRS)

ifeq ($(REPO_TYPE),git)
$(PRJ_SLUG):
	git clone --bare $(URL) $(PRJ_SLUG)

$(VER_DIRS): %/: $(PRJ_SLUG)
	git clone -b $* $(PRJ_SLUG) $*

endif

ifeq ($(REPO_TYPE),tar)
$(VER_DIRS): %/ : $(PRJ_SLUG)-%.$(TARBALL_SUFFIX)
	tar $(TAR_OPTS) $<
	mv $(PRJ_SLUG)-$* $*

endif


ifeq ($(PRJ_TYPE),podir)
$(VER_TASKS): %/pot/: %/

endif

maintainer-main-workflow-mvn: $(addprefix maintainer-main-workflow-mvn,$(VERS))

$(addprefix maintainer-main-workflow-mvn,$(VERS)):maintainer-main-workflow-mvn%:
	cd $*; $(TOP_DIR)/client-tests/common/maintainer-main-workflow-test.sh  mvn $(PRJ_SLUG) $* $(PRJ_TYPE)




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

