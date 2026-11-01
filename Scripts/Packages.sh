#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}
	local REPO_PATH="./package/$REPO_NAME"

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ./feeds/luci/ ./feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库：失败必须终止构建，否则会静默产出缺插件的固件
	if ! git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git" "$REPO_PATH"; then
		echo "ERROR: 克隆失败 $PKG_REPO ($PKG_BRANCH)，终止编译" >&2
		rm -rf "$REPO_PATH"
		exit 1
	fi

	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find $REPO_PATH/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./package \;
		rm -rf $REPO_PATH
	fi
}

# 调用示例
# UPDATE_PACKAGE "OpenAppFilter" "destan19/OpenAppFilter" "master" "" "custom_name1 custom_name2"
# UPDATE_PACKAGE "open-app-filter" "destan19/OpenAppFilter" "master" "" "luci-app-appfilter oaf" 这样会把原有的open-app-filter，luci-app-appfilter，oaf相关组件删除，不会出现coremark错误。

# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg，可选，从大杂烩中单独提取包名插件"
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
UPDATE_PACKAGE "fluent" "LazuliKao/luci-theme-fluent" "main"
UPDATE_PACKAGE "footstrap" "VizzleTF/luci-theme-footstrap" "main"
UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "master"
UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "master"
UPDATE_PACKAGE "shadcn" "eamonxg/luci-theme-shadcn" "main"

UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "master" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"
UPDATE_PACKAGE "diskmanager" "4IceG/luci-app-mini-diskmanager" "main"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "axonhub gecoosac sing-box luci-app-homeproxy luci-app-timewol luci-app-wolplus luci-app-wolultra"
# vnt：原仓库 lmq8267/luci-app-vnt 已删除（404），且 Config 未启用该包，暂时停用
# 如需恢复：改用活跃分支 whzhni1/luci-app-vnt2，并在 Config 中加 CONFIG_PACKAGE_luci-app-vnt2=y
# UPDATE_PACKAGE "vnt" "lmq8267/luci-app-vnt" "main"

UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"

UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox ookla-speedtest"
UPDATE_PACKAGE "netwizard" "sirpdboy/luci-app-netwizard" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
UPDATE_PACKAGE "timecontrol" "sirpdboy/luci-app-timecontrol" "main"

UPDATE_PACKAGE "natmapt" "muink/openwrt-natmapt" "master"
UPDATE_PACKAGE "stuntman" "muink/openwrt-stuntman" "master"
UPDATE_PACKAGE "luci-app-natmapt" "muink/luci-app-natmapt" "master"

UPDATE_PACKAGE "airpi3000m-fancontrol" "LianXia233/luci-app-airpi3000m-fancontrol" "main"
UPDATE_PACKAGE "chfs" "LianXia233/luci-app-chfs" "main"
UPDATE_PACKAGE "fm350" "LianXia233/luci-app-fm350" "main"
UPDATE_PACKAGE "h5000m-netmode" "LianXia233/luci-app-h5000m-netmode" "main"
UPDATE_PACKAGE "mt5700" "LianXia233/luci-app-mt5700" "main"
UPDATE_PACKAGE "mt5700m" "LianXia233/luci-app-mt5700m" "main"
UPDATE_PACKAGE "netmonitor" "LianXia233/luci-app-netmonitor" "main"
UPDATE_PACKAGE "qmodem-generic" "LianXia233/luci-app-qmodem-generic" "main"

#清理 feeds install 留下的悬空软链接（指向已删除的 feeds 目录会让 defconfig 扫描报错）
for LINK in ./package/feeds/*/*; do
	if [ -L "$LINK" ] && [ ! -e "$LINK" ]; then
		rm -f "$LINK"
		echo "Remove dangling link: $LINK"
	fi
done

#内置 OpenClash Meta 内核（mihomo）：刷机后开箱即用，免去首次启动联网下载内核
#1) 仅当 Config 启用 luci-app-openclash（或 WRT_PACKAGE 指定）才执行；
#2) 按目标平台自动选 amd64/arm64（本仓库除 X86 外均为 armv8）；
#3) 放入 ./files/etc/openclash/core/clash_meta，走 OpenWrt 顶层 files/ 覆盖机制随固件生成；
#4) 下载失败不终止构建：OpenClash 运行时在线更新内核仍可兜底
OC_ENABLED=false
case "$WRT_TEST" in
	true*|True*|TRUE*) ;;
	*)
		grep -rqs '^CONFIG_PACKAGE_luci-app-openclash=y' "${GITHUB_WORKSPACE:-.}/Config/" && OC_ENABLED=true
		case "$WRT_PACKAGE" in
			*luci-app-openclash*) OC_ENABLED=true ;;
		esac
		;;
esac
if $OC_ENABLED; then
	OC_ARCH=arm64
	grep -qs '^CONFIG_TARGET_x86' "${GITHUB_WORKSPACE:-.}/Config/$WRT_CONFIG.txt" 2>/dev/null && OC_ARCH=amd64
	OC_CORE_DIR="./files/etc/openclash/core"
	OC_VER=$(curl -sL --max-time 30 "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" | jq -r ".tag_name // empty")
	if [ -n "$OC_VER" ]; then
		echo "OpenClash Meta core: $OC_VER ($OC_ARCH)"
		mkdir -p "$OC_CORE_DIR"
		if curl -sL --max-time 300 "https://github.com/MetaCubeX/mihomo/releases/download/$OC_VER/mihomo-linux-$OC_ARCH-$OC_VER.gz" -o /tmp/mihomo.gz \
			&& gzip -t /tmp/mihomo.gz 2>/dev/null; then
			gunzip -f /tmp/mihomo.gz
			mv /tmp/mihomo "$OC_CORE_DIR/clash_meta"
			chmod 0755 "$OC_CORE_DIR/clash_meta"
			echo "core installed: $(du -h "$OC_CORE_DIR/clash_meta" | cut -f1) -> $OC_CORE_DIR/clash_meta"
		else
			echo "WARN: mihomo 内核下载失败，固件不带内置内核（运行时会自动在线下载）"
			rm -f /tmp/mihomo.gz
		fi
	else
		echo "WARN: 获取 mihomo 最新版本号失败，跳过内置内核"
	fi
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./package/ ./feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
#UPDATE_VERSION "sing-box"

#引入私有扩展脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
