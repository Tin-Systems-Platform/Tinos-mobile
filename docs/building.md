# Detailed build guide

## Scope and host

The checked-in build helpers target Linux. `prep-env.sh` prepares the EDK2 firmware and Limine ARM64 EFI loader. `Build-bootable-image-sm-a105fs.sh` is a separate packaging attempt for the Samsung SM-A105FN. It is not an end-to-end build: it currently has path and artifact-name mismatches described below, so inspect and reconcile those before expecting a boot image.

The Exynos submodule README says its firmware build was tested on Ubuntu 24.04. The repository does not pin a Linux container or a complete host package manifest. Expect to install the usual EDK2 build dependencies (compiler, `make`, `uuid-dev`, `iasl`, `nasm`, and Python) as well as the tools listed in the scripts. The environment script explicitly checks for `aarch64-linux-gnu-gcc`; the image packer invokes `cosmos`, `mkfs.vfat`, `truncate`, `mmd`, `mcopy`, `mkbootimg`, and `tar`.

## 1. Get the sources

```sh
git clone --recurse-submodules <repository-url>
cd Tinos-mobile
```

For an existing checkout:

```sh
git submodule update --init --recursive
```

The firmware and bootloader sources are submodules. `prep-env.sh` also synchronizes and updates them to the revisions recorded by this repository.

## 2. Prepare EDK2 and Limine

From the repository root:

```sh
./prep-env.sh
```

The script builds EDK2 for AArch64 using the Exynos project wrapper when present; otherwise it uses the upstream EDK2 build command and the `Exynos7885Pkg` description. It searches the Exynos source tree for a `*UEFI.fd` image and copies the first match to `staging/UEFI.fd`.

It then runs Limine's `bootstrap`, configures `--enable-uefi-aarch64`, builds it, and copies `bin/BOOTAA64.EFI` to `staging/BOOTAA64.EFI`.

Generated files under `staging/` are ignored by Git. The script verifies that a firmware image and EFI binary are found, but it does not run either artifact on hardware or validate the complete boot chain.

## 3. Build the Cosmos kernel

The kernel project is `Tinos_mobile.kernel/Tinos_mobile.kernel.csproj`; the solution is `Tinos-mobile.slnx`. The kernel project uses `Cosmos.Sdk/3.0.99`, targets `net10.0`, and references the supporting project folders. The image script expects the `cosmos` command to be installed and calls:

```sh
cosmos build --project ./Tinos_mobile.kernel/Tinos_mobile.kernel.csproj -c Release
```

The script assumes the result is at `Tinos_mobile.kernel/output-arm64/MyCosmosOS.bin`. Confirm the actual output for your Cosmos SDK version. The checked-in Limine configuration instead names `Tinos_mobile.kernel.elf` at `/boot/Tinos_mobile.kernel.elf`; these names and locations do not currently agree.

The kernel entry point currently writes `TEST` in `BeforeRun()` and has an empty `Run()` method. This is a bring-up skeleton, not a complete mobile operating system.

## 4. Package a device boot image (work in progress)

The packaging helper is `Build-bootable-image-sm-a105fs.sh`. It expects a DTB at `stock_boot/boot.img-dtb` and creates `build_artifacts/`. It makes a 32 MiB FAT image, copies a Limine EFI loader, Limine configuration, and a kernel payload into it, appends the DTB to the EDK2 firmware image when the DTB exists, calls `mkbootimg`, and wraps the result in an Odin `.tar` archive.

Before using this stage, reconcile the current checked-in script assumptions:

- The environment script stages Limine at `staging/BOOTAA64.EFI`, while the packer reads `staging/limine/BOOTAA64.EFI`.
- The packer copies `MyCosmosOS.bin` as `/cosmos.bin`, while `Tinos_mobile.kernel/Bootloader/limine.conf` requests `/boot/Tinos_mobile.kernel.elf`.
- The packer uses a fixed EDK2 firmware path under `edk2-exynos7885/workspace/Build/...`; the environment script instead discovers the first `*UEFI.fd` and stages it as `staging/UEFI.fd`.
- The `mkbootimg` base, offsets, page size, OS version, and patch level are sample values in the script. Its comment explicitly says to replace the offsets with values for the unpacked target boot image.

The script can produce an image only when its inputs exist and its tools accept the parameters; that is not proof the image is valid for a particular phone. Generated artifacts are ignored under `build_artifacts/`.

## Build outputs

| Stage | Expected output | Purpose |
| --- | --- | --- |
| EDK2 | `staging/UEFI.fd` | Exynos UEFI firmware payload |
| Limine | `staging/BOOTAA64.EFI` | ARM64 UEFI bootloader |
| Cosmos | Expected by packer: `Tinos_mobile.kernel/output-arm64/MyCosmosOS.bin` | Kernel payload (verify SDK output name) |
| Image packaging | `build_artifacts/uefi_boot.img`, `build_artifacts/uefi_boot.tar` | Android boot image and Odin archive |

## Troubleshooting

- **Cross compiler not found:** install/configure `aarch64-linux-gnu-gcc` so it is available in `PATH`.
- **Submodule missing:** initialize submodules from the repository root with `git submodule update --init --recursive`.
- **EDK2 build fails:** check host dependencies and review the Exynos submodule's build notes; the helper supports both its wrapper and a fallback upstream build route.
- **Packer reports a missing file:** compare its hard-coded paths with the actual staged and Cosmos outputs. The mismatches above are present in the checked-in scripts.
- **Boot image is rejected or fails to boot:** verify the target's boot image header format and exact load addresses/offsets. No device-specific validation is encoded in the script.
