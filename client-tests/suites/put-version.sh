# Test case common part
CLASSNAME=put-version
unset local_args

if [ -n "$USE_DEFAULT_OPTIONS" ];then
    unversal_option_get_default_executable local_args
fi

### Add subCommand
local_args+=( $CLASSNAME )

if [ -n "$USE_DEFAULT_OPTIONS" ];then
    unversal_option_get_default_auth local_args
    : ${ZANATA_VERSION_SLUG:=master}
    local_args+=("--version-project=${ZANATA_PROJECT_SLUG}" "--version-slug=${ZANATA_VERSION_SLUG}")
fi

local_args+=( "${PUT_VERSION_OPTIONS[@]}" )

TestCaseStart "${TEST_CASE_NAME_PREFIX}"
RunCmd ${ZANATA_EXECUTABLE} "${local_args[@]}"
OutputNoError

