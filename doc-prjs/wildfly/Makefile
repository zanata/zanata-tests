# Large properties project with multiple documents.

PRJ_TYPE:=properties
SLUG:=wildfly
NAME:="Wildfly (JBoss)"
DESC:="WildFly, formerly known as JBoss AS, or simply JBoss, is an application server authored by JBoss"
VERS:=master 8.x 7.1
VER_TASKS:=$(addsuffix /pom.xml,$(VERS))
URL:=git://github.com/$(SLUG)/$(SLUG).git
REPO_TYPE:=git
INCLUDES:="**/*.i18n.properties"
MODULES:=1
MAVEN_VERSION:=$(shell mvn --version | grep "Apache Maven" | sed -e 's/Apache Maven //' | sed -e 's/ .*//')
MAVEN_REQUIRED_VERSION:=3.1
versionNewer=$(shell echo -e  "$(1)\n$(2)" | sort -Vr | head -n 1)
MAVEN_VERSION_NEWEST:=$(call versionNewer,${MAVEN_VERSION},${MAVEN_REQUIRED_VERSION})

show_maven_option:
	echo "$(MAVEN_VERSION)"
	echo "$(MAVEN_VERSION_NEWEST)"

ifeq (${MAVEN_VERSION},${MAVEN_VERSION_NEWEST})
include ../common.mk

$(VER_TASKS): %/pom.xml: $(VER_DIRS)
	cd $*; mvn install -DskipTests

else
    $(info "maven required version "${MAVEN_REQUIRED_VERSION}" is newer that our ${MAVEN_VERSION}, skip")
SKIP_TARGET:=1
include ../common.mk
endif
