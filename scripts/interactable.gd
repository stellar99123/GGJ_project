extends Area2D

## 可交互物：道具（拾取）或 NPC（对话）

@export var is_npc: bool = false
@export var observable: bool = false   # 观察物（壁画等）：E 触发对话，不可拾取、无待机动画
@export var item_id: String = ""
@export var dialogue_id: String = ""
@export var is_foreshadow: bool = false
@export var display_scale: float = 2.0   # NPC 显示缩放，与 player 的 display_scale 保持一致

## NPC 待机动画：2 帧，缺失时回退占位多边形
const NPC_IDLE_FRAMES := [
	"res://assets/npc/idle_0.png",
	"res://assets/npc/idle_1.png",
]
const NPC_ANIM_FPS := 1.0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0
	monitoring = true
	monitorable = true
	_build()


func _build() -> void:
	if is_npc:
		_build_npc()
	elif observable:
		_build_observable()
	else:
		_build_item()


func _build_npc() -> void:
	# 物理碰撞体：layer 2，与玩家 collision_mask 一致，玩家撞上走不过去
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 20) * display_scale  # 足迹与 player 一致
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)

	# 待机动画（2 帧），缺资产回退占位
	if _build_npc_idle():
		return
	var v := Polygon2D.new()
	var half := 10.0 * display_scale
	v.polygon = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)
	])
	v.color = Color(0.62, 0.45, 0.9)
	add_child(v)


func _build_npc_idle() -> bool:
	var frames := SpriteFrames.new()
	var t0 := _load_texture(NPC_IDLE_FRAMES[0])
	var t1 := _load_texture(NPC_IDLE_FRAMES[1])
	if t0 == null or t1 == null:
		return false
	frames.add_animation("idle")
	var dur := 1.0 / NPC_ANIM_FPS
	frames.add_frame("idle", t0, dur)
	frames.add_frame("idle", t1, dur)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.animation = "idle"
	spr.scale = Vector2(display_scale, display_scale)
	spr.play()
	add_child(spr)
	return true


func _build_item() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	# 道具视觉：有美术资源用贴图，否则回退纯色方块
	var path: String = Game.ITEM_TEXTURES.get(item_id, "")
	if path != "" and ResourceLoader.exists(path):
		var spr := Sprite2D.new()
		spr.texture = load(path) as Texture2D
		add_child(spr)
	else:
		var v := Polygon2D.new()
		v.polygon = PackedVector2Array([
			Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
		])
		v.color = _item_color()
		add_child(v)


func _build_observable() -> void:
	# 观察物（壁画等）：仅视觉占位；E 触发对话，不可拾取、无碰撞体
	var v := Polygon2D.new()
	v.polygon = PackedVector2Array([
		Vector2(-40, -24), Vector2(40, -24), Vector2(40, 24), Vector2(-40, 24)
	])
	v.color = Color(0.42, 0.4, 0.36)
	add_child(v)


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _item_color() -> Color:
	if is_foreshadow:
		return Color(0.5, 0.5, 0.5)
	match item_id:
		"line_transparent":
			return Color(0.9, 0.95, 1.0)
		"line_colorful":
			return Color(0.95, 0.5, 0.75)
		"line_thick":
			return Color(0.95, 0.6, 0.3)
		_:
			return Color(0.9, 0.85, 0.4)
