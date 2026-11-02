# 安装与使用 Time

## 系统要求与下载

- macOS 13 或更高版本。
- Universal 安装包同时支持 Apple Silicon 和 Intel Mac，无需安装 Xcode。
- 从 [GitHub Releases](https://github.com/yauyy/time/releases) 下载应用及对应版本的校验文件。

| 文件 | 用途 |
| --- | --- |
| [Time-macOS-universal.dmg](https://github.com/yauyy/time/releases/latest/download/Time-macOS-universal.dmg) | 打开后拖动安装 |
| [Time-macOS-universal.zip](https://github.com/yauyy/time/releases/latest/download/Time-macOS-universal.zip) | 解压后安装 |
| [SHA256SUMS.txt](https://github.com/yauyy/time/releases/latest/download/SHA256SUMS.txt) | 核对下载文件的 SHA256 |

## 安装

1. 下载并打开 DMG；如果下载的是 ZIP，先双击解压。
2. 将 **Time.app** 拖入 Finder 中的“应用程序”文件夹。
3. 从“应用程序”打开 Time。它不显示 Dock 图标或普通主窗口；菜单栏上的时间就是入口，默认显示上海时间。
4. 点击菜单栏时间打开面板，点击齿轮配置显示方式。

建议完成安装后再开启“登录时启动 Time”，并保持应用所在位置不变。使用 DMG 时，安装完成即可在 Finder 中推出磁盘映像。

## 首次打开被 macOS 拦截

当前发布包使用 ad hoc 签名，尚未使用 Developer ID 签名和 Apple 公证，首次打开可能被 Gatekeeper 拦截。

确认应用来自本项目发布页后，按照 [Apple 官方说明](https://support.apple.com/en-us/102445)操作：

1. 先尝试打开已安装的 Time.app。
2. 打开“系统设置 → 隐私与安全性”，滚动到安全性区域。
3. 找到 Time 的拦截提示，点击“仍要打开”。
4. 在再次出现的提示中确认打开；系统可能要求密码或 Touch ID。

这会为 Time 保存单独的打开许可。若没有对应按钮，或提示应用损坏，请先重新下载并核对校验值；仍有问题可在 [Issues](https://github.com/yauyy/time/issues) 中反馈 macOS 版本和芯片类型。

## 核对下载文件

从同一次发布下载安装包和 `SHA256SUMS.txt`。在终端进入下载目录，计算文件校验值：

```bash
cd ~/Downloads
shasum -a 256 Time-macOS-universal.dmg
```

使用 ZIP 时，把命令中的文件名换成 `Time-macOS-universal.zip`。将输出与 `SHA256SUMS.txt` 中对应文件的值比较，应完全一致。校验值用于确认文件内容一致，不代表 Apple 已对应用进行公证。

## 日常设置

- **主时区**：在世界时钟列表点击城市，或在显示设置中选择菜单栏时区。
- **添加或移除城市**：“+”打开搜索；可按中文、英文或 `Asia/Shanghai` 等时区标识搜索。城市选项菜单可移除城市，至少保留一个。
- **日期和时间**：日期、星期、秒钟及闪动分隔符独立控制；关闭 24 小时制后可显示上午/下午。预览和菜单栏即时更新，设置自动保存在本机。
- **登录时启动**：在显示设置中开启。若系统要求允许，按照应用提示打开登录项设置完成确认。
- **关闭与退出**：点击面板外区域可关闭面板，菜单栏时钟继续运行；选择面板底部“退出 Time”可完全退出。

## 菜单栏位置与原生时钟

按住 **Command** 拖动 Time 的菜单栏时间，可调整它与其他可移动项目的顺序。位置受 macOS 管理，系统保留区域、刘海和可用空间可能限制放置位置；减少日期或秒钟的显示可缩短文字。

macOS 的原生时钟始终显示，Time 不能通过公开接口替换或完全隐藏它。可在系统设置的“菜单栏”（部分旧版本为“控制中心”）中打开“时钟选项”，把原生时钟改为指针样式，并关闭日期和星期，减少重复显示。[Apple 官方说明](https://support.apple.com/en-euro/guide/mac-help/mchlb3236e90/27/mac/27)

Time 只按所选时区显示时间，不改变系统时间或系统时区。

## 更新

1. 在 Time 面板中选择“退出 Time”。
2. 从 [Releases](https://github.com/yauyy/time/releases) 下载新版，将原位置的 Time.app 替换为新版。
3. 再次打开应用。已有时区和显示设置会保留。

当前没有内置自动更新功能。若更新后系统要求重新确认打开许可或登录启动，请按提示处理。

## 卸载

1. 在 Time 设置中关闭“登录时启动 Time”；也可在 macOS 的登录项设置中移除。
2. 退出 Time。
3. 删除“应用程序”中的 Time.app。

删除应用后，本机偏好会保留，重新安装时可继续使用原来的设置。
