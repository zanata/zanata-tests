#!/bin/sh

function print_usage(){
    cat <<END
$0 - get docker image id
SYNOPSIS
    $0 -<repositoryRegex> [tag]


DESCRIPTION
    Return the first matched id

END
}

if [ $# -le 0 ];then
    print_usage
    exit 1
fi


: ${DOCKER_CMD:=docker}
REPOSITORY=$1
TAG=$2

${DOCKER_CMD} images -a | awk -v tag="$TAG" -v repo="$REPOSITORY" '($1 ~ repo && $2 ~ tag) { print $3 }' 
exit $?

