# Test case common part
CLASSNAME=put-version

if [ -n "$USE_DEFAULT" ];then
    if [ -z "${COMMON_OPTIONS}" ];then
	COMMON_OPTIONS=(--url=${ZANATA_URL} --username=${ZANATA_USERNAME} --key=${ZANATA_KEY})
    fi

    : ${ZANATA_VERSION_SLUG:=master}
    : ${COMPULSORY_OPTIONS:="--version-project=${ZANATA_PROJECT_SLUG}" "--version-slug=${ZANATA_VERSION_SLUG}--project-slug=${ZANATA_PROJECT_SLUG} --project-name=${ZANATA_PROJECT_NAME} --project-desc=${ZANATA_PROJECT_DESC} --default-project-type=${ZANATA_PROJECT_TYPE}"}
fi
COMPULSORY_OPTIONS=("--version-project=${ZANATA_PROJECT_SLUG}" "--version-slug=${ZANATA_VERSION_SLUG}")

TestCaseStart "${TEST_CASE_NAME_PREFIX}"
RunCmd ${ZANATA_EXECUTABLE} -B -e ${CLASSNAME} ${COMMON_OPTIONS[@]} ${COMPULSORY_OPTIONS[@]} ${OPTIONS[@]}
OutputNoError

if [ -n "$CLEAN_OPTIONS" ];then
    unset COMMON_OPTIONS
    unset COMPULSORY_OPTION
    unset OPTIONS
fi
