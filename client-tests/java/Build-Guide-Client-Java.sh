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
    GIT_BRANCH
	zanata-client branch to be test.
	Default: "master"

    PACKAGE_INSTALL_COMMAND 
        The command to install a package
	Default: "yum -y install"

    PACKAGE_LIST_COMMAND
	The command used to check the existance of a package
        Default: "yum list"

    ZANATA_CLIENT_CHECKOUT_PARENT_DIR
        The parent directory for cloned zanata-client repo.
	Default: "/tmp"

    ZANATA_CLIENT_CHECKOUT_DIR '/tmp'
	The directory for cloned zanata-client repo.
	Default: "${ZANATA_CLIENT_CHECKOUT_PARENT_DIR}/zanata-client"

    ZANATA_BACKEND
	The zanata client executable.
	Default: "${ZANATA_CLIENT_CHECKOUT_DIR}/zanata-cli/etc/scripts/zanata-cli"

EXIT STATUS
    0 if all tests passed
    ${EXIT_CODE_INVALID_ARGUMENTS} invalid or missing arguments
    ${EXIT_CODE_FAILED} at least one of test not passed


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
set_var revdate 2015-01-19
set_var revnumber 2
set_var numbered
set_var toc2
set_var GIT_BRANCH 'master'
set_var PACKAGE_INSTALL_COMMAND 'yum -y install'
set_var PACKAGE_LIST_COMMAND 'yum list'
set_var ZANATA_CLIENT_CHECKOUT_PARENT_DIR '/tmp'
set_var ZANATA_CLIENT_CHECKOUT_DIR '${ZANATA_CLIENT_CHECKOUT_PARENT_DIR}/zanata-client'
set_var ZANATA_BACKEND '${ZANATA_CLIENT_CHECKOUT_DIR}/zanata-cli/etc/scripts/zanata-cli'


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
### = Zanata Java Client Build Guide
### Document Version {revnumber}-{revdate}
### 
### This document shows the steps to build Zanata Java client (zanata-cli).
### 
### == Prerequisites
### . maven should be installed 
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
${ZANATA_BACKEND}
###
#### End Doc

${COMMON_DIR}/smoke-test.sh ${ZANATA_BACKEND}

