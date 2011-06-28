#!/usr/bin/env sh
scriptDir=`dirname $0`
baseDir=$1
zanataUrl=$2
proj=$3
shift 3;

# ver="" means project only
if [ -n "$1" ];then
    ver=$1
    shift
else
    ver=
fi
langList=$1

projDir=${baseDir}/${proj}/${ver}

rm -f ${projDir}/zanata.xml
cat > ${projDir}/zanata.xml << END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://zanata.org/namespace/config/">
    <url>${zanataUrl}</url>
    <project>${proj}</project>
END

if [ -n "$ver" ]; then
    echo "    <project-version>${ver}</project-version>" >> ${projDir}/zanata.xml
    echo "    <locales>" >> ${projDir}/zanata.xml

    _langs=`echo $langList | sed -e 's/;/ /g'`

    for _l in ${_langs}; do
	_lDir=`${scriptDir}/find_valid_lang_dir.sh "$projDir" $_l`
	if [ -n "${_lDir}" ]; then
	    echo "        <locale map-from=\"${_lDir}\">$_l</locale>" >> ${projDir}/zanata.xml
	fi
    done
    echo "    </locales>" >> ${projDir}/zanata.xml
fi



cat >> ${projDir}/zanata.xml << END
</config>
END
