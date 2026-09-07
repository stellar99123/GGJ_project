extends CharacterBody2D

## 汐：WASD 移动 + 4 方向行走动画 + 距离检测附近可交互物 / 隐藏点

@export var speed: float = 220.0
@export var detect_radius: float = 60.0
@export var anim_fps: float = 2.0
@export var display_scale: float = 2.0   # 显示缩放：比物品栏格子（56px）更大，可自行调

var _nearby_areas: Array[Area2D] = []
var _nearby_bodies: Array[Node2D] = []
var _sprite: AnimatedSprite2D = null
var _was_walking := false

## 行走动画：每个方向的动画名（帧 0/1 按命名约定加载）
const PLAYER_DIRS: Array[String] = ["down", "up", "left", "right"]


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2  # 与障碍物（层 2）碰撞
	_build_body()


func _build_body() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 20) * display_scale
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	if _build_animated_sprite():
		return
	# 回退占位：动画资产未导入时的菱形
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(11, 0), Vector2(0, 13), Vector2(-11, 0)
	])
	visual.color = Color(0.3, 0.8, 0.8)
	visual.scale = Vector2(display_scale, display_scale)
	add_child(visual)


## 尝试按命名约定加载 4 方向 × 2 帧行走动画；全部就绪才返回 true
func _build_animated_sprite() -> bool:
	var frames := SpriteFrames.new()
	var any := false
	for dir_name in PLAYER_DIRS:
		var anim_name := "walk_" + dir_name
		var t0 := _load_texture("res://assets/player/walk_%s_0.png" % dir_name)
		var t1 := _load_texture("res://assets/player/walk_%s_1.png" % dir_name)
		if t0 == null:
			continue  # 该方向没帧就跳过，缺某一帧不再导致整套动画回退
		if t1 == null:
			t1 = t0  # 缺第二帧时复用第一帧（该方向静止）
		frames.add_animation(anim_name)
		var dur := 1.0 / anim_fps
		frames.add_frame(anim_name, t0, dur)
		frames.add_frame(anim_name, t1, dur)
		any = true

	if not any:
		return false
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.animation = "walk_down"
	_sprite.scale = Vector2(display_scale, display_scale)
	add_child(_sprite)
	return true


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Game.dialogue_active:
		dir = Vector2.ZERO  # 对话/独白进行中禁止移动（E 仍可推进对话）
	velocity = dir * speed
	move_and_slide()
	_update_animation(dir)
	_update_walk_sfx(dir)
	_update_nearby()
	_handle_actions()


func _update_animation(dir: Vector2) -> void:
	if _sprite == null:
		return
	if dir != Vector2.ZERO:
		_sprite.play(_dir_to_anim(dir))
	else:
		_sprite.stop()  # 无待机：静止停在站姿帧（frame 0）


func _dir_to_anim(dir: Vector2) -> String:
	if absf(dir.x) > absf(dir.y):
		return "walk_right" if dir.x > 0.0 else "walk_left"
	return "walk_down" if dir.y > 0.0 else "walk_up"


func _update_walk_sfx(dir: Vector2) -> void:
	var walking := dir != Vector2.ZERO
	if walking != _was_walking:
		_was_walking = walking
		Sound.set_walking(walking)


func _update_nearby() -> void:
	_nearby_areas.clear()
	_nearby_bodies.clear()
	for node in get_tree().get_nodes_in_group("interactable"):
		var a := node as Area2D
		if a != null and global_position.distance_to(a.global_position) <= detect_radius:
			_nearby_areas.append(a)
	for node in get_tree().get_nodes_in_group("hiding_spot"):
		if node.get("opened"):
			continue
		var b := node as Node2D
		if b != null and global_position.distance_to(b.global_position) <= detect_radius:
			_nearby_bodies.append(b)


func _handle_actions() -> void:
	_handle_slot_keys()
	if Input.is_action_just_pressed("interact"):
		if Game.dialogue_active:
			Game.advance_dialogue()
		else:
			var target := _nearest_area()
			if target != null and (target.get("is_npc") or target.get("observable")):
				Game.start_npc_dialogue(target.get("dialogue_id"))
		return
	if Game.dialogue_active:
		return  # 对话/独白进行中，忽略拾取与搜索，避免打断
	if Input.is_action_just_pressed("pickup"):
		var target := _nearest_area()
		if target != null and not target.get("is_npc") and not target.get("observable"):
			Game.pickup_item(target)
		else:
			Game.use_selected_item()
	elif Input.is_action_just_pressed("search"):
		var spot := _nearest_body()
		if spot != null:
			spot.call("open")


func _handle_slot_keys() -> void:
	for i in range(Game.SLOT_COUNT):
		if Input.is_action_just_pressed("slot_%d" % (i + 1)):
			Game.select_slot(i)


func get_hint() -> String:
	var s := _nearest_body()
	if s != null:
		if s.get("spot_type") == "shell":
			return "按 空格 打开贝壳"
		return "按 空格 拨开海藻"
	var a := _nearest_area()
	if a != null:
		if a.get("is_npc"):
			return "按 E 对话"
		if a.get("observable"):
			return "按 E 观察"
		return "按 F 拾取"
	return ""


func _nearest_area() -> Area2D:
	var nearest: Area2D = null
	var best := INF
	for a in _nearby_areas:
		if not is_instance_valid(a):
			continue
		var d: float = global_position.distance_squared_to(a.global_position)
		if d < best:
			best = d
			nearest = a
	return nearest


func _nearest_body() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for b in _nearby_bodies:
		if not is_instance_valid(b):
			continue
		var d: float = global_position.distance_squared_to(b.global_position)
		if d < best:
			best = d
			nearest = b
	return nearest
