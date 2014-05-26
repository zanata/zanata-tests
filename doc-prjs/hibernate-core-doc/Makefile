# Medium podir project with translations

PRJ_TYPE:=podir
SLUG:=hibernate-core-doc
NAME:="Documentation of Hibernate ORM core module"
DESC:="Hibernate ORM (Hibernate in short) is an object-relational mapping library for the Java language, providing a framework for mapping an object-oriented domain model to a traditional relational database."
BRANCHES:=3_5
BRANCH_DIRS:=$(addsuffix /,$(BRANCHES))
URL_PRE:=http://anonsvn.jboss.org/repos/hibernate/core/
URL_POST:=documentation/manual/src/main/docbook/
VER_DIRS:=trunk/ $(BRANCH_DIRS)
VER_TASKS:=$(addsuffix pot/,$(VER_DIRS))

include ../common.mk

trunk/: %/ : 
	svn co $(URL_PRE)$@$(URL_POST) $*

$(BRANCH_DIRS): %/ :
	svn co $(URL_PRE)branches/Branch_$@$(URL_POST) $*

