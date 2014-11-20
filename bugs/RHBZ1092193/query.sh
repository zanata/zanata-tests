#!/bin/bash

function print_usage(){
    cat <<EOF
$0 <username>
EOF
}

ZANATA_URL=${ZANATA_URL:=http://dchen-t60.usersys.redhat.com:8080/zanata/}
USERNAME=${ZANATA_USERNAME:=alice}
API_KEY=${ZANATA_KEY:=128c87da802113d3a5ca8c34f473773f}
PRJ=${ZANATA_PROJECT_SLUG:=tar-a}
VER=${ZANATA_VERSION_SLUG:=1.27.1}
DATE_FROM=${DATE_FROM:-2014-11-20}
DATE_TO=${DATE_TO:-2014-12-31}

if [ $# -le 0 ]; then
    print_usage
    exit 1
fi

export QUERY_USER=$1
curl -v -X GET -H "X-Auth-User:${USERNAME}" -H "X-Auth-Token:${API_KEY}" -H "Content-Type:application/json" "${ZANATA_URL}rest/stats/project/${PRJ}/version/${VER}/contributor/${QUERY_USER}/${DATE_FROM}..${DATE_TO}"

