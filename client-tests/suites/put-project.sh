# Test case common part
CLASSNAME=put-project
unset local_args

if [ -n "$USE_DEFAULT_OPTIONS" ];then
    unversal_option_get_default_executable local_args
fi

### Add subCommand
local_args+=( $CLASSNAME )

if [ -n "$USE_DEFAULT_OPTIONS" ];then
    unversal_option_get_default_auth local_args
    : ${ZANATA_PROJECT_NAME:=${ZANATA_PROJECT_SLUG}}
    : ${ZANATA_PROJECT_DESC:=${ZANATA_PROJECT_DESC}}
    : ${ZANATA_PROJECT_TYPE:=gettext}
    local_args+=(--project-slug=${ZANATA_PROJECT_SLUG} "--project-name=${ZANATA_PROJECT_NAME}" "--project-desc=${ZANATA_PROJECT_DESC}" "--default-project-type=${ZANATA_PROJECT_TYPE}")
fi

local_args+=( "${PUT_PROJECT_OPTIONS[@]}" )

TestCaseStart "${TEST_CASE_NAME_PREFIX}"
RunCmd ${ZANATA_EXECUTABLE} "${local_args[@]}"
OutputNoError

