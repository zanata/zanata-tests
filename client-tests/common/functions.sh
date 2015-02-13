### common/functions.sh
### -------------------
### Helper functions that should be sourced.

### Variables 
### ~~~~~~~~~~
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
ZANATA_OUTPUT_FILE_TEMPLATE="/tmp/zanata-test.XXXXXXXX"

### String functions
### ~~~~~~~~~~~~~~~~
function hyphen_to_camel_case(){
    sed -e 's/-\([a-z]\)/\U\1/g'<<<$1
}

### Option processing
### ~~~~~~~~~~~~~~~~~

### Default options 
### ^^^^^^^^^^^^^^^
function unversal_option_get_default_executable(){
    var=$1
    eval "$var+=( -B -e )"
}

function unversal_option_get_default_auth(){
    var=$1
    eval "$var+=('--url=$ZANATA_URL' '--username=$ZANATA_USERNAME' '--key=$ZANATA_KEY')"
}


### Convert to ZANATA_EXECUTABLE options from universal options
### ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
declare -A CONVERT_OPTION_MVN
CONVERT_OPTION_MVN['disable-ssl-cert']=zanata.disableSSLCert
CONVERT_OPTION_MVN['merge-type']=zanata.merge
CONVERT_OPTION_MVN['v']=detail
CONVERT_OPTION_MVN['push:s']=zanata.srcDir
CONVERT_OPTION_MVN['push:t']=zanata.transDir
CONVERT_OPTION_MVN['pull:s']=zanata.srcDir
CONVERT_OPTION_MVN['pull:t']=zanata.transDir

function option_name_convert(){
    local cmd=$1
    local subCommand=$2
    local name=$3
    case $cmd in
	*mvn )
	    if [ -n "${CONVERT_OPTION_MVN["$subCommand:$name"]}" ];then
		echo "-D${CONVERT_OPTION_MVN["$subCommand:$name"]}"
	    elif  [ -n "${CONVERT_OPTION_MVN["$name"]}" ];then
		echo "-D${CONVERT_OPTION_MVN["$name"]}"
	    else
		echo -n "-Dzanata."
		hyphen_to_camel_case "$name"
	    fi
	    ;;
	* )
	    if [[ $name =~ ^[A-Za-z0-9]$ ]]; then
		echo "-$name"
	    else
		echo "--$name"
	    fi
	    ;;
    esac
}

function option_convert(){
    local cmd=$1
    local subCommand=$2
    local optionName=$3
    local value=$4
    local name=`option_name_convert $cmd $subCommand $optionName`

    case $cmd in
	*mvn )
	    if [ -n "$value" ];then
		args+=("$name=$value")
	    else
		args+=("$name")
	    fi
	    ;;
	* )
	    args+=("$name")
	    if [ -n "$value" ];then
		args+=("$value")
	    fi
	    ;;
    esac
}


function argument_convert(){
    local cmd=$1
    local optString=$2
    if [ -z "$subCommand" ];then
	# First non-option argument become subCommand (e.g. help)
	if [[ ! "$optString" =~ ^- ]]; then
	    subCommand="$optString"
	    case $cmd in
		*mvn )
		    args+=($MVN_COMMAND_PREFIX:$subCommand)
		    ;;

		* )
		    args+=($subCommand)
		    ;;
	    esac
	else
	    # Still an option
	    args+=($optString)
	fi
    else
	case $optString in
	    -* )
		optStr=`sed -e 's/^-*//'<<<$optString`
		local name=`sed -e 's/=.*$//'<<<$optStr`
		local value=`sed -e 's/^[^=]*=*//'<<<$optStr`
		option_convert "$cmd" "$subCommand" "$name" "$value"
		;;
	    * )
		if [[ $cmd =~ mvn ]];then
		    if [ -z "${subCommand}" ];then
			args+=("$MVN_COMMAND_PREFIX:$optString")
		    elif [ "${subCommand}" = "help" ];then
			args+=("-Dgoal=$optString" "-Ddetail")
		    else
			args+=($optString)
		    fi
		else
		    args+=("$optString")
		fi
		;;
	esac
    fi
}

### Executable handling functions
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### time_command: Time the execution time
### ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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


### real_command: Obtain canonicalized command path
### ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
### real_command  <cmd>
### Stdout: Canonicalized command path
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

function get_test_package(){
    local realCmd=`real_command $1`
    case $realCmd in
	*mvn )
	    echo "mvn"
	    ;;
	*zanata-cli )
	    echo "zanata-client"
	    ;;
	*zanata )
	    echo "zanata-python-client"
	    ;;
	* )
	    basename $realCmd
	    ;;
    esac
}

### zanata.xml functions
### ^^^^^^^^^^^^^^^^^^^^
function get_zanata_xml_url(){
    local url=$1
    local prj=$2
    local ver=$3
    echo "${url}iteration/view/${prj}/${ver}?actionMethod=iteration%2Fview.xhtml%3AconfigurationAction.downloadGeneralConfig%28%29"
}

function zanata_xml_make(){
    local force=0
    if [ "$1" = "-f" ];then
	force=1
	shift
    fi
    local url=$1
    local prj=$2
    local ver=$3
    local zanataXml=$4
    if [ -z "$zanataXml" ];then
	zanataXml="zanata.xml"
    fi
    if [ -r "$zanataXml" -a "$force" -eq 0 ];then
	# zanata.xml exist and no force
	return
    else
	zanataXmlUrl=$(get_zanata_xml_url "$url" "$prj" "$ver")
	wget --no-check-certificate -O "$zanataXml" "$zanataXmlUrl"
    fi
}

### Guide document generation functions
### ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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

### Test Reporting Functions
### ~~~~~~~~~~~~~~~~~~~~~~~~

### Time reporting
### ^^^^^^^^^^^^^^^^^^^^^^^^

total=0
totaltime=0.0
failed=0
skipped=0

function get_real_time(){
    local realTime=`grep -e "real" $1 2>/dev/null`
    if [ -n "${realTime}" ];then
	sed -e 's/real //'<<<${realTime}
    else
	echo "0.00"
    fi
}

### Test Result Outputting
### ^^^^^^^^^^^^^^^^^^^^^^
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
    stderr_echo "-- FAILED -- ${TEST_CASE_NAME} ----- NEW_CMD_FULL=${NEW_CMD_FULL}"

    if [ -n "${outFile}" ];then
	stderr_echo "-- FAILED -- ${TEST_CASE_NAME} ----- STDOUT --------------------------------"
	cat ${outFile} > /dev/stderr
    fi
    if [ -n "${errFile}" ];then
	stderr_echo "-- FAILED -- ${TEST_CASE_NAME} ----- STDERR --------------------------------"
	cat ${errFile} > /dev/stderr
    fi
    if [ -n "${outFile}" -o -n "${errFile}" ];then
	stderr_echo "================================================================="
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
    local message=$2
    local outFile=$3
    local errFile=$4
    local consoleOut="OK: $CLASSNAME $TEST_CASE_NAME ($eTime)"
    echo $consoleOut
    : $((total++))
    totalTime=`perl -e "print $totalTime+$eTime;"`

    if [ -n "$ZANATA_TEST_DEBUG" ];then
	stderr_echo "-- OK -- ${TEST_CASE_NAME} ----- NEW_CMD_FULL=${NEW_CMD_FULL}"

	if [ -n "${outFile}" ];then
	    stderr_echo "-- OK -- ${TEST_CASE_NAME} ----- STDOUT --------------------------------"
	    cat ${outFile} > /dev/stderr
	fi
	if [ -n "${errFile}" ];then
	    stderr_echo "-- OK -- ${TEST_CASE_NAME} ----- STDERR --------------------------------"
	    cat ${errFile} > /dev/stderr
	fi
	if [ -n "${outFile}" -o -n "${errFile}" ];then
	    stderr_echo "================================================================="
	fi
    fi



    if [ -n "${JUNIT_XML_INTERNAL}" ];then
	junit_xml_append_test_case OK "$TEST_CASE_NAME" "$eTime"
    fi
    unset TEST_CASE_NAME
}

function print_summary(){
    echo "$1 Summary: total=$total failed=$failed skipped=$skipped totalTime=$totalTime"
    if [ -z "${JUNIT_XML_INTERNAL}" ];then
	return
    fi

    : ${TEST_PACKAGE:=$(get_test_package ${ZANATA_EXECUTABLE})}
    sed -i -e "s/@TEST_PACKAGE@/${TEST_PACKAGE}/" ${JUNIT_XML_INTERNAL}
    sed -i -e "s/@FAILED@/${failed}/" ${JUNIT_XML_INTERNAL}
    sed -i -e "s/@TOTAL@/${total}/" ${JUNIT_XML_INTERNAL}
    sed -i -e "s/@TOTAL_TIME@/${totalTime}/" ${JUNIT_XML_INTERNAL}
cat >>${JUNIT_XML_INTERNAL}<<END
</testsuite>
END
}

### JUnit Functions
### ^^^^^^^^^^^^^^^
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

### Keyword-Based testing Function
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### These are "real" testing functions that should be written in test cases.

### === TestCaseStart
### TestCaseStart <TEST_CASE_NAME_PREFIX>
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

    subCommand=
    declare -a args
    for o in "$@";do
	argument_convert "$cmd" "$o"
    done

    LAST_CMD_FULL="${cmd} ${args[*]}"
    if [ -n "$SKIP_TEST" ];then
	skipped_msg 0.0 "${LAST_CMD_FULL}"
	return $EXIT_CODE_SKIPPED
    fi
    time_command $cmd "${args[@]}"
    CMDERR_FILE="${NEW_CMDERR_FILE}"
    CMDOUT_FILE="${NEW_CMDOUT_FILE}"
    LAST_EXIT_CODE=${NEW_EXIT_CODE}

    if [ ${LAST_EXIT_CODE} -eq ${expectedExit} ];then
	ok_msg  ${REAL_TIME} "Command returns $expectedExit" "${CMDOUT_FILE}" "${CMDERR_FILE}"
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
	    ok_msg ${REAL_TIME} "stdout contains $str" "${CMDOUT_FILE}" "${CMDERR_FILE}"
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

