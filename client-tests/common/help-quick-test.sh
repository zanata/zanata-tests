#!/bin/bash
function print_usage(){
    cat <<END
    $0 - Client help-quick test
SYNOPSIS
    $0  <command>

ARGUMENTS
    command: Client command with path.

DESCRIPTION
    The purpose of help-quick test is make sure new client users
    can access sufficient command line help.

    Scope of help quick test:
    1. Command exists
    2. Command outputs 0 without argument.
    3. Command outputs available commands, especially:
       a. help
       b. push
       c. pull
    4. -v outputs
       a. API version
    5. help push
    6. help pull

   If command does not exist, the rest of test will be skipped.

   If test case succeed, it outputs "OK: <test case name>"
   If test case failed, it outputs "FAILED: <test case name>"
   If test case is skipped, it outputs "SKIPPED" <test case name>"
   
   Finally it outputs the number of total, failed and skipped 
   test cases.

EXIT STATUS
   0 if all tests passed
   ${EXIT_CODE_INVALID_ARGUMENTS} invalid or missing arguments
   ${EXIT_CODE_FAILED} at least one of test not passed


END
}


: ${CLASSNAME:=$(basename $0 .sh | sed -e 's/-test$//')}
: ${TEST_SUITE_NAME:=${CLASSNAME}}

export SCRIPT_DIR="$(dirname "$(readlink -f $0)")"
TOP_DIR=${SCRIPT_DIR%%/client-tests/*}
COMMON_DIR="${SCRIPT_DIR}"
source ${COMMON_DIR}/functions.sh

## Parse CMD
CMD=`real_command $1`
ret=$?
if [ $ret -ne 0 ];then
    exit $ret
fi

shift

## No arguments
case $cmd in
    *mvn )
	RunCmd "No arguments" ${CMD} help
	;;
    * )
	RunCmd "No arguments" ${CMD}
	;;
esac
StdoutContainArgument "" "help"
StdoutContainArgument "" "push"
StdoutContainArgument "" "pull"

## Verbose mode (-v)
RunCmd "Verbose" ${CMD} -v
StdoutContain "" "API version: [0-9]*.[0-9]*"

function check_push_pull_common_args(){
    StdoutContainArgument "" "disable-ssl-cert"
    StdoutContainArgument "" "url"
    StdoutContainArgument "" "username"
    StdoutContainArgument "" "key"
    StdoutContainArgument "" "user-config"
    StdoutContainArgument "" "project-config"
    StdoutContainArgument "" "src-dir"
    StdoutContainArgument "" "trans-dir"
    StdoutContainArgument "" "excludes"
    StdoutContainArgument "" "includes"
    StdoutContainArgument "" "locales"
    StdoutContainArgument "" "project"
    StdoutContainArgument "" "project-version"
}

## Subcommand: help push
RunCmd "help push" ${CMD} help push
check_push_pull_common_args
StdoutContainArgument "" "copy-trans"
StdoutContainArgument "" "file-types"
StdoutContainArgument "" "merge-type"
StdoutContainArgument "" "push-type"
StdoutContainArgument "" "from-doc"

## Subcommand: help pull
RunCmd "help pull" ${CMD} help pull
check_push_pull_common_args
StdoutContainArgument "" "create-skeletons"
StdoutContainArgument "" "encode-tabs"
StdoutContainArgument "" "include-fuzzy"
StdoutContainArgument "" "pull-type"

print_summary `basename $0 .sh`

if [ $failed -ne 0 ];then
    exit ${EXIT_CODE_FAILED}
fi
exit 0

