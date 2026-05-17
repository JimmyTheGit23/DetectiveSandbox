extends Node
## 全局设置：BGM 音量 / 语音音量 / 持久化到 user://settings.cfg
##
## 用线性 0.0..1.0 表示音量；内部转换为 volume_db 应用到 BgmPlayer / VoicePlayer。
## 0 = 静音（< -60 dB）；1 = 默认音量（0 dB）。

signal settings_changed()

const SAVE_PATH := "user://settings.cfg"

var bgm_volume: float = 0.8  # 0.0 .. 1.0
var voice_volume: float = 1.0
var gm_unlock_all: bool = false  # GM 指令：无视条件解锁所有案件

# BgmPlayer 的"默认播放音量"是 default_volume_db（默认 -12 dB），这里再叠加用户系数。
# voice_player 的"默认 volume_db"是 0 dB（直接出）。


func _ready() -> void:
	load_settings()
	# 等 autoload 全部就绪后再应用，避免播放器还没构造好
	call_deferred("apply_to_players")


func set_bgm_volume(v: float) -> void:
	bgm_volume = clampf(v, 0.0, 1.0)
	_apply_bgm()
	save_settings()
	settings_changed.emit()


func set_voice_volume(v: float) -> void:
	voice_volume = clampf(v, 0.0, 1.0)
	_apply_voice()
	save_settings()
	settings_changed.emit()


func set_gm_unlock_all(enabled: bool) -> void:
	gm_unlock_all = enabled
	save_settings()
	settings_changed.emit()


func apply_to_players() -> void:
	_apply_bgm()
	_apply_voice()


func _linear_to_db(v: float) -> float:
	if v <= 0.001:
		return -80.0
	# 用 linear_to_db 标准换算
	return linear_to_db(v)


func _apply_bgm() -> void:
	var bgm := get_node_or_null("/root/BgmPlayer")
	if bgm == null:
		return
	# 在 BgmPlayer 的 default_volume_db 基础上叠加用户调节
	# 静音（v=0）直接禁用播放
	if bgm_volume <= 0.001:
		if bgm.has_method("set_enabled"):
			bgm.set_enabled(false)
		return
	if bgm.has_method("set_enabled"):
		bgm.set_enabled(true)
	# 直接覆盖 default_volume_db 与当前活动播放器音量
	# default_volume_db 范围：-30 dB（很小）.. 0 dB（最大）
	var target_db: float = lerp(-30.0, 0.0, bgm_volume)
	if "default_volume_db" in bgm:
		bgm.default_volume_db = target_db
	# 立即应用到当前正在播放的 player
	var active = bgm.get("_active_player")
	if active != null and is_instance_valid(active):
		active.volume_db = target_db


func _apply_voice() -> void:
	var vp := get_node_or_null("/root/VoicePlayer")
	if vp == null:
		return
	if voice_volume <= 0.001:
		if vp.has_method("set"):
			vp.enabled = false
		return
	vp.enabled = true
	var target_db: float = lerp(-30.0, 0.0, voice_volume)
	vp.volume_db = target_db
	# 应用到内部 _player
	var inner = vp.get("_player")
	if inner != null and is_instance_valid(inner):
		inner.volume_db = target_db


# ─── 持久化 ───
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "bgm_volume", bgm_volume)
	cfg.set_value("audio", "voice_volume", voice_volume)
	cfg.set_value("gm", "unlock_all", gm_unlock_all)
	var _err := cfg.save(SAVE_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return
	bgm_volume = float(cfg.get_value("audio", "bgm_volume", bgm_volume))
	voice_volume = float(cfg.get_value("audio", "voice_volume", voice_volume))
	gm_unlock_all = bool(cfg.get_value("gm", "unlock_all", gm_unlock_all))
