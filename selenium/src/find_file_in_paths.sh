#!/bin/sh
# $0 <glob pattern> <searchPaths>

PATTERN=$1
SEARCH_PATHS=`echo $2 | sed -e 's/ /\\ /g' | sed -e 's/\([^\\]\);/\1 /g' | sed -e 's/\\;/;/g' `
echo "SEARCH_PATHS=${SEARCH_PATHS}"

for fileDir in ${SEARCH_PATHS} ;do
    dirs=`/bin/ls -d ${fileDir} 2>/dev/null`
    for fileDirM in $dirs; do
	filePath=`find $fileDirM -name "${PATTERN}" -type f | head --lines=1`
	if [ -n ${filePath} ]; then
	    echo "${filePath}"
	    exit 0
	fi
    done
done
echo "NOT_FOUND"

