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

#### Start Var
declare author="Ding-Yi Chen"
declare revdate=2015-02-03
declare revnumber=1
declare numbered
declare toc2

### The command for package management system
declare PACKAGE_SYSTEM_COMMAND=yum

### The command to install a package
declare PACKAGE_INSTALL_COMMAND="${PACKAGE_SYSTEM_COMMAND} -y install"

### The command to install a package in updates-testing
declare PACKAGE_INSTALL_UPDATE_REPO_COMMAND="${PACKAGE_SYSTEM_COMMAND} -y install --enablerepo=updates-testing"

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

### Docker instances for fedora releases
declare DOCKER_FEDORA_IMAGE_TAGS="rawhide f21 f20"

### Docker RHEL REPO
declare DOCKER_RHEL_REPO=""

### Docker RHEL REPO
declare DOCKER_RHEL_IMAGE_TAGS="latest"

### Zanata client package names
declare ZANATA_CLIENT_PACKAGE_NAMES="maven zanata-client zanata-python-client"

### Database backend in Fedora tags
declare DB_FEDORA_TAGS=([mariadb]="mariadb mariadb-server mysql-connector-java" [mysql]="mysql mysql-server mysql-connector-java")


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
	(start==1 && /^[^#]/ && $2 ~ nameFilter) { sub(/^\"/, "", $3); sub(/\"$/, "", $3); print $2 "\t" $3 "\t" descr ; descr="";} \
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
		'$2 ~ /[^\)]$/ {print "exportb " $1 "=\""$2"\"" ;} \
		$2 ~ /\)$/ {print "exporta " $1 "="$2 ;} '
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
	/^#### End Doc/ { start=0} \
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
### . Determine which docker image
lsbReleaseId=`lsb_release -is`
lsbReleaseRelease=`lsb_release -rs`
lsbReleaseReleaseMajor=$(sed -e 's/\..*$//' <<<$lsbReleaseRelease)
case "$lsbReleaseId" in
    RedHatEnterprise* )
	# RHEL
	if [[ $lsbReleaseMajor -le 5 ]];then
	    echo "RHEL 5 and earlier does not support docker" > /dev/stderr
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

### . Add +DOCKER_RUN_USER' to docker group if not already.
if ! grep docker &>/dev/null <<<$(id -Gn ${DOCKER_RUN_USER}); then
    sudo gpasswd -a ${DOCKER_RUN_USER} docker
fi

### . Enable and start docker service
sudo systemctl enable docker
sudo systemctl start docker

### == Setup Support Platforms
### We put all +DockerFile+ in sub-directory named <repo>:<tag>
### under +DOCKER_DOCKERFILE_TOP_DIR+
### 
function docker_image_build(){
    local from=$1
    local repoName=$2
    shift 2

    for tag in "$@" ;do
	local subDir=${DOCKER_DOCKERFILE_TOP_DIR}/${repoName}:${tag}
	mkdir -p ${subDir}
	local dockerFile=${subDir}/Dockerfile
	cat >${dockerFile}<<END
FROM ${from}:${tag}
MAINTAINER "Ding-Yi Chen" <dchen@redhat.com>
END
	cat >>${dockerFile}</dev/stdin
	sg docker "docker build --rm -t ${repoName}:${tag} ${subDir}/"
    done
}

### === Common Images
### Common images contain common environment for both server and client.
### That is, basic packages and users.
### It is build by following script
commonDockerScript=$(cat<<END
RUN ${PACKAGE_SYSTEM_COMMAND} -y update; ${PACKAGE_INSTALL_COMMAND} sudo wget git glibc-common; ${PACKAGE_SYSTEM_COMMAND} clean all
##Disable Defaults requiretty in sudoers file
RUN sed -ie 's/Defaults\\(.*\\)requiretty/ #Defaults\\1requiretty/g' /etc/sudoers
RUN groupadd ${DOCKER_IMAGE_SUDO_GROUP}; echo '%${DOCKER_IMAGE_SUDO_GROUP} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN cat > /etc/profiles.d/common.sh<<<'export PS1="[\u@\h \w]\\$ "'
RUN adduser -p "" -m zanata -G ${DOCKER_IMAGE_SUDO_GROUP};
END
)
for username in ${DOCKER_IMAGE_SUDO_USERS}; do
    commonDockerScript+=" adduser -p '' -m ${username} -G ${DOCKER_IMAGE_SUDO_GROUP}; "
done

### ==== Fedora
### Script to build Fedora common images
docker_image_build fedora znt_f ${DOCKER_FEDORA_IMAGE_TAGS} <<<"${commonDockerScript}"
### ==== RHEL
### If you have access to {DOCKER_RHEL_REPO} 
### then use following script to build RHEL common images. 
DOCKER_RHEL_REPO_SITE=$(sed -e 's|/.*$||' <<<${DOCKER_RHEL_REPO})
if ping -c 5 ${DOCKER_RHEL_REPO_SITE}; then
    DOCKER_RHEL_ENABLE=${DOCKER_RHEL_REPO_SITE}
fi

if [ -n "${DOCKER_RHEL_ENABLE}" ];then
    sg docker "docker pull ${DOCKER_RHEL_REPO}"

    docker_image_build ${DOCKER_RHEL_REPO} znt_r ${DOCKER_RHEL_IMAGE_TAGS} <<<"${commonDockerScript}"
fi
### === Client Images
### Docker images for following clients will be built: {ZANATA_CLIENT_PACKAGE_NAMES}
### ==== Fedora
for package in ${ZANATA_CLIENT_PACKAGE_NAMES};do
    docker_image_build znt_f znt_f_${package} ${DOCKER_FEDORA_IMAGE_TAGS} <<<"RUN ${PACKAGE_INSTALL_UPDATE_REPO_COMMAND} ${package}"
done
### === Server Images
### Database and JBoss will be built.
### ==== Fedora
### . Add database images
for db in "${!DB_FEDORA_TAGS[@]}";do
    docker_image_build znt_f znt_f_${db} ${DOCKER_FEDORA_IMAGE_TAGS} <<<"RUN ${PACKAGE_INSTALL_COMMAND} ${DB_FEDORA_TAGS[@]}"
done
### === Final
### You may need to re-login if you are not already in group docker.
#### End Doc

