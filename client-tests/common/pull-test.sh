#!/bin/bash
function print_usage(){
    cat <<END
    $0 - Client pull test
SYNOPSIS
    $0  <command>

ARGUMENTS
    command: Client command with path.

DESCRIPTION
    Scope: 
      Basic main workflow (no alternative paths)
      Assume the project and version is created
    1. pull 
    2. pull source
    3. pull both

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
source ${SUITE_DIR}/pull-quick.sh
## Test end

print_summary "${CLASSNAME}"

if [ $failed -ne 0 ];then
    exit ${EXIT_CODE_FAILED}
fi
exit ${EXIT_CODE_OK}
