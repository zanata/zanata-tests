#!/bin/bash
function print_usage(){
    cat <<END
    $0 - Client put-project test
SYNOPSIS
    $0  <command>

ARGUMENTS
    command: Client command with path.

DESCRIPTION
    Scope: 
      Basic main workflow (no alternative paths)

EXIT STATUS
   0 if all tests passed
   ${EXIT_CODE_INVALID_ARGUMENTS} invalid or missing arguments
   ${EXIT_CODE_FAILED} at least one of test not passed

END
}

: ${TEST_SUITE_NAME:=$(basename $0 .sh | sed -e 's/-test$//')}

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

SUITE_DIR=${TOP_DIR}/client-tests/suites
## Test start
source ${SUITE_DIR}/put-project-quick.sh
## Test end


print_summary "${TEST_SUITE_NAME}"

if [ $failed -ne 0 ];then
    exit ${EXIT_CODE_FAILED}
fi
exit ${EXIT_CODE_OK}

