#!/usr/bin/env sh
# Compares 2 POs and see whether they are equivalent.
# Direct diff comparison is not very useful, because
# 1) Header field such as Date may be different.
# 2) msgid and msgstr may not be normalized.

function print_usage(){
    cat <<END
    $0 - Whether  2 PO files are identical
Usage: $0 [-v] potFile poFile1 poFile2
Options:
    -v: Verbose mode
    potFile: pot file as reference
    poFile1, poFile2:  2 po files to be compared.
END
}
verbose=0
quietOpt=

if [ $# -lt 3 ];then
    print_usage
    exit -1
fi

if [ "$1" = "-v" ];then
    verbose=1
    shift
else
    quietOpt="-q"
fi
potF="$1"
poF1="$2"
poF2="$3"

tmp1="$poF1.tmp"
tmp2="$poF2.tmp"

[ $verbose -gt 0 ] && echo "Info: Comparing ${poF1} and ${poF2} with ${potF}"
msgcmp -m "${poF1}" "${potF}" | cut -d ':' -f 3,4 > ${tmp1} 2>&1
msgcmp -m "${poF2}" "${potF}" | cut -d ':' -f 3,4 > ${tmp2} 2>&1

ret=0
if diff $quietOpt ${tmp1} ${tmp2}; then
    echo "${poF1} and ${poF2} are equivalent"
    rm -f ${tmp1} ${tmp2}
else
    ret=1
    echo "Error: ${poF1} and ${poF2} are NOT equivalent"  > /dev/stderr
fi
exit ${ret}

