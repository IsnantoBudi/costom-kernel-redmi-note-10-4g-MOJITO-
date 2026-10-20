# Custom Kernel Build Suite - Redmi Note 10 4G (mojito / sunny)
> **Target Spesifikasi**: MIUI Global 14 (Android 12) | Kernel Base 4.14.262 | SoC Qualcomm Snapdragon 678 (SM6150) | Toolchain: Proton-Clang

Suite otomasi kompilasi custom kernel yang dirancang khusus agar **ringan, adem, hemat daya tanpa lag**, serta dilengkapi dengan **Aggressive 33W Fast Charging** pada ROM resmi MIUI 14.

---

## 📦 3 Pilihan Varian Kernel (Tersedia di Folder `output/`)

Repositori ini menyediakan 3 varian kernel flashable zip siap pakai yang disesuaikan dengan kebutuhan preferensi pengguna:

| Varian / Nama File | Profil Charging | CPU & GPU Profile | Karakteristik & Rekomendasi |
| :--- | :--- | :--- | :--- |
| **1. Normal Charging**<br>`output/AnyKernel3-Mojito-MIUI14-Cool-20261020_1342 normal charging.zip` | Standar Pabrik Xiaomi (Batas suhu 45°C, screen-on 1000mA) | CPU Standar (hingga 2.21 GHz), GPU Standar (hingga 845 MHz) | **Paling Aman untuk Baterai**: Menggunakan kurva pengisian daya original bawaan pabrik, dipadukan dengan optimasi scheduler Schedutil, ZRAM LZ4, dan TCP BBR agar baterai awet jangka panjang. |
| **2. Fast Charging**<br>`output/AnyKernel3-Mojito-MIUI14-Cool-20261020_1421 fast charging.zip` | Aggressive 33W (Screen-on ~4.5A / 22W, Thermal limit 47°C, step-chg s/d 90%) | CPU Standar (hingga 2.21 GHz), GPU Standar (hingga 845 MHz) | **Performa Penuh & Fast Charge**: Kecepatan clock prosesor tetap standar bawaan Qualcomm (2.21 GHz), namun pengisian daya dilonggarkan agresif agar ngecas tetap kilat meski layar menyala. |
| **3. UltraCool & FastCharge (Recommended)**<br>`output/AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-20261020_1447.zip`<br>*(Simbolis: `output/AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-latest.zip`)* | Aggressive 33W (Screen-on ~4.5A / 22W, Thermal limit 47°C, step-chg s/d 90%) | **CPU Capped @ 1.90 GHz**, **GPU Capped @ 700 MHz**, **Schedutil 500µs / 30ms** | **Paling Adem, Hemat Daya & Ngecas Kilat**: Edisi unggulan yang memangkas frekuensi rakus daya (+64% power) dan mengunci latensi respons UI 60 FPS tanpa micro-stutter. Suhu ponsel paling dingin untuk pemakaian harian & gaming. |

---

## ⚡ Detail Lokasi & Arsitektur Optimalisasi

### 1. Optimalisasi Manajemen Daya & Temperatur (UltraCool Edition):
* **CPU Big Core Capping (`arch/arm64/boot/dts/qcom/sm6150.dtsi`)**:
  - Frekuensi Big Core Kryo 460 Gold dikunci maksimal pada **1.90 GHz** (`1900800`).
  - Menghilangkan frekuensi 2.11 GHz dan 2.21 GHz yang menghasilkan lonjakan tegangan dan panas tertinggi, tanpa menurunkan kelancaran render UI layar 60Hz.
* **Governor Anti-Stutter (`kernel/sched/cpufreq_schedutil.c`)**:
  - `up_rate_limit_us = 500`: Lompatan frekuensi super responsif (0.5 milidetik) saat jari menyentuh layar agar animasi 60 FPS tidak drop.
  - `down_rate_limit_us = 30000`: Tahanan frekuensi 30 milidetik saat jeda render frame untuk mencegah osilasi naik-turun frekuensi penyebab *micro-stutter*.
* **GPU Ceiling (`drivers/gpu/msm/kgsl_pwrctrl.c`)**:
  - Powerlevel default GPU Adreno 612 dibatasi pada level **700 MHz (NOM)**, mencegah lonjakan ke 845 MHz Turbo saat scrolling aplikasi.

### 2. Optimalisasi Fast Charging 33W:
* **Screen-On Charging Bypass (`drivers/power/supply/qcom/smb5-lib.c`)**:
  - Arus pengisian cepat (*Fast Charge Current*) saat layar menyala dipertahankan minimal **4500mA (~22W)**, mencegah penurunan drastis ke 1000mA.
* **Thermal Cutoff 47°C (`drivers/power/supply/ti/cp_qc30.h`)**:
  - Batas suhu perlindungan charge pump TI BQ2597x dinaikkan dari 45°C ke **47°C** (`JEITA_WARM_THR = 470`) dengan level thermal maksimal hingga level 15.
* **Relaxed Step-Charging Curve (`arch/arm64/boot/dts/qcom/sm6150-idp.dtsi`)**:
  - Mempertahankan arus 5.6A - 4.8A hingga ambang voltase 4.47V (~90% kapasitas baterai) sebelum melambat ke tahap akhir.

### 3. Kepatuhan Android 12 & AnyKernel3:
* **Android Boot Header v3**: Binary berupa `Image.gz` murni tanpa appended DTB, mencegah kerusakan kalkulasi offset ramdisk pada bootloader Qualcomm ABL.
* **Deteksi Partisi Dinamis**: Menggunakan `BLOCK=boot;` dan `IS_SLOT_DEVICE=auto;` pada `anykernel.sh` agar kompatibel di semua TWRP dan OrangeFox.

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
├── output/                      # Berisi 3 varian flashable zip AnyKernel3
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

---

## 🛡️ Panduan Flashing via Custom Recovery

1. Salin salah satu file zip pilihan Anda dari folder `output/` ke penyimpanan internal ponsel atau flashdisk OTG.
2. Masuk ke **TWRP / OrangeFox Recovery** (`Volume Atas + Tombol Power`).
3. Pilih menu **Install** > pilih file zip kernel yang diinginkan.
4. Geser untuk konfirmasi flash (**Swipe to Confirm Flash**).
5. Pilih **Reboot System**.

> [!TIP]
> Jika sewaktu-waktu ingin kembali ke kernel stock bawaan pabrik, gunakan skrip [PULIHKAN_HP_STOCK_BOOT.bat](PULIHKAN_HP_STOCK_BOOT.bat) dengan menghubungkan ponsel pada mode Fastboot.
