#!/bin/bash
function print_usage(){
    cat <<END
    $0 -  Tests of help message of frequently used command.
SYNOPSIS
    $0  <command>

ARGUMENTS
    command: Client command with path.

DESCRIPTION
    Tests for help messages of frequently used command.

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

: ${TEST_SUITE_NAME:=$(basename $0 .sh | sed -e 's/-test$//')}

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

SUITE_DIR=${TOP_DIR}/client-tests/suites
## Test start
source ${SUITE_DIR}/help-quick.sh
## Test end

print_summary "${TEST_SUITE_NAME}"

if [ $failed -ne 0 ];then
    exit ${EXIT_CODE_FAILED}
fi
exit ${EXIT_CODE_OK}

