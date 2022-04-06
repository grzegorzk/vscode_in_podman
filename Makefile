SHELL=/bin/bash

HOST_PATH_TO_REPOS=$${HOST_PATH_TO_REPOS?Please provide HOST_PATH_TO_REPOS}

DOCKER=podman

ARCH_IMAGE=x11_arch
UUID=$(shell id -u)
GUID=$(shell id -g)
UNAME=$(shell whoami)

WITH_USERNS=$$(eval [ "podman" == "${DOCKER}" ] && echo "--userns=keep-id")

MAKERC=.makerc
include ${CURDIR}/${MAKERC}

list:
	@ $(MAKE) -pRrq -f Makefile : 2>/dev/null \
		| grep -e "^[^[:blank:]]*:$$\|#.*recipe to execute" \
		| grep -B 1 "recipe to execute" \
		| grep -e "^[^#]*:$$" \
		| sed -e "s/\(.*\):/\1/g" \
		| sort

build:
	@ ${DOCKER} build \
		--build-arg USER_ID=${UUID} \
		--build-arg GROUP_ID=${GUID} \
		--build-arg USER_NAME=${UNAME} \
		-t ${ARCH_IMAGE} .;

run:
	@ ${DOCKER} run \
		${WITH_USERNS} \
		--security-opt label=type:container_runtime_t \
		--net=host -it --rm \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v /dev/dri:/dev/dri \
		-v $(HOME)/.Xauthority:"/home/${UNAME}/.Xauthority":Z \
		--device /dev/video0 \
		-e DISPLAY \
		-v /etc/machine-id:/etc/machine-id \
		-e EXTENSIONS_DIR=/extensions \
		-v "${CURDIR}"/docker_files/extensions:/extensions \
		-v "${CURDIR}"/.config:/home/${UNAME}/.config \
		-v "${HOST_PATH_TO_REPOS}":"${HOST_PATH_TO_REPOS}" \
		${ARCH_IMAGE} 
