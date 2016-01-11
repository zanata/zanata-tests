#!/bin/bash

function print_usage(){
    cat <<EOF
$0 <PRJ> <VER> <CONTRIBUTOR>
EOF
}

: ${ZANATA_URL:=http://dchen-svr.usersys.redhat.com:8080/zanata/}

if [ $# -le 0 ]; then
    print_usage
    exit 5
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

PRJ=$1
VER=$2
CONTRIBUTOR=$3
: ${DATE_FROM:=2015-07-01}
: ${DATE_TO:=2016-01-31}

function rest_query(){
    path="${ZANATA_URL}rest/stats/project/${PRJ}/version/${VER}/contributor/${CONTRIBUTOR}/${DATE_FROM}..${DATE_TO}"
    curl -v -X GET -H "X-Auth-User:${ZANATA_USERNAME}" -H "X-Auth-Token:${ZANATA_KEY}" -H "Content-Type:application/json" "$path"
}

rest_query
