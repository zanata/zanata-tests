#!/bin/sh -x
PRJ=$1
VER=$2
PUSH_TYPE=$3
shift 3

if [ -n "${PUSH_TYPE}" ];then
    PUSH_OPTS="-Dzanata.pushType=${PUSH_TYPE}"
else
    PUSH_OPTS=""
fi

if [ -n "${ZANATA_URL}" ];then
    AUTH_OPTS=-Dzanata.url=${ZANATA_URL}
fi
if [ -n "${ZANATA_USERNAME}" ];then
    AUTH_OPTS="${AUTH_OPTS} -Dzanata.username=${ZANATA_USERNAME}"
fi
if [ -n "${ZANATA_KEY}" ];then
    AUTH_OPTS+="${AUTH_OPTS} -Dzanata.key=${ZANATA_KEY}"
fi

mvn -B -e zanata:put-version ${AUTH_OPTS} -Dzanata.versionProject=${PRJ} -Dzanata.versionSlug=${VER} 
wget -O zanata.xml "${ZANATA_URL}iteration/view/${PRJ}/${VER}?cid=77&actionMethod=iteration%2Fview.xhtml%3AconfigurationAction.downloadGeneralConfig%28%29" 
mvn -B -e zanata:push ${AUTH_OPTS} ${PUSH_OPTS} $@
mvn -B -e zanata:pull ${AUTH_OPTS} $@

