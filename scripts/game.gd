extends Node

## 全局游戏状态、场景数据、输入注册（autoload 单例 Game）

signal inventory_changed
signal chapter_complete
signal dialogue_line_changed(text: String, speaker: String, expr: String)
signal dialogue_closed
signal selection_changed(slot: int)
signal pickup_prompt(text: String)   # 拾取独白结束后：弹「已获得 xx」
@warning_ignore("unused_signal")     # 由 hiding_spot.gd 发射、main.gd 监听，本类不直接 emit
signal search_again                  # 空海藻二次搜索：玩家上方浮字
signal use_prompt(text: String)      # 使用道具：玩家头顶浮字（使用成功 / 顺序不对）
signal ritual_complete               # 第二章缠线完成：切深海前的黑屏过场

const KEYS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
	"interact": KEY_E,
	"pickup": KEY_F,
	"search": KEY_SPACE,
	"slot_1": KEY_1,
	"slot_2": KEY_2,
	"slot_3": KEY_3,
	"slot_4": KEY_4,
	"slot_5": KEY_5,
}

const REQUIRED_LINE_IDS := ["line_transparent", "line_colorful", "line_thick"]
const SLOT_COUNT := 5

## 说话者显示名（对话框人名独占一行，更大更粗）
const SPEAKER_NAMES := {
	"xi_young": "幼年汐",
	"xi": "汐",
	"elder": "长老",
	"ajie": "阿姐",
}

## 场景标题卡（进入场景前画面正中浮字，1s 后渐隐）
const CHAPTER_TITLES := {
	"coral": "浅滩",
	"ritual": "长老居所",
	"deep": "深海",
}

## 第二章「按顺序使用饰线」的正确顺序（透明 → 彩虹 → 粗）
const RITUAL_USE_ORDER := ["line_transparent", "line_colorful", "line_thick"]

## 第二章结尾黑屏过场文字
const RITUAL_TRANSITION_SENTENCES := [
	"时光在深海无声游走。",
	"汐不再是浅海里那个无忧无虑的小女孩。她的身体在发育成长的同时，尾鳍上的‘标志’也一天天变得更加沉重……",
]

## 饰线（道具）美术资源路径：缺失时回退纯色
const ITEM_TEXTURES := {
	"line_transparent": "res://assets/items/line_transparent.png",
	"line_colorful": "res://assets/items/line_colorful.png",
	"line_thick": "res://assets/items/line_thick.png",
	"line_faded": "res://assets/items/line_faded.png",
	"shell_container": "res://assets/items/shell_container.png",
}

## 隐藏点（海藻 ×3 / 贝壳）美术资源路径：缺失时回退纯色多边形
const SPOT_TEXTURES := {
	"seaweed_1": "res://assets/spots/seaweed_1.png",
	"seaweed_2": "res://assets/spots/seaweed_2.png",
	"seaweed_3": "res://assets/spots/seaweed_3.png",
	"shell": "res://assets/spots/shell.png",
}

## 拾取道具后的内心独白（按 E 推进），结束后弹「已获得 xx」
const PICKUP_MONOLOGUES := {
	"line_transparent": [
		{"speaker": "xi_young", "expr": "happy", "text": "好细、好透……像极了壁画里描述的星光丝缕。只是摸起来冰凉又生硬，一点温度也没有。长老常说「神物自带有骨之气」，这应该就是大自然淬炼出的坚韧吧？"},
	],
	"line_thick": [
		{"speaker": "xi_young", "expr": "confused", "text": "这根线真粗实，上面的打结方式从没见过。沉甸甸的，死死绞在一起……真的能缠在尾鳍上吗？但为了能像阿姐们一样威风地游向深海，这点分量算什么。"},
	],
	"line_colorful": [
		{"speaker": "xi_young", "expr": "happy", "text": "好刺眼鲜艳的颜色！在大海深处可找不到这么亮丽的花纹。它一定就是传说中最罕见的「七彩星光线」了！把它缠在最显眼的地方，长老一定会夸我是最漂亮的族人。"},
	],
	"line_faded": [
		{"speaker": "xi_young", "expr": "confused", "text": "这好像是……以前的族人留下的？上面的颜色几乎全褪光了，质地又发白又干硬。奇怪，古书上不是说真正的星光线会与肉体融为一体、永不褪色吗？为什么这根线会被弃在这里……上面好像还有几道浅浅的血痕印子。"},
	],
}

## 拾取提示「已获得「xx」」里的名字（用 chapter1 的命名）
const PICKUP_LABELS := {
	"line_transparent": "细透明线",
	"line_thick": "编织粗绳",
	"line_colorful": "艳丽彩线",
	"line_faded": "褪色旧线",
	"shell_container": "贝壳容器",
}

## 对话数据：每句台词 = { speaker, expr, text }
## speaker 决定立绘用谁 + 立绘在哪侧（xi/xi_young 在右，其余在左）
## expr 决定该说话者的哪张表情（见 PORTRAITS）
const DIALOGUES := {
	"elder": [
		{"speaker": "xi_young", "expr": "happy", "text": "（眼睛发亮，小尾巴欢快摆动）“哇……好漂亮！姐姐，你尾鳍上的汐纹线在发光呢！”"},
		{"speaker": "ajie", "expr": "default", "text": "（停下游动，神色疲惫，强撑起微笑）“是小汐啊。这可是成年礼上长老亲手缠上的‘成长勋章’……等你到了年纪，也会有的。”"},
		{"speaker": "xi_young", "expr": "happy", "text": "（满心憧憬）“真希望我也能快快长大！等我缠上最密的汐纹线，就能像你们一样游去更深的大洋了，对不对？”"},
		{"speaker": "ajie", "expr": "default", "text": "（下意识动了动尾鳍，眉头微皱，低声）“游去深海吗……可能是吧。不过，长大的过程……可是会有点‘紧’的。”"},
		{"speaker": "xi_young", "expr": "confused", "text": "（没听清，歪头）“嗯？阿姐你说什么？”"},
		{"speaker": "ajie", "expr": "default", "text": "（摇摇头，快速游走）“没什么。快去浅海找找看吧，饰线都藏在珊瑚和海藻里，集齐三样，长老就会为你开启仪式。”"},
	],
	"empty_seaweed_1": [
		{"speaker": "xi_young", "expr": "happy", "text": "这株珊瑚长得真好看，粉粉嫩嫩的……"},
	],
	"empty_seaweed_2": [
		{"speaker": "xi_young", "expr": "happy", "text": "空空如也呢……不过你的颜色这么耀眼，一定也在默默守护着这片海吧？"},
	],
	"mural": [
		{"speaker": "narrator", "text": "“一净星光，水泛微芒；先素后艳，先细后密。”"},
	],
	"shell_doubt": [
		{"speaker": "xi", "expr": "speechless", "text": "（盯着静静躺在容器底部的三根丝线，眨了眨眼）“奇怪……石碑上不是说，真正的汐纹线是用深海星光凝结的吗？‘遇水则泛微芒，如夜空星河’……为什么这三根线浸了海水之后，一点光都没有？”"},
		{"speaker": "narrator", "text": "（汐伸手拿起来仔细端详，丝线在水里依然显得死板、僵硬）"},
		{"speaker": "xi", "expr": "speechless", "text": "（小声嘀咕）“不仅不发光，摸起来还硬梆邦的……这真的是星光凝成的丝线吗？”"},
	],
	"elder_scold": [
		{"speaker": "narrator", "text": "（人鱼长老见汐迟迟没有下一步动作，皱起眉头游上前，打断了汐的思考）"},
		{"speaker": "elder", "expr": "default", "text": "（声音沉了下来，带着几分严厉与不悦）“汐，你在磨蹭什么？吉时已到，仪式不可耽搁！”"},
		{"speaker": "xi", "expr": "sad", "text": "（有些犹豫地指着珊瑚容器）“长老……您看这水里。古训上说汐纹线遇海水会散发星光，可我找来的这三根线泡在水里，连一点光彩都没有，摸上去还特别刺手……”"},
		{"speaker": "elder", "expr": "default", "text": "（看都没看容器里的线，摆了摆手，语气满是不耐与冷漠）“胡闹！如今这片海域大不如前，海水早已不如百年前纯净，光芒隐没些许有什么好大惊小怪的？”"},
		{"speaker": "elder", "expr": "default", "text": "“再者，这线是我看着你从浅海采来的，大家缠的不都是这些？难道你觉得祖辈流传下来的仪式会有错？”"},
		{"speaker": "xi", "expr": "sad", "text": "（被长老的气势压制，低下头小声辩解）“我……我不是这个意思……”"},
		{"speaker": "elder", "expr": "default", "text": "（递给汐一个严厉的眼神，催促道）“收起你的疑心！别拿这些无稽之谈当托辞。赶紧按顺序把线缠上，神圣的仪式容不得你迟疑！”"},
	],
	"ritual_pain": [
		{"speaker": "narrator", "text": "汐无奈，只能在长老的盯视下，硬着头皮按照壁画顺序将三根硬质丝线缠绕在尾鳍上"},
		{"speaker": "xi", "expr": "surprised", "text": "（身躯一震，尾鳍剧烈地缩了一下）“唔……好痛！”"},
		{"speaker": "elder", "expr": "default", "text": "（收起严厉，神色恢复了麻木的温和）“很好。孩子，记住这阵痛，这是长大的感觉。从今天起，你也是带上‘成长勋章’的大人人鱼了。”"},
		{"speaker": "xi", "expr": "sad", "text": "（看着尾鳍上完全不发光、反而有些割肉的紧绷丝线，按捺下心中的不安，勉强挤出一个微笑）“长大的……感觉吗……”"},
	],
	"placeholder": [
		{"speaker": "elder", "expr": "default", "text": "（这个场景的内容还在准备中……）"},
	],
}

## 立绘映射：{ speaker: { expr: 纹理路径 } }
const PORTRAITS := {
	"elder": {"default": "res://assets/portraits/NPC/elder.png"},
	"ajie": {"default": "res://assets/portraits/NPC/elder.png"},
	"xi": {
		"neutral": "res://assets/portraits/xi/neutral.png",
		"happy": "res://assets/portraits/xi/happy.png",
		"surprised": "res://assets/portraits/xi/surprised.png",
		"sad": "res://assets/portraits/xi/sad.png",
		"speechless": "res://assets/portraits/xi/speechless.png",
		"pain": "res://assets/portraits/xi/pain.png",
		"expectant": "res://assets/portraits/xi/expectant.png",
	},
	"xi_young": {
		"expectant": "res://assets/portraits/xi_young/expectant.png",
		"happy": "res://assets/portraits/xi_young/happy.png",
		"confused": "res://assets/portraits/xi_young/confused.png",
	},
}

## 场景数据：每场景 = 背景图 + world 场景文件
## ★ 海藻 / 贝壳 / NPC 的位置和大小：在 world_*.tscn 里用鼠标拖拽编辑，不要在这里改
const SCENES := {
	"coral": {
		"name": "珊瑚浅滩",
		"background": "res://assets/backgrounds/coral.png",
		"world": "res://scenes/world_coral.tscn",
	},
	"ritual": {
		"name": "仪式浅滩",
		"background": "res://assets/backgrounds/ritual.png",
		"world": "res://scenes/world_ritual.tscn",
	},
	"deep": {
		"name": "深海",
		"background": "res://assets/backgrounds/deep.png",
		"world": "res://scenes/world_deep.tscn",
	},
}

## 场景推进顺序（按进度切换，见 next_scene_id）
const SCENE_ORDER := ["coral", "ritual", "deep"]

var inventory: Array[String] = []
var selected_slot: int = 0
var foreshadow_found: bool = false
var dialogue_active: bool = false
var dialogue_lines: Array = []
var dialogue_index: int = 0
var current_scene: String = ""
var hints_dismissed: bool = false
var chapter_complete_emitted: bool = false
var pending_pickup_label: String = ""
var pending_chapter_complete: bool = false
var ritual_can_wrap: bool = false
var ritual_use_progress: int = 0
var pending_ritual_complete: bool = false


func _ready() -> void:
	_register_input()


func _register_input() -> void:
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev := InputEventKey.new()
			ev.keycode = KEYS[action]
			ev.physical_keycode = KEYS[action]
			InputMap.action_add_event(action, ev)


func get_dialogue(id: String) -> Array:
	if DIALOGUES.has(id):
		return DIALOGUES[id]
	return []


func pickup_item(item: Area2D) -> void:
	Sound.play_sfx("pickup")  # 获得物品音效
	var id: String = item.get("item_id")
	if id != "":
		inventory.append(id)
	if item.get("is_foreshadow"):
		foreshadow_found = true
	inventory_changed.emit()
	hints_dismissed = true  # 完成一次操作后，不再给任何提示
	item.queue_free()

	var mono: Array = PICKUP_MONOLOGUES.get(id, [])
	if not mono.is_empty():
		# 拾取后先内心独白，独白结束后弹「已获得 xx」
		pending_pickup_label = PICKUP_LABELS.get(id, "")
		# 若集齐三样，转场延后到独白结束（避免和对话框打架）
		if collected_line_count() == REQUIRED_LINE_IDS.size() and not chapter_complete_emitted:
			chapter_complete_emitted = true
			pending_chapter_complete = true
		start_dialogue(mono)
	elif collected_line_count() == REQUIRED_LINE_IDS.size() and not chapter_complete_emitted:
		chapter_complete_emitted = true
		chapter_complete.emit()


func collected_line_count() -> int:
	var n := 0
	for id in REQUIRED_LINE_IDS:
		if inventory.has(id):
			n += 1
	return n


func next_scene_id() -> String:
	var idx := SCENE_ORDER.find(current_scene)
	if idx != -1 and idx + 1 < SCENE_ORDER.size():
		return SCENE_ORDER[idx + 1]
	return ""


func select_slot(n: int) -> void:
	selected_slot = clampi(n, 0, SLOT_COUNT - 1)
	selection_changed.emit(selected_slot)


func start_npc_dialogue(id: String) -> void:
	start_dialogue(get_dialogue(id))
	if id == "elder_scold":
		# 长老催促结束后才允许按顺序缠线（对话中 F 被 dialogue_active 拦截）
		ritual_can_wrap = true


func use_selected_item() -> void:
	if selected_slot >= inventory.size():
		return
	var id: String = inventory[selected_slot]
	if id == "shell_container":
		_use_shell_container()
	elif id in RITUAL_USE_ORDER:
		_use_ritual_line(id)


func _use_shell_container() -> void:
	Sound.play_sfx("use_shell")  # 使用盛水贝壳音效
	_remove_item("shell_container")
	start_dialogue(get_dialogue("shell_doubt"))


func _use_ritual_line(id: String) -> void:
	if current_scene != "ritual" or not ritual_can_wrap:
		return
	if id == RITUAL_USE_ORDER[ritual_use_progress]:
		ritual_use_progress += 1
		_remove_item(id)
		Sound.play_sfx("use_line")  # 使用饰线音效
		use_prompt.emit("使用成功")
		if ritual_use_progress >= RITUAL_USE_ORDER.size():
			Sound.play_sfx("wrap")  # 缠绕音效（饰线用完后）
			pending_ritual_complete = true
			start_dialogue(get_dialogue("ritual_pain"))
	else:
		use_prompt.emit("这个顺序好像不对呢…")


func _remove_item(id: String) -> void:
	inventory.erase(id)
	inventory_changed.emit()


func start_dialogue(lines: Array) -> void:
	if lines.is_empty():
		return
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_active = true
	_emit_line(dialogue_lines[0])


func advance_dialogue() -> void:
	if not dialogue_active:
		return
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		dialogue_active = false
		# 拾取独白结束：先弹「已获得 xx」，再按需触发章节完成转场
		if pending_pickup_label != "":
			var label: String = pending_pickup_label
			pending_pickup_label = ""
			pickup_prompt.emit(label)
		if pending_chapter_complete:
			pending_chapter_complete = false
			chapter_complete.emit()
		if pending_ritual_complete:
			pending_ritual_complete = false
			ritual_complete.emit()
		dialogue_closed.emit()
	else:
		_emit_line(dialogue_lines[dialogue_index])


func _emit_line(line: Variant) -> void:
	var d: Dictionary = line
	dialogue_line_changed.emit(
		str(d.get("text", "")),
		str(d.get("speaker", "")),
		str(d.get("expr", "neutral"))
	)
