#!/bin/bash
# Usage: $0 <testRole> <testSuiteDir> <testSuiteName> <browser>
# Need HOME_PAGE_FILE
# Selenium html suite cannot stop when assert statement in a test case is
# failed.

_scriptDir=`dirname $0`
#PARAMS=(testRole testSuiteDir testSuiteName browser)
PARAMS="testRole testSuiteDir testSuiteName browser"
source ${_scriptDir}/test_common_func.sh


HOME_PAGE_PATH="${testSuiteDir}/${HOME_PAGE_FILE}"
HOME_PAGE_FILE="HomePage.html"
SIGN_IN_FILE="SignIn${testRole}.html"
SIGN_IN_PATH="${testSuiteDir}/${SIGN_IN_FILE}"
SIGN_OUT_FILE="SignOut.html"
SIGN_OUT_PATH="${testSuiteDir}/${SIGN_OUT_FILE}"


############################################################
# File generation

function print_suite_header(){
    file=$1
    cat >> ${flie} <<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <meta content="text/html; charset=UTF-8" http-equiv="content-type" />
    <title>Test Suite</title>
</head>
<body>
<table id="suiteTable" cellpadding="1" cellspacing="1" border="1" class="selenium">
<tbody>
    <tr><td><b>Test Suite</b></td></tr>
END
}

function print_suite_footer(){
    file=$1
cat >> ${flie} <<END
</tbody>
</table>
</body>
</html>
END
}

ROLE_LOGIN_CHECK_SUITE="${testSuiteDir}/${testRole}-LoginCheckSuite.html"
print_suite_header ${ROLE_LOGIN_CHECK_SUITE}
cat >> ${ROLE_LOGIN_CHECK_SUITE} <<END
    <tr><td><a href="${HOME_PAGE_FILE}">Home Page</a></td></tr>
    <tr><td><a href="${SIGN_IN_FILE}">SignIn${testRole}</a></td></tr>
END
print_suite_footer ${ROLE_LOGIN_CHECK_SUITE}

### print run_selenium_${browser}


