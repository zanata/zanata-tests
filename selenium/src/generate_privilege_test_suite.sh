#!/bin/sh
# Usage: $0 <privilege_test_cases_path>


if [ $# -ne 1 ]; then
    echo "Usage: $0 <privilege_test_cases_path>"
    exit 1
fi

echo "Generating privilege test suite.."
TEST_CASES_PATH=$1

#=========================================================
# Functions
function print_html_header() {
    FILENAME=$1
    TITLE=$2
    cat > ${FILENAME} << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <meta content="text/html; charset=UTF-8" http-equiv="content-type" />
    <title>${TITLE}</title>
</head>
<body>
EOF
}

function print_html_suite_header() {
    FILENAME=$1
    TITLE=$2
    print_html_header ${FILENAME} "${TITLE}"
    cat >> ${FILENAME} << EOF
<table id="suiteTable" cellpadding="1" cellspacing="1" border="1" class="selenium"><tbody>
    <tr><td><b>${TITLE}</b></td></tr>
EOF
}

function print_html_suite_item() {
    FILENAME="$1"
    HREF="$2"
    TESTNAME="$3"
    echo "	<tr><td><a href=\"${HREF}\">${TESTNAME}</a></td></tr>" >> ${FILENAME}
}

function print_html_case_header() {
    FILENAME=$1
    TITLE=$2
    print_html_header ${FILENAME} "${TITLE}"
    cat >> ${FILENAME} << EOF
<table cellpadding="1" cellspacing="1" border="1">
<thead>
<tr><td rowspan="1" colspan="3">${TITLE}</td></tr>
</thead><tbody>
EOF
}

function print_html_case_item() {
    FILENAME=$1
    CMD=$2
    PARAM1=$3
    PARAM2=$4
    cat >> ${FILENAME} << EOF
<tr>
    <td>${CMD}</td>
    <td>${PARAM1}</td>
    <td>${PARAM2}</td>
</tr>
EOF
}

function print_html_case_item_signin_check() {
    FILENAME=$1
    _url=$2
    print_html_case_item ${FILENAME} open "${_url}"
    print_html_case_item ${FILENAME} verifyText "css=li.warnmsg" "Please log in first"
}

function print_html_case_item_permission_deny() {
    FILENAME=$1
    _url=$2
    print_html_case_item ${FILENAME} open "${_url}"
    print_html_case_item ${FILENAME} verifyTextPresent "You don't have permission to access this resource"
}


function test_case_read_line(){
    OUTPUTFILE=$1
    LINE=$2
    TYPE=`echo "${LINE}" | cut -f 1`
    if [ -z "${TYPE}" ];then
	break
    fi
    case ${TYPE} in
	\#* )
	    break
   	    ;;
        HTTP404 )
	    # They are handled by http404_check.perl
	    break
	    ;;
        PERMISSION )
	    URL=`echo "${LINE}" | cut -f 2`
	    echo "PAT=/${FLIES_PATH}${URL}"
	    print_html_case_item_signin_check ${OUTPUTFILE}.prelogin.html "/${FLIES_PATH}${URL}"
	    print_html_case_item_permission_deny ${OUTPUTFILE}.normal.html "/${FLIES_PATH}${URL}"
	    ;;
        TEXT_PRESENT )
	    TEXT=`echo "${LINE}" | cut -f 2`
	    print_html_case_item ${OUTPUTFILE}.normal.html verifyTextPresent ${TEXT}
	    ;;
        TEXT_NOT_PRESENT )
	    TEXT=`echo "${LINE}" | cut -f 2`
	    print_html_case_item ${OUTPUTFILE}.normal.html verifyTextNotPresent ${TEXT}
	    ;;
        ELEM_PRESENT )
	    LOCATOR=`echo "${LINE}" | cut -f 2`
	    print_html_case_item ${OUTPUTFILE}.normal.html verifyElementPresent ${LOCATOR}
	    ;;
        ELEM_NOT_PRESENT )
 	    LOCATOR=`echo "${LINE}" | cut -f 2`
	    print_html_case_item ${OUTPUTFILE}.normal.html verifyElementNotPresent ${LOCATOR}
	    ;;
	*)
	    ;;
    esac
}


function print_html_footer() {
    FILENAME=$1
    cat >> ${FILENAME} << EOF
</tbody></table>
</body>
</html>
EOF
}

source ./test.cfg
HTTP_404_CHECK_RESULT_REAL=${PWD}/${HTTP_404_CHECK_RESULT}

pushd ${TEST_CASES_PATH}
### remove old generation file.
rm -f Issue*.prelogin.html
rm -f Issue*.normal.html

### Header for prelogin
print_html_suite_header ${PRESIGNIN_TEST_SUITE} "Pre Sign-in Privilege Test Suite"

### Header for normal user
print_html_suite_header ${NORMAL_TEST_SUITE} "Normal user Privilege Test Suite"

for testSuiteRaw in *.suite ;do
    # echo "testSuiteRaw=${testSuiteRaw}"
    testSuiteName=`basename ${testSuiteRaw} .suite`
    print_html_case_header ${testSuiteName}.prelogin.html "${testSuiteName}"
    print_html_case_header ${testSuiteName}.normal.html "${testSuiteName}"
    cat ${testSuiteRaw} | while read _line; do test_case_read_line ${testSuiteName} "${_line}"; done
    print_html_footer ${testSuiteName}.prelogin.html
    print_html_footer ${testSuiteName}.normal.html
done

### For prelogin
for testSuite in Issue*.prelogin.html;do
    testName=`basename ${testSuite} .prelogin.html`
    echo "<tr><td><a href=\"${testSuite}\">${testName}</a></td></tr>" >> ${PRESIGNIN_TEST_SUITE}
    echo "   ${testName}	added to pre sign-in tests."
done

### For Normal user
for testSuite in Issue*.normal.html;do
    testName=`basename ${testSuite} .normal.html`
    echo "<tr><td><a href=\"${testSuite}\">${testName}</a></td></tr>" >> ${NORMAL_TEST_SUITE}
    echo "   ${testName}	added to normal user privilege tests."
done

### Footers
print_html_footer ${PRESIGNIN_TEST_SUITE}
print_html_footer ${NORMAL_TEST_SUITE}

popd

source ./generate_test_suite.sh NORMAL ${TEST_CASES_PATH} ${NORMAL_TEST_SUITE_NAME} ${NORMAL_TEST_SUITE_SI}  ${NORMAL_TEST_SUITE_SISO}

echo "Done generating privilege test suite."

