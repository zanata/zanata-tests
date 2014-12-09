#!/bin/bash
function print_usage(){
    cat <<END
    $0 - Client smoke test
SYNOPSIS
    $0  <command>

ARGUMENTS
    command: Client command with path.

DESCRIPTION
    Scope of smoke test:
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
   1 at least one of test not passed
   2 invalid or missing arguments

END
}

function test_global_options_output(){
    if [ -n "${MAVEN_CMD}" ];then
        has_string_check "disbaleSSLCert" "$commandOutput"
	has_string_check "projectConfig" "$commandOutput"
    else
        has_string_check "disable-ssl-cert" "$commandOutput"
        has_string_check "project-config" "$commandOutput"
    fi
    has_string_check "key" "$commandOutput"
    has_string_check "url" "$commandOutput"
    has_string_check "username" "$commandOutput"
}

function test_push_pull_common_options_output(){
    if [ -n "${MAVEN_CMD}" ];then
        has_string_check "fromDoc" "$commandOutput"
        has_string_check "srcDir" "$commandOutput"
	has_string_check "transDir" "$commandOutput"
    else
	has_string_check "from-doc" "$commandOutput"
        has_string_check "src-dir" "$commandOutput"
	has_string_check "trans-dir" "$commandOutput"
    fi
    has_string_check "excludes" "$commandOutput"
    has_string_check "includes" "$commandOutput"
    has_string_check "locales" "$commandOutput"
    has_string_check "project" "$commandOutput"
}

SCRIPT_DIR=`dirname $0`
COMMON_DIR="${SCRIPT_DIR}"
source ${COMMON_DIR}/functions.sh
MAVEN_GOAL_PREFIX="org.zanata:zanata-maven-plugin"

CMD=$1
shift

CMD_NAME=`basename ${CMD}`
if [ "${CMD_NAME}" = "mvn" ];then
    MAVEN_CMD=1
else
    MAVEN_CMD=
fi

if [ -z "${CMD}" ]; then
    print_usage
    echo "[command] is not specified"
    exit 2
fi

if [ -n "${SKIP_TEST}" ]; then
    skipped_msg "Command exists"
else
    if [ -x "${CMD}" ];then
	ok_msg "Command exists"
    else
	failed_msg "Command exists"
	SKIP_TEST=1
    fi
fi

commandOutput=
command_return 0 ${CMD}

# available commands
if [ -z "${SKIP_TEST}" ];then
    if [ -n "${MAVEN_CMD}" ];then
	commandOutput=`${CMD} ${MAVEN_GOAL_PREFIX}:help`
    fi
fi

if [ -z "${MAVEN_CMD}" ];then
    has_string_check "Usage:" "$commandOutput"
    has_string_check "Available commands" "$commandOutput"
fi

has_string_check "help" "$commandOutput"
has_string_check "push" "$commandOutput"
has_string_check "pull" "$commandOutput"

if [ -z "${MAVEN_CMD}" ];then
    # -v output
    commandOutput=
    if [ -z "${SKIP_TEST}" ];then
        commandOutput=`${CMD} -v`
    fi
    has_string_check "API version: [0-9]*.[0-9]*" "$commandOutput"
fi

# help push
commandOutput=
if [ -z "${SKIP_TEST}" ];then
    if [ -n "${MAVEN_CMD}" ];then
	commandOutput=`${CMD} ${MAVEN_GOAL_PREFIX}:help -Ddetail -Dgoal=push`
    else
        command_return 0 "${CMD} help push"
    fi
fi

test_global_options_output
test_push_pull_common_options_output

if [ -n "${MAVEN_CMD}" ];then
    has_string_check "copyTrans" "$commandOutput"
    has_string_check "fileTypes" "$commandOutput"
    has_string_check "merge" "$commandOutput"
    has_string_check "pushType" "$commandOutput"
else
    has_string_check "copy-trans" "$commandOutput"
    has_string_check "file-types" "$commandOutput"
    has_string_check "merge-type" "$commandOutput"
    has_string_check "push-type" "$commandOutput"
fi

# help pull
commandOutput=
if [ -z "${SKIP_TEST}" ];then
    if [ -n "${MAVEN_CMD}" ] ;then
	commandOutput=`${CMD} ${MAVEN_GOAL_PREFIX}:help -Ddetail -Dgoal=pull`
    else
	commandOutput=`${CMD} help pull`
    fi
fi

test_global_options_output
test_push_pull_common_options_output

if [ -n "${MAVEN_CMD}" ];then
    has_string_check "createSkeletons" "$commandOutput"
    has_string_check "encodeTabs" "$commandOutput"
    has_string_check "includeFuzzy" "$commandOutput"
    has_string_check "pullType" "$commandOutput"
else
    has_string_check "create-skeletons" "$commandOutput"
    has_string_check "encode-tabs" "$commandOutput"
    has_string_check "include-fuzzy" "$commandOutput"
    has_string_check "pull-type" "$commandOutput"
fi

print_summary `basename $0 .sh`

if [ $failed -ne 0 ];then
    exit 1
fi
exit 0
