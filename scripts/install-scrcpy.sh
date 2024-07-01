#!/bin/bash

# fail on error
set -e
set -o pipefail

# https://github.com/Genymobile/scrcpy/blob/master/doc/build.md#docker


# scrcpy server
SCRCPY_SERVER_SHA256=1488b1105d6aff534873a26bf610cd2aea06ee867dd7a4d9c6bb2c091396eb15
curl -L -o scrcpy-server "https://github.com/Genymobile/scrcpy/releases/download/v2.5/scrcpy-server-v2.5"
echo "$SCRCPY_SERVER_SHA256 scrcpy-server" | sha256sum -c
SCRCPY_SERVER_PATH="$(pwd)/scrcpy-server"

# will load everything into /usr/local/bin/scrcpy
git clone https://github.com/Genymobile/scrcpy
cd scrcpy/
git checkout a8871bfad77ed1d0b968f3919df685a301849f8f  # v2.5, same as the server
# we do not build the server, it would go here
meson setup "build-client/" --buildtype=release --strip -Db_lto=true -Dcompile_app=true -Dcompile_server=false -Dprebuilt_server=$SCRCPY_SERVER_PATH
# we do not compile the server, it would go here
ninja -C build-client/ install
cd ..
rm -rf scrcpy/  # we don't need to keep the source for the client
