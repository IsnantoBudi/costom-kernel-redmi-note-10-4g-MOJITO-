#!/usr/bin/env bash
# ==============================================================================
# Script 02: Fetch Kernel Source, Toolchain & AnyKernel3
# Target: Redmi Note 10 4G (mojito / sunny) - MIUI 14 (Android 12)
# Dioptimalkan untuk performa native WSL2 & case-sensitivity ext4
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$HOME/kernel_workspace_mojito"

mkdir -p "$WORK_DIR"
mkdir -p "$ROOT_DIR/output"

echo "=========================================================="
echo " Direktori Proyek Windows: $ROOT_DIR"
echo " Direktori Build WSL2    : $WORK_DIR"
echo "=========================================================="

# 1. Setup Toolchain Proton-Clang (Gunakan yang sudah diunduh di ROOT_DIR jika ada)
CLANG_DIR="$WORK_DIR/toolchain/proton-clang"
mkdir -p "$WORK_DIR/toolchain"

if [ -f "$ROOT_DIR/toolchain/proton-clang/bin/clang" ]; then
    echo ">> [1/3] Mendeteksi Proton-Clang sudah ada di $ROOT_DIR."
    if [ ! -e "$CLANG_DIR" ]; then
        ln -sf "$ROOT_DIR/toolchain/proton-clang" "$CLANG_DIR"
        echo ">> Berhasil menghubungkan symlink Proton-Clang ke lingkungan WSL2."
    fi
elif [ ! -d "$CLANG_DIR" ]; then
    echo ">> [1/3] Mengunduh Proton-Clang toolchain (LLVM Clang)..."
    git clone --depth=1 --single-branch https://github.com/kdrag0n/proton-clang.git "$CLANG_DIR"
else
    echo ">> [1/3] Proton-Clang toolchain sudah siap di $CLANG_DIR. Melewati..."
fi

# 2. Unduh Kernel Source Xiaomi Mojito ke Filesystem Native WSL2 (ext4)
# Mencegah error tabrakan file case-sensitive (seperti xt_CONNMARK.h) pada NTFS
KERNEL_DIR="$WORK_DIR/kernel_src"
if [ -d "$KERNEL_DIR" ] && [ ! -f "$KERNEL_DIR/Makefile" ]; then
    echo ">> Direktori $KERNEL_DIR tidak lengkap. Membersihkan..."
    rm -rf "$KERNEL_DIR"
fi

if [ ! -d "$KERNEL_DIR" ]; then
    echo ">> [2/3] Mengunduh Kernel Source Mojito ke native WSL2 (Branch: memeui - MIUI Optimized)..."
    git clone --depth=1 --single-branch --branch memeui https://github.com/xiaomi-sdm678/android_kernel_xiaomi_mojito.git "$KERNEL_DIR"
else
    echo ">> [2/3] Kernel source sudah siap di $KERNEL_DIR. Melewati..."
fi

# 3. Unduh AnyKernel3 untuk Flashing via TWRP/OrangeFox
ANYKERNEL_DIR="$WORK_DIR/anykernel3"
if [ ! -d "$ANYKERNEL_DIR" ]; then
    echo ">> [3/3] Menyiapkan AnyKernel3 template..."
    if [ -d "$ROOT_DIR/anykernel3" ] && [ -f "$ROOT_DIR/anykernel3/anykernel.sh" ]; then
        cp -r "$ROOT_DIR/anykernel3" "$ANYKERNEL_DIR"
    else
        git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git "$ANYKERNEL_DIR"
        
        echo ">> Mengonfigurasi anykernel.sh untuk Redmi Note 10 4G..."
        cat << 'EOF' > "$ANYKERNEL_DIR/anykernel.sh"
### AnyKernel3 Packaging Config for Redmi Note 10 4G (mojito/sunny)
properties() { '
kernel.string=Clean & Cool Kernel for Redmi Note 10 4G (MIUI 14)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=mojito
device.name2=sunny
device.name3=M2101K7AG
device.name4=M2101K7AI
supported.versions=11-13
supported.patchlevels=
'; }

# boot shell variables
BLOCK=boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching
. tools/ak3-core.sh;

# boot install
split_boot;
flash_boot;
if [ -f /tmp/anykernel/dtbo.img ]; then
    flash_dtbo;
fi
### end boot install
EOF
    fi
    echo ">> AnyKernel3 berhasil dikonfigurasi."
else
    echo ">> [3/3] AnyKernel3 sudah ada di $ANYKERNEL_DIR. Melewati..."
fi

echo "=========================================================="
echo " Selesai! Semua source dan toolchain telah siap."
echo " Kompilasi kernel akan berjalan di native ext4 WSL2 (super cepat & tanpa tabrakan file)."
echo " Silakan lanjutkan dengan:"
echo "   bash build_all.sh"
echo "=========================================================="
