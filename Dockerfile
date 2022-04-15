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
        openssh \
        sudo \
        xorg-server \
        xorg-apps \
    && rm -rf /var/cache/pacman/pkg/* \
    && /bin/bash /root/skim.sh

RUN sed -i -- 's/#[ ]*\(%wheel[ ]*ALL[ ]*=[ ]*([ ]*ALL[ ]*:[ ]*ALL[ ]*)[ ]*NOPASSWD[ ]*:[ ]*ALL\)$/\1/gw /tmp/sed.done' /etc/sudoers \
    && [ -z "$(cat /tmp/sed.done | wc -l)" ] && echo "Failed to enable sudo for wheel group" && exit 1 \
    || echo "Enabled sudo for wheel group" && rm /tmp/sed.done

ARG GROUP_ID
ARG USER_ID
ARG USER_NAME

COPY docker_files/entrypoint.sh /entrypoint.sh

RUN groupadd -g $GROUP_ID $USER_NAME \
    && useradd -u $USER_ID -g $GROUP_ID -G wheel -m $USER_NAME \
    && chmod ugo+x /entrypoint.sh

USER $USER_NAME

RUN cd /tmp \
    && git clone https://aur.archlinux.org/trizen.git \
    && cd trizen \
    && makepkg -si --noconfirm \
    && cd / \
    && rm -r /tmp/trizen

RUN trizen -S --noconfirm \
    code-features

USER root

RUN sed -i -- 's/^[ ]*\(%wheel[ ]*ALL[ ]*=[ ]*([ ]*ALL[ ]*:[ ]*ALL[ ]*)[ ]*NOPASSWD[ ]*:[ ]*ALL\)$/# \1/gw /tmp/sed.done' /etc/sudoers \
    && [ -z "$(cat /tmp/sed.done | wc -l)" ] && echo "Failed to disable sudo for wheel group" && exit 1 \
    || echo "Disabled sudo for wheel group" && rm /tmp/sed.done

USER $USER_NAME

ENTRYPOINT ["/entrypoint.sh"]
CMD []
