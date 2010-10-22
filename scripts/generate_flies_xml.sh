#!/usr/bin/env sh
baseDir=$1
proj=$2
ver=$3
shift 3;

projDir=${baseDir}/${proj}/${ver}

rm -f ${projDir}/flies.xml
cat >> ${projDir}/flies.xml << END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://flies.openl10n.net/config/v1/">
    <url>http://localhost:8080/flies/</url>
    <project>${proj}</project>
    <project-version>${ver}</project-version>
    <locales>
END

for l in "$@"; do
    echo "        <locale>${l}</locale>" >> ${projDir}/flies.xml
done

cat >> ${projDir}/flies.xml << END
    </locales>
</config>
END
