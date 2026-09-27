# AGENTS.md — Termo（fork 自用仓库）

给 ZCode agent 的工作区指令。产品介绍、视觉规范、产品事实**已存在于专门文档中，本文件只做索引与规则，不重复其内容**。

## 最高原则（优先级高于一切）

- 本仓库是 [icloudza/termo](https://github.com/icloudza/termo) 的 **fork，仅供个人自用**，后续会紧跟上游代码。
- **绝对禁止任何可能打扰原作者的操作**：不向上游发 PR、不开 issue、不加评论、不发帖、不通过任何外部渠道联系原作者或社区。所有改动只 commit / push 到本仓库（`gbandszxc/termo`）。
- 因此不要建议"回馈上游""提 issue 问作者"之类的行动；上游行为差异一律在本仓库内解决。
- 许可证为 PolyForm Noncommercial 1.0.0：仅限非商业使用，不得商用或闭源再分发。

## 文档索引与维护时机

| 文档 | 内容 | 何时读 | 何时更新 |
|---|---|---|---|
| [README.zh-CN.md](README.zh-CN.md) / [README.md](README.md) | 产品介绍、功能表、下载与构建说明 | 需要了解产品全貌时 | 新增用户可见功能后 |
| [CONTEXT.md](CONTEXT.md) | 产品事实：用户、定位、能力约束、Roadmap | 做产品级决策前 | 定位/约束/新功能方向变化时 |
| [DESIGN.md](DESIGN.md) | 视觉系统：YAML token + 八章节规范 | **任何 UI 改动前必读** | 视觉系统变化时（见下条规则） |
| [CHANGELOG.md](CHANGELOG.md) | Keep a Changelog 格式 | 发版时 | 每个值得记录的变更写入 `[Unreleased]` |
| [PRODUCT.md](PRODUCT.md) | 指向 CONTEXT.md 的指针（工具链用） | 一般不用读 | 不要编辑，改 CONTEXT.md |

## 样式维护规则（硬性）

1. **文档先行**：任何视觉变化（颜色、圆角、字号、间距、组件规范）必须**先改 DESIGN.md 的 token/章节，再改代码**，两处取值保持一字不差。
2. **token 优先**：代码中的样式值一律取自 `Termo/UI/Theme/Theme.swift`（`ThemeColors` / `Pal`）与 DESIGN.md frontmatter；禁止硬编码新颜色、新圆角档位、新字号档位。
3. **双主题验证**：每个自绘组件必须在深色（`#1e1e1e` 系）与浅色（`#f5f6f9` 系）下同时正确，用 `Pal.fill()` 叠加体系而非写死色值。
4. 使用方式：AI 生成新界面时以 DESIGN.md 为唯一视觉依据；其 `.impeccable/design.json` 是 token 的机器可读 sidecar，与 DESIGN.md 同步维护。

## 构建与发版

- 工程由 **XcodeGen** 管理：`project.yml` 是唯一工程事实源，**不要手改 `Termo.xcodeproj`**（改了也会被 `xcodegen generate` 覆盖）。
- 构建：`xcodegen generate && xcodebuild -scheme Termo -configuration Release build`；沙盒 MAS 版用 `DebugMAS` / `ReleaseMAS` 配置。
- 版本号唯一源：`Termo/Info.plist`（`CFBundleShortVersionString` + 严格递增的 `CFBundleVersion`）。
- 发版：`scripts/release.sh`（交互向导，`--dry-run` 预览；推 tag 后由 GitHub Actions 接管构建/签名/公证/发布）。
- 第三方依赖（FreeRDP / libssh2 / SwiftTerm 等）以 xcframework 形式在 `Vendor/` 与 `LocalPackages/`，勿随手升级。

## 架构与代码约定

- 目录边界：`App/`（AppModel/AppSettings/入口）、`Core/`（引擎与模型）、`Features/`（Terminal/File/RDP/SSH/Keys/PortForward/Snippets/Settings）、`UI/`（Theme/Components/Layout/Icons）、`System/`（Tray/Notifications）。
- 源语言为**简体中文**（`developmentLanguage: zh-Hans`，注释也用中文）：新增 UI 文案用 `LocalizedStringKey` 字面量（自动进 String Catalog），运行时动态字符串用 `verbatim`；英文翻译在 `Termo/Localizable.xcstrings`。
- **禁用系统原生控件外观**：输入框聚焦光环、原生开关、原生弹窗一律用 `UI/Components/Components.swift` 的 `Themed*` 组件；新控件先找现成组件。
- 密码/私钥口令只进系统钥匙串，禁止明文落盘或写日志；IP/主机名等敏感信息注意 `privacyBlur` 脱敏机制。
- 本地终端入口受 `AppEnv.localTerminalEnabled` 控制（MAS 沙盒构建隐藏），改动相关 UI 时需兼容两种构建。
