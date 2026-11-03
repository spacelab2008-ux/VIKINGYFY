# 高质量<免费>交流群

[IPQ技术讨论群](https://qm.qq.com/q/v7nMhzB4oU)

# 高质量<付费>中转站

[LiBwrt-Ai](https://api.zipimg.cn/register?aff=FFPS3UMJ8HJD)

# 本地编译器

https://github.com/VIKINGYFY/OWRT-Tools.git

# 自用修改版插件

https://github.com/VIKINGYFY/packages.git

# OpenWRT-CI

官方版：

https://github.com/immortalwrt/immortalwrt.git

自用版：

https://github.com/VIKINGYFY/immortalwrt.git

# U-BOOT

高通版-沉心：

https://github.com/chenxin527/uboot-qsdk12.5-build.git

高通版-小猪：

https://github.com/1980490718/u-boot-2016.git

联发科-全新版：

https://github.com/VIKINGYFY/UBOOT-CI/releases

联发科-官方版：

https://drive.wrt.moe/uboot/mediatek

# 固件简要说明

固件每天早上 7:23（北京时间）自动触发编译；受 GitHub Actions 队列延迟影响，实际开跑通常在 10:00–10:40 之间。

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

MEDIATEK系列、QUALCOMMAX系列、ROCKCHIP系列、X86系列。

# 目录简要说明

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置

### Config 启用状态

| 文件 | 状态 | 说明 |
|---|---|---|
| `IPQ60XX-WIFI-NO.txt` | ✅ 生产 | `NN6000-V2.yml` 当前唯一引用的机型配置 |
| `GENERAL.txt` | ✅ 生产 | 所有构建追加的通用配置 |
| `TEST.txt` | ✅ 生产 | `TEST=true` 时仅输出配置、不编译固件 |
| `AIROHA` `IPQ53XX` `IPQ95XX` `ROCKCHIP` `X86` | ⚠️ 备用 | 无 workflow 引用，保留给将来多机型 |
| `MEDIATEK-WIFI-YES/NO` `IPQ807X-WIFI-YES/NO` `IPQ60XX-WIFI-YES` | ⚠️ 备用 | 同上；按需在 workflow 里把 `WRT_CONFIG` 指过来即可启用 |

> ⚠️ 标记「备用」的文件**不参与任何构建**，只作为模板存档。新增机型时复制一份 `NN6000-V2.yml`，改 `WRT_CONFIG` 指向目标文件即可。

## Star History

<a href="https://www.star-history.com/?repos=spacelab2008-ux%2FVIKINGYFY&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=spacelab2008-ux/VIKINGYFY&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=spacelab2008-ux/VIKINGYFY&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=spacelab2008-ux/VIKINGYFY&type=date&legend=top-left" />
 </picture>
</a>
