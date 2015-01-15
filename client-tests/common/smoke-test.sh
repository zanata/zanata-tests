#!/bin/bash
function print_usage(){
    cat <<END
    $0 - Client smoke test
SYNOPSIS
    $0  <command>

ARGUMENTS
    command: Client command with path.

DESCRIPTION
    Smoke tests covert most frequenty used functions.

    Scope of smoke test:
    1. help-quick: Tests for help messages of frequently used command.
    2. put-project: Tests for put project
    3. put-version: Tests for put version
    4. push
    5. pull

EXIT STATUS
   0 if all tests passed
   ${EXIT_CODE_INVALID_ARGUMENTS} invalid or missing arguments
   ${EXIT_CODE_FAILED} at least one of test not passed

END
}

TEST_SUITE_NAME="Smoke"

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

## Test start
SUITE_DIR=${TOP_DIR}/client-tests/suites
source ${SUITE_DIR}/help-quick.sh
source ${SUITE_DIR}/put-project-quick.sh
source ${SUITE_DIR}/put-version-quick.sh
source ${SUITE_DIR}/push-quick.sh
source ${SUITE_DIR}/pull-quick.sh

print_summary "${CLASSNAME}"

if [ $failed -ne 0 ];then
    exit ${EXIT_CODE_FAILED}
fi
exit ${EXIT_CODE_OK}
