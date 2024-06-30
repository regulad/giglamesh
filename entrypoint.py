#!/usr/bin/python3

# this is an addendum to entrypoint.sh that launches the cage server and then wayvnc when it is ready
# i *could* do this in bash but I am far more comfortable doing it with subprocess in python and it will definitely work better

import subprocess
import re


if __name__ == "__main__":
    print("Starting cage server...")

    # start the cage server
    cage = subprocess.Popen(
        ["cage", "scrcpy"],
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env={
            "XDG_RUNTIME_DIR": "/tmp",
            # "WAYLAND_DISPLAY": "wayland-0",
            "SDL_VIDEODRIVER": "wayland",
        },
    )

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

    # wait to read ready from cage
    for line in cage.stdout:
        line_string = line.decode("utf-8")
        print(line_string)  # newlines are already stripped
        # we are looking for the pattern is running on Wayland display %s, where %s is the WAYLAND_SERVER
        # use regex
        match = re.match(r".*running on Wayland display (.*)", line_string)
        if match:
            wayland_display = match.group(1)
            print(f"Wayland display: {wayland_display}")
            break
    else:
        print("Cage never started properly.")
        exit(1)

    # start wayvnc
    wayvnc = subprocess.Popen(
        [
            "wayvnc",
            "0.0.0.0",
        ],
        shell=True,
        env={
            "WAYLAND_DISPLAY": wayland_display,
        },
    )

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

    # wait for wayvnc to finish

    wayvnc.wait()
    cage.wait()
