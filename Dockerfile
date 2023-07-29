FROM debian:12

# Install packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cabextract \
        gnupg \
        locales \
        openssh-server \
        s6 \
        sudo \
        unzip \
        wget \
        winbind \
        x11-utils \
        xterm \
        xvfb \
        xz-utils \
    && rm -f /etc/ssh/ssh_host_*

COPY util/static-dl /usr/local/bin/static-dl

# Install Xpra from upstream (the Debian version is old)
RUN static-dl \
        --hash 4df3209ea4b759f0b5838b60baedb6893ec62df7abad9046462176a6e6a7ed7d \
        --url https://xpra.org/xpra.asc \
        --out "/usr/share/keyrings/xpra.asc" \
    && static-dl \
        --hash 038b65b550a370dcde24123d2282e7d4e685d2f91888a8fb85d08f904c3f578d \
        --url https://xpra.org/repos/bookworm/xpra.sources \
        --out /etc/apt/sources.list.d/xpra.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends python3-rencode xpra

# Install Wine
RUN dpkg --add-architecture i386
RUN mkdir --parents --mode 755 /etc/apt/keyrings \
    && static-dl \
        --hash 78b185fabdb323971d13bd329fefc8038e08559aa51c4996de18db0639a51df6 \
        --url https://dl.winehq.org/wine-builds/winehq.key \
        --out /etc/apt/keyrings/winehq-archive.key \
    && static-dl \
        --hash 8dd8ef66c749d56e798646674c1c185a99b3ed6727ca0fbb5e493951e66c0f9e \
        --url https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources \
        --out /etc/apt/sources.list.d/winehq-bookworm.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends winehq-devel

# Install winetricks
RUN static-dl \
        --hash be4196ba3358be7c68cb58e7a7cbe9b37418e12e92beb88876e119998f438532 \
        --url https://raw.githubusercontent.com/Winetricks/winetricks/37aeb0bf34f0d6d2318276a6b4d96340d14621c3/src/winetricks \
        --out /usr/bin/winetricks \
    && chmod +x /usr/bin/winetricks

# Install Wine Mono
RUN static-dl \
        --url 'https://dl.winehq.org/wine/wine-mono/8.0.0/wine-mono-8.0.0-x86.tar.xz' \
        --hash 14c7d76780b79dc62d8ed9d1759e7adcfa332bb2406e2e694dee7b2128cc7a77 \
        --out /tmp/wine-mono.tar.xz \
    && mkdir --parents /opt/wine/mono \
    && tar xf /tmp/wine-mono.tar.xz -C /opt/wine/mono/ \
    && rm /tmp/wine-mono.tar.xz

# Add user with password-less sudo
ARG user=admin
RUN useradd --create-home --password '*' --shell /bin/bash "$user" \
    && echo "$user" ALL=\(root\) NOPASSWD:ALL > "/etc/sudoers.d/$user" \
    && chmod 0440 "/etc/sudoers.d/$user"
ENV PATH /home/$user/.local/bin:$PATH
USER "$user"

# Avoid the flood of "fixme" log messages.
ENV WINEDEBUG "fixme-all"

# Set variables, also for future use.
ENV WINEPREFIX "/home/admin/.wine"
RUN echo export WINEDEBUG=\'"$WINEDEBUG"\' >> ~/.profile \
    && echo export WINEPREFIX=\'"$WINEPREFIX"\' >> ~/.profile

ENV DISPLAY_NUM 42
ENV DISPLAY ":$DISPLAY_NUM"
RUN \
    sudo Xvfb "$DISPLAY" & \
    winetricks --unattended -q \
        sound=disabled \
        corefonts \
        d3dcompiler_47 \
        vcrun2019 \
        dotnet48 \
    && pkill wine \
    && sudo pkill Xvfb \
    && sudo rm -f "/tmp/.X$DISPLAY_NUM-lock"

# Configure SSH for the main user
RUN mkdir --parents /home/admin/.ssh \
    && chmod 700 /home/admin/.ssh
RUN touch ~/.Xauthority

USER root

# Prepare services
RUN mkdir --parents /var/run/sshd
COPY services /root/services
WORKDIR /root/services
COPY conf/xpra.conf /etc/xpra/xpra.conf
ENTRYPOINT ["s6-svscan", "/root/services"]
