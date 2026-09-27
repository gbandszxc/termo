# Fork 改动与上游同步记录

用于核对个人差异与合并方案；用户更新日志见 [CHANGELOG.md](../CHANGELOG.md)。每次个人改动或上游同步，在同一提交中更新本文件。下文路径均相对仓库根目录。

## 同步决策

- **缺少的上游新功能直接合并**：遵守仓库约束，保留既有个人功能；如需改变双方已有的同类功能，按下一条处理。
- **双方已有的同类功能，上游实现优先考虑，但必须先询问用户**：即使 Git 能自动合并，也不能自行决定采用、替换或删除实现。取得明确确认后，才执行对应方案。
- **询问前给出客观比较与推荐方案**：比较能力覆盖、正确性与安全、性能证据、维护成本和兼容性；说明双方优缺点、保留或失去的行为、推荐方案及理由。区分事实与推测，未验证项标为未知。
- **安全与连接修复优先纳入推荐方案**，但不能绕过上述确认或无声丢失个人功能。确认采用上游等价能力后，删除重复实现。
- **展示版本 X.Y.Z 跟随采用的上游版本**，个人版仅用不同 build 区分，不自行增加展示版本。`CFBundleVersion` 严格递增，新 build 大于已发布个人 build 和引入的上游 build；版本号只修改 `Termo/Info.plist`。

## 基线与发布

- 上游：`icloudza/termo`；自用仓库：`gbandszxc/termo`。只向自用仓库推送，不向上游发 PR、issue、评论或联系社区；遵守非商业许可、钥匙串和脱敏约束。
- fork 起点 / 最后同步基线：`ac788250967598c0ceb6543ac82b7f8ea13d230b`，上游 1.0.2 / build 34。
- 个人记录：build 35 为本地包；36 发布目录传输和默认下载目录；37 发布终端与 SFTP 路径导航；38 增加自定义终端字体。
- 个人标签为 `personal-<版本>-<build>`，Release 标题为 `Termo <版本> (<build>)`，附本地生成的 DMG。
- `v*` Actions 关联上游签名、公证、R2 和 Sparkle 服务，不用于个人发布。`LC_ALL=C scripts/release.sh --dry-run` 仅作预览，实际通过个人标签与 `gh release` 发布。
- 无 Developer ID 时采用 ad-hoc 签名、未公证；现有 Sparkle 源仍指向上游，不代表个人 Release 自动更新通道。

## 个人差异清单

下表记录当前行为与合并时的核对点，不代替“同步决策”中的用户确认。

| 改动 / 提交 | 主要文件 | 需要核对的行为 |
|---|---|---|
| 终端字体（build 38） | `SettingsView.swift`、`AppSettings.swift`、`AppModel.swift`、`Components.swift`、`TerminalFontSettingsTests.swift` | 自定义开关、本机字体搜索、双主题无箭头列表；预置与自定义值分别持久化、即时应用，字体缺失保留等宽回退；同步上游同类功能前先比较并确认。 |
| 产品与视觉：`c6ee50e` | `CONTEXT.md`、`PRODUCT.md`、`DESIGN.md`、`.impeccable/design.json` | 自用定位；PRODUCT 仅作指针；规范与深浅主题 token 跟随实际代码，不用旧文档强盖新实现。 |
| 工作约定：`636ec3a`、`3a62b1c`、`cc8171a` | `AGENTS.md` | 自用仓库边界、中文文案、非商业许可、钥匙串、脱敏与 XcodeGen 约定。 |
| SFTP 目录传输：`a5e5b4d` | `DirectoryTransfer.swift`、`FileUpload.swift`、`RemoteFS.swift`、`FileOps.swift`、`FileBrowser.swift`、`AppModel.swift`、`BackgroundCenterView.swift` | 文件/目录及 Finder 混合传输、空目录、跳过链接、按需遍历；并发、暂停/取消、续传；最近 128 项历史与全部失败重试。 |
| 传输测试：`1a011c4` | `TermoTests/DirectoryTransferTests.swift`、`project.yml` | 15 项行为测试；适配接口变化，保留覆盖；工程文件通过 XcodeGen 重新生成。 |
| 默认下载目录：`524886b` | `AppSettings.swift`、`AppModel.swift` | 默认 `Downloads/Termo`、自动创建、自选路径优先；沿用上游沙盒访问授权机制。 |
| 本地打包：`b393dff` | `scripts/package-app.sh` | 自动生成工程；`.app` 与 DMG 输出到 `dist/<版本>-<build>/`；验证 DMG 和包内版本，吸收上游签名、公证修复。 |
| 路径导航：`68a4ef0` | `TerminalSurface.swift`、`AppModel.swift`、`FileBrowser.swift`、`RemoteFS.swift` | 终端 cwd 跳转并复用主机文件标签；地址编辑、回车、取消；错误保留目录、列表、选择和历史。无 cwd 时已有标签保留目录、新标签加载家目录。 |
| 导航测试与翻译：`68a4ef0` | `TermoTests/SFTPNavigationTests.swift`、`Localizable.xcstrings` | 6 项回归测试；无回调也执行加载；路径不作为 shell 命令执行；适配 OSC 上报格式，本仓库原钩子直接上报 `$PWD`。翻译按 key 合并。 |
| 版本与文档：`e379800`、`b393dff`、`b38044d` | `Termo/Info.plist`、README 中英文、`CHANGELOG.md`、本文件 | 展示版本跟随上游、build 递增；上游与个人发布记录分别保留；更新同步基线及差异状态。 |

## 同步流程

1. 保留当前工作，在 `codex/` 同步分支操作。读取上游候选提交，对照最后同步基线与个人差异清单；只 fetch 上游，不 push 上游。
2. 按“同步决策”处理新功能与重叠功能。冲突同时核对基线、个人版本、上游版本，不整文件选择 ours/theirs；需要确认的方案获批后再合并。
3. 已发布的 `main` 默认 merge，避免改写发布历史；未发布的独立分支可 rebase。合并 `project.yml` 后运行 `xcodegen generate`，不手工拼接生成工程。
4. 检查未合并路径与 `git diff --check`；验证 Release、ReleaseMAS 构建及测试：

   ```bash
   xcodegen generate
   xcodebuild -scheme Termo -configuration Release build
   xcodebuild -scheme Termo-MAS -configuration ReleaseMAS build
   xcodebuild -scheme Termo -configuration Debug -destination 'platform=macOS,arch=arm64' test
   ```

   无项目证书时可加 `CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO` 做本地验证，不能视为正式分发签名。
5. 实机核对受影响的传输、导航、错误恢复、下载目录及深浅主题。更新最后同步基线、适配提交、已保留/替代/移除的差异，以及用户文档和翻译；仅推送自用仓库。

## 当前验收

build 38：22 项测试通过（含自定义字体选择与切换持久化回归）；Release 归档、ReleaseMAS 构建及 DMG 内容与 ad-hoc 签名校验通过。

build 37：Release、ReleaseMAS 编译与 21 项测试通过；默认回调跳过加载、浅色错误文案对比问题已修复。未做远端实机操作；界面服务超时，深浅主题截图未验证，不作为后续同步的实机验收证据。
