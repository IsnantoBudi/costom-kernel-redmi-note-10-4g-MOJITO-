### AnyKernel3 Packaging Config for Redmi Note 10 4G (mojito/sunny)
properties() { '
kernel.string=Clean & Cool Kernel for Redmi Note 10 4G (MIUI 14)
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
. /tmp/anykernel/tools/ak3-core.sh;
split_boot;
flash_boot;
if [ -f /tmp/anykernel/dtbo.img ]; then
    flash_dtbo;
fi
