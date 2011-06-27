#!/usr/bin/env sh
# Compares 2 POs and see whether they are equivalent.
# Direct diff comparison is not very useful, because
# 1) Header field such as Date may be different.
# 2) msgid and msgstr may not be normalized.

function print_usage(){
    cat <<END
    $0 - Whether po files under 2 directories are equivalent.
Usage: $0 [options] potDir dir1 dir2 [langList]
Options:
    dir1, dir2: 2 directories to be compared.
END
}

function compare_dirs(){
    _potDir=$1
    _dir1=$2
    _dir2=$3
    _fileList1=`find $dir1 -name '*.po'| sort`
    _fileList2=`find $dir2 -name '*.po'| sort`
    if [ "$_fileList1" = "$_fileList2" ]; then
	_fileA1=(`echo $_fileList1 | xargs`)
	_fileA2=(`echo $_fileList2 | xargs`)
	_i=0
	_len=${#_fileA1}
	while [ $_i -lt $_len ]; do
	    _bf=`basename ${_fileA1[$_i]} .po`
	    _d1=`dirname ${_fileA1[$_i]}`
	    _d2=`dirname ${_fileA2[$_i]}`
	    if ! $scriptDir/compare_translation.sh $_potDir/$_bf.pot $_d1/$_bf.po $_d2/$_bf.po; then
		echo "Error: [compare_translation_dir.sh] $_dir1 is different with $_dir2"  > /dev/stderr
		return 1
	    fi
	done

    fi
    echo "Files of $_dir1 and $_dir2 are different!"
    return -1

}

scriptDir=`dirname $0`
potDir=$1
dir1=$2
dir2=$3
shift 3
if [ -n $1 ];then
    langList=$1
else
    langList=
fi

if [ -n $langList ]; then
    _postFix1=(`$scriptDir/find_valid_locale_dir.sh $dir1 $langList`)
    _postFix2=(`$scriptDir/find_valid_locale_dir.sh $dir2 $langList`)
    if [ ${#_postFix1} -ne ${#_postFix2} ]; then
	echo "Error: [compare_translation_dir.sh] $dir1 contains ${#_postFix1}	valid locale, but $dir2 contains ${#_postFix2}"  > /dev/stderr
	exit -1
    fi
    for

fi

