#!/usr/bin/env bash
# $0 - Return the absolute path
# Usage: $0 <path>
#

p=$1

if [ -d $p ]; then
    _p_filename=
    _p_dir=$p
else
    _p_filename=`basename $p`
    _p_dir=`dirname $p`
fi

pushd $_p_dir > /dev/null
_p_real_dir=`pwd`
popd > /dev/null
echo ${_p_real_dir}/${_p_filename}

