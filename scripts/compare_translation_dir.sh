#!/bin/bash
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
    podDir: Directory that contains pot files.
    dir1, dir2: 2 directories to be compared.
    langList: list of languages, separated by ';'
END
}

function compare_paths(){
    _potDir=$1
    _path1=$2
    _path2=$3
    echo "_potDir=$_potDir _path1=$_path1 _path2=$_path2"
    if [ $gettext_mode -eq 1 ];then
	if ! $scriptDir/compare_translation.sh $_potDir $_path1 $_path2; then
	    echo "Error: [compare_translation_path.sh] $_path1 is different with $_path2"  > /dev/stderr
	    return 1
	fi
    else
	_fileA0=(`find $_potDir -name '*.pot'| sort | xargs `)
	#echo "fileA0=${_fileA0[*]}"
	for((_i=0; $_i < ${#_fileA0[*]}; _i++));do
	    _potF="${_fileA0[$_i]#${_potDir}}"
	    _relDir=`dirname ${_potF}`
	    _bf=`basename ${_potF} .pot`
	    _d1="${_path1}/${_relDir}"
	    _d2="${_path2}/${_relDir}"
	    # Sometimes source po has more files than pot
	    # But number of target po and pot should match.
	    if [ ! -r  $_d2/$_bf.po ]; then
		echo "Error: $_d2/$_bf.po is not pulled" > /dev/stderr
		return 1
	    fi

	    if [ -r  $_d1/$_bf.po ]; then
		if ! $scriptDir/compare_translation.sh ${_fileA0[$_i]} $_d1/$_bf.po $_d2/$_bf.po; then
		    echo "Error: [compare_translation_path.sh] $_path1 is different with $_path2"  > /dev/stderr
		    return 1
		fi
	    else
		# If source po does not exist, then just compare it with the pot
		if ! $scriptDir/compare_translation.sh ${_fileA0[$_i]} $_d2/$_bf.po $_d2/$_bf.po; then
		    echo "Error: [compare_translation_path.sh] $_d2/$_bf.po is not pulled correctly" > /dev/stderr
		    return 1
		fi
	    fi
	done
    fi
    echo "Files of $_path1 and $_path2 are equivalent."
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

if [ -z "$langList" ]; then
    echo "Error: Please specify langList" > /dev/stderr
    print_usage
    exit -1;
fi

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
    if ! compare_paths $potDir $dir1/${_postFix1[$_i]} $dir2/${_postFix2[$_i]}; then
	exit 1
    fi
done

