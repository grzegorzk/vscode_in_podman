SHELL=/bin/bash

HOST_PATH_TO_PROJECT=$${HOST_PATH_TO_PROJECT?Please provide HOST_PATH_TO_PROJECT}
CONTAINER_PATH_TO_MOUNT_PROJECT=$${CONTAINER_PATH_TO_MOUNT_PROJECT?Please provide CONTAINER_PATH_TO_MOUNT_PROJECT}

DOCKER=podman

ARCH_IMAGE=x11_arch
CODE_CONTAINER=code_arch
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
	@ ${DOCKER} run -d --rm \
		--network none \
		--name "${CODE_CONTAINER}" \
		${WITH_USERNS} \
		--security-opt label=type:container_runtime_t \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v /dev/dri:/dev/dri \
		-v "$(HOME)"/.Xauthority:"/home/${UNAME}/.Xauthority":Z \
		--device /dev/video0 \
		-e DISPLAY \
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
		${ARCH_IMAGE}

logs:
	@ ${DOCKER} logs -f "${CODE_CONTAINER}"

bash:
	@ ${DOCKER} exec -it "${CODE_CONTAINER}" /bin/bash
