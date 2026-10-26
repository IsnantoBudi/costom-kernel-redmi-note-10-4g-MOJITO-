@echo off
chcp 65001 >nul
title Kirim Zip Kernel ke Redmi Note 10 4G (mojito)

echo ==========================================================
echo  PENGIRIM KERNEL OTOMATIS KE HP (VIA ADB)
echo ==========================================================
echo Menunggu HP terhubung dengan USB Debugging aktif...

adb wait-for-device

echo [OK] HP Terdeteksi!
echo Mengirim file kernel terbaru ke /sdcard/ ...
adb push "output\AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-latest.zip" /sdcard/
adb push "output\AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-latest.zip" /sdcard/Download/

echo ==========================================================
echo  SELESAI! File tersimpan di /sdcard/
echo  File: AnyKernel3-Mojito-MIUI14-UltraCool-FastCharge-latest.zip
echo ==========================================================
pause
