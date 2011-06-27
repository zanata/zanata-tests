#!/usr/bin/env bash
# Usage: $0 <baseDir> <langList>
# Outputs: Find correspond relative path dir;
#   or none if the <lang> does not exists.

function print_usage(){
cat <<END
    $0 - Given list of locale to find, return the paths

    Usage: $0 [options] baseDir localeList
    Options:
        -h: Print this help.
	-m: Allow multiple finding per lang.
	-s separator: Output sepration charactor. Default is ' '.

    Parameters:
	baseDir: base dir
	localeList: list of locale (separate by ';')

Output:
    pathList: Relative directories, seperated by defined separator.
END
}

function findLangDirs(){
    bDir=$1
    langNameTemplate=$2
    _ret=

    _lDirA=(`find $bDir -wholename "*/$langNameTemplate/*.po" -exec dirname '{}' \; | sort -u`)
    if [ ${#_lDirA} -gt 0 ];then
	#echo "_lDirA[0]=${_lDirA[0]}"
	_rDir=`${scriptDir}/relative_path.sh ${bDir} ${_lDirA[0]}`
	_ret=${_rDir%%/}
	if [ ${_multiple} -eq 1 ];then
	    for((_i=1; $_i < ${#_lDirA}; _i++ )); do
		_rDir=`${scriptDir}/relative_path.sh ${bDir} ${_lDirA[$_i]}`
		_ret="$_ret$_separator${_rDir%%/}"
	    done
	fi
    else
	echo "findLangDir(): non-empty $langNameTemplate is not found in $bDir" > /dev/stderr
    fi

    echo "$_ret"
}

_separator=' '
_multiple=0

while getopts "hms:" opt; do
    case $opt in
	h)
	    print_usage
	    exit 0
	    ;;
	m)
	    _multiple=1
	    ;;
	s)
	    _separator=$OPTARG
	    ;;
	*)
	;;
    esac
done
shift $((OPTIND-1));

scriptDir=`dirname $0`
baseDir=$1
langList=$2

_langA=(`echo $langList | sed -e 's/;/ /g'`)
_out=

for(( _i=0 ;$_i < ${#_langA}; _i++)); do
    echo "_i=$_i"
    case ${_langA[$_i]} in
	zh*CN | zh*Hans )
	    _ret=`findLangDirs $baseDir "zh*CN"`
	    ;;
	zh*TW | zh*Hant )
	    _ret=`findLangDirs $baseDir "zh*TW"`
	    ;;
	* )
	    _ret=`findLangDirs $baseDir "${_langA[$_i]}*"`
	    ;;
    esac
    if [ $_i -gt 0 ];then
	_out="$_out$_separator$_ret"
    else
	_out="$_ret"
    fi
done
echo "$_out"

