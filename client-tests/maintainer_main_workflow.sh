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

function mvn_opts(){
    opt=$1
    str=$2
    IFS=';' read -ra arr <<< "$str"
    for((i=0; i<${#arr[@]};i++));do
	o=${arr[$i]}
	case $opt in
	    c )
		echo -n "-$o "
		;;
	    * )
		echo -n "\"-Dzanata.$o\" "
		;;
	esac
    done
}


while getopts "c:g:p:v:s:l:" opt;do
    case $opt in
	c )
	    CMD_OPTS+=`mvn_opts $opt "$OPTARG"`
	    ;;
	g )
	    GLOBAL_OPTS+=`mvn_opts $opt "$OPTARG"`
	    ;;
	p )
	    PRJ_OPTS+=`mvn_opts $opt "$OPTARG"`
	    ;;
	v )
	    VER_OPTS+=`mvn_opts $opt "$OPTARG"`
	    ;;
	s )
	    PUSH_OPTS+=`mvn_opts $opt "$OPTARG"`
	    ;;
	l)
	    PULL_OPTS+=`mvn_opts $opt "$OPTARG"`
	    ;;
	* )
	    ;;
    esac
done
shift $((OPTIND-1))
PRJ=$1
VER=$2
shift 2

GLOBAL_OPTS+=`mvn_opts $opt "url=${ZANATA_URL}"`
PRJ_OPTS+=`mvn_opts p projectSlug=$PRJ`
VER_OPTS+=`mvn_opts p "versionSlug=$VER;versionProject=$PRJ"`

ZANATA_CMD=mvn
PUT_PRJ_CMD=zanata:put-project
PUT_VER_CMD=zanata:put-version
PUSH_CMD=zanata:push
PULL_CMD=zanata:pull

if [ ! -r zanata.xml ];then
    if [ -z "${ZANATA_URL}" ];then
	echo "ZANATA_URL should be defined." > /dev/stderr
	exit 1
    fi
fi

time ${ZANATA_CMD} ${CMD_OPTS} ${PUT_PRJ_CMD} ${GLOBAL_OPTS} ${PRJ_OPTS}
time ${ZANATA_CMD} ${CMD_OPTS} ${PUT_VER_CMD} ${GLOBAL_OPTS} ${VER_OPTS}
wget --no-check-certificate -O zanata.xml "${ZANATA_URL}iteration/view/${PRJ}/${VER}?cid=77&actionMethod=iteration%2Fview.xhtml%3AconfigurationAction.downloadGeneralConfig%28%29" 
time ${ZANATA_CMD} ${CMD_OPTS} ${PUSH_CMD} ${GLOBAL_OPTS} ${PUSH_OPTS}
time ${ZANATA_CMD} ${CMD_OPTS} ${PULL_CMD} ${GLOBAL_OPTS} ${PULL_OPTS}

