#!/bin/bash
set -e 
set -o pipefail

function print_usage(){
    cat <<END
    $0 -  Test the Build Guide for Java Client
SYNOPSIS
    $0


DESCRIPTION
    Following the Build Guide and do the smoke test.

ENVIRONMENT
------------
END
    print_variables usage $0
}

#### Start Var
declare author="Ding-Yi Chen"
declare revdate=2015-02-06
declare revnumber=2
declare numbered
declare toc2

### Project name
declare PROJECT_NAME="zanata-client"

### Clone url
declare GIT_URL="https://github.com/zanata/${PROJECT_NAME}.git"

### zanata-client branch to be test.
declare GIT_BRANCH=master

### The command for package management system
declare PACKAGE_SYSTEM_COMMAND=yum

### The command to install a package
declare PACKAGE_INSTALL_COMMAND="${PACKAGE_SYSTEM_COMMAND} -y install"

### The command to check list matched package in repo
declare PACKAGE_LIST_COMMAND="${PACKAGE_SYSETEM_COMMAND} list"

### The command to check whether the package is installed
declare PACKAGE_EXIST_COMMAND="rpm -q"

### The parent directory for cloned zanata-client repo.
declare ZANATA_CLIENT_CHECKOUT_PARENT_DIR="/tmp"

### The directory for cloned zanata-client repo.
declare ZANATA_CLIENT_CHECKOUT_DIR="${ZANATA_CLIENT_CHECKOUT_PARENT_DIR}/zanata-client"

### Zanata client executable file with path
declare ZANATA_EXECUTABLE="${ZANATA_CLIENT_CHECKOUT_PARENT_DIR}/${PROJECT_NAME}/zanata-cli/etc/scripts/zanata-cli"
#### End Var

#===== Start Guide Functions =====

## Exit status
export EXIT_CODE_OK=0
export EXIT_CODE_INVALID_ARGUMENTS=3
export EXIT_CODE_DEPENDENCY_MISSING=4
export EXIT_CODE_ERROR=5
export EXIT_CODE_FAILED=6
export EXIT_CODE_SKIPPED=7
export EXIT_CODE_FATAL=125


function extract_variable(){
    local file=$1
    local nameFilter=$2
    awk -v nameFilter="$nameFilter" \
	'BEGIN {FPAT = "(\"[^\"]+\")|(\\(.+\\))|([^ =]+)"; start=0; descr=""} \
	/^#### End Var/ { start=0} \
	(start==1 && /^[^#]/ && $2 ~ nameFilter) { sub(/^\"/, "", $3); sub(/\"$/, "", $3); print $2 "\t" $3 "\t" descr ; descr="";} \
	(start==1 && /^###/) { gsub("^###[ ]?","", $0) ; descr=$0} \
	/^#### Start Var/ { start=1; } ' $file
}

function print_variables(){
    local format=$1
    local file=$2
    case $format in
	asciidoc )
	    extract_variable $file | awk -F '\\t' 'BEGIN { done=0 } \
		$2 ~ /^\$\{.*:[=-]/ { ret=gensub(/^\$\{.*:[=-](.+)\}/, "\\1", "g", $2) ; print ":" $1 ": " ret; done=1 }\
		done==0  {print ":" $1 ": " $2 ; done=1 }\
		done==1  {done=0}'
	    ;;
	bash )
	    extract_variable $file "^[A-Z]" | awk -F '\\t' \
		'$2 ~ /[^\)]$/ {print "export " $1 "=\""$2"\"" ;} \
		$2 ~ /\)$/ {print "export " $1 "="$2 ;} '
	    ;;
	usage )
	    extract_variable $file "^[A-Z]" | awk -F '\\t' '{print $1 "::"; \
		if ( $3 != "" ) {print "    " $3  }; \
		print "    Default: " $2 "\n"}'
	    ;;	    
	* )
	    ;;
    esac
}

function to_asciidoc(){  
    print_variables asciidoc $0
    # Extract variable

    awk 'BEGIN {start=0;sh_start=0; in_list=0} \
	/^#### End Doc/ { start=0} \
	(start==1 && /^[^#]/ ) { if (sh_start==0) {sh_start=1; if (in_list ==1 ) {print "+"}; print "[source,sh]"; print "----"} print $0;} \
	(start==1 && /^### \./ ) { in_list=1 } \
	(start==1 && /^###/ ) { if (sh_start==1) {sh_start=0; print "----"} gsub("^###[ ]?","", $0) ; print $0;} \
	/^#### Start Doc/ { start=1; } ' $0
    echo "== Default Environment Variables"
    echo "[source,sh]"
    echo "----"
    # Extract variable
    print_variables bash $0
    echo "----"
}

while [ -n "$1" ];do
    case $1 in
	--asciidoc )
	    to_asciidoc
	    exit 0
	    ;;
	--help | -h )
	    print_usage
	    exit 0
	    ;;
	* )
	    echo "Invalid argument $1" > /dev/stderr
	    exit ${EXIT_CODE_INVALID_ARGUMENTS}
	    ;;
    esac
    shift
done
#===== End Guide Functions =====

#### Start Doc
### = {PROJECT_NAME} Build Guide
### Document Version {revnumber}-{revdate}
### 
### This document shows the steps to build Zanata Java client (zanata-cli).
### 
### == Prerequisites
### . Make sure maven is installed
if ! rpm -q --whatprovides maven2 ;then
    # Find suitable package
    PACKAGE_NAME=
    if ${PACKAGE_LIST_COMMAND} maven; then
	PACKAGE_NAME=maven
    else
	# EL does not have maven
	PACKAGE_NAME=apache-maven
	if ! ${PACKAGE_LIST_COMMAND} ${PACKAGE_NAME}; then
	    # Install repo file
	    sudo wget -O /etc/yum.repos.d/epel-apache-maven.repo https://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo
	fi
    fi
    sudo ${PACKAGE_INSTALL_COMMAND} ${PACKAGE_NAME}
fi
###
### == Steps
### . Change dir to {ZANATA_CLIENT_CHECKOUT_PARENT_DIR}
cd ${ZANATA_CLIENT_CHECKOUT_PARENT_DIR}
###
###  . Clone the zanata-client git repo; change dir to {ZANATA_CLIENT_CHECKOUT_DIR}; 
if [ ! -d zanata-client ];then
    git clone https://github.com/zanata/zanata-client.git
fi
cd ${ZANATA_CLIENT_CHECKOUT_DIR}
###
### . (Optional) Checkout the branch {GIT_BRANCH}; and pull the latest change
git checkout master
git pull
git checkout ${GIT_BRANCH}
git pull --rebase
###
### . mvn install
mvn clean install
###
### == To Test
### . Command without arguments should return available commands
${ZANATA_EXECUTABLE}
###
#### End Doc

