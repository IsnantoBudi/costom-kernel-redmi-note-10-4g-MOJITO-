#!/usr/bin/env python3
"""
Surgical V2 Code Applicator for Redmi Note 10 4G (mojito)
Applies Dynamic Fsync, Simple LMK, and In-Kernel Tethering Bypass Clamp.
"""

import os
import sys

KERNEL_SRC = os.path.expanduser("~/kernel_workspace_mojito/kernel_src")
if not os.path.isdir(KERNEL_SRC):
    # Fallback to local if running in windows or alternate path
    KERNEL_SRC = "/mnt/d/Project/kernel redmi note 10/kernel_src"

print(f">> Targeting KERNEL_SRC: {KERNEL_SRC}")

# 1. Write drivers/misc/dyn_fsync.c
dyn_fsync_c = os.path.join(KERNEL_SRC, "drivers/misc/dyn_fsync.c")
dyn_fsync_code = """/*
 * Dynamic Fsync Driver
 * Target: Redmi Note 10 4G (mojito / sunny)
 * Based on Faux123 / Sultan implementation
 */

#include <linux/module.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/notifier.h>
#include <linux/fb.h>

bool dyn_fsync_active = true;
EXPORT_SYMBOL(dyn_fsync_active);

static bool dyn_fsync_enabled = true;

static ssize_t dyn_fsync_active_show(struct kobject *kobj,
				     struct kobj_attribute *attr, char *buf)
{
	return sprintf(buf, "%u\\n", dyn_fsync_active ? 1 : 0);
}

static ssize_t dyn_fsync_active_store(struct kobject *kobj,
				      struct kobj_attribute *attr,
				      const char *buf, size_t count)
{
	unsigned int val;

	if (kstrtouint(buf, 10, &val))
		return -EINVAL;

	dyn_fsync_enabled = !!val;
	dyn_fsync_active = dyn_fsync_enabled;
	return count;
}

static struct kobj_attribute dyn_fsync_attribute =
	__ATTR(Dyn_fsync_active, 0644, dyn_fsync_active_show, dyn_fsync_active_store);

static struct attribute *dyn_fsync_attrs[] = {
	&dyn_fsync_attribute.attr,
	NULL,
};

static struct attribute_group dyn_fsync_attr_group = {
	.attrs = dyn_fsync_attrs,
};

static int dyn_fsync_fb_notifier_callback(struct notifier_block *self,
					  unsigned long event, void *data)
{
	struct fb_event *evdata = data;
	int *blank;

	if (event != FB_EVENT_BLANK)
		return 0;

	blank = evdata->data;
	if (*blank == FB_BLANK_UNBLANK) {
		if (dyn_fsync_enabled)
			dyn_fsync_active = true;
	} else if (*blank == FB_BLANK_POWERDOWN) {
		dyn_fsync_active = false;
		emergency_sync();
	}

	return 0;
}

static struct notifier_block dyn_fsync_fb_notif = {
	.notifier_call = dyn_fsync_fb_notifier_callback,
};

static struct kobject *dyn_fsync_kobj;

static int __init dyn_fsync_init(void)
{
	int ret;

	dyn_fsync_kobj = kobject_create_and_add("dyn_fsync", kernel_kobj);
	if (!dyn_fsync_kobj)
		return -ENOMEM;

	ret = sysfs_create_group(dyn_fsync_kobj, &dyn_fsync_attr_group);
	if (ret) {
		kobject_put(dyn_fsync_kobj);
		return ret;
	}

	fb_register_client(&dyn_fsync_fb_notif);
	pr_info("Dynamic Fsync: initialized successfully (active)\\n");
	return 0;
}
core_initcall(dyn_fsync_init);
MODULE_LICENSE("GPL v2");
"""

with open(dyn_fsync_c, "w") as f:
    f.write(dyn_fsync_code)
print("  [OK] drivers/misc/dyn_fsync.c")

# 2. Update drivers/misc/Makefile
misc_make = os.path.join(KERNEL_SRC, "drivers/misc/Makefile")
with open(misc_make, "r") as f:
    content = f.read()
if "dyn_fsync.o" not in content:
    content += "\nobj-$(CONFIG_DYNAMIC_FSYNC) += dyn_fsync.o\n"
    with open(misc_make, "w") as f:
        f.write(content)
print("  [OK] drivers/misc/Makefile")

# 3. Update drivers/misc/Kconfig
misc_kconfig = os.path.join(KERNEL_SRC, "drivers/misc/Kconfig")
with open(misc_kconfig, "r") as f:
    content = f.read()
if "DYNAMIC_FSYNC" not in content:
    content += """
config DYNAMIC_FSYNC
	bool "Dynamic Fsync"
	default y
	help
	  Dynamic Fsync disables synchronous fsync calls when screen is ON
	  to eliminate micro-stutter and I/O latency. When screen turns OFF,
	  it flushes all pending dirty buffers safely to storage.
"""
    with open(misc_kconfig, "w") as f:
        f.write(content)
print("  [OK] drivers/misc/Kconfig")

# 4. Update fs/sync.c
fs_sync = os.path.join(KERNEL_SRC, "fs/sync.c")
with open(fs_sync, "r") as f:
    content = f.read()

if "CONFIG_DYNAMIC_FSYNC" not in content:
    header_hook = """#include "internal.h"

#ifdef CONFIG_DYNAMIC_FSYNC
extern bool dyn_fsync_active;
#endif
"""
    content = content.replace('#include "internal.h"', header_hook, 1)

    target_code = """int vfs_fsync_range(struct file *file, loff_t start, loff_t end, int datasync)
{
	struct inode *inode = file->f_mapping->host;

	if (!file->f_op->fsync)
		return -EINVAL;"""

    replacement_code = """int vfs_fsync_range(struct file *file, loff_t start, loff_t end, int datasync)
{
	struct inode *inode = file->f_mapping->host;

	if (!file->f_op->fsync)
		return -EINVAL;
#ifdef CONFIG_DYNAMIC_FSYNC
	if (dyn_fsync_active)
		return 0;
#endif"""

    if target_code in content:
        content = content.replace(target_code, replacement_code, 1)
        with open(fs_sync, "w") as f:
            f.write(content)
        print("  [OK] fs/sync.c")
    else:
        print("  [WARN] target_code not matched in fs/sync.c")
else:
    print("  [SKIP] fs/sync.c already modified")

# 5. Update drivers/staging/android/Kconfig
android_kconfig = os.path.join(KERNEL_SRC, "drivers/staging/android/Kconfig")
with open(android_kconfig, "r") as f:
    content = f.read()

if "ANDROID_SIMPLE_LMK" not in content:
    target_kconfig = """select HAVE_LOW_MEMORY_KILLER
	---help---
	  Registers processes to be killed when low memory conditions, this is useful
	  as there is no particular swap space on android."""

    replacement_kconfig = target_kconfig + """

config ANDROID_SIMPLE_LMK
	bool "Android Simple Low Memory Killer (Sultan LMK)"
	depends on ANDROID_LOW_MEMORY_KILLER
	default y
	help
	  Lightweight low memory killer tailored for 4GB RAM devices."""

    if target_kconfig in content:
        content = content.replace(target_kconfig, replacement_kconfig, 1)
        with open(android_kconfig, "w") as f:
            f.write(content)
        print("  [OK] drivers/staging/android/Kconfig")
    else:
        print("  [WARN] target_kconfig not matched in drivers/staging/android/Kconfig")
else:
    print("  [SKIP] drivers/staging/android/Kconfig already modified")

# 6. Update drivers/staging/android/lowmemorykiller.c
lmk_c = os.path.join(KERNEL_SRC, "drivers/staging/android/lowmemorykiller.c")
with open(lmk_c, "r") as f:
    content = f.read()

if "SIMPLE_LMK_WATERMARK" not in content:
    target_include = '#include <linux/vmpressure.h>'
    replacement_include = """#include <linux/vmpressure.h>

#ifdef CONFIG_ANDROID_SIMPLE_LMK
/* Safe watermark for 4GB RAM Snapdragon 678: ~400MB threshold (100000 pages) */
#define SIMPLE_LMK_WATERMARK 100000
#endif"""

    content = content.replace(target_include, replacement_include, 1)

    target_scan = """static unsigned long lowmem_scan(struct shrinker *s, struct shrink_control *sc)
{
	struct task_struct *tsk;
	struct task_struct *selected = NULL;
	unsigned long rem = 0;
	int tasksize;
	int i;
	int ret = 0;
	short min_score_adj = OOM_SCORE_ADJ_MAX + 1;
	int minfree = 0;
	int scale_percent;
	int selected_tasksize = 0;
	short selected_oom_score_adj;
	int array_size = ARRAY_SIZE(lowmem_adj);
	int other_free;
	int other_file;
	bool lock_required = true;"""

    replacement_scan = """static unsigned long lowmem_scan(struct shrinker *s, struct shrink_control *sc)
{
	struct task_struct *tsk;
	struct task_struct *selected = NULL;
	unsigned long rem = 0;
	int tasksize;
	int i;
	int ret = 0;
	short min_score_adj = OOM_SCORE_ADJ_MAX + 1;
	int minfree = 0;
	int scale_percent;
	int selected_tasksize = 0;
	short selected_oom_score_adj;
	int array_size = ARRAY_SIZE(lowmem_adj);
	int other_free;
	int other_file;
	bool lock_required = true;

#ifdef CONFIG_ANDROID_SIMPLE_LMK
	other_free = global_zone_page_state(NR_FREE_PAGES);
	other_file = global_node_page_state(NR_FILE_PAGES) -
		global_node_page_state(NR_SHMEM) -
		total_swapcache_pages();

	if ((other_free + other_file) > SIMPLE_LMK_WATERMARK)
		return 0;

	rcu_read_lock();
	for_each_process(tsk) {
		struct task_struct *p;
		short oom_score_adj;

		if (tsk->flags & PF_KTHREAD)
			continue;

		p = find_lock_task_mm(tsk);
		if (!p)
			continue;

		oom_score_adj = p->signal->oom_score_adj;
		if (oom_score_adj < 200) {
			task_unlock(p);
			continue;
		}

		tasksize = get_mm_rss(p->mm);
		task_unlock(p);

		if (tasksize > selected_tasksize) {
			selected_tasksize = tasksize;
			selected = p;
		}
	}

	if (selected) {
		lowmem_print(1, "Simple LMK: Killing '%s' (pid %d), adj %d, size %d to free RAM\\n",
			     selected->comm, selected->pid, selected->signal->oom_score_adj, selected_tasksize);
		send_sig(SIGKILL, selected, 0);
		rem = selected_tasksize;
	}
	rcu_read_unlock();
	return rem;
#endif"""

    if target_scan in content:
        content = content.replace(target_scan, replacement_scan, 1)
        with open(lmk_c, "w") as f:
            f.write(content)
        print("  [OK] drivers/staging/android/lowmemorykiller.c")
    else:
        print("  [WARN] target_scan not matched in lowmemorykiller.c")
else:
    print("  [SKIP] lowmemorykiller.c already modified")

# 7. Update net/ipv4/ip_forward.c
ip_fwd = os.path.join(KERNEL_SRC, "net/ipv4/ip_forward.c")
with open(ip_fwd, "r") as f:
    content = f.read()

if "CONFIG_IP_NF_TARGET_TTL" not in content:
    target_ttl = "\tip_decrease_ttl(iph);"
    replacement_ttl = """#ifdef CONFIG_IP_NF_TARGET_TTL
	/* In-kernel tethering bypass: keep TTL at 64 for hotspot clients */
	if (iph->ttl < 64)
		iph->ttl = 64;
	else
		ip_decrease_ttl(iph);
#else
	ip_decrease_ttl(iph);
#endif"""

    if target_ttl in content:
        content = content.replace(target_ttl, replacement_ttl, 1)
        with open(ip_fwd, "w") as f:
            f.write(content)
        print("  [OK] net/ipv4/ip_forward.c")
    else:
        print("  [WARN] target_ttl not matched in net/ipv4/ip_forward.c")
else:
    print("  [SKIP] net/ipv4/ip_forward.c already modified")

# 8. Update net/ipv6/ip6_output.c
ip6_out = os.path.join(KERNEL_SRC, "net/ipv6/ip6_output.c")
with open(ip6_out, "r") as f:
    content = f.read()

if "CONFIG_IP6_NF_TARGET_HL" not in content:
    target_hl = "\thdr->hop_limit--;"
    replacement_hl = """#ifdef CONFIG_IP6_NF_TARGET_HL
	/* In-kernel tethering bypass: keep Hop Limit at 64 for IPv6 */
	if (hdr->hop_limit < 64)
		hdr->hop_limit = 64;
	else
		hdr->hop_limit--;
#else
	hdr->hop_limit--;
#endif"""

    if target_hl in content:
        content = content.replace(target_hl, replacement_hl, 1)
        with open(ip6_out, "w") as f:
            f.write(content)
        print("  [OK] net/ipv6/ip6_output.c")
    else:
        print("  [WARN] target_hl not matched in net/ipv6/ip6_output.c")
else:
    print("  [SKIP] net/ipv6/ip6_output.c already modified")

print(">> All V2 code changes processed successfully.")
