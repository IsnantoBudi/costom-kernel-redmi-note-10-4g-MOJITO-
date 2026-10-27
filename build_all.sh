#!/usr/bin/env bash
# ==============================================================================
# Master Runner: build_all.sh
# Eksekusi terpadu download source & kompilasi kernel
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "=========================================================="
echo "    REDMI NOTE 10 4G (MOJITO) - KERNEL BUILD SUITE"
echo "=========================================================="
echo " Target: MIUI 14 (Android 12) | Profil: Cool & Balanced"
echo "=========================================================="

# 1. Validasi Dependensi Wajib (make, bc, bison, flex, gcc/clang)
MISSING_DEPS=()
for cmd in make bc bison flex git tar zip; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_DEPS+=("$cmd")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "=========================================================="
    echo " [PERHATIAN] Paket dependensi build belum terpasang: ${MISSING_DEPS[*]}"
    echo " Silakan jalankan perintah ini di terminal WSL Anda:"
    echo ""
    echo "    bash scripts/01_setup_wsl_env.sh"
    echo ""
    echo " (Masukkan password sudo pengguna WSL Anda saat diminta)"
    echo "=========================================================="
    exit 1
fi

# 2. Pastikan dependensi / source sudah ada
WORK_DIR="$HOME/kernel_workspace_mojito"
if [ ! -d "$WORK_DIR/kernel_src" ] && [ ! -d "$ROOT_DIR/kernel_src" ]; then
    echo ">> Source belum lengkap. Menjalankan pengunduhan source..."
    bash scripts/02_fetch_sources.sh
else
    echo ">> Source tree kernel sudah siap."
fi

# 3. Jalankan proses kompilasi
echo ">> Memulai proses kompilasi..."
bash scripts/03_build_kernel.sh

# 4. Generate seluruh 5 varian kernel V2.0
if [ -f "scripts/build_variants.py" ]; then
    echo ">> Membangun seluruh 5 varian paket rilis V2.0..."
    python3 scripts/build_variants.py
fi
