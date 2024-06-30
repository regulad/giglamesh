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
RUN apt-get update \
    && apt -y install ffmpeg libsdl2-2.0-0 adb wget \
                      gcc git pkg-config meson ninja-build libsdl2-dev \
                      libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
                      libswresample-dev libusb-1.0-0 libusb-1.0-0-dev \
                      \
                      expat libexpat1 libexpat1-dev libxml++2.6-2v5 libxml++2.6-dev \
                      \
                      meson libwayland-dev wayland-protocols libdrm-dev libxkbcommon-dev libpixman-1-dev \
                      \
                      libwayland-dev libxkbcommon-dev \
                      \
                      meson libdrm-dev libxkbcommon-dev libwlroots-dev libjansson-dev \
                      libpam0g-dev libgnutls28-dev libavfilter-dev libavcodec-dev \
                      libavutil-dev libturbojpeg0-dev scdoc \
                      \
                      adb android-sdk-platform-tools-common fastboot cmake \
    && apt-get clean

# we are going to do this all in one layer (each) to prevent the cache from balloning
# we would ./install_release.sh but we need to build the server first since we might be on arm64 and not the assumed x86_64

WORKDIR /deps

# will load everything into /usr/local/bin/scrcpy
RUN git clone https://github.com/Genymobile/scrcpy \
    && cd scrcpy/ \
    && meson setup "build-server/" --buildtype=release --strip -Db_lto=true -Dcompile_app=false -Dcompile_server=true \
    && meson setup "build-client/" --buildtype=release --strip -Db_lto=true -Dcompile_app=true -Dcompile_server=false -Dprebuilt_server=/scrcpy/build-server/scrcpy-server \
    && ninja -C build-client/ install \
    && cd .. \
    && rm -rf scrcpy

# build & install wayland (dependency for wlroots, needs a new version)
RUN git clone https://gitlab.freedesktop.org/wayland/wayland.git \
    && cd wayland/ \
    && meson setup build/ \
    && ninja -C build/ -Dtests=false -Ddocumentation=false \
    && ninja -C build/ install \
    && cd .. \
    && rm -rf wayland

# build & install wlroots (dependency for cage)
RUN git clone https://gitlab.freedesktop.org/wlroots/wlroots.git \
    && cd wlroots/ \
    && meson setup build/ \
    && ninja -C build/ \
    && ninja -C build/ install \
    && cd .. \
    && rm -rf wlroots

# now build cage (our kiosk compositor)
RUN git clone https://github.com/cage-kiosk/cage.git \
    && cd cage/ \
    && meson build \
    && ninja -C build \
    && ninja -C build install \
    && cd .. \
    && rm -rf cage

# now build wayvnc (our vnc server)
# https://github.com/any1/wayvnc#configure-and-build
RUN git clone https://github.com/any1/wayvnc.git \
    && git clone https://github.com/any1/neatvnc.git \
    && git clone https://github.com/any1/aml.git \
    && mkdir wayvnc/subprojects \
    && cd wayvnc/subprojects \
    && ln -s ../../neatvnc . \
    && ln -s ../../aml . \
    && cd ../.. \
    && mkdir neatvnc/subprojects \
    && cd neatvnc/subprojects \
    && ln -s ../../aml . \
    && cd ../.. \
    && cd wayvnc/ \
    && meson build \
    && ninja -C build \
    && ninja -C build install \
    && cd .. \
    && rm -rf wayvnc neatvnc aml

WORKDIR /

ARG USERNAME=giglamesh
ARG USER_UID=1008
ARG USER_GID=$USER_UID

RUN addgroup -g $USER_GID -S $USERNAME \
    && adduser -u $USER_UID -G $USERNAME -D -S $USERNAME

RUN mkdir -p /home/$USERNAME \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME

# Switch to non-root user (for security)
# This makes dockerfile_lint complain, but it's fine
# dockerfile_lint - ignore
USER $USERNAME

# Set the working directory to the user's home directory
WORKDIR /home/$USERNAME

# Copy the current directory contents into the container at /app
COPY entrypoint.sh /home/$USERNAME/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /home/$USERNAME/entrypoint.sh

# Run the entrypoint script
ENTRYPOINT ["/home/giglamesh/entrypoint.sh"]
