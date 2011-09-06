#!/usr/bin/env sh
# Compares 2 directories that contains po files.
#

function print_usage(){
    cat <<END
    $0 - Whether po files under 2 directories are equivalent.
Usage: $0 [options] potDir dir1 dir2 langList
Options:
    potDir: Directory that contains pot files.
    dir1, dir2: 2 directories to be compared.
    langList: list of languages, separated by ';'
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
	for((_i=0; $_i < ${#_fileA1[*]}; _i++));do
	    _bf=`basename ${_fileA1[$_i]} .po`
	    _d1=`dirname ${_fileA1[$_i]}`
	    _d2=`dirname ${_fileA2[$_i]}`
	    if ! $scriptDir/compare_translation.sh $_potDir/$_bf.pot $_d1/$_bf.po $_d2/$_bf.po; then
		echo "Error: [compare_translation_dir.sh] $_dir1 is different with $_dir2"  > /dev/stderr
		return 1
	    fi
	done

    fi
    echo "Files of $_dir1 and $_dir2 are equivalent."
    return

}

if [ $# -ne 4 ]; then
    print_usage
    exit 0
fi

scriptDir=`dirname $0`
potDir=$1
dir1=$2
dir2=$3
langList=$4
shift 4

if [ -n $langList ]; then
    _postFix1=(`$scriptDir/find_valid_langs.sh -m -p $potDir $dir1 $langList`)
    echo "_postFix1=${_postFix1}"
    _postFix2=(`$scriptDir/find_valid_langs.sh -m -p $potDir $dir2 $langList`)
    echo "_postFix2=${_postFix2}"
    if [ ${#_postFix1[*]} -ne ${#_postFix2[*]} ]; then
	echo "Error: [compare_translation_dir.sh] $dir1 contains
	${#_postFix1[*]} valid locale dirs (${_postFix1[*]}), but $dir2 contains
	${#_postFix2[*]}: (${_postFix2[*]})"  > /dev/stderr
	exit 1
    fi
    for((_i=0; $_i < ${#_postFix1[*]} ; _i++));do
	if ! compare_dirs $potDir $dir1/${_postFix1[$_i]} $dir2/${_postFix2[$_i]}; then
	    exit 1
	fi
    done
fi

