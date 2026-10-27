### AnyKernel3 Packaging Config for Redmi Note 10 4G (mojito/sunny)
properties() { '
kernel.string=UltraCool Kernel v2.0 for Redmi Note 10 4G (MIUI 14)
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
# V2.0 Hotspot Tethering Bypass & TCP Network Tuning (Auto-apply upon sys.boot_completed)
if [ -f init.rc ]; then
    insert_line init.rc "on property:sys.boot_completed=1" after "on property:sys.boot_completed=1" "    exec -- /system/bin/sh -c 'iptables -t mangle -A POSTROUTING -j TTL --ttl-set 64 2>/dev/null; ip6tables -t mangle -A POSTROUTING -j HL --hl-set 64 2>/dev/null; echo 3 > /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null; echo \"262144 1048576 4194304\" > /proc/sys/net/ipv4/tcp_wmem 2>/dev/null; echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null'";
fi;

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
