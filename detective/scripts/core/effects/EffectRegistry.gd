extends Node
## EffectRegistry — 内容执行层统一入口（三层架构 Layer 3）
##
## 所有"内容效果"（发证据 / 置 flag / 解锁阶段 / 切地点…）的唯一执行点。
## 此前同样的效果应用代码在 GameManager / DialogueManager / CompanionService
## 各有一份，现已全部收敛到这里。
##
## 新机制接入方式：register_effect() 注册新 handler，无需改动框架层。
##
## context 约定：
##   hold_obtain_display: bool — 证据获得弹窗是否停留展示（默认 true）

signal effect_applied(effect_name: String, value, context: Dictionary)

## 内置效果执行顺序：保持与旧 GameManager.apply_event_effects 完全一致的落库顺序
## （set_flag → gain_clue → done flag → gain_evidence → unlock_phase → change_location）
const _EXECUTION_ORDER: Array[String] = [
	"set_flag",
	"gain_clue",
	"auto_done_flag",
	"gain_evidence",
	"unlock_phase",
	"change_location",
]

var _handlers: Dictionary = {}  # effect_name -> Callable(value, context)


func _ready() -> void:
	_register_builtin_handlers()


## 注册效果处理器。handler 签名: func(value, context: Dictionary) -> void
## 同名重复注册会覆盖（允许热替换/测试桩）。
func register_effect(effect_name: String, handler: Callable) -> void:
	if effect_name == "" or not handler.is_valid():
		push_error("[EffectRegistry] invalid register: %s" % effect_name)
		return
	_handlers[effect_name] = handler


func has_effect(effect_name: String) -> bool:
	return _handlers.has(effect_name)


## 应用一组效果。内置效果按 _EXECUTION_ORDER 顺序执行；
## 其余已注册的自定义效果按字典顺序随后执行。未注册 key 仅告警不中断。
func apply_effects(effects, context: Dictionary = {}) -> void:
	if effects == null or typeof(effects) != TYPE_DICTIONARY:
		return
	var d: Dictionary = effects
	if d.is_empty():
		return
	for key in _EXECUTION_ORDER:
		if d.has(key):
			apply_effect(key, d[key], context)
	for key in d.keys():
		if _EXECUTION_ORDER.has(key):
			continue
		if _handlers.has(str(key)):
			apply_effect(str(key), d[key], context)
		else:
			push_warning("[EffectRegistry] unknown effect key: %s" % str(key))


func apply_effect(effect_name: String, value, context: Dictionary = {}) -> void:
	var handler: Callable = _handlers.get(effect_name, Callable())
	if not handler.is_valid():
		push_warning("[EffectRegistry] no handler for effect: %s" % effect_name)
		return
	handler.call(value, context)
	effect_applied.emit(effect_name, value, context)


# ─── 内置效果 ───
func _register_builtin_handlers() -> void:
	register_effect("set_flag", _effect_set_flag)
	register_effect("gain_clue", _effect_gain_clue)
	register_effect("gain_evidence", _effect_gain_evidence)
	register_effect("unlock_phase", _effect_unlock_phase)
	register_effect("change_location", _effect_change_location)
	register_effect("auto_done_flag", _effect_auto_done_flag)
	# 演出类 key：实际执行在 MainGame._on_narration_effects（narration_effects 信号）。
	# 此处注册为空操作，仅消除 "unknown effect key" 告警，让数据层可自由书写演出效果。
	for k in ["sfx", "mind_sfx", "bgm", "bgm_stop", "sfx_loop", "sfx_loop_stop", "shake", "shake_intensity", "shake_duration", "flash", "flash_duration", "tint", "bg_offset_y", "disable_typewriter_skip", "typewriter_char_delay"]:
		register_effect(k, _effect_noop_presentation)


static func _as_string_list(value) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for v in value:
			out.append(str(v))
	elif value is String:
		if value != "":
			out.append(value)
	elif value != null:
		out.append(str(value))
	return out


func _effect_set_flag(value, _context: Dictionary) -> void:
	for flag_id in _as_string_list(value):
		GameManager.set_flag(flag_id)


func _effect_gain_clue(value, _context: Dictionary) -> void:
	for clue_id in _as_string_list(value):
		GameManager.add_clue(clue_id)


func _effect_gain_evidence(value, context: Dictionary) -> void:
	var hold := bool(context.get("hold_obtain_display", true))
	for evidence_id in _as_string_list(value):
		GameManager.add_evidence(evidence_id, hold)


func _effect_unlock_phase(value, _context: Dictionary) -> void:
	var phase_id := str(value)
	if phase_id == "":
		return
	if not GameManager.unlocked_phases.has(phase_id):
		GameManager.unlocked_phases.append(phase_id)
		GameManager.phase_unlocked.emit(phase_id)
		GameManager.save_game()


func _effect_change_location(value, _context: Dictionary) -> void:
	var loc_id := str(value)
	if loc_id != "":
		GameManager.change_location(loc_id, false)


## 事件完成后自动落 "<evt_id>_done" flag（与 day_events trigger 里的 not flag 配对）
func _effect_auto_done_flag(value, _context: Dictionary) -> void:
	var source_id := str(value)
	if source_id != "":
		GameManager.set_flag(source_id + "_done")


## 演出类效果空操作：sfx/shake/flash/tint 等由 MainGame._on_narration_effects 消费，
## 本 handler 仅占位，避免 EffectRegistry 报 unknown key。
func _effect_noop_presentation(_value, _context: Dictionary) -> void:
	pass
