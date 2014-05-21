# Medium project with translations
SLUG=guvnor
NAME="Guvnor"
DESC="Guvnor is the web application and repository to govern Drools and jBPM assets."
VERS=master 6.0.x 5.6.x
URL=git://github.com/droolsjbpm/guvnor.git
INCLUDES="**/src/main/**/*Constants.properties"
PRJ_TYPE=utf8properties

all: download_vers

download_vers: $(addsuffix /.git,$(VERS))

$(SLUG):
	git clone --bare $(URL) $(SLUG)

%/.git: $(SLUG)
	git clone -b $* $(SLUG) $*


clean:
	rm -fr ${VERS}

