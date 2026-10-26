#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$HOME/kernel_workspace_mojito"
OUT_DIR="$WORK_DIR/out"
ANYKERNEL_DIR="$WORK_DIR/anykernel3"
OUTPUT_ZIP_DIR="$ROOT_DIR/output"

echo ">> Updating anykernel.sh..."
cp "$ROOT_DIR/anykernel.sh" "$ANYKERNEL_DIR/anykernel.sh"

AK3_TMP="$OUT_DIR/ak3_package"
rm -rf "$AK3_TMP"
cp -r "$ANYKERNEL_DIR" "$AK3_TMP"

# Salin kernel image
rm -f "$AK3_TMP/Image.gz-dtb"
cp "$OUT_DIR/arch/arm64/boot/Image.gz" "$AK3_TMP/Image.gz"

# Salin dtb (tabel frekuensi 1.90 GHz)
cp "$OUT_DIR/arch/arm64/boot/dts/qcom/sm6150.dtb" "$AK3_TMP/dtb"

# Buat file zip
DATE_STR=$(date '+%Y%m%d_%H%M')
ZIP_NAME="AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-${DATE_STR}.zip"
cd "$AK3_TMP"
zip -r9 "$OUTPUT_ZIP_DIR/$ZIP_NAME" * -x .git* README.md *placeholder
cp -f "$OUTPUT_ZIP_DIR/$ZIP_NAME" "$OUTPUT_ZIP_DIR/AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-latest.zip"
cp -f "$OUTPUT_ZIP_DIR/$ZIP_NAME" "$OUTPUT_ZIP_DIR/AnyKernel3-Mojito-MIUI14-Cool-latest.zip"

echo "=========================================================="
echo " ✅ AnyKernel3 ZIP BERHASIL DIPERBAIKI & DIBUAT ULANG!"
echo " Berkas DTB & Image.gz telah terpasang di root ZIP."
echo " Output File: $OUTPUT_ZIP_DIR/$ZIP_NAME"
echo "=========================================================="
