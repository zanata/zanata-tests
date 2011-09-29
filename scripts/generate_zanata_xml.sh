#!/usr/bin/env bash
# Generate zanata.xml
#
function print_usage(){
cat <<END
$0 - Generate zanata.xml
Usage: $0 [-h] [-v ver] [-l langList] [-t projType] -z [PathTo-zanata.xml] baseDir zanataUrl proj
Options:
 -h: Print this help.
 -v [ver]: specify version
 -l langList: Specify language list, split by ';'
 -t projType: Specify project type: gettext, podir, properties, xliff
 -z PathTo_zanata.xml: path to zanata.xml from current dir, or absolute path.
Parameters:
 baseDir: Base working dir.
 zanataUrl: URL to Zanata server
 proj; project ID
END
}

ver=
langList=
zanata_xml=
projType=podir
while getopts "hl:t:v:z:" opt; do
    case $opt in
	h)
	    print_usage
	    exit 0
	    ;;
	l)
	    langList=$OPTARG
	    ;;
	t)
	    projType=$OPTARG
	   ;;
	v)
	    ver=$OPTARG
	    ;;
	z)
	    zanata_xml=$OPTARG
	   ;;
       esac
done
shift $((OPTIND-1));

scriptDir=`dirname $0`
baseDir=$1
zanataUrl=$2
proj=$3
if [ -z "$zanata_xml" ]; then
    zanata_xml=${baseDir}/zanata.xml
fi

function find_valid_lang_file(){
    base=$1
    case $2 in
	zh*CN | zh*Hans* )
	    l="zh*CN"
	    ;;
	zh*TW | zh*Hant* )
	    l="zh*TW"
	    ;;
	* )
	    l=$2
	    ;;
    esac

    find $base -name "${l}*.po" -exec echo '{}' \;
}

rm -f ${zanata_xml}
cat > ${zanata_xml} << END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://zanata.org/namespace/config/">
    <url>${zanataUrl}</url>
    <project>${proj}</project>
    <project-type>${projType}</project-type>
END

if [ -n "$ver" ]; then
    echo "    <project-version>${ver}</project-version>" >> $zanata_xml
    echo "    <locales>" >> $zanata_xml

    _langs=`echo $langList | sed -e 's/;/ /g'`

    # Insert locales to zanata.xml
    for _l in ${_langs}; do
	_lRet=

	# For properties and xliff, try not find existing translation.
	# For other types, it find existing translation and set the mapping.

	case $projType in
	    gettext)
		_lRet=`${scriptDir}/find_valid_langs.sh -f $baseDir $_l | sed -e 's/\.po//'`
		;;

	    properties | xliff)
		_lRet=$_l
		;;
	    *)
		# podir
		_lRet=`${scriptDir}/find_valid_langs.sh "$baseDir" $_l`
		;;

	esac
	# echo "_lRet=|${_lRet}|"
	if [ -n "${_lRet}" ]; then
	    if [ "${_lRet}" = "${_l}" ]; then
		echo "        <locale>$_l</locale>" >> $zanata_xml
	    else
		echo "        <locale map-from=\"${_lRet}\">$_l</locale>" >> $zanata_xml
	    fi
	fi
    done
    echo "    </locales>" >> $zanata_xml
fi



cat >> $zanata_xml << END
</config>
END
