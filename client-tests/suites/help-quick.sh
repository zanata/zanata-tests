CLASSNAME=help
SUMMARY="Help message of frequently used command"


TestCaseStart "No arguments"
case $CMD in
    *mvn )
	RunCmd ${CMD} help
	;;
    * )
	RunCmd ${CMD}
	;;
esac
StdoutContainArgument "help"
StdoutContainArgument "push"
StdoutContainArgument "pull"

## Verbose mode (-v)
TestCaseStart "Verbose"
unset SKIP_TEST
case $CMD in
    *mvn )
	## mvn does not have the sole verbose mode for Zanata
	;;
    * )
	RunCmd ${CMD} -v
	StdoutContain "API version: [0-9]*.[0-9]*"
	;;
esac

## Subcommand: help push
function check_push_pull_common_args(){
    StdoutContainArgument "disable-ssl-cert"
    StdoutContainArgument "url"
    StdoutContainArgument "username"
    StdoutContainArgument "key"
    StdoutContainArgument "user-config"
    StdoutContainArgument "project-config"
    StdoutContainArgument "src-dir"
    StdoutContainArgument "trans-dir"
    StdoutContainArgument "excludes"
    StdoutContainArgument "includes"
    StdoutContainArgument "locales"
    StdoutContainArgument "project"
    StdoutContainArgument "project-version"
}

TestCaseStart "help push"
SKIP_TEST=
RunCmd ${CMD} help push
check_push_pull_common_args
StdoutContainArgument "copy-trans"
StdoutContainArgument "file-types"
StdoutContainArgument "merge-type"
StdoutContainArgument "push-type"
StdoutContainArgument "from-doc"

TestCaseStart "help pull"
SKIP_TEST=
RunCmd ${CMD} help pull
check_push_pull_common_args
StdoutContainArgument "create-skeletons"
StdoutContainArgument "encode-tabs"
StdoutContainArgument "include-fuzzy"
StdoutContainArgument "pull-type"

