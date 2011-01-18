#!/usr/bin/env sh
# If publican.cfg exists, this script does a publican update,
# otherwise do noting except linking pom.xml
scriptDir=`dirname $0`
langs=$1
cmake_home_dir=$2

if [ -e /usr/bin/publican ] ; then
    if [ -e publican.cfg ]; then
	sed -e "s/brand:.*//" publican.cfg > publican.cfg.striped
	publican update_pot --config publican.cfg.striped \
	&& publican update_po --config publican.cfg.striped --langs ${langs}
    fi
fi

ln -sf $cmake_home_dir/pom.xml pom.xml

