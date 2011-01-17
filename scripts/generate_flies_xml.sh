#!/usr/bin/env sh
baseDir=$1
proj=$2
ver=$3
shift 3;

function findLangDir(){
    projDir=$1
    langNameTemplate=$2
    dirFound=`find ${projDir}  -wholename "*/$langNameTemplate/*.po"`
    if [ -n "${dirFound}" ]; then
       basename $(dirname `echo "${dirFound}" | head --lines=1`)
    else
        echo "findLangDir(): $langNameTemplate is not found in $projDir" > /dev/stderr
    fi
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
	    lDir=`findLangDir $projDir "ja*"`
           tagContent="ja"
	    ;;
	zh*CN )
	    lDir=`findLangDir $projDir "zh*CN"`
           tagContent="zh-Hans-CN"
	    ;;
	zh*TW)
	    lDir=`findLangDir $projDir "zh*TW"`
           tagContent="zh-Hant-TW"
	    ;;
	*)
           tagContent=$l
	    ;;
    esac
    if [ -n "$lDir" ]; then
	    echo "        <locale map-from=\"$lDir\">$tagContent</locale>" >> ${projDir}/flies.xml
    fi
done

cat >> ${projDir}/flies.xml << END
    </locales>
</config>
END
