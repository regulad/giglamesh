#### NOTE: The Wayland version of this project is abandoned. [I was unable to get cage to properly start the app (scrcpy or weston-terminal, both were lost causes) and it required extremely broad Docker permissions to run, which was a no-go because I may have hundreds of instances running that should not lock up hardware.](https://gist.github.com/regulad/32f22d2abf59fe8ae7a17b004b53e103) I am currently working on recreating giglamesh in another X11-based Docker container, possibly using KasmVNC.

#### ADDENDUM: I ended up doing just that. [You can see a test docker-compose file here.](https://github.com/regulad/test-scrcpy). It uses KasmVNC & scrcpy to provide a simple interface for Android.

# Giglamesh

Giglamesh creates a VNC server from any ADB device. This allows you to connect to the VNC server and interact with the Android device as if you were using it directly. This circumvents the need to install any additional software on the Android device itself.

Built-in support for `arm64` platforms is included and prioritized.

## Prerequisites

You will need `Docker` and `Docker Compose` installed on your system.

## Running the Docker Container

To run the Docker container, use the `docker-compose up` command. This will also build the image if it can't pull it from GitHub Packages.

(Run `docker-compose build` to force a rebuild of the image, or do `docker-compose --build up`.)

## Environment Variables

The following environment variables need to be set in the `.env` file (a `.env.example` is provided:

- `DEVICE_IP`: The IP address of the Android device.
- `DEVICE_ADB_PORT`: The ADB port of the Android device (default is 5555; likely will not need customization unless you are on a fancy Android 11+ device that rotates the port).

## Accessing the VNC Server

Once the Docker container is running, you can access the VNC server at `localhost:5900`. Note that if the ADB connection to the Android device dies for any reason, the VNC server will too. You are responsible for restarting a container running from this image.

## Notes

I am aware of https://hub.docker.com/r/kasmweb/redroid but it does not fit my needs. It uses docker-in-docker, which is simply too indirect for the access I needed to the ADB device in doppelganger. In addition, it also doesn't run in a kiosk mode which is a must when the VNC stream is going to be inserted into another app.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
