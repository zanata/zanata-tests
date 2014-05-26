# Medium project with translations
SLUG=guvnor
NAME="Guvnor"
DESC="Guvnor is the web application and repository to govern Drools and jBPM assets."
VERS=master 6.0.x 5.6.x
VER_DIRS=$(addsuffix /.git,$(VERS))
URL=git://github.com/droolsjbpm/guvnor.git
INCLUDES="**/src/main/**/*Constants.properties"
PRJ_TYPE=utf8properties

download_all: $(VER_DIRS)

$(SLUG):
	git clone --bare $(URL) $(SLUG)

$(VER_DIRS): %/.git: $(SLUG)
	git clone -b $* $(SLUG) $*

clean:
	rm -fr ${VERS}

