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
 -g: gettext mode
Parameters:
 baseDir: Base working dir.
 zanataUrl: URL to Zanata server
 proj; project ID
END
}

ver=
langList=
zanata_xml=
gettext_mode=0
projType=podir
while getopts "hv:l:t:z:g" opt; do
    case $opt in
	h)
	    print_usage
	    exit 0
	    ;;
	g)
	    gettext_mode=1
	    ;;
	t)
	    projType=$OPTARG
	   ;;
	v)
	    ver=$OPTARG
	    ;;
	l)
	    langList=$OPTARG
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

    for _l in ${_langs}; do
	_lRet=
	if [ $gettext_mode -eq 1 ]; then
	    _lRet=`${scriptDir}/find_valid_langs.sh -f $baseDir $_l | sed -e 's/\.po//'`
#		echo "_lRet=|${_lRet}|"
	else
	    _lRet=`${scriptDir}/find_valid_langs.sh "$baseDir" $_l`
	fi
	if [ -n "${_lRet}" ]; then
	    echo "        <locale map-from=\"${_lRet}\">$_l</locale>" >> $zanata_xml
	fi
    done
    echo "    </locales>" >> $zanata_xml
fi



cat >> $zanata_xml << END
</config>
END
