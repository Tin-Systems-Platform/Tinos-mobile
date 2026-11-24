#!/usr/bin/env bash
set -euo pipefail

# --- 1. DIRECTORIES & TOOLCHAINS ---
ROOT_DIR="$(pwd)"
STAGING_DIR="$ROOT_DIR/staging"
mkdir -p "$STAGING_DIR"

# Cross-compiler prefix for ARM64 bare-metal/UEFI builds
export GCC5_AARCH64_PREFIX="aarch64-linux-gnu-"

# Component paths (adjust to match your repo layout)
EDK2_REPO="$ROOT_DIR/edk2-exynos7885"
LIMINE_REPO="$ROOT_DIR/Limine"

echo "Environmet preparation started. Staging directory: $STAGING_DIR"

echo "=== [1/2] Compiling EDK2 for Exynos 7884/7885 ==="
git clone https://github.com/sonic011gamer/edk2-exynos7885.git --depth 1
git clone https://github.com/tianocore/edk2 --depth 1 --recurse-submodules --shallow-submodules
git clone https://github.com/tianocore/edk2-platforms.git --depth 1
pushd "$EDK2_REPO" >/dev/null
    
# Most community Exynos EDK2 ports include a build.sh wrapper;
# if yours uses raw EDK2 BaseTools, replace this block with edksetup.sh + build -a AARCH64 ...
if [ -f "./build.sh" ]; then
    ./firstrun.sh
    ./build.sh
else
    source edksetup.sh
    build -a AARCH64 -t GCC5 -p Exynos7885Pkg/Exynos7885Pkg.dsc -b RELEASE
fi

# Copy the resulting .fd payload to staging
FD_PATH=$(find . -name "*UEFI.fd" | head -n 1)
cp "$FD_PATH" "$STAGING_DIR/UEFI.fd"
popd >/dev/null


echo "=== [2/2] Compiling Limine ARM64 UEFI Bootloader ==="
git clone https://github.com/Limine-Bootloader/Limine --depth 1
pushd "$LIMINE_REPO" >/dev/null
    
./bootstrap
./configure --enable-uefi-aarch64
make -j"$(nproc)"
    
cp bin/BOOTAA64.EFI "$STAGING_DIR/BOOTAA64.EFI"
popd >/dev/null

echo "Env prep complete. Staged artifacts:"
ls -lh "$STAGING_DIR"