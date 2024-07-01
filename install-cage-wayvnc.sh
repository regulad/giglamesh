#!/bin/bash

# fail on error
set -e
set -o pipefail

# build & install wayland (dependency for wlroots, needs a new version)
git clone https://gitlab.freedesktop.org/wayland/wayland.git
cd wayland/ && git checkout 1d5772b7b9d0bbfbc27557721f62a9f805b66929 && cd ..
#meson build/
#ninja -C build/ install

# build & install libdrm (dep for wlroots, needs a new version)
git clone https://gitlab.freedesktop.org/mesa/drm.git
cd drm/ && git checkout b065dbc5cc91bab36856c7f7d6610ddf0a3bfd75 && cd ..
#meson build/
#ninja -C build/ install

# build & install wayland-protocol (dep for wlroots, needs a new version)
git clone https://gitlab.freedesktop.org/wayland/wayland-protocols.git
cd wayland-protocols/
git checkout 7d5a3a8b494ae44cd9651f9505e88a250082765e

mkdir subprojects
cd subprojects
ln -s ../../wayland .
cd ..

#meson build/
#ninja -C build/ install
cd ..

# build & install wlroots (dependency for cage) (pinned to v0.17.0)
git clone https://gitlab.freedesktop.org/wlroots/wlroots.git
cd wlroots/
git checkout a2d2c38a3127745629293066beeed0a649dff8de

mkdir subprojects
cd subprojects
ln -s ../../wayland .
ln -s ../../wayland-protocols .
ln -s ../../drm .
cd ..

meson setup build/ -Dxwayland=enabled # -Dlogind=enabled -Dlogind-provider=elogind  # couldn't get it to build nor dependencies to solve
#ninja -C build/ install
cd ..

# now build cage (our kiosk compositor)
git clone https://github.com/cage-kiosk/cage.git
cd cage/
git checkout e7d8780f46277af87881e0be91cb2092541bb1d5

mkdir subprojects
cd subprojects
ln -s ../../wlroots .
ln -s ../../wayland .
ln -s ../../wayland-protocols .
cd ..

meson build/ -Dxwayland=enabled
ninja -C build/ install
cd ..

# now build wayvnc (our vnc server)
git clone https://github.com/any1/wayvnc.git
cd wayvnc/ && git checkout 2d62e1203e5589cf754e9b7031ddc609124cf156 && cd ..
git clone https://github.com/any1/neatvnc.git
cd neatvnc/ && git checkout 76ea172a78096ad74e03c7138ca4909c4894ae41 && cd ..
git clone https://github.com/any1/aml.git
cd aml/ && git checkout ef33f2d8d1187afbf89b07f84ad9e82a1a87e8e4 && cd ..

mkdir wayvnc/subprojects
cd wayvnc/subprojects
ln -s ../../neatvnc .
ln -s ../../aml .
cd ../..

mkdir neatvnc/subprojects
cd neatvnc/subprojects
ln -s ../../aml .
cd ../..

cd wayvnc/
meson build/
ninja -C build/
ninja -C build/ install
cd ..

# now with cage & wayvnc installed, we can remove the build directories
rm -rf wayvnc/ cage/ wlroots/ wayland/ wayland-protocols/ drm/ neatvnc/ aml/
