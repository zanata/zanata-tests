#!/bin/sh
# Test whether the flies server is up.

function print_usage(){
    echo "Usage: $0 <FLIES_SERVER_URL>"
}

UP_PATTERN='id="Sign_in"'
FLIES_SERVER_URL=$1
DOWNLOAD_FILE=index.html.tmp

if [ -z $FLIES_SERVER_URL ]; then
    print_usage
    exit -1
fi

wget -O $DOWNLOAD_FILE $FLIES_SERVER_URL
if grep $UP_PATTERN $DOWNLOAD_FILE; then
    UP=1
    echo "Flies server on $FLIES_SERVER_URL is [UP]"
else
    UP=0
    echo "Flies server on $FLIES_SERVER_URL is [DOWN]"
fi

rm -f $DOWNLOAD_FILE

if [ "$UP" = "0" ];then
    exit 1
fi
exit 0;

