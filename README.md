# Tinos-mobile

A mobile / arm64 version of Tinos.

This project explores running a Cosmos-based .NET kernel on ARM64 mobile hardware. The current boot path combines EDK2 firmware for Samsung Exynos 7884/7885 devices with the Limine ARM64 UEFI bootloader. The repository also includes an initial Android boot image packaging script for the Samsung SM-A105FN (Galaxy A10). 

Currently, the project is experimental and device-specific; it is not a general-purpose mobile operating system for now, if you want a device to be supported you will need to contribute to the project adding drivers for it.

## Project layout

- `Tinos_mobile.kernel` — Cosmos kernel entry point and boot configuration.
- `Tinos_mobile.arm64`, `Tinos_mobile.common`, `Tinos_mobile.Drivers`, `Tinos_mobile.UI`, `Tinos_mobile.Applications`, and `Tinos_mobile.Utilities` — supporting project areas.
- `edk2-exynos7885`, `edk2`, `edk2-platforms`, and `Limine` — firmware and bootloader source dependencies tracked as Git submodules.
- `prep-env.sh` — builds and stages EDK2 firmware and the Limine ARM64 EFI binary.
- `Build-bootable-image-sm-a105fs.sh` — packages a boot image for the SM-A105FN device.

More detailed notes are in [`docs/`](docs/README.md), including the build stages, intended boot workflow, current script integration gaps, and device support status.

## Status

This is experimental and device-specific. The included Exynos firmware project reports reaching the UEFI shell; that does not imply that the Tinos kernel boots successfully. The boot image script contains device-specific assumptions and expects a stock DTB extracted into `stock_boot/`. Review its paths and boot image parameters for your device before using it.

## Requirements

The environment preparation script is intended for Linux and expects an AArch64 cross-compiler (`aarch64-linux-gnu-gcc`), Git, and the EDK2 build dependencies. The image packaging script additionally uses `cosmos`, `mkfs.vfat`, `mtools` (`mmd` and `mcopy`), and `mkbootimg`.

## Build

### Prerequisites
- A Linux system with a working development environment.
- An AArch64 cross-compiler (`aarch64-linux-gnu-gcc`).
- Git installed.
- The EDK2 build dependencies(`aarch64-linux-gnu-gcc`, `build-essential`, `nasm`, `python3`, `iasl`).

Clone with the submodules initialized:

```sh
git clone --recurse-submodules https://github.com/Tin-Systems-Platform/Tinos-mobile
cd Tinos-mobile
```

If you already cloned without submodules, run:

```sh
git submodule update --init --recursive
```

Prepare the firmware and bootloader artifacts:

```sh
./prep-env.sh
```

The script stages `UEFI.fd` and `BOOTAA64.EFI` under `staging/`. The kernel solution is `Tinos-mobile.slnx`; the kernel project uses the Cosmos SDK. To attempt packaging the device boot image, first provide the expected stock DTB and verify the script's device parameters, then run:

```sh
./Build-bootable-image-sm-a105fs.sh
```

The generated image and Odin archive are written to `build_artifacts/`. No generic mobile installation process is provided; flashing can make a device unbootable, so use device-specific recovery procedures and only proceed with artifacts built and checked for the exact target device.

## License

Check the licenses of this project and its submodules before redistribution. Each submodule may have its own license.


### Q: Why aarch64-linux-gnu-gcc and not clang or gcc?
The system GCC compiler targets the host architecture by default. aarch64-linux-gnu-gcc is a cross-compiler configured to generate code for the AArch64 architecture, allowing the EDK2 build environment to compile ARM64 firmware on an x86-64 Linux host.

Clang can also be configured for cross-compilation, but this project currently uses the GNU AArch64 cross-toolchain expected by its EDK2 build configuration.
