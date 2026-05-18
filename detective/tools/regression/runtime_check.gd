## 这份脚本由 MCP 客户端调用 godot-mcp-pro.execute_game_script 执行。
## 调用前：play_scene mode=main 让游戏处于运行态。
## 输出：以 _mcp_print 输出键值对，调用方解析每行 "k=v" 验证。
##
## 重要：必须过滤 _comment 等以 "_" 开头的键，否则会撞 schema 不一致。
##
## 验证矩阵：
##   - AssetResolver autoload 实例化
##   - 三大注册表加载数量 = 期望（actors=8 / scenes=9 / tracks=8）
##   - 当前案件 casting 已加载、case_id 正确
##   - 当前案件每个 NPC：actor_id 解析、portrait 文件存在
##   - 当前案件每个 location：scene_type 解析到的背景文件存在
##   - 当前案件每个 BGM 键（locations + states）：解析到的 wav 文件存在
##   - 主题曲实际播放
## 失败任意一项：bad_*>0 → REGRESSION=FAIL

extends RefCounted

func _run() -> void:
	var resolver = get_node("/root/AssetResolver")
	var gm = get_node("/root/GameManager")
	var bgm = get_node("/root/BgmPlayer")

	if resolver == null or gm == null or bgm == null:
		_mcp_print("FAIL=missing_autoload")
		return

	# ── 注册表 ──
	_mcp_print("case_id=" + gm.ACTIVE_CASE)
	_mcp_print("actors_count=" + str(resolver._actors.size()))
	_mcp_print("scenes_count=" + str(resolver._scenes.size()))
	_mcp_print("tracks_count=" + str(resolver._bgm_tracks.size()))
	_mcp_print("casting_count=" + str(resolver._casting.size()))

	# ── NPC 解析 ──
	var bad_npc = 0
	var checked_npc = 0
	var nids = gm.npcs_data.keys()
	for i in range(nids.size()):
		var nid : String = nids[i]
		if nid.begins_with("_"):
			continue
		checked_npc += 1
		var aid : String = resolver.get_actor_id_for_npc(nid)
		var portrait : String = resolver.get_portrait(nid, gm.npcs_data)
		if aid == "" or portrait == "" or not ResourceLoader.exists(portrait):
			bad_npc += 1
	_mcp_print("npc=" + str(bad_npc) + "/" + str(checked_npc))

	# ── 地点解析（必须过滤 _comment 等非 Dictionary 键）──
	var bad_loc = 0
	var checked_loc = 0
	var locs = gm.locations_data.keys()
	for j in range(locs.size()):
		var lid : String = locs[j]
		if lid.begins_with("_"):
			continue
		var ldata = gm.locations_data[lid]
		if typeof(ldata) != TYPE_DICTIONARY:
			continue
		checked_loc += 1
		var bg : String = resolver.get_scene_background(ldata)
		if bg == "" or not ResourceLoader.exists(bg):
			bad_loc += 1
	_mcp_print("loc=" + str(bad_loc) + "/" + str(checked_loc))

	# ── BGM 解析（按 bgm_config 实际配置）──
	var bcfg = resolver._bgm_config
	var bgm_keys = []
	for k in bcfg.get("locations", {}).keys():
		bgm_keys.append(k)
	for k in bcfg.get("states", {}).keys():
		bgm_keys.append(k)
	var bad_bgm = 0
	for m in range(bgm_keys.size()):
		var f : String = resolver.resolve_bgm_file(bgm_keys[m])
		if f == "" or not FileAccess.file_exists(f):
			bad_bgm += 1
	_mcp_print("bgm=" + str(bad_bgm) + "/" + str(bgm_keys.size()))
	_mcp_print("current_bgm=" + bgm.current_bgm_id())

	# ── 总判 ──
	if bad_npc == 0 and bad_loc == 0 and bad_bgm == 0:
		_mcp_print("REGRESSION=PASS")
	else:
		_mcp_print("REGRESSION=FAIL")

func _mcp_print(msg: String) -> void:
	print(msg)
