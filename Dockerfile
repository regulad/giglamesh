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
                      doxygen graphviz xmlto xsltproc \
                      \
                      meson libxkbcommon-dev libpixman-1-dev \
                      \
                      libxkbcommon-dev \
                      \
                      meson libxkbcommon-dev libjansson-dev \
                      libpam0g-dev libgnutls28-dev libavfilter-dev libavcodec-dev \
                      libavutil-dev libturbojpeg0-dev scdoc \
                      \
                      adb android-sdk-platform-tools-common fastboot cmake coreutils \
    && apt-get clean

# we are going to do this all in one layer (each) to prevent the cache from balloning
# we would ./install_release.sh but we need to build the server first since we might be on arm64 and not the assumed x86_64

WORKDIR /deps

# build & install wayland (dependency for wlroots, needs a new version)
RUN git clone https://gitlab.freedesktop.org/wayland/wayland.git \
    && cd wayland/ \
    && git checkout 1d5772b7b9d0bbfbc27557721f62a9f805b66929 \
    && meson build/ \
    && ninja -C build/ install \
    && cd .. \
    && rm -rf wayland

# build & install libdrm (dep for wlroots, needs a new version)
RUN git clone https://gitlab.freedesktop.org/mesa/drm.git \
    && cd drm/ \
    && git checkout b065dbc5cc91bab36856c7f7d6610ddf0a3bfd75 \
    && meson build/ \
    && ninja -C build/ install \
    && cd .. \
    && rm -rf drm

# build & install wayland-protocol (dep for wlroots, needs a new version)
RUN git clone https://gitlab.freedesktop.org/wayland/wayland-protocols.git \
    && cd wayland-protocols/ \
    && git checkout 7d5a3a8b494ae44cd9651f9505e88a250082765e \
    && meson build/ \
    && ninja -C build/ install \
    && cd .. \
    && rm -rf wayland-protocols

# build & install wlroots (dependency for cage)
RUN git clone https://gitlab.freedesktop.org/wlroots/wlroots.git \
    && cd wlroots/ \
    && git checkout 54ec69f682a5c49300ca2ed285913bcedeee5c06 \
    && meson setup build/ \
    && ninja -C build/ \
    && ninja -C build/ install \
    && cd .. \
    && rm -rf wlroots

# now build cage (our kiosk compositor)
RUN git clone https://github.com/cage-kiosk/cage.git \
    && cd cage/ \
    && git checkout e7d8780f46277af87881e0be91cb2092541bb1d5 \
    && meson build \
    && ninja -C build \
    && ninja -C build install \
    && cd .. \
    && rm -rf cage

# now build wayvnc (our vnc server) (2d62e1203e5589cf754e9b7031ddc609124cf156 at authoring)
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

# will load everything into /usr/local/bin/scrcpy (a8871bfad77ed1d0b968f3919df685a301849f8f at authoring)
RUN git clone https://github.com/Genymobile/scrcpy \
    && cd scrcpy/ \
    && meson setup "build-server/" --buildtype=release --strip -Db_lto=true -Dcompile_app=false -Dcompile_server=true \
    && meson setup "build-client/" --buildtype=release --strip -Db_lto=true -Dcompile_app=true -Dcompile_server=false -Dprebuilt_server=/scrcpy/build-server/scrcpy-server \
    && ninja -C build-client/ install \
    && cd .. \
    && rm -rf scrcpy

# add go to path for envsubst
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.4.linux-$(arch).tar.gz
ENV PATH=$PATH:/usr/local/go/bin
RUN go install github.com/a8m/envsubst/cmd/envsubst@latest # v1.4.2 at authoring

# finally, we are done with the deps

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
COPY wayvnc/config_template /home/$USERNAME/.config/wayvnc/config_template

# Make the entrypoint script executable
RUN chmod +x /home/$USERNAME/entrypoint.sh

# Run the entrypoint script
ENTRYPOINT ["/home/giglamesh/entrypoint.sh"]
