#!/bin/bash
L4T_VERSION=$1
shift 1
sudo podman run \
    -ti \
    --rm \
    --privileged \
    --network host \
    -v /dev/bus/usb:/dev/bus/usb \
    -v /dev:/dev \
    -v ./build:/build \
    -v /run/systemd/system:/run/systemd/system \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    -w /build/Linux_for_Tegra \
    localhost/jetson-builder:l4t"$L4T_VERSION"
    "$@"
