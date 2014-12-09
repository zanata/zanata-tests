SUPPORTED_VERSION:=rawhide 21 20
DISTRO:=fedora
IMAGE_PREFIX:=zanata-client
DOCKER_CMD:=docker

SUPPORTED=$(addprefix ${DISTRO}-,${SUPPORTED_VERSION})
SUPPORTED_DOCKERFILES=$(addsuffix /Dockerfile,${SUPPORTED})

SUPPORTED_CREATE=$(addsuffix -create,${SUPPORTED})
SUPPORTED_REFRESH=$(addsuffix -refresh,${SUPPORTED})
.PHONY : ${SUPPORTED_CREATE} ${SUPPORT_REFRESH}


all: ${SUPPORTED_CREATE}

# Create images
${SUPPORTED_CREATE}: ${DISTRO}-%-create : ${SUPPORTED_DOCKERFILES}
	${DOCKER_CMD} build --rm -t ${IMAGE_PREFIX}-${DISTRO}:$* ${DISTRO}-$*/

${SUPPORTED_DOCKERFILES}: ${DISTRO}-%/Dockerfile : Dockerfile.in
	mkdir -p ${DISTRO}-$*
	sed -e "s/@DISTRO@/${DISTRO}/g" Dockerfile.in | sed -e "s/@RELEASE@/$*/g" > $@


# Refresh images
${SUPPORTED_REFRESH}: ${DISTRO}-%-refresh : ${SUPPORTED_DOCKERFILES}
	${DOCKER_CMD} build --rm --nocache -t ${IMAGE_PREFIX}-${DISTRO}:$* ${DISTRO}-$*/


clean: 
	rm -fr ${SUPPORTED}

help:
	@echo "Available targets:"
	@echo "  all"
	@echo "  ${SUPPORTED_CREATE}"
	@echo "  ${SUPPORTED_REFRESH}"

