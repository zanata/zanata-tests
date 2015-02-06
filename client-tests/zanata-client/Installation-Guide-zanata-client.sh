#!/bin/bash
set -e 
set -o pipefail

function print_usage(){
    cat <<END
    $0 -  Test the Installation Guide for Java Client
SYNOPSIS
---------
    $0 [--asciidoc]

DESCRIPTION
------------
    Following the Installation Guide and do the smoke test.

EXIT STATUS
------------
    ${EXIT_CODE_OK} if all tests passed
    ${EXIT_CODE_INVALID_ARGUMENTS} invalid or missing arguments
    ${EXIT_CODE_FAILED} at least one of test not passed

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

### The command for package management system
declare PACKAGE_SYSTEM_COMMAND=yum

### The command to install a package in updates-testing
declare PACKAGE_INSTALL_UPDATE_REPO_COMMAND="${PACKAGE_SYSTEM_COMMAND} -y install --enablerepo=updates-testing"

### Zanata client package names
declare PACKAGE_NAME="zanata-client"

### Zanata client executable file with path
declare ZANATA_EXECUTABLE="/usr/bin/zanata-cli"
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
### = {PACKAGE_NAME} Installation Guide
### Document Version {revnumber}-{revdate}
### 
### This document shows the steps to install Zanata Java client (zanata-cli).
###
### == Steps
### . Install +{PACKAGE_NAME}+ though +{PACKAGE_SYSTEM_COMMAND}+
sudo ${PACKAGE_INSTALL_UPDATE_REPO_COMMAND} ${PACKAGE_NAME}
###
### == To Test
### . Command without arguments should return available commands
${ZANATA_EXECUTABLE}
###
#### End Doc

