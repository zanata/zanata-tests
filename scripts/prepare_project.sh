#!/usr/bin/env sh
# Once complete successfully, a file named "$stamp" is touched.
# If publican.cfg exists, this script does a publican update,
# otherwise do noting except touching "$stamp"
langs=$1
stamp=$2

if [ -e /usr/bin/publican ] ; then
    if [ -e publican.cfg ]; then
	sed -e "s/brand:.*//" publican.cfg > publican.cfg.striped
	publican update_pot --config publican.cfg.striped \
	&& publican update_po --config publican.cfg.striped --langs ${langs}
    fi
fi

touch ${stamp}

