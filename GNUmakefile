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
PUBLICAN_PROJECTS=PROJ_RELEASE_NOTE PROJ_SECURITY_GUIDE


#include test.cfg

.PHONY: get_source

all:

samples:
	mkdir -p samples

get_source: samples
	for pProj in ${PUBLICAN_PROJECTS};do \
	    projSlug=$$(eval echo \$$$${pProj}_NAME);\
	    echo "Get source of project $${pProj} |${projSlug}| $${projSlug}: ";\
	done



