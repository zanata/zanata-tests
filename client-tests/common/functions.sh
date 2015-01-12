# this is to be sourced

#================================
# Variables
#
export EXIT_CODE_OK=0
export EXIT_CODE_FAILED=3
export EXIT_CODE_SKIPPED=4
export EXIT_CODE_FATAL=125

#================================
# Guide functions
#

declare -a varNames
declare -A varValues
function set_var(){
    varNames+=($1)
    local origValue=$(eval echo \$$1)
    if [ -n "${origValue}" ]; then
	# Environment already defined
	varValues[$1]="${origValue}"
    elif [ -n "$2" ];then
	varValues[$1]="$2"
	eval `echo $1=\"$2\"`
    else
	eval `echo $1=`
    fi
}

function to_asciidoc(){  # NOT_IN_DOC
    for k in "${varNames[@]}";do
	local value=
	if [ -n "${varValues[$k]}" ];then
	    value=" "
	    value+=`str_convert_variable_to_asciidoc_variable "${varValues[$k]}"`
	fi
	echo ":$k:$value"
    done
    awk 'BEGIN {start=0;} \
	/^#### End Doc/ { start=0} \
	start==1 { gsub("^###[ ]?","", $0); print $0;}\
	/^#### Start Doc/ { start=1; } ' $0
}

function str_convert_variable_to_asciidoc_variable(){
    sed -e 's/[$][{]/{/g' <<<$1
}

#================================
# Test functions
#

total=0
failed=0
skipped=0

function skipped_msg(){
    SKIP_TEST=1
    echo "SKIPPED: $1"
    : $((skipped++))
    : $((total++))
}


function failed_msg(){
    if [ -n "$SKIP_TEST" ];then
	skipped_msg $1
	return
    fi
    echo "FAILED: $1"
    : $((failed++))
    : $((total++))
}

function ok_msg(){
    if [ -n "$SKIP_TEST" ];then
	skipped_msg $1
	return
    fi
    echo "OK: $1"
    : $((total++))
}

function command_return(){
    local expected=$1
    local cmd=$2
    if [ -n "$SKIP_TEST" ];then
	skipped_msg "Command return $expected"
	return $EXIT_CODE_SKIPPED
    fi
    commandOutput=$($cmd 2>/dev/null)
    ret=$?
    if [ $? -eq $expected ];then
	ok_msg "Command returns $expected"
	return $EXIT_CODE_OK
    else
	failed_msg "Command failed to return $expected, returned $ret instead"
    fi
    return $EXIT_CODE_FAILED
}

function command_has_no_error_check(){
    local promptStr=$1
    local cmd=$2
    shift 2

    commandOutput=`$cmd "$@" 2>/dev/null`
    ret=$?
    result=$EXIT_CODE_OK

    ## Command return test 
    if [ -n "$SKIP_TEST" ];then
	skipped_msg "Command return 0"
	result=$EXIT_CODE_SKIPPED
    elif [ $ret -eq 0 ];then
	ok_msg "Command return 0"
    else
	failed_msg "Command should return 0 but return $ret instead"
	result=$EXIT_CODE_FAILED
    fi

    ## Command has error test 
    if [ -n "$SKIP_TEST" ];then
	skipped_msg "$promptStr has no [ERROR]"
    elif [ $ret -eq 126 -o $ret -eq 127 ];then
	skipped_msg "$promptStr has no [ERROR], because return 0 test failed"
    elif grep -e '\[ERROR\]'  2>/dev/null <<<"$commandOutput"  ;then
	failed_msg "$promptStr has [ERROR]"
	result=$EXIT_CODE_FAILED
    else
	ok_msg "$promptStr has no [ERROR]"
    fi
    return $result
}

function has_string_check(){
    local str=$1
    local output=$2
    if ! grep -e "$str" 2>/dev/null <<<"$output" ;then
	failed_msg "$str does not exist"
	return $EXIT_CODE_FAILED
    fi
    ok_msg "$str"

}


function print_summary(){
    echo "$1 Summary: total=$total failed=$failed skipped=$skipped"
}
