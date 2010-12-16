#!/usr/bin/env sh
baseDir=$1
proj=$2
ver=$3
shift 3;

function findLangDir(){
    projDir=$1
    langNameTemplate=$2
    basename `find $projDir -type d -name "${langNameTemplate}"`
}

projDir=${baseDir}/${proj}/${ver}

rm -f ${projDir}/flies.xml
cat >> ${projDir}/flies.xml << END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://flies.openl10n.net/config/v1/">
    <url>${FLIES_URL}</url>
    <project>${proj}</project>
    <project-version>${ver}</project-version>
    <locales>
END

_langs=`echo $1 | sed -e 's/;/ /g'`

for l in ${_langs}; do
    case $l in
	ja* )
	    lDir=findLangDir $projDir "ja*"
	    echo "        <locale map-from=\"$lDir\">ja</locale>" >> ${projDir}/flies.xml
	    ;;
	zh*CN )
	    lDir=findLangDir $projDir "zh*CN"
	    echo "        <locale map-from=\"$lDir\">zh-Hans-CN</locale>" >> ${projDir}/flies.xml
	    ;;
	zh*TW)
	    lDir=findLangDir $projDir "zh*TW"
	    echo "        <locale map-from=\"$l\">zh-Hant-TW</locale>" >> ${projDir}/flies.xml
	    ;;
	*)
	    echo "        <locale>${l}</locale>" >> ${projDir}/flies.xml
	    ;;
    esac
done

cat >> ${projDir}/flies.xml << END
    </locales>
</config>
END
