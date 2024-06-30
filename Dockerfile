# I originally designed this to be built in multiple stages, but it became a nightmare
FROM debian:bookworm-slim

LABEL Name=giglamesh
LABEL Version=0.0.1

# in order:
# scrcpy
# wayland
# wlroots
# cage
# wayvnc
# adb/platform tools for us & scrcpy
RUN echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get -y install ffmpeg libsdl2-2.0-0 adb wget \
                      gcc git pkg-config meson ninja-build libsdl2-dev \
                      libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
                      libswresample-dev libusb-1.0-0 libusb-1.0-0-dev \
                      \
                      expat libexpat1 libexpat1-dev libxml++2.6-2v5 libxml++2.6-dev \
                      doxygen graphviz xmlto xsltproc \
                      \
                      meson libxkbcommon-dev libpixman-1-dev \
                      xwayland libxcb1 libxcb1-dev libxcb-render-util0 libxcb-render-util0-dev libxcb-ewmh-dev libxcb-ewmh2 \
                      libxcb-errors-dev/bookworm-backports libxcb-errors0/bookworm-backports  \
                      libxcb-composite0-dev libxcb-composite0  \
                      libseat-dev libseat1 udev libudev-dev libudev1 libxcb-icccm4 libxcb-icccm4-dev \
                      libxcb-render-util0 libxcb-render-util0-dev libxcb-res0 libxcb-res0-dev libxcb-xfixes0 libxcb-xfixes0-dev \
                      \
                      libxkbcommon-dev libwlroots-dev libxkbcommon-dev \
                      \
                      meson libdrm-dev libxkbcommon-dev libwlroots-dev libjansson-dev \
                      libpam0g-dev libgnutls28-dev libavfilter-dev libavcodec-dev \
                      libavutil-dev libturbojpeg0-dev scdoc \
                      \
                      adb android-sdk-platform-tools-common fastboot cmake coreutils gettext-base \
    && apt-get clean

# we are going to do this all in one layer (each) to prevent the cache from balloning
# we would ./install_release.sh but we need to build the server first since we might be on arm64 and not the assumed x86_64

WORKDIR /deps

COPY install-dependencies.sh /deps/install-dependencies.sh
RUN chmod +x /deps/install-dependencies.sh
RUN /deps/install-dependencies.sh

# finally, we are done with the deps

WORKDIR /

ARG USERNAME=giglamesh
ARG USER_UID=1008
ARG USER_GID=$USER_UID

RUN groupadd -g $USER_GID $USERNAME \
    && useradd -u $USER_UID -g $USERNAME -m -s /bin/bash $USERNAME

RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

# Switch to non-root user (for security)
# This makes dockerfile_lint complain, but it's fine
# dockerfile_lint - ignore
USER $USERNAME

# Set the working directory to the user's home directory
WORKDIR /home/$USERNAME

RUN mkdir -p /home/$USERNAME/.config/wayvnc

# Copy the current directory contents into the container at /app
COPY --chown=$USERNAME:$USERNAME entrypoint.sh /home/$USERNAME/entrypoint.sh
RUN chmod +x /home/$USERNAME/entrypoint.sh
COPY --chown=$USERNAME:$USERNAME wayvnc/config_template /home/$USERNAME/.config/wayvnc/config_template

# Run the entrypoint script
ENTRYPOINT ["/home/giglamesh/entrypoint.sh"]
