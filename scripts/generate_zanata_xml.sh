#!/usr/bin/env bash
# Generate zanata.xml
#
function print_usage(){
cat <<END
$0 - Generate zanata.xml
Usage: $0 [-h] [-v ver] [-l langList] -z [PathTo-zanata.xml] baseDir zanataUrl proj
Options:
 -h: Print this help.
 -v [ver]: specify version
 -l [langList]: Specify language list, split by ';'
 -z [PathTo_zanata.xml]: path to zanata.xml from current dir, or absolute path.
Parameters:
 baseDir: Base working dir.
 zanataUrl: URL to Zanata server
 proj; project ID
END
}

ver=
langList=
zanata_xml=
while getopts "hv:l:z:" opt; do
    case $opt in
	h)
	    print_usage
	    exit 0
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

rm -f ${zanata_xml}
cat > ${zanata_xml} << END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://zanata.org/namespace/config/">
    <url>${zanataUrl}</url>
    <project>${proj}</project>
END

if [ -n "$ver" ]; then
    echo "    <project-version>${ver}</project-version>" >> $zanata_xml
    echo "    <locales>" >> $zanata_xml

    _langs=`echo $langList | sed -e 's/;/ /g'`

    for _l in ${_langs}; do
	_lDir=`${scriptDir}/find_valid_lang_dir.sh "$baseDir" $_l`
	if [ -n "${_lDir}" ]; then
	    echo "        <locale map-from=\"${_lDir}\">$_l</locale>" >> $zanata_xml
	fi
    done
    echo "    </locales>" >> $zanata_xml
fi



cat >> $zanata_xml << END
</config>
END
