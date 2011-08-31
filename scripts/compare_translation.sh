#!/usr/bin/env sh
# Compares 2 POs and see whether they are equivalent.
# Direct diff comparison is not very useful, because
# 1) Header field such as Date may be different.
# 2) msgid and msgstr may not be normalized.

function print_usage(){
    cat <<END
    $0 - Whether  2 PO files are identical
Usage: $0 [options] potFile [poFile1 poFile2]
Options:
    potFile: pot file as reference
    poFile1, poFile2:  2 po files to be compared.
END
}


if [ $# -ne 3 ];then
    print_usage
    exit -1
fi
potF=$1
poF1=$2
poF2=$3

tmp1="1.tmp"
tmp2="2.tmp"

msgcmp -m ${poF1} ${potF} > ${tmp1} 2>&1
msgcmp -m ${poF2} ${potF} > ${tmp2} 2>&1

ret=0
if diff ${tmp1} ${tmp2}; then
    echo "${poF1} and ${poF2} are equivalent"
else
    ret=1
    echo "Error: ${poF1} and ${poF2} are NOT equivalent"  > /dev/stderr
fi
exit ${ret}

