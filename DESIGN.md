---
name: Termo
description: 原生 macOS 远程运维工作台——安静的驾驶舱
colors:
  # ── 深色主题（默认观感，以下为规范值）──
  base: "#1e1e1e"            # 工作区 / 终端 / 编辑器底
  mantle: "#252526"          # 侧栏 / 标签栏 / 弹层底
  crust: "#333333"           # 活动栏（最深一档中的最亮）
  surface0: "#37373d"        # 浮起表面 / 输入底
  text: "#cccccc"
  text-bright: "#ffffff"
  subtext: "#9d9d9d"
  overlay: "#7a7a7a"         # 图标默认态 / 占位符
  mauve: "#569cd6"           # 强调蓝（唯一 accent）
  green: "#4ec9b0"           # 成功 / 流畅延迟
  yellow: "#d7ba7d"          # 警告 / 未保存脏点
  red: "#f14c4c"             # 危险 / 高延迟
  term-selection: "#264f78"
  term-caret: "#aeafad"
  # ── 浅色主题（跟随系统时的另一套完整取值）──
  base-light: "#f5f6f9"
  mantle-light: "#edeef2"
  crust-light: "#e6e8ed"
  surface0-light: "#dfe2e9"
  text-light: "#2e3440"
  text-bright-light: "#1a1d24"
  subtext-light: "#6b7280"
  overlay-light: "#9aa0ac"
  mauve-light: "#3b82f6"
  green-light: "#10b981"
  yellow-light: "#f59e0b"
  red-light: "#ef4444"
  term-selection-light: "#bfdbfe"
  term-caret-light: "#3b82f6"
typography:
  title:
    fontFamily: "SF Pro (system, -apple-system)"
    fontSize: "15px"
    fontWeight: 500
    lineHeight: 1.3
  headline:
    fontFamily: "SF Pro (system)"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "SF Pro (system)"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.35
  secondary:
    fontFamily: "SF Pro (system)"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.35
  caption:
    fontFamily: "SF Pro (system)"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.3
  label:
    fontFamily: "SF Pro (system)"
    fontSize: "11px"
    fontWeight: 500
    letterSpacing: "normal"
  mono-terminal:
    fontFamily: "JetBrainsMono Nerd Font → MesloLGM/MesloLGS Nerd Font → Hack → FiraCode Nerd Font → system monospaced（回退链）"
    fontSize: "13px"
    fontWeight: 400
  mono-inline:
    fontFamily: "SF Mono (system, design: .monospaced)"
    fontSize: "12px"
    fontWeight: 400
rounded:
  xs: "4px"     # 标签关闭钮等微型热区
  sm: "6px"     # 菜单选项 / 小图标底 / 复选框 5px
  md: "7px"     # 按钮 / 标签 chip / Tooltip
  lg: "8px"     # 输入框 / 列表行 / 主机卡（使用最多）
  xl: "9px"     # 分段控件 / 活动栏按钮（38×38）
  card: "12px"  # 大卡片 / 监控图卡
  dialog: "14px" # 对话框 / 设置面板
spacing:
  xs: "4px"
  sm: "6px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  "2xl": "20px"
components:
  button-primary:
    backgroundColor: "{colors.mauve}"
    textColor: "#ffffff"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "16px 7px"
  button-secondary:
    backgroundColor: "#2b2b2b"
    textColor: "{colors.subtext}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "16px 7px"
  input-text:
    backgroundColor: "#292929"
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: "11px 8px"
  segment-selected:
    backgroundColor: "#393939"
    textColor: "{colors.text}"
    typography: "{typography.secondary}"
    rounded: "{rounded.sm}"
    padding: "10px 6px"
  dialog-card:
    backgroundColor: "{colors.base}"
    textColor: "{colors.text}"
    rounded: "{rounded.dialog}"
    padding: "20px"
    width: "340px"
  toggle-on:
    backgroundColor: "{colors.mauve}"
    rounded: "9999px"
    size: "38px 22px"
---

# Design System: Termo

## Overview

**Creative North Star: "安静的驾驶舱"（The Quiet Cockpit）**

Termo 的界面是一间深夜机房旁的驾驶舱：仪表都在，但没有一块仪表在抢戏。工作区永远是最暗（深色）或最亮（浅色）的那块"风挡玻璃"，光从四面落进去；强调蓝 `#569cd6` 是舱内唯一的信号灯——它只指示"可以操作"与"正在发生"，从不参与装饰。信息密度对齐专业工具（VS Code 的骨架、Xcode 的克制、Ghostty 的终端观感），密度本身不是噪音，无序才是。

谱系与命名：颜色变量沿用 Catppuccin 词汇（`crust / mantle / base / surface0 / mauve`），但深色取值实际是 VS Code 经典配色（`#1e1e1e / #252526 / #333333`）；浅色主题换用 Tailwind 500 号色板（`blue-500 / emerald-500 / amber-500 / red-500`）。所有界面自绘 SwiftUI，系统原生控件外观（focus ring、原生开关、原生弹窗）一律禁用并替换为自定义实现。

**Key Characteristics:**

- 四级表面梯度 + 半透明叠加层（`fill(opacity)`）表达一切层级，几乎不用阴影
- 唯一强调色双主题切换：深色 `#569cd6`（沉稳）→ 浅色 `#3b82f6`（清新）
- 交互反馈全部走 `easeOut 0.12–0.18s` 短过渡，无弹簧、无大动画
- 状态永远"颜色 + 文字/图标"双通道（延迟徽章、在线点、脏标记）
- 圆角语言收敛在 6/7/8/14 四档，对话框最大（14px），微型热区最小（4px）

## Colors

调色板是"两级灰阶 + 一个信号蓝 + 三枚语义色"：灰阶负责空间，蓝色负责动作，语义色只报告状态。

### Primary
- **Signal Blue（信号蓝）**（深色 `#569cd6` / 浅色 `#3b82f6`）：唯一强调色。用途：主按钮填充、选中态底（10–16% 透明度叠底）、聚焦描边、可点击图标、链接文字、开关选中、活动栏选中图标。它是"可操作"的代名词。

### Secondary（语义色——只报告，不装饰）
- **Verdant（青翠）**（深色 `#4ec9b0` / 浅色 `#10b981`）：成功、在线主机呼吸点、流畅延迟（<80ms）、"已复制"确认。
- **Amber（琥珀）**（深色 `#d7ba7d` / 浅色 `#f59e0b`）：警告、延迟较高（80–499ms）、编辑器未保存脏点、有后台任务的托盘徽标。
- **Alarm（警报红）**（深色 `#f14c4c` / 浅色 `#ef4444`）：破坏性操作确认按钮、延迟很高（≥500ms）、错误信息、断连提示。

### Neutral（四级表面梯度）
- **Base（墨色）**（深色 `#1e1e1e` / 浅色 `#f5f6f9`）：工作区、终端底、编辑器底、对话框卡底。内容发生的地方。
- **Mantle（面板灰）**（深色 `#252526` / 浅色 `#edeef2`）：侧栏、标签栏、下拉弹层与 Tooltip 底。
- **Crust（外壳灰）**（深色 `#333333` / 浅色 `#e6e8ed`）：活动栏（最外侧边条）。
- **Surface0（浮层灰）**（深色 `#37373d` / 浅色 `#dfe2e9`）：浮起的次级表面。
- **Text（正文）**（`#cccccc` / `#2e3440`）、**TextBright（高亮）**（`#ffffff` / `#1a1d24`）：标题与主文本。
- **Subtext（次文本）**（`#9d9d9d` / `#6b7280`）：次要说明、次要按钮文字。
- **Overlay（隐文本）**（`#7a7a7a` / `#9aa0ac`）：默认态图标、占位符、分组头、空状态插图。

**The 光落工作区 Rule.** 表面梯度的方向永远把"光"导向工作区：深色下 crust(亮)→mantle→base(暗)，浅色下 base(亮)→mantle→crust(暗)。任何新面板都必须落进这四级梯度，不许发明第五档底色。

**The 信号灯 Rule.** 强调蓝在任一屏占比 ≤10%。选中底、聚焦框、主按钮是它的全部舞台；列表、图表、正文不得大面积使用。语义色（绿/黄/红）只允许以小徽章、文字、细线条出现。

### 半透明叠加系统（`Pal.fill(opacity)`，全项目通用的"第五原色"）
深色用白色叠加、浅色用黑色叠加（×1.4 系数），保证双主题同构：
- `fill(0.04–0.08)`：hover 底、标签 chip 选中底、卡片底
- `fill(0.10–0.14)`：按下/选中强化、搜索框底
- `fill(0.12)`：输入框常态描边（聚焦时换 mauve 1.5px）
- `fill(0.15–0.16)`：列表行选中（mauve 透明度版）
- 强调色透明底规范：`mauve.opacity(0.10–0.16)`（选中项、活动栏选中、Tint 按钮）

### 终端调色板
深色终端使用 VS Code ANSI 16 色（`#cd3131 / #0dbc79 / #e5e510 / #2472c8 …`），底 `#1e1e1e`、字 `#cccccc`、光标 `#aeafad`、选区 `#264f78`；浅色终端为经典 VGA 系（`#00bc00 / #949500 …`），光标即信号蓝。

## Typography

**Display/Body Font:** SF Pro（系统栈，SwiftUI `.system(size:weight:)`，不引入自定义字体文件）
**Terminal Font:** 用户可选 Nerd Font，回退链 JetBrainsMono Nerd Font → MesloLGM/LGS Nerd Font → Hack → FiraCode Nerd Font → 系统等宽（默认 13px，可在设置调节）
**Inline Mono:** SF Mono（`.monospaced` design）——用于路径、ID、数值、代码预览等行内等宽场景

**Character:** 纯系统字体的工具美学——层级完全靠字号（13 > 12 > 11 三档主力）和字重（regular / medium / semibold）表达，几乎不用 bold；行内等宽字体是"这是机器的数据"的排版信号。

### Hierarchy
- **Headline**（16–18px, semibold）：设置页章节题（"通用"）、空状态大标题。
- **Title**（15px, medium/semibold）：侧栏面板标题（"主机"）、对话框标题。
- **Body**（13px, regular）：输入框、按钮、列表行主文字、说明正文。绝对主力。
- **Secondary**（12px, regular）：标签 chip、分段控件、次要按钮、说明行。
- **Caption**（11px, regular）：主机 IP、延迟徽章、分组头、元信息。
- **Label**（11px, medium）：可点击的小按钮文字（"添加主机"）、托盘徽标。
- **Mono**（12–13px）：终端、代码编辑器、路径/命令值。

**The 三档 Rule.** UI 文本只在 11/12/13px 三档里选；往上只有标题（15/16），往下只有徽标（9–10px，仅图标和单字符）。禁止为强调而放大正文——强调用字重和颜色。

## Layout

单窗口三栏骨架（对齐 VS Code / Xcode 的工具布局）：

```
┌──────┬──────────┬────────────────────────────┐
│      │ 主机   + │ ⌘ tab  tab  tab          + │ ← 标签栏（mantle，chip r7）
│ 活动 │ 搜索框…  ├────────────────────────────┤
│ 栏   │          │                            │
│ 76pt │ 侧栏     │      工作区 / 终端          │ ← 风挡（base，全 bleed）
│ crust│ 224pt+   │                            │
│      │ mantle   │                            │
│ ⚙    │ 本地终端  │                            │
└──────┴──────────┴────────────────────────────┘
```

- **活动栏**固定 76pt，图标按钮 38×38、间距 6，顶部为系统红绿灯留 52pt；底部是托盘中控与设置。
- **侧栏**默认 224pt，可拖拽调宽（最小 224）；内边距水平 12–14；主机行内边距 8×9、行距 4。
- **标签栏**高约 34pt，chip 间距 6，不截断标题、超出横向滚动。
- **设置面板**固定 720×480 居中 sheet，左导航 176pt，右侧表单行距约 30。
- **对话框**固定宽 340，内边距 20。
- **间距节奏**：4 / 6 / 8 为主（紧凑工具密度），区块间 14–20；图标与文字间距 7–9。
- 全窗口 `hiddenTitleBar` + `fullSizeContentView`，内容顶到窗口上沿，窗口底色预热为主题 base（消除冷启动白闪）。

## Elevation & Depth

**平层 + 叠加**体系：深度几乎完全由四级表面梯度和半透明叠加层（`fill(opacity)`）表达，阴影是稀缺资源，只属于"真正浮起的东西"。

### Shadow Vocabulary
- **Dialog Lift**（`black 30%, r20, y8`）：居中对话框/任务弹窗——唯一的大阴影。
- **Pill Lift**（`black 25%/12%, r1.5, y1`）：分段控件选中的小药丸（深/浅不同强度）。
- **Knob Lift**（`black 20%, r1, y0.5`）：开关圆形旋钮。
- **Tooltip**：无阴影，用 `fill(0.10)` 1px 描边替代（浮动面板本身不带影）。

**The 描边即边界 Rule.** 卡片与输入框不靠阴影区分于背景，靠 `fill(0.08–0.12)` 的 1px 描边；弹层（下拉、Tooltip）靠 mantle 实底色区分。阴影只给悬浮物，不给容器。

## Shapes

圆角收敛为七档，按"越小越瞬时、越大越对话"分布：

| 档位 | 值 | 使用 |
|---|---|---|
| xs | 4px | 标签关闭钮热区 |
| sm | 5–6px | 复选框、菜单选项、小图标底、分段药丸 |
| md | 7px | 按钮、标签 chip、Tooltip、搜索框内芯 |
| lg | 8px | **输入框、下拉、列表行、主机卡（默认档）** |
| xl | 9px | 分段控件容器、活动栏按钮 |
| card | 12px | 大卡片、监控图卡 |
| dialog | 14px | 对话框、设置面板（最"浮"的东西圆角最大） |

开关是唯一 Capsule（38×22）；托盘徽标、状态药丸用 Capsule。分隔线一律 1px、`fill(0.06–0.10)`。图标体系为 SF Symbols（11–16px 主力）+ Nerd Font 发行版 Logo（单色、不带品牌色）+ 自绘文件类型图标。

## Components

### 按钮
- **Primary**：mauve 实底、白字 13px medium、r7、内距 16×7；禁用 = 同底 40% 透明度。hover 无变色（pointerCursor 手型即可），确认对话框中 busy 时降至 0.6 透明度 + 转圈。
- **Secondary**：`fill(0.06)` 底、subtext 字，其余同 Primary。
- **Tint 图标钮**（侧栏 + 号、导入等）：裸 SF Symbol，mauve 或 overlay 着色，无底无框，hover 提亮 + 手型光标。
- **破坏性确认**：red 实底替代 mauve，其余同 Primary。

### 输入框
- **样式**：`fill(0.05)`（深）/ 白（浅）底、r8、内距 11×8、`fill(0.12)` 1px 描边、13px 正文。
- **聚焦**：mauve 描边 1.5px，`easeOut 0.12s` 过渡；**原生 focus ring 全局禁用**。
- 密码框带小眼睛（20×20 热区）；多行编辑器等宽字体、固定 80 高；下拉 = 同款输入外观 + chevron（开合旋转 180°），弹层 mantle 实底 r? 无、内衬 6、选项行 r6、hover `fill(0.08)`、选中 mauve 10% 底 + checkmark；可搜索下拉顶部内嵌搜索框；步进器 = 输入外观 + 30×30 减/加钮 + 1px 竖分隔。

### 开关与复选
- **Toggle**：38×22 Capsule，选中 mauve 实底，未选 `fill(0.18)`；18px 白旋钮带微阴影，`easeOut 0.16s`。
- **Checkbox**：18×18 r5，选中 mauve 底 + 白勾 10px bold，未选 `fill(0.10)` 底 + `fill(0.22)` 描边。

### 标签栏（Tab Chips）
- chip：r7，内距 左10/右6/垂直5，图标 11px + 标题 12px（`fixedSize` 不截断）；选中 `fill(0.08)` 底、text 色；hover `fill(0.04)`；关闭钮 16×16 r4 仅 hover/active 显示。
- 编辑器标签未保存：7px 黄圆点 ↔ hover 换关闭钮。

### 活动栏按钮
- 38×38、r9、图标 16px；选中 = mauve 图标 + `mauve 16%` 底；hover = subtext 图标 + `fill(0.08)` 底；默认 overlay 图标。

### 列表行（主机/密钥/片段）
- 行内距 8×9、行距 4、r8；选中 = `mauve 15%` 底（`easeOut 0.18s` 淡入）；hover = `fill(0.05)`（0.12s）；主文字 13 text + 副文字 11 subtext（IP 等）；右缘延迟徽章 11px 语义色。脱敏开启时整行高斯模糊 r3.5。

### 卡片与对话框
- **监控卡/信息卡**：r12（概览快捷入口卡 r8、选中入口 mauve 14% 底 + mauve 图标），`fill(0.03–0.06)` 底或描边卡，内距 12–14；进度条 = 细圆角条（信号蓝/语义色）。
- **居中对话框**：`black 35%` 全屏遮罩；卡片 base 实底 r14、`fill(0.08)` 描边、Dialog Lift 阴影、内距 20、宽 340；标题 15 semibold、正文 13 subtext；按钮右对齐，间距 10。
- **Popover**（下拉/预览）：mantle 实底、内衬 6–8、内容宽度 ≥180。

### Tooltip（签名组件）
自绘全局 Tooltip（独立无边框 NSPanel，0.45s 延迟，永不抢焦点）：mantle 实底 r7、`fill(0.10)` 1px 描边、无阴影、11.5px 文字、内距 9×5、最大宽 440，光标右下弹出并自动翻面防裁切。

### 托盘与呼吸灯（签名组件）
菜单栏常驻图标；端口转发等活动进行时呈"呼吸灯"节奏；后台任务弹窗从活动栏底部中控统一管理（进行中计数、清理已完成）。

### 状态徽章
延迟等级三档（流畅/延迟较高/延迟很高）以"语义色文字 + ms 数值"呈现；在线主机行首 7px 绿点；全部双通道（颜色 + 文字/位置），不裸靠色相传义。

## Do's and Don'ts

### Do:
- **Do** 新面板从四级表面梯度（base/mantle/crust/surface0）里选底色，深浅两套同时校验。
- **Do** 用 `fill(0.04–0.12)` 表达 hover/选中/描边——这是本系统的通用语法。
- **Do** 所有交互反馈用 `easeOut 0.12–0.18s`；选中态淡入、chevron 旋转、聚焦描边皆如此。
- **Do** 状态用"颜色 + 文字"双通道（延迟徽章、脏点 + 关闭钮互换）。
- **Do** 行内等宽字体（SF Mono 12px）呈现路径、命令、数值——机器的数据用机器的字体。
- **Do** 可点击元素一律 pointerCursor 手型光标 + tooltip（0.45s 延迟自绘样式）。

### Don't:
- **Don't** 使用系统原生控件外观：原生 focus ring、原生开关、原生菜单/弹窗样式一律替换为 Themed* 组件。
- **Don't** 让强调蓝超过一屏的 ~10%，或把它用作装饰/图表色。
- **Don't** 引入第五档底色或发明新圆角档位（现有 4/5/6/7/8/9/12/14 已覆盖全部场景）。
- **Don't** 给容器加阴影——阴影只属于对话框、分段药丸、开关旋钮三类悬浮物。
- **Don't** 大胆放大字号做强调（正文永远 11/12/13 三档）。
- **Don't** 在浅色主题里直接复用深色取值或反之——两套色板是成对设计的（含终端 ANSI）。
- **Don't** 用纯白/纯黑做大面积底色（浅色工作区是 `#f5f6f9` 降眩白，不是 `#ffffff`）。
