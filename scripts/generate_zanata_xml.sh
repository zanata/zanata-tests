#!/usr/bin/env sh
scriptDir=`dirname $0`
baseDir=$1
proj=$2
ver=$3
zanataUrl=$4
shift 4;


projDir=${baseDir}/${proj}/${ver}

rm -f ${projDir}/zanata.xml
cat >> ${projDir}/zanata.xml << END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://zanata.org/namespace/config/">
    <url>${zanataUrl}</url>
    <project>${proj}</project>
    <project-version>${ver}</project-version>
    <locales>
END

_langs=`echo $1 | sed -e 's/;/ /g'`

for l in ${_langs}; do
    lDir=`${scriptDir}/find_valid_lang_dir.sh "$projDir" $l`
    if [ -n "$lDir" ]; then
	    echo "        <locale map-from=\"$lDir\">$l</locale>" >> ${projDir}/zanata.xml
    fi
done

cat >> ${projDir}/zanata.xml << END
    </locales>
</config>
END
