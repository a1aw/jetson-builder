#!/bin/bash
set -e
set -o xtrace

L4T_VERSION=36
BSP_URL=https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.3/release/Jetson_Linux_r36.4.3_aarch64.tbz2
SRC_URL=https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.3/sources/public_sources.tbz2
WORKING_DIR=$(pwd)

mkdir -p build
sudo chown $USER:$USER build
wget -qO- $BSP_URL | tar -jxpf - -C build
wget -qO- $SRC_URL | tar -jxpf - -C build

pushd build/Linux_for_Tegra
patch nv_tegra/nv-apply-debs.sh < $WORKING_DIR/patches/0001-nv-apply-debs-force-overwrite.diff
patch tools/ota_tools/version_upgrade/recovery_copy_binlist.txt < $WORKING_DIR/patches/0002-recovery-copy-binlist-extra.diff

rm -rf nv_tegra/l4t_deb_packages/nvidia-l4t-nvpmodel-gui-tools*.deb
rm -rf nv_tegra/l4t_deb_packages/nvidia-l4t-jetsonpower-gui-tools*.deb
rm -rf tools/python-jetson-gpio_*_arm64.deb
popd

sudo podman build \
    --cap-add=all \
    -v "$(pwd)/build":/build:ro \
    -t localhost/jetson-builder:l4t36 \
    -f Containerfile.l4t"$L4T_VERSION" \
    --build-arg USER_ID=$(id -u ${USER}) \
    --build-arg GROUP_ID=$(id -g ${USER}) \
