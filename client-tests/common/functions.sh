# this is to be sourced

#================================
# Variables
#
export EXIT_CODE_OK=0
export EXIT_CODE_INVALID_ARGUMENTS=3
export EXIT_CODE_ERROR=5
export EXIT_CODE_FAILED=6
export EXIT_CODE_SKIPPED=7
export EXIT_CODE_FATAL=125

MVN_COMMAND_PREFIX=org.zanata:zanata-maven-plugin

: ${ZANATA_URL:=http://localized-zanatatest.itos.redhat.com/}
: ${ZANATA_USERNAME:=peggy}
: ${ZANATA_KEY:=1a0172997f0a751ca351285b08de4d64}

## Project definition
: ${ZANATA_PROJECT_SLUG:=ibus-chewing}
: ${ZANATA_PROJECT_NAME:=$ZANATA_PROJECT_SLUG}
: ${ZANATA_PROJECT_DESC:=$ZANATA_PROJECT_NAME}
: ${ZANATA_VERSION_SLUG:=master}
: ${ZANATA_PROJECT_TYPE:=gettext}
: ${WORK_DIR:=${TOP_DIR}/doc-prjs/$ZANATA_PROJECT_SLUG/$ZANATA_VERSION_SLUG}

JUNIT_XML_INTERNAL=

#================================
# String functions
#

function hyphen_to_camel_case(){
    sed -e 's/-\([a-z]\)/\U\1/g'<<<$1
}

function long_option_name_convert(){
    local cmd=$1
    local name=$2
    case $cmd in
	*mvn )
	    if [ "$name" = "disable-ssl-cert" ];then
		echo "disableSSLCert"
	    elif [ "$name" = "merge-type" ];then
		echo "merge"
	    else
		hyphen_to_camel_case "$name"
	    fi
	    ;;
	* )
	    echo "$name"
	    ;;
    esac
}

function long_option_convert(){
    local cmd=$1
    local name=`long_option_name_convert $cmd $2`
    local value=$3

    case $cmd in
	*mvn )
	    if [ -n "$value" ];then
		echo "-Dzanata.$name=$value"
	    else
		echo "-Dzanata.$name"
	    fi
	    ;;
	* )
	    if [ -n "$value" ];then
		echo "--$name $value"
	    else
		echo "--$name"
	    fi
	    ;;
    esac
}

function short_option_convert(){
    local cmd=$1
    local name=$2
    local value=$3

    case $cmd in
	*mvn )
	    if [ "$name" = "v" ];then
		name="Ddetail"
	    fi
	    if [ -n "$value" ];then
		echo "-$name $value"
	    else
		echo "-$name"
	    fi
	    ;;
	* )
	    if [ -n "$value" ];then
		echo "-$name $value"
	    else
		echo "-$name"
	    fi
	    ;;
    esac
}


function argument_convert(){
    local cmd=$1
    local optString=$2
    local subCommand=$3
    
    case $optString in
	--* )
	    optStr=`sed -e 's/^--//'<<<$optString`
	    local name=`sed -e 's/=.*$//'<<<$optStr`
	    local value=`sed -e 's/^[^=]*=*//'<<<$optStr`
	    long_option_convert "$cmd" "$name" "$value"
	    ;;
	-* )
	    optStr=`sed -e 's/^-//'<<<$optString`
	    local name=`sed -e 's/=.*$//'<<<$optStr`
	    local value=`sed -e 's/^[^=]*=*//'<<<$optStr`
	    short_option_convert "$cmd" "$name" "$value"
	    ;;
	* )
	    if [[ $cmd =~ mvn ]];then
		if [ -z "${subCommand}" ];then
		    echo "$MVN_COMMAND_PREFIX:$optString"
		elif [ "${subCommand}" = "help" ];then
		    echo "-Dgoal=$optString -Ddetail"
		else
		    echo "$optString" 
		fi
	    else
		echo "$optString"
	    fi
	    ;;
    esac
}

#================================
# Command functions
#


## real_command  <cmd> - Obtain canonicalized command path
## Stdout: Canonicalized command path
function real_command(){
    local cmd=$1
    if [ -z "$cmd" ]; then
	## Redirect to stderr because
	##   1) It is error message
	##   2) stdout of this command is only for result.
	print_usage >/dev/stderr
	stderr_echo "Command not specified"
	exit $EXIT_CODE_INVALID_ARGUMENTS
    fi
    local str=`which $cmd`
    if [ -z "$str" ];then
	print_usage >/dev/stderr
	stderr_echo "Command $cmd invalid"
	exit $EXIT_CODE_INVALID_ARGUMENTS
    fi
    readlink -f "$str"
}

function command_get_type(){
    local realCmd=`real_command $1`
    case $realCmd in
	*mvn )
	    echo "mvn"
	    ;;
	*zanata-cli )
	    echo "java"
	    ;;
	*zanata )
	    echo "python"
	    ;;
	* )
	    basename $realCmd
	    ;;
    esac
}

#================================
# Utilities functions
#

function get_zanata_xml_url(){
    local url=$1
    local proj=$2
    local ver=$3
    echo "${url}iteration/view/${proj}/${ver}?actionMethod=iteration%2Fview.xhtml%3AconfigurationAction.downloadGeneralConfig%28%29"
}

ZANATA_OUTPUT_FILE_TEMPLATE="/tmp/zanata-test.XXXXXXXX"

#================================
# Guide functions
#

function extract_variable(){
    local file=$1
    local nameFilter=$2
    awk -v nameFilter="$nameFilter" \
	'BEGIN {FPAT = "(\"[^\"]+\")|(\\(.+\\))|([^ =]+)"; start=0; descr=""} \
	/^#### End Var/ { start=0} \
        (start==1 && /^[^#]/ && $2 ~ nameFilter) { sub(/^\"/, "", $3); sub(/\"$/, "", $3); print $2 "\t" $3 "\t" descr ; descr="";} \
	(start==1 && /^###/) { gsub("^###[ ]?","", $0) ; descr=$0} \
        /^#### Start Var/ { start=1; } ' $file
}

function print_variables(){
    local format=$1
    local file=$2
    case $format in
        asciidoc )
	    extract_variable $file | awk -F '\\t' 'BEGIN { done=0 } \
		$2 ~ /^\$\{.*:[=-]/ { ret=gensub(/^\$\{.*:[=-](.+)\}/, "\\1", "g", $2) ; print ":" $1 ": " ret; done=1 }\
		done==0  {print ":" $1 ": " $2 ; done=1 }\
		done==1  {done=0}'
	    ;;
	bash )
	    extract_variable $file "^[A-Z]" | awk -F '\\t' \
		'$2 ~ /[^\)]$/ {print "exportb " $1 "=\""$2"\"" ;} \
		$2 ~ /\)$/ {print "exporta " $1 "="$2 ;} '
	    ;;
        usage )
	    extract_variable $file "^[A-Z]" | awk -F '\\t' '{print $1 "::"; \
		if ( $3 != "" ) {print "    " $3  }; \
		print "    Default: " $2 "\n"}'
	    ;;	    
        * )
	    ;;
    esac
}

function to_asciidoc(){  
    print_variables asciidoc $0

    awk 'BEGIN {start=0;sh_start=0; in_list=0} \
	/^#### End Doc/ { start=0} \
	(start==1 && /^[^#]/ ) { if (sh_start==0) {sh_start=1; if (in_list ==1 ) {print "+"}; print "[source,sh]"; print "----"} print $0;} \
	(start==1 && /^### \./ ) { in_list=1 } \
        (start==1 && /^###/ ) { if (sh_start==1) {sh_start=0; print "----"} gsub("^###[ ]?","", $0) ; print $0;} \
	/^#### Start Doc/ { start=1; } ' $0
    echo "== Default Environment Variables"
    echo "[source,sh]"
    echo "----"
    # Extract variable
    print_variables bash $0
    echo "----"
}

#================================
# Test Reporting
#

total=0
totaltime=0.0
failed=0
skipped=0

function stderr_echo (){
    echo "$@" >/dev/stderr
}

function clean_files (){
    if [ -n "${CMDERR_FILE}" ];then
	rm -f "${CMDERR_FILE}"
    fi
    if [ -n "${CMDOUT_FILE}" ];then
        rm -f "${CMDOUT_FILE}"
    fi
    if [ -n "${NEW_CMDERR_FILE}" ];then
        rm -f "${NEW_CMDERR_FILE}"
    fi
    if [ -n "${NEW_CMDOUT_FILE}" ];then
	rm -f "${NEW_CMDOUT_FILE}"
    fi
}

function skipped_msg(){
    SKIP_TEST=1
    local eTime=$1
    local message=$2
    local detail=$3
    local consoleOut="SKIPPED: $CLASSNAME $TEST_CASE_NAME ($eTime)"
    echo $consoleOut
    : $((skipped++))
    : $((total++))
    totalTime=`perl -e "print $totalTime+$eTime;"`

    if [ -n "${JUNIT_XML_INTERNAL}" ];then
	junit_xml_append_test_case SKIPPED "${TEST_CASE_NAME}" "$eTime" "${message}" "${detail}"
    fi
    unset TEST_CASE_NAME
}

function failed_msg(){
    if [ -n "$SKIP_TEST" ];then
	skipped_msg "$@"
	return
    fi
    local eTime=$1
    local message=$2
    local detail=$3
    local outFile=$4
    local errFile=$5
    local consoleOut="FAILED: $CLASSNAME $TEST_CASE_NAME ($eTime)"
    echo $consoleOut
    : $((failed++))
    : $((total++))
    totalTime=`perl -e "print $totalTime+$eTime;"`
    echo "-- FAILED -- ${TEST_CASE_NAME} ----- NEW_CMD_FULL=${NEW_CMD_FULL}" > /dev/stderr

    if [ -n "${outFile}" ];then
	echo "-- FAILED -- ${TEST_CASE_NAME} ----- STDOUT --------------------------------" > /dev/stderr
	cat ${outFile} > /dev/stderr
    fi
    if [ -n "${errFile}" ];then
	echo "-- FAILED -- ${TEST_CASE_NAME} ----- STDERR --------------------------------" > /dev/stderr
	cat ${errFile} > /dev/stderr
    fi
    if [ -n "${outFile}" -o -n "${errFile}" ];then
	echo "=================================================================" > /dev/stderr
    fi

    if [ -n "${JUNIT_XML_INTERNAL}" ];then
	junit_xml_append_test_case FAILED "$TEST_CASE_NAME" "$eTime" "${message}" "${detail}" "${outFile}" "${errFile}"
    fi
    unset TEST_CASE_NAME
}

function ok_msg(){
    if [ -n "$SKIP_TEST" ];then
        skipped_msg "$@"
	return
    fi
    local eTime=$1
    local consoleOut="OK: $CLASSNAME $TEST_CASE_NAME ($eTime)"
    echo $consoleOut
    : $((total++))
    totalTime=`perl -e "print $totalTime+$eTime;"`

    if [ -n "${JUNIT_XML_INTERNAL}" ];then
	junit_xml_append_test_case OK "$TEST_CASE_NAME" "$eTime"
    fi
    unset TEST_CASE_NAME
}

function get_real_time(){
    local realTime=`grep -e "real" $1 2>/dev/null`
    if [ -n "${realTime}" ];then
	sed -e 's/real //'<<<${realTime}
    else
	echo "0.00"
    fi
}


## Time 
function time_command(){
    NEW_CMDERR_FILE=`mktemp "${ZANATA_OUTPUT_FILE_TEMPLATE}"`
    NEW_CMDOUT_FILE=`mktemp "${ZANATA_OUTPUT_FILE_TEMPLATE}"`
    NEW_TIME_FILE=`mktemp "${ZANATA_OUTPUT_FILE_TEMPLATE}"`
    NEW_CMD_FULL="$*"
    /usr/bin/time -p -o ${NEW_TIME_FILE} "$@" 1>${NEW_CMDOUT_FILE} 2>${NEW_CMDOUT_FILE}
    NEW_EXIT_CODE=$?
    REAL_TIME=`get_real_time ${NEW_TIME_FILE}`
    rm -f ${NEW_TIME_FILE}
}

function print_summary(){
    echo "$1 Summary: total=$total failed=$failed skipped=$skipped totalTime=$totalTime"
    if [ -z "${JUNIT_XML_INTERNAL}" ];then
	return
    fi

    : ${TEST_PACKAGE:=client-$(command_get_type ${CMD})}
    sed -i -e "s/@TEST_PACKAGE@/${TEST_PACKAGE}/" ${JUNIT_XML_INTERNAL}
    sed -i -e "s/@FAILED@/${failed}/" ${JUNIT_XML_INTERNAL}
    sed -i -e "s/@TOTAL@/${total}/" ${JUNIT_XML_INTERNAL}
    sed -i -e "s/@TOTAL_TIME@/${totalTime}/" ${JUNIT_XML_INTERNAL}
cat >>${JUNIT_XML_INTERNAL}<<END
</testsuite>
END
}

function has_string_check(){
    if ! grep -e "$str" 2>/dev/null <<<"$output" ;then
	failed_msg "$str does not exist"
	return $EXIT_CODE_FAILED
    fi
    ok_msg "$str"
}

#================================
# JUnit
#

function file_encode_xml(){
    local file=$1
    if [ -z "$file" ];then
	file=/dev/stdin
    fi
    sed -e 's~&~\&amp;~g' -e 's~<~\&lt;~g'  -e  's~>~\&gt;~g' "$file"
}

function junit_xml_print_test_case_header(){
    local name=$1
    local eTime=$2
    local sub=$3
    local result="  <testcase name=\"$name\" time=\"$eTime\""
    if [ -n "${CLASSNAME}" ];then
	result+=" classname=\"${CLASSNAME}\""
    fi
    if [ -z "${sub}" ];then
	result+="/>"
    else
	result+=">"
    fi
    echo "$result"
}

function junit_xml_append_test_case(){
    local msgType=$1
    local name=$2
    local eTime=$3
    local message=$4
    local detail=$5
    local outFile=$6
    local errFile=$7
    case $msgType in
	SKIPPED )
	    junit_xml_print_test_case_header "$name" $eTime 1 >> ${JUNIT_XML_INTERNAL}
	    echo "    <skipped/>" >> ${JUNIT_XML_INTERNAL}
	    echo "  </testcase>" >> ${JUNIT_XML_INTERNAL}
	    ;;
	FAILED )
	    junit_xml_print_test_case_header "$name" $eTime 1 >> ${JUNIT_XML_INTERNAL}
	    echo "    <error message=\"$message\">$detail</error>" >> ${JUNIT_XML_INTERNAL}
	    if [ -n "${outFile}" ];then
		echo "    <system-out>" >> ${JUNIT_XML_INTERNAL}
		file_encode_xml "${outFile}" >> ${JUNIT_XML_INTERNAL}
		echo "    </system-out>" >> ${JUNIT_XML_INTERNAL}
	    fi
	    if [ -n "${errFile}" ];then
		echo "    <system-err>" >> ${JUNIT_XML_INTERNAL}
		file_encode_xml "${errFile}" >> ${JUNIT_XML_INTERNAL}
		echo "    </system-err>" >> ${JUNIT_XML_INTERNAL}
	    fi
	    echo "  </testcase>" >> ${JUNIT_XML_INTERNAL}
	    ;;
	* )
	    junit_xml_print_test_case_header "$name" $eTime  >> ${JUNIT_XML_INTERNAL}
	    ;;
    esac
}

function junit_xml_new(){
    JUNIT_XML_INTERNAL=$1
    if [ -z "${JUNIT_XML_INTERNAL}" ];then
	echo "Please specify output JUnit XML file" > /dev/stderr
	exit $EXIT_CODE_INVALID_ARGUMENTS
    fi

    rm -f "${JUNIT_XML_INTERNAL}"
    TIME_STAMP=`date --iso-8601=second`
    HOSTNAME=`hostname`
    local resultDir=$(dirname $(readlink -m "${JUNIT_XML_INTERNAL}"))
    if [ -n "${resultDir}" ];then
	mkdir -p "${resultDir}"
    fi
    cat >${JUNIT_XML_INTERNAL}<<END
<?xml version="1.0" encoding="UTF-8" ?>
<testsuite errors="0" failures="@FAILED@" hostname="${HOSTNAME}" package="@TEST_PACKAGE@" name="${TEST_SUITE_NAME}" tests="@TOTAL@" time="@TOTAL_TIME@" timestamp="${TIME_STAMP}">
END
}

#================================
# Function for Keyword-Based testing
#

function TestCaseStart(){
    clean_files
    TEST_CASE_NAME_PREFIX=$1
}

function RunCmdExitCode(){
    local expectedExit=$1
    LAST_EXPECTED_EXIT_CODE=$expectedExit
    local cmd=$2
    LAST_CMD="$cmd"
    shift 2

    : ${TEST_CASE_NAME:=${TEST_CASE_NAME_PREFIX}-RunCmdExitCode}

    local subCommand
    declare -a args
    for o in "$@";do
	if [ -z "${subCommand}" ];then
	    # First non-option argument become subCommand (e.g. help)
	    if [[ ! "$o" =~ ^- ]]; then
		subCommand="$o"
	    fi
	    args+=(`argument_convert "$cmd" "$o"`)
	else
	    args+=(`argument_convert "$cmd" "$o" "${subCommand}"`)
	fi
    done

    LAST_CMD_FULL="${cmd} ${args[*]}"
    if [ -n "$ZANATA_TEST_DEBUG" ];then
	stderr_echo "LAST_CMD_FULL=$LAST_CMD_FULL"
    fi
    if [ -n "$SKIP_TEST" ];then
	skipped_msg 0.0 "${LAST_CMD_FULL}"
	return $EXIT_CODE_SKIPPED
    fi
    time_command $cmd ${args[@]} 
    CMDERR_FILE="${NEW_CMDERR_FILE}"
    CMDOUT_FILE="${NEW_CMDOUT_FILE}"
    LAST_EXIT_CODE=${NEW_EXIT_CODE}

    if [ ${LAST_EXIT_CODE} -eq ${expectedExit} ];then
	ok_msg  ${REAL_TIME} "Command returns $expectedExit"
	return $EXIT_CODE_OK
    fi

    failed_msg ${REAL_TIME} "${LAST_CMD_FULL}" "Expected: $expectedExit, Actual: $ret instead. Command=${LAST_CMD_FULL}" "${CMDOUT_FILE}" "${CMDERR_FILE}"
    return $EXIT_CODE_FAILED
}

function RunCmd(){
    : ${TEST_CASE_NAME:=${TEST_CASE_NAME_PREFIX}-RunCmd}
    RunCmdExitCode 0 "$@"
    return $?
}

function StdoutContain(){
    local str=$1
    local exitCode=$EXIT_CODE_OK
    : ${TEST_CASE_NAME:=${TEST_CASE_NAME_PREFIX}-StdoutContain-$str}

    if [ -n "$SKIP_TEST" ];then
	skipped_msg 0.0
	return $EXIT_CODE_SKIPPED
    elif [ ${LAST_EXIT_CODE} -ne ${LAST_EXPECTED_EXIT_CODE} ];then
	skipped_msg 0.0 "LAST_EXIT_CODE=${LAST_EXIT_CODE}" "LAST_EXIT_CODE=${LAST_EXIT_CODE} Command=${LAST_CMD_FULL}"
	exitCode=$EXIT_CODE_SKIPPED
    else
	time_command grep -e "$str"  2>/dev/null ${CMDOUT_FILE}
	if [ ${NEW_EXIT_CODE} -ne 0 ];then
	    failed_msg ${REAL_TIME}  "String $str does not exist" "Command=${LAST_CMD_FULL}" "${NEW_CMDOUT_FILE}" "${NEW_CMDERR_FILE}"
	    exitCode=$EXIT_CODE_FAILED
	else
	    ok_msg ${REAL_TIME}
	fi
	rm -f ${NEW_CMDERR_FILE} ${NEW_CMDOUT_FILE}
    fi
    return $exitCode
}

function StdoutContainArgument(){
    local str=$1
    local arg=`long_option_name_convert "${LAST_CMD}" "$str"`
    : ${TEST_CASE_NAME:=${TEST_CASE_NAME_PREFIX}-StdoutContainArgument-${arg}}

    StdoutContain "$arg"
}

function OutputNoError(){
    ## Command has error test 
    : ${TEST_CASE_NAME:=${TEST_CASE_NAME_PREFIX}-OutputNoError}

    if [ -n "$SKIP_TEST" ];then
	skipped_msg 0.0
	return $EXIT_CODE_SKIPPED
    elif [ ${LAST_EXIT_CODE} -ne ${LAST_EXPECTED_EXIT_CODE} ];then
	skipped_msg 0.0 "LAST_EXIT_CODE=${LAST_EXIT_CODE}" "Command=${LAST_CMD_FULL}"
	return $EXIT_CODE_SKIPPED
    else
	time_command grep -e '\[ERROR\]'  2>/dev/null ${CMDOUT_FILE}
	if [ ${NEW_EXIT_CODE} -eq 0 ];then
	    failed_msg ${REAL_TIME}  "[ERROR] exist" "stdout contains [ERROR] Command=${LAST_CMD_FULL}"
	    return $EXIT_CODE_FAILED
	fi
    fi
    ok_msg ${REAL_TIME}
    return $EXIT_CODE_OK
}

#================================
# Common exit
#

function finish {
    clean_files
}

trap finish EXIT 

#================================
# Common init
#

if [ -n "${JUNIT_XML}" ];then
    junit_xml_new "$(readlink -m "${JUNIT_XML}")"
fi

