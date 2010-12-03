#!/bin/bash
# Usage: $0 <cfgFile> <testSuitePath> <testSuiteName>

function print_usage(){
    echo "$0 <cfgFile> <testSuitePath> <testSuiteName>"
}

for para in cfgFile testSuitePath testSuiteName; do
    if [ -z $1 ];then
	print_usage
	exit -1
    fi

    eval "$para=$1"
    shift
    value=$(eval echo \$$para)
    echo $para 1=${value}
done


if [ -z ${FLIES_URL} ] || [ -z ${FUNCTIONS_DIR} ]; then
    source ${cfgFile}
fi

testRoles=`echo ${TEST_ROLES} | sed -e 's/;/ /'`
echo "testRoles=${testRoles}"


SI_PATTERN_MATCH="</b></td></tr>"
case $testRole in
        Admin )
	    PASSWD=admin
            ;;
	Prj ) # Project maintainer
	    SIGN_IN_FILE=${SIGN_IN_FILE_PROJECt}
	    ;;
	Translator )
	    SIGN_IN_FILE=${SIGN_IN_FILE_ADMIN}
	    ;;
	Login )
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

