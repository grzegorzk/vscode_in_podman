ARG GROUP_ID=1001
ARG USER_ID=1001

ARG ARCH_BASE_IMAGE

FROM docker.io/${ARCH_BASE_IMAGE} AS x11_arch

RUN pacman -Sy --disable-download-timeout --noconfirm \
        base-devel \
        binutils \
        fakeroot \
        git \
        gnome-keyring \
        mesa \
        openssh \
        sudo \
        procps \
        pulseaudio \
        pulseaudio-alsa \
        python \
        xorg-server \
        xorg-apps \
    && /bin/bash /root/skim.sh

ARG WITH_CUDA

RUN [ -n "${WITH_CUDA}" ] \
    && pacman -Sy --disable-download-timeout --noconfirm \
        nvidia \
        cuda \
        cudnn \
    || echo "Not installing CUDA"

RUN sed -i -- 's/#[ ]*\(%wheel[ ]*ALL[ ]*=[ ]*([ ]*ALL[ ]*:[ ]*ALL[ ]*)[ ]*NOPASSWD[ ]*:[ ]*ALL\)$/\1/gw /tmp/sed.done' /etc/sudoers \
    && [ -z "$(cat /tmp/sed.done | wc -l)" ] && echo "Failed to enable sudo for wheel group" && exit 1 \
    || echo "Enabled sudo for wheel group" && rm /tmp/sed.done

ARG GROUP_ID
ARG USER_ID
ARG USER_NAME
ARG VSCODE_PKGBUILD_VERSION

RUN groupadd -g $GROUP_ID $USER_NAME \
    && useradd -u $USER_ID -g $GROUP_ID -G wheel -m $USER_NAME

USER $USER_NAME

RUN cd /tmp \
    && git clone https://aur.archlinux.org/trizen.git \
    && cd trizen \
    && makepkg -si --noconfirm \
    && cd / \
    && rm -r /tmp/trizen

RUN cd /tmp \
    && gpg --recv-keys B26995E310250568 \
    && trizen -S --noconfirm \
        python38 \
        python39 \
    && trizen -G visual-studio-code-bin \
    && cd /tmp/visual-studio-code-bin \
    && git checkout ${VSCODE_PKGBUILD_VERSION} \
    && cd /tmp \
    && trizen -S --nopull --noconfirm --local visual-studio-code-bin \
    && rm -rf /tmp/visual-studio-code-bin \
    && trizen -Scc --aur --noconfirm

USER root

RUN sed -i -- 's/^[ ]*\(%wheel[ ]*ALL[ ]*=[ ]*([ ]*ALL[ ]*:[ ]*ALL[ ]*)[ ]*NOPASSWD[ ]*:[ ]*ALL\)$/# \1/gw /tmp/sed.done' /etc/sudoers \
   && [ -z "$(cat /tmp/sed.done | wc -l)" ] && echo "Failed to disable sudo for wheel group" && exit 1 \
   || echo "Disabled sudo for wheel group" && rm /tmp/sed.done

USER $USER_NAME

COPY docker_files/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD []
