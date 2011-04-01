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

if [ -z "$ZANATA_URL" ]; then
    source ./test.cfg
fi
echo "ZANATA_URL=$ZANATA_URL"
COOKIE_FILE=cookie.file
curl --cookie-jar ${COOKIE_FILE} --output tmp0.html ${ZANATA_URL}/account/sign_in

# extract jsession id
JSESSION_ID=`grep -m 1 '<form.*sign_in;jsessionid=' tmp0.html | sed -e 's/^.*sign_in//' | sed -e 's/".*//'`
echo "JSESSION_ID=${JSESSION_ID}"

# extract form signature
FORM_SIGNATURE=`grep -m 1 'name="javax.faces.FormSignature"' tmp0.html | sed -e 's/^.*name="javax.faces.FormSignature"[ \t]*value="//' | sed -e 's/".*//'`
echo "FORM_SIGNATURE=$FORM_SIGNATURE"


CMD1="curl --cookie ${COOKIE_FILE} --cookie-jar ${COOKIE_FILE}  --data 'login=login' --data \"javax.faces.FormSignature=${FORM_SIGNATURE}\" --data \"login%3AusernameField%3Ausername=${USER}\" --data \"login%3ApasswordField%3Apassword=${PASS}\" --data \"login%3ArememberMeField%3ArememberMe=on&login%3Aj_id117=Sign+In&javax.faces.ViewState=j_id1\" --location --output tmp1.html ${ZANATA_URL}/account/sign_in${JSESSION_ID}"
#echo "CMD1=$CMD1"
eval "$CMD1"

curl --cookie ${COOKIE_FILE} --location --output tmp2.html ${ZANATA_URL}/profile/view

csplit -f tmpc tmp2.html '%Your current API%'
ret=`head --lines=2 tmpc00 | grep '<code>' | sed -e 's|^.*<code>||' | sed -e 's|</code>.*||'`
rm -f tmpc tmp?.html ${COOKIE_FILE}
export APIKEY_${USER}=${ret}
eval echo APIKEY_${USER}=\${APIKEY_${USER}}
echo ${ret} > apikey.${USER}

