# 🤖 AGENTS.md — Guardrails & Context Rules for AI Assistants

Dokumen ini berisi aturan permanen bagi Coding Assistant (AI / LLM) saat bekerja di repositori Custom Kernel Redmi Note 10 4G (`mojito` / `sunny`).

---

## 📱 1. Konteks Perangkat & Arsitektur Kernel
- **Perangkat**: Xiaomi Redmi Note 10 4G (Model: `M2101K7AG` / Codename: `mojito` / `sunny`).
- **SoC**: Qualcomm Snapdragon 678 (SM6150) — 2x Kryo 460 Gold + 6x Kryo 460 Silver.
- **Sistem Operasi**: MIUI 14 Global (Android 12, Boot Header v3, Kernel 4.14 CAF base).
- **Skema Partisi**: Partisi Virtual A/B (`boot_a` / `boot_b`, `vendor_boot_a` / `vendor_boot_b`, `dtbo_a` / `dtbo_b`).
  - *Catatan Kritis*: Tidak ada partisi `recovery` terpisah. Masuk recovery lewat fastboot wajib menggunakan `fastboot boot recovery.img`.
  - *Boot Header v3*: Partisi `boot` hanya memuat biner kernel (`Image.gz`) dan ramdisk. Tabel frekuensi CPU (OPP table) dan driver charging dimuat dari berkas **`dtb` di partisi `vendor_boot`**.

---

## 🛑 2. Aturan Baku AnyKernel3 Packaging (Anti-Regression)

### A. Case-Sensitivity Wajib (HURUF BESAR / KAPITAL)
Shell Android Recovery (`ash` di TWRP/OrangeFox) bersifat **case-sensitive**:
```sh
# WAJIB: Definisikan huruf kapital (dan sertakan fallback huruf kecil)
BLOCK=/dev/block/bootdevice/by-name/boot;
block=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=auto;
is_slot_device=auto;
RAMDISK_COMPRESSION=auto;
ramdisk_compression=auto;
PATCH_VBMETA_FLAG=auto;
patch_vbmeta_flag=auto;
```
> [!CAUTION]
> **DILARANG KERAS** hanya menggunakan huruf kecil (`block=boot;` atau `is_slot_device=auto;`).
> Script inti `ak3-core.sh` memeriksa variabel `$BLOCK` dan `$IS_SLOT_DEVICE`. Jika hanya huruf kecil, variabel bernilai kosong sehingga instalasi gagal total dengan error:
> `Unable to determine  partition. Aborting... (Error 1)`

### B. Gunakan Jalur Blok Absolut
Gunakan selalu `/dev/block/bootdevice/by-name/boot`. Jangan mengandalkan nama pendek `boot` agar pendeteksian partisi slot A/B langsung terkunci tanpa gagal pada recovery unofficial.

### C. Dual-Flash Partisi `boot` dan `vendor_boot`
Pada Android 12 (Boot Header v3), kernel biner (`Image.gz`) berada di partisi `boot`, sedangkan Device Tree Blob (`dtb` / tabel OPP frekuensi) berada di partisi `vendor_boot`.
Konfigurasi baku `anykernel.sh` wajib memproses kedua partisi secara berurutan:
```sh
## AnyKernel boot install
dump_boot;
write_boot;
## end boot install

# AnyKernel vendor_boot install (Device Tree & OPP Freq Capping)
BLOCK=/dev/block/bootdevice/by-name/vendor_boot;
block=/dev/block/bootdevice/by-name/vendor_boot;
IS_SLOT_DEVICE=auto;
is_slot_device=auto;

reset_ak;

dump_boot;
write_boot;
## end vendor_boot install
```
> [!NOTE]
> Rutinitas di atas memastikan AnyKernel3 menimpa `Image.gz` pada partisi `boot` dan `dtb` pada partisi `vendor_boot` secara atomik dalam 1x flash di TWRP/OrangeFox.

### D. Verifikasi Tanda Tangan TWRP
Database kunci TWRP pada ROM MIUI (`/system/etc/security/otacerts.zip`) hanya berisi sertifikat publik Xiaomi Corporation. Pengguna **harus meng-uncheck** opsi *"Zip signature verification"* di menu Install TWRP sebelum menggeser slider konfirmasi flash.

### E. Qualcomm OSM Boost Frequency Resurrection Bypass (SM6150 / SM6150P)
Driver clock Qualcomm Operating State Manager (`drivers/clk/qcom/clk-cpu-osm.c`) memiliki logika internal di mana jika frekuensi puncak dihapus dari Device Tree, driver otomatis membangkitkan frekuensi tersebut sebagai frekuensi Turbo Boost (`CPUFREQ_BOOST_FREQ`).
Agar capping frekuensi (1.516 GHz Little / 1.900 GHz Big) benar-benar terkunci pada hardware dan terbaca di `cpuinfo_max_freq`:
1. Blok pembentukan boost frequency pada `clk-cpu-osm.c` dinonaktifkan (`break;` langsung saat mencapai akhir tabel OSM).
2. Properti driver diatur `.boost_enabled = false;`.

---

## 🧹 3. Standar Kebersihan & Verifikasi
- Sebelum merilis zip baru, selalu uji isi biner menggunakan:
  ```powershell
  tar -tf output/<nama_zip>.zip
  ```
  Pastikan `Image.gz`, `dtb`, `anykernel.sh`, dan `tools/ak3-core.sh` berada di root direktori zip.
- Pastikan berkas temporary di root direktori selalu dibersihkan (zero untracked trash).
