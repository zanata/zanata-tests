# Test case common part
CLASSNAME=put-project

if [ -n "$USE_DEFAULT" ];then
    if [ -z "${COMMON_OPTIONS}" ];then
	COMMON_OPTIONS=(--url=${ZANATA_URL} --username=${ZANATA_USERNAME} --key=${ZANATA_KEY})
    fi
    : ${ZANATA_PROJECT_NAME:=${ZANATA_PROJECT_SLUG}}
    : ${ZANATA_PROJECT_DESC:=${ZANATA_PROJECT_DESC}}
    : ${ZANATA_PROJECT_TYPE:=gettext}
    if [ -z "${COMPULSORY_OPTIONS}" ];then
	COMPULSORY_OPTIONS=(--project-slug=${ZANATA_PROJECT_SLUG} "--project-name=${ZANATA_PROJECT_NAME}" "--project-desc=${ZANATA_PROJECT_DESC}" "--default-project-type=${ZANATA_PROJECT_TYPE}")
    fi
fi

TestCaseStart "${TEST_CASE_NAME_PREFIX}"
RunCmd ${ZANATA_EXECUTABLE} -B -e ${CLASSNAME} "${COMMON_OPTIONS[@]}" "${COMPULSORY_OPTIONS[@]}" ${OPTIONS[@]}
OutputNoError
exit 0

if [ -n "$CLEAN_OPTIONS" ];then
    unset COMMON_OPTIONS
    unset COMPULSORY_OPTION
    unset OPTIONS
fi
