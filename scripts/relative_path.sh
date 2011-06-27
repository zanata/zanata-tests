#!/usr/bin/env bash
# Usage: $0 <src> <dst>

scriptDir=`dirname $0`
src=$1
dst=$2

src_real=`${scriptDir}/real_path.sh ${src}`
dst_real=`${scriptDir}/real_path.sh ${dst}`

common_part=$src_real
back=
while [ "${dst_real#$common_part}" = "${dst_real}" ]; do
  common_part=$(dirname $common_part)/
  back="../${back}"
done

echo ${back}${dst_real#$common_part}

