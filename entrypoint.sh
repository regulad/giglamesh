#!/bin/bash
# i don't think the shebang is respected in the docker container

# Set the environment variables
export PATH="/usr/local/bin:${PATH}"
# shellcheck disable=SC2155  # arch will not fail
export PKG_CONFIG_PATH="/usr/local/lib/$(arch)-linux-gnu/pkgconfig:${PKG_CONFIG_PATH}"
# shellcheck disable=SC2155  # arch will not fail
export LD_LIBRARY_PATH="/usr/local/lib/$(arch)-linux-gnu/:${LD_LIBRARY_PATH}"
# on PATH in docker now: scrcpy, adb, cage, wayvnc

# https://github.com/Genymobile/scrcpy
# https://github.com/cage-kiosk/cage
# https://github.com/any1/wayvnc

# a lot of the code in here will be borrowed from Stringray, the last project I did with remote desktops and servers
# https://github.com/regulad/stingray/blob/master/stingray.py

echo "Rotating TLS key and certificate for wayvnc..."
# just rotate the key every time, it's not like it's a big deal
cd ~/.config/wayvnc || exit 1
rm -f tls_key.pem tls_cert.pem
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -sha384 \
	-days 3650 -nodes -keyout tls_key.pem -out tls_cert.pem \
	-subj /CN=localhost \
	-addext subjectAltName=DNS:localhost,DNS:localhost,IP:127.0.0.1 || exit 1
cd ~ || exit 1

# envsubst
echo "Injecting environment variables into wayvnc config..."
rm -f ~/.config/wayvnc/config || exit 1
envsubst < ~/.config/wayvnc/config_template > ~/.config/wayvnc/config || exit 1

function connect_adb() {
  echo "Attempting ADB connection..."
  adb connect "$DEVICE_IP":"$DEVICE_ADB_PORT" | grep "connected"  # handles "connected to" and "already connected to"
}

echo "Connecting to ADB device..."
while ! connect_adb;
do
  echo "Failed to connect to ADB device, retrying..."
  sleep 10
done
echo "Connected to ADB device."

# running

function open_scrcpy() {
  echo "Starting scrcpy..."

#  $ cage
#  Usage: cage [OPTIONS] [--] APPLICATION
#
#   -d      Don't draw client side decorations, when possible
#   -h      Display this help message
#   -m extend Extend the display across all connected outputs (default)
#   -m last Use only the last connected output
#   -s      Allow VT switching
#   -v      Show the version number and exit
#
#   Use -- when you want to pass arguments to APPLICATION

  SDL_VIDEODRIVER=wayland cage scrcpy || exit 1
}

function open_wayvnc() {
  echo "Starting wayvnc... (container will be ready soon)"

#  $ wayvnc --help
#  Usage: wayvnc [options] [address [port]]
#
#  Starts a VNC server for $WAYLAND_DISPLAY
#
#  Arguments:
#      address        The IP address or unix socket path to listen on.
#                     Default: 127.0.0.1
#      port           The TCP port to listen on.
#                     Default: 5900
#
#  Options:
#      -C,--config=<path>                        Select a config file.
#      -g,--gpu                                  Enable features that need GPU.
#      -o,--output=<name>                        Select output to capture.
#      -k,--keyboard=<layout>[-<variant>]        Select keyboard layout with an
#                                                optional variant.
#      -s,--seat=<name>                          Select seat by name.
#      -S,--socket=<path>                        Control socket path.
#      -t,--transient-seat                       Use transient seat.
#      -r,--render-cursor                        Enable overlay cursor rendering.
#      -f,--max-fps=<fps>                        Set rate limit.
#                                                Default: 30
#      -p,--performance                          Show performance counters.
#      -u,--unix-socket                          Create unix domain socket.
#      -x,--external-listener-fd=<fd>            Listen on a bound socket at <fd>
#                                                instead of binding to an address.
#                                                Default: -1
#      -d,--disable-input                        Disable all remote input.
#      -D,--detached                             Start detached from a compositor.
#      -V,--version                              Show version info.
#      -v,--verbose                              Be more verbose. Same as setting
#                                                --log-level=info
#      -w,--websocket                            Create a websocket.
#      -L,--log-level=<level>                    Set log level. The levels are:
#                                                error, warning, info, debug trace
#                                                and quiet.
#                                                Default: warning
#      -h,--help                                 Get help (this text).

  wayvnc 0.0.0.0 || exit 1
}

open_scrcpy &
open_wayvnc
