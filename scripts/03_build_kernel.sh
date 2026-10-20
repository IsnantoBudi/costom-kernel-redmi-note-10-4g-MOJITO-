#!/usr/bin/env bash
# ==============================================================================
# Script 03: Build Kernel & AnyKernel3 Packager
# Target: Redmi Note 10 4G (mojito / sunny) - MIUI 14 (Android 12)
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$HOME/kernel_workspace_mojito"
KERNEL_SRC="$WORK_DIR/kernel_src"
TOOLCHAIN_DIR="$WORK_DIR/toolchain/proton-clang"
TOOLCHAIN_BIN="$TOOLCHAIN_DIR/bin"
ANYKERNEL_DIR="$WORK_DIR/anykernel3"
OUT_DIR="$WORK_DIR/out"
OUTPUT_ZIP_DIR="$ROOT_DIR/output"

mkdir -p "$WORK_DIR/toolchain"
mkdir -p "$OUTPUT_ZIP_DIR"

echo "=========================================================="
echo " [START] Kompilasi Custom Kernel Redmi Note 10 4G"
echo " Waktu Mulai  : $(date '+%Y-%m-%d %H:%M:%S')"
echo " Source Kernel: $KERNEL_SRC"
echo " Toolchain    : $TOOLCHAIN_DIR"
echo " Output Zip   : $OUTPUT_ZIP_DIR"
echo "=========================================================="

# 1. Pastikan Toolchain Berada di Storage Native ext4 (Mencegah Bug Spasi & Lambat)
if [ ! -f "$TOOLCHAIN_BIN/clang" ]; then
    if [ -d "$ROOT_DIR/toolchain/proton-clang" ]; then
        echo ">> Menyalin Proton-Clang ke storage native WSL2..."
        cp -r "$ROOT_DIR/toolchain/proton-clang" "$TOOLCHAIN_DIR"
    else
        echo "Error: Toolchain Proton-Clang tidak ditemukan!"
        exit 1
    fi
fi

# 2. Perbaiki Kompatibilitas Ubuntu 24.04 (Bypass Old LD yang tidak support .relr.dyn)
if [ -f "$TOOLCHAIN_BIN/ld" ]; then
    mv "$TOOLCHAIN_BIN/ld" "$TOOLCHAIN_BIN/ld.gnu236" || true
fi
if [ -f "$TOOLCHAIN_BIN/ld.bfd" ]; then
    mv "$TOOLCHAIN_BIN/ld.bfd" "$TOOLCHAIN_BIN/ld.bfd.gnu236" || true
fi

# 3. Patch gcc-wrapper.py agar Kompatibel Python3
cat << 'EOF' > "$KERNEL_SRC/scripts/gcc-wrapper.py"
#!/usr/bin/env python3
import sys, subprocess
sys.exit(subprocess.call(sys.argv[1:]))
EOF
chmod +x "$KERNEL_SRC/scripts/gcc-wrapper.py"

# 4. Patch RTIC data in init.h (Mencegah error relocation truncated R_AARCH64_ADR_PREL_PG_HI21)
python3 -c "
p = '$KERNEL_SRC/include/linux/init.h'
with open(p, 'r') as f: s = f.read()
s = s.replace('#define __rticdata  __attribute__((section(\".bss.rtic\")))', '#define __rticdata')
with open(p, 'w') as f: f.write(s)
"

# 5. Pastikan AnyKernel3 Siap di WORK_DIR
if [ ! -d "$ANYKERNEL_DIR" ]; then
    if [ -d "$ROOT_DIR/anykernel3" ]; then
        cp -r "$ROOT_DIR/anykernel3" "$ANYKERNEL_DIR"
    else
        git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git "$ANYKERNEL_DIR"
    fi
fi

# Konfigurasi AnyKernel3 khusus mojito/sunny
cat << 'EOF' > "$ANYKERNEL_DIR/anykernel.sh"
### AnyKernel3 Packaging Config for Redmi Note 10 4G (mojito/sunny)
properties() { '
kernel.string=UltraCool & FastCharge Kernel for Redmi Note 10 4G (MIUI 14)
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

# shell variables
BLOCK=boot;
block=boot;
IS_SLOT_DEVICE=auto;
is_slot_device=auto;
RAMDISK_COMPRESSION=auto;
ramdisk_compression=auto;
PATCH_VBMETA_FLAG=auto;
patch_vbmeta_flag=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel boot install
dump_boot;

# begin ramdisk changes

write_boot;
## end boot install
EOF

# 6. Setup Environment Variabel Kompilasi
export PATH="$TOOLCHAIN_BIN:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export KBUILD_BUILD_USER="isnanto"
export KBUILD_BUILD_HOST="workstation"

# Deteksi ccache
if command -v ccache &> /dev/null; then
    export USE_CCACHE=1
    export CCACHE_EXEC="$(command -v ccache)"
    echo ">> ccache aktif untuk mempercepat kompilasi."
fi

# 7. Pastikan Source Tree Bersih untuk Out-of-Tree Build
cd "$KERNEL_SRC"
if [ -f ".config" ]; then
    echo ">> Membersihkan source tree (make mrproper)..."
    make mrproper
fi

# 8. Generate & Tuning Defconfig
DEFCONFIG_TARGET="mojito_defconfig"
if [ ! -f "arch/arm64/configs/$DEFCONFIG_TARGET" ]; then
    if [ -f "arch/arm64/configs/vendor/mojito_perf_defconfig" ]; then
        DEFCONFIG_TARGET="vendor/mojito_perf_defconfig"
    fi
fi

echo ">> Menyiapkan defconfig: $DEFCONFIG_TARGET..."
make O="$OUT_DIR" ARCH=arm64 CC=clang "$DEFCONFIG_TARGET"

# Aplikasikan fragment konfigurasi adem & ringan
if [ -f "$ROOT_DIR/patches/mojito_cool_balanced.cfg" ]; then
    echo ">> Mengaplikasikan fragment optimasi hemat daya & temperatur adem..."
    bash "$ROOT_DIR/scripts/apply_defconfig_tuning.sh" \
        "$OUT_DIR/.config" \
        "$ROOT_DIR/patches/mojito_cool_balanced.cfg" \
        "$KERNEL_SRC/scripts/config"
    
    echo ">> Memvalidasi konfigurasi kernel (olddefconfig)..."
    make O="$OUT_DIR" ARCH=arm64 CC=clang olddefconfig
fi

# 9. Eksekusi Kompilasi Penuh Kernel
CPU_CORES=$(nproc --all)
echo "=========================================================="
echo " Memulai kompilasi penuh dengan $CPU_CORES core CPU..."
echo " Target: Image.gz & dtbs (Android 12 Boot Header v3)"
echo "=========================================================="
START_TIME=$(date +%s)

make -j"$CPU_CORES" \
    O="$OUT_DIR" \
    ARCH=arm64 \
    CC=clang \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    Image.gz dtbs 2>&1 | tee "$OUT_DIR/build.log"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 10. Validasi Output Kernel
KERNEL_IMAGE="$OUT_DIR/arch/arm64/boot/Image.gz"
if [ ! -f "$KERNEL_IMAGE" ]; then
    echo "=========================================================="
    echo " [ERROR] Kompilasi GAGAL! Kernel Image.gz tidak terbentuk."
    echo " Periksa baris terakhir file log di: $OUT_DIR/build.log"
    echo "=========================================================="
    exit 1
fi

echo "=========================================================="
echo " [SUCCESS] Kompilasi selesai dalam ${DURATION} detik!"
echo " Kernel Image: $KERNEL_IMAGE ($(du -h "$KERNEL_IMAGE" | cut -f1))"
echo "=========================================================="

# 11. Packaging ke AnyKernel3 Flashable Zip
echo ">> Menyiapkan AnyKernel3 flashable zip..."
AK3_TMP="$OUT_DIR/ak3_package"
rm -rf "$AK3_TMP"
cp -r "$ANYKERNEL_DIR" "$AK3_TMP"

# Salin kernel image murni (Sesuai spesifikasi Header v3 Android 12)
rm -f "$AK3_TMP/Image.gz-dtb"
cp "$KERNEL_IMAGE" "$AK3_TMP/Image.gz"

# Salin dtbo.img jika ada
if [ -f "$OUT_DIR/arch/arm64/boot/dtbo.img" ]; then
    cp "$OUT_DIR/arch/arm64/boot/dtbo.img" "$AK3_TMP/dtbo.img"
    echo ">> dtbo.img disertakan dalam package."
fi

# Buat file zip
DATE_STR=$(date '+%Y%m%d_%H%M')
ZIP_NAME="AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-${DATE_STR}.zip"
cd "$AK3_TMP"
zip -r9 "$OUTPUT_ZIP_DIR/$ZIP_NAME" * -x .git* README.md *placeholder
cp -f "$OUTPUT_ZIP_DIR/$ZIP_NAME" "$OUTPUT_ZIP_DIR/AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-latest.zip"
cp -f "$OUTPUT_ZIP_DIR/$ZIP_NAME" "$OUTPUT_ZIP_DIR/AnyKernel3-Mojito-MIUI14-Cool-latest.zip"

echo "=========================================================="
echo " ✅ FLASHABLE ZIP BERHASIL DIBUAT!"
echo " Ukuran File: $(du -h "$OUTPUT_ZIP_DIR/$ZIP_NAME" | cut -f1)"
echo " Lokasi di Windows: $OUTPUT_ZIP_DIR/$ZIP_NAME"
echo "=========================================================="
