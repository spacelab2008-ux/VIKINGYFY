#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY
#
# eBPF 支持注入（移植自 davidtall/DaeWRT-CI，适配本仓库多目标架构）
# 为 dae/daed 内核级透明代理提供内核依赖：
#   BPF syscall/JIT + BTF(CO-RE) + cgroup BPF + XDP sockets

#内核底层选项：直接追加到 target/linux/<目标>/<子目标>/config-default
function cat_kernel_config() {
	if [ -f "$1" ]; then
		cat >> "$1" <<EOF

#eBPF support (dae/daed)
CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_BPF_JIT=y
CONFIG_CGROUPS=y
CONFIG_KPROBES=y
CONFIG_NET_INGRESS=y
CONFIG_NET_EGRESS=y
CONFIG_NET_SCH_INGRESS=m
CONFIG_NET_CLS_BPF=m
CONFIG_NET_CLS_ACT=y
CONFIG_BPF_STREAM_PARSER=y
CONFIG_DEBUG_INFO=y
# CONFIG_DEBUG_INFO_REDUCED is not set
CONFIG_DEBUG_INFO_BTF=y
CONFIG_KPROBE_EVENTS=y
CONFIG_BPF_EVENTS=y
CONFIG_NET_SCH_BPF=y
CONFIG_SCHED_CLASS_EXT=y
CONFIG_PROBE_EVENTS_BTF_ARGS=y
EOF
		#ARM64 专属选项（x86 等目标跳过）
		if [[ "${WRT_TARGET,,}" != "x86" ]]; then
			cat >> "$1" <<EOF
CONFIG_ARM64_CONTPTE=y
CONFIG_ARM64_BRBE=y
EOF
		fi
		echo "cat_kernel_config to $1 done"
	fi
}

#OpenWrt 层内核选项：追加到顶层 .config，make defconfig 时回传内核
function cat_ebpf_config() {
	cat >> "$1" <<EOF

#eBPF support (dae/daed)
CONFIG_KERNEL_DEBUG_INFO=y
CONFIG_KERNEL_DEBUG_INFO_REDUCED=n
CONFIG_KERNEL_DEBUG_INFO_BTF=y
CONFIG_KERNEL_CGROUPS=y
CONFIG_KERNEL_CGROUP_BPF=y
CONFIG_KERNEL_BPF_EVENTS=y
CONFIG_KERNEL_XDP_SOCKETS=y
CONFIG_BPF_TOOLCHAIN_HOST=y
EOF
}

#统一入口：给当前编译目标注入 eBPF 支持
function apply_ebpf_config() {
	#1) OpenWrt 层选项写入 .config
	cat_ebpf_config ./.config

	#2) 内核层选项写入目标 config-default（存在才写）
	local BASE="./target/linux/${WRT_TARGET,,}"
	local KCFG_LIST=()
	if [ -n "$WRT_SUBTARGET" ] && [ -f "$BASE/$WRT_SUBTARGET/config-default" ]; then
		KCFG_LIST+=("$BASE/$WRT_SUBTARGET/config-default")
	elif [ -f "$BASE/config-default" ]; then
		KCFG_LIST+=("$BASE/config-default")
	fi

	for KCFG in "${KCFG_LIST[@]}"; do
		#防止缓存/重复执行时重复追加
		if grep -q "^CONFIG_DEBUG_INFO_BTF=y" "$KCFG"; then
			echo "$KCFG already has eBPF config, skip!"
		else
			cat_kernel_config "$KCFG"
		fi
	done
}
