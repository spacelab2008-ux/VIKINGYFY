#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY
#
# 目标平台内核/镜像调整（已移除 eBPF 注入：本仓库不再编译 dae/daed）

#Link NN6000 的 factory.bin 内核槽大小
#本机已刷 12MB 内核分区（rootfs 起始偏移 12MB），故由上游默认的 6144k 改为 12288k。
#注意：该值同时决定 rootfs 在镜像内的偏移，必须与设备上 U-Boot 的读取偏移一致，
#否则镜像能编出来但刷进去不启动。不是 nn6000 的设备不要跟着改。
NN6000_KERNEL_SIZE="12288k"

#调整 nn6000 的内核槽：只改 link_nn6000-common 这一段，
#jdcloud re-cs-02/cs-07/re-ss-01 等同为 6144k 的设备保持原样
function patch_kernel_size() {
	local IMG_MK="./target/linux/qualcommax/image/ipq60xx.mk"
	[ -f "$IMG_MK" ] || return 0

	if ! grep -q "define Device/link_nn6000-common" "$IMG_MK"; then
		echo "no link_nn6000-common in $IMG_MK, skip!"
		return 0
	fi

	if grep -A8 "define Device/link_nn6000-common" "$IMG_MK" | grep -q "KERNEL_SIZE := ${NN6000_KERNEL_SIZE}"; then
		echo "nn6000 KERNEL_SIZE already ${NN6000_KERNEL_SIZE}, skip!"
		return 0
	fi

	#用 awk 限定在 link_nn6000-common 这一段内替换，避免误改其他设备的 6144k
	awk -v ks="$NN6000_KERNEL_SIZE" '
		/^define Device\/link_nn6000-common/ { inblk = 1 }
		inblk && /KERNEL_SIZE := 6144k/ { sub(/6144k/, ks); inblk = 0 }
		/^endef/ { inblk = 0 }
		{ print }
	' "$IMG_MK" > "$IMG_MK.tmp" && mv "$IMG_MK.tmp" "$IMG_MK"
	echo "nn6000 KERNEL_SIZE -> $(grep -A8 'define Device/link_nn6000-common' "$IMG_MK" | sed -n 's/.*KERNEL_SIZE := //p')"
}

#把 sch_fq（Fair Queue pacing）编进内核，作为 BBR 的配套调度器。
#背景：源码 feeds 里没有 kmod-sched-fq 这个包（只有 sched-fq-pie / sched-core），
#在 GENERAL.txt 写 CONFIG_PACKAGE_kmod-sched-fq=y 会被 make defconfig 静默丢弃。
#内核层符号 CONFIG_NET_SCH_FQ 在 generic/config-6.18 里默认 "is not set"，
#这里在子目标 config-default（合并顺序最后、优先级最高）注入为 =y，编进内核 built-in。
#不设置 net.core.default_qdisc=fq：本固件带 NSS 硬件 qdisc 加速，全局改默认 qdisc
#有冲突风险；且 BBR 自 kernel 4.13 起有 TCP internal pacing 兜底，不强制依赖 fq qdisc。
function patch_sched_fq() {
	local KCFG="./target/linux/qualcommax/ipq60xx/config-default"
	[ -f "$KCFG" ] || { echo "$KCFG not found, skip sch_fq injection!"; return 0; }

	if grep -q '^CONFIG_NET_SCH_FQ=y' "$KCFG"; then
		echo "sch_fq already enabled in $KCFG, skip!"
		return 0
	fi

	#删除 generic 合并可能带来的 "is not set" 行，避免同文件内冲突，再追加 =y
	sed -i '/^# CONFIG_NET_SCH_FQ is not set$/d' "$KCFG"
	printf '\n# FQ pacing scheduler (BBR companion)\nCONFIG_NET_SCH_FQ=y\n' >> "$KCFG"
	echo "sch_fq injected -> $KCFG"
}

#统一入口：镜像布局调整 + 内核调度器注入（eBPF 注入已随 dae/daed 移除）
function apply_kernel_tweaks() {
	patch_kernel_size
	patch_sched_fq
}
