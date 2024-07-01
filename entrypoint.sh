#!/bin/bash
# i don't think the shebang is respected in the docker container

set -e

# Set the environment variables
export PATH="/usr/local/bin:${PATH}"
# shellcheck disable=SC2155  # arch will not fail
export PKG_CONFIG_PATH="/usr/local/lib/$(arch)-linux-gnu/pkgconfig:${PKG_CONFIG_PATH}"
# shellcheck disable=SC2155  # arch will not fail
export LD_LIBRARY_PATH="/usr/local/lib/$(arch)-linux-gnu/:${LD_LIBRARY_PATH}"
# on PATH in docker now: scrcpy, adb, cage, wayvnc
# also from a transient dependency: python3???

# https://github.com/Genymobile/scrcpy
# https://github.com/cage-kiosk/cage
# https://github.com/any1/wayvnc

# a lot of the code in here will be borrowed from Stringray, the last project I did with remote desktops and servers
# https://github.com/regulad/stingray/blob/master/stingray.py

echo "Rotating TLS key and certificate for wayvnc..."
# just rotate the key every time, it's not like it's a big deal
rm -f /tmp/vnc
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
envsubst < ~/config_template > config || exit 1
cd ~

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
python3 ./entrypoint.py
