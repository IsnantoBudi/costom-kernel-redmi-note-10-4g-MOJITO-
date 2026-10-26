#!/usr/bin/env bash
# ==============================================================================
# Script: Build All Kernel Variants for Redmi Note 10 4G (mojito/sunny)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/build_variants.py"
