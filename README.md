# jetson-builder
(Work-in-progress) A container-based Jetson series build and flash environment. Currently this script only builds a Ubuntu 24.04 rootfs.

> At the time of writing (9th March 2025), NVIDIA does not have support for Ubuntu noble 24.04 yet.
>
> This script attempts to provide support by adding jammy (22.04) APT sources alongside
> noble (24.04) sources in order to install NVIDIA L4T packages properly. There MIGHT EXIST INCOMPABILITIES.
>
> In the future, if Ubuntu noble (24.04) support is out (probably JetPack 7), this script
> should change to use that JetPack and Jetson Linux version for full compatibility.

Instead of creating an image file, this project aims to reuse the NVIDIA provided toolkit in order to allow initrd flash, which is required for eMMC, NVME flashing. This allows production modules (non-dev-kit modules) to be flashed.

## Requirements

### Host system

- Native Linux System Required

- Or, VMWare Workstation (Windows) running Ubuntu 22.04 with the Jetson USB forward redirection remembered (VERY IMPORTANT FOR FLASHING TO WORK PROPERLY).
    - WSL and emulators are not supported. Other VMs, hypervisors are not supported.

### Dependencies

- Podman 3.4.4 or later

    https://podman.io/docs/installation

## Flashing environment

1. Build environment: The `build` folder

    > Do not run this multiple times unless you want to recreate the environment.
    >
    > Remove the `build/Linux_for_Tegra` before recreating the environment.

    ```bash
    ./build_env_l4t36.sh
    ```

2. Build rootfs: `build/rootfs_noble.tbz2`

    ```bash
    ./build_rootfs_noble.sh
    ```

3. Extract built rootfs

    ```bash
    # remove existing rootfs
    sudo rm -rf build/Linux_for_Tegra/rootfs
    # create folder and extract
    mkdir -p build/Linux_for_Tegra/rootfs
    sudo tar xpf build/rootfs_noble.tbz2 -C build/Linux_for_Tegra/rootfs
    ```

4. Use environment

    This will run the flash environment container we created and allowing users to
    run NVIDIA Jetson flashing commands directly.

    ```bash
    ./use_env.sh <l4t version> [command] [argument 1] [argument 2] ... 
    ```

    Example:

    ```bash
    ./use_env.sh 36
    # (launches container)

    # apply NVIDIA packages to rootfs
    sudo ./apply_binaries.sh
    # create default user
    sudo ./tools/l4t_create_default_user.sh -u jetson -p jetson --accept-license

    # flash to NVME
    sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 \
    -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p "-c bootloader/generic/cfg/flash_t234_qspi.xml" \
    --showlogs --network usb0 jetson-orin-nano-devkit-super nvme0n1p1
    ```

> :warning: Flashing directly inside container is still work-in-progress. The above command flashing to NVME does not work inside container, yet. It will output an error related to NFS server.

## Build environment

TODO

## License
Licensed under MIT License.
