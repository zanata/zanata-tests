#!/bin/bash
# Usage: $0 <testRole> <testSuiteDir> <testSuiteName> <serverBase>
# <serverPath> <testUser> <testPass> <sisoIndex> <authMethod> <loginFieldId>
# <passwordFieldId>

_scriptDir=`dirname $0`
PARAMS="testRole testSuiteDir testSuiteName serverBase serverPath testUser testPass sisoIndex authMethod loginFieldId passwordFieldId"
source ${_scriptDir}/test_common_func.sh

HOME_PAGE_FILE="HomePage.html"
#HOME_PAGE_PATH="${testSuiteDir}/${HOME_PAGE_FILE}"
SIGN_IN_FILE="SignIn${testRole}.html"
SIGN_IN_PATH="${testSuiteDir}/${SIGN_IN_FILE}"
SIGN_OUT_FILE="SignOut.html"
SIGN_OUT_PATH="${testSuiteDir}/${SIGN_OUT_FILE}"

#testRoles=`echo ${TEST_ROLES} | sed -e 's/;/ /'`
#echo "testRoles=${testRoles}"

# SI: Suite with Sign In
# SISO: Suite with Sign In and Sign Out

SISO=$sisoIndex
SI=`expr $sisoIndex - 1`
SIGN_IN_TITLE="${testUser} Sign In"

SI_PATTERN_MATCH="</b></td></tr>"
SI_PATTERN_REPLACE="${SI_PATTERN_MATCH}\n\
    <tr><td><a href=\"${HOME_PAGE_FILE}\">Home Page</a></td></tr>\n\
    <tr><td><a href=\"${SIGN_IN_FILE}\">${SIGN_IN_TITLE}</a></td></tr>"

SO_PATTERN_MATCH="</tbody>"
SO_PATTERN_REPLACE="<tr><td><a href=\"${SIGN_OUT_FILE}\">Sign Out</a></td></tr>\n${SO_PATTERN_MATCH}"

### Write Selenium test files
siSuite=${testSuiteDir}/${SI}-${testSuiteName}.html
cat ${testSuiteDir}/0-${testSuiteName}.html | sed -e "s|${SI_PATTERN_MATCH}|${SI_PATTERN_REPLACE}|" > ${siSuite}

siSoSuite=${testSuiteDir}/${SISO}-${testSuiteName}.html
cat ${siSuite} | sed -e "s|${SO_PATTERN_MATCH}|${SO_PATTERN_REPLACE}|" > ${siSoSuite}

############################################################
# File generation

function print_header(){
    file=$1
    serverBase=$2
    TITLE=$3

    cat >> ${file} <<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head profile="http://selenium-ide.openqa.org/profiles/test-case">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <link rel="selenium.base" href="" />
    <title>${TITLE}</title>
</head>
<body>
<table cellpadding="1" cellspacing="1" border="1">
<thead>
<tr><td rowspan="1" colspan="3">${TITLE}</td></tr>
</thead>
<tbody>
END
}

function print_footer(){
    file=$1

    cat >> ${file} <<END
</tbody>
</table>
</body>
</html>
END
}

### Print HomePage.html
#echo "serverPath=${serverPath}"
#if [ ! -e  ${HOME_PAGE_PATH} ]; then
#    print_header ${HOME_PAGE_PATH} "${serverBase}" "Home Page"
#    cat >> ${HOME_PAGE_PATH} <<END
#<tr>
#    <td>open</td>
#    <td>${serverPath}</td>
#    <td></td>
#</tr>
#END
#    print_footer ${HOME_PAGE_PATH}
#fi

### Print SignIn${testRole}.html
if [ ! -e  ${SIGN_IN_PATH} ]; then
    print_header ${SIGN_IN_PATH} "${serverBase}" "${SIGN_IN_TITLE}"
    cat >> ${SIGN_IN_PATH} <<END
<tr>
    <td>clickAndWait</td>
    <td>Sign_in</td>
    <td></td>
</tr>
END

cat >> ${SIGN_IN_PATH} <<END
<tr>
    <td>type</td>
    <td>${loginFieldId}</td>
    <td>${testUser}</td>
</tr>
END

if [ ! "${passwordFieldId}" = "NONE" ]; then
    cat >> ${SIGN_IN_PATH} <<END
<tr>
    <td>type</td>
    <td>${passwordFieldId}</td>
    <td>${testPass}</td>
</tr>
END
fi

cat >> ${SIGN_IN_PATH} <<END
<tr>
    <td>clickAndWait</td>
    <td>login:Sign_in</td>
    <td></td>
</tr>
<tr>
    <td>assertElementPresent</td>
    <td>css=ul#messages&gt;li:contains("Welcome")</td>
    <td></td>
</tr>
END
    print_footer ${SIGN_IN_PATH}
fi

### Print SignOut.html
if [ ! -e  ${SIGN_OUT_PATH} ]; then
    print_header ${SIGN_OUT_PATH} "${serverBase}" "SignOut"
    cat >> ${SIGN_OUT_PATH} <<END
    <tr>
	<td>clickAndWait</td>
	<td>link=Sign Out</td>
	<td></td>
    </tr>
END
    print_footer ${SIGN_OUT_PATH}
fi


