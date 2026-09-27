# AGENTS.md — Termo（fork 自用仓库）

## 仓库规则

- 本仓库 fork 自 `icloudza/termo`，仅供个人自用，持续同步上游。
- 只向 `gbandszxc/termo` commit / push；禁止向上游发 PR、issue、评论、帖子或联系原作者及社区，也不要建议这些操作。
- 上游行为差异在本仓库内解决，保持改动便于 rebase。
- 遵守 PolyForm Noncommercial 1.0.0：禁止商用或闭源再分发。

## 文档

| 文档 | 使用要求 |
|---|---|
| [README.zh-CN.md](README.zh-CN.md) / [README.md](README.md) | 了解产品与构建方式；新增用户可见功能后同步更新。 |
| [CONTEXT.md](CONTEXT.md) | 产品决策前阅读；定位、约束或功能方向变化时更新。 |
| [DESIGN.md](DESIGN.md) | UI 改动前必读；视觉变化先更新文档。 |
| [CHANGELOG.md](CHANGELOG.md) | 发版前阅读；值得记录的变更写入 `[Unreleased]`，遵循 Keep a Changelog。 |
| [PRODUCT.md](PRODUCT.md) | 不编辑，改 `CONTEXT.md`。 |

## UI

- 以 `DESIGN.md` 为唯一视觉依据；先改 token / 规范，再改代码，同步 `.impeccable/design.json`。
- 样式值取自 `Termo/UI/Theme/Theme.swift`（`ThemeColors` / `Pal`）与设计 token，禁止硬编码新颜色、圆角、字号。
- 自绘组件使用 `Pal.fill()`，验证深色与浅色主题。
- 复用 `UI/Components/Components.swift` 的 `Themed*` 控件；禁用原生输入框聚焦光环、开关和弹窗外观。

## 构建与发版

- 只修改 `project.yml`，不手改 `Termo.xcodeproj`；改后运行 `xcodegen generate`。
- 编译验证：`xcodegen generate && xcodebuild -scheme Termo -configuration Release build`。
- MAS 使用 `DebugMAS` / `ReleaseMAS`，相关改动兼容普通与沙盒构建。
- 本地打包：`scripts/package-app.sh`；必须输出 `.app` 和 DMG 到 `dist/<版本>-<build>/`。
- 版本号只改 `Termo/Info.plist`，`CFBundleVersion` 严格递增。
- 发版用 `scripts/release.sh`，预览用 `--dry-run`；推 tag 触发 GitHub Actions 发布。
- 不随意升级 `Vendor/` 与 `LocalPackages/` 中的第三方依赖。

## 架构

按以下目录边界放置代码：

```text
Termo/
├── App/               # 入口、AppModel、AppSettings
├── Core/              # 引擎与模型
├── Features/
│   ├── Terminal/      # 终端
│   ├── File/          # 文件与传输
│   ├── RDP/           # 远程桌面
│   ├── SSH/           # SSH
│   ├── Keys/          # 密钥
│   ├── PortForward/   # 端口转发
│   ├── Snippets/      # 代码片段
│   ├── Settings/      # 设置
│   └── Update/        # 软件更新
├── UI/
│   ├── Theme/         # 主题与 token
│   ├── Components/    # 通用控件
│   ├── Layout/        # 布局
│   └── Icons/         # 图标
└── System/
    ├── Tray/          # 托盘
    └── Notifications/ # 通知
```

## 代码约定

- 源文案和注释使用简体中文（`zh-Hans`）；UI 文案用 `LocalizedStringKey` 字面量，动态字符串用 `verbatim`，英文翻译维护在 `Termo/Localizable.xcstrings`。
- 密码和私钥口令只存系统钥匙串，不写明文文件或日志；IP、主机名等使用 `privacyBlur` 脱敏。
- 本地终端入口使用 `AppEnv.localTerminalEnabled` 控制，MAS 构建隐藏。
