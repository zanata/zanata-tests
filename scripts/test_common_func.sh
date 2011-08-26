
function print_usage(){
    echo "$0 ${PARAMS}"
}

function is_allow_empty(){
    for i in ${PARAMS_ALLOW_EMPTY}; do
	if [ "$i" = "$1" ]; then
	    exit 0
	fi
    done
    exit 1
}


for para in ${PARAMS}; do
    if [ -z $1 ];then
	if ! is_allow_empty $para; then
	    echo "No value for ${para}" >/dev/stderr
	    print_usage ${PARAMS}
	    exit -1
	else
	    echo "Warn: No value for ${para}" >/dev/stderr
	fi
    fi
    eval "$para=$1"
    shift
    value=$(eval echo \$$para)
#    echo $para=${value}
done




