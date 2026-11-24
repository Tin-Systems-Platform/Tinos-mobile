# Boot workflow

## Intended chain

The intended design transfers control through several distinct layers:

```text
Device boot ROM / existing Android boot mechanism
        ↓
Android boot image containing the EDK2 firmware payload
        ↓
EDK2 UEFI for the Exynos platform
        ↓
Limine ARM64 EFI application on a FAT filesystem
        ↓
Cosmos ARM64 kernel
```

This is the design implied by `prep-env.sh`, `Build-bootable-image-sm-a105fs.sh`, and the Limine configuration. The checked-in files do not yet form a consistent, verified chain.

## What each layer does

1. **Android boot image:** the packaging script invokes `mkbootimg` with a payload named `payload.bin` as the kernel field and a 32 MiB FAT image as the ramdisk field. The script comments identify its addresses and page size as values to replace for the unpacked SM-A105FN boot image.
2. **EDK2 firmware:** `prep-env.sh` builds Exynos 7884/7885 UEFI firmware. The packer concatenates a stock DTB to a hard-coded EDK2 `.fd` file if `stock_boot/boot.img-dtb` exists, otherwise it uses the firmware file alone. Appending a DTB this way is a script assumption; it is not demonstrated here as a universally valid firmware handoff format.
3. **EFI filesystem and Limine:** the packer creates a FAT32 image with `EFI/BOOT/BOOTAA64.EFI`, a Limine configuration at the filesystem root, and the kernel payload. The UEFI removable-media path `EFI/BOOT/BOOTAA64.EFI` is intended to let EDK2 launch Limine.
4. **Kernel load:** Limine reads `limine.conf` and should load the referenced kernel file. The current config requests `/boot/Tinos_mobile.kernel.elf` using `boot():/` as the filesystem root.

## Current integration mismatches

The chain needs alignment before it can work as documented:

- The builder copies `BOOTAA64.EFI` to `staging/BOOTAA64.EFI`; the packer looks for `staging/limine/BOOTAA64.EFI`.
- The packer places the Cosmos output at `/cosmos.bin`; the Limine config asks for `/boot/Tinos_mobile.kernel.elf`.
- The packer's EDK2 input path is a fixed build-tree path, while the preparation script stages firmware at `staging/UEFI.fd`.
- The solution and Cosmos project names the kernel `Tinos_mobile.kernel`; the packer expects `MyCosmosOS.bin`.

These are concrete file/name discrepancies, separate from lower-level questions such as whether the chosen Android boot image fields, DTB handoff, or load offsets are correct on a target device.

## Expected kernel behavior today

`Tinos_mobile.kernel/Kernel.cs` prints `TEST` in the Cosmos `BeforeRun()` hook. Its `Run()` hook is empty. There is no implemented mobile shell, touch interface, display stack, or device boot manager in this entry point. A successful handoff to this kernel would be an early bring-up milestone, not evidence that phone hardware is fully supported.
