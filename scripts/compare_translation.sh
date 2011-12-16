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

tmpPrefix='comparePo'

tmp1="$poF1.tmp"
tmp2="$poF2.tmp"



LANG=C
# Whether pulled matches the pot
[ $verbose -gt 0 ] && echo "Info: Matching ${poF2} with ${potF}" > /dev/stderr
potPullDiff=`msgcomm -u --no-wrap "${poF2}" "${potF}"`
if [ -n "${potPullDiff}" ];then
    echo "Error: ${poF2} does not match ${potF}" > /dev/stderr
    echo "${potPullDiff}"  > /dev/stderr
    exit 1
fi

[ $verbose -gt 0 ] && echo "Info: Does ${poF2} has every valid messages in ${poF1} " > /dev/stderr
# header need to be cut
msgcomm -s --more-than 1 --no-wrap --no-location "${poF1}" "${poF2}" > ${tmp1}
msgcomm -s --more-than 1 --no-wrap --no-location "${poF2}" "${poF1}" > ${tmp2}

if [ -s ${tmp1} ]; then
    csplit -s -f ${tmpPrefix}S ${tmp1} '/^\s*$/1'
else
    rm -f ${tmpPrefix}S01; touch ${tmpPrefix}S01
fi
if [ -s ${tmp2} ]; then
    csplit -s -f ${tmpPrefix}T ${tmp2} '/^\s*$/1'
else
    rm -f ${tmpPrefix}T01; touch ${tmpPrefix}T01
fi
ret=0

# Compare the tail part
if diff $quietOpt ${tmpPrefix}S01 ${tmpPrefix}T01; then
    echo "${poF1} and ${poF2} are equivalent"
    rm -f ${tmpPrefix}?0?  ${tmp1} ${tmp2}
else
    ret=1
    echo "Error: ${poF1} and ${poF2} are NOT equivalent"  > /dev/stderr
fi
exit ${ret}

