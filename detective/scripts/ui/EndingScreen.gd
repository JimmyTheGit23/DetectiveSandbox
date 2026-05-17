extends Control
## 结局画面：标题 + 文案 + 进度结算（XP / 升级 / 解锁）+ 重玩按钮

@onready var title_label: Label = $Center/VBox/Title
@onready var text_label: RichTextLabel = $Center/VBox/Text
@onready var restart_btn: Button = $Center/VBox/RestartBtn

var _progression_container: VBoxContainer = null


func _ready() -> void:
	restart_btn.pressed.connect(_on_restart)


func show_ending(title: String, text: String) -> void:
	title_label.text = title
	text_label.text = "[center]" + text + "[/center]"
	# 每次显示先清空旧的进度结算
	if _progression_container and is_instance_valid(_progression_container):
		_progression_container.queue_free()
		_progression_container = null


## summary: { earned_xp, first_clear, rank_up, old_rank, new_rank, unlocked: [case_id,...] }
## iv: 当前的 InvestigatorService（可为 null，但传了便于显示等级条）
func show_progression_summary(summary: Dictionary, iv: Node) -> void:
	if _progression_container and is_instance_valid(_progression_container):
		_progression_container.queue_free()
	_progression_container = VBoxContainer.new()
	_progression_container.add_theme_constant_override("separation", 6)
	_progression_container.alignment = BoxContainer.ALIGNMENT_CENTER
	# 插入到 RestartBtn 之前
	var vb := restart_btn.get_parent()
	vb.add_child(_progression_container)
	vb.move_child(_progression_container, restart_btn.get_index())

	# 分隔线
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 12)
	_progression_container.add_child(sep)

	# XP 行
	var earned: int = int(summary.get("earned_xp", 0))
	var first_clear: bool = bool(summary.get("first_clear", false))
	var xp_lbl := Label.new()
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.text = "本案经验：+%d XP%s" % [earned, "  （首次通关 +50 奖励）" if first_clear else "  （重玩 30%）"]
	xp_lbl.add_theme_font_size_override("font_size", 20)
	xp_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1))
	_progression_container.add_child(xp_lbl)

	# 当前等级 + 进度条
	if iv:
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.min_value = 0
		bar.max_value = 100
		bar.value = iv.rank_progress() * 100.0
		bar.custom_minimum_size = Vector2(480, 14)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_progression_container.add_child(bar)

		var rank_lbl := Label.new()
		rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_lbl.text = "Lv.%d  %s    （%d / %d）" % [iv.get_rank(), iv.get_rank_title(), iv.get_xp(), iv.xp_for_next_rank()]
		rank_lbl.add_theme_font_size_override("font_size", 16)
		rank_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42, 1))
		_progression_container.add_child(rank_lbl)

	# 升级提示
	if bool(summary.get("rank_up", false)) and iv:
		var up_lbl := Label.new()
		up_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		up_lbl.text = "★ 推理等级提升：Lv.%d → Lv.%d「%s」" % [
			int(summary.get("old_rank", 0)),
			int(summary.get("new_rank", 0)),
			iv.get_rank_title(int(summary.get("new_rank", 0))),
		]
		up_lbl.add_theme_font_size_override("font_size", 18)
		up_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.42, 1))
		_progression_container.add_child(up_lbl)

	# 解锁提示
	var unlocked: Array = summary.get("unlocked", [])
	if not unlocked.is_empty():
		for cid in unlocked:
			var u_lbl := Label.new()
			u_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			u_lbl.text = "✦ 新案件解锁：%s" % _case_title(str(cid))
			u_lbl.add_theme_font_size_override("font_size", 16)
			u_lbl.add_theme_color_override("font_color", Color(0.60, 0.95, 0.55, 1))
			_progression_container.add_child(u_lbl)


static func _case_title(case_id: String) -> String:
	var path := "res://data/cases/%s/manifest.json" % case_id
	if not FileAccess.file_exists(path):
		return case_id
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return case_id
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return case_id
	return parsed.get("title", case_id)


func _on_restart() -> void:
	get_tree().reload_current_scene()
