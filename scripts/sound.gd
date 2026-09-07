extends Node

## 全局音频（autoload 单例 Sound）：背景音乐 + 音效
## 音频资产放进 assets/audio/，缺失时静默跳过（不报错、不崩溃）。
## 播放时机（跳过开头静音 / 只播一段）按 sound1.md 配置在下面的 *_START / SFX_DURATION。

const BGM_PATHS := {
	"start": "res://assets/audio/bgm_start.mp3",
	"prologue": "res://assets/audio/bgm_prologue.mp3",
	"chapter1": "res://assets/audio/bgm_chapter1.mp3",
	"chapter2": "res://assets/audio/bgm_chapter2.mp3",
}

const SFX_PATHS := {
	"start_button": "res://assets/audio/sfx_start_button.wav",
	"walk": "res://assets/audio/sfx_walk.wav",
	"search": "res://assets/audio/sfx_search.wav",
	"pickup": "res://assets/audio/sfx_pickup.wav",
	"use_shell": "res://assets/audio/sfx_use_shell.wav",
	"use_line": "res://assets/audio/sfx_use_line.wav",
	"wrap": "res://assets/audio/sfx_wrap.wav",
}

## BGM 播放起点（秒）：跳过文件开头的静音（sound1.md）
const BGM_START := {
	"start": 0.07,
	"prologue": 0.06,
	"chapter1": 0.06,
	"chapter2": 0.07,
}

## 音效播放起点（秒）
const SFX_START := {
	"search": 0.07,
	"use_line": 0.08,
	"wrap": 0.0,
}

## 音效播放时长（秒）：>0 表示播这么长后自动停止；0 表示播到自然结束
const SFX_DURATION := {
	"search": 1.0,
	"use_line": 1.0,
	"wrap": 0.04,
}

## 音乐音量（dB）：略低于音效，避免 BGM 盖过走路/搜索等音效
const BGM_VOLUME_DB := -8.0

## 音效池大小：同一帧最多同时播放这么多个一次性音效
const SFX_POOL_SIZE := 8

var _bgm: AudioStreamPlayer
var _walk: AudioStreamPlayer
var _walk_stream: AudioStream
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_timers: Array[Timer] = []
var _fade_tween: Tween


func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)

	_walk = AudioStreamPlayer.new()
	add_child(_walk)

	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
		var t := Timer.new()
		t.one_shot = true
		t.timeout.connect(p.stop)
		add_child(t)
		_sfx_timers.append(t)


func play_bgm(id: String) -> void:
	_kill_fade()
	var stream := _load_bgm_stream(id)
	if stream == null:
		return
	if _bgm.stream == stream and _bgm.playing:
		return  # 同一首已在播，不打断
	_bgm.stream = stream
	_bgm.volume_db = BGM_VOLUME_DB
	_bgm.play(BGM_START.get(id, 0.0))


func stop_bgm() -> void:
	_kill_fade()
	_bgm.stop()


## 背景音乐渐弱（duration 秒内降到近静音后停止）
func fade_out_bgm(duration: float) -> void:
	_kill_fade()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_bgm, "volume_db", -40.0, duration)
	_fade_tween.tween_callback(_after_fade_out)


func _after_fade_out() -> void:
	_bgm.stop()
	_bgm.volume_db = BGM_VOLUME_DB
	_fade_tween = null


func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func play_sfx(id: String) -> void:
	var stream := _load(SFX_PATHS.get(id, ""))
	if stream == null:
		return
	var idx := _free_sfx_index()
	if idx == -1:
		return
	var p := _sfx_pool[idx]
	p.stream = stream
	p.play(SFX_START.get(id, 0.0))
	var dur: float = SFX_DURATION.get(id, 0.0)
	if dur > 0.0:
		_sfx_timers[idx].start(dur)
	else:
		_sfx_timers[idx].stop()


## 走路音效：on 时循环播放，off 时停止
func set_walking(on: bool) -> void:
	if _walk_stream == null:
		_walk_stream = _load(SFX_PATHS.get("walk", ""))
		if _walk_stream != null:
			_walk_stream.set("loop_mode", 1)  # 走路音效循环
	if _walk_stream == null:
		return
	if on:
		if not _walk.playing:
			_walk.stream = _walk_stream
			_walk.play()
	else:
		_walk.stop()


func _load_bgm_stream(id: String) -> AudioStream:
	var stream := _load(BGM_PATHS.get(id, ""))
	if stream == null:
		return null
	stream.set("loop_mode", 1)  # 1 = LOOP_FORWARD（循环）
	var offset: float = BGM_START.get(id, 0.0)
	if offset > 0.0 and "loop_offset" in stream:
		stream.set("loop_offset", offset)  # 循环时也从 offset 开始，跳过开头静音
	return stream


func _load(path: String) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _free_sfx_index() -> int:
	for i in range(_sfx_pool.size()):
		if not _sfx_pool[i].playing:
			return i
	return -1
