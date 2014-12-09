#!/bin/sh

function print_usage(){
    cat <<END
$0 - remove docker image id
SYNOPSIS
    $0 REPOSITORY [TAG]

DESCRIPTION
    Return the specified docker image

EXIT STATUS
    0 Ok
    1 Showing print_usage
    41 Failed to remove image
    44 if no such repository
    45 if tag is not found
END
}

function error_msg(){
    echo $1 > /dev/stderr
}

if [ $# -le 0 ];then
    print_usage
    exit 1
fi

REPOSITORY=$1
TAG=$2
SCRIPT_DIR=`dirname $0`
: ${DOCKER_CMD:=docker}

imageId=`$SCRIPT_DIR/docker-get-image-id.sh $REPOSITORY $TAG`
ret=$?

case $ret in
    44)
	error_msg "No such repository"
	exit 44
	;;
    45)
	error_msg "No such tag"
	exit 45
	;;
esac

if [ -z "$imageId" ];then
    error_msg "Image Id not found"
    exit 41
fi

if ! $DOCKER_CMD rmi $imageId; then
    error_msg "Failed to remove image"
    exit 41
fi

exit 0

