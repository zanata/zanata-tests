#!/bin/sh
# Usage: $0 <testRole> <testSuitePath> <testSuiteName> <siOut> <siSoOut>

testRole=$1
testSuitePath=$2
testSuiteName=$3
siOut=$4
siSoOut=$5
testRoot=$6

if [ -z ${FLIES_URL} ]; then
    source ./test.cfg
fi

SI_PATTERN_MATCH="</b></td></tr>"
case $testRole in
        'ADMIN' )
            SIGN_IN_FILE=${SIGN_IN_FILE_ADMIN}
            ;;
        * )
            SIGN_IN_FILE=${SIGN_IN_FILE_NORMAL}
            ;;
esac
SI_PATTERN_REPLACE="${SI_PATTERN_MATCH}\n<tr><td><a href=\"${SIGN_IN_FILE}\">${testRole} Sign In</a></td></tr>"
ln -sf ${PWD}/${FUNCTIONS_DIR}/${SIGN_IN_FILE} ${testSuitePath}

SO_PATTERN_MATCH="</tbody>"
SO_PATTERN_REPLACE="<tr><td><a href=\"${SIGN_OUT_FILE}\">Sign Out</a></td></tr>\n${SO_PATTERN_MATCH}"
ln -sf ${PWD}/${FUNCTIONS_DIR}/${SIGN_OUT_FILE} ${testSuitePath}

### Write Selenium test files
cat ${testSuitePath}/0-${testSuiteName}.html | sed -e "s|${SI_PATTERN_MATCH}|${SI_PATTERN_REPLACE}|" > ${testSuitePath}/${siOut}
cat ${testSuitePath}/${siOut} | sed -e "s|${SO_PATTERN_MATCH}|${SO_PATTERN_REPLACE}|" > ${testSuitePath}/${siSoOut}

