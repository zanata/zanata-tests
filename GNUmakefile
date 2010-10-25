FLIES_PYTHON_CLIENT=flies
FLIES_MAVEN_CLIENT=mvn

# Deployment Guide
DeploymentGuide_REPO_TYPE:=git
DeploymentGuide_NAME:="Fedora Deployment Guide"
DeploymentGuide_DESC:="The Fedora Deployment Guide"
DeploymentGuide_VERS:=f13 f14
DeploymentGuide_URL_f13:="git://git.fedorahosted.org/docs/deployment-guide.git"
DeploymentGuide_URL_f14:="git://git.fedorahosted.org/docs/deployment-guide.git"

# Documentation tools and utilities
DocUtils_REPO_TYPE:=git
DocUtils_NAME:="Documentation tools and utilities"
DocUtils_DESC:="Fedora Documentation tools and utilities"
DocUtils_VERS:=f13 f14
DocUtils_URL_f13:="git://git.fedorahosted.org/docs/fedora-doc-utils.git"
DocUtils_URL_f14:="git://git.fedorahosted.org/docs/fedora-doc-utils.git"

# Release Notes
ReleaseNotes_REPO_TYPE:=git
ReleaseNotes_NAME:="Fedora Release Notes"
ReleaseNotes_DESC:="Fedora Documentation - Release Notes"
ReleaseNotes_VERS:=f13 f14
ReleaseNotes_URL_f13:="git://git.fedorahosted.org/git/docs/release-notes.git"
ReleaseNotes_URL_f14:="git://git.fedorahosted.org/git/docs/release-notes.git"

# Security Guide
SecurityGuide_REPO_TYPE:=svn
SecurityGuide_NAME:="Fedora Security Guide"
SecurityGuide_DESC:="Fedora Documentation - Security Guide"
SecurityGuide_VERS:=trunk
SecurityGuide_URL_trunk:="http://svn.fedorahosted.org/svn/securityguide/community/trunk"

# Selinux Guide
SELinuxGuide_REPO_TYPE:=svn
SELinuxGuide_NAME:="Fedora SELinux Guide"
SELinuxGuide_DESC:="Fedora Documentation - SELinux Guide"
SELinuxGuide_VERS:=trunk f13
SELinuxGuide_URL_trunk:="http://svn.fedorahosted.org/svn/selinuxguide/community/trunk/SELinux_User_Guide"
SELinuxGuide_URL_f13:="http://svn.fedorahosted.org/svn/selinuxguide/community/branches/f13"

SAMPLE_PROJ_DIR:=samples
LANGS:=zh-CN,zh-TW
LANG_LIST:=zh-CN zh-TW

proj_vers=$(foreach ver,${${1}_VERS},${SAMPLE_PROJ_DIR}/${1}/${ver})
PYTHON_PROJECTS:=DeploymentGuide DocUtils
PYTHON_PROJECT_DIRS:=$(foreach proj,${PYTHON_PROJECTS},$(call proj_vers,${proj}))

MVN_PROJECTS:=ReleaseNotes SecurityGuide SELinuxGuide
MVN_PROJECT_DIRS:=$(foreach proj,${MVN_PROJECTS},$(call proj_vers,${proj}))

PUBLICAN_PROJECTS:= ${PYTHON_PROJECTS} ${MVN_PROJECTS}
PUBLICAN_PROJECT_DIRS:=${PYTHON_PROJECT_DIRS} ${MVN_PROJECT_DIRS}

PUBLICAN_CFG_STAMP:=publican.cfg.stamp

PYTHON_STAMP:=python.stamp
PROJ_PYTHON_STAMP:=.proj.${PYTHON_STAMP}
VERS_PYTHON_STAMP:=.vers.${PYTHON_STAMP}
POT_UPLOADED_PYTHON_STAMP:=.pot.${PYTHON_STAMP}
PO_UPLOADED_PYTHON_STAMP:=.po.${PYTHON_STAMP}

MVN_STAMP:=mvn.stamp
PROJ_MVN_STAMP:=.proj.${MVN_STAMP}
VERS_MVN_STAMP:=.vers.${MVN_STAMP}
POT_UPLOADED_MVN_STAMP:=.pot.${MVN_STAMP}
PO_UPLOADED_MVN_STAMP:=.po.${MVN_STAMP}

#include test.cfg

.SUFFIXES:
.PHONY: ${PUBLICAN_PROJECTS}

all:

force: ;

#####################################################################
# Python Client
#
$(addsuffix /${PO_UPLOADED_PYTHON_STAMP}, ${PYTHON_PROJECT_DIRS}) :\
    ${SAMPLE_PROJ_DIR}/%/${PO_UPLOADED_PYTHON_STAMP}:\
    ${SAMPLE_PROJ_DIR}/%/${POT_UPLOADED_PYTHON_STAMP}
	@echo "  [Python] Uploading po for proj $(*D) ver $(*F)"
	for l in ${LANG_LIST}; do \
	    for doc in $(@D)/$$l/*.po; do \
		echo "      Uploading po $$doc";\
		flies publican update --project-id $(*D) --version-id $(*F) $$doc; \
	    done; \
	done && touch $@

$(addsuffix /${POT_UPLOADED_PYTHON_STAMP}, ${PYTHON_PROJECT_DIRS}) :\
    ${SAMPLE_PROJ_DIR}/%/${POT_UPLOADED_PYTHON_STAMP}:\
    ${SAMPLE_PROJ_DIR}/%/${VERS_PYTHON_STAMP}
	@echo "  [Python] Uploading pot for proj $(*D) ver $(*F)"
	for doc in $(@D)/pot/*.pot; do \
	    echo "      Uploading pot $$doc";\
	    flies publican push --project-id $(*D) --version-id $(*F) $$doc; \
	done &&	touch $@

$(addsuffix /${VERS_PYTHON_STAMP}, ${PYTHON_PROJECT_DIRS}):\
    ${SAMPLE_PROJ_DIR}/%/${VERS_PYTHON_STAMP}:\
    ${SAMPLE_PROJ_DIR}/%/${PROJ_PYTHON_STAMP}
	@echo "  [Python] Creating versions: proj $(*D) ver $(*F)"
	flies iteration create --version-id $(*F) --project-id $(*D) --version-name "Ver $(*F)" --version-desc "Desc of Ver $(*D)" && touch $@

$(addsuffix /${PROJ_PYTHON_STAMP}, ${PYTHON_PROJECT_DIRS}):\
    ${SAMPLE_PROJ_DIR}/%/${PROJ_PYTHON_STAMP}:\
    ${SAMPLE_PROJ_DIR}/%/pot ${SAMPLE_PROJ_DIR}/%/update_po
	@echo "  [Python] Creating versions: proj $(*D)"
	flies project create --project-id $(*D) --project-name ${$(*D)_NAME} --project-desc ${$(*D)_DESC} && touch $@

${PYTHON_PROJECTS}: % : ${SAMPLE_PROJ_DIR}/%/${POT_UPLOADED_PYTHON_STAMP}

#####################################################################
# Mvn Client
#
$(addsuffix /${PO_UPLOADED_MVN_STAMP}, ${MVN_PROJECT_DIRS}) :\
    ${SAMPLE_PROJ_DIR}/%/${PO_UPLOADED_MVN_STAMP}:\
    ${SAMPLE_PROJ_DIR}/%/${POT_UPLOADED_MVN_STAMP}
	@echo "  [Mvn] Uploading po for proj $(*D) ver $(*F)"
	mvn flies:publican-push -Dusername=admin -Dkey=b6d7044e9ee3b2447c28fb7c50d86d98 -Dproject=$(*D) -DprojectVersion=$(*F) -DsubDir=$(@D) && touch $@

$(addsuffix /${POT_UPLOADED_MVN_STAMP}, ${MVN_PROJECT_DIRS}) :\
    ${SAMPLE_PROJ_DIR}/%/${POT_UPLOADED_MVN_STAMP}:\
    ${SAMPLE_PROJ_DIR}/%/${VERS_MVN_STAMP}
	@echo "  [Mvn] Uploading pot for proj $(*D) ver $(*F)"
	touch $@

$(addsuffix /${VERS_MVN_STAMP}, ${MVN_PROJECT_DIRS}):\
    ${SAMPLE_PROJ_DIR}/%/${VERS_MVN_STAMP}:\
    ${SAMPLE_PROJ_DIR}/%/${PROJ_MVN_STAMP}
	@echo "  [Mvn] Creating versions: proj $(*D) ver $(*F)"
	mvn flies:putversion -Dusername=admin -Dkey=b6d7044e9ee3b2447c28fb7c50d86d98 -DversionSlug=$(*F) -DversionProject=$(*D) -DversionName="Ver $(*F)" --DversionDesc="Desc of Ver $(*D)" && touch $@

$(addsuffix /${PROJ_MVN_STAMP}, ${MVN_PROJECT_DIRS}):\
    ${SAMPLE_PROJ_DIR}/%/${PROJ_MVN_STAMP}:\
    ${SAMPLE_PROJ_DIR}/%/flies.xml
	@echo "  [Mvn] Creating versions: proj $(*D)"
	mvn flies:putproject -Dusername=admin -Dkey=b6d7044e9ee3b2447c28fb7c50d86d98 -DprojectSlug=$(*D) -DprojectName=${$(*D)_NAME} -DprojectDesc=${$(*D)_DESC} && touch $@


$(addsuffix /flies.xml,${MVN_PROJECT_DIRS}):\
    ${SAMPLE_PROJ_DIR}/%/flies.xml:\
    ${SAMPLE_PROJ_DIR}/%/pot ${SAMPLE_PROJ_DIR}/%/update_po
	perl scripts/generate_flies_xml.pl samples SELinuxGuide trunk ${LANG_LIST}

ReleaseNotes: ${SAMPLE_PROJ_DIR}/ReleaseNotes/f13 ${SAMPLE_PROJ_DIR}/ReleaseNotes/f14

SecurityGuide: ${SAMPLE_PROJ_DIR}/SecurityGuide/trunk

SELinuxGuide: ${SAMPLE_PROJ_DIR}/SELinuxGuide/trunk/ ${SAMPLE_PROJ_DIR}/SELinuxGuide/f13

${MVN_PROJECTS}: % : $(addsuffix ${PO_UPLOADED_MVN_STAMP},$(call proj_vers,%))


#####################################################################
# Common config
#
${SAMPLE_PROJ_DIR}:
	mkdir -p ${SAMPLE_PROJ_DIR}

$(addprefix ${SAMPLE_PROJ_DIR}/,${PUBLICAN_PROJECTS}): ${SAMPLE_PROJ_DIR}/% : $(call proj_vers,%)

${PUBLICAN_PROJECT_DIRS}: ${SAMPLE_PROJ_DIR}/% : | ${SAMPLE_PROJ_DIR}
	@echo "   Get sources of $* $(*D):${$(*D)_NAME}"
	perl scripts/get_project.pl ${SAMPLE_PROJ_DIR} $(*D) ${$(*D)_REPO_TYPE} $(*F) ${$(*D)_URL_$(*F)}

$(addsuffix /publican.cfg,${PUBLICAN_PROJECT_DIRS}):\
    ${SAMPLE_PROJ_DIR}/%/publican.cfg: ${SAMPLE_PROJ_DIR}/%

$(addsuffix /${PUBLICAN_CFG_STAMP},${PUBLICAN_PROJECT_DIRS}):\
    ${SAMPLE_PROJ_DIR}/%/${PUBLICAN_CFG_STAMP}: ${SAMPLE_PROJ_DIR}/%/publican.cfg
	if grep -e 'brand:.*' $(@D)/publican.cfg; then \
	    echo "    Removing brand"; \
	    mv $(@D)/publican.cfg $(@D)/${PUBLICAN_CFG_STAMP}; \
	    sed -e 's/brand:.*//' $(@D)/${PUBLICAN_CFG_STAMP} > $(@D)/publican.cfg; \
	    else \
	    cp $(@D)/publican.cfg $(@D)/${PUBLICAN_CFG_STAMP}; \
	    fi

$(addsuffix /pot,${PUBLICAN_PROJECT_DIRS}):\
    ${SAMPLE_PROJ_DIR}/%/pot: ${SAMPLE_PROJ_DIR}/%/${PUBLICAN_CFG_STAMP}
	cd $(@D); publican update_pot; touch pot

$(addsuffix /update_po,${PUBLICAN_PROJECT_DIRS}):\
    ${SAMPLE_PROJ_DIR}/%/update_po: ${SAMPLE_PROJ_DIR}/%/pot
	cd $(@D); publican update_po --langs "$(LANGS)"


show:
	echo "PYTHON_PROJECT_DIRS=${PYTHON_PROJECT_DIRS}"
	echo "MVN_PROJECT_DIRS=${MVN_PROJECT_DIRS}"
	echo "PUBLICAN_PROJECT_DIRS=${PUBLICAN_PROJECT_DIRS}"

