# HANDOFF — 《Bound to Grow / 汐缠》开发交接文档

> 最后更新：2026-09-06
> 本文档记录当前任务状态，供跨会话 / 换人继续开发时快速对齐。

---

## 一、现在在做什么任务

对《Bound to Grow》（Godot 4.7.2 · GL Compatibility · 1280×720 · canvas_items 拉伸）原型做六轮改造，依据 **`request.md`（8 条）**、**`new.md`（6 条）**、**`update.md`（4 条）**、**`update_1.md`（10 条）**、**`question.md`（6 条）** 以及**第六轮的用户口述需求**。各轮需求**均已实现并验证通过（`get_debug_output` 返回 `errors: []`）**。

当前阶段：**第六轮（本次）——「立绘缺失 + NPC 缺失 + 立绘不拉伸 + 立绘可改位置」修复**。用户原话「已更新资产，但是立绘缺失，npc缺失，立绘不要拉伸并且我能够改位置」。核心背景：主角是人鱼少女「汐」，游戏隐喻海洋塑料污染。海藻 / 贝壳 / NPC 已是 `world_*.tscn` 里的真实节点（编辑器可拖拽），**任何美术资产缺失都回退占位图形，不崩溃**。

第五轮：按 `question.md`（6 条）实现并验证——①玩家大小可调（比物品栏大）且对话中禁移动、②第一章台词补全括号动作描写、③开场文字改淡入淡出（1.5s/句）、④「已获得 xx」改玩家头顶浮字、⑤NPC 待机动画 + 碰撞体（大小与玩家一致）、⑥立绘撤回到第三轮 340×460。

第六轮（本次）：修复四个问题——①「立绘缺失」= 两个立绘文件名带笔误（`happy (4).png`、`happy .png`），重命名对齐代码规范名；②「NPC 缺失」= NPC 待机动画此前放错目录、长老立绘缺图（用户已自行移到 `assets/npc/` 并补 `elder.png`）；③「立绘不拉伸」= `STRETCH_SCALE` 改 `STRETCH_KEEP_ASPECT_CENTERED`；④「可改位置」= 加 3 个 `@export` 坐标/尺寸变量，Inspector 里改。

---

## 二、已经做完的

### `request.md`（第一轮 8 条）

| 项 | 状态 | 说明 |
|----|------|------|
| 对话框增高到 1/3 | ✅ | `dialogue_panel` = `(120,440)` 尺寸 `1040×240`，底边 y=680。 |
| 立绘放大下移 | ✅ | 已放大到 `340×460`（见 new.md 第 1 条，二次放大）。 |
| 三场景数据 + 程序化生成 | ✅ | `game.gd` 的 `SCENES`（coral/ritual/deep）；`main.gd` 的 `_load_scene`/`_spawn_spot`/`_spawn_npc`。 |
| 移除背包 → 5 格物品栏 | ✅ | 删除 `toggle_inventory`/`inventory_open`/`inventory_toggled`；新增 `selected_slot` + `select_slot()` + `selection_changed` 信号 + `slot_1..5` 键位；底部居中 5 格，选中高亮 alpha 1.0、未选 0.45。 |
| 收集度右上角 | ✅ | `collect_panel` 九宫格背景，显示「饰线 N / 3」，位置 `(1000,16)`。 |
| 开始界面（独立场景） | ✅ | `scenes/start.tscn` + `scripts/start.gd`，`project.godot` 主场景指向 `start.tscn`。 |
| 操作提示左上角，拾取后消失 | ✅ | `tutorial_label`；拾取后（`inventory_changed`）隐藏。 |
| 像素字体 + 全黑 | ✅ | `main.gd` `_setup_font()` 加载 `res://assets/fonts/pixel.ttf`，缺失回退 `SystemFont`；Label 字体色统一 `Color(0,0,0)`。 |

### `new.md`（第二轮 6 条）

| 项 | 状态 | 说明 |
|----|------|------|
| 立绘再放大、再下移 | ✅ | 尺寸 `340×460`；NPC 左 `(30,240)`、汐右 `(910,240)`，底边对齐对话框底。 |
| 物品栏背景/格子/右上角收集度用 ninepatch | ✅ | `main.gd` `_ninepatch_stylebox()`；`DIALOGUE_BOX_MARGIN=24`、`SLOT_MARGIN=8`；缺失回退 `StyleBoxFlat` 纯色。 |
| 场景资产 + 开始按钮资产导入路径 | ✅ | 全部写进 `assets/README.md`；`start.gd` 按钮有 `start_button.png` 用图标、否则回退文字「开始」。 |
| 提示一次性全部消失 | ✅ | `game.gd` 新增 `hints_dismissed` 标志，`pickup_item()` 置 true；`main.gd` `_process` 与 `_on_inventory_changed` 据此清空/隐藏提示。 |
| 饰线资产导入路径 | ✅ | `game.gd` `ITEM_TEXTURES`（line_transparent/colorful/thick/faded），缺失回退纯色方块。 |
| 场景按进度切换（文字放大 3s） | ✅ | `SCENE_ORDER := ["coral","ritual","deep"]` + `next_scene_id()`；集齐 3 样 → `chapter_complete` → `complete_label` 从 scale 0.4 tween 到 2.0（3 秒）→ `_load_scene(下一场景)`。 |

### 额外（用户追问）

| 项 | 状态 | 说明 |
|----|------|------|
| 隐藏点资产导入 | ✅ | `game.gd` `SPOT_TEXTURES`；`hiding_spot.gd` 有贴图用 Sprite2D、否则回退纯色多边形。 |
| 三张不同海藻 | ✅ | `seaweed_1/2/3` + `shell` 四个映射；珊瑚浅滩 4 个隐藏点分别指向对应 `type`。 |
| 单立绘位（随说话者切左右） | ✅ | `_on_dialogue_line` 按 `speaker` 判断：`xi`/`xi_young` 右，其余 NPC 左。 |
| 空格搜索键 | ✅ | `KEYS.search = KEY_SPACE`。 |

### `update.md`（第三轮 4 条）

| 项 | 状态 | 说明 |
|----|------|------|
| 海藻/贝壳/NPC 位置大小可调 | ✅ | `hiding_spot.gd`/`interactable.gd` 加 `@export size`；`game.gd` `SCENES` 加 `pos`/`size` 字段，改数字即可移动/缩放，默认和物品栏格子（56px）差不多大。 |
| 修复行走动画不显示 | ✅ | `player.gd` 逐方向容错加载，缺某一帧不再整套回退；根因是缺 `walk_right_1.png`（现只剩 7 帧，代码已兜住）。 |
| 修复开始界面背景不显示 | ✅ | 上一轮已把 `background/` 目录统一为 `backgrounds/`，本轮复核 `errors: []`。 |
| 开始按钮大小位置可调 | ✅ | `start.gd` 加 `@export` `start_button_size`/`start_button_position`，默认 `240×240` 居中，Inspector 可改。 |
| 操作提示每行一条 | ✅ | `main.gd` 左上角提示改 5 行（WASD/E/F/空格/1-5 各占一行），附近提示下移。 |

### 清理（本轮）

- 删除 `scripts/exit.gd`（死代码，无引用）。
- 删除根目录冗余 `pixel.ttf`（代码用 `assets/fonts/pixel.ttf`）。
- 重命名 `portraits/xi_young/happy .png` → `happy.png`（去掉文件名末尾多余空格）。

### `update_1.md`（第四轮 10 条）

| 项 | 状态 | 说明 |
|----|------|------|
| 开始按钮去灰边/高亮 | ✅ | `start.gd` 按钮三态 stylebox 覆盖 `StyleBoxEmpty`，只显示图标。 |
| 编辑器拖拽 player/海藻/贝壳/NPC | ✅ | 场景对象移到 `scenes/world_*.tscn` 真实节点；`game.gd` `SCENES` 精简为 `{name, background, world}`；出生点改读 `PlayerSpawn` 节点。 |
| 行走动画 3 帧/秒 | ✅ | `player.gd` 加 `@export anim_fps=3.0`。 |
| 物品栏选中反色 | ✅ | 选中 alpha 0.45、未选 1.0（原来是选中 1.0/未选 0.45）。 |
| 立绘 200×200 不裁剪 | ✅ | `main.gd` `@export portrait_size` + 最近邻过滤；上下不对齐对话框、左右不遮文字；源图 256×256 不裁。 |
| 地图边缘碰撞墙 | ✅ | `main.tscn` 4 条 `StaticBody2D`（layer 2），编辑器可拖。 |
| 空海藻内心 OS + 二次浮字 | ✅ | `hiding_spot.gd` `empty_monologue_id`；首次搜索播 OS、再次搜索头顶浮字「这里已经搜索过了」。 |
| 黑屏开场逐句文字 | ✅ | `start.gd` 点按钮后全屏黑 + 5 句白字（`pixel_1.ttf` 回退 `pixel.ttf`）+ 抖动，约 3s/句。 |
| 拾取→独白→「已获得 xx」 | ✅ | `game.gd` `PICKUP_MONOLOGUES`/`PICKUP_LABELS` + `pickup_prompt` 信号；集齐三样转场延后到独白结束。 |
| 写第一章剧情 | ✅ | `DIALOGUES["elder"]` 6 句开场 + `empty_seaweed_1/2` 内心 OS。 |

### `question.md`（第五轮 6 条）

| 项 | 状态 | 说明 |
|----|------|------|
| 玩家大小可调 + 对话禁移动 | ✅ | `player.gd` 加 `@export display_scale=2.0`（缩放贴图与碰撞，比物品栏格子大）；对话中 `dir=ZERO` 禁移动，E 仍可推进。 |
| 台词补全括号动作 | ✅ | `DIALOGUES["elder"]` 6 句全部补上 `（…）` 动作描写与台词原文。 |
| 开场文字淡入淡出 | ✅ | `start.gd` 去掉抖动与 Timer，改用 tween 淡入→停顿→淡出（约 1.5s/句）。 |
| 「已获得 xx」改头顶浮字 | ✅ | `_on_pickup_prompt` 复用 `_show_float_above_player`，删除居中 toast。 |
| NPC 待机动画 + 碰撞体 | ✅ | `interactable.gd` 加 `display_scale`、2 帧待机（`assets/npc/idle_0/1.png`）、`StaticBody2D`（layer 2）碰撞体；删 `size`。 |
| 立绘撤回到第三轮 | ✅ | 删 `portrait_size`；`_make_portrait` 恢复 340×460 STRETCH_SCALE；`_on_dialogue_line` 恢复 NPC 左 `(30,240)`/汐右 `(910,240)`，文字避让立绘。 |

### 第六轮（用户口述：立绘缺失 + NPC 缺失 + 立绘不拉伸 + 可改位置）

| 项 | 状态 | 说明 |
|----|------|------|
| 修「立绘缺失」 | ✅ | 两个文件名笔误已重命名对齐：`xi/happy (4).png` → `xi/happy.png`、`xi_young/happy .png` → `xi_young/happy.png`（并删旧 `.import`），随后用 Godot `--headless --import` 重新导入生成新 `.import`。 |
| 修「NPC 缺失」 | ✅ | NPC 待机动画已由用户移到 `assets/npc/idle_0/1.png`（带 `.import`），`interactable.gd` 的 `NPC_IDLE_FRAMES` 现命中；`elder.png` 已由用户补入并导入。 |
| 立绘不拉伸 | ✅ | `_make_portrait()` 由 `STRETCH_SCALE`（把 ~211×192 近方图硬撑成 340×460 变形）改为 `STRETCH_KEEP_ASPECT_CENTERED`（比例不变，不足留透明、居中）。 |
| 立绘可改位置/尺寸 | ✅ | 新增 3 个 `@export`：`portrait_size`、`npc_portrait_position`（左）、`xi_portrait_position`（右）；`_on_dialogue_line` 改用导出坐标。在 `Main` 节点 Inspector 直接改。 |
| 验证 | ✅ | `run_project`（main.tscn 与 start.tscn）均 `errors: []`；重命名立绘已重新导入并复跑确认无错。 |

---

## 三、还没做的

1. **立绘仍缺 2 张（第一章未用到，留待后续）**：`portraits/xi/pain.png`、`portraits/xi_young/expectant.png`。
2. **场景背景仍缺 2 张**：`ritual.png`、`deep.png`（第 2/3 章纯色回退）。
3. **ritual / deep 场景只有占位**：`DIALOGUES.placeholder`（长老说「内容还在准备中……」）+ 一个占位 NPC，无具体剧情。

---

## 四、关键决策及理由

| 决策 | 理由 |
|------|------|
| **全程序化构建 UI / 内容**（`main.gd` 建 UI，脚本自绘视觉） | 用户逐批导入资产；代码用 `ResourceLoader.exists()` 判空，缺什么回退占位色块，绝不因缺资产崩溃。 |
| **单立绘位，随说话者切左右** | 简化：一次只显示当前说话者；NPC 在左、汐在右，视觉稳定不混淆。 |
| **移除背包，只留 5 格物品栏** | 用户明确「不要背包」；物品栏是装饰/提示性质，1–5 键选格高亮，无开合 UI。 |
| **对话/场景数据用 `Dictionary` 常量（`game.gd`）** | 对话 = `{speaker, expr, text}` 数组，立绘 = `{speaker: {expr: 路径}}`；改内容只改 `DIALOGUES`/`PORTRAITS`，不动引擎。 |
| **输入在运行时注册（`Game._register_input`）** | 所有键位集中在 `game.gd` 的 `KEYS`，一处改全局生效。 |
| **开始界面 = 独立场景文件**（`start.tscn`） | 用户最终拍板「独立场景文件」而非覆盖层（覆盖层是已放弃的上一版方案）。 |
| **场景切换按进度（非出口）** | 用户拍板：集齐三样饰线 → 文字放大 3 秒 → 自动切下一场景；因此 `exit.gd` 出口方案废弃。 |
| **提示一次性永久消失** | 用户拍板「完成一次操作后全部都消失」；用 `hints_dismissed` 布尔标志全局压住，而非只隐藏某一条。 |
| **字体 `pixel.ttf` + 全黑** | 用户拍板；缺失回退系统 CJK 字体保证可读。 |
| **`chapter_complete_emitted` 防重触发** | 3 秒转场动画期间玩家仍可能拾到第 4 件（伏笔）道具，会再次触发 `chapter_complete`；加布尔守卫只发一次。 |
| **立绘保持比例不拉伸（`KEEP_ASPECT_CENTERED`）** | 用户明确「不要拉伸」；源图 ~211×192 / ~226×222 近方形，硬撑到 340×460 变形严重。改保持比例 + 居中，显示框大小仍可经 `portrait_size` 调。 |
| **立绘位置/尺寸用 `@export`（Inspector 可改）** | 用户要「能够改位置」；`@export` 挂在 `Main` 节点上，改坐标/尺寸无需动代码，最符合其习惯。 |

---

## 五、改过的重要文件

| 文件 | 改动 |
|------|------|
| `scripts/game.gd` | 重写：`KEYS`、`SCENES`、`SCENE_ORDER`、`DIALOGUES`、`PORTRAITS`、`ITEM_TEXTURES`、`SPOT_TEXTURES`、`selected_slot`/`select_slot`、`hints_dismissed`/`chapter_complete_emitted`、`pickup_item`/`next_scene_id`；**删除** `toggle_inventory`/`inventory_open`/`inventory_toggled`。 |
| `scripts/main.gd` | 重写：字体、背景层、UI（对话框/立绘/物品栏/收集度/提示/章节完成提示）、ninepatch、`_load_scene`/`_spawn_spot`/`_spawn_npc`、`_on_chapter_complete`（3s 放大转场）/`_on_chapter_transition_done`。**已删** `_build_start_screen`/`_spawn_exit`/`EXIT_SCRIPT`。 |
| `scripts/start.gd` | 新建：开始界面（背景 + 开始按钮，有图用图否则文字）→ `change_scene_to_file("main.tscn")`。 |
| `scenes/start.tscn` | 新建：`Start`(Node2D) 挂 `start.gd`。 |
| `scripts/player.gd` | `_handle_actions` 加 `_handle_slot_keys()`（1–5 → `Game.select_slot`）；**已删** `toggle_inventory` 死代码。 |
| `scripts/hiding_spot.gd` | `_visual` 改 `CanvasItem` 类型统一 Sprite2D/Polygon2D；`spot_type` 支持 `seaweed_1/2/3`+`shell`，有贴图用贴图否则多边形。 |
| `scripts/interactable.gd` | 道具视觉有贴图用 Sprite2D、否则纯色方块。 |
| `scripts/exit.gd` | 新建后**废弃**（无引用）。 |
| `scenes/main.tscn` | 精简为 `Main`(main.gd) + `Player`(player.gd) 两个节点。 |
| `project.godot` | `run/main_scene` → `res://scenes/start.tscn`；autoload `Game`；canvas_items 拉伸 1280×720。 |
| `assets/README.md` | 完整资产命名约定表（player/portraits/ui/backgrounds/items/spots）。 |
| `GDD.md` | 补场景系统、物品栏、字体、收集度、开始界面等章节。 |
| `scripts/player.gd` | 行走动画容错：缺某一帧不再整套回退（本轮）。 |
| `scripts/start.gd` | 加 `@export` `start_button_size`/`start_button_position`（本轮）。 |
| `scripts/main.gd` | 提示改 5 行、附近提示下移、`_spawn_spot`/`_spawn_npc` 传 `size`（本轮）。 |
| `scripts/hiding_spot.gd` / `interactable.gd` | 加 `@export size`，碰撞/视觉随尺寸缩放（本轮）。 |
| `scripts/game.gd` | `SCENES` 加 `pos`/`size` 注释说明（本轮）。 |
| `assets/portraits/xi_young/happy .png` | 重命名为 `happy.png`（去空格，本轮）。 |
| `scripts/exit.gd`、根目录 `pixel.ttf` | 删除（死代码 / 冗余，本轮）。 |
| `scenes/world_coral.tscn` / `world_ritual.tscn` / `world_deep.tscn` | 新建（第四轮）：可拖拽的海藻/贝壳/NPC/出生点节点，替代 `game.gd` 里运行时生成的 `spots`/`npcs`。 |
| `scripts/game.gd` | `SCENES` 精简为 `{name, background, world}`；加 `PICKUP_MONOLOGUES`/`PICKUP_LABELS`、`pickup_prompt`/`search_again` 信号；`pickup_item`/`advance_dialogue` 改拾取→独白→提示流程；写第一章剧情（第四轮）。 |
| `scripts/main.gd` | `_load_scene` 改实例化 world 场景 + 读 `PlayerSpawn`；删 `_spawn_spot`/`_spawn_npc`；物品栏反色；立绘 200×200 最近邻；浮字/toast helper；连新信号（第四轮）。 |
| `scripts/start.gd` | 按钮去灰边 + 黑屏开场逐句白字（第四轮）。 |
| `scripts/hiding_spot.gd` | `empty_monologue_id` + 空海藻内心 OS / 二次浮字（第四轮）。 |
| `scenes/main.tscn` | 加 4 条地图边缘碰撞墙（第四轮）。 |
| `scripts/main.gd` | 加 3 个 `@export`（`portrait_size`/`npc_portrait_position`/`xi_portrait_position`）；`_make_portrait` 改 `STRETCH_KEEP_ASPECT_CENTERED` + `portrait_size`；`_on_dialogue_line` 用导出坐标（第六轮）。 |
| `assets/portraits/xi/happy (4).png` | 重命名 → `xi/happy.png`（第六轮）。 |
| `assets/portraits/xi_young/happy .png` | 重命名 → `xi_young/happy.png`（第六轮）。 |
| `assets/README.md` | 立绘小节补「保持比例不拉伸、`Main` 节点 Inspector 可调三变量」（第六轮）。 |

---

## 六、现在存在的问题

1. **【缺失资产】立绘缺 2 张**：`portraits/xi/pain.png`、`portraits/xi_young/expectant.png`（第一章未引用，仅占 `PORTRAITS` 字典，留待后续章节）。
2. **【缺失资产】场景背景缺 2 张**：`ritual.png`、`deep.png`（第 2/3 章纯色占位）。
3. **【占位场景】`ritual`/`deep`** 只有占位 NPC 和「内容还在准备中」台词，待补正式剧情。

> 已解决：目录 `background/`→`backgrounds/`、`Line_faded.png`→`line_faded.png`；`happy (4).png`→`happy.png`、`happy .png`→`happy.png`（本轮，已 `--headless --import` 重新导入生成 `.import`）；`pixel_1.ttf`、`walk_right_1.png`、`npc/idle_0/1.png`、`elder.png`、`coral.png`、`xi/expectant.png` 均已导入；已删 `exit.gd` 死代码、根目录冗余 `pixel.ttf`。

---

## 七、接下来要做什么（建议顺序）

1. **手测立绘**：走到长老处按 E 对话——幼汐「开心」立绘正常显示（不再灰块）、长老显示 `elder.png`；立绘比例不变形；改 `Main` 节点 Inspector 的 `xi_portrait_position` 能移动右侧立绘。
2. **补立绘**：`portraits/xi/pain.png`、`portraits/xi_young/expectant.png`（后续章节用）。
3. **补场景背景**：`ritual.png` / `deep.png`。
4. **补剧情**：`ritual`/`deep` 场景的正式 NPC/道具/对话（在 `world_ritual.tscn`/`world_deep.tscn` 里加节点，在 `game.gd` 的 `DIALOGUES` 里加台词）。
5. **（可选）拖拽调位置**：在 Godot 编辑器里直接拖 `world_coral.tscn` / `main.tscn` 里的海藻/贝壳/NPC/碰撞墙。
6. **最终验证**：`run_project` + `get_debug_output`，确认 `errors: []`，逐场景/逐资产核对显示。

---

## 八、踩过的坑（后面别再踩）

1. **用 Edit 替换大段代码时，旧文本的缩进（Tab vs 空格）必须与文件完全一致**，否则报 `String to replace not found`。教训：改 `game.gd` 里 `SCENES.spots` 那一段时，整块替换失败，改成**只匹配不含前导空白的子串**（如 `"type": "seaweed"` → `"type": "seaweed_1"`）做三次小替换才成功。以后编辑缩进敏感的块，先 Read 精确对，或拆成无缩进锚点的子串。
2. **资产目录命名单复数 / 大小写要一次定死并全文统一**：本次出现 `backgrounds/` vs `background/`、`line_faded.png` vs `Line_faded.png` 两处不一致，导致回退占位。以后新增目录先在 `assets/README.md` 写清楚路径，再让代码常量与磁盘严格同名（建议全小写、目录用复数）。
3. **方案变更后要立刻清理旧代码**：场景切换从「出口按 E」改成「按进度自动切」后，`exit.gd`、`_spawn_exit`、`EXIT_SCRIPT` 一度残留；`player.gd` 里 `Game.toggle_inventory()` 死代码也残留过。改方案时同步 grep 全项目确认无悬空引用。
4. **转场动画期间的重复触发**：`chapter_complete` 用 tween 放大 3 秒，期间玩家还能拾第 4 件伏笔道具会再触发一次。用 `chapter_complete_emitted` 布尔守卫，只发一次。
5. **玩家出生点由 `PlayerSpawn` 节点决定**（第四轮起）：`main.gd` `_load_scene` 读 `world_*.tscn` 里的 `PlayerSpawn` 节点定位玩家，不再硬编码坐标。改出生点 = 在编辑器里拖 `world_*.tscn` 的 `PlayerSpawn` 节点，不是改 `main.tscn` 的 Player。
6. **`_visual` 要声明为 `CanvasItem`** 而不是 `Polygon2D`/`Sprite2D`，才能统一 `.modulate.a` 变淡的写法（`open()` 里对贴图 Sprite 和多边形 Polygon 都要生效）。
7. **重命名 PNG 后，Godot 不会自动生成新的 `.import` 边车**（`run_project` 也不会）。只 `mv` 文件 + 删旧 `.import`，新名仍是「未导入」状态，`ResourceLoader.exists()` 会判定为不存在而回退占位。**解法**：用 Godot 二进制跑一次 `--headless --import --path <项目目录>`（本机二进制在 `C:\Users\Stellar923\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`），或打开编辑器触发扫描；它会按新名重新生成 `.import`。排查「文件在磁盘上却加载不出来」时，先 `ls` 确认有没有同名的 `.import`。
8. **文件名笔误是「资源缺失」最常见的根因**：`happy (4).png`（多余 ` (4)`）、`happy .png`（`.png` 前多余空格）这类肉眼难辨的差异，会让代码的规范路径匹配不上。排查「明明放图了却不显示」时，先 `ls -1` 列磁盘真实文件名与代码期望名逐字比对（空格、大小写、括号、后缀）。
