#!/bin/bash
function print_usage(){
    cat <<END
    $0 - Client smoke test
SYNOPSIS
    $0  <zanata-executable>

ARGUMENTS
    zanata-executable: Path to zanata executable (e.g. /usr/bin/zanata-cli)

DESCRIPTION
    Smoke tests covert most frequenty used functions.

    Scope of smoke test:
    1. help-quick: Tests for help messages of frequently used command.
    2. put-project: Tests for put project
    3. put-version: Tests for put version
    4. push
    5. pull

EXIT STATUS
   ${EXIT_CODE_OK} if all tests passed
   ${EXIT_CODE_INVALID_ARGUMENTS} invalid or missing arguments
   ${EXIT_CODE_FAILED} at least one of test not passed

END
}

: ${TEST_SUITE_NAME:="Smoke"}

export SCRIPT_DIR="$(dirname "$(readlink -f $0)")"
TOP_DIR=${SCRIPT_DIR%%/client-tests/*}
COMMON_DIR="${TOP_DIR}/client-tests/common"
source ${COMMON_DIR}/functions.sh

## Parse CMD
CMD=`real_command $1`
ret=$?
if [ $ret -ne 0 ];then
    exit $ret
fi

shift

## Test start
SUITE_DIR=${TOP_DIR}/client-tests/suites
export ZANATA_EXECUTABLE=${CMD}
: ${ZANATA_PROJECT_SLUG:=ibus-chewing}
: ${ZANATA_PROJECT_NAME:=$ZANATA_PROJECT_SLUG}
: ${ZANATA_PROJECT_DESC:=$ZANATA_PROJECT_NAME}
: ${ZANATA_VERSION_SLUG:=master}
: ${ZANATA_PROJECT_TYPE:=gettext}
: ${WORK_DIR:=${TOP_DIR}/doc-prjs/$ZANATA_PROJECT_SLUG/$ZANATA_VERSION_SLUG}

source ${SUITE_DIR}/help-quick.sh
unset SKIP_TEST
source ${SUITE_DIR}/put-project-quick.sh
unset SKIP_TEST
source ${SUITE_DIR}/put-version-quick.sh
unset SKIP_TEST

###===== Start push tests =====
CLASSNAME=push
pushd ${WORK_DIR}
PUSH_OPTIONS=(--
--project=${ZANATA_PROJECT_SLUG} --project-version=${ZANATA_VERSION_SLUG} --project-type=${ZANATA_PROJECT_TYPE})

### push with Compulsory options Only
TestCaseStart "Compulsory options"
RunCmd ${ZANATA_EXECUTABLE} 

source ${SUITE_DIR}/push.sh

## push with --push-type=trans
TEST_CASE_NAME_PREFIX="pushType=trans"
PUSH_OPTIONS=( "${PUSH_ORIG_OPTIONS[@]}" --push-type=trans)
source ${SUITE_DIR}/push.sh

## push with --push-type=both
## Push type both
TEST_CASE_NAME_PREFIX="pushType=both"
PUSH_OPTIONS=( "${PUSH_ORIG_OPTIONS[@]}" --push-type=both)
source ${SUITE_DIR}/push.sh

## Restore PUSH_OPTIONS
PUSH_OPTIONS=("${PUSH_ORIG_OPTIONS[@]}")
popd
unset SKIP_TEST
###===== End push tests =====

###===== Start pull tests =====
unset SKIP_TEST
pushd ${WORK_DIR}
USE_DEFAULT_OPTIONS=1
PULL_OPTIONS=(--project=${ZANATA_PROJECT_SLUG} --project-version=${ZANATA_VERSION_SLUG} --project-type=${ZANATA_PROJECT_TYPE})
PULL_ORIG_OPTIONS=("${PULL_OPTIONS[@]}")

## Compulsory options Only
TEST_CASE_NAME_PREFIX="Compulsory options"
source ${SUITE_DIR}/pull.sh

## Pull type trans
TEST_CASE_NAME_PREFIX="pullType=source"
PULL_OPTIONS=( "${PULL_ORIG_OPTIONS[@]}" --pull-type=source)
source ${SUITE_DIR}/pull.sh

## Pull type both
TEST_CASE_NAME_PREFIX="pullType=both"
PULL_OPTIONS=( "${PULL_ORIG_OPTIONS[@]}" --pull-type=both)
source ${SUITE_DIR}/pull.sh

## Restore PULL_OPTIONS
PULL_OPTIONS=("${PULL_ORIG_OPTIONS[@]}")
popd
###===== End push tests =====

print_summary "${TEST_SUITE_NAME}"

if [ $failed -ne 0 ];then
    exit ${EXIT_CODE_FAILED}
fi
exit ${EXIT_CODE_OK}

