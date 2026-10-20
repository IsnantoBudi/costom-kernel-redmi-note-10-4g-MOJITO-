@echo off
title PULIHKAN REDMI NOTE 10 KE KERNEL RESMI (STOCK BOOT)
color 0A
echo ==========================================================
echo    PEMULIHAN KERNEL RESMI REDMI NOTE 10 4G (MOJITO)
echo    Target: MIUI 14 Global 14.0.6.0 (SKGEUXM - Android 12)
echo ==========================================================
echo.
echo 1. Pastikan HP dalam mode FASTBOOT (Layar hitam tulisan FASTBOOT oranye).
echo    (Caranya: Tekan dan tahan tombol POWER + VOLUME BAWAH)
echo 2. Hubungkan HP ke Laptop/PC dengan kabel data USB.
echo.
echo Menunggu HP terdeteksi di Fastboot...
fastboot wait-for-device
echo.
echo >> HP Terdeteksi! Memasang kernel stock resmi MIUI 14...
fastboot flash boot "%~dp0output\stock_boot_MIUI14_V14.0.6.0.SKGEUXM.img"
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Gagal melakukan flash boot image. Periksa koneksi kabel USB.
    pause
    exit /b %errorlevel%
)
echo.
echo >> Sukses terpasang! Me-restart HP ke sistem MIUI 14...
fastboot reboot
echo.
echo ==========================================================
echo  SELESAI! HP Anda sekarang sedang booting normal ke MIUI.
echo ==========================================================
pause
