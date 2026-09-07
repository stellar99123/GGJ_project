extends Node2D

## 游戏主控制器：字体 / UI / 场景系统 / 背景

const DIALOGUE_BOX_PATH := "res://assets/ui/dialogue_box.png"
const ITEM_BAR_PATH := "res://assets/ui/item_bar.png"
const ITEM_SLOT_PATH := "res://assets/ui/item_slot.png"
const COLLECT_BG_PATH := "res://assets/ui/collect_bg.png"
const FONT_PATH := "res://assets/fonts/pixel.ttf"
const DIALOGUE_BOX_MARGIN := 24
const SLOT_MARGIN := 8
const FONT_COLOR := Color(0, 0, 0)
const HINT_COLOR := Color(0.96, 0.94, 0.87)  # 米白色（左上角提示文字）

var ui_font: Font
var canvas: CanvasLayer          # 游戏 UI 层（layer 10）

var background: TextureRect      # 场景背景图
var scene_content: Node2D        # 当前场景内容容器（隐藏点 / NPC / 出口）

var collect_panel: Panel
var collect_label: Label
var tutorial_label: Label
var hint_label: Label
var dialogue_panel: Panel
var dialogue_label: Label
var portrait: TextureRect
var name_label: Label
var item_bar: Panel
var item_slots: Array[Panel] = []
var complete_label: Label
var _transition_overlay: ColorRect
var _transition_label: Label
var _transition_index: int = 0

var player: CharacterBody2D


@export var portrait_size: Vector2 = Vector2(340, 460)        # 立绘显示框（保持比例居中，不拉伸）
@export var npc_portrait_position: Vector2 = Vector2(30, 240) # 说话者=长老/NPC（左）时的立绘位置
@export var xi_portrait_position: Vector2 = Vector2(910, 240) # 说话者=汐/幼汐（右）时的立绘位置


func _ready() -> void:
	_setup_font()
	_build_scene_root()
	_build_ui()
	player = $Player
	Game.inventory_changed.connect(_on_inventory_changed)
	Game.chapter_complete.connect(_on_chapter_complete)
	Game.dialogue_line_changed.connect(_on_dialogue_line)
	Game.dialogue_closed.connect(_on_dialogue_closed)
	Game.selection_changed.connect(_on_selection_changed)
	Game.pickup_prompt.connect(_on_pickup_prompt)
	Game.search_again.connect(_on_search_again)
	Game.use_prompt.connect(_on_use_prompt)
	Game.ritual_complete.connect(_on_ritual_complete)
	_load_scene("coral")
	_refresh_collect()
	_refresh_item_bar()


func _process(_delta: float) -> void:
	if Game.hints_dismissed:
		hint_label.text = ""
		return
	if player and player.is_physics_processing():
		hint_label.text = str(player.call("get_hint"))
	else:
		hint_label.text = ""


# ---------- 字体 ----------

func _setup_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		var f := load(FONT_PATH) as FontFile
		if f != null:
			ui_font = f
			return
	# 回退：系统 CJK 字体
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "PingFang SC", "Arial"
	])
	ui_font = sys


# ---------- 场景根 / 背景 ----------

func _build_scene_root() -> void:
	var size := get_viewport_rect().size
	background = TextureRect.new()
	background.position = Vector2.ZERO
	background.size = size
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture = _color_texture(Color(0.32, 0.6, 0.82))
	background.z_index = -10  # 背景永远在角色与场景内容之后
	add_child(background)

	scene_content = Node2D.new()
	scene_content.name = "SceneContent"
	scene_content.z_index = -5  # 场景内容在角色之后、背景之前
	add_child(scene_content)


func _load_scene(id: String) -> void:
	if not Game.SCENES.has(id):
		return
	Game.current_scene = id
	var cfg: Dictionary = Game.SCENES[id]

	# 背景图
	var bg_path: String = cfg.get("background", "")
	if bg_path != "" and ResourceLoader.exists(bg_path):
		background.texture = load(bg_path) as Texture2D
	else:
		background.texture = _color_texture(Color(0.32, 0.6, 0.82))

	# 清空旧内容
	for c in scene_content.get_children():
		c.free()

	# 实例化 world 场景（海藻 / 贝壳 / NPC 是编辑器里可拖拽的真实节点）
	var world_path: String = cfg.get("world", "")
	if world_path != "" and ResourceLoader.exists(world_path):
		var world := load(world_path).instantiate() as Node2D
		scene_content.add_child(world)
		_move_player_to_spawn(world)

	_show_chapter_title(id)
	_play_scene_bgm(id)


func _move_player_to_spawn(world: Node2D) -> void:
	var spawn := world.get_node_or_null("PlayerSpawn") as Node2D
	if spawn != null:
		player.global_position = spawn.global_position


func _play_scene_bgm(id: String) -> void:
	match id:
		"coral":
			Sound.play_bgm("chapter1")
		"ritual":
			Sound.play_bgm("chapter2")


# ---------- UI ----------

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	# 操作提示（左上角，首次拾取后隐藏）
	tutorial_label = _make_label(20)
	tutorial_label.add_theme_color_override("font_color", HINT_COLOR)
	tutorial_label.position = Vector2(20, 16)
	tutorial_label.text = "WASD 移动\nE 对话 / 观察\nF 拾取 / 使用\n空格 搜索\n1-5 选择物品"
	canvas.add_child(tutorial_label)

	# 附近交互提示（左上角第二行）
	hint_label = _make_label(20)
	hint_label.add_theme_color_override("font_color", HINT_COLOR)
	hint_label.position = Vector2(20, 180)
	canvas.add_child(hint_label)

	# 收集度（右上角，九宫格背景）
	collect_panel = Panel.new()
	collect_panel.position = Vector2(1000, 16)
	collect_panel.size = Vector2(260, 80)
	collect_panel.add_theme_stylebox_override("panel", _ninepatch_stylebox(COLLECT_BG_PATH, DIALOGUE_BOX_MARGIN, Color(0.06, 0.12, 0.2, 0.92)))
	collect_label = _make_label(22)
	collect_label.position = Vector2(16, 24)
	collect_label.size = Vector2(228, 40)
	collect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collect_panel.add_child(collect_label)
	canvas.add_child(collect_panel)

	# 对话框（九宫格背景，占画面 1/3 高）
	dialogue_panel = Panel.new()
	dialogue_panel.position = Vector2(120, 520)
	dialogue_panel.size = Vector2(1040, 190)
	dialogue_panel.add_theme_stylebox_override("panel", _ninepatch_stylebox(DIALOGUE_BOX_PATH, DIALOGUE_BOX_MARGIN, Color(0.08, 0.1, 0.18, 0.88)))
	name_label = _make_label(26)
	name_label.add_theme_font_override("font", _make_bold_font())
	name_label.position = Vector2(20, 6)
	name_label.size = Vector2(740, 40)
	dialogue_panel.add_child(name_label)
	dialogue_label = _make_label(20)
	dialogue_label.position = Vector2(20, 48)
	dialogue_label.size = Vector2(740, 130)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_panel.add_child(dialogue_label)
	canvas.add_child(dialogue_panel)
	dialogue_panel.hide()
	name_label.hide()

	# 单立绘位：随说话者切左右（底边对齐对话框底，向上探出、可遮住对话框）
	portrait = _make_portrait(npc_portrait_position)
	canvas.add_child(portrait)
	portrait.hide()

	# 5 格物品栏（底部居中）
	item_bar = Panel.new()
	item_bar.position = Vector2(470, 632)
	item_bar.size = Vector2(340, 76)
	item_bar.add_theme_stylebox_override("panel", _ninepatch_stylebox(ITEM_BAR_PATH, DIALOGUE_BOX_MARGIN, Color(0.06, 0.12, 0.2, 0.92)))
	canvas.add_child(item_bar)
	for i in range(Game.SLOT_COUNT):
		var slot := _make_slot(Vector2(8 + i * 64, 10))
		item_bar.add_child(slot)
		item_slots.append(slot)

	# 章节完成提示
	complete_label = _make_label(26)
	complete_label.position = Vector2(320, 300)
	complete_label.size = Vector2(640, 100)
	complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(complete_label)
	complete_label.hide()


# ---------- 小工具 ----------

func _make_label(font_size: int = 18) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", ui_font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", FONT_COLOR)
	return l


func _make_bold_font() -> Font:
	var fv := FontVariation.new()
	fv.base_font = ui_font
	fv.variation_embolden = 1.2
	return fv


func _make_portrait(pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.size = portrait_size
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture = _color_texture(Color(0.5, 0.55, 0.65, 0.9))
	return t


func _make_slot(pos: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = Vector2(56, 56)
	p.add_theme_stylebox_override("panel", _ninepatch_stylebox(ITEM_SLOT_PATH, SLOT_MARGIN, Color(0.25, 0.28, 0.35, 0.9)))
	return p


func _ninepatch_stylebox(path: String, margin: int, fallback: Color) -> StyleBox:
	if ResourceLoader.exists(path):
		var sb := StyleBoxTexture.new()
		sb.texture = load(path) as Texture2D
		sb.texture_margin_left = margin
		sb.texture_margin_right = margin
		sb.texture_margin_top = margin
		sb.texture_margin_bottom = margin
		return sb
	var flat := StyleBoxFlat.new()
	flat.bg_color = fallback
	return flat


func _color_texture(color: Color) -> Texture2D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


func _item_color(id: String) -> Color:
	match id:
		"line_transparent":
			return Color(0.9, 0.95, 1.0)
		"line_colorful":
			return Color(0.95, 0.5, 0.75)
		"line_thick":
			return Color(0.95, 0.6, 0.3)
		"line_faded":
			return Color(0.5, 0.5, 0.5)
		_:
			return Color(0.9, 0.85, 0.4)


# ---------- 刷新 ----------

func _refresh_collect() -> void:
	var n := Game.collected_line_count()
	var total := Game.REQUIRED_LINE_IDS.size()
	collect_label.text = "饰线 %d / %d" % [n, total]


func _refresh_item_bar() -> void:
	for i in range(Game.SLOT_COUNT):
		var slot := item_slots[i]
		for c in slot.get_children():
			c.queue_free()
		if i < Game.inventory.size():
			_show_item_swatch(slot, Game.inventory[i])
		slot.modulate.a = 0.45 if i == Game.selected_slot else 1.0


func _show_item_swatch(slot: Panel, id: String) -> void:
	var swatch := TextureRect.new()
	swatch.position = Vector2(8, 8)
	swatch.size = Vector2(40, 40)
	swatch.stretch_mode = TextureRect.STRETCH_SCALE
	var path: String = Game.ITEM_TEXTURES.get(id, "")
	if path != "" and ResourceLoader.exists(path):
		swatch.texture = load(path) as Texture2D
	else:
		swatch.texture = _color_texture(_item_color(id))
	slot.add_child(swatch)


# ---------- 信号回调 ----------

func _on_inventory_changed() -> void:
	tutorial_label.hide()  # 首次拾取后隐藏操作提示
	hint_label.hide()      # 附近交互提示一并隐藏（不再给提示）
	_refresh_collect()
	_refresh_item_bar()


func _on_selection_changed(_slot: int) -> void:
	_refresh_item_bar()


func _on_dialogue_line(text: String, speaker: String, expr: String) -> void:
	dialogue_label.text = text
	dialogue_panel.show()
	item_bar.hide()
	# 旁白：无立绘、无人名，文字全宽居中
	if speaker == "narrator":
		portrait.hide()
		name_label.hide()
		dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dialogue_label.position = Vector2(20, 20)
		dialogue_label.size = Vector2(1000, 150)
		return
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	portrait.show()
	name_label.show()
	name_label.text = str(Game.SPEAKER_NAMES.get(speaker, ""))
	_set_portrait(portrait, speaker, expr)
	# 立绘 340×460：NPC 在左、汐在右，底边对齐对话框底；文字避让立绘
	if speaker == "xi" or speaker == "xi_young":
		portrait.position = xi_portrait_position
		name_label.position = Vector2(20, 6)
		dialogue_label.position = Vector2(20, 48)
		dialogue_label.size = Vector2(740, 130)
	else:
		portrait.position = npc_portrait_position
		name_label.position = Vector2(300, 6)
		dialogue_label.position = Vector2(300, 48)
		dialogue_label.size = Vector2(740, 130)


func _set_portrait(p: TextureRect, speaker: String, expr: String) -> void:
	var tex := _portrait_texture(speaker, expr)
	if tex != null:
		p.texture = tex


func _portrait_texture(speaker: String, expr: String) -> Texture2D:
	var exps: Dictionary = Game.PORTRAITS.get(speaker, {})
	var path: String = exps.get(expr, "")
	if path == "":
		for p in exps.values():
			path = p
			break
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _on_dialogue_closed() -> void:
	dialogue_panel.hide()
	portrait.hide()
	item_bar.show()


func _on_pickup_prompt(text: String) -> void:
	_show_float_above_player("已获得「%s」" % text)


func _on_search_again() -> void:
	_show_float_above_player("这里已经搜索过了")


func _on_use_prompt(text: String) -> void:
	_show_float_above_player(text)


func _show_float_above_player(text: String) -> void:
	var l := _make_label(18)
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(player.global_position.x - 200.0, player.global_position.y - 60.0)
	l.size = Vector2(400, 30)
	canvas.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 40.0, 1.0)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(l.queue_free)


func _on_chapter_complete() -> void:
	complete_label.text = "集齐三样饰线！初缠仪式即将开始……"
	complete_label.show()
	complete_label.pivot_offset = complete_label.size / 2.0
	complete_label.scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(complete_label, "scale", Vector2(2.0, 2.0), 3.0)
	tw.tween_callback(_on_chapter_transition_done)


func _on_chapter_transition_done() -> void:
	complete_label.hide()
	complete_label.scale = Vector2.ONE
	var next_id: String = Game.next_scene_id()
	if next_id != "":
		_load_scene(next_id)


func _show_chapter_title(id: String) -> void:
	var title: String = Game.CHAPTER_TITLES.get(id, "")
	if title == "":
		return
	var l := _make_label(48)
	l.text = title
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(240, 290)
	l.size = Vector2(800, 120)
	canvas.add_child(l)
	l.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.7)
	tw.tween_callback(l.queue_free)


func _on_ritual_complete() -> void:
	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color(0, 0, 0, 1)
	_transition_overlay.position = Vector2.ZERO
	_transition_overlay.size = get_viewport_rect().size
	_transition_overlay.z_index = 100
	canvas.add_child(_transition_overlay)

	_transition_label = _make_label(28)
	_transition_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_transition_label.size = Vector2(1000, 120)
	_transition_label.position = Vector2(140, 300)
	_transition_overlay.add_child(_transition_label)

	_transition_index = 0
	_show_transition_sentence()


func _show_transition_sentence() -> void:
	var sentences: Array = Game.RITUAL_TRANSITION_SENTENCES
	_transition_label.text = sentences[_transition_index]
	_transition_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_transition_label, "modulate:a", 1.0, 0.5)
	tw.tween_interval(1.5)
	tw.tween_property(_transition_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(_on_transition_advance)


func _on_transition_advance() -> void:
	_transition_index += 1
	if _transition_index >= Game.RITUAL_TRANSITION_SENTENCES.size():
		_transition_overlay.queue_free()
		_load_scene("deep")
	else:
		_show_transition_sentence()
