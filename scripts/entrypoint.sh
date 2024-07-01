#!/bin/bash
set -e

# Set the environment variables
export PATH="/usr/local/bin:${PATH}"
# shellcheck disable=SC2155  # arch will not fail
export PKG_CONFIG_PATH="/usr/local/lib/$(arch)-linux-gnu/pkgconfig:${PKG_CONFIG_PATH}"
# shellcheck disable=SC2155  # arch will not fail
export LD_LIBRARY_PATH="/usr/local/lib/$(arch)-linux-gnu/:${LD_LIBRARY_PATH}"
# on PATH in docker now: scrcpy, adb, cage, wayvnc

# this is for ADB which creates a .android directory in the home directory; nothing else should use HOME since we are root
export HOME=/tmp

# a lot of the code in here will be borrowed from Stringray, the last project I did with remote desktops and servers
# https://github.com/regulad/stingray/blob/master/stingray.py

echo "Rotating TLS key and certificate for wayvnc..."
# just rotate the key every time, it's not like it's a big deal
rm -rf /tmp/vnc
mkdir -p /tmp/vnc
cd /tmp/vnc
rm -f tls_key.pem tls_cert.pem
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -sha384 \
	-days 3650 -nodes -keyout tls_key.pem -out tls_cert.pem \
	-subj /CN=localhost \
	-addext subjectAltName=DNS:localhost,DNS:localhost,IP:127.0.0.1
# envsubst
echo "Injecting environment variables into wayvnc config..."
rm -f config
envsubst < /root/config_template > config
cd /root

function connect_adb() {
  echo "Attempting ADB connection..."
  adb connect "$DEVICE_IP":"$DEVICE_ADB_PORT" | grep "connected"  # handles "connected to" and "already connected to"
}

echo "Starting ADB server..."
adb start-server

#export ANDROID_SDK_HOME="/tmp/.android"  # ANDROID_SDK_HOME is not checked on linux. holy balls!!!!
echo "Connecting to ADB device..."
while ! connect_adb;
do
  echo "Failed to connect to ADB device, retrying..."
  sleep 10
done
echo "Connected to ADB device."

# running
echo "Starting cage server..."
mkdir -p /tmp/vnc
# start the cage server
export XDG_RUNTIME_DIR="/tmp/vnc"
export SDL_VIDEODRIVER="wayland"  # this is for scrcpy
export WLR_LIBINPUT_NO_DEVICES="1"  # this is for cage: the devices will be added later when wayvnc initializes

# see if the /dev/tty0 symlink is needed
if [ ! -e /dev/tty0 ]; then
  echo "Creating /dev/tty0 symlink..."
  ln -s "$(tty)" /dev/tty0  # integrated seatd will only work with /dev/tty0
  # the ptty will not be enough for seatd to work on most systems (privileged containers will be required) however some host distros could possibly be more lenient
fi
rm -f /tmp/cage.log
touch /tmp/cage.log
# https://gist.github.com/regulad/64cc432a8d201ea6d9136722d9bdc66e
# https://gist.github.com/regulad/047f1bbe20614681a263caaa16dee661 & https://wiki.libsdl.org/SDL2/FAQUsingSDL
# debugging tips: https://github.com/cage-kiosk/cage/issues/184#issuecomment-844666508
# cage REQUIRES a session, maybe we need to switch to something x11-based
# tee logs to /tmp/cage.log and to stdout
# |& is a bashism that combines stdout and stderr
# & runs the command in the background
# check for a custom SCRCPY_RUN
if [ -z "$SCRCPY_RUN" ]; then
  SCRCPY_RUN="scrcpy -e --no-audio --no-audio-playback"
fi
# shellcheck disable=SC2086  # we want word splitting
# shellcheck disable=SC2046  # we want word splitting
# shellcheck disable=SC2116  # reliable way to split the string
(cage -- $(echo "$SCRCPY_RUN") |& tee /tmp/cage.log) &
cage_pid=$!

wayland_display_regex=""
max_wait_seconds=60
counter=0
while [ -z "$wayland_display_regex" ] && [ $counter -lt $max_wait_seconds ]; do
  # wait for cage to start, get the wayland display
  wayland_display_regex=$(tail -n 100 /tmp/cage.log | grep -oP 'running on Wayland display \K.*')

  # Check if cage has exited
  if ! kill -0 $cage_pid 2>/dev/null; then
    # Wait for the process to get the exit status
    wait $cage_pid
    cage_exit_status=$?
    echo "Cage exited with status $cage_exit_status"
    exit $cage_exit_status
  fi

  sleep 1
  counter=$((counter + 1))
done

if [ -z "$wayland_display_regex" ]; then
    echo "Cage never started properly."
    exit 1
fi

# check to see if the wayland display has already been set
if [ -z "$WAYLAND_DISPLAY" ]; then
  echo "Setting WAYLAND_DISPLAY to $wayland_display_regex"
  export WAYLAND_DISPLAY="$wayland_display_regex"
fi

echo "Starting wayvnc server..."
# https://gist.github.com/regulad/5cc442cb0afd00c31a0ce7296ca2a4ff
wayvnc --config=/tmp/vnc/config 0.0.0.0 5900

# TODO: FPS limit passed to scrcpy & wayvnc
# TODO: resolution limit that sets size of canvas for cage & scrcpy
# TODO: add an audio stream https://github.com/any1/wayvnc/issues/209 https://github.com/Genymobile/scrcpy/blob/master/doc/audio.md
# TODO: copy-paste between host and guest
# TODO: simulating gestures https://github.com/Genymobile/scrcpy/blob/master/doc/control.md#pinch-to-zoom-rotate-and-tilt-simulation
