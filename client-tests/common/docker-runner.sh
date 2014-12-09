#!/bin/bash

function print_usage(){
    cat <<END
    $0 - Run test on docker, as if run in local
SYNOPSIS
    $0 [OPTIONS] <command>

ARGUMENTS
    command: Command to be run at docker

OPTIONS
    -i <image>: docker image name
    -t <tag>: docker tag name
    -u <username>: username inside docker

DESCRIPTION

EXIT STATUS
    1: Unrecoginzed option or command is not specified
    Otherwise same as <command>
END
}

SCRIPT_DIR=$(readlink -f `dirname $0`)
TOP_DIR=`(cd ${SCRIPT_DIR}; git-rev-parse --show-toplevel)`
COMMON_DIR="${TOP_DIR}/client-tests/common"
source ${COMMON_DIR}/functions.sh

DOCKER_USERNAME=queen
DOCKER_IMAGE=zanata-client-fedora
DOCKER_IMAGE_TAG=20

while getopts "i:t:u:" opt; do
    case $opt in
	i)
	    DOCKER_IMAGE=$OPTARG
	    ;;
	t)
	    DOCKER_IMAGE_TAG=$OPTARG
	    ;;
	u) 
	    DOCKER_USERNAME=$OPTARG
	    ;;
	*)
	    print_usage
	    echo "Unrecognized option $opt" > /etc/strerr
	    exit 1
	    ;;
    esac
done
shift $((OPTIND-1));
CMD=$1
shift

if [ -z "${CMD}" ]; then
    print_usage
    echo "[command] is not specified"
    exit 1
fi

CMD_DIR=$(dirname `readlink -f ${CMD}`)
CMD_NAME=$(basename ${CMD})

DOCKER_CMD_REL_PATH=${CMD_DIR##$TOP_DIR}

DOCKER_COMMAND="docker run --rm -t -i -v ${TOP_DIR}/:/zanata-tests/ ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG} su - ${DOCKER_USERNAME} -c "

${DOCKER_COMMAND} /zanata-tests${DOCKER_CMD_REL_PATH}/${CMD_NAME} "$@"

