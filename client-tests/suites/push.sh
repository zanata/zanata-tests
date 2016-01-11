# Test case common part
CLASSNAME=push
unset local_args

if [ -n "$USE_DEFAULT_OPTIONS" ];then
    unversal_option_get_default_executable local_args
fi

### Add subCommand
local_args+=( $CLASSNAME )

if [ -n "$USE_DEFAULT_OPTIONS" ];then
    unversal_option_get_default_auth local_args
    case $ZANATA_PROJECT_TYPE in
	gettext )
	    if [ `get_test_package ${ZANATA_EXECUTABLE}` = "zanata-client" ];then
		local_args+=( "-s=po" "-t=po")
	    fi
	    ;;
	podir )
	    if [ `get_test_package ${ZANATA_EXECUTABLE}` = "zanata-client" ];then
		local_args+=( "-s=pot" "-t=.")
	    fi
	    ;;
	* )
	    if [ `get_test_package ${ZANATA_EXECUTABLE}` = "zanata-client" ];then
		local_args+=( "-s=." "-t=.")
	    fi
	    ;;
    esac
fi

local_args+=( "${PUSH_OPTIONS[@]}" )

TestCaseStart "${TEST_CASE_NAME_PREFIX}"
RunCmd ${ZANATA_EXECUTABLE} "${local_args[@]}"
OutputNoError

