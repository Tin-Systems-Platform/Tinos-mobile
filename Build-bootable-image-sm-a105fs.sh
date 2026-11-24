#!/usr/bin/env bash
set -euo pipefail

# --- 1. PATHS & CONFIGURATION ---
COSMOS_PROJ="./Tinos_mobile.kernel/Tinos_mobile.kernel.csproj"
COSMOS_OUT="./Tinos_mobile.kernel/output-arm64" # Adjust target framework/RID
LIMINE_EFI="./staging/limine/BOOTAA64.EFI"
LIMINE_CFG="./Tinos_mobile.kernel/Bootloader/limine.conf"

EDK2_DIR="./edk2-exynos7885"
EDK2_FD="$EDK2_DIR/workspace/Build/Exynos7885Pkg/RELEASE_GCC5/FV/EXYNOS7885PKG_UEFI.fd"
STOCK_DTB="./stock_boot/boot.img-dtb" # Extracted once from your SM-A105FN boot.img

BUILD_DIR="./build_artifacts"
RAMDISK_IMG="$BUILD_DIR/ramdisk.fat"
OUTPUT_BOOT="$BUILD_DIR/uefi_boot.img"

mkdir -p "$BUILD_DIR"

# --- 2. BUILD COSMOS GEN3 (ARM64) ---
echo "[1/4] Building Cosmos gen3 kernel..."
cosmos build --project "$COSMOS_PROJ"  -c Release 

# --- 3. CREATE FAT32 RAMDISK (NO SUDO NEEDED) ---
echo "[2/4] Packing Limine + Cosmos into FAT32 RAM disk..."
rm -f "$RAMDISK_IMG"
truncate -s 32M "$RAMDISK_IMG"          # 32MB virtual disk image
mkfs.vfat -F 32 "$RAMDISK_IMG" >/dev/null

# Use mtools (mmd / mcopy) to inject files cleanly without mounting
mmd -i "$RAMDISK_IMG" ::/EFI
mmd -i "$RAMDISK_IMG" ::/EFI/BOOT
mcopy -i "$RAMDISK_IMG" "$LIMINE_EFI" ::/EFI/BOOT/BOOTAA64.EFI
mcopy -i "$RAMDISK_IMG" "$LIMINE_CFG" ::/limine.conf
mcopy -i "$RAMDISK_IMG" "$COSMOS_OUT/Tinos_mobile.kernel.bin" ::/cosmos.bin # Match path in limine.conf

# --- 4. APPEND DTB TO EDK2 PAYLOAD ---
echo "[3/4] Preparing EDK2 kernel payload..."
if [ -f "$STOCK_DTB" ]; then
    cat "$EDK2_FD" "$STOCK_DTB" > "$BUILD_DIR/payload.bin"
else
    cp "$EDK2_FD" "$BUILD_DIR/payload.bin"
fi

# --- 5. PACK SAMSUNG BOOT.IMG ---
# Replace offsets below with the exact ones from your unpacked SM-A105FN boot.img!
echo "[4/4] Packing Android boot.img..."
mkbootimg \
    --kernel "$BUILD_DIR/payload.bin" \
    --ramdisk "$RAMDISK_IMG" \
    --base 0x10000000 \
    --kernel_offset 0x00008000 \
    --ramdisk_offset 0x01000000 \
    --tags_offset 0x00000100 \
    --pagesize 2048 \
    --os_version 11.0.0 \
    --os_patch_level 2023-01 \
    -o "$OUTPUT_BOOT"

# Optional: Create Odin-flashable .tar
tar -H ustar -c -C "$BUILD_DIR" "$(basename "$OUTPUT_BOOT")" > "$BUILD_DIR/uefi_boot.tar"

echo "Done! Ready to flash: $OUTPUT_BOOT or $BUILD_DIR/uefi_boot.tar (Odin)"
