# Fork 改动与上游同步记录

本文件记录自用 fork 相对上游的差异，供同步时核对行为与合并方案；用户更新日志仍维护在 `CHANGELOG.md`。每次新增、移除或被上游替代的个人改动，都在同一提交中更新本文件。

## 基线与发布

- 上游：`icloudza/termo`；自用仓库：`gbandszxc/termo`。只向自用仓库推送，不向上游发 PR、issue 或评论。
- fork 起点 / 当前最后同步基线：`ac788250967598c0ceb6543ac82b7f8ea13d230b`，上游 1.0.2 / build 34。
- 个人构建保留展示版本 1.0.2，构建号严格递增；35 为本地包，36 为首次个人 GitHub Release，37 新增 SFTP 路径导航。
- 个人 Release 使用 `personal-<版本>-<build>` 标签，标题为 `Termo <版本> (<build>)`，附本地生成的 DMG。
- 现有 `scripts/release.sh` 和 `v*` Actions 服务上游签名、公证、R2 与 Sparkle 发布链路；个人发布仅用脚本 `--dry-run` 预览，实际用个人标签与 `gh release`，避免触发该链路。预览时使用 `LC_ALL=C`，兼容 macOS 系统 Bash 的变量名解析。
- 本地缺少 Developer ID 时使用 ad-hoc 签名，个人 DMG 未经公证；现有 Sparkle 源仍指向上游，不代表个人 Release 的自动更新通道。

## 必须核对的个人差异

| 改动 / 提交 | 当前行为与涉及文件 | 上游冲突时的合并原则 |
|---|---|---|
| 产品与视觉文档：`c6ee50e` | `CONTEXT.md` 记录自用定位；`PRODUCT.md` 仅作指针；`DESIGN.md`、`.impeccable/design.json` 记录深浅主题与既有 token。 | 保留自用定位。上游视觉或组件变化先核对实际代码，再同步规范和 sidecar；不把旧文档中的实现细节强盖回新代码。 |
| 仓库工作约定：`636ec3a`、`3a62b1c`、`cc8171a` | `AGENTS.md`：自用仓库边界、中文文案、XcodeGen、主题、安全和构建约定。 | 保留只向自用仓库推送、非商业许可、钥匙串及脱敏要求；目录说明随上游结构更新。 |
| SFTP 目录传输：`a5e5b4d` | `DirectoryTransfer.swift`、`FileUpload.swift`、`RemoteFS.swift`、`FileOps.swift`、`FileBrowser.swift`、`AppModel.swift`、`BackgroundCenterView.swift`：文件/目录统一上传下载、Finder 混合拖入、保留空目录、默认跳过链接、按需遍历；历史最多 128 项，完整失败记录可重试。 | 不整文件取 ours/theirs。保留上游连接、安全及取消修复，并逐项核对目录枚举、并发队列、暂停/取消、断点续传和失败重试。如果上游已有等价能力，优先复用并删除重复实现。 |
| 传输测试与工程：`1a011c4` | `TermoTests/DirectoryTransferTests.swift` 的 15 项测试；`project.yml` 新增测试 target 与 scheme。 | 合并 `project.yml` 后运行 `xcodegen generate`；生成工程冲突通过重新生成解决，不手工拼接 pbxproj。保留业务行为覆盖，适配上游接口变化。 |
| 默认下载位置：`524886b` | `AppSettings.swift` 的 `resolvedDownloadDir` 与 `AppModel.swift`：默认系统下载目录下的 `Termo`，下载时创建目录，保留用户自选路径。 | 保留默认子目录和自选路径优先级；若上游改为沙盒书签或新存储方式，沿用其访问授权机制。 |
| 本地打包：`b393dff` | `scripts/package-app.sh` 自动运行 XcodeGen，生成并验证 DMG，`.app` 与 DMG 输出到 `dist/<版本>-<build>/`。 | 保留上游签名、公证与安全修复，同时保留工程生成、双产物及 DMG 校验；不要以“打包完成”的日志代替实际文件和版本核验。 |
| 终端与 SFTP 路径导航：`68a4ef0` | `TerminalSurface.swift` 菜单复用 OSC 7 cwd；`AppModel.swift` 复用同主机文件标签；`FileBrowser.swift` 增加上传左侧编辑按钮、回车跳转、Escape/xmark 取消。支持绝对、相对和家目录路径；错误保留路径、列表、选择及返回历史。`RemoteFS.swift` 校验目录类型和访问权限。 | 保留上游终端及认证流程，再接入当前目录导航；未收到 cwd 时已有文件标签保留目录、新标签加载家目录。目录加载必须独立执行，不能放在可选回调的实参中。路径作为字面数据传递，不执行 shell 输入；本仓库 OSC 7 钩子直接上报 `$PWD`，不能擅自把 `%20` 当空格解码。 |
| 导航回归：`68a4ef0` | `TermoTests/SFTPNavigationTests.swift` 的 6 项测试：无回调真实导航入口、路径解析、无效输入、错误保留状态、菜单作用域和 OSC 路径。新增 UI 文案及英文翻译维护在 `Localizable.xcstrings`。 | 改上游接口时同步适配测试；对 String Catalog 按 key 合并，保留英文翻译，不用整文件覆盖。 |
| 构建号与发布记录：`e379800`、`b393dff`、个人标签 | 版本号只在 `Termo/Info.plist` 维护；个人版 build 35 → 36 → 37。`README.md`、`README.zh-CN.md`、`CHANGELOG.md` 同步功能与构建说明。 | 同步上游版本时重新选择大于已发布个人构建号和引入的上游构建号的新 build；不要降级 build。上游更新日志与个人发布记录分别保留，不重复宣称已经发布的功能。 |

## 同步与冲突处理

1. 先检查工作区、保留正在进行的工作；在 `codex/` 同步分支上操作，不在未提交的工作区开始合并。
2. 只读取上游代码，并记录候选提交：

   ```bash
   git fetch https://github.com/icloudza/termo.git main
   git rev-parse FETCH_HEAD
   git diff --stat ac788250967598c0ceb6543ac82b7f8ea13d230b FETCH_HEAD
   ```

3. 将上游差异与上表逐项交叉核对，再选择 merge 或 rebase。已发布且共享的 `main` 默认 merge，避免改写发布提交；未发布的独立工作分支可 rebase。
4. 对冲突同时读取基线、个人版本、上游版本，按“上游修了什么 / 个人行为要保留什么 / 最终共同接口是什么”写出合并方案。安全与连接修复优先，但不能无声丢失个人功能；无法兼容时先明确取舍，再完成合并。
5. 合并后检查 `git diff --check` 与未合并路径，生成工程并验证：

   ```bash
   xcodegen generate
   xcodebuild -scheme Termo -configuration Release build
   xcodebuild -scheme Termo-MAS -configuration ReleaseMAS build
   xcodebuild -scheme Termo -configuration Debug -destination 'platform=macOS,arch=arm64' test
   ```

   无项目签名证书时可使用 `CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO` 做本地验证；正式分发签名另行核对。
6. 实机核对 SFTP 目录传输、终端当前目录跳转、地址编辑、无权限/不存在目录、返回历史、深浅主题，以及默认下载与自选目录。
7. 更新本文件的最后同步基线、每项差异的状态与适配提交；被上游等价实现替代的条目标明原因并删除重复代码。更新用户文档、翻译与日志，只推送 `gbandszxc/termo`。

## 当前验收记录

- build 37：Release 与 ReleaseMAS 编译通过；21 项测试通过（目录传输 15 项、导航 6 项）。
- 路径导航源码复核发现的默认回调跳过加载、浅色提示文字对比不足均已修复。
- 本次未做真实远端操作；界面自动化服务超时，深浅主题截图未验证。后续同步不能把这两项视为既有实机验收证据。
