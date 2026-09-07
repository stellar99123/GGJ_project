extends Node2D

## 开始界面：背景 + 「开始」按钮 → 黑屏开场逐句文字 → 主场景

const START_BG_PATH := "res://assets/backgrounds/start.png"
const START_BUTTON_PATH := "res://assets/ui/start_button.png"
const FONT_PATH := "res://assets/fonts/pixel.ttf"
const INTRO_FONT_PATH := "res://assets/fonts/pixel_1.ttf"
const FONT_COLOR := Color(0, 0, 0)
const INTRO_COLOR := Color(1, 1, 1)

## 开场文字：一句一句出现，白字居中，每句约 1.5 秒，淡入淡出
const INTRO_SENTENCES := [
	"人鱼一族拥有长达三百年的寿命，恪守着成年时将「汐纹线」缠绕尾鳍的古老传统。",
	"一百年前的深海纯净无暇，长老缠上的星光线柔韧而充满生机。",
	"如今工业废料坠入深渊，族人将坚韧不可降解的塑料鱼线与化纤废网误认作新时代的赐福。",
	"十五岁的人鱼「汐」即将迎来成年礼，却不知这枚「勋章」将在成长中嵌入血脉。",
	"所谓的蜕变与荣耀，不过是一场被垃圾层层绞紧的慢性窒息。",
]
const INTRO_FADE_IN := 0.5
const INTRO_HOLD := 1.5
const INTRO_FADE_OUT := 0.5

## 开始按钮大小 / 位置：选中场景里的 Start 节点，在 Inspector 里直接改
@export var start_button_size: Vector2 = Vector2(300, 300)
@export var start_button_position: Vector2 = Vector2(520, 500)

var _font: Font
var _intro_font: Font
var _intro_label: Label
var _intro_index: int = 0


func _ready() -> void:
	_setup_font()
	_build()
	Sound.play_bgm("start")  # 开始界面音乐，循环播放


func _setup_font() -> void:
	_font = _load_font(FONT_PATH)
	if _font == null:
		_font = _system_font()
	_intro_font = _load_font(INTRO_FONT_PATH)
	if _intro_font == null:
		_intro_font = _font  # pixel_1.ttf 未导入时回退 pixel.ttf


func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		var f := load(path) as FontFile
		if f != null:
			return f
	return null


func _system_font() -> Font:
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "PingFang SC", "Arial"
	])
	return sys


func _build() -> void:
	var size := get_viewport_rect().size

	var bg := TextureRect.new()
	bg.position = Vector2.ZERO
	bg.size = size
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(START_BG_PATH):
		bg.texture = load(START_BG_PATH) as Texture2D
	else:
		bg.texture = _color_texture(Color(0.06, 0.12, 0.24))
	add_child(bg)

	var btn := Button.new()
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 32)
	btn.add_theme_color_override("font_color", FONT_COLOR)
	# 去掉默认按钮 stylebox 的灰色描边/高亮，只显示图标
	var empty_sb := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)
	btn.position = start_button_position
	btn.size = start_button_size
	if ResourceLoader.exists(START_BUTTON_PATH):
		btn.icon = load(START_BUTTON_PATH) as Texture2D
		btn.expand_icon = true
	else:
		btn.text = "开始"
	btn.pressed.connect(_on_start_pressed)
	add_child(btn)


func _on_start_pressed() -> void:
	Sound.play_sfx("start_button")  # 点击 UI 音效
	Sound.stop_bgm()                # 停掉开始界面音乐
	_start_intro()


func _start_intro() -> void:
	Sound.play_bgm("prologue")  # 前情提要背景音乐
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.position = Vector2.ZERO
	overlay.size = get_viewport_rect().size
	overlay.z_index = 100
	add_child(overlay)

	_intro_label = _make_intro_label()
	overlay.add_child(_intro_label)

	_intro_index = 0
	_show_intro_sentence()


func _show_intro_sentence() -> void:
	_intro_label.text = INTRO_SENTENCES[_intro_index]
	_intro_label.position = Vector2(140, 300)
	_intro_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_intro_label, "modulate:a", 1.0, INTRO_FADE_IN)
	tw.tween_interval(INTRO_HOLD)
	tw.tween_property(_intro_label, "modulate:a", 0.0, INTRO_FADE_OUT)
	tw.tween_callback(_on_intro_advance)

	# 最后一句话：整句 3s（淡入 0.5 + 停留 2 + 淡出 0.5），提前 1s 让前情提要 BGM 渐弱
	if _intro_index == INTRO_SENTENCES.size() - 1:
		var bgm := create_tween()
		bgm.tween_interval(2.0)
		bgm.tween_callback(func(): Sound.fade_out_bgm(1.0))


func _on_intro_advance() -> void:
	_intro_index += 1
	if _intro_index >= INTRO_SENTENCES.size():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		_show_intro_sentence()


func _make_intro_label() -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", _intro_font)
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", INTRO_COLOR)
	l.size = Vector2(1000, 120)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _color_texture(color: Color) -> Texture2D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
