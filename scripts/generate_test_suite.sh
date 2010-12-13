#!/bin/bash
# Usage: $0 <cfgFile> <testRole> <testSuiteDir> <testSuiteName>

function print_usage(){
    echo "$0 <cfgFile> <testRole> <testSuiteDir> <testSuiteName>"
}

for para in cfgFile testRole testSuiteDir testSuiteName; do
    if [ -z $1 ];then
	print_usage
	exit -1
    fi

    eval "$para=$1"
    shift
    value=$(eval echo \$$para)
    #echo $para=${value}
done


if [ -z ${FLIES_URL} ] || [ -z ${FUNCTIONS_DIR} ]; then
    source ${cfgFile}
fi
HOME_PAGE_FILE="HomePage.html"
HOME_PAGE_PATH="${testSuiteDir}/${HOME_PAGE_FILE}"
SIGN_IN_FILE="SignIn${testRole}.html"
SIGN_IN_PATH="${testSuiteDir}/${SIGN_IN_FILE}"
SIGN_OUT_FILE="SignOut.html"
SIGN_OUT_PATH="${testSuiteDir}/${SIGN_OUT_FILE}"

#testRoles=`echo ${TEST_ROLES} | sed -e 's/;/ /'`
#echo "testRoles=${testRoles}"

# SI: Suite with Sign In
# SISO: Suite with Sign In and Sign Out

case $testRole in
    Admin )
	USR=admin
	SI=1
	SISO=2
	;;
    Prjmant ) # Project maintainer
	USR=autoprjmant
	SI=3
	SISO=4
	;;
    Trans )
        USR=autotrans
	SI=5
	SISO=6
	;;
    Login )
	USR=autologin
	SI=7
	SISO=8
	;;
esac

SI_PATTERN_MATCH="</b></td></tr>"
SI_PATTERN_REPLACE="${SI_PATTERN_MATCH}\n\
    <tr><td><a href=\"${HOME_PAGE_FILE}\">Home Page</a></td></tr>\n\
    <tr><td><a href=\"${SIGN_IN_FILE}\">${testRole} Sign In</a></td></tr>"

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
    SERVER_BASE=$2
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
if [ ! -e  ${HOME_PAGE_PATH} ]; then
    print_header ${HOME_PAGE_PATH} ${SERVER_BASE} "Home Page"
    cat >> ${HOME_PAGE_PATH} <<END
<tr>
    <td>open</td>
    <td>${SERVER_PATH}</td>
    <td></td>
</tr>
END
    print_footer ${HOME_PAGE_PATH}
fi

### Print SignIn${testRole}.html
print_header ${SIGN_IN_PATH} ${SERVER_BASE} "SignIn${testRole}"
cat >> ${SIGN_IN_PATH} <<END
<tr>
    <td>clickAndWait</td>
    <td>Sign_in</td>
    <td></td>
</tr>
<tr>
    <td>type</td>
    <td>login:usernameField:username</td>
    <td>${USR}</td>
</tr>
<tr>
    <td>type</td>
    <td>login:passwordField:password</td>
    <td>${USR}</td>
</tr>
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

### Print SignOut.html
if [ ! -e  ${SIGN_OUT_PATH} ]; then
    print_header ${SIGN_OUT_PATH} ${SERVER_BASE} "SignOut"
    cat >> ${SIGN_OUT_PATH} <<END
    <tr>
	<td>clickAndWait</td>
	<td>link=Sign Out</td>
	<td></td>
    </tr>
END
    print_footer ${SIGN_OUT_PATH}
fi


