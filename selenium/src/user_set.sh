#!/bin/sh
if [ $# -le 0 ]; then
    print "Usage: $0 <user> [files-publican put user options]"
fi

USER=$1
case $USER in
	admin)
		PASS=admin
		HASH=Eyox7xbNQ09MkIfRyH+rjg==
		;;
	autotester)
		PASS=a10Tester
		HASH=DMAmVthsF0H09oxlwUqJUQ==
		;;
esac
shift

LANGUS=
FLIES_URL=
ROLES=
EMAIL=
for opt in $*;do
	case $opt in
		--flies)
			shift
			FLIES_URL=$1
			shift
			;;
		--email)
			shift
			EMAIL=$1
			shift
			;;
		--langs)
			shift
			LANGUS=$1
			shift
			;;
		--name)
			shift
			NAME=$1
			shift
			;;
		--roles)
			shift
			ROLES=$1
			shift
			;;
	esac
done

if [ -z ${FLIES_PUBLICAN} ];then
	FLIES_PUBLICAN=flies-publican
fi


if [ -z "$FLIES_URL" ]; then
    source ./test.cfg
fi

# Filling defaults
if [ -z "${EMAIL}" ]; then
	EMAIL=${USER}@example.com
fi
if [ -z "${NAME}" ]; then
	case $USER in
		admin)
			NAME="Administrator"
			;;
		autotester)
			NAME="Automate Tester"
			;;
		*)
			NAME="$USER"
			;;
	esac
fi
if [ -z "${ROLES}" ]; then
	if [ "${USER}" = "admin" ];then
		ROLES="user,admin"
	else
		ROLES="user"
	fi 
fi

./get_apikey.sh admin admin
APIKEY_admin=`cat apikey.admin`
if [ "${USER}" = "admin" ];then
    APIKEY_USER=${APIKEY_admin}
else
    ./get_apikey.sh $USER $PASS
    APIKEY_USER=`cat apikey.${USER}`
fi 
echo "USER=$USER NAME=$NAME"
echo "APIKEY_USER=${APIKEY_USER}"

CMD="$FLIES_PUBLICAN putuser -e --debug --user admin --key \"${APIKEY_admin}\" --flies \"${FLIES_URL}\"  --name \"${NAME}\" --username \"${USER}\" --email \"${EMAIL}\" --passwordhash \"${HASH}\" --userkey \"${APIKEY_USER}\" --roles \"${ROLES}\" --langs \"${LANGUS}\""
echo "CMD=$CMD"
eval "$CMD"

