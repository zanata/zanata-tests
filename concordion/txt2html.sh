#!/bin/sh

function print_usage(){
    cat <<END
    $0 - Convert asciidoc to concordion html

SYNOPSIS
    $0 <TxtFile> <htmlDir|htmlFile>

DESCRIPTION
    This program convert an asciidoc text file to concodion
    instrumented html file. For example:
    $0 TestCase1.txt TestCases/
    will convert TestCase1.txt to TestCases/TextCase1.html

    If target file is already exist, this program will not touch it
    and exit with -2.

EXIT STATUS
    0: if everything is normal.
    -1: Source file cannot be read.
    -2: Target file exists.
    1: Other error.
END
}

src=$1
name=`basename $src .txt`
target=$2

if [ ! -r $src ];then
    echo "Cannot read $src" > /dev/stderr
    exit -1
fi

if [ -d $target ];then
    target="$target/$name.html"
fi

if [ -e $target ];then
    echo "Target file $target already exists" > /dev/stderr
    exit -2
fi

scriptDir=`dirname $0`
cfgFile=$scriptDir/xhtml11.conf

asciidoc -f $cfgFile -o $target $src
exit $?
