# Custom Kernel Build Suite - Redmi Note 10 4G (mojito / sunny)
> **Target Spesifikasi**: MIUI Global 14 (Android 12) | Kernel Base 4.14.262 | SoC Qualcomm Snapdragon 678 (SM6150) | Toolchain: Proton-Clang | **Rilis: V2.0 Edition**

Suite otomasi kompilasi custom kernel yang dirancang khusus agar **ringan, adem, hemat daya tanpa lag**, dilengkapi **Aggressive 33W Fast Charging**, serta paket fitur esensial V2.0: **Google BBR**, **Hotspot Tethering Bypass (TTL 64 / HL 64)**, **Simple LMK**, dan **Dynamic Fsync** pada ROM resmi MIUI 14.

---

## 📦 5 Pilihan Varian Kernel (Tersedia di Folder `output/`)

Repositori ini menyediakan 5 varian kernel flashable zip siap pakai dalam seri rilis **V2.0 Edition** (dengan arsip v1.0 tetap dipertahankan):

| Varian / Nama File V2.0 | Batas Frekuensi CPU (Big / Little) | Fitur Jaringan & Performa V2.0 | Karakteristik & Rekomendasi |
| :--- | :--- | :--- | :--- |
| **1. UltraCool (Recommended)**<br>`output/AnyKernel3-Mojito-v2.0-UltraCool-Big1.9-Little1.5.zip`<br>*(Alias: `AnyKernel3-Mojito-v2.0-UltraCool-latest.zip`)* | **Big: 1.90 GHz** (`1900800`)<br>**Little: 1.51 GHz** (`1516800`) | BBR TCP + TTL 64 + Simple LMK + Dynamic Fsync + 33W Fast Charge | **Paling Adem & Baterai Paling Awet (Sudah Teruji Fisik)**: Menghapus step frekuensi terpanas, menjaga suhu ponsel tetap dingin, anti-reload GCam LMC & WhatsApp, ping game stabil. Sustained performance stabil di ~94 GIPS. |
| **2. Cool (Sweet Spot)**<br>`output/AnyKernel3-Mojito-v2.0-Cool-Big2.0-Little1.6.zip` | **Big: 2.01 GHz** (`2016000`)<br>**Little: 1.59 GHz** (`1593600`) | BBR TCP + TTL 64 + Simple LMK + Dynamic Fsync + 33W Fast Charge | **Keseimbangan Ideal Harian**: Sedikit lebih bertenaga dibanding UltraCool untuk multitasking harian yang padat, dengan efisiensi termal yang tetap terkendali. |
| **3. Performance**<br>`output/AnyKernel3-Mojito-v2.0-Performance-Big2.1-Little1.7.zip` | **Big: 2.11 GHz** (`2112000`)<br>**Little: 1.70 GHz** (`1708800`) | BBR TCP + TTL 64 + Simple LMK + Dynamic Fsync + 33W Fast Charge | **Gaming Responsif Tanpa Overheat**: Membuka clock 2.11 GHz untuk framerate game kompetitif, namun tetap memotong step frekuensi puncak 2.21 GHz yang paling rakus daya dan panas. |
| **4. StockMax**<br>`output/AnyKernel3-Mojito-v2.0-StockMax-Big2.2-Little1.7.zip` | **Big: 2.20 GHz** (`2208000`)<br>**Little: 1.70 GHz** (`1708800`) | BBR TCP + TTL 64 + Simple LMK + Dynamic Fsync + 33W Fast Charge | **Performa Big Core Maksimal Bawaan**: Memanfaatkan clock penuh 2.20 GHz Kryo 460 Gold standar pabrik, dipadu dengan Little Core 1.70 GHz yang lebih hemat daya. |
| **5. FullStock**<br>`output/AnyKernel3-Mojito-v2.0-FullStock-Big2.2-Little1.8.zip` | **Big: 2.20 GHz** (`2208000`)<br>**Little: 1.80 GHz** (`1804800`) | BBR TCP + TTL 64 + Simple LMK + Dynamic Fsync + 33W Fast Charge | **100% Frekuensi Bawaan Pabrik**: Clock CPU standar pabrik seutuhnya, namun sudah dilengkapi perbaikan Qualcomm OSM boost bypass, thermal floor mitigation (anti drop ke 1.2 GHz), dan Fast Charge 33W. |

---

## ⚡ Detail Lokasi & Arsitektur Optimalisasi

### 1. Optimalisasi Manajemen Daya & Temperatur:
* **CPU Frequency Capping & OPP Table (`arch/arm64/boot/dts/qcom/sm6150.dtsi`)**:
  - Disesuaikan per-varian melalui Device Tree Blob (`dtb`) di partisi `vendor_boot`.
  - Dilengkapi patch bypass `CPUFREQ_BOOST_FREQ` pada `drivers/clk/qcom/clk-cpu-osm.c` (`.boost_enabled = false`) agar capping frekuensi benar-benar terkunci pada hardware Snapdragon 678.
* **Thermal Throttling Floor Mitigation @ 1.516 GHz**:
  - `drivers/thermal/cpu_cooling.c`: Memastikan batas bawah mitigasi termal kernel (`clip_freq`) tidak jatuh di bawah 1.516 GHz.
  - `drivers/cpufreq/cpufreq.c`: Mencegah daemon thermal pengguna (`mi_thermald`) mencekik `scaling_max_freq` di bawah 1.516 GHz saat ponsel hangat.
  - `arch/arm64/boot/dts/qcom/sm6150-thermal.dtsi`: Mengatur `low_limits_floor` pada seluruh 16 thermal zones agar sinkron dengan tabel frekuensi.
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

### 3. Kepatuhan Android 12 Boot Header v3 & AnyKernel3:
* **Dual-Flash Partition Flashing (`anykernel.sh`)**:
  - Android 12 Boot Header v3 memisahkan biner kernel (`Image.gz` pada partisi `boot`) dan Device Tree (`dtb` pada partisi `vendor_boot`).
  - `anykernel.sh` mem-flash kedua partisi secara atomik dalam 1x klik flash di recovery.
* **Case-Sensitivity & Absolute Block Path**:
  - Menggunakan huruf kapital `BLOCK=/dev/block/bootdevice/by-name/boot` dan `IS_SLOT_DEVICE=auto` agar tidak terjadi error `Unable to determine partition` di recovery TWRP / OrangeFox.

### 4. Fitur Esensial V2.0 Edition:
* **Google BBR TCP Congestion Control (`net/ipv4/tcp_bbr.c`)**:
  - Ditetapkan sebagai algoritma TCP default kernel (`CONFIG_DEFAULT_BBR=y`).
  - Mengukur kapasitas pipa bandwidth dan RTT aktual secara dinamis, menjaga throughput maksimal dan latensi ping game online tetap stabil di jaringan 4G fluktuatif.
* **TCP Network Stack Tuning & Upload Expansion**:
  - Injeksi otomatis saat `sys.boot_completed=1` via AnyKernel3 init script:
    - `tcp_fastopen = 3`: Mengizinkan payload data dikirim pada SYN pertama (memangkas 1 full RTT handshake koneksi).
    - `tcp_wmem = 262144 1048576 4194304`: Mengangkat batas soket upload buffer dari 1MB ke **4MB**, menyeimbangkan Bandwidth-Delay Product (BDP) dengan buffer download 8MB.
    - `tcp_slow_start_after_idle = 0`: Mencegah TCP BBR me-reset window aliran data saat koneksi diam beberapa detik.
* **Hotspot Tethering Bypass TTL 64 / HL 64 (`net/netfilter/xt_HL.c` & `net/ipv4/ip_forward.c`)**:
  - Mencegah pengurangan TTL saat perangkat tethering hotspot ke laptop/PC.
  - Dilengkapi dual failsafe: in-kernel forwarding clamp dan script inisialisasi AnyKernel3 saat `sys.boot_completed=1` (otomatis aktif tanpa aplikasi tambahan). Kuota reguler langsung terpakai untuk hotspot.
* **Simple LMK / Sultan LMK (`drivers/staging/android/lowmemorykiller.c`)**:
  - Menggantikan scan LMK bawaan yang berat dengan algoritma cerdas hemat CPU di kernel-space.
  - Mempertahankan ~400MB batas aman RAM 4GB, membunuh proses latar belakang tidak aktif saat memori menipis, dan memproteksi GCam LMC serta WhatsApp dari reload/app kill paksa.
* **Dynamic Fsync (`drivers/misc/dyn_fsync.c`)**:
  - Mematikan operasi fsync sinkron saat layar menyala (*screen ON*) untuk melenyapkan framedrop dan micro-stutter I/O saat scrolling aplikasi.
  - Otomatis memicu sinkronisasi data (*flush*) ke penyimpanan flash UFS saat layar padam (*screen OFF*).

---

## 📁 Struktur Direktori

```text
.
├── build_all.sh                 # Master script otomasi kompilasi
├── scripts/
│   ├── 01_setup_wsl_env.sh      # Setup toolchain dan dependensi WSL2 Ubuntu
│   ├── 02_fetch_sources.sh      # Unduh Proton-Clang & source kernel mojito
│   ├── 03_build_kernel.sh       # Kompilasi Clang & pembuatan AnyKernel3 zip
│   ├── apply_v2_code_changes.py # Injektor otomatis source tree V2.0 (Dynamic Fsync, Simple LMK, TTL)
│   ├── build_variants.py        # Generator otomasi multi-varian V2.0 (1.9 s/d 2.2 GHz)
│   └── build_variants.sh        # Runner bash untuk build_variants.py
├── patches/
│   ├── mojito_cool_balanced.cfg # Fragment konfigurasi kernel hemat daya & BBR/TTL
│   ├── 0001-mojito-ultracool-fastcharge.patch # Patch driver charging, CPU/GPU, & Schedutil
│   └── 0002-mojito-v2-features-suite.patch    # Patch Dynamic Fsync, Simple LMK & TTL Forwarding
├── output/                      # Berisi 5 varian flashable zip AnyKernel3 (v1.0 & V2.0)
├── KIRIM_KERNEL_KE_HP.bat       # Menu interaktif kirim varian kernel via ADB
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

## 🛡️ Panduan Masuk TWRP & Flashing Custom Kernel

### A. Cara Masuk ke TWRP / OrangeFox via File .img di Fastboot (Tanpa Menimpa Kernel)
Redmi Note 10 4G (`mojito`/`sunny`) menggunakan skema partisi A/B tanpa partisi recovery tersendiri. Anda dapat memuat file image recovery secara sementara ke RAM tanpa merusak instalasi kernel yang ada:

* **Opsi 1: Menggunakan Skrip Otomatis 1-Klik (Windows)**:
  1. Letakkan file image recovery Anda (misal `twrp-mojito.img` atau `orangefox.img`) di folder ini, atau cukup seret *(drag-and-drop)* file `.img` ke atas file skrip.
  2. Matikan ponsel, masuk ke mode Fastboot (`Tombol Power + Volume Bawah`).
  3. Hubungkan ponsel ke komputer dengan kabel USB.
  4. Jalankan [MASUK_TWRP_FASTBOOT.bat](MASUK_TWRP_FASTBOOT.bat). Ponsel akan otomatis booting langsung ke antarmuka TWRP.

* **Opsi 2: Perintah Manual via Terminal / Command Prompt**:
  ```bash
  # 1. Pastikan perangkat terdeteksi di mode Fastboot:
  fastboot devices

  # 2. Booting image TWRP ke RAM:
  fastboot boot nama_file_twrp.img
  ```

> [!NOTE]
> Jangan gunakan perintah `fastboot flash recovery` karena Redmi Note 10 tidak memiliki partisi `recovery` terpisah. Perintah `fastboot boot` memuat recovery ke memori RAM secara aman.

---

### B. Prosedur Flashing Kernel via Recovery:

1. Salin file zip kernel pilihan Anda dari folder `output/` (misalnya `AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-latest.zip`) ke penyimpanan internal ponsel atau flashdisk OTG.
2. Di antarmuka **TWRP / OrangeFox**, pilih menu **Install** > cari file zip kernel.
3. ⚠️ **Pastikan kotak centang `[ ] Zip signature verification` TIDAK DICENTANG**.
4. Geser tombol konfirmasi (**Swipe to Confirm Flash**).
   - *Catatan: Installer AnyKernel3 akan otomatis memperbarui kernel pada partisi `boot` dan tabel frekuensi pada `vendor_boot`.*
5. Setelah selesai, pilih **Reboot System**.

---

## ⚠️ Panduan Kritis AnyKernel3 & AI Guardrails (Anti-Regression)

Untuk mencegah error `Unable to determine partition` atau `Updater process ended with ERROR: 1`, setiap perubahan konfigurasi installer wajib mematuhi aturan baku berikut:

1. **Sensitivitas Huruf (Case-Sensitivity)**:
   - Shell environment di Android recovery (`ash`) bersifat **case-sensitive**.
   - Variabel konfigurasi target blok partisi **WAJIB HURUF KAPITAL**:
     ```sh
     BLOCK=/dev/block/bootdevice/by-name/boot;
     block=/dev/block/bootdevice/by-name/boot;
     IS_SLOT_DEVICE=auto;
     is_slot_device=auto;
     ```
   - ⚠️ *Dilarang keras hanya menggunakan huruf kecil (`block=boot;`)* karena `ak3-core.sh` membaca `$BLOCK`. Jika huruf kecil, `$BLOCK` bernilai kosong sehingga TWRP menampilkan error: `Unable to determine  partition. Aborting...`.

2. **Jalur Blok Partisi Absolut**:
   - Selalu gunakan `/dev/block/bootdevice/by-name/boot` daripada sekadar `boot` agar pengenal partisi A/B slot pada UFS Snapdragon 678 terdeteksi instan tanpa mengandalkan pencarian dinamis yang lambat/gagal di TWRP.

3. **Dual-Flash Partisi `boot` dan `vendor_boot` (Android 12 Boot Header v3)**:
   - Partisi `boot` menyimpan kernel biner `Image.gz`, sedangkan partisi `vendor_boot` memuat Device Tree Blob (`dtb` / tabel OPP frekuensi).
   - Skrip `anykernel.sh` memproses kedua partisi secara berurutan dalam 1x flash di TWRP/OrangeFox:
     ```sh
     ## AnyKernel boot install
     dump_boot;
     write_boot;
     ## end boot install

     # vendor_boot install (Device Tree & OPP Table)
     BLOCK=/dev/block/bootdevice/by-name/vendor_boot;
     block=/dev/block/bootdevice/by-name/vendor_boot;
     IS_SLOT_DEVICE=auto;
     is_slot_device=auto;

     reset_ak;

     dump_boot;
     write_boot;
     ## end vendor_boot install
     ```

4. **Thermal Mitigation Floor & Qualcomm OSM Boost Bypass**:
   - Big Core (Kryo 460 Gold) dibatasi maksimal di **1.90 GHz** dan Little Core (Kryo 460 Silver) di **1.51 GHz**.
   - Driver clock Qualcomm `clk-cpu-osm.c` dipatch agar tidak membangkitkan kembali frekuensi puncak sebagai `CPUFREQ_BOOST_FREQ`.
   - Driver thermal `cpu_cooling.c` dan `cpufreq.c` dipasang *hard floor* di **1.516 GHz** sehingga Big Core tidak pernah lagi anjlok ke 1.20 GHz saat uji beban panjang. Seluruh 8 core bekerja sinkron dan stabil di 80%–85% sustained performance (~94k GIPS).

---

## 🔄 Pemulihan ke Kernel Bawaan Pabrik

> [!TIP]
> Jika sewaktu-waktu ingin kembali ke kernel stock bawaan resmi MIUI 14, hubungkan ponsel dalam mode Fastboot lalu jalankan skrip [PULIHKAN_HP_STOCK_BOOT.bat](PULIHKAN_HP_STOCK_BOOT.bat). Skrip akan mengembalikan partisi `boot` ke kondisi original pabrik.

---

## 🧪 Checklist Pengujian Manual Fitur V2.0 (via ADB Shell)

Setelah kernel V2.0 berhasil di-flash dan ponsel menyala di sistem MIUI 14, jalankan langkah-langkah verifikasi berikut melalui terminal / ADB:

1. **Verifikasi Google BBR TCP Congestion Control**:
   ```bash
   adb shell sysctl net.ipv4.tcp_congestion_control
   # Output yang diharapkan:
   # net.ipv4.tcp_congestion_control = bbr
   ```

2. **Verifikasi Dynamic Fsync Status**:
   ```bash
   adb shell cat /sys/kernel/dyn_fsync/Dyn_fsync_active
   # Output saat layar menyala: 1 (aktif menahan I/O wait)
   ```

3. **Verifikasi Hotspot Tethering Bypass (TTL 64 & HL 64)**:
   ```bash
   adb shell iptables -t mangle -L POSTROUTING -v -n
   # Periksa baris POSTROUTING, rule TTL set to 64 terpasang aktif.
   ```
   *Uji Laptop/PC*: Sambungkan laptop ke Hotspot HP, buka Command Prompt di laptop dan jalankan:
   ```cmd
   ping 8.8.8.8
   # Nilai TTL yang diterima adalah 64 (bukan 63/127), terdeteksi sebagai kuota utama.
   ```

4. **Verifikasi Simple LMK & Multitasking**:
   - Buka aplikasi chat (WhatsApp/Telegram) dan browser dengan beberapa tab aktif.
   - Buka **GCam LMC (Hasli)**, bidik beberapa foto HDR+ secara beruntun hingga RAM terisi penuh.
   - Tekan tombol Recent Apps / geser ke WhatsApp: aplikasi langsung terbuka instan **tanpa reload** (*no app kill*).

5. **Verifikasi Batas Frekuensi UltraCool (1.90 GHz / 1.51 GHz)**:
   ```bash
   adb shell cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
   # Output Little Core: 1516800 (1.51 GHz)
   
   adb shell cat /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
   # Output Big Core: 1900800 (1.90 GHz)
   ```

6. **Verifikasi TCP Network Tuning & Upload Buffer**:
   ```bash
   adb shell "cat /proc/sys/net/ipv4/tcp_fastopen; cat /proc/sys/net/ipv4/tcp_wmem; cat /proc/sys/net/ipv4/tcp_slow_start_after_idle"
   # Output yang diharapkan:
   # 3
   # 262144  1048576  4194304
   # 0
   ```

---

## 📶 Panduan Optimasi Jaringan Seluler & Modem (XL 4G / LTE)

Untuk memaksimalkan performa modem Qualcomm Snapdragon X12 pada Redmi Note 10 4G tanpa risiko kehilangan data:

### 1. Private DNS Rendah Latensi (DoT)
* Mengalihkan DNS ke **`dns.nextdns.io`** (atau custom ID NextDNS) memangkas latensi lookup domain dari **~54 ms (AdGuard) menjadi ~40 ms** via Anycast lokal Indonesia tanpa mengorbankan proteksi iklan.
* Perintah via ADB Shell:
  ```bash
  adb shell settings put global private_dns_mode hostname
  adb shell settings put global private_dns_specifier dns.nextdns.io
  ```

### 2. Penguncian Radio ke `LTE only` (Anti-Drop 3G Sunset)
* Kominfo dan seluruh operator di Indonesia telah mematikan jaringan 3G (*3G Sunset*).
* Buka dialer telepon, ketik `*#*#4636#*#*` > **Phone Information 1** > ubah *Set Preferred Network Type* ke **`LTE only`**.
* Mencegah modem Snapdragon 678 membuang siklus RF untuk memindai jaringan 2G/3G yang sudah nonaktif dan mengeliminasi ping spike/koneksi blank saat sinyal melemah sejenak. Fitur VoLTE XL tetap aktif normal (`mVopsSupport = 2`).

### 3. Profil APN XL Axiata (Dual-Stack IPv4/IPv6)
* Pada *Settings > SIM card & mobile networks > XL > Access Point Names*:
  - **APN Protocol**: Ganti dari `IPv4` ke **`IPv4/IPv6`**
  - **APN Roaming Protocol**: **`IPv4/IPv6`**
  - **APN Type**: `default,supl,xcap`
  - **Bearer**: Centang **`LTE`** (hapus centang `Unspecified`)
* Menghubungkan paket data langsung ke CDN Google, Meta, dan Cloudflare tanpa terowongan Carrier-Grade NAT (CGNAT) XL, memotong latensi hingga 10–15 ms.

> [!CAUTION]
> **Peringatan Kritis Hardware RF: Plat Tembaga / Modifikasi Termal Fisik**
> DILARANG menaruh plat tembaga atau pelat logam tebal di dalam *backcover* ponsel (misal sebagai heatsink/pendingin DIY). Tembaga adalah pemantul gelombang mikro terkuat (efek Sangkar Faraday / *Faraday Shielding*). Menaruh plat tembaga di belakang ponsel akan:
> 1. Memblokir antena sekunder (*Diversity RxD*) di frame atas, mematikan fungsi MIMO 2x2 dan Carrier Aggregation (4G+).
> 2. Menimbulkan kapasitansi liar (*Antenna Detuning*), merusak resonansi frekuensi 1800/2100 MHz.
> 3. Menghancurkan rasio sinyal terhadap gangguan (SNR) hingga titik kritis **`1 dB`** sehingga modem terpaksa turun ke modulasi terlambat (QPSK).
> 
> *Solusi Aman*: Gunakan lembaran grafit karbon (*graphite sheet / graphene sticker*) atau kipas pendingin eksternal (*phone cooler*) yang tidak menghalangi gelombang radio RF.
