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
    2. pull trans
    3. pull both

EXIT STATUS
   0 if all tests passed
   1 at least one of test not passed
   2 invalid or missing arguments

END
}

function get_zanata_xml_url(){
    local url=$1
    local proj=$2
    local ver=$3
    echo "${url}iteration/view/${proj}/${ver}?actionMethod=iteration%2Fview.xhtml%3AconfigurationAction.downloadGeneralConfig%28%29"
}

error=
 : ${ZANATA_URL:=http://localized-zanatatest.itos.redhat.com/}
 : ${ZANATA_USERNAME:=peggy}
 : ${ZANATA_KEY:=1a0172997f0a751ca351285b08de4d64}


if [ -n "$error" ];then
    exit 2
fi

SCRIPT_DIR=$(dirname $(readlink -f $0))
TOP_DIR=${SCRIPT_DIR%%/client-tests/*}
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
    exit 1
fi


if [ -n "$MAVEN_CMD" ];then
    REAL_CMD="${CMD} -B -e ${MAVEN_GOAL_PREFIX}:pull -Dzanata.username=${ZANATA_USERNAME} -Dzanata.key=${ZANATA_KEY}"
else
    REAL_CMD="${CMD} -B -e pull --username ${ZANATA_USERNAME} --key ${ZANATA_KEY}"
fi

## Use GNU tar
OUTPUT_DIR=/tmp/doc-prjs/ibus-chewing/master/po

mkdir -p ${OUTPUT_DIR}
cd $OUTPUT_DIR

wget -O zanata.xml $(get_zanata_xml_url $ZANATA_URL tar 1.26)

## pull (without arguments)
command_has_no_error_check "pull" "${REAL_CMD}"

## pull --pull-type trans
command_has_no_error_check "pull --pull-type src" "${REAL_CMD} --pull-type src"

## pull --pull-type both
command_has_no_error_check "pull --pull-type both" "${REAL_CMD} --pull-type both"

print_summary `basename $0 .sh`

if [ $failed -ne 0 ];then
    exit 1
fi
exit 0
