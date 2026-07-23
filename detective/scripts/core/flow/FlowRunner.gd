extends Node
## FlowRunner — 流程骨架层（三层架构 Layer 1）
##
## 职责：
##   1) 大阶段状态机：驱动 阶段进入 → 钩子 → 转移条件求值 → 下一阶段。
##      本层不认识任何具体案件内容，阶段定义全部来自数据（json_docs 的 flow 文档）。
##   2) 对峙后路由数据查询：confront_key → 胜利/失败后的 flag 设置、缓冲台词、
##      后续事件链、结局覆盖。此前这些硬编码在 MainGame 的 match 里。
##
## 扩展方式：加阶段类型 / 在 flow 数据里加字段，本层不需要改。
##
## flow 数据格式（json_docs.csv, doc_id="flow"）：
## {
##   "start": "cabin",
##   "phases": [
##     {"id": "cabin", "type": "search",
##      "next_when": {"flag": "cabin_phase_done"}, "next": "accused",
##      "enter_effects": {"set_flag": "..."}          # 可选
##     }, ...
##   ],
##   "confrontation_routes": {
##     "confrontation_wang": {
##       "victory_flags": [...],                      # 胜利时设置（在 <key>_completed 前）
##       "final_flags": [...],                        # final 对峙结束时无论胜败都设置
##       "ending_override": "prologue_fixed",         # final 结局覆盖
##       "victory_buffer": [{"speaker":..,"text":..}], # 胜利后缓冲台词（adhoc narration）
##       "victory_event": "evt_id",                   # 胜利后接续单个事件
##       "victory_event_chain": ["evt_a", "evt_b"],   # 胜利后事件链
##       "match_suspect": "agui"                      # 可选：仅当 suspect 匹配时生效
##     }, ...
##   ]
## }

signal phase_changed(phase_id: String, phase_type: String)

# ─── 大阶段类型（冻结层；新类型在此追加） ───
const PHASE_PROLOGUE := "prologue"
const PHASE_SEARCH := "search"
const PHASE_EVENT := "event"
const PHASE_CONFRONTATION := "confrontation"
const PHASE_ACCUSATION := "accusation"
const PHASE_ENDING := "ending"

var current_phase: String = ""
var _flow: Dictionary = {}
var _phases: Dictionary = {}   # phase_id -> def
var _fast_forwarding := false


func _ready() -> void:
	call_deferred("_init_flow")


func _init_flow() -> void:
	reload_for_case()
	HookBus.subscribe(HookBus.CASE_SWITCHED, _on_case_switched)
	HookBus.subscribe(HookBus.SAVE_LOADED, _on_save_loaded)
	# 阶段转移检查在 day_events(20)/progression(10) 之后执行
	HookBus.subscribe(HookBus.FLAG_SET, _on_state_mutated, 5)
	HookBus.subscribe(HookBus.EVIDENCE_ADDED, _on_state_mutated, 5)
	HookBus.subscribe(HookBus.CLUE_ADDED, _on_state_mutated, 5)


# ─── 数据加载 ───
func reload_for_case() -> void:
	_flow = CaseTableLoader.load_flow(GameManager.ACTIVE_CASE)
	_phases.clear()
	for p in _flow.get("phases", []):
		var pid: String = str(p.get("id", ""))
		if pid != "":
			_phases[pid] = p
	current_phase = str(_flow.get("start", ""))
	_fast_forward()


func has_flow() -> bool:
	return not _flow.is_empty() and not _phases.is_empty()


func _on_case_switched(_payload: Dictionary) -> void:
	reload_for_case()


## 读档后：从起点按已存 flag 快进推导当前阶段（推导幂等，无需入档）
func _on_save_loaded(_payload: Dictionary) -> void:
	if not has_flow():
		return
	current_phase = str(_flow.get("start", ""))
	_fast_forward()


# ─── 阶段推进 ───
func _on_state_mutated(_payload: Dictionary) -> void:
	if not has_flow():
		return
	_try_advance()


## 尝试推进一次；_fast_forwarding 时循环推进直到稳定（读档/切案场景）
func _fast_forward() -> void:
	if not has_flow():
		return
	_fast_forwarding = true
	var guard := 0
	while guard < 32:
		if not _try_advance():
			break
		guard += 1
	_fast_forwarding = false


func _try_advance() -> bool:
	var phase: Dictionary = _phases.get(current_phase, {})
	if phase.is_empty():
		return false
	var cond = phase.get("next_when", null)
	if cond == null:
		return false
	if not GameManager.evaluate_condition(cond):
		return false
	var next_id: String = str(phase.get("next", ""))
	if next_id == "" or not _phases.has(next_id):
		return false
	_advance_to(next_id)
	return true


func _advance_to(phase_id: String) -> void:
	var old_id := current_phase
	var next_def: Dictionary = _phases.get(phase_id, {})
	var next_type: String = str(next_def.get("type", ""))
	if not _fast_forwarding:
		HookBus.emit_hook(HookBus.PHASE_EXITING, {"phase_id": old_id, "next": phase_id})
	current_phase = phase_id
	if not _fast_forwarding:
		HookBus.emit_hook(HookBus.PHASE_ENTERING, {"phase_id": phase_id, "phase_type": next_type})
		var enter_effects: Dictionary = next_def.get("enter_effects", {})
		if not enter_effects.is_empty():
			EffectRegistry.apply_effects(enter_effects, {"source": "flow_phase:" + phase_id})
		HookBus.emit_hook(HookBus.PHASE_ENTERED, {"phase_id": phase_id, "phase_type": next_type})
		phase_changed.emit(phase_id, next_type)


func current_phase_type() -> String:
	return str(_phases.get(current_phase, {}).get("type", ""))


## 读档恢复标记（如序章船舱阶段判断）：{any_flags: [], any_clues: []}，无配置返回 {}
func get_resume_markers() -> Dictionary:
	return _flow.get("resume_markers", {})


## 强制对峙配置（教学对峙等）：{confront_key, when, location}，无配置返回 {}
func get_forced_confrontation() -> Dictionary:
	return _flow.get("forced_confrontation", {})


# ─── 对峙后路由查询 ───
## 返回 confront_key 对应的路由 dict；match_suspect 不匹配或无定义时返回 {}。
## suspect 由调用方从 case_data 读出传入（骨架层不读案件内容）。
func get_confrontation_route(confront_key: String, suspect: String = "") -> Dictionary:
	var routes: Dictionary = _flow.get("confrontation_routes", {})
	if not routes.has(confront_key):
		return {}
	var route: Dictionary = routes[confront_key]
	var match_suspect: String = str(route.get("match_suspect", ""))
	if match_suspect != "" and match_suspect != suspect:
		return {}
	return route
