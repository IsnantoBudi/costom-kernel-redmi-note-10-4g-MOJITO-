#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/mnt/d/Project/kernel redmi note 10"
WORK_DIR="/home/zygarde/kernel_workspace_mojito"
KERNEL_SRC="$WORK_DIR/kernel_src"
TOOLCHAIN_BIN="$WORK_DIR/toolchain/proton-clang/bin"
OUT_DIR="$WORK_DIR/out"

# Ensure gcc-wrapper is Python3 pass-through
cat << 'EOF' > "$KERNEL_SRC/scripts/gcc-wrapper.py"
#!/usr/bin/env python3
import sys, subprocess
sys.exit(subprocess.call(sys.argv[1:]))
EOF
chmod +x "$KERNEL_SRC/scripts/gcc-wrapper.py"

export PATH="$TOOLCHAIN_BIN:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

cd "$KERNEL_SRC"
echo ">> Running make mojito_defconfig..."
make O="$OUT_DIR" ARCH=arm64 CC=clang mojito_defconfig

echo ">> Applying tuning fragment..."
bash "$ROOT_DIR/scripts/apply_defconfig_tuning.sh" \
    "$OUT_DIR/.config" \
    "$ROOT_DIR/patches/mojito_cool_balanced.cfg" \
    "$KERNEL_SRC/scripts/config"

echo ">> Running olddefconfig to validate applied settings..."
make O="$OUT_DIR" ARCH=arm64 CC=clang olddefconfig

echo ">> Testing compilation of init/ with Clang (16 cores)..."
make -j16 O="$OUT_DIR" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- init/
echo ">> SUCCESS! INIT COMPILED!"
