#!/bin/bash

# on PATH in docker: scrcpy, adb, cage, wayvnc

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

echo "Connecting to ADB device..."
adb connect "$DEVICE_IP":"$DEVICE_ADB_PORT" | grep "connected" > /dev/null || exit 1

# running

function open_scrcpy() {
  echo "Starting scrcpy..."
  SDL_VIDEODRIVER=wayland cage scrcpy || exit 1
}

function open_wayvnc() {
  sleep 10 # give cage time to start scrcpy
  echo "Starting wayvnc... (container will be ready soon)"
  wayvnc 0.0.0.0 || exit 1
}

open_scrcpy &
open_wayvnc
