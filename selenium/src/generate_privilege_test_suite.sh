#!/bin/sh
# Usage: $0 <privilege_test_cases_path>
if [ $# -ne 1 ]; then
    echo "Usage: $0 <privilege_test_cases_path>"
    exit 1
fi

echo "Generating privilege test suite.."
TEST_CASES_PATH=$1

source ./test.cfg
pushd ${TEST_CASES_PATH}
### remove old generation file.
rm -f Issue*.prelogin.html
rm -f Issue*.normal.html

### Header for prelogin
cat > ${PRESIGNIN_TEST_SUITE} << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta content="text/html; charset=UTF-8" http-equiv="content-type" />
    <title>Prelogin Privilege Test Suite</title>
</head>
<body>
<table id="suiteTable" cellpadding="1" cellspacing="1" border="1" class="selenium"><tbody>
<tr><td><b>Prelogin Privilege Test Suite</b></td></tr>
EOF

### Header for normal user
cat > ${NORMAL_TEST_SUITE} << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta content="text/html; charset=UTF-8" http-equiv="content-type" />
    <title>Normal User Privilege Test Suite</title>
</head>
<body>
<table id="suiteTable" cellpadding="1" cellspacing="1" border="1" class="selenium"><tbody>
<tr><td><b>Normal User Privilege Test Suite</b></td></tr>
EOF

for testCase in Issue*.html;do
    ### For prelogin
    testName=`basename $testCase .html`
    preLogin="${testName}.prelogin.html"
    sed -f prelogin.pattern $testCase > ${preLogin}
    if [ -f ${preLogin} ]; then
	echo "<tr><td><a href=\"${preLogin}\">${testName}</a></td></tr>" >> ${PRESIGNIN_TEST_SUITE}
    else
	echo "<tr><td><a href=\"${testCase}\">${testName}</a></td></tr>" >> ${PRESIGNIN_TEST_SUITE}
    fi

    ### For Normal user
    normalLogin="${testName}.normal.html"
    sed -f normal.pattern $testCase > ${normalLogin}
    if [ -f ${normalLogin} ]; then
	echo "<tr><td><a href=\"${normalLogin}\">${testName}</a></td></tr>" >> ${NORMAL_TEST_SUITE}
    else
	echo "<tr><td><a href=\"${testCase}\">${testName}</a></td></tr>" >> ${NORMAL_TEST_SUITE}
    fi
    echo "  Case $testName is added to test suite."
done

### Footer for prelogin
cat >> ${PRESIGNIN_TEST_SUITE} << EOF
</tbody></table>
</body>
</html>
EOF

### Footer for normal user
cat >> ${NORMAL_TEST_SUITE} << EOF
</tbody></table>
</body>
</html>
EOF
popd

source ./generate_test_suite.sh NORMAL ${TEST_CASES_PATH} ${NORMAL_TEST_SUITE_NAME} ${NORMAL_TEST_SUITE_SI}  ${NORMAL_TEST_SUITE_SISO}


echo "Done generating privilege test suite."

