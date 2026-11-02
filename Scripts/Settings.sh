#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY
#移除luci-app-attendedsysupgrade
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "/attendedsysupgrade/d" {} +
#修改默认主题
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" {} +
#修改immortalwrt.lan关联IP
find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js" -exec sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" {} +
#添加编译日期标识
find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" -exec sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" {} +
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_UC" ]; then
	#上游模板是 set ${si}.ssid='${defaults?.ssid || 'OWRT'}'
	#用 ssid='.*' 贪婪替换会把 ${defaults?.ssid || 'OWRT'} 整段吃掉，同时丢掉空值兜底：
	#WRT_SSID 为空时默认 SSID 会变成空串，无线直接不可见。
	#这里精确匹配整段表达式，并把空值兜底补回来。
	WRT_SSID=${WRT_SSID:-OWRT}
	WRT_WORD=${WRT_WORD:-12345678}
	#替换串里的 \ & # 都是 sed 特殊字符（& = 整个匹配，# = 本行分隔符），逐个转义
	sed_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/&/\\&/g' -e 's/#/\\#/g'; }
	SSID_ESC=$(sed_escape "$WRT_SSID")
	WORD_ESC=$(sed_escape "$WRT_WORD")
	#修改WIFI名称
	sed -i "s#ssid='\${defaults?.ssid || 'OWRT'}'#ssid='$SSID_ESC'#g" "$WIFI_UC"
	#修改WIFI密码
	sed -i "s#key='\${defaults?.key || '12345678'}'#key='$WORD_ESC'#g" "$WIFI_UC"
	#模板若被上游改写，精确匹配会失效，这里只告警不猜替换，避免产出坏语法
	if grep -qF '${defaults?.ssid' "$WIFI_UC"; then
		echo "WARN: mac80211.uc 的 ssid 模板已变化，默认 SSID 未被替换" >&2
	fi
	if grep -qF '${defaults?.key' "$WIFI_UC"; then
		echo "WARN: mac80211.uc 的 key 模板已变化，默认密码未被替换" >&2
	fi
fi
CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config
#引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi
#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi
#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#无WIFI配置调整Q6大小
	if [[ "$WRT_WIFI" == "WIFI-NO" ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi
#预置 AdGuard Home 配置与 DNS 劫持规则：Files/ -> ./files/，随固件烧入（顶层 files/ 会被打进 rootfs）
if [ -d "$GITHUB_WORKSPACE/Files" ]; then
	mkdir -p ./files
	cp -a "$GITHUB_WORKSPACE/Files/." ./files/
	#DNS 劫持规则里的内网网段跟随 WRT_IP（默认写的是 192.168.10.0/24）
	NFT_FILE="./files/etc/nftables.d/20-dns-hijack.nft"
	if [ -f "$NFT_FILE" ] && [ -n "$WRT_IP" ]; then
		SUBNET="${WRT_IP%.*}.0/24"
		sed -i "s#ip daddr [0-9.]*/24 return#ip daddr $SUBNET return#" "$NFT_FILE"
		echo "dns hijack subnet -> $SUBNET"
	fi
	#权限：AGH 主配置仅属主可读（启动时 init 会 chown 给 adguardhome 用户）
	chmod 600 ./files/etc/adguardhome/adguardhome.yaml ./files/etc/config/adguardhome 2>/dev/null
	chmod 755 ./files/etc/uci-defaults/zz-adguard-dns 2>/dev/null
	chmod 644 ./files/etc/nftables.d/20-dns-hijack.nft 2>/dev/null
	echo "AdGuard Home presets copied to ./files/"
fi
#内核槽大小适配（nn6000 已刷 12MB 内核分区，见 function.sh）
source $GITHUB_WORKSPACE/Scripts/function.sh
apply_kernel_tweaks
