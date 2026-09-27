# Context —— Termo 产品上下文

<!-- impeccable:product-schema 1 -->

> 本文件是本仓库的产品事实记录（fork 维护者确认）。`PRODUCT.md` 是指向本文件的指针，
> 供 impeccable 等工具链读取；两处不要同时编辑，改这里即可。

## Platform

原生 macOS 应用（SwiftUI + AppKit，单窗口 + 菜单栏托盘）。要求 macOS 14 (Sonoma) 及以上、Apple Silicon。
注意：不适用 Web/ iOS / Android 的设计约定，所有界面为自绘 SwiftUI，视觉不依赖系统控件默认外观。

## Fork 目标

- **上游**：[icloudza/termo](https://github.com/icloudza/termo)（v1.0.2 / build 34 起 fork），本仓库：[gbandszxc/termo](https://github.com/gbandszxc/termo)。
- **用途**：个人自用；本地已安装原版 `/Applications/Termo.app` 作为视觉与行为的对照基准。
- **方向**：有明确的新功能计划（具体条目待定，见下方 Roadmap 占位）。在新功能落地前，UI 与交互保持与上游一致，不主动偏离。

### Roadmap（占位）

> 维护者确认「有明确新功能方向」，具体条目尚未录入。确定后请补写到这里，
> 并同步评估是否影响 DESIGN.md 的视觉系统（新增面板/控件须复用现有 token）。

- [ ] （待补充：新功能 1）
- [ ] （待补充：新功能 2）

## Users

- **主要用户**：维护者本人——管理若干台 Linux 云主机（阿里云等）与 Windows 远程桌面的开发者/运维者，日常在 macOS 上完成 SSH 终端、文件传输、端口转发、主机监控。
- 场景特征：多主机并行、频繁开关终端标签、关注连接稳定性与延迟；有截图/共享屏幕需求（应用内置脱敏模式）。

## Product Purpose

Termo 把原本分散在多个工具中的远程运维事务——SSH 终端、SFTP 文件传输、Windows 远程桌面、端口转发、主机监控、SSH 密钥管理、常用命令片段——收进**同一个高完成度的原生 macOS 界面**。成功标准：连接稳、启动快、开箱即用，细节观感对齐 Ghostty / Xcode。

## Positioning

**全进程内引擎**：SSH / SFTP / 终端 / 端口转发 / 密钥全部以 libssh2 + OpenSSL 编译进单一二进制（不 spawn 系统 `ssh`），RDP 内嵌 FreeRDP。自包含、经 Apple 签名公证——这是相邻产品（依赖外部进程或 Electron 的客户端）无法照抄的机制。

## Operating Context

- 工程由 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 声明式管理（`project.yml` → `xcodegen generate` 生成 `Termo.xcodeproj`）；第三方原生依赖（FreeRDP / libssh2 / Sparkle）以 xcframework 随仓库提供（`Vendor/`、`LocalPackages/`）。
- 构建：`xcodegen generate && xcodebuild -scheme Termo -configuration Release build`。
- 版本号只在 `Termo/Info.plist` 一处维护（`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`）。
- 发布走 Sparkle + EdDSA 签名自动更新，国内经 Cloudflare R2 加速；官网 termoi.app。
- 密码/私钥口令存系统钥匙串，不落明文磁盘。
- 应用内提供中英双语切换（`Localizable.xcstrings`，改语言需重启生效）。

## Capabilities and Constraints

**能力**（上游既有，fork 默认继承）：

| 模块 | 要点 |
|---|---|
| SSH 终端 | SwiftTerm 渲染；断线自动重连；OSC 7 上报 cwd 驱动侧栏文件树 |
| SFTP | 上传/下载/重命名/权限/断点续传/并发队列/远程代码在线编辑 |
| RDP | FreeRDP 内嵌标签或独立窗口；剪贴板双向同步可选 |
| 端口转发 | -L / -R / -D(SOCKS)；后台常驻，托盘看板 |
| 主机监控 | CPU/内存/磁盘/网络实时折线；异常可发系统通知；仅数据采集不部署脚本 |
| 密钥管理 | 进程内生成/导入 ed25519 · RSA |
| 代码片段 | 一键插入或直接运行 |
| 本地终端 | 仅 Developer ID 构建可用（MAS 沙盒构建隐藏入口，`AppEnv.localTerminalEnabled`） |

**约束**：

- 许可证 **PolyForm Noncommercial 1.0.0**（上游版权 cloudza）——仅限非商业使用；fork 自用合规，不得商用或闭源再分发。
- 深色/浅色双主题为硬性要求，所有自绘组件必须双主题验证（`ThemeManager` / `Pal`）。
- 中英双语：新增 UI 文案必须进 String Catalog（`LocalizedStringKey` 字面量自动录入；动态字符串用 verbatim）。
- 统一自绘：禁用系统原生控件外观（原生 focus ring 已通过 `noNativeFocusRing()` 全局关闭）。

## Brand Commitments

- 名称 **Termo**；Logo 为 `assets/logo-light.svg` / `assets/logo-dark.svg`（终端光标箭头 + 下划线意象）。
- 观感承诺（README 明示）：**「深 / 浅色主题、菜单栏呼吸灯，细节对齐 Ghostty / Xcode 的观感」**——设计系统以此为锚（见 DESIGN.md）。
- 托盘常驻 + 菜单栏呼吸灯（端口转发等活动状态可视）。

## Evidence on Hand

- `README.zh-CN.md` / `README.md`：功能表、构建说明、官网下载。
- `assets/termo-overview.png`：官方宣传截图。
- 本次固化时对原版应用的实拍截图（深/浅 × 主机列表/概览/终端/设置）：`/tmp/termo-shots/*.png`（会话临时目录，如需长期保留请移入仓库）。
- 代码即视觉事实源：`Termo/UI/Theme/Theme.swift`（全部颜色 token）、`Termo/UI/Components/Components.swift`（自绘组件）、`Termo/UI/Layout/`（活动栏 76pt / 侧栏 224pt / 标签栏）。

## Product Principles

1. **连接可靠优先**——任何 UI 改动不得损害进程内引擎的稳定性与首帧体验（冷启动无白闪）。
2. **双主题即正确性**——一个组件只在深色下好看等于没做完。
3. **自绘但不过度**——替换系统控件外观，但保留 macOS 的键盘/菜单/辅助功能习惯。
4. **信息密度服务于扫读**——工具型界面，扫读效率高于装饰表达。

## Accessibility & Inclusion

- 未确立特殊无障碍标准；继承 SwiftUI/AppKit 默认可达性。
- 已有相关实践：脱敏模式（截图/共享时高斯模糊隐藏 IP 与主机名）、中英双语、延迟等级以「颜色 + 文字标签」双通道呈现（不只靠颜色区分状态）。
