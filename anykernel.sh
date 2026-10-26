### AnyKernel3 Packaging Config for Redmi Note 10 4G (mojito/sunny)
properties() { '
kernel.string=UltraCool & FastCharge Kernel for Redmi Note 10 4G (MIUI 14)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=mojito
device.name2=sunny
device.name3=M2101K7AG
device.name4=M2101K7AI
supported.versions=11-13
supported.patchlevels=
'; }

# shell variables
# CATATAN KRITIS: Variabel shell di Android recovery/ash bersifat case-sensitive!
# Wajib gunakan HURUF KAPITAL (BLOCK, IS_SLOT_DEVICE) dan definisikan jalur blok absolut
# untuk mencegah error "Unable to determine partition. Aborting...".
BLOCK=/dev/block/bootdevice/by-name/boot;
block=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=auto;
is_slot_device=auto;
RAMDISK_COMPRESSION=auto;
ramdisk_compression=auto;
PATCH_VBMETA_FLAG=auto;
patch_vbmeta_flag=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel boot install
dump_boot;

# begin ramdisk changes

write_boot;
## end boot install

# AnyKernel vendor_boot install (Device Tree & OPP Freq Capping)
BLOCK=/dev/block/bootdevice/by-name/vendor_boot;
block=/dev/block/bootdevice/by-name/vendor_boot;
IS_SLOT_DEVICE=auto;
is_slot_device=auto;

reset_ak;

dump_boot;

# begin ramdisk changes

write_boot;
## end vendor_boot install
