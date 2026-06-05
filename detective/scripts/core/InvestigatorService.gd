extends Node
## 推理者计划 · 调查员档案服务
##
## 跨案件持久化玩家档案：代号 / 等级 / XP / 通关记录 / 已解锁案件。
## 与单案存档完全独立：user://investigator.json。
##
## 信号：
##   xp_changed(new_xp, delta)
##   rank_changed(old_rank, new_rank, new_title)
##   case_cleared(case_id, ending_id, earned_xp)
##   case_unlocked(case_id)
##   codename_changed(codename)

signal xp_changed(new_xp: int, delta: int)
signal rank_changed(old_rank: int, new_rank: int, new_title: String)
signal case_cleared(case_id: String, ending_id: String, earned_xp: int)
signal case_unlocked(case_id: String)
signal codename_changed(codename: String)

const PROFILE_PATH := "user://investigator.json"
const RANKS_PATH := "res://data/meta/ranks.json"
const DEFAULT_CODENAME := "无名调查员"
const PROFILE_VERSION := 1

# 调查员档案
var codename: String = ""
var rank: int = 1
var xp: int = 0
var cleared_cases: Dictionary = {}   # case_id -> { best_ending, first_cleared_at, play_count, earned_xp }
var unlocked_cases: Array = []       # [case_id, ...]
var meta_flags: Dictionary = {}

# 等级表（从 ranks.json 加载）
var _ranks_data: Dictionary = {}
var _ranks: Array = []               # [{rank,title,xp_required}, ...]
var _ending_xp: Dictionary = {}
var _replay_multiplier: float = 0.3
var _first_clear_bonus: int = 50


func _ready() -> void:
	_load_ranks()
	_load_profile()
	_apply_initial_unlocks()


# ─── 加载 / 保存 ──────────────────────────────────────────────────────────

func _load_ranks() -> void:
	if not FileAccess.file_exists(RANKS_PATH):
		push_warning("[InvestigatorService] ranks.json not found, using fallback table.")
		_ranks = [
			{ "rank": 1, "title": "实习侦探", "xp_required": 0 },
			{ "rank": 2, "title": "见习调查员", "xp_required": 200 },
		]
		_ending_xp = { "perfect": 200, "good": 140, "partial": 80, "bad": 30, "timeout": 20 }
		return
	var f := FileAccess.open(RANKS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_ranks_data = parsed
	_ranks = parsed.get("ranks", [])
	_ending_xp = parsed.get("ending_xp", {})
	_replay_multiplier = float(parsed.get("replay_xp_multiplier", 0.3))
	_first_clear_bonus = int(parsed.get("first_clear_bonus", 50))


func _load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		_create_default_profile()
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if f == null:
		_create_default_profile()
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_create_default_profile()
		return
	var d: Dictionary = parsed
	codename = String(d.get("codename", ""))
	rank = int(d.get("rank", 1))
	xp = int(d.get("xp", 0))
	cleared_cases = d.get("cleared_cases", {})
	unlocked_cases = d.get("unlocked_cases", [])
	meta_flags = d.get("meta_flags", {})


func _create_default_profile() -> void:
	codename = ""
	rank = 1
	xp = 0
	cleared_cases = {}
	unlocked_cases = []
	meta_flags = {}
	save_profile()


func save_profile() -> void:
	var data := {
		"version": PROFILE_VERSION,
		"codename": codename,
		"rank": rank,
		"xp": xp,
		"cleared_cases": cleared_cases,
		"unlocked_cases": unlocked_cases,
		"meta_flags": meta_flags,
	}
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))


## 启动时根据案件索引补全已自然解锁的案件（unlock_after 为空 或 前置案件已通关）
func _apply_initial_unlocks() -> void:
	var entries: Array = GameManager.get_case_index_entries() if GameManager else []
	var changed := false
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var cid: String = entry.get("id", "")
		var prereq: String = entry.get("unlock_after", "")
		var can_unlock := false
		if prereq == "":
			can_unlock = true
		elif cleared_cases.has(prereq):
			can_unlock = true
		if can_unlock and not unlocked_cases.has(cid):
			unlocked_cases.append(cid)
			changed = true
	if changed:
		save_profile()


# ─── 代号 ─────────────────────────────────────────────────────────────────

func has_codename() -> bool:
	return codename.strip_edges() != ""


func get_codename(fallback: String = DEFAULT_CODENAME) -> String:
	return codename if has_codename() else fallback


func set_codename(new_codename: String) -> void:
	codename = new_codename.strip_edges()
	save_profile()
	codename_changed.emit(codename)


# ─── 等级与 XP ────────────────────────────────────────────────────────────

func get_rank() -> int:
	return rank


func get_rank_title(r: int = -1) -> String:
	var target := rank if r < 0 else r
	for e in _ranks:
		if int(e.get("rank", 0)) == target:
			return String(e.get("title", ""))
	return ""


func get_max_rank() -> int:
	var m := 1
	for e in _ranks:
		m = max(m, int(e.get("rank", 1)))
	return m


func get_xp() -> int:
	return xp


## 距下一级所需总 XP（达上限返回当前 XP）
func xp_for_next_rank() -> int:
	for e in _ranks:
		if int(e.get("rank", 0)) == rank + 1:
			return int(e.get("xp_required", 0))
	# 满级
	for e in _ranks:
		if int(e.get("rank", 0)) == rank:
			return int(e.get("xp_required", xp))
	return xp


## 当前等级起始 XP
func xp_for_current_rank() -> int:
	for e in _ranks:
		if int(e.get("rank", 0)) == rank:
			return int(e.get("xp_required", 0))
	return 0


## 当前等级进度 0..1
func rank_progress() -> float:
	var cur := xp_for_current_rank()
	var nxt := xp_for_next_rank()
	if nxt <= cur:
		return 1.0
	return clampf(float(xp - cur) / float(nxt - cur), 0.0, 1.0)


## 加经验，自动判定升级；返回 { rank_up:bool, old_rank, new_rank }
func add_xp(amount: int) -> Dictionary:
	if amount == 0:
		return { "rank_up": false, "old_rank": rank, "new_rank": rank }
	var old_rank := rank
	xp = max(0, xp + amount)
	xp_changed.emit(xp, amount)
	# 检查升级（一次可能跨多级）
	while rank < get_max_rank():
		var threshold := 0
		for e in _ranks:
			if int(e.get("rank", 0)) == rank + 1:
				threshold = int(e.get("xp_required", 0))
				break
		if xp >= threshold:
			rank += 1
		else:
			break
	save_profile()
	if rank != old_rank:
		rank_changed.emit(old_rank, rank, get_rank_title(rank))
		_apply_initial_unlocks()
		return { "rank_up": true, "old_rank": old_rank, "new_rank": rank }
	return { "rank_up": false, "old_rank": old_rank, "new_rank": rank }


# ─── 案件结算 ─────────────────────────────────────────────────────────────

## 通关一个案件，按结局给 XP；返回 { earned_xp, rank_up, new_rank, unlocked:[case_id,...] }
func record_case_cleared(case_id: String, ending_id: String) -> Dictionary:
	var base := int(_ending_xp.get(ending_id, 0))
	var prev: Dictionary = cleared_cases.get(case_id, {})
	var is_first := prev.is_empty()
	var earned: float = float(base)
	if not is_first:
		earned = float(base) * _replay_multiplier
	earned += _first_clear_bonus if is_first else 0
	var earned_int := int(round(earned))

	# 写入档案
	var play_count: int = int(prev.get("play_count", 0)) + 1
	var best_ending: String = _best_ending(prev.get("best_ending", ""), ending_id)
	var record := {
		"best_ending": best_ending,
		"first_cleared_at": prev.get("first_cleared_at", Time.get_datetime_string_from_system()),
		"play_count": play_count,
		"earned_xp": int(prev.get("earned_xp", 0)) + earned_int,
		"last_ending": ending_id,
	}
	cleared_cases[case_id] = record
	save_profile()
	case_cleared.emit(case_id, ending_id, earned_int)

	# 加 XP（可能触发升级，进而解锁更多案件）
	var xp_result := add_xp(earned_int)

	# 收集本次新解锁的案件 ID（通关后，后续案件自动解锁）
	var newly_unlocked: Array = []
	var entries: Array = GameManager.get_case_index_entries() if GameManager else []
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var cid: String = entry.get("id", "")
		var prereq: String = entry.get("unlock_after", "")
		if prereq == case_id and not unlocked_cases.has(cid):
			unlocked_cases.append(cid)
			newly_unlocked.append(cid)
	# manifest.rewards.unlock_cases 显式追加（不看 rank）
	var manifest_path: String = ""
	for entry in entries:
		if entry.get("id", "") == case_id:
			manifest_path = entry.get("manifest", "")
			break
	if manifest_path != "" and FileAccess.file_exists(manifest_path):
		var mf := FileAccess.open(manifest_path, FileAccess.READ)
		if mf:
			var pm = JSON.parse_string(mf.get_as_text())
			if typeof(pm) == TYPE_DICTIONARY:
				var rewards: Dictionary = pm.get("rewards", {})
				for extra_cid in rewards.get("unlock_cases", []):
					var s := str(extra_cid)
					if not unlocked_cases.has(s):
						unlocked_cases.append(s)
						newly_unlocked.append(s)
				
				# 预埋 P3: meta_clue
				var meta_clue_data = pm.get("meta_clue", null)
				if typeof(meta_clue_data) == TYPE_DICTIONARY:
					var clue_id: String = meta_clue_data.get("id", "")
					var unlock_endings: Array = meta_clue_data.get("unlock_at_ending", [])
					var should_unlock_clue := false
					if unlock_endings.is_empty() or ending_id in unlock_endings:
						should_unlock_clue = true
					if should_unlock_clue and clue_id != "":
						if not meta_flags.has("unlocked_clues"):
							meta_flags["unlocked_clues"] = []
						if not meta_flags["unlocked_clues"].has(clue_id):
							meta_flags["unlocked_clues"].append(clue_id)
						if not meta_flags.has("clues_details"):
							meta_flags["clues_details"] = {}
						meta_flags["clues_details"][clue_id] = {
							"name": meta_clue_data.get("name", ""),
							"description": meta_clue_data.get("description", ""),
							"unlocked_from": case_id,
							"unlocked_at_ending": ending_id
						}
	if not newly_unlocked.is_empty():
		save_profile()
		for nu in newly_unlocked:
			case_unlocked.emit(nu)

	return {
		"earned_xp": earned_int,
		"first_clear": is_first,
		"rank_up": xp_result.get("rank_up", false),
		"old_rank": xp_result.get("old_rank", rank),
		"new_rank": rank,
		"unlocked": newly_unlocked,
	}


## 比较两个 ending，返回"更好"的那个（perfect > prologue_fixed/good > partial > bad > timeout > ""）
func _best_ending(a: String, b: String) -> String:
	const ORDER := ["timeout", "bad", "partial", "good", "prologue_fixed", "perfect"]
	var ia := ORDER.find(a)
	var ib := ORDER.find(b)
	return a if ia >= ib else b


# ─── 案件解锁 / 状态查询 ──────────────────────────────────────────────────

func is_case_unlocked(case_id: String) -> bool:
	# GM 模式：无视所有条件
	var ss := get_node_or_null("/root/SettingsService")
	if ss and ss.get("gm_unlock_all"):
		return true
	if unlocked_cases.has(case_id):
		return true
	# 按线性前置判断（防档案漂移）
	var entries: Array = GameManager.get_case_index_entries() if GameManager else []
	for entry in entries:
		if entry.get("id", "") == case_id:
			var prereq: String = entry.get("unlock_after", "")
			if prereq == "":
				return true  # 无前置，始终可用
			return cleared_cases.has(prereq)
	return false


func is_case_cleared(case_id: String) -> bool:
	return cleared_cases.has(case_id)


func get_case_record(case_id: String) -> Dictionary:
	return cleared_cases.get(case_id, {})


## 主屏要展示的案件列表（含锁定态），按 order 排序
func get_visible_cases() -> Array:
	var entries: Array = GameManager.get_case_index_entries() if GameManager else []
	# GM 模式：全部视为解锁
	var ss := get_node_or_null("/root/SettingsService")
	var gm_mode: bool = ss != null and bool(ss.get("gm_unlock_all"))
	var out: Array = []
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var cid: String = entry.get("id", "")
		var prereq: String = entry.get("unlock_after", "")
		var is_locked: bool = false
		if not gm_mode:
			if bool(entry.get("locked", false)):
				is_locked = true
			elif prereq != "" and not cleared_cases.has(prereq):
				is_locked = true
		var record: Dictionary = cleared_cases.get(cid, {})
		out.append({
			"entry": entry,
			"locked": is_locked,
			"unlock_after": prereq,
			"cleared": not record.is_empty(),
			"best_ending": record.get("best_ending", ""),
			"play_count": int(record.get("play_count", 0)),
		})
	return out


# ─── Debug ────────────────────────────────────────────────────────────────

func reset_profile() -> void:
	_create_default_profile()
	_apply_initial_unlocks()


func snapshot() -> Dictionary:
	return {
		"codename": codename,
		"rank": rank,
		"rank_title": get_rank_title(),
		"xp": xp,
		"xp_to_next": xp_for_next_rank(),
		"cleared_cases": cleared_cases.keys(),
		"unlocked_cases": unlocked_cases,
	}
