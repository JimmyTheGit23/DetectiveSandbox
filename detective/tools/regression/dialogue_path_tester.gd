## 对话路径运行时测试脚本
##
## 由 MCP 客户端调用 godot-mcp-pro.execute_game_script 执行。
## 调用前：play_scene mode=main 让游戏处于运行态。
##
## 注意：execute_game_script 不支持 await，所有逻辑必须同步执行。
##       顶层 func 定义会自动提取为类方法，剩余代码放入 run() 体。
##
## 输出格式：key=value
##   - node_check=<npc_id>.<node_id> : 正在检查的节点
##   - status=PASS/FAIL/WARN : 测试结果
##   - message=<message> : 详细信息
##   - path_count=<count> : 已测试路径数
##   - error_count=<count> : 错误数
##   - TEST_STATUS=PASS/FAIL : 最终状态
##   - TEST_COMPLETE : 测试完成标记

func _get_npc_ids() -> Array:
	var npc_ids = ["agui", "fisherman_wang", "lao_fan", "li_zheng", "shen_qingyue", "zhou_wife"]
	return npc_ids

func _check_node_exists(tree: Dictionary, npc_id: String, node_id: String) -> bool:
	var nodes = tree.get("nodes", {})
	return nodes.has(node_id)

func _check_goto_targets(tree: Dictionary, npc_id: String) -> Array:
	var errors = []
	var nodes = tree.get("nodes", {})
	for node_id in nodes.keys():
		var node = nodes[node_id]
		for option in node.get("options", []):
			var goto = option.get("goto", "")
			if goto != "" and goto != "__exit__" and goto != "__confront__":
				if not nodes.has(goto):
					errors.append("goto_missing:%s.%s -> %s" % [node_id, option.get("text", "?"), goto])
	return errors

func _check_conditions(tree: Dictionary, npc_id: String) -> Array:
	var warnings = []
	var nodes = tree.get("nodes", {})
	for node_id in nodes.keys():
		var node = nodes[node_id]
		for option in node.get("options", []):
			var requires = option.get("requires", {})
			if typeof(requires) == TYPE_DICTIONARY:
				for key in requires.keys():
					# CaseTableLoader._parse_condition 支持的条件类型
					var known = ["flag", "not_flag", "evidence", "clue",
						"visited", "not", "all", "any",
						"location", "location_unlocked", "default"]
					if not known.has(key):
						warnings.append("unknown_cond:%s.%s requires.%s" % [node_id, option.get("text", "?"), key])
	return warnings

func _check_node_content(tree: Dictionary, npc_id: String) -> Array:
	var errors = []
	var nodes = tree.get("nodes", {})
	for node_id in nodes.keys():
		var node = nodes[node_id]
		var options = node.get("options", [])
		var lines = node.get("lines", [])
		var is_end = node.get("end", false)
		if not is_end and options.is_empty() and lines.is_empty():
			errors.append("empty_node:%s.%s (no options, no lines, not end)" % [npc_id, node_id])
	return errors

func _check_dead_ends(tree: Dictionary, npc_id: String) -> Array:
	var warnings = []
	var nodes = tree.get("nodes", {})
	for node_id in nodes.keys():
		var node = nodes[node_id]
		var options = node.get("options", [])
		var has_exit = false
		for option in options:
			var goto = option.get("goto", "")
			if goto == "" or goto == "__exit__":
				has_exit = true
				break
		if not has_exit and options.is_empty():
			warnings.append("no_exit:%s.%s" % [npc_id, node_id])
	return warnings

func _check_flag_consistency(tree: Dictionary, npc_id: String, gm: Node) -> Array:
	var errors = []
	var nodes = tree.get("nodes", {})
	for node_id in nodes.keys():
		var node = nodes[node_id]
		for option in node.get("options", []):
			var set_flags = option.get("set_flags", [])
			for flag in set_flags:
				if typeof(flag) != TYPE_STRING or flag.is_empty():
					errors.append("invalid_flag:%s.%s set_flags contains non-string" % [npc_id, node_id])
	return errors

# === 主测试代码（放入 run() 体） ===

var gm = get_node("/root/GameManager")
var dm = get_node("/root/DialogueManager")

if gm == null:
	_mcp_print("TEST_STATUS=FAIL")
	_mcp_print("error_count=1")
	_mcp_print("message=GameManager not found")
	_mcp_print("TEST_COMPLETE")
else:
	_mcp_print("case_id=" + gm.ACTIVE_CASE)
	
	var npc_ids = _get_npc_ids()
	_mcp_print("npc_count=" + str(npc_ids.size()))
	
	var total_paths = 0
	var total_errors = 0
	var total_warnings = 0
	
	for npc_id in npc_ids:
		_mcp_print("npc_id=" + npc_id)
		
		# 从 CaseTableLoader 加载对话数据（在引擎内验证加载是否成功）
		var tree = CaseTableLoader.load_dialogue(gm.ACTIVE_CASE, npc_id)
		if tree.is_empty():
			_mcp_print("node_check=%s.load" % npc_id)
			_mcp_print("status=FAIL")
			_mcp_print("message=failed_to_load_dialogue")
			total_errors += 1
			continue
		
		var nodes = tree.get("nodes", {})
		var node_count = nodes.size()
		var option_count = 0
		for nid in nodes.keys():
			option_count += nodes[nid].get("options", []).size()
		
		total_paths += node_count
		
		_mcp_print("node_count=%d" % node_count)
		_mcp_print("option_count=%d" % option_count)
		
		# 检查 goto 目标
		var goto_errors = _check_goto_targets(tree, npc_id)
		for err in goto_errors:
			_mcp_print("node_check=%s.goto" % npc_id)
			_mcp_print("status=FAIL")
			_mcp_print("message=" + err)
			total_errors += 1
		
		# 检查节点内容
		var content_errors = _check_node_content(tree, npc_id)
		for err in content_errors:
			_mcp_print("node_check=%s.content" % npc_id)
			_mcp_print("status=WARN")
			_mcp_print("message=" + err)
			total_warnings += 1
		
		# 检查条件语法
		var cond_warnings = _check_conditions(tree, npc_id)
		for w in cond_warnings:
			_mcp_print("node_check=%s.condition" % npc_id)
			_mcp_print("status=WARN")
			_mcp_print("message=" + w)
			total_warnings += 1
		
		# 检查 flag 一致性
		var flag_errors = _check_flag_consistency(tree, npc_id, gm)
		for err in flag_errors:
			_mcp_print("node_check=%s.flag" % npc_id)
			_mcp_print("status=FAIL")
			_mcp_print("message=" + err)
			total_errors += 1
		
		# 检查死胡同
		var dead_warnings = _check_dead_ends(tree, npc_id)
		for w in dead_warnings:
			_mcp_print("node_check=%s.dead_end" % npc_id)
			_mcp_print("status=WARN")
			_mcp_print("message=" + w)
			total_warnings += 1
		
		# 如果没有错误，报告通过
		if goto_errors.is_empty() and flag_errors.is_empty():
			_mcp_print("node_check=%s.structure" % npc_id)
			_mcp_print("status=PASS")
			_mcp_print("message=structure_valid")
		
		_mcp_print("npc_complete=" + npc_id)
	
	_mcp_print("path_count=" + str(total_paths))
	_mcp_print("error_count=" + str(total_errors))
	_mcp_print("warning_count=" + str(total_warnings))
	
	if total_errors == 0:
		_mcp_print("TEST_STATUS=PASS")
	else:
		_mcp_print("TEST_STATUS=FAIL")
	
	_mcp_print("TEST_COMPLETE")