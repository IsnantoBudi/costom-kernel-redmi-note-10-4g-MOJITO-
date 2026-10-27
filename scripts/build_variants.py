#!/usr/bin/env python3
"""
Custom Kernel Variant Generator & Packager
Target: Xiaomi Redmi Note 10 4G (mojito / sunny)
"""

import os
import re
import subprocess
import shutil
import sys

KERNEL_SRC = os.path.expanduser("~/kernel_workspace_mojito/kernel_src")
OUT_DIR = os.path.expanduser("~/kernel_workspace_mojito/out")
ANYKERNEL_DIR = os.path.expanduser("~/kernel_workspace_mojito/anykernel3")
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUTPUT_ZIP_DIR = os.path.join(ROOT_DIR, "output")

TOOLCHAIN_BIN = os.path.expanduser("~/kernel_workspace_mojito/toolchain/proton-clang/bin")
ENV = os.environ.copy()
ENV["PATH"] = f"{TOOLCHAIN_BIN}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:{ENV.get('PATH', '')}"
ENV["ARCH"] = "arm64"
ENV["SUBARCH"] = "arm64"
ENV["CC"] = "clang"
ENV["CLANG_TRIPLE"] = "aarch64-linux-gnu-"
ENV["CROSS_COMPILE"] = "aarch64-linux-gnu-"
ENV["CROSS_COMPILE_ARM32"] = "arm-linux-gnueabi-"

SM6150_DTSI = os.path.join(KERNEL_SRC, "arch/arm64/boot/dts/qcom/sm6150.dtsi")
SM6150_THERMAL_DTSI = os.path.join(KERNEL_SRC, "arch/arm64/boot/dts/qcom/sm6150-thermal.dtsi")
ANYKERNEL_SH_TEMPLATE = os.path.join(ROOT_DIR, "anykernel.sh")

LITTLE_FREQS = [
    300000, 576000, 748800, 1017600, 1209600, 1363200, 1516800, 1593600, 1708800, 1804800
]

BIG_FREQS = [
    300000, 652800, 768000, 979200, 1017600, 1209600, 1363200, 1516800, 1708800, 1900800, 2016000, 2112000, 2208000
]

VARIANTS = [
    {
        "name": "UltraCool",
        "zip_name": "AnyKernel3-Mojito-v2.0-UltraCool-Big1.9-Little1.5.zip",
        "string": "UltraCool Kernel v2.0 (Big 1.9GHz / Little 1.5GHz) - Redmi Note 10 4G",
        "max_big": 1900800,
        "max_little": 1516800,
        "cpu0_floor_state": 0,  # 1516800 is idx 0 in descending
        "cpu6_floor_state": 2,  # 1900800(0), 1708800(1), 1516800(2)
        "is_primary": True,
    },
    {
        "name": "Cool",
        "zip_name": "AnyKernel3-Mojito-v2.0-Cool-Big2.0-Little1.6.zip",
        "string": "Cool Balanced Kernel v2.0 (Big 2.0GHz / Little 1.6GHz) - Redmi Note 10 4G",
        "max_big": 2016000,
        "max_little": 1593600,
        "cpu0_floor_state": 1,  # 1593600(0), 1516800(1)
        "cpu6_floor_state": 3,  # 2016000(0), 1900800(1), 1708800(2), 1516800(3)
        "is_primary": False,
    },
    {
        "name": "Performance",
        "zip_name": "AnyKernel3-Mojito-v2.0-Performance-Big2.1-Little1.7.zip",
        "string": "Performance Kernel v2.0 (Big 2.1GHz / Little 1.7GHz) - Redmi Note 10 4G",
        "max_big": 2112000,
        "max_little": 1708800,
        "cpu0_floor_state": 2,  # 1708800(0), 1593600(1), 1516800(2)
        "cpu6_floor_state": 4,  # 2112000(0), 2016000(1), 1900800(2), 1708800(3), 1516800(4)
        "is_primary": False,
    },
    {
        "name": "StockMax",
        "zip_name": "AnyKernel3-Mojito-v2.0-StockMax-Big2.2-Little1.7.zip",
        "string": "StockMax Kernel v2.0 (Big 2.2GHz / Little 1.7GHz) - Redmi Note 10 4G",
        "max_big": 2208000,
        "max_little": 1708800,
        "cpu0_floor_state": 2,
        "cpu6_floor_state": 5,  # 2208000(0), 2112000(1), 2016000(2), 1900800(3), 1708800(4), 1516800(5)
        "is_primary": False,
    },
    {
        "name": "FullStock",
        "zip_name": "AnyKernel3-Mojito-v2.0-FullStock-Big2.2-Little1.8.zip",
        "string": "FullStock Kernel v2.0 (Big 2.2GHz / Little 1.8GHz) - Redmi Note 10 4G",
        "max_big": 2208000,
        "max_little": 1804800,
        "cpu0_floor_state": 3,  # 1804800(0), 1708800(1), 1593600(2), 1516800(3)
        "cpu6_floor_state": 5,
        "is_primary": False,
    },
]

def format_dts_table(freqs, max_freq):
    selected = [f for f in freqs if f <= max_freq]
    lines = []
    for f in selected:
        lines.append(f"\t<{f:>8}>,")
    # Replace last comma with semicolon
    lines[-1] = lines[-1].rstrip(",") + ";"
    return "\n".join(lines)

def update_dts(max_little, max_big, cpu0_floor, cpu6_floor):
    # 1. Update sm6150.dtsi clock_cpucc
    with open(SM6150_DTSI, "r") as f:
        content = f.read()

    little_block = format_dts_table(LITTLE_FREQS, max_little)
    big_block = format_dts_table(BIG_FREQS, max_big)

    new_clock_cpucc = (
        f"&clock_cpucc {{\n"
        f"\tqcom,cpufreq-table-0 =\n{little_block}\n\n"
        f"\tqcom,cpufreq-table-6 =\n{big_block}\n"
        f"}};"
    )

    pattern = r"&clock_cpucc\s*\{[^}]+\};"
    if not re.search(pattern, content):
        raise RuntimeError("Cannot find &clock_cpucc in sm6150.dtsi")

    content = re.sub(pattern, new_clock_cpucc, content)
    with open(SM6150_DTSI, "w") as f:
        f.write(content)

    # 2. Update sm6150-thermal.dtsi floor states
    with open(SM6150_THERMAL_DTSI, "r") as f:
        thermal_content = f.read()

    thermal_content = re.sub(
        r"cooling-device = <&CPU0 \d+ \d+>;",
        f"cooling-device = <&CPU0 {cpu0_floor} {cpu0_floor}>;",
        thermal_content
    )
    thermal_content = re.sub(
        r"cooling-device = <&CPU6 \d+ \d+>;",
        f"cooling-device = <&CPU6 {cpu6_floor} {cpu6_floor}>;",
        thermal_content
    )
    with open(SM6150_THERMAL_DTSI, "w") as f:
        f.write(thermal_content)

def build_dtbs():
    cmd = [
        "make", f"-j{os.cpu_count() or 8}",
        f"O={OUT_DIR}",
        "ARCH=arm64",
        "CC=clang",
        "CLANG_TRIPLE=aarch64-linux-gnu-",
        "CROSS_COMPILE=aarch64-linux-gnu-",
        "CROSS_COMPILE_ARM32=arm-linux-gnueabi-",
        "dtbs"
    ]
    res = subprocess.run(cmd, cwd=KERNEL_SRC, env=ENV, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if res.returncode != 0:
        print(res.stdout)
        raise RuntimeError("Gagal mengompilasi DTBs!")

def package_variant(var):
    zip_dest = os.path.join(OUTPUT_ZIP_DIR, var["zip_name"])
    staging = os.path.join(OUT_DIR, "ak3_stage_" + var["name"])
    if os.path.exists(staging):
        shutil.rmtree(staging)
    shutil.copytree(ANYKERNEL_DIR, staging)

    # Copy Image.gz
    kernel_img = os.path.join(OUT_DIR, "arch/arm64/boot/Image.gz")
    if not os.path.exists(kernel_img):
        raise RuntimeError(f"Kernel image {kernel_img} tidak ditemukan!")
    shutil.copyfile(kernel_img, os.path.join(staging, "Image.gz"))

    # Copy dtb
    dtb_src = os.path.join(OUT_DIR, "arch/arm64/boot/dts/qcom/sm6150.dtb")
    if not os.path.exists(dtb_src):
        raise RuntimeError(f"DTB {dtb_src} tidak ditemukan!")
    shutil.copyfile(dtb_src, os.path.join(staging, "dtb"))

    # Generate custom anykernel.sh with variant string
    with open(ANYKERNEL_SH_TEMPLATE, "r") as f:
        ak_sh = f.read()

    ak_sh = re.sub(
        r"kernel\.string=.*",
        f"kernel.string={var['string']}",
        ak_sh
    )
    with open(os.path.join(staging, "anykernel.sh"), "w") as f:
        f.write(ak_sh)

    # Remove any unwanted files
    for ign in [".git", "README.md"]:
        p = os.path.join(staging, ign)
        if os.path.isdir(p):
            shutil.rmtree(p)
        elif os.path.isfile(p):
            os.remove(p)

    # Create zip
    if os.path.exists(zip_dest):
        os.remove(zip_dest)

    cmd = ["zip", "-r9", zip_dest, "."]
    res = subprocess.run(cmd, cwd=staging, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if res.returncode != 0:
        print(res.stdout)
        raise RuntimeError(f"Gagal membuat zip {zip_dest}")

    if var.get("is_primary"):
        latest1 = os.path.join(OUTPUT_ZIP_DIR, "AnyKernel3-Mojito-v2.0-UltraCool-latest.zip")
        shutil.copyfile(zip_dest, latest1)

    sz = os.path.getsize(zip_dest) / (1024 * 1024)
    print(f"  [OK] {var['zip_name']} ({sz:.2f} MB)")

def main():
    print("==========================================================")
    print(" 🚀 MEMULAI PEMBUATAN 5 VARIAN KERNEL REDMI NOTE 10 4G")
    print("==========================================================")
    os.makedirs(OUTPUT_ZIP_DIR, exist_ok=True)

    for i, var in enumerate(VARIANTS, 1):
        print(f"\n[{i}/{len(VARIANTS)}] Membangun Varian '{var['name']}':")
        print(f"  - Big Core   : {var['max_big'] / 1000000:.1f} GHz ({var['max_big']} kHz)")
        print(f"  - Little Core: {var['max_little'] / 1000000:.1f} GHz ({var['max_little']} kHz)")
        print(f"  - Modifikasi DTS...")
        update_dts(var["max_little"], var["max_big"], var["cpu0_floor_state"], var["cpu6_floor_state"])
        print(f"  - Kompilasi DTBs...")
        build_dtbs()
        print(f"  - Packaging AnyKernel3...")
        package_variant(var)

    # Kembalikan DTS ke kondisi UltraCool (1.9 GHz / 1.5 GHz) sebagai baseline
    update_dts(1516800, 1900800, 0, 2)
    build_dtbs()

    print("\n==========================================================")
    print(" ✅ SELURUH 5 VARIAN BERHASIL DIBUAT DENGAN LENGKAP!")
    print(f" Lokasi Output: {OUTPUT_ZIP_DIR}")
    print("==========================================================")

if __name__ == "__main__":
    main()
