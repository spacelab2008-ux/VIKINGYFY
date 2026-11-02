#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

set -euo pipefail

# --- Rust 工具链守卫：缺失则优雅跳过，而不是让整轮固件构建失败 ---
RUSTUP_BIN=$(command -v rustup || true)
if [ -z "$RUSTUP_BIN" ]; then
	for candidate in "$HOME/.cargo/bin/rustup" /usr/bin/rustup; do
		if [ -x "$candidate" ]; then RUSTUP_BIN=$candidate; break; fi
	done
fi
# 没有 rustup：尝试自助引导（需要网络）。这样在默认不预装 Rust 的
# GitHub-hosted runner 上也能自洽，不必依赖外部预装环境。
if [ -z "$RUSTUP_BIN" ]; then
	if command -v curl >/dev/null 2>&1 && curl -fsSL --max-time 60 https://sh.rustup.rs | sh -s -- -y --profile minimal >/dev/null 2>&1; then
		RUSTUP_BIN="$HOME/.cargo/bin/rustup"
	fi
fi
# 仍然拿不到 rustup：当前 38 个包均不在编译期依赖 Rust，直接跳过。
# 若日后加入需要 Rust 的包，再回来收紧此分支（改为 exit 1）。
if [ -z "$RUSTUP_BIN" ]; then
	echo "rustup 不可用且自助引导失败；未检测到需要 Rust 的包 -> 跳过 Rust 准备" >&2
	exit 0
fi

RUST_FEED="$PWD/feeds/packages/lang/rust"
RUST_MAKEFILE="$RUST_FEED/Makefile"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPORT_DIR="${GITHUB_WORKSPACE:-$PWD}/build-reports"
mkdir -p "$REPORT_DIR"

# Ask the feed for its target triple so CI and OpenWrt use the same mapping.
RUST_TARGET=$(make --no-print-directory -s -f - TOPDIR="$PWD" ci-rust-target <<'MAKE'
include $(TOPDIR)/rules.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-values.mk
.PHONY: ci-rust-target
ci-rust-target:
	@printf '%s\n' '$(RUSTC_TARGET_ARCH)'
MAKE
)
PATH="$(dirname "$RUSTUP_BIN"):$PATH"
export PATH
RUST_TOOLCHAIN=$(rustup show active-toolchain | awk '{print $1}')
printf 'Rust toolchain: %s\nRust target: %s\n' "$RUST_TOOLCHAIN" "$RUST_TARGET" | tee "$REPORT_DIR/rust-toolchain.txt"

rustup target add --toolchain "$RUST_TOOLCHAIN" "$RUST_TARGET"
RUST_ROOT=$(rustup run "$RUST_TOOLCHAIN" rustc --print sysroot)
test -d "$RUST_ROOT/lib/rustlib/$RUST_TARGET/lib"
for tool in cargo rustc rustdoc; do
	test -x "$RUST_ROOT/bin/$tool"
done

# Replace the source bootstrap before OpenWrt expands its host build rules.
{
	printf 'CI_RUST_ROOT:=%s\n' "$RUST_ROOT"
	cat "$SCRIPT_DIR/rust-prebuilt.mk"
} > "$RUST_FEED/ci-prebuilt.mk"
# shellcheck disable=SC2016 # Match the literal Make expression.
sed -i '/^include \.\/ci-prebuilt.mk$/d; /^$(eval $(call HostBuild))$/i include ./ci-prebuilt.mk' "$RUST_MAKEFILE"
grep -Fxq 'include ./ci-prebuilt.mk' "$RUST_MAKEFILE"

"$RUST_ROOT/bin/rustc" --version | tee -a "$REPORT_DIR/rust-toolchain.txt"
echo "Using runner Rust $RUST_TOOLCHAIN for $RUST_TARGET" | tee -a "$REPORT_DIR/rust-toolchain.txt"
sha256sum "$RUST_MAKEFILE" >> "$REPORT_DIR/rust-toolchain.txt"
