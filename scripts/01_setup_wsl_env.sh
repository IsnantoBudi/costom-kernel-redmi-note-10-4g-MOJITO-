#!/usr/bin/env bash
# ==============================================================================
# Script 01: Setup WSL2 Environment Dependencies
# Target: Ubuntu (termasuk 22.04 LTS & 24.04 LTS Noble) / Debian di WSL2
# Perangkat: Redmi Note 10 4G (mojito/sunny) - Kernel 4.14 (arm64)
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo " [1/4] Memperbarui Repositori Paket WSL2..."
echo "=========================================================="
sudo apt update -y && sudo apt upgrade -y

echo "=========================================================="
echo " [2/4] Menginstal Toolchain & Dependensi Build Kernel..."
echo "=========================================================="
sudo apt install -y \
    bc \
    bison \
    build-essential \
    ccache \
    cpio \
    curl \
    flex \
    git \
    git-lfs \
    libelf-dev \
    libssl-dev \
    lld \
    llvm \
    lz4 \
    make \
    ninja-build \
    python3 \
    python-is-python3 \
    rsync \
    tar \
    unzip \
    wget \
    xz-utils \
    zip \
    zlib1g-dev

echo "=========================================================="
echo " [3/4] Mengonfigurasi ccache untuk Mempercepat Build..."
echo "=========================================================="
ccache -M 30G
ccache -s

echo "=========================================================="
echo " [4/4] Selesai! Environment WSL2 siap untuk kompilasi."
echo " Silakan lanjutkan dengan:"
echo "   bash build_all.sh"
echo "=========================================================="
