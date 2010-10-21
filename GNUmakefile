FLIES_PYTHON_CLIENT=flies
FLIES_MAVEN_CLIENT=mvn
# Security Guide
SecurityGuide:=SecurityGuide
SecurityGuide_REPO_TYPE:=svn
SecurityGuide_VERSION:=trunk
SecurityGuide_URL:="http://svn.fedorahosted.org/svn/securityguide/community/trunk"
SecurityGuide_NAME:="Security Guide of Fedora"
SecurityGuide_DESC:="Security Guide of Fedora"

# Release Note
ReleaseNote:=ReleaseNote
ReleaseNote_VERSION:=f13 f14
ReleaseNote_REPO_TYPE:=git
ReleaseNote_URL:="git://git.fedorahosted.org/git/docs/release-notes.git"
ReleaseNote_NAME:="Fedora Release Note"
ReleaseNote_DESC:="Fedora Release Note"

#PUBLICAN_PROJECTS="ReleaseNote SecurityGuide_F13 PROJ_ABOUT_FEDORA"
#PUBLICAN_PROJECTS=ReleaseNote SecurityGuide
.SUFFIXES:

SAMPLE_PROJ_DIR:=samples

LANGS:=zh-CN,zh-TW
LANG_LIST:=zh-CN zh-TW
PUBLICAN_PROJECTS:= SecurityGuide ReleaseNote
PUBLICAN_PROJECT_DIRS:=$(addprefix $(SAMPLE_PROJ_DIR)/,$(PUBLICAN_PROJECTS))


PYTHON_STAMP:=python.stamp
VERS_PYTHON_STAMP:=.vers.${PYTHON_STAMP}
PROJ_PYTHON_STAMP:=.proj.${PYTHON_STAMP}
POT_UPLOADED_PYTHON_STAMP:=.pot.${PYTHON_STAMP}
PO_UPLOADED_PYTHON_STAMP:=.po.${PYTHON_STAMP}

#include test.cfg

.PHONY: get_projects create_vers_python create_projs_python


all:

force: ;


${SAMPLE_PROJ_DIR}:
	mkdir -p ${SAMPLE_PROJ_DIR}

$(addsuffix /${PO_UPLOADED_PYTHON_STAMP}, ${PUBLICAN_PROJECT_DIRS}) : ${SAMPLE_PROJ_DIR}/%/${PO_UPLOADED_PYTHON_STAMP}: ${SAMPLE_PROJ_DIR}/%/${POT_UPLOADED_PYTHON_STAMP}
	@echo "  [Python] Uploading po for $*"
	for v in ${$*_VERSION};do \
		echo "    Uploading for Ver $$v";\
		perl scripts/switch_version.pl ${SAMPLE_PROJ_DIR} $* ${$*_REPO_TYPE} $$v; \
		for l in ${LANG_LIST}; do \
			for doc in $(@D)/$$l/*.po; do \
				echo "      Uploading po $$doc";\
				flies publican update --project $* --iteration $$v  $$doc; \
			done; \
		done; \
	done
	touch $@

$(addsuffix /${POT_UPLOADED_PYTHON_STAMP}, ${PUBLICAN_PROJECT_DIRS}) : ${SAMPLE_PROJ_DIR}/%/${POT_UPLOADED_PYTHON_STAMP}: ${SAMPLE_PROJ_DIR}/%/${VERS_PYTHON_STAMP}
	@echo "  [Python] Uploading pot for $*"
	for v in ${$*_VERSION};do \
		echo "    Uploading for Ver $$v";\
		perl scripts/switch_version.pl ${SAMPLE_PROJ_DIR} $* ${$*_REPO_TYPE} $$v; \
		for doc in $(@D)/pot/*.pot; do \
			echo "      Uploading pot $$doc";\
			flies publican push $$doc --project $* --iteration $$v $$doc; \
		done; \
	done
	touch $@

$(addsuffix /${VERS_PYTHON_STAMP}, ${PUBLICAN_PROJECT_DIRS}): ${SAMPLE_PROJ_DIR}/%/${VERS_PYTHON_STAMP}: ${SAMPLE_PROJ_DIR}/%/${PROJ_PYTHON_STAMP}
	@echo "  [Python] Creating versions of $*"
	for v in ${$*_VERSION};do \
		echo "    Create Ver $$v";\
		flies iteration create $$v --project $* --name "Ver $$v" --description "Desc of Ver $$v";\
	done
	touch $@

$(addsuffix /${PROJ_PYTHON_STAMP}, ${PUBLICAN_PROJECT_DIRS}): ${SAMPLE_PROJ_DIR}/%/${PROJ_PYTHON_STAMP}:
	@echo "  [Python] Creating project $*:${$*_NAME}"
	flies project create  $* --name ${$*_NAME} --description ${$*_DESC}
	touch $@

${PUBLICAN_PROJECT_DIRS}: ${SAMPLE_PROJ_DIR}/% : | ${SAMPLE_PROJ_DIR}
	@echo "   Get sources of $(@F):${$(@F)_NAME}"
	perl scripts/get_project.pl ${SAMPLE_PROJ_DIR} $(@F) ${$(@F)_REPO_TYPE} {$(@F)_URL}

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

create_projs_python: $(addsuffix /${PROJ_PYTHON_STAMP}, ${PUBLICAN_PROJECT_DIRS})

create_vers_python: $(addsuffix /${VERS_PYTHON_STAMP}, ${PUBLICAN_PROJECT_DIRS})

upload_pots_python: $(addsuffix /${POT_UPLOADED_PYTHON_STAMP}, ${PUBLICAN_PROJECT_DIRS})

upload_pos_python: $(addsuffix /${PO_UPLOADED_PYTHON_STAMP}, ${PUBLICAN_PROJECT_DIRS})

