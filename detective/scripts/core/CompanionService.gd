extends Node
## 助手系统服务（Companion System）
##
## 管理助手的被动旁白（Banter）和主动讨论（Discussion）。
## 助手不会撒谎，但能力有限，信息不一定准确。
##
## 信号：
##   banter_ready(lines: Array)          — 被动旁白准备好，UI 应播放
##   topic_state_changed()               — 讨论话题可用状态变化
##   companion_joined()                  — 助手加入（案件开始时）

signal banter_ready(lines: Array)
signal topic_state_changed()
signal companion_joined()

# ─── 配置路径 ───
const COMPANIONS_REGISTRY_PATH := "res://data/companions/registry.json"

# ─── 运行时数据 ───
var _registry: Dictionary = {}           # companions registry (全局)
var _case_config: Dictionary = {}        # 当前案件的 companion.json
var _discussions: Dictionary = {}        # 当前案件的 discussions.json
var _banter_data: Dictionary = {}        # 当前案件的 banter.json（通用旁白）

# ─── 助手状态 ───
var _active: bool = false
var _companion_id: String = ""
var _role_name: String = ""
var _actor_id: String = ""

# ─── 限流状态（每日重置）───
var _topic_usage: Dictionary = {}        # topic_id -> { "used_on_days": [...] }
var _seen_banters: Dictionary = {}       # "context_key" -> true
var _banter_count_today: int = 0
var _last_banter_day: int = 0


func _ready() -> void:
	_load_registry()
	# 在 GameManager 加载完案件后初始化（GameManager 在 autoload 列表中排在前面，已就绪）
	_init_for_case()
	# 监听日切换重置每日计数
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)


# ─── 加载 ──────────────────────────────────────────────────────────────────

func _load_registry() -> void:
	if not FileAccess.file_exists(COMPANIONS_REGISTRY_PATH):
		push_warning("[CompanionService] registry.json not found.")
		return
	var f := FileAccess.open(COMPANIONS_REGISTRY_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_registry = parsed


func _init_for_case() -> void:
	var case_id: String = GameManager.ACTIVE_CASE
	var config_path := "res://data/cases/%s/companion/companion.json" % case_id
	var discuss_path := "res://data/cases/%s/companion/discussions.json" % case_id
	var banter_path := "res://data/cases/%s/companion/banter.json" % case_id

	_case_config = _read_json(config_path)
	_discussions = _read_json(discuss_path)
	_banter_data = _read_json(banter_path)

	if _case_config.is_empty():
		_active = false
		return

	_companion_id = _case_config.get("companion_id", "")
	_role_name = _case_config.get("role_name", "")
	_actor_id = _case_config.get("actor_id", "")
	_active = _companion_id != ""

	if _active:
		companion_joined.emit()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


## 切案件时调用
func reload_for_case() -> void:
	_topic_usage.clear()
	_seen_banters.clear()
	_banter_count_today = 0
	_last_banter_day = 0
	_init_for_case()


# ─── 公开查询 ──────────────────────────────────────────────────────────────

func has_companion() -> bool:
	return _active


func get_companion_id() -> String:
	return _companion_id


func get_companion_role_name() -> String:
	return _role_name


func get_companion_actor_id() -> String:
	return _actor_id


## 获取助手立绘路径
func get_companion_portrait() -> String:
	if _companion_id == "":
		return ""
	var companions: Dictionary = _registry.get("companions", {})
	var comp: Dictionary = companions.get(_companion_id, {})
	# 优先使用独立 portrait 字段
	var portrait: String = comp.get("portrait", "")
	if portrait != "":
		return portrait
	# 回退：从 actors registry 通过 actor_id 取
	var aid: String = comp.get("actor_id", _actor_id)
	if AssetResolver.has_method("get_portrait_for_actor"):
		return AssetResolver.get_portrait_for_actor(aid)
	return ""


# ─── 被动旁白（Banter）──────────────────────────────────────────────────────

## 由 DialogueManager 在关键节点结束时调用
## context: { trigger: String, npc_id: String, node_id: String, gained_clue: String, gained_evidence: String }
func try_emit_banter(context: Dictionary) -> void:
	if not _active:
		return

	# 每日上限检查
	var max_per_day: int = int(_case_config.get("banter_max_per_day", 8))
	if _last_banter_day != GameManager.current_day:
		_banter_count_today = 0
		_last_banter_day = GameManager.current_day
	if _banter_count_today >= max_per_day:
		return

	# 去重
	var ctx_key := "%s.%s.%s" % [
		context.get("npc_id", ""),
		context.get("node_id", ""),
		context.get("trigger", "")
	]
	if _seen_banters.has(ctx_key):
		return

	# 1) 先查 banter.json 的 rules（通用旁白）
	var lines: Array = _match_banter_rules(context)

	# 2) 如果没匹配到通用，看对话节点自带的 companion_banter（内嵌方式）
	if lines.is_empty():
		var node_banter: Array = context.get("companion_banter", [])
		if not node_banter.is_empty():
			lines = node_banter

	if lines.is_empty():
		return

	_seen_banters[ctx_key] = true
	_banter_count_today += 1
	banter_ready.emit(lines)


func _match_banter_rules(context: Dictionary) -> Array:
	var rules: Array = _banter_data.get("rules", [])
	var trigger: String = context.get("trigger", "")
	for rule in rules:
		if typeof(rule) != TYPE_DICTIONARY:
			continue
		var when: Dictionary = rule.get("when", {})
		var rule_trigger: String = when.get("trigger", "")
		if rule_trigger != "" and rule_trigger != trigger:
			continue
		# npc_id 条件匹配
		var npc_id: String = when.get("npc_id", "")
		if npc_id != "" and npc_id != context.get("npc_id", ""):
			continue
		# 额外条件匹配
		var evidence: String = when.get("evidence", "")
		if evidence != "" and evidence != context.get("gained_evidence", ""):
			continue
		var clue: String = when.get("clue", "")
		if clue != "" and clue != context.get("gained_clue", ""):
			continue
		# cooldown 检查
		var rule_id: String = rule.get("id", "")
		if rule_id != "" and _seen_banters.has("rule:" + rule_id):
			continue
		# 匹配成功
		if rule_id != "":
			_seen_banters["rule:" + rule_id] = true
		var lines_pool: Array = rule.get("lines", [])
		if lines_pool.is_empty():
			continue
		# 随机取一条或全部返回
		var pick: String = lines_pool[randi() % lines_pool.size()]
		return [{"text": pick, "speaker": _role_name}]
	return []


# ─── 主动讨论（Discussion）─────────────────────────────────────────────────

## 获取话题列表及其状态
func get_available_topics() -> Array:
	var topics: Array = _case_config.get("available_topics", [])
	var result: Array = []
	for topic_id in topics:
		result.append({
			"id": topic_id,
			"state": get_topic_state(topic_id),
		})
	return result


## 获取单个话题的状态
func get_topic_state(topic_id: String) -> Dictionary:
	if not _active:
		return {"available": false, "reason": "no_companion"}

	var limits: Dictionary = _case_config.get("limits", {}).get(topic_id, {})
	var per_day: int = int(limits.get("per_day", 1))
	var cost_period: int = int(limits.get("cost_period", 0))
	var cost_cognitive: int = int(limits.get("cost_cognitive", 0))

	# 终局日锁定
	var lock_final: bool = _case_config.get("lock_on_final_day", false)
	if lock_final and GameManager.current_day >= GameManager.TOTAL_DAYS:
		if topic_id != "chitchat":
			return {"available": false, "reason": "final_day_locked", "remaining": 0}

	# 今日使用次数
	var usage: Dictionary = _topic_usage.get(topic_id, {})
	var used_days: Array = usage.get("used_on_days", [])
	var today_count: int = 0
	for d in used_days:
		if int(d) == GameManager.current_day:
			today_count += 1

	var remaining: int = max(0, per_day - today_count)
	if remaining <= 0:
		return {"available": false, "reason": "daily_limit", "remaining": 0}

	# 时段不够
	if cost_period > 0 and GameManager.remaining_periods() <= cost_period:
		return {"available": false, "reason": "no_time", "remaining": remaining}

	return {
		"available": true,
		"remaining": remaining,
		"cost_period": cost_period,
		"cost_cognitive": cost_cognitive,
	}


## 执行讨论，返回对话行
func discuss(topic_id: String) -> Array:
	var state := get_topic_state(topic_id)
	if not state.get("available", false):
		return []

	# 记录使用
	if not _topic_usage.has(topic_id):
		_topic_usage[topic_id] = {"used_on_days": []}
	_topic_usage[topic_id]["used_on_days"].append(GameManager.current_day)

	# 消耗时段
	var limits: Dictionary = _case_config.get("limits", {}).get(topic_id, {})
	var cost_period: int = int(limits.get("cost_period", 0))
	if cost_period > 0:
		GameManager.advance_period(cost_period)

	topic_state_changed.emit()

	# 匹配台词
	var lines := _resolve_discussion(topic_id)
	return lines


func _resolve_discussion(topic_id: String) -> Array:
	var topic_data = _discussions.get(topic_id, {})
	if typeof(topic_data) != TYPE_DICTIONARY:
		return [{"speaker": _role_name, "text": "嗯……我也没什么头绪。"}]

	var rules: Array = topic_data.get("rules", [])
	# 对 chitchat 用 pool
	if topic_id == "chitchat":
		var pool: Array = topic_data.get("pool", [])
		if pool.is_empty():
			return [{"speaker": _role_name, "text": "陆大人，歇歇吧。"}]
		var item = pool[randi() % pool.size()]
		if item is String:
			return [{"speaker": _role_name, "text": item}]
		if item is Dictionary:
			var lines_arr: Array = item.get("lines", [])
			var result: Array = []
			for l in lines_arr:
				result.append({"speaker": _role_name, "text": l})
			return result
		return [{"speaker": _role_name, "text": str(item)}]

	# 规则匹配
	for rule in rules:
		if typeof(rule) != TYPE_DICTIONARY:
			continue
		var when = rule.get("when", {})
		if _evaluate_discussion_condition(when):
			var lines_arr: Array = rule.get("lines", [])
			var result: Array = []
			for l in lines_arr:
				result.append({"speaker": _role_name, "text": l})
			return result

	# 兜底
	return [{"speaker": _role_name, "text": "唔……这个我也说不清，您比我懂。"}]


func _evaluate_discussion_condition(when) -> bool:
	if when == null:
		return true
	if typeof(when) != TYPE_DICTIONARY:
		return true
	var d: Dictionary = when
	if d.is_empty():
		return true
	if d.get("default", false):
		return true

	# day 条件
	if d.has("day"):
		if GameManager.current_day != int(d["day"]):
			return false
	if d.has("day_gte"):
		if GameManager.current_day < int(d["day_gte"]):
			return false
	if d.has("day_lte"):
		if GameManager.current_day > int(d["day_lte"]):
			return false

	# period 条件
	if d.has("period_lte"):
		if GameManager.current_period > int(d["period_lte"]):
			return false

	# 线索条件
	if d.has("has_clue"):
		if not GameManager.has_clue(d["has_clue"]):
			return false
	if d.has("has_evidence"):
		if not GameManager.has_evidence(d["has_evidence"]):
			return false
	if d.has("has_flag"):
		if not GameManager.has_flag(d["has_flag"]):
			return false
	if d.has("not_flag"):
		if GameManager.has_flag(d["not_flag"]):
			return false

	# 未访问地点
	if d.has("not_visited"):
		var loc: String = d["not_visited"]
		if GameManager.visited_locations.has(loc):
			return false

	# 证据充足度
	if d.has("evidence_ratio_gte"):
		var key_ev: Array = GameManager.case_data.get("key_evidence", [])
		var total: int = key_ev.size()
		if total == 0:
			return false
		var count: int = 0
		for ev in key_ev:
			if GameManager.has_evidence(ev):
				count += 1
		var ratio: float = float(count) / float(total)
		if ratio < float(d["evidence_ratio_gte"]):
			return false

	return true


# ─── 日切换重置 ────────────────────────────────────────────────────────────

func _on_day_changed(_new_day: int) -> void:
	topic_state_changed.emit()


# ─── 存档 / 读档 ──────────────────────────────────────────────────────────

func get_save_data() -> Dictionary:
	return {
		"topic_usage": _topic_usage,
		"seen_banters": _seen_banters,
		"banter_count_today": _banter_count_today,
		"last_banter_day": _last_banter_day,
	}


func load_save_data(data: Dictionary) -> void:
	_topic_usage = data.get("topic_usage", {})
	_seen_banters = data.get("seen_banters", {})
	_banter_count_today = int(data.get("banter_count_today", 0))
	_last_banter_day = int(data.get("last_banter_day", 0))
