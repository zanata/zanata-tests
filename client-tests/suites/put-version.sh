# Test case common part
CLASSNAME=put-version

if [ -n "$USE_DEFAULT" ];then
    if [ -z "${COMMON_OPTIONS}" ];then
	COMMON_OPTIONS=(--url=${ZANATA_URL} --username=${ZANATA_USERNAME} --key=${ZANATA_KEY})
    fi
    : ${ZANATA_VERSION_SLUG:=master}

    if [ -z "${COMPULSORY_OPTIONS}" ];then
	COMPULSORY_OPTIONS=("--version-project=${ZANATA_PROJECT_SLUG}" "--version-slug=${ZANATA_VERSION_SLUG}")
    fi

fi

TestCaseStart "${TEST_CASE_NAME_PREFIX}"
RunCmd ${ZANATA_EXECUTABLE} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} ${OPTIONS[@]}
OutputNoError

if [ -n "$CLEAN_OPTIONS" ];then
    unset COMMON_OPTIONS
    unset COMPULSORY_OPTION
    unset OPTIONS
fi
