#!/bin/bash
set -e 
set -o pipefail

function print_usage(){
    cat <<END
NAME
----
$0 -  Setup docker environment for Zanata

SYNOPSIS
--------
$0

DESCRIPTION
-----------
    Setup docker environment for Zanata


EXIT STATUS
-----------
    ${EXIT_CODE_OK} if successiful
    ${EXIT_CODE_DEPENDENCY_MISSING} if dependency is missing
    ${EXIT_CODE_INVALID_ARGUMENTS} invalid or missing arguments


ENVIRONMENT
-----------
END
    print_variables usage $0
}
ZANATA_DOCKER_SCRIPT_DIR=$(readlink -f `dirname $0`)

#### Start Var
declare author="Ding-Yi Chen"
declare revdate=2015-04-20
declare revnumber=1
declare numbered
declare toc2


### The command for package management system
declare PACKAGE_SYSTEM_COMMAND=yum

### The command to install a package
declare PACKAGE_INSTALL_COMMAND="${PACKAGE_SYSTEM_COMMAND} -y install"

### The command to check list matched package in repo
declare PACKAGE_LIST_COMMAND="${PACKAGE_SYSETEM_COMMAND} list"

### The command to check whether the package is installed
declare PACKAGE_EXIST_COMMAND="rpm -q"

### The package name of docker
declare DOCKER_PACKAGE_NAME=docker

### The user to run docker
declare DOCKER_RUN_USER="${DOCKER_RUN_USER:=$USER}"

### Group for sudo inside docker image
declare DOCKER_IMAGE_SUDO_GROUP="sudo"

### Users for sudo inside docker
declare DOCKER_IMAGE_SUDO_USERS="alice grace irene peggy queen"

### Base dir for generate docker file
declare DOCKER_DOCKERFILE_TOP_DIR="${DOCKER_DOCKERFILE_TOP_DIR:-$PWD}"

### Docker instances for fedora releases except rawhide
declare DOCKER_FEDORA_IMAGE_TAGS="21 20"

### Docker Centos
declare DOCKER_CENTOS_IMAGE_TAGS="7"

### Zanata client Fedora package names
declare ZANATA_CLIENT_FEDORA_PACKAGE_NAMES="maven zanata-client zanata-python-client"

### Zanata client CentOS package names
declare ZANATA_CLIENT_CENTOS_PACKAGE_NAMES="maven zanata-python-client"

### Database backend in Fedora tags
declare -A DB_FEDORA_TAGS=([mariadb]="mariadb mariadb-server mysql-connector-java" [mysql]="mysql mysql-server mysql-connector-java")


### Database backend in Centos tags
declare -A DB_CENTOS_TAGS=([mariadb]="mariadb mariadb-server mysql-connector-java" [mysql]="mysql mysql-server mysql-connector-java")

### Base of work directories
declare WORK_BASE_DIR="/tmp"

#### End Var


#===== Start Guide Functions =====

## Exit status
export EXIT_CODE_OK=0
export EXIT_CODE_INVALID_ARGUMENTS=3
export EXIT_CODE_DEPENDENCY_MISSING=4
export EXIT_CODE_ERROR=5
export EXIT_CODE_FAILED=6
export EXIT_CODE_SKIPPED=7
export EXIT_CODE_FATAL=125

function extract_variable(){
    local file=$1
    local nameFilter=$2
    awk -v nameFilter="$nameFilter" \
	'BEGIN {FPAT = "(\"[^\"]+\")|(\\(.+\\))|([^ =]+)"; start=0; descr=""} \
	/^#### End Var/ { start=0} \
	(start==1 && /^[^#]/ && $2 != "-A" && $2 ~ nameFilter) { sub(/^\"/, "", $3); sub(/\"$/, "", $3); print $2 "\t" $3 "\t" descr ; descr="";} \
	(start==1 && /^[^#]/ && $2 == "-A" && $3 ~ nameFilter) { print $3 "\t" $4} \
	(start==1 && /^###/) { gsub("^###[ ]?","", $0) ; descr=$0} \
	/^#### Start Var/ { start=1; } ' $file
}

function print_variables(){
    local format=$1
    local file=$2
    case $format in
	asciidoc )
	    extract_variable $file | awk -F '\\t' 'BEGIN { done=0 } \
		$2 ~ /^\$\{.*:[=-]/ { ret=gensub(/^\$\{.*:[=-](.+)\}/, "\\1", "g", $2) ; print ":" $1 ": " ret; done=1 }\
		done==0  {print ":" $1 ": " $2 ; done=1 }\
		done==1  {done=0}'
	    ;;
	bash )
	    extract_variable $file "^[A-Z]" | awk -F '\\t' \
		'$2 ~ /[^\)]$/ {print "export " $1 "=\""$2"\"" ;} \
		$2 ~ /\)$/ {print "export " $1 "=" $2 ;} '
	    ;;
	usage )
	    extract_variable $file "^[A-Z]" | awk -F '\\t' '{print $1 "::"; \
		if ( $3 != "" ) {print "    " $3  }; \
		print "    Default: " $2 "\n"}'
	    ;;	    
	* )
	    ;;
    esac
}

function to_asciidoc(){  
    print_variables asciidoc $0
    # Extract variable

    awk 'BEGIN {start=0;sh_start=0; in_list=0} \
	/^#### End Doc/ { print "" ; start=0} \
	(start==1 && /^[^#]/ ) { if (sh_start==0) {sh_start=1; if (in_list ==1 ) {print "+"}; print "[source,sh]"; print "----"} print $0;} \
	(start==1 && /^### \./ ) { in_list=1 } \
	(start==1 && /^###/ ) { if (sh_start==1) {sh_start=0; print "----"} gsub("^###[ ]?","", $0) ; print $0;} \
	/^#### Start Doc/ { start=1; } ' $0
    echo "== Default Environment Variables"
    echo "[source,sh]"
    echo "----"
    # Extract variable
    print_variables bash $0
    echo "----"
}

while [ -n "$1" ];do
    case $1 in
	--asciidoc )
	    to_asciidoc
	    exit 0
	    ;;
	--help | -h )
	    print_usage
	    exit 0
	    ;;
	* )
	    echo "Invalid argument $1" > /dev/stderr
	    exit ${EXIT_CODE_INVALID_ARGUMENTS}
	    ;;
    esac
    shift
done
#===== End Guide Functions =====


#### Start Doc
### = Zanata docker test environment Setup Guide
### Document Version {revnumber}-{revdate}
### 
### This document shows the steps to install docker environment for zanata-tests
###
### == Steps
### . Obtain zanata-tests
### +
### ----
### cd ${WORK_BASE_DIR}
### git clone https://github.com/zanata/zanata-tests.git
### cd zanata-tests
### ----
### +
### . Determine docker package name:
lsbReleaseId=`lsb_release -is`
lsbReleaseRelease=`lsb_release -rs`
lsbReleaseReleaseMajor=$(sed -e 's/\..*$//' <<<$lsbReleaseRelease)
case "$lsbReleaseId" in
    RedHatEnterprise* )
	# CENTOS
	if [[ $lsbReleaseReleaseMajor -le 5 ]];then
	    echo "CENTOS 5 and earlier does not support docker" > /dev/stderr
	    exit $DEPENDENCY_MISSING
	fi
	distroCompatible=RedHat
	;;
    Fedora* )
	DOCKER_PACKAGE_NAME=docker-io
	distroCompatible=RedHat
	;;
    * )
	;;
esac
### . Install +{DOCKER_PACKAGE_NAME}+ if it is not already installed.
if ! ${PACKAGE_EXIST_COMMAND} "${DOCKER_PACKAGE_NAME}";then
    if ! sudo ${PACKAGE_INSTALL_COMMAND} $p; then
	echo "Error: ${PACKAGE_INSTALL_COMMAND} $p" >/dev/stderr
	exit ${EXIT_CODE_DEPENDENCY_MISSING}
    fi
fi

### . Add docker group if not already
if ! grep "^docker:" /etc/group &>/dev/null;then
    sudo groupadd docker
fi

### . Add +DOCKER_RUN_USER+ to docker group if not already.
if ! grep docker &>/dev/null <<<$(id -Gn ${DOCKER_RUN_USER}); then
    sudo gpasswd -a ${DOCKER_RUN_USER} docker
fi

### . Enable docker service if not enabled
if ! systemctl -q is-enabled docker; then
    sudo systemctl enable docker
fi

### . Start docker service if not active
if ! systemctl -q is-active docker; then
    sudo systemctl start docker
fi

### == Setup Support Platforms
###
### === Base images
### Base images contain basic utilities, users, and yum repository
###
### ==== Base images for Fedora
### Dockerfile and image for fedora {DOCKER_FEDORA_IMAGE_TAGS} will be build with following
adduserSnipplet=
for username in ${DOCKER_IMAGE_SUDO_USERS}; do
    adduserSnipplet+=" adduser -p '' -m ${username} -G ${DOCKER_IMAGE_SUDO_GROUP}; "
done

for tag in ${DOCKER_FEDORA_IMAGE_TAGS}; do
    repo="fedora"
    imageName="znt-fedora:${tag}"
    ${ZANATA_DOCKER_SCRIPT_DIR}/docker-make-dockerfile -a \
	-b ${WORK_BASE_DIR} -t ${imageName} $repo $tag \
	${ZANATA_DOCKER_SCRIPT_DIR}/Dockerfile.${repo}.in \
	<<< "RUN $adduserSnipplet"
    subDir="${WORK_BASE_DIR}/${imageName}"
    sg docker "docker build --rm -t ${imageName} ${subDir}/"
done

### ==== Base images for CentOS
### Dockerfile and image for fedora {DOCKER_FEDORA_IMAGE_TAGS} will be build with following

for tag in ${DOCKER_CENTOS_IMAGE_TAGS}; do
    repo="centos"
    imageName="znt-${repo}:${tag}"
    ${ZANATA_DOCKER_SCRIPT_DIR}/docker-make-dockerfile -a \
	-b ${WORK_BASE_DIR} -t ${imageName} $repo $tag \
	${ZANATA_DOCKER_SCRIPT_DIR}/Dockerfile.${repo}.in \
	<<< $adduserSnipplet
    subDir="${WORK_BASE_DIR}/${imageName}"
    sg docker "docker build --rm -t ${imageName} ${subDir}/"
done
###
### === Server Images
### Images with databases
### ==== Fedora
### . Add database to images

for db in "${!DB_FEDORA_TAGS[@]}";do
    databasePkgs="${DB_FEDORA_TAGS[$db]}"

    for tag in ${DOCKER_FEDORA_IMAGE_TAGS}; do
	repo="znt-fedora"
	imageName="${repo}-${db}:${tag}"
	if [ "$tag" = "rawhide" ];then
	    ${ZANATA_DOCKER_SCRIPT_DIR}/docker-make-dockerfile -a \
		-b ${WORK_BASE_DIR} -t ${imageName} $repo $tag \
		<<< "RUN yum -y install ${databasePkgs}"
	else
	    ${ZANATA_DOCKER_SCRIPT_DIR}/docker-make-dockerfile -a \
		-b ${WORK_BASE_DIR} -t ${imageName} $repo $tag \
		<<< "RUN yum -y --enablerepo=updates-testing install ${databasePkgs}"
	fi
	subDir="${WORK_BASE_DIR}/${imageName}"
	sg docker "docker build --rm -t ${imageName} ${subDir}/"
    done
done

### ==== CentOS
### . Add database to images
for db in "${!DB_CENTOS_TAGS[@]}";do
    databasePkgs="${DB_CENTOS_TAGS[$db]}"

    for tag in ${DOCKER_CENTOS_IMAGE_TAGS}; do
	repo="znt-centos"
	imageName="${repo}-${db}:${tag}"
	${ZANATA_DOCKER_SCRIPT_DIR}/docker-make-dockerfile -a \
	    -b ${WORK_BASE_DIR} -t ${imageName} $repo $tag \
	    <<< "RUN yum -y --enablerepo=epel-testing install ${databasePkgs}"
	subDir="${WORK_BASE_DIR}/${imageName}"
	sg docker "docker build --rm -t ${imageName} ${subDir}/"
    done
done

### == Final
### You may need to re-login if you are not already in group docker.
#### End Doc

