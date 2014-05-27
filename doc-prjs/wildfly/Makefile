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

include ../common.mk

$(VER_TASKS): %/pom.xml: $(VER_DIRS)
	cd $*; mvn install -DskipTests

