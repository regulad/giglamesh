FROM debian:bookworm-slim

LABEL Name=giglamesh
LABEL Version=0.0.1

WORKDIR /deps
COPY install-cage-wayvnc.sh /deps/install-cage-wayvnc.sh
RUN chmod +x /deps/install-cage-wayvnc.sh
COPY install-scrcpy.sh /deps/install-scrcpy.sh
RUN chmod +x /deps/install-scrcpy.sh

# https://packages.debian.org/index
# in order:
# scrcpy
# wayland
# wlroots
# cage
# wayvnc
# adb/platform tools for us & scrcpy
# when we uninstall, only uninstall the development headers (the ones that end in -dev)
RUN echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free" >> /etc/apt/sources.list \
    && apt update \
    && apt -y install ffmpeg libsdl2-2.0-0 adb libusb-1.0-0 \
                      gcc git pkg-config meson ninja-build libsdl2-dev \
                      libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
                      libswresample-dev libusb-1.0-0-dev \
                      openjdk-17-jdk \
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
                      hwdata libdisplay-info-bin/bookworm-backports libdisplay-info-dev/bookworm-backports libdisplay-info1/bookworm-backports libliftoff0 libliftoff-dev \
                      \
                      libxkbcommon-dev libwlroots-dev libxkbcommon-dev \
                      \
                      meson libdrm-dev libxkbcommon-dev libwlroots-dev libjansson-dev \
                      libpam0g-dev libgnutls28-dev libavfilter-dev libavcodec-dev \
                      libavutil-dev libturbojpeg0-dev scdoc \
                      \
                      adb android-sdk-platform-tools-common fastboot cmake coreutils gettext-base weston \
    && /deps/install-scrcpy.sh \
    && /deps/install-cage-wayvnc.sh \
    && apt -y remove gcc pkg-config meson ninja-build libsdl2-dev libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
                      libswresample-dev libusb-1.0-0-dev libexpat1-dev libxml++2.6-dev \
                      doxygen graphviz xmlto xsltproc \
                      libxkbcommon-dev libpixman-1-dev \
                      libxcb1-dev libxcb-render-util0-dev libxcb-ewmh-dev libxcb-errors-dev/bookworm-backports \
                      libxcb-composite0-dev libseat-dev libudev-dev libxcb-icccm4-dev libxcb-render-util0-dev \
                      libxcb-res0-dev libxcb-xfixes0-dev libdisplay-info-dev/bookworm-backports libliftoff-dev \
                      libwlroots-dev libxkbcommon-dev libjansson-dev libpam0g-dev libgnutls28-dev libavfilter-dev \
                      libavcodec-dev libavutil-dev libturbojpeg0-dev scdoc \
    && apt clean

# finally, we are done with the deps
# we have to run as root to let cage access resources without setting the setuid bit because then we can't pass
# environment variables to cage at runtime

WORKDIR /

COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
COPY wayvnc_config_template /root/config_template

# Run the entrypoint script
ENTRYPOINT ["/bin/bash", "/root/entrypoint.sh"]
