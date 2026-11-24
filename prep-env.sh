#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Tinos-mobile - Environment Preparation
# EDK2 Exynos 7884/7885 + Limine ARM64 UEFI
# ============================================================


ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAGING_DIR="$ROOT_DIR/staging"

EDK2_EXYNOS_REPO="$ROOT_DIR/edk2-exynos7885"
EDK2_REPO="$ROOT_DIR/edk2"
EDK2_PLATFORMS_REPO="$ROOT_DIR/edk2-platforms"
LIMINE_REPO="$ROOT_DIR/Limine"

mkdir -p "$STAGING_DIR"


export GCC5_AARCH64_PREFIX="aarch64-linux-gnu-"

echo "Environment preparation started."
echo "Root: $ROOT_DIR"
echo "Staging: $STAGING_DIR"


command -v aarch64-linux-gnu-gcc >/dev/null || {
    echo "ERROR: AArch64 cross-compiler unavailable."
    exit 1
}

# --- 4. REPOSITORY MANAGEMENT ---

clone_or_update() {
    local url="$1"
    local dir="$2"

    if [[ -d "$dir/.git" ]]; then
        echo "Repository already exists: $dir"
    elif [[ -e "$dir" ]]; then
        echo "ERROR: $dir exists but is not a Git repository."
        exit 1
    else
        echo "Cloning: $url"

        git clone \
            --depth 1 \
            --recurse-submodules \
            --shallow-submodules \
            "$url" "$dir"
    fi

    echo "Initializing submodules: $dir"

    git -C "$dir" submodule sync --recursive
    git -C "$dir" submodule update --init --recursive
}

# --- 5. FETCH SOURCES ---

echo "=== Fetching source repositories ==="

clone_or_update \
    "https://github.com/sonic011gamer/edk2-exynos7885.git" \
    "$EDK2_EXYNOS_REPO"

clone_or_update \
    "https://github.com/tianocore/edk2.git" \
    "$EDK2_REPO"

clone_or_update \
    "https://github.com/tianocore/edk2-platforms.git" \
    "$EDK2_PLATFORMS_REPO"

clone_or_update \
    "https://github.com/Limine-Bootloader/Limine.git" \
    "$LIMINE_REPO"

# --- 6. BUILD EDK2 ---

echo "=== [1/2] Compiling EDK2 for Exynos 7884/7885 ==="

pushd "$EDK2_EXYNOS_REPO" >/dev/null

if [[ -f "./build.sh" ]]; then

    echo "Using Exynos build wrapper."

    if [[ -f "./firstrun.sh" ]]; then
        ./firstrun.sh
    fi

    ./build.sh

else

    echo "Using upstream EDK2 build system."

    # Build EDK2 BaseTools.
    make -C "$EDK2_REPO/BaseTools" -j"$(nproc)"

    # Configure EDK2 environment.
    export WORKSPACE="$EDK2_EXYNOS_REPO"
    export PACKAGES_PATH="$EDK2_REPO:$EDK2_PLATFORMS_REPO:$EDK2_EXYNOS_REPO"
    export EDK_TOOLS_PATH="$EDK2_REPO/BaseTools"

    source "$EDK2_REPO/edksetup.sh"

    # Compile firmware.
    build \
        -a AARCH64 \
        -t GCC5 \
        -p Exynos7885Pkg/Exynos7885Pkg.dsc \
        -b RELEASE

fi

popd >/dev/null

FD_PATH="$(find "$EDK2_EXYNOS_REPO" -type f -name '*UEFI.fd' -print -quit)"

if [[ -z "$FD_PATH" ]]; then
    echo "ERROR: No UEFI.fd artifact found!"
    exit 1
fi

cp "$FD_PATH" "$STAGING_DIR/UEFI.fd"

echo "EDK2 firmware staged successfully."


echo "=== [2/2] Compiling Limine ARM64 UEFI Bootloader ==="

pushd "$LIMINE_REPO" >/dev/null

./bootstrap

./configure --enable-uefi-aarch64

make -j"$(nproc)"

if [[ ! -f "bin/BOOTAA64.EFI" ]]; then
    echo "ERROR: Limine ARM64 EFI binary not found!"
    exit 1
fi

cp bin/BOOTAA64.EFI "$STAGING_DIR/BOOTAA64.EFI"

popd >/dev/null


echo
echo "=========================================="
echo "Environment preparation complete!"
echo "=========================================="

echo "Staged artifacts:"
ls -lh "$STAGING_DIR"
