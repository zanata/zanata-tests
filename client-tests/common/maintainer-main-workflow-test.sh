#!/bin/bash
function print_usage(){
    cat <<END
    $0 - maintainer main workflow
SYNOPSIS
    $0  <zanata-executable> <project> <version> <project-type> [options]

ARGUMENTS
    zanata-executable: Path to zanata executable (e.g. /usr/bin/zanata-cli)


DESCRIPTION
    This command should be run under the project work root directory.
    (e.g you should be in ibus-chewing/ to work with ibus-chewing project)

    maintainer main workflow is:
    1. put-project
    2. put-version
    3. push --push-type=both
    4. pull (default)

EXIT STATUS
   0 if all tests passed
   ${EXIT_CODE_INVALID_ARGUMENTS} invalid or missing arguments
   ${EXIT_CODE_FAILED} at least one of test not passed

END
}

: ${TEST_SUITE_NAME:="maintainer-main-workflow"}

for p in ZANATA_EXECUTABLE ZANATA_PROJECT_SLUG ZANATA_VERSION_SLUG ZANATA_PROJECT_TYPE;do
    if [ -z "$1" ];then
	echo "Argument $p required" >/dev/stderr
	exit 1
    fi
    eval "$p=\"$1\""
    shift
    export $p
done

export SCRIPT_DIR="$(dirname "$(readlink -f $0)")"
TOP_DIR=${SCRIPT_DIR%%/client-tests/*}
COMMON_DIR="${TOP_DIR}/client-tests/common"
source ${COMMON_DIR}/functions.sh

## Canonicalize ZANATA_EXECUTABLE
ZANATA_EXECUTABLE=`real_command $ZANATA_EXECUTABLE`
ret=$?
if [ $ret -ne 0 ];then
    exit $ret
fi
shift


### Test Start
### ~~~~~~~~~~~
SUITE_DIR=${TOP_DIR}/client-tests/suites

### Test put-project
### ^^^^^^^^^^^^^^^^
unset SKIP_TEST
source ${SUITE_DIR}/put-project-quick.sh

### Test put-version
### ^^^^^^^^^^^^^^^^
unset SKIP_TEST
source ${SUITE_DIR}/put-version-quick.sh

### Make zanata.xml (Not a test)
### ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
zanata_xml_make ${ZANATA_URL} ${ZANATA_PROJECT_SLUG} ${ZANATA_VERSION_SLUG}

### Test push
### ^^^^^^^^^
unset SKIP_TEST
PUSH_ORIG_OPTIONS=("${PUSH_OPTIONS[@]}")

### push with Compulsory Options
### ++++++++++++++++++++++++++++
TEST_CASE_NAME_PREFIX="Compulsory options"
source ${SUITE_DIR}/push.sh

### push with pushType=both
### ++++++++++++++++++++++++
TEST_CASE_NAME_PREFIX="pushType=both"
PUSH_OPTIONS=( "${PUSH_ORIG_OPTIONS[@]}" --push-type=both)
source ${SUITE_DIR}/push.sh

## Restore PUSH_OPTIONS
PUSH_OPTIONS=("${PUSH_ORIG_OPTIONS[@]}")

### Test pull
### ^^^^^^^^^
unset SKIP_TEST
PULL_ORIG_OPTIONS=("${PULL_OPTIONS[@]}")

### pull with Compulsory Options
### ++++++++++++++++++++++++++++
TEST_CASE_NAME_PREFIX="Compulsory options"
source ${SUITE_DIR}/pull.sh

### pull with pullType=both
### ++++++++++++++++++++++++
TEST_CASE_NAME_PREFIX="pullType=both"
PULL_OPTIONS=( "${PULL_ORIG_OPTIONS[@]}" --pull-type=both)
source ${SUITE_DIR}/pull.sh

## Restore PULL_OPTIONS
PULL_OPTIONS=("${PULL_ORIG_OPTIONS[@]}")

print_summary "${TEST_SUITE_NAME}"

if [ $failed -ne 0 ];then
    exit ${EXIT_CODE_FAILED}
fi
exit ${EXIT_CODE_OK}


