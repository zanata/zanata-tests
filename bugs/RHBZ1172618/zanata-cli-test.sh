#!/bin/bash -x 

function print_usage(){
    cat <<EOF
$0 <commandPath> [<projectBaseDir> ...]
EOF
}

if [ $# -le 0 ]; then
    print_usage
    exit 1
fi

ok=1
for k in ZANATA_URL ZANATA_USERNAME ZANATA_KEY;do
    eval "v=\${${k}}"
    if [ -z "$v" ];then
         ok=0
         echo "Required environment var $k">/dev/stderr
    fi
done

if [ $ok -eq 0 ];then
    exit 2
fi

commandPath=$1
projectBaseDir=$2
if [ -z "$projectBaseDir" ];then
    projectBaseDir="."
fi
shift 2

function pull_tests(){
    subCommand=$1
    shift 

    echo -e "\n##################"
    ### Valid Auth
    $commandPath -B -e $subCommand --url ${ZANATA_URL} --username ${ZANATA_USERNAME} --key ${ZANATA_KEY} "$@"

    echo -e "\n-----------------"

    ### No Auth
    $commandPath -B -e $subCommand --url ${ZANATA_URL}  "$@"


    echo -e "\n================="

    ### Invalid auth
    $commandPath -B -e $subCommand --url ${ZANATA_URL}  --username ${ZANATA_USERNAME} --key invalid "$@"

}

cd ${projectBaseDir}

pull_tests pull "$@"
pull_tests stats "$@"
pull_tests list-remote "$@"


