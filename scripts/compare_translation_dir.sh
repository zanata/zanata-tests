#!/usr/bin/env sh
# Compares 2 directories that contains po files.
#

function print_usage(){
    cat <<END
    $0 - Whether po files under 2 directories are equivalent.
Usage: $0 [options] potDir dir1 dir2 langList
Options:
    -h: This help
    -g: gettext mode
Parameters:
    potDir: Directory that contains pot files.
    dir1, dir2: 2 directories to be compared.
    langList: list of languages, separated by ';'
END
}

function is_dir_item_same(){
    _d1=$1
    _d1Content=$2
    _d2=$3
    _d2Content=$4
    if [[ $_d1Content != $_d2Content ]];then
	echo "Error: [compare_translation_dir.sh] $_d1 has $_d1Content items, but $_d2 has $_d2Content items"  > /dev/stderr
	return 1
    fi
    return 0
}

function compare_dirs(){
    _potDir=$1
    _dir1=$2
    _dir2=$3
    _fileA0=(`find $_potDir -name '*.pot'| sort | xargs `)
    _fileA1=(`find $_dir1 -name '*.po'| sort | xargs `)
    _fileA2=(`find $_dir2 -name '*.po'| sort | xargs `)
    if ! is_dir_item_same "$_potDir" ${#_fileA0[*]} "$_dir1" ${#_fileA1[*]} ; then
	return 1
    fi
    if ! is_dir_item_same "$_potDir" ${#_fileA0[*]} "$_dir2" ${#_fileA2[*]} ; then
	return 1
    fi

    # Number of items in _potDir, _dir1 and _dir2 should be same here
    for((_i=0; $_i < ${#_fileA1[*]}; _i++));do
	_bf=`basename ${_fileA1[$_i]} .po`
	_d1=`dirname ${_fileA1[$_i]}`
	_d2=`dirname ${_fileA2[$_i]}`
	if ! $scriptDir/compare_translation.sh $_potDir/$_bf.pot $_d1/$_bf.po $_d2/$_bf.po; then
	    echo "Error: [compare_translation_dir.sh] $_dir1 is different with $_dir2"  > /dev/stderr
	    return 1
	fi
    done
    echo "Files of $_dir1 and $_dir2 are equivalent."
    return 0

}

gettext_mode=0
while getopts "hg" opt; do
    case $opt in
	h)
	    print_usage
	    exit 0
	    ;;
	g)
	    gettext_mode=1
	    ;;
	*)
	    ;;
    esac
done
shift $((OPTIND-1));

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
    if [ $gettext_mode -eq 1 ];then
	_postFix1=(`$scriptDir/find_valid_langs.sh -f -p $potDir $dir1 $langList`)
	_postFix2=(`$scriptDir/find_valid_langs.sh -f -p $potDir $dir2 $langList`)
    else
	_postFix1=(`$scriptDir/find_valid_langs.sh -m -p $potDir $dir1 $langList`)
	_postFix2=(`$scriptDir/find_valid_langs.sh -m -p $potDir $dir2 $langList`)
    fi
    echo "_postFix1=${_postFix1} potDir=$potDir dir1=$dir1"
    echo "_postFix2=${_postFix2} potDir=$potDir dir2=$dir2"
    if [ ${#_postFix1[*]} -ne ${#_postFix2[*]} ]; then
	echo "Error: [compare_translation_dir.sh] $dir1 contains ${#_postFix1[*]} valid locale dirs (${_postFix1[*]}), but $dir2 contains ${#_postFix2[*]}: (${_postFix2[*]})"  > /dev/stderr
	exit 1
    fi
    for((_i=0; $_i < ${#_postFix1[*]} ; _i++));do
	if ! compare_dirs $potDir $dir1/${_postFix1[$_i]} $dir2/${_postFix2[$_i]}; then
	    exit 1
	fi
    done
fi

