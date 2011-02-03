
function print_usage(){
    echo "$0 ${PARAMS}"
}


for para in ${PARAMS}; do
    if [ -z $1 ];then
	echo "No value for ${para}" >/dev/stderr
	print_usage ${PARAMS}
	exit -1
    fi
    eval "$para=$1"
    shift
    value=$(eval echo \$$para)
#    echo $para=${value}
done




