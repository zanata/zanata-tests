#!/usr/bin/env sh
scriptDir=`dirname $0`
baseDir=$1
proj=$2
ver=$3
fliesUrl=$4
shift 4;


projDir=${baseDir}/${proj}/${ver}

rm -f ${projDir}/flies.xml
cat >> ${projDir}/flies.xml << END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://flies.openl10n.net/config/v1/">
    <url>${fliesUrl}</url>
    <project>${proj}</project>
    <project-version>${ver}</project-version>
    <locales>
END

_langs=`echo $1 | sed -e 's/;/ /g'`

for l in ${_langs}; do
    lDir=`${scriptDir}/find_valid_lang_dir.sh "$projDir" $l`
    if [ -n "$lDir" ]; then
	    echo "        <locale map-from=\"$lDir\">$l</locale>" >> ${projDir}/flies.xml
    fi
done

cat >> ${projDir}/flies.xml << END
    </locales>
</config>
END
