#!/bin/bash

set -e
set -o xtrace

NETCFG_YAML_FILE="$(pwd)/config/netcfg.yaml"
PKG_LIST_FILE="$(pwd)/rootfs_noble_packages.txt"
BASE_URL=https://cdimage.ubuntu.com/ubuntu-base/releases/24.04.2/release/ubuntu-base-24.04.2-base-arm64.tar.gz
TARBALL=rootfs_noble.tbz2

function check_prereq()
{
	if [ "$(whoami)" != "root" ]; then
		echo "Please run this script with sudo." > /dev/stderr
		exit 1
	fi
}

function clean_previous_build()
{
    rm -rf build/rootfs
}

function download_base()
{
    # download and extract preinstalled base tarball from ubuntu
    mkdir -p build/rootfs
    wget -qO- $BASE_URL | tar -xzpf - --numeric-owner -C build/rootfs
}

function build_rootfs()
{
    set +e
    pushd build/rootfs
    
    # prepare for chroot
    mount /sys ./sys -o bind
    mount /proc ./proc -o bind
    mount /dev ./dev -o bind
    mount /dev/pts ./dev/pts -o bind

    if [ -s etc/resolv.conf ]; then
        mv etc/resolv.conf etc/resolv.conf.saved
    fi
    if [ -e "/run/resolvconf/resolv.conf" ]; then
        cp /run/resolvconf/resolv.conf etc/
    elif [ -e "/etc/resolv.conf" ]; then
        cp /etc/resolv.conf etc/
    fi

    mkdir -p etc/netplan
    cp "$NETCFG_YAML_FILE" etc/netplan/
    chmod 600 etc/netplan/*

    # unfortunately, at the time of writing Ubuntu 24.04 (aka JetPack 7) isn't available yet
    # we add the below jammy (22.04) sources to support NVIDIA L4T packages
    echo \
'Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: jammy
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg' >> etc/apt/sources.list.d/ubuntu.sources

    LC_ALL=C
    chroot . apt-get update

    PKG_LIST=$(cat "${PKG_LIST_FILE}")
    if [ ! -z "${PKG_LIST}" ]; then
        DEBIAN_FRONTEND=noninteractive chroot . apt-get -y --no-install-recommends install ${PKG_LIST}
    fi

    # Fixes bluetooth service pointing to a wrong bluetoothd location
    sed -i 's/lib/libexec/g' /usr/lib/systemd/system/bluetooth.service.d/nv-bluetooth-service.conf

    chroot . sync
    chroot . apt-get clean
    chroot . sync

    if [ -s etc/resolv.conf.saved ]; then
        mv etc/resolv.conf.saved etc/resolv.conf
    fi

    umount ./sys
    umount ./proc
    umount ./dev/pts
    umount ./dev

    rm -rf var/lib/apt/lists/*
    rm -rf dev/*
    rm -rf var/log/*
    rm -rf var/cache/apt/archives/*.deb
    rm -rf var/tmp/*
    rm -rf tmp/*

    popd
    set -e
}

function save_rootfs()
{
    # save to tarball
    pushd build/rootfs
    tar --numeric-owner -jcpf ../$TARBALL *
    cd ..
    rm -rf rootfs
    popd
}

check_prereq
clean_previous_build
download_base
build_rootfs
save_rootfs
