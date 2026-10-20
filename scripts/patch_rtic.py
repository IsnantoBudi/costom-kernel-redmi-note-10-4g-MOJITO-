#!/usr/bin/env python3
import sys

path = "/home/zygarde/kernel_workspace_mojito/kernel_src/include/linux/init.h"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

target = '#define __rticdata  __attribute__((section(".bss.rtic")))'
replacement = '#define __rticdata'

if target in content:
    content = content.replace(target, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("SUCCESS: __rticdata patched in init.h")
else:
    print("TARGET NOT FOUND or ALREADY PATCHED")
