# Large properties project with multiple documents.

PRJ_TYPE:=properties
SLUG:=weld-core
NAME:="weld/core"
DESC:="Weld is the reference implementation of CDI: Contexts and Dependency Injection for the Java EE"
VERS:=2.0.0
VER_TASKS:=$(addsuffix /pom.xml,$(VERS))
URL:=https://github.com/weld/core.git
REPO_TYPE:=git
INCLUDES:=**/*_en.properties
PUSH_OPTIONS:=--includes=$(INCLUDES)
export PUSH_OPTIONS

include ../common.mk

$(VER_TASKS): %/pom.xml: $(VER_DIRS)
	cd $*; mvn --fail-never generate-resources -DskipTests=true


