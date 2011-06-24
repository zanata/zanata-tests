#!/usr/bin/env bash
# Usage: $0 <src> <dst>

src=$1
dst=$2
pushd $src > /dev/null
src_real=`pwd`
popd > /dev/null
#echo "src_real=$src_real"

if [ -d $dst ]; then
    dst_filename=
    dst_dir=$dst
else
    dst_filename=`basename $dst`
    dst_dir=`dirname $dst`
fi
pushd $dst_dir > /dev/null
dst_real_dir=`pwd`
popd > /dev/null
dst_real=${dst_real_dir}/${dst_filename}
#echo dst_real=$dst_real


common_part=$src_real/
back=
while [ "${dst_real#$common_part}" = "${dst_real}" ]; do
  common_part=$(dirname $common_part)/
  back="../${back}"
#  echo common_part=$common_part
#  echo back=$back
done

echo ${back}${dst_real#$common_part}



