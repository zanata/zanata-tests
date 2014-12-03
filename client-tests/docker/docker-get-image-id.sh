#!/bin/sh

function print_usage(){
    cat <<END
$0 - get docker image id
SYNOPSIS
    $0 REPOSITORY [TAG]

DESCRIPTION
    Return the first matched id

EXIT STATUS
    0 if matched id is found
    1 for showing print_usage
    44 if repository is not found 
    45 if tag is not found
END
}

if [ $# -le 0 ];then
    print_usage
    exit 1
fi

: ${DOCKER_CMD:=docker}
REPOSITORY=$1
TAG=$2

output=`$DOCKER_CMD images $REPOSITORY`

if [ -z "$output" ];then
    echo "repository is no found" > /dev/stderr
    exit 44
fi

repoList=`echo "${output}" | tail -n -1`
if [ -z "$TAG" ];then
    echo "$repoList" | head -n 1 | awk '{print $3}'
    exit 0
fi

imageId=`echo $repoList | awk -v tag="$TAG" '$2==tag {print $3}'`

if [ -z "$imageId" ];then
    echo "tag is no found" > /dev/stderr
    exit 45
fi

echo "$imageId"

exit 0
