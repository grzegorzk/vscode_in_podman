#!/usr/bin/env make
SHELL=/bin/bash

DOCKER=podman

HOST_PATH_TO_PROJECT=$${HOST_PATH_TO_PROJECT?Please provide HOST_PATH_TO_PROJECT}
CONTAINER_PATH_TO_MOUNT_PROJECT=$${CONTAINER_PATH_TO_MOUNT_PROJECT?Please provide CONTAINER_PATH_TO_MOUNT_PROJECT}

NO_NETWORK=
NETWORK=$$([ -n "${NO_NETWORK}" ] && echo "none" || echo "host")

WITH_NVIDIA_GPU=
NVIDIA_GPU=$$([ -n "${WITH_NVIDIA_GPU}" ] && echo $$([ DOCKER = "podman" ] && echo "--device nvidia.com/gpu=all --security-opt=label=disable" || echo "--privileged --gpus=all"))

OSS_CODE_IMAGE=oss_code_arch
OSS_CODE_CONTAINER=oss_code_arch
UUID=$(shell id -u)
GUID=$(shell id -g)
UNAME=$(shell whoami)

ARCH_BASE_IMAGE=techgk/arch:latest
VSCODE_PKGBUILD_VERSION=master

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
		--build-arg ARCH_BASE_IMAGE=${ARCH_BASE_IMAGE} \
		--build-arg VSCODE_PKGBUILD_VERSION=${VSCODE_PKGBUILD_VERSION} \
		--build-arg WITH_CUDA=${WITH_NVIDIA_GPU} \
		-t ${OSS_CODE_IMAGE} .;

run:
	@ ${DOCKER} run -d --rm \
		--shm-size 2g \
		--network ${NETWORK} \
		${NVIDIA_GPU} \
		--name "${OSS_CODE_CONTAINER}" \
		${WITH_USERNS} \
		--security-opt label=type:container_runtime_t \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v /dev/dri:/dev/dri \
		-v "$(HOME)"/.Xauthority:"/home/${UNAME}/.Xauthority":Z \
		--device /dev/video0 \
		-e DISPLAY \
		-e XAUTHORITY \
		-v ${XAUTHORITY}:${XAUTHORITY} \
		-v /etc/machine-id:/etc/machine-id \
		-v "$(HOME)"/.config/pulse/cookie:/home/${UNAME}/.config/pulse/cookie \
		-v /run/user/${UUID}/pulse:/run/user/${UUID}/pulse \
		-v /var/lib/dbus:/var/lib/dbus \
		--device /dev/snd \
		-e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
		-v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
		-v "$(CURDIR)"/docker_files/.ssh:/home/${UNAME}/.ssh \
		-e EXTENSIONS_DIR=/extensions \
		-v "${CURDIR}"/docker_files/extensions:/extensions \
		-v "${CURDIR}"/.config:/home/${UNAME}/.config \
		-v "${HOST_PATH_TO_PROJECT}":"${CONTAINER_PATH_TO_MOUNT_PROJECT}" \
		${OSS_CODE_IMAGE}

logs:
	@ ${DOCKER} logs -f "${OSS_CODE_CONTAINER}"

bash:
	@ ${DOCKER} exec -it "${OSS_CODE_CONTAINER}" /bin/bash
