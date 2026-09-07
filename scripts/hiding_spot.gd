extends StaticBody2D

## 隐藏点：海藻 / 贝壳，有碰撞体阻挡玩家；按空格「拨开/打开」后显露道具
## empty_monologue_id 非空时是「空海藻」：搜索不产道具、不变淡，播内心 OS

@export var item_id: String = ""
@export var item_is_foreshadow: bool = false
@export var spot_type: String = "seaweed_1"  # "seaweed_1" / "seaweed_2" / "seaweed_3" / "shell"
@export var size: Vector2 = Vector2(56, 56)   # 碰撞与显示尺寸（像素），默认和物品栏格子一样大
@export var empty_monologue_id: String = ""   # 非空 = 空海藻：搜索播内心 OS，不产道具、不变淡

var opened: bool = false
var _searched: bool = false
var _visual: CanvasItem


func _ready() -> void:
	add_to_group("hiding_spot")
	collision_layer = 2
	collision_mask = 1  # 扫描玩家所在层（层 1），双向碰撞才生效
	_build()


func _build() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	# 视觉：有美术资源用贴图，否则回退纯色多边形
	var path: String = Game.SPOT_TEXTURES.get(spot_type, "")
	if path != "" and ResourceLoader.exists(path):
		var spr := Sprite2D.new()
		spr.texture = load(path) as Texture2D
		spr.scale = _fit_scale(spr.texture.get_size())
		_visual = spr
	else:
		var poly := Polygon2D.new()
		poly.polygon = _polygon()
		poly.color = _color()
		poly.scale = _fit_scale(Vector2(48, 56))
		_visual = poly
	add_child(_visual)


## 保持长宽比，把视觉缩放到 size 框内
func _fit_scale(base: Vector2) -> Vector2:
	var s := minf(size.x / base.x, size.y / base.y)
	return Vector2(s, s)


func _polygon() -> PackedVector2Array:
	if spot_type == "shell":
		return PackedVector2Array([
			Vector2(-24, 0), Vector2(-20, -14), Vector2(-10, -22),
			Vector2(4, -24), Vector2(18, -16), Vector2(24, 0), Vector2(0, 6)
		])
	# 海藻：起伏的竖条
	return PackedVector2Array([
		Vector2(-22, -28), Vector2(-16, -18), Vector2(-20, -6), Vector2(-14, 6),
		Vector2(-20, 18), Vector2(-14, 28), Vector2(14, 28), Vector2(20, 18),
		Vector2(14, 6), Vector2(20, -6), Vector2(16, -18), Vector2(22, -28)
	])


func _color() -> Color:
	if spot_type == "shell":
		return Color(0.85, 0.7, 0.5)
	return Color(0.2, 0.6, 0.32)


func open() -> void:
	if opened:
		return
	Sound.play_sfx("search")  # 搜索音效（按空格）
	if empty_monologue_id != "":
		_open_empty()
		return
	opened = true
	# 拨开 / 打开：视觉变淡 + 取消碰撞
	_visual.modulate.a = 0.3
	collision_layer = 0
	_spawn_item()


## 空海藻：不变淡、不清碰撞、不产道具；首次播内心 OS，再次提示已搜索
func _open_empty() -> void:
	if not _searched:
		_searched = true
		Game.start_dialogue(Game.get_dialogue(empty_monologue_id))
	else:
		Game.search_again.emit()


func _spawn_item() -> void:
	var item := Area2D.new()
	item.name = "HiddenItem"
	item.set_script(preload("res://scripts/interactable.gd"))
	item.set("item_id", item_id)
	item.set("is_foreshadow", item_is_foreshadow)
	add_child(item)
