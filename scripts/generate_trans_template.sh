#!/usr/bin/env sh
# Generate translation template files (such as .pot)
# And translation files (such as .po)

function print_usage(){
    cat <<END
$0 - Generate translation template files (.pot and .po)
Usage: $0 [-h] lang [command]
Options:
    -h: Print this help.
    lang: language locale to be generate
    command: Optional command to generate pot and po
END
}

langs=
cmd=
while getopts "h" opt; do
    case $opt in
	h)
	    print_usage
	    exit 0
	    ;;
    esac
done
shift $((OPTIND-1));

scriptDir=`dirname $0`

# If publican.cfg exists, this script does a publican update,
# otherwise do nothing.
langs=$1
if [ -z "$langs" ] ;then
    print_usage
    exit 0
fi
if [ -n "$2" ] ; then
    cmd="$2";
fi

_langs=`echo $langs | sed -e 's/;/ /g'`
_first=1
_langs_final=
for l in ${_langs};
do
    lDir=`${scriptDir}/find_valid_langs.sh . $l`
    if [ -n "$lDir" ];then
	if [ "$_first" = "0" ]; then
	    _langs_final="${_langs_final},"
	else
	    _first=0
	fi
	_l=`basename $lDir`
	_langs_final="${_langs_final}${_l}"
    fi
done
#echo "_langs_final=${_langs_final}"

if [ -e publican.cfg ]; then
    if [ -n `which publican` ] ; then
	sed -e "s/brand:.*//" publican.cfg > publican.cfg.striped
	publican update_pot --config publican.cfg.striped \
	&& publican update_po --config publican.cfg.striped --langs ${_langs_final}
    else
	echo "[Error] publican is not installed" > /dev/stderr
	exit 1
    fi
else
    [ -n "$cmd" ] && $cmd
    touch publican.cfg.striped
fi
exit 0

