#!/bin/bash

function print_usage(){
    cat <<EOF
$0 <restPath> [<accept> [<method>]]
EOF
}

 : ${ZANATA_URL:=http://dchen-t60.usersys.redhat.com:8080/zanata/}

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

restPath=$1
accept=$2
method=$3

function curl_tests(){
    restPath=$1
    accept=$2
    method=$3
    if [ -z "$method" ];then
        method="GET"
    fi
    curlOpts=()

    if [ -n "$accept" ];then
        curlOpts+=(-H "Accept:$accept")
    fi

    ### Valid Auth
    curl -v -X $method -H "X-Auth-User:${ZANATA_USERNAME}" -H "X-Auth-Token:${ZANATA_KEY}" "${curlOpts[@]}" "${ZANATA_URL}rest${restPath}"

    echo -e "\n-----------------"

    ### No Auth
    curl -v -X $method "${curlOpts[@]}" "${ZANATA_URL}rest${restPath}"

    echo -e "\n================="

    ### Invalid auth
    curl -v -X $method -H "X-Auth-User:${ZANATA_USERNAME}" -H "X-Auth-Token:1" "${curlOpts[@]}" "${ZANATA_URL}rest${restPath}"
}

curl_tests "$restPath" "$accept" "$method"

