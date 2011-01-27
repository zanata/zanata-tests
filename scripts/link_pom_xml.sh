#!/usr/bin/env sh
# If publican.cfg exists, this script does a publican update,
# otherwise do noting except linking pom.xml
scriptDir=`dirname $0`
cmake_home_dir=$1

touch $cmake_home_dir/pom.xml
ln -sf $cmake_home_dir/pom.xml pom.xml

