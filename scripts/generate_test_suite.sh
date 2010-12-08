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
    Projmant ) # Project maintainer
	USR=autoprojmant
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

HOME_PAGE_FILE="HomePage.html"
SIGN_IN_FILE="SignIn${testRole}.html"
SI_PATTERN_MATCH="</b></td></tr>"
SI_PATTERN_REPLACE="${SI_PATTERN_MATCH}\n\
    <tr><td><a href=\"${HOME_PAGE_FILE}\">Home Page</a></td></tr>\n\
    <tr><td><a href=\"${SIGN_IN_FILE}\">${testRole} Sign In</a></td></tr>"

SIGN_OUT_FILE="SignOut.html"
SO_PATTERN_MATCH="</tbody>"
SO_PATTERN_REPLACE="<tr><td><a href=\"${SIGN_OUT_FILE}\">Sign Out</a></td></tr>\n${SO_PATTERN_MATCH}"

### Write Selenium test files
siSuite=${testSuiteDir}/${SI}-${testSuiteName}.html
cat ${testSuiteDir}/0-${testSuiteName}.html | sed -e "s|${SI_PATTERN_MATCH}|${SI_PATTERN_REPLACE}|" > ${siSuite}

siSoSuite=${testSuiteDir}/${SISO}-${testSuiteName}.html
cat ${siSuite} | sed -e "s|${SO_PATTERN_MATCH}|${SO_PATTERN_REPLACE}|" > ${siSoSuite}

############################################################
# File generation

HOME_PAGE_PATH="${testSuiteDir}/HomePage.html"
cat >> ${HOME_PAGE_PATH} <<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head profile="http://selenium-ide.openqa.org/profiles/test-case">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <link rel="selenium.base" href="${SERVER_BASE}" />
    <title>SignIn${testRole}</title>
</head>
<body>
    <table cellpadding="1" cellspacing="1" border="1">
        <thead>
	    <tr><td rowspan="1" colspan="3">Home Page</td></tr>
	</thead>
	<tbody>
	    <tr>
		<td>open</td>
		<td>${SERVER_PATH}</td>
		<td></td>
	    </tr>
	</tbody>
    </table>
</body>
</html>
END

SIGN_IN_PATH="${testSuiteDir}/${SIGN_IN_FILE}"
cat >> ${SIGN_IN_PATH} <<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head profile="http://selenium-ide.openqa.org/profiles/test-case">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <link rel="selenium.base" href="${SERVER_BASE}" />
    <title>SignIn${testRole}</title>
</head>
<body>
    <table cellpadding="1" cellspacing="1" border="1">
        <thead>
	    <tr><td rowspan="1" colspan="3">SignIn${testRole}</td></tr>
	</thead>
	<tbody>
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
		<td>css=ul#message&gt;li:contains("Welcome")</td>
		<td></td>
	    </tr>
	</tbody>
    </table>
</body>
</html>
END

SIGN_OUT_FILE="${testSuiteDir}/SignOut.html"
cat >> ${SIGN_OUT_FILE} <<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head profile="http://selenium-ide.openqa.org/profiles/test-case">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <link rel="selenium.base" href="${SERVER_BASE}" />
    <title>SignIn${testRole}</title>
</head>
<body>
    <table cellpadding="1" cellspacing="1" border="1">
        <thead>
	    <tr><td rowspan="1" colspan="3">SignOut</td></tr>
	</thead>
	<tbody>
	    <tr>
		<td>clickAndWait</td>
		<td>link=Sign Out</td>
		<td></td>
	    </tr>
	</tbody>
    </table>
</body>
</html>
END


