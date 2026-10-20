#!/usr/bin/env bash
# ==============================================================================
# Helper Script: Apply Defconfig Tuning
# Mengaplikasikan fragment konfigurasi ke .config kernel
# ==============================================================================

set -euo pipefail

CONFIG_FILE="${1:-out/.config}"
FRAGMENT_FILE="${2:-patches/mojito_cool_balanced.cfg}"
CONFIG_TOOL="${3:-kernel_src/scripts/config}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: File $CONFIG_FILE tidak ditemukan!"
    exit 1
fi

if [ ! -f "$FRAGMENT_FILE" ]; then
    echo "Error: File fragment $FRAGMENT_FILE tidak ditemukan!"
    exit 1
fi

echo ">> Mengaplikasikan parameter tuning dari $FRAGMENT_FILE ke $CONFIG_FILE..."

while IFS= read -r line || [ -n "$line" ]; do
    # Lewati baris komentar dan baris kosong
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    if [[ "$line" =~ ^(CONFIG_[A-Za-z0-9_]+)=([ynm])$ ]]; then
        OPT_NAME="${BASH_REMATCH[1]#CONFIG_}"
        OPT_VAL="${BASH_REMATCH[2]}"
        if [ "$OPT_VAL" = "y" ]; then
            "$CONFIG_TOOL" --file "$CONFIG_FILE" --enable "$OPT_NAME" || true
        elif [ "$OPT_VAL" = "n" ]; then
            "$CONFIG_TOOL" --file "$CONFIG_FILE" --disable "$OPT_NAME" || true
        elif [ "$OPT_VAL" = "m" ]; then
            "$CONFIG_TOOL" --file "$CONFIG_FILE" --module "$OPT_NAME" || true
        fi
    elif [[ "$line" =~ ^(CONFIG_[A-Za-z0-9_]+)=\"([^\"]*)\"$ ]]; then
        OPT_NAME="${BASH_REMATCH[1]#CONFIG_}"
        OPT_VAL="${BASH_REMATCH[2]}"
        "$CONFIG_TOOL" --file "$CONFIG_FILE" --set-str "$OPT_NAME" "$OPT_VAL" || true
    elif [[ "$line" =~ ^(CONFIG_[A-Za-z0-9_]+)=([0-9]+)$ ]]; then
        OPT_NAME="${BASH_REMATCH[1]#CONFIG_}"
        OPT_VAL="${BASH_REMATCH[2]}"
        "$CONFIG_TOOL" --file "$CONFIG_FILE" --set-val "$OPT_NAME" "$OPT_VAL" || true
    fi
done < "$FRAGMENT_FILE"

echo ">> Selesai mengaplikasikan tuning konfigurasi."
