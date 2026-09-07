# 资产目录（美术资源由你导入）

所有资源按下面的命名约定放入对应子目录，项目运行时会**自动加载**。
资源缺失时程序会**回退到占位图形**，不会报错、不会崩溃——你可以随时把文件放进来自动生效。

## player/ — 主角行走动画（每方向 2 帧，无待机）

| 文件名 | 含义 |
|--------|------|
| `walk_down_0.png` / `walk_down_1.png` | 向下走（面向镜头） |
| `walk_up_0.png` / `walk_up_1.png` | 向上走（背对镜头） |
| `walk_left_0.png` / `walk_left_1.png` | 向左走 |
| `walk_right_0.png` / `walk_right_1.png` | 向右走 |

- 建议 **32×32**（或 16×16）像素、透明背景 PNG；左右方向各自独立贴图。
- 缺某一帧不会导致整套动画消失（缺第 2 帧时自动复用第 1 帧，该方向静止），但建议把 8 帧补齐。
- **显示缩放**：`scripts/player.gd` 的 `@export display_scale`（默认 2.0，≈ 64px，比物品栏格子 56px 大），在 Inspector 里可自行调整。

## npc/ — NPC 待机动画（2 帧）

| 文件名 | 含义 |
|--------|------|
| `idle_0.png` | NPC 待机第 1 帧 |
| `idle_1.png` | NPC 待机第 2 帧 |

- 建议 **32×32** 像素、透明背景，与主角行走帧同尺寸；缺失回退紫色占位方块。
- NPC 有物理碰撞体（layer 2），玩家撞上走不过去；显示缩放同主角（`scripts/interactable.gd` 的 `@export display_scale` 默认 2.0，保持一致）。

## portraits/ — 对话立绘（单立绘位：随说话者切左右，NPC 左 / 汐右）

### NPC（左位，单表情，放 `portraits/NPC/` 下）
- `elder.png` — 长老（第二章「长老居所」）
- `ajie`（阿姐 / 第一章的前辈人鱼）—— **暂复用 `elder.png`**；后续想换独立立绘时补 `ajie.png` 并在 `scripts/game.gd` 的 `PORTRAITS["ajie"]` 里改路径

### 成年汐（右位，7 表情，放 `portraits/xi/` 下）

| 文件名 | 表情 |
|--------|------|
| `neutral.png` | 普通 |
| `happy.png` | 开心 |
| `surprised.png` | 惊讶 |
| `sad.png` | 难过 |
| `speechless.png` | 无语 |
| `pain.png` | 痛苦 |
| `expectant.png` | 期待 |

### 幼年汐（右位，3 表情，放 `portraits/xi_young/` 下）

| 文件名 | 表情 |
|--------|------|
| `expectant.png` | 期待 |
| `happy.png` | 开心 |
| `confused.png` | 疑惑 |

> 新增 NPC：在 `scripts/game.gd` 的 `DIALOGUES` 与 `PORTRAITS` 加同名 key，并放同名 PNG。

> **立绘不拉伸 + 调位置/尺寸**：在 `Main` 节点 Inspector 里改 `portrait_size`（显示框，保持比例不拉伸）、`npc_portrait_position`（NPC/长老立绘位置，左）、`xi_portrait_position`（汐立绘位置，右）。

## ui/ — 界面背景（全部九宫格拉伸，缺失回退占位）

| 文件名 | 用途 | 九宫格边框 |
|--------|------|-----------|
| `dialogue_box.png` | 对话框背景 | 约 24px |
| `item_bar.png` | 物品栏背景 | 约 24px |
| `item_slot.png` | 物品栏单格底图 | 约 8px |
| `collect_bg.png` | 右上角收集度面板 | 约 24px |
| `start_button.png` | 开始界面「开始」按钮 | — |

> 九宫格（ninepatch）边框要留够、中心透明或纯色，任意拉伸不变形；边框大小要和 `scripts/main.gd` 里的 `*_MARGIN` 常量一致（目前对话框/物品栏/收集度 = 24px，单格 = 8px）。

> **调整「开始」按钮大小 / 位置**：在 `scripts/start.gd` 的 `@export` 变量里改 `start_button_size`（大小）和 `start_button_position`（位置），或选中场景里的 Start 节点在 Inspector 里直接调。

## fonts/ — 字体

| 文件名 | 用途 |
|--------|------|
| `pixel.ttf` | 游戏内 UI / 对话（黑字） |
| `pixel_1.ttf` | 开始界面黑屏开场的逐句白字（**暂未导入**，缺失时自动回退 `pixel.ttf`） |

## backgrounds/ — 场景背景

| 文件名 | 用途 |
|--------|------|
| `start.png` | 开始界面全屏背景 |
| `coral.png` | 珊瑚浅滩 |
| `ritual.png` | 仪式浅滩 |
| `deep.png` | 深海 |

> **场景标题卡**：进入每个场景前，画面正中会浮现该章标题（浅滩 / 长老居所 / 深海）约 1 秒后渐隐。标题文字在 `scripts/game.gd` 的 `CHAPTER_TITLES` 里改。

## items/ — 饰线（道具）贴图

| 文件名 | 含义 |
|--------|------|
| `line_transparent.png` | 透明饰线 |
| `line_colorful.png` | 彩色饰线 |
| `line_thick.png` | 粗饰线 |
| `line_faded.png` | 褪色丝线残段 |
| `shell_container.png` | 贝壳容器（第二章，按 F 使用后触发内心 OS 并清空该格） |

> 缺失时，物品栏格子和场景里的道具会回退为纯色方块。

## spots/ — 隐藏点（需要探索/搜索的东西）

| 文件名 | 含义 |
|--------|------|
| `seaweed_1.png` | 海藻 1（珊瑚浅滩左侧，藏透明饰线） |
| `seaweed_2.png` | 海藻 2（右侧，藏粗饰线） |
| `seaweed_3.png` | 海藻 3（下方，藏褪色丝线残段·伏笔） |
| `shell.png` | 贝壳（藏彩色饰线） |

> 建议 **约 48×56** 像素、透明背景；缺失时回退为纯色多边形（海藻绿 / 贝壳米色）。被玩家搜索「拨开」后会自动变淡。

> **想移动 / 缩放海藻、贝壳、NPC、玩家出生点**：现在都是 `scenes/world_coral.tscn`（及 `world_ritual.tscn` / `world_deep.tscn`）里的**真实节点**，直接在 Godot 编辑器 2D 视口里用鼠标拖拽位置、改 `size` 即可，不用改代码。地图边缘的 4 条碰撞墙在 `scenes/main.tscn` 里，同样可拖拽。

## 如何改对话内容 & 每句话对应立绘

对话和立绘都在 `scripts/game.gd` 里改，不用动引擎：

1. **对话内容**：`DIALOGUES` 是「对话组 id → 台词数组」。每句台词是一个字典：
   `{"speaker": "说话者", "expr": "表情", "text": "台词"}`
   - `speaker` 决定用谁的立绘、站哪一侧（`xi` / `xi_young` 在右，其余 NPC 在左）。
	 - 特殊值 `"narrator"` = 旁白：不显示立绘、不显示人名，文字全宽居中。
	 - 对话框里人名独占一行、更大更粗，显示名由 `SPEAKER_NAMES` 映射（幼年汐 / 汐 / 长老 / 阿姐）。
   - `expr` 决定该说话者的哪张表情。
   - `text` 是屏幕上显示的台词。

2. **每句话对应立绘**：`PORTRAITS` 是「说话者 → {表情 → png 路径}」。
   改一句话的立绘 = 同时改这句的 `speaker`（用谁）和 `expr`（哪张脸）。
   例如让汐说一句「惊讶」：
   `{"speaker": "xi", "expr": "surprised", "text": "……怎么会这样？"}`

3. **加新表情 / 新 NPC**：在 `PORTRAITS` 给对应 `speaker` 加 `expr: 路径`，并把 PNG 放进 `portraits/` 对应目录（见上文）。
