ARG GROUP_ID=1001
ARG USER_ID=1001

FROM docker.io/techgk/arch:latest AS x11_arch

RUN pacman -Sy --disable-download-timeout --noconfirm \
        base-devel \
        binutils \
        code \
        fakeroot \
        git \
        mesa \
        procps \
        python \
        sudo \
        xorg-server \
        xorg-apps \
    && rm -rf /var/cache/pacman/pkg/* \
    && /bin/bash /root/skim.sh

ARG GROUP_ID
ARG USER_ID
ARG USER_NAME

COPY docker_files/entrypoint.sh /entrypoint.sh

RUN groupadd -g $GROUP_ID $USER_NAME \
    && useradd -u $USER_ID -g $GROUP_ID -G wheel -m $USER_NAME \
    && chmod ugo+x /entrypoint.sh

USER $USER_NAME

ENTRYPOINT ["/entrypoint.sh"]
CMD []
