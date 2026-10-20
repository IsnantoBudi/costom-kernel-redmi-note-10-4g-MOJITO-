# Custom Kernel Build Suite - Redmi Note 10 4G (mojito / sunny)
> **Target Spesifikasi**: MIUI Global 14 (Android 12) | Kernel Base 4.14.262 | SoC Qualcomm Snapdragon 678 (SM6150) | Toolchain: Proton-Clang

Suite otomasi kompilasi custom kernel yang dirancang khusus agar **ringan, adem, hemat daya tanpa lag**, serta dilengkapi dengan **Aggressive 33W Fast Charging** pada ROM resmi MIUI 14.

---

## ⚡ Fitur Utama ("UltraCool & FastCharge Edition")

1. **CPU Frequency Sweet-Spot (Kryo 460 Gold Capping)**:
   - Frekuensi maksimal Big Cores (Cortex-A76) dikunci di **1.90 GHz** (`1900800`).
   - Memotong frekuensi rakus daya 2.11 GHz dan 2.21 GHz yang memicu lonjakan konsumsi daya +64% dan panas berlebih, tanpa mengurangi kehalusan animasi layar 60Hz.
2. **Schedutil Governor Anti-Stutter & Instant Response**:
   - `up_rate_limit_us = 500`: Lompatan frekuensi super responsif (0.5 milidetik) saat jari menyentuh layar agar animasi 60 FPS terkunci mulus tanpa frame drop.
   - `down_rate_limit_us = 30000`: Tahanan frekuensi 30 milidetik saat jeda render antar-frame untuk melenyapkan osilasi naik-turun frekuensi penyebab micro-stutter.
3. **GPU Adreno 612 Thermal Ceiling**:
   - Batas daya default Adreno 612 dibatasi di level **700 MHz (NOM)**, mencegah GPU melonjak ke 845 MHz Turbo saat scrolling aplikasi atau pemutaran video.
4. **Aggressive Fast Charging 33W**:
   - **Screen-On Charging**: Arus pengisian cepat saat layar menyala dipertahankan minimal **4500mA (~22W)**, tidak lagi anjlok ke 1000mA.
   - **Thermal Cutoff 47°C**: Ambang batas proteksi panas charge pump TI BQ2597x dilonggarkan ke 47°C agar mode daya 33W bertahan lebih lama.
   - **Relaxed Step-Charging**: Arus 5.6A - 4.8A dipertahankan hingga ambang voltase 4.47V (~90% kapasitas baterai) sebelum melambat ke tahap akhir.
5. **Android 12 Boot Header Version 3 Compliance**:
   - Paket AnyKernel3 memuat `Image.gz` murni sesuai standar Boot Header v3 Google/Qualcomm, menjamin offset ramdisk tidak rusak di bootloader ABL.
6. **Deteksi Partisi Otomatis (Anti-Error)**:
   - AnyKernel3 modern dengan deteksi partisi dinamis (`BLOCK=boot;` dan `IS_SLOT_DEVICE=auto;`) untuk TWRP dan OrangeFox.

---

## 📁 Struktur Direktori

```text
.
├── build_all.sh                 # Master script otomasi kompilasi
├── scripts/
│   ├── 01_setup_wsl_env.sh      # Setup toolchain dan dependensi WSL2 Ubuntu
│   ├── 02_fetch_sources.sh      # Unduh Proton-Clang & source kernel mojito
│   └── 03_build_kernel.sh       # Kompilasi Clang & pembuatan AnyKernel3 zip
├── patches/
│   ├── mojito_cool_balanced.cfg # Fragment konfigurasi kernel hemat daya
│   └── 0001-mojito-ultracool-fastcharge.patch # Patch driver charging, CPU/GPU, & Schedutil
├── output/                      # Hasil flashable zip AnyKernel3
├── PULIHKAN_HP_STOCK_BOOT.bat   # Skrip pemulihan instan 1-klik via Fastboot
└── README.md                    # Dokumentasi proyek
```

---

## 🚀 Panduan Kompilasi di WSL2

Buka terminal Ubuntu di WSL2:

```bash
cd "/mnt/d/Project/kernel redmi note 10"

# Jalankan kompilasi penuh 1-klik:
bash build_all.sh
```

Hasil paket flashable zip akan otomatis tersedia di folder `output/`:
- `AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-latest.zip`

---

## 🛡️ Panduan Flashing via Custom Recovery

1. Salin file zip dari folder `output/` ke penyimpanan internal ponsel atau flashdisk OTG.
2. Masuk ke **TWRP / OrangeFox Recovery** (`Volume Atas + Tombol Power`).
3. Pilih menu **Install** > pilih file zip `AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-latest.zip`.
4. Geser untuk konfirmasi flash (**Swipe to Confirm Flash**).
5. Pilih **Reboot System**.

> [!TIP]
> Jika sewaktu-waktu ingin kembali ke kernel stock bawaan pabrik, gunakan skrip [PULIHKAN_HP_STOCK_BOOT.bat](PULIHKAN_HP_STOCK_BOOT.bat) dengan menghubungkan ponsel pada mode Fastboot.
