#!/bin/sh
# Get the apikey

USER=
PASS=
if [ $# -ge 1 ]; then
    USER=$1
    PASS=$2
else
    USER=admin
    PASS=admin
fi

# Environment's ZANATA_PROFILE should take precedence
ZANATA_PROFILE_OVERRIDE=
if [ -n ${ZANATA_PROFILE} ]; then
	ZANATA_PROFILE_OVERRIDE=${ZANATA_PROFILE}
fi
source ./test.cfg
# Restore ZANATA_PROFILE
if [ -n ${ZANATA_PROFILE_OVERRIDE} ]; then
	ZANATA_PROFILE=${ZANATA_PROFILE_OVERRIDE}
fi
echo "Using ZANATA_PROFILE ${ZANATA_PROFILE}"
eval "ZANARA_SERVER_PROTO=\${${ZANATA_PROFILE}_SERVER_PROTO}"
if [ -z $ZANARA_SERVER_PROTO ]; then
    ZANARA_SERVER_PROTO=$SERVER_PROTO_DEFAULT
fi

eval "ZANARA_SERVER_PORT=\${${ZANATA_PROFILE}_SERVER_PORT}"
if [ -z $ZANARA_SERVER_PORT ]; then
    ZANARA_SERVER_PORT=$SERVER_PORT_DEFAULT
fi


eval "ZANATA_URL=${ZANARA_SERVER_PROTO}://\${${ZANATA_PROFILE}_SERVER_HOST}${ZANARA_SERVER_PORT}\${${ZANATA_PROFILE}_SERVER_PATH}"
echo "ZANATA_URL=${ZANATA_URL}"
COOKIE_FILE=cookie.file
curl --location --cookie-jar ${COOKIE_FILE} --output tmp0.html ${ZANATA_URL}/account/sign_in

# extract jsession id
#JSESSION_ID=`grep -m 1 '<form.*sign_in;jsessionid=' tmp0.html | sed -e 's/^.*sign_in//' | sed -e 's/".*//'`
#echo "JSESSION_ID=${JSESSION_ID}"

# extract form ViewState
VIEW_STATE_ID=javax.faces.ViewState
VIEW_STATE=`grep -m 1 name="\"${VIEW_STATE_ID}\"" tmp0.html | sed -e "s/^.*name=\"${VIEW_STATE_ID}\"[^>]*value=\"//" | sed -e 's/".*//'`
echo "VIEW_STATE=$VIEW_STATE"

# extract form signature
FORM_SIGNATURE=`grep -m 1 'name="javax.faces.FormSignature"' tmp0.html | sed -e 's/^.*name="javax.faces.FormSignature"[ \t]*value="//' | sed -e 's/".*//'`
echo "FORM_SIGNATURE=$FORM_SIGNATURE"


CMD1="curl --cookie ${COOKIE_FILE} --cookie-jar ${COOKIE_FILE}  --data 'login=login' --data \"javax.faces.FormSignature=${FORM_SIGNATURE}\" --data \"login%3AusernameField%3Ausername=${USER}\" --data \"login%3ApasswordField%3Apassword=${PASS}\" --data \"login%3ArememberMeField%3ArememberMe=on&login%3ASign_in=Sign+In&javax.faces.ViewState=${VIEW_STATE_ID}\" --location --output tmp1.html ${ZANATA_URL}/account/sign_form"

#CMD1="curl \"--cookie login=login;javax.faces.FormSignature=${FORM_SIGNATURE};login%3AusernameField%3Ausername=${USER};login%3ApasswordField%3Apassword=${PASS};login%3ArememberMeField%3ArememberMe=on;login:Sign_in=Sign+In;javax.faces.ViewState=${VIEW_STATE_ID}\" --cookie-jar ${COOKIE_FILE} --location --output tmp1.html ${ZANATA_URL}/account/sign_form"

#${JSESSION_ID}"
echo "CMD1=$CMD1"
eval "$CMD1"

curl --cookie ${COOKIE_FILE} --location --output tmp2.html ${ZANATA_URL}/profile/view

csplit -f tmpc tmp2.html '%Your current API key is%'
ret=`head --lines=2 tmpc00 | grep '<code>' | sed -e 's|^.*<code>||' | sed -e 's|</code>.*||'`
#rm -f tmpc tmp?.html ${COOKIE_FILE}
export APIKEY_${USER}=${ret}
eval echo APIKEY_${USER}=\${APIKEY_${USER}}
echo ${ret} > apikey.${USER}

