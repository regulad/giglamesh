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

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
