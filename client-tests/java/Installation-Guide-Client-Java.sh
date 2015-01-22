#!/bin/bash
set -e 
set -o pipefail

function print_usage(){
    cat <<END
    $0 -  Test the Installation Guide for Java Client
SYNOPSIS
    $0

DESCRIPTION
    Following the Installation Guide and do the smoke test.

ENVIRONMENT
    PACKAGE_INSTALL_COMMAND 
        The command to install a package
	Default: "yum -y install"

    ZANATA_BACKEND
	The zanata client executable.
	Default: "/usr/bin/zanata-cli"

EXIT STATUS
    0 if all tests passed
    ${EXIT_CODE_INVALID_ARGUMENTS} invalid or missing arguments
    ${EXIT_CODE_FAILED} at least one of test not passed
    ${EXIT_CODE_DEPENDENCY_MISSING} if dependency is missing


END
}

: ${TEST_SUITE_NAME:=$(basename "$0" .sh)}
export TEST_SUITE_NAME

export SCRIPT_DIR="$(dirname "$(readlink -f $0)")"
TOP_DIR=${SCRIPT_DIR%%/client-tests/*}
COMMON_DIR="${TOP_DIR}/client-tests/common"
source ${COMMON_DIR}/functions.sh


#=== Variables =============================

set_var author 'Ding-Yi Chen'
set_var revdate 2015-01-22
set_var revnumber 2
set_var numbered
set_var toc2
set_var GIT_BRANCH 'master'
set_var PACKAGE_INSTALL_COMMAND 'yum -y install'
set_var PACKAGE_NAME 'zanata-client'
set_var ZANATA_BACKEND '/usr/bin/zanata-cli'

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
	    stderr_echo "Invalid argument $1"
	    exit ${EXIT_CODE_INVALID_ARGUMENTS}
	    ;;
    esac
    shift
done

#### Start Doc
### = Zanata Java Client Installation Guide
### Document Version {revnumber}-{revdate}
### 
### This document shows the steps to install Zanata Java client (zanata-cli).
###
### == Steps
### . Install +{PACKAGE_NAME}+ though +{PACKAGE_INSTALL_COMMAND}+
sudo ${PACKAGE_INSTALL_COMMAND} ${PACKAGE_NAME}
###
### == To Test
### . Command without arguments should return available commands
${ZANATA_BACKEND}
###
#### End Doc

${COMMON_DIR}/smoke-test.sh ${ZANATA_BACKEND}
