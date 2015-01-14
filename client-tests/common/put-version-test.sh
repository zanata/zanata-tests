#!/bin/bash
function print_usage(){
    cat <<END
    $0 - Client put-version test
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

## Project definition
: ${ZANATA_PROJECT_SLUG:=ibus-chewing-a}
: ${ZANATA_PROJECT_NAME:=$ZANATA_PROJECT_SLUG}
: ${ZANATA_PROJECT_DESC:=$ZANATA_PROJECT_NAME}
: ${ZANATA_VERSION_SLUG:=master}
: ${ZANATA_PROJECT_TYPE:=gettext}
: ${WORK_DIR:=/tmp/doc-prjs/$ZANATA_PROJECT_SLUG/$ZANATA_VERSION_SLUG}

mkdir -p ${WORK_DIR}
cd $WORK_DIR

COMMON_OPTIONS=("--url=${ZANATA_URL}" "--username=${ZANATA_USERNAME}" "--key=${ZANATA_KEY}")
COMPULSORY_OPTIONS=("--version-project=${ZANATA_PROJECT_SLUG}" "--version-slug=${ZANATA_VERSION_SLUG}")

## Compulsory options Only
RunCmd "CompulsoryOptions Only" ${CMD} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} 

OutputNoError

print_summary `basename $0 .sh`

if [ $failed -ne 0 ];then
    exit ${EXIT_CODE_FAILED}
fi
exit 0

