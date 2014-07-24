#!/bin/bash -x
function print_usage(){
cat <<EOF
NAME
    maintainer_main_workflow.sh - maintainer workfolw test

SYNOPSIS
    maintainer_main_workflow.sh [opts] <PRJ> <VER>

OPTIONS:
    -c "opt1=value;opt2": Global options to pass ZANATA_CMD itself.
       e.g. -o "-e;-B" to mvn -e -B
    -g "opt1=value;opt2": Global options.
    -p "opt1=value;opt2": Put-project options.
    -v "opt1=value;opt2": Put-version options.
    -s "opt1=value;opt2": push options
    -l "opt1=value;opt2": pull options
EOF
}

function to_camel_case(){
    echo $1 | sed -e 's,-\([a-z]\),\u\1,g'
}

MVN_SUBCMD_PREFIX="org.zanata:zanata-maven-plugin"
function mvn_subcmd(){
    echo "${MVN_SUBCMD_PREFIX}:$1"
}

function mvn_opts(){
    local opt
    opt=$1
    local str
    str=$2
    IFS=';' read -ra arr <<< "$str"
    for((i=0; i<${#arr[@]};i++));do
	local oStr
	oStr=${arr[$i]}
	local oName
        oName=`echo $oStr | sed -e 's|=.*$||'`
        oName=`to_camel_case $oName`
	local oValue
        oValue=`echo $oStr | sed -e 's|^[^=]*||' | sed -e 's|^=||'`
	local oOut
	if [[ -n "$oValue" ]];then
	    oOut="-Dzanata.$oName=$oValue"
	else
	    oOut="-Dzanata.$oName"
	fi 
	case $opt in
	    c )
		CMD_OPTS+=(-$oStr)
		;;
	    g )
		GLOBAL_OPTS+=("$oOut")
		;;
	    p )
		PRJ_OPTS+=("$oOut")
		;;
	    v )
		VER_OPTS+=("$oOut")
		;;
	    s )
		PUSH_OPTS+=("$oOut")
		;;
	    l)
		PULL_OPTS+=("$oOut")
		;;
	    * )
		;;
	esac
    done
}

function zanata-cli_subcmd(){
    echo $1
}

function zanata-cli_opts(){
    local opt
    opt=$1
    local str
    str=$2
    IFS=';' read -ra arr <<< "$str"
    opt=$1
    IFS=';' read -ra arr <<< "$str"
    for((i=0; i<${#arr[@]};i++));do
	local oStr
	oStr=${arr[$i]}
	local oName
	oName=`echo $oStr | sed -e 's|=.*$||'`
	local oValue
	oValue=`echo $oStr | sed -e 's|^[^=]*||' | sed -e 's|^=||'`
	case $opt in
	    c )
		CMD_OPTS+=(-$oStr)
		;;
	    g )
		GLOBAL_OPTS+=(--$oName "$oValue")
		;;
	    p )
		PRJ_OPTS+=(--$oName "$oValue")
		;;
	    v )
		VER_OPTS+=(--$oName "$oValue")
		;;
	    s )
		PUSH_OPTS+=(--$oName "$oValue")
		;;
	    l)
		PULL_OPTS+=(--$oName "$oValue")
		;;
	    * )
		;;
	esac
    done
}

[[ -z "${ZANATA_CMD}" ]] && export ZANATA_CMD=mvn
opt_parse="${ZANATA_CMD}_opts"
subcmd="${ZANATA_CMD}_subcmd"

while getopts "c:g:p:v:s:l:" opt;do
    ${opt_parse} $opt "$OPTARG"
done
shift $((OPTIND-1))
PRJ=$1
VER=$2
shift 2

${opt_parse} g "url=${ZANATA_URL}"
echo "####g ${GLOBAL_OPTS[@]}"
${opt_parse} p "project-slug=$PRJ"
echo "####p ${PRJ_OPTS[@]}"
echo "PRJ_OPTS=${#PRJ_OPTS[@]}"
for ((i=0;$i<${#PRJ_OPTS[@]};i++));do
    echo "$i ${PRJ_OPTS[$i]}"
done

${opt_parse} v "version-slug=$VER;version-project=$PRJ"


if [ ! -r zanata.xml ];then
    if [ -z "${ZANATA_URL}" ];then
	echo "ZANATA_URL should be defined." > /dev/stderr
        print_usage
	exit 1
    fi
fi

PUT_PRJ_CMD=`${subcmd} put-project`
time ${ZANATA_CMD} "${CMD_OPTS[@]}" "${PUT_PRJ_CMD[@]}" "${GLOBAL_OPTS[@]}" "${PRJ_OPTS[@]}" || exit 2

PUT_VER_CMD=`${subcmd} put-version`
time ${ZANATA_CMD} ${CMD_OPTS[@]} "${PUT_VER_CMD[@]}" "${GLOBAL_OPTS[@]}" "${VER_OPTS[@]}"  || exit 2
wget --no-check-certificate -O zanata.xml "${ZANATA_URL}iteration/view/${PRJ}/${VER}?cid=77&actionMethod=iteration%2Fview.xhtml%3AconfigurationAction.downloadGeneralConfig%28%29" 

PUSH_CMD=`${subcmd} push`
time ${ZANATA_CMD} "${CMD_OPTS[@]}" "${PUSH_CMD[@]}" "${GLOBAL_OPTS[@]}" "${PUSH_OPTS[@]}"  || exit 2

PULL_CMD=`${subcmd} pull`
time ${ZANATA_CMD} "${CMD_OPTS[@]}" "${PULL_CMD[@]}" "${GLOBAL_OPTS[@]}" "${PULL_OPTS[@]}"  || exit 2

