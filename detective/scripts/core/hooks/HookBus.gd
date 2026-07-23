extends Node
## HookBus — 钩子骨架层（三层架构 Layer 2）
##
## 统一事件订阅中心，替代旧的"每个 mutator 手动调 _check_day_events /
## _check_progression 全表扫描"轮询模式。新机制接入方式：
##   1) 在下方常量清单追加一个新钩子名
##   2) 在产生该事件的位置 emit_hook()
##   3) 在关心该事件的系统里 subscribe()
## 框架层（HookBus 自身）不需要再改。
##
## 同步执行：emit_hook 按 priority 降序依次调用订阅者，顺序可控。

signal hook_emitted(hook_name: String, payload: Dictionary)

# ═══ 内置钩子清单（新增机制在此追加） ═══
# ── 状态类 ──
const FLAG_SET := "flag.set"                    # {flag_id}
const EVIDENCE_ADDED := "evidence.added"        # {evidence_id}
const CLUE_ADDED := "clue.added"                # {clue_id}
const LOCATION_CHANGED := "location.changed"    # {location_id}
const NODE_VISITED := "node.visited"            # {npc_id, node_id}
const NPC_STATE_CHANGED := "npc_state.changed"  # {npc_id, stat, value}
const TIME_ADVANCED := "time.advanced"          # {day, period}
# ── 流程类（P3 FlowRunner 使用） ──
const FLOW_STARTED := "flow.started"            # {flow_id}
const PHASE_ENTERING := "phase.entering"        # {phase_id, phase_type}
const PHASE_ENTERED := "phase.entered"          # {phase_id, phase_type}
const PHASE_EXITING := "phase.exiting"          # {phase_id, phase_type}
const FLOW_FINISHED := "flow.finished"          # {flow_id}
# ── 交互类 ──
const SEARCH_RESOLVED := "search.resolved"      # {location_id, point_id, result}
const DIALOGUE_ENDED := "dialogue.ended"        # {npc_id}
const OPTION_CHOSEN := "option.chosen"          # {npc_id, node_id, option_index}
# ── 对决类 ──
const CONFRONTATION_FINISHED := "confrontation.finished"  # {confront_key, result, mistakes}
# ── 系统类 ──
const SAVE_LOADED := "save.loaded"              # {}
const CASE_SWITCHED := "case.switched"          # {case_id}

var _subscribers: Dictionary = {}  # hook_name -> Array[Dictionary{callable, priority}]


## 订阅钩子。priority 越大越先执行（同优先级按订阅顺序）。
func subscribe(hook_name: String, callable: Callable, priority: int = 0) -> void:
	if hook_name == "" or not callable.is_valid():
		push_error("[HookBus] invalid subscribe: %s" % hook_name)
		return
	if not _subscribers.has(hook_name):
		_subscribers[hook_name] = []
	var list: Array = _subscribers[hook_name]
	# 防重复订阅
	for entry in list:
		if entry["callable"] == callable:
			return
	var entry := {"callable": callable, "priority": priority}
	# 按 priority 降序插入
	var insert_at := list.size()
	for i in list.size():
		if int(list[i]["priority"]) < priority:
			insert_at = i
			break
	list.insert(insert_at, entry)


func unsubscribe(hook_name: String, callable: Callable) -> void:
	if not _subscribers.has(hook_name):
		return
	var list: Array = _subscribers[hook_name]
	for i in range(list.size() - 1, -1, -1):
		if list[i]["callable"] == callable:
			list.remove_at(i)


## 触发钩子：同步按 priority 降序调用所有订阅者。
func emit_hook(hook_name: String, payload: Dictionary = {}) -> void:
	hook_emitted.emit(hook_name, payload)
	if not _subscribers.has(hook_name):
		return
	# 复制快照，避免订阅者在回调中 subscribe/unsubscribe 导致迭代失效
	var list: Array = _subscribers[hook_name].duplicate()
	for entry in list:
		var cb: Callable = entry["callable"]
		if cb.is_valid():
			cb.call(payload)


## 调试用：返回某钩子的订阅数
func subscriber_count(hook_name: String) -> int:
	return _subscribers.get(hook_name, []).size()
