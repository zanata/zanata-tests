#!/usr/bin/env bash
# Usage: $0 <baseDir> <langList>
# Outputs: Find correspond relative path;
#   or empty if none of the <langList> exists.

function print_usage(){
cat <<END
    $0 - Given list of locale to find, return the paths

    Usage: $0 [options] baseDir localeList
    Options:
        -h: Print this help.
	-m: Allow multiple finding per lang.
	-s separator: Output sepration charactor. Default is ' '.
	-p potDir: Directory that contains pot files.
	           potDir should either be relative path from baseDir,
		   or absolute path.
	-f: find files instead of directories.

    Parameters:
	baseDir: base dir
	localeList: list of locale (separate by ';')

Output:
    pathList: Relative directories, seperated by defined separator.
END
}

function findLangs(){
    langNameTemplate=$1
#    echo "langNameTemplate=${langNameTemplate}" > /dev/stderr
#   _r: result
    _r=

    # find the files/directories that match langNameTemplate
    if [ $_fileMode -eq 1 ]; then
	_pA=(`find $baseDir -wholename "*/$langNameTemplate*.po"  | sort -u`)
    else
	_pA=(`find $baseDir -wholename "*/$langNameTemplate/*.po" -exec dirname '{}' \; | sort -u`)
    fi
#    echo "_pA[*]=${_pA[*]}" > /dev/stderr
    if [ ${#_pA[*]} -gt 0 ];then
	for((_i=0; $_i < ${#_pA[*]}; _i++ )); do
	    # _rPath: relative path from baseDir
	    _rPath=$(${scriptDir}/relative_path.sh ${baseDir} ${_pA[$_i]})
#	    echo "baseDir=${baseDir} _pA[$_i]=${_pA[$_i]} _rPath=$_rPath" > /dev/stderr
	    _is_valid=0
	    if [ $_fileMode -eq 1 ]; then
		# In file mode, just pass the found files.
		_is_valid=1

	    else
		# In directory mode, need to check whether corresponding
		# directory in pot directory

		# _pPath: corresponding path in pot_dir
		_pPath=${_potDir}/${_rPath#$langNameTemplate/}
#		 echo "_rPath=$_rPath _pPath=$_pPath" > /dev/stderr
		if [ -e "$_pPath" ]; then
		    # Has corresponding pot directory
		    _is_valid=1
		fi
	    fi

#	    echo "_is_valid=$_is_valid" > /dev/stderr
	    if [ $_is_valid -eq 1 ]; then
		if [  -z "$_r" ];then
		    _r=${_rPath%%/}
		else
		    _r="$_r$_separator${_rPath%%/}"
		fi
		if [ ${_multiple} -eq 0 ];then
		    break
		fi
	    fi

	done
	#echo "_r=$_r" > /dev/stderr
	if [ -n "$_r" ];then
	    echo "$_r"
	else
	    echo "findLangs(): no valid path for $langNameTemplate in $baseDir" > /dev/stderr
	fi
    else
	echo "findLangs(): non-empty $langNameTemplate is not found in $baseDir" > /dev/stderr
    fi
}

if [ $# -lt 2 ]; then
    print_usage
    exit 1
fi


_separator=' '
_multiple=0
_fileMode=0
_potDir=.

while getopts "fhms:p:" opt; do
    case $opt in
	h)
	    print_usage
	    exit 0
	    ;;
	f)
	    _fileMode=1
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

if [ "${_potDir:0:1}" != "/" ]; then
    # path that related to baseDir
    _potDir="${baseDir}/${_potDir}"
fi

_langA=(`echo "$langList" | sed -e 's/;/ /g'`)
#echo "_langA[*]=${_langA[*]}"
_out=

for(( _i=0 ;$_i < ${#_langA[*]}; _i++)); do
#    echo "_langA[$_i]=${_langA[$_i]}"
    case ${_langA[$_i]} in
	zh*CN | zh*Hans )
	    _ret=`findLangs "zh*CN"`
	    ;;
	zh*TW | zh*Hant )
	    _ret=`findLangs "zh*TW"`
	    ;;
	* )
	    _ret=`findLangs "${_langA[$_i]}*"`
	    ;;
    esac
    if [ -n "$_out" ];then
	_out="$_out$_separator$_ret"
    else
	_out="$_ret"
    fi
done
echo "$_out"

