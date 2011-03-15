#!/usr/bin/env sh
# Usage: $0 <baseDir> <lang>
# Outputs: Find correspond relative path dir;
#   or none if the <lang> does not exists.

baseDir=$1
lang=$2

# Using dirFound=`find ${bDir}  -wholename "*/$langNameTemplate/*.po"`
# sometimes finds an incorrect subdirectory.
function findLangDir(){
    bDir=$1
    langNameTemplate=$2

    if [ -d ${bDir}/$langNameTemplate ];then
	if ls -1 ${bDir}/$langNameTemplate/*.po > /dev/null;then
	    echo $(dirname `ls -1 ${bDir}/$langNameTemplate/*.po | head --lines=1` )
	else
	    echo "findLangDir(): $langNameTemplate does not have any .po files!" > /dev/stderr
	fi
    else
	echo "findLangDir(): $langNameTemplate is not found in $bDir" > /dev/stderr
    fi
}

case $lang in
    zh*CN | zh*Hans )
	findLangDir $baseDir "zh*CN"
	;;
    zh*TW | zh*Hant )
	findLangDir $baseDir "zh*TW"
	;;
    * )
	findLangDir $baseDir "${lang}*"
	;;
esac

