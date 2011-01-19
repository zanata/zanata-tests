#!/usr/bin/env sh
# Usage: $0 <baseDir> <lang>
# Outputs: Find correspond relative path dir;
#   or none if the <lang> does not exists.

baseDir=$1
lang=$2

function findLangDir(){
    bDir=$1
    langNameTemplate=$2
    dirFound=`find ${bDir}  -wholename "*/$langNameTemplate/*.po"`
    if [ -n "${dirFound}" ]; then
       echo $(dirname `echo "${dirFound}" | head --lines=1`) | sed -e "s!${baseDir}!!" | sed -e "s!^/!!"
    else
        echo "findLangDir(): $langNameTemplate is not found in $Dir" > /dev/stderr
    fi
}

case $lang in
    zh*CN )
	findLangDir $baseDir "zh*CN"
	;;
    zh*TW )
	findLangDir $baseDir "zh*TW"
	;;
    * )
	findLangDir $baseDir "${lang}-?*"
	;;
esac

