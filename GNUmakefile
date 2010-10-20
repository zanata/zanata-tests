FLIES_PYTHON_CLIENT=flies
FLIES_MAVEN_CLIENT=mvn
# Security Guide F13
PROJ_SECURITY_GUIDE=SecurityGuide
PROJ_SECURITY_GUIDE_REPO_TYPE=svn
PROJ_SECURITY_GUIDE_VERSION="13 14"
PROJ_SECURITY_GUIDE_URL="http://svn.fedorahosted.org/svn/securityguide/community/f%{ver}"
PROJ_SECURITY_GUIDE_NAME="Security Guide of Fedora"
PROJ_SECURITY_GUIDE_DESC="Security Guide of Fedora"

# Release Note
PROJ_RELEASE_NOTE=ReleaseNote
PROJ_RELEASE_NOTE_VERSION=13
PROJ_RELEASE_NOTE_REPO_TYPE=git
PROJ_RELEASE_NOTE_URL="git://git.fedorahosted.org/git/docs/release-notes.git"
PROJ_RELEASE_NOTE_NAME="Fedora Release Note"
PROJ_RELEASE_NOTE_DESC="Fedora Release Note"

#PUBLICAN_PROJECTS="PROJ_RELEASE_NOTE PROJ_SECURITY_GUIDE_F13 PROJ_ABOUT_FEDORA"
#PUBLICAN_PROJECTS=PROJ_RELEASE_NOTE PROJ_SECURITY_GUIDE

SAMPLE_PROJ_DIR=samples

LANGS:=zh-CN,zh-TW
PUBLICAN_PROJECTS:= SecurityGuide ReleaseNote
PUBLICAN_PROJECT_DIRS=$(addprefix $(SAMPLE_PROJ_DIR)/,$(PUBLICAN_PROJECTS))

#include test.cfg

.PHONY: get_projects


all:

force: ;


${SAMPLE_PROJ_DIR}:
	mkdir -p ${SAMPLE_PROJ_DIR}

${SAMPLE_PROJ_DIR}/ReleaseNote: ${SAMPLE_PROJ_DIR} force
	perl scripts/get_project.pl $(SAMPLE_PROJ_DIR) "ReleaseNote" \
	    "Fedora Release Note" "Fedora Release Note." \
	    "f13 f14" "git" \
	    "git://git.fedorahosted.org/git/docs/release-notes.git"


${SAMPLE_PROJ_DIR}/SecurityGuide: ${SAMPLE_PROJ_DIR} force
	perl scripts/get_project.pl $(SAMPLE_PROJ_DIR) "SecurityGuide" \
	    "Security Guide of Fedora" "Security Guide of Fedora." \
	    "trunk" "svn" \
	    "http://svn.fedorahosted.org/svn/securityguide/community/trunk"

%/publican.cfg.stamp: %/publican.cfg
	if grep -e 'brand:.*' $(@D)/publican.cfg; then \
	    echo "    Removing brand"; \
	    mv $(@D)/publican.cfg $(@D)/publican.cfg.stamp; \
	    sed -e 's/brand:.*//' $(@D)/publican.cfg.stamp > $(@D)/publican.cfg; \
	else \
	    cp $(@D)/publican.cfg $(@D)/publican.cfg.stamp; \
	fi

%/pot: % %/publican.cfg.stamp force
	cd $(@D); publican update_pot; touch pot

%/update_po: force
	cd $(@D); publican update_po --langs "$(LANGS)"

get_projects: ${PUBLICAN_PROJECT_DIRS}

update_pots: get_projects $(addsuffix /pot, ${PUBLICAN_PROJECT_DIRS})

update_pos: update_pots $(addsuffix /update_po, ${PUBLICAN_PROJECT_DIRS})

%/create_proj_python: force
	echo "   Creating project $$(basename $(@D))"
	flies project create \"$$(basename $(@D))\" --name \"${projName}\" --description \"${projDesc}\" >> ${logFile}
create_projs_python: $(addsuffix /update_po, ${PUBLICAN_PROJECT_DIRS})

