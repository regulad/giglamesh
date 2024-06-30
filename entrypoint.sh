#!/bin/bash

# on PATH in docker: scrcpy, adb, cage, wayvnc

# https://github.com/Genymobile/scrcpy
# https://github.com/cage-kiosk/cage
# https://github.com/any1/wayvnc

# a lot of the code in here will be borrowed from Stringray, the last project I did with remote desktops and servers
# https://github.com/regulad/stingray/blob/master/stingray.py

function wait_for_device() {
    while true; do
        adb devices | grep -q "$DEVICE_IP:$DEVICE_ADB_PORT" && break
        sleep 1
    done
}

adb connect "$DEVICE_IP":"$DEVICE_ADB_PORT"
wait_for_device

function open_scrcpy() {
  export SDL_VIDEODRIVER=wayland  # satisfies scrcpy and tells it to use wayland
  cage scrcpy
}

function open_wayvnc() {
  sleep 10 # give cage time to start scrcpy
  wayvnc 0.0.0.0
}

open_scrcpy &
open_wayvnc
