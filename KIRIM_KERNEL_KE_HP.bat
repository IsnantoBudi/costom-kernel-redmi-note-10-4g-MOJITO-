@echo off
chcp 65001 >nul
title Kirim Zip Custom Kernel ke Redmi Note 10 4G (mojito)

echo ==========================================================
echo  PILIH VARIAN KERNEL REDMI NOTE 10 4G UNTUK DIKIRIM KE HP
echo ==========================================================
echo  [1] UltraCool   : Big 1.9 GHz / Little 1.5 GHz (Paling Adem & Baterai Awet)
echo  [2] Cool        : Big 2.0 GHz / Little 1.6 GHz (Seimbang / Sweet Spot Harian)
echo  [3] Performance : Big 2.1 GHz / Little 1.7 GHz (Gaming Responsif)
echo  [4] StockMax    : Big 2.2 GHz / Little 1.7 GHz (Performa Maksimal Big Core)
echo  [5] FullStock   : Big 2.2 GHz / Little 1.8 GHz (100%% Frekuensi Pabrik)
echo  [6] Kirim SEMUA Varian ke HP
echo ==========================================================
set /p PILIHAN="Masukkan pilihan [1-6] (Default: 1): "

if "%PILIHAN%"=="" set PILIHAN=1

echo.
echo Menunggu HP terhubung dengan USB Debugging aktif...
adb wait-for-device
echo [OK] HP Terdeteksi!
echo.

if "%PILIHAN%"=="1" (
    set TARGET_FILE=output\AnyKernel3-Mojito-v2.0-UltraCool-Big1.9-Little1.5.zip
    if not exist "%TARGET_FILE%" set TARGET_FILE=output\AnyKernel3-Mojito-UltraCool-Big1.9-Little1.5.zip
    goto PUSH_SINGLE
)
if "%PILIHAN%"=="2" (
    set TARGET_FILE=output\AnyKernel3-Mojito-v2.0-Cool-Big2.0-Little1.6.zip
    if not exist "%TARGET_FILE%" set TARGET_FILE=output\AnyKernel3-Mojito-Cool-Big2.0-Little1.6.zip
    goto PUSH_SINGLE
)
if "%PILIHAN%"=="3" (
    set TARGET_FILE=output\AnyKernel3-Mojito-v2.0-Performance-Big2.1-Little1.7.zip
    if not exist "%TARGET_FILE%" set TARGET_FILE=output\AnyKernel3-Mojito-Performance-Big2.1-Little1.7.zip
    goto PUSH_SINGLE
)
if "%PILIHAN%"=="4" (
    set TARGET_FILE=output\AnyKernel3-Mojito-v2.0-StockMax-Big2.2-Little1.7.zip
    if not exist "%TARGET_FILE%" set TARGET_FILE=output\AnyKernel3-Mojito-StockMax-Big2.2-Little1.7.zip
    goto PUSH_SINGLE
)
if "%PILIHAN%"=="5" (
    set TARGET_FILE=output\AnyKernel3-Mojito-v2.0-FullStock-Big2.2-Little1.8.zip
    if not exist "%TARGET_FILE%" set TARGET_FILE=output\AnyKernel3-Mojito-FullStock-Big2.2-Little1.8.zip
    goto PUSH_SINGLE
)
if "%PILIHAN%"=="6" (
    goto PUSH_ALL
)

:PUSH_SINGLE
echo Mengirim %TARGET_FILE% ke /sdcard/ dan /sdcard/Download/ ...
adb push "%TARGET_FILE%" /sdcard/
adb push "%TARGET_FILE%" /sdcard/Download/
echo.
echo ==========================================================
echo  ✅ SELESAI! File tersimpan di /sdcard/Download/
echo  File siap di-flash via TWRP / OrangeFox Recovery!
echo ==========================================================
pause
exit /b 0

:PUSH_ALL
echo Mengirim SEMUA varian kernel ke /sdcard/Download/ ...
for %%f in (output\AnyKernel3-Mojito-*.zip) do (
    echo Mengirim %%f ...
    adb push "%%f" /sdcard/Download/
)
echo.
echo ==========================================================
echo  ✅ SELESAI! Semua 5 varian tersimpan di /sdcard/Download/
echo  File siap di-flash via TWRP / OrangeFox Recovery!
echo ==========================================================
pause
exit /b 0
