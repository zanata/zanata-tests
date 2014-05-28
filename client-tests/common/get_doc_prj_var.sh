#!/bin/bash
NAME=`basename $0`

function usage(){
    cat<<EOF
NAME
    $NAME - get a variable of document project from a Makefile
SYNOPSIS
    $NAME file var
EOF
}

if [[ $# -eq 0 ]];then
    usage
    exit 1
fi

FILE=$1
VAR=$2

grep "$VAR:=" $FILE | sed -e "s/^\s*$VAR:=//" | sed -e 's/^\s*"//' | sed -e 's/"\s*$//'
