#!/bin/bash

# on PATH in docker: scrcpy, adb, cage, wayvnc

# https://github.com/Genymobile/scrcpy
# https://github.com/cage-kiosk/cage
# https://github.com/any1/wayvnc

# a lot of the code in here will be borrowed from Stringray, the last project I did with remote desktops and servers
# https://github.com/regulad/stingray/blob/master/stingray.py

# just rotate the key every time, it's not like it's a big deal
cd ~/.config/wayvnc || exit 1
rm -f tls_key.pem tls_cert.pem
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -sha384 \
	-days 3650 -nodes -keyout tls_key.pem -out tls_cert.pem \
	-subj /CN=localhost \
	-addext subjectAltName=DNS:localhost,DNS:localhost,IP:127.0.0.1 || exit 1
cd ~ || exit 1

# envsubst
rm -f ~/.config/wayvnc/config || exit 1
envsubst < ~/.config/wayvnc/config_template > ~/.config/wayvnc/config || exit 1

function wait_for_device() {
    while true; do
        adb devices | grep -q "$DEVICE_IP:$DEVICE_ADB_PORT" && break
        sleep 1
    done
}

adb connect "$DEVICE_IP":"$DEVICE_ADB_PORT" || exit 1
wait_for_device

# running

function open_scrcpy() {
  export SDL_VIDEODRIVER=wayland  # satisfies scrcpy and tells it to use wayland
  cage scrcpy || exit 1
}

function open_wayvnc() {
  sleep 10 # give cage time to start scrcpy
  wayvnc 0.0.0.0 || exit 1
}

open_scrcpy &
open_wayvnc
