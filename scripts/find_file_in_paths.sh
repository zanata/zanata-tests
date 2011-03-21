#!/bin/sh
# $0 <glob pattern> <searchPaths>

PATTERN=$1
SEARCH_PATHS=`echo $2 | sed -e 's/ /\\ /g' | sed -e 's/\([^\\]\);/\1 /g' | sed -e 's/\\;/;/g' `
#echo "SEARCH_PATHS=${SEARCH_PATHS}"

for fileDir in ${SEARCH_PATHS} ;do
    dirs=`/bin/ls -d ${fileDir} 2>/dev/null`
    #echo "dirs=${dirs}"
    for fileDirM in $dirs; do
	#echo "fileDirM=${fileDirM}"
	filePath=`find ${fileDirM}/ -name "${PATTERN}" -type f | head --lines=1`
	#echo "filePath=|${filePath}|"
	if [ -n "${filePath}" ]; then
	    echo "${filePath}"
	    exit 0
	fi
    done
done
echo "NOTFOUND"

