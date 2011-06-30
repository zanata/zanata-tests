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
	-p potDir: Directory that contains pot files.

    Parameters:
	baseDir: base dir
	localeList: list of locale (separate by ';')

Output:
    pathList: Relative directories, seperated by defined separator.
END
}

function findLangDirs(){
    langNameTemplate=$1
#    echo "langNameTemplate=${langNameTemplate}"
    _ret=
    _lDirA=(`find $baseDir -wholename "*/$langNameTemplate/*.po" -exec dirname '{}' \; | sort -u`)
#    echo "_lDirA[*]=${_lDirA[*]}"
    if [ ${#_lDirA[*]} -gt 0 ];then
	for((_i=0; $_i < ${#_lDirA[*]}; _i++ )); do
	    _rDir=`${scriptDir}/relative_path.sh ${baseDir} ${_lDirA[$_i]}`
#	    echo "_rDir=$_rDir _tDir=$_potDir/${_rDir#$langNameTemplate/}"
	    if [ -d $_potDir/${_rDir#$langNameTemplate/} ]; then
		# Has corresponding pot directory
		if [  -z "$_ret" ];then
		    _ret=${_rDir%%/}
		else
		    _ret="$_ret$_separator${_rDir%%/}"
		fi
		if [ ${_multiple} -eq 0 ];then
		    break
		fi
	    fi
	done
	if [ -n "$_ret" ];then
	    echo "$_ret"
	else
	    echo "findLangDirs(): pot directory does not contains corresponding  subdirectories of $baseDir" > /dev/stderr
	fi
    else
	echo "findLangDirs(): non-empty $langNameTemplate is not found in $baseDir" > /dev/stderr
    fi
}

if [ $# -lt 2 ]; then
    print_usage
    exit 1
fi


_separator=' '
_multiple=0
_potDir=.

while getopts "hms:p:" opt; do
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
	p)
	    _potDir=$OPTARG
	    ;;
	*)
	;;
    esac
done
shift $((OPTIND-1));

scriptDir=`dirname $0`
baseDir=$1
#echo baseDir=$baseDir
langList=$2
#echo langList=$langList

_langA=(`echo "$langList" | sed -e 's/;/ /g'`)
#echo "_langA[*]=${_langA[*]}"
_out=

for(( _i=0 ;$_i < ${#_langA[*]}; _i++)); do
    case ${_langA[$_i]} in
	zh*CN | zh*Hans )
	    _ret=`findLangDirs "zh*CN"`
	    ;;
	zh*TW | zh*Hant )
	    _ret=`findLangDirs "zh*TW"`
	    ;;
	* )
	    _ret=`findLangDirs "${_langA[$_i]}*"`
	    ;;
    esac
    if [ -n "$_out" ];then
	_out="$_out$_separator$_ret"
    else
	_out="$_ret"
    fi
done
echo "$_out"

