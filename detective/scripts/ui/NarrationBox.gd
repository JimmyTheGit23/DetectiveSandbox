extends Control
## 序章/叙述框：支持底部对话框与居中提示框两种显示，有 speaker 时显示立绘
## 逐字显示：点击一次 = 显示全文；再次点击 = 翻页
## 支持叙述中的选项（密室逃脱等交互场景）

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")

@onready var box: PanelContainer = $Box
@onready var speaker_label: Label = $Box/VBox/SpeakerName
@onready var text_label: RichTextLabel = $Box/VBox/TextLabel
@onready var continue_label: Label = $Box/VBox/ContinueLabel

var _has_next: bool = true
var _portrait_rect: TextureRect = null
var _typewriter: Node = null
var _centered_layout: bool = false
var _choices_container: VBoxContainer = null
var _has_choices: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.scroll_active = false
	_create_portrait_rect()
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)
	_create_choices_container()
	DialogueManager.narration_choices_ready.connect(_on_choices_ready)


func _create_portrait_rect() -> void:
	_portrait_rect = TextureRect.new()
	_portrait_rect.name = "NarrationPortrait"
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_rect.anchor_left = 0.0
	_portrait_rect.anchor_top = 1.0
	_portrait_rect.anchor_right = 0.0
	_portrait_rect.anchor_bottom = 1.0
	_portrait_rect.offset_left = 20
	_portrait_rect.offset_top = -460
	_portrait_rect.offset_right = 220
	_portrait_rect.offset_bottom = 40
	_portrait_rect.visible = false
	add_child(_portrait_rect)


func _create_choices_container() -> void:
	_choices_container = VBoxContainer.new()
	_choices_container.name = "NarrationChoices"
	_choices_container.anchor_left = 0.5
	_choices_container.anchor_top = 0.0
	_choices_container.anchor_right = 0.5
	_choices_container.anchor_bottom = 0.0
	_choices_container.offset_left = -340
	_choices_container.offset_right = 340
	_choices_container.offset_top = 80
	_choices_container.offset_bottom = 400
	_choices_container.add_theme_constant_override("separation", 12)
	_choices_container.visible = false
	add_child(_choices_container)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# 有选项时不响应点击推进
	if _has_choices:
		return
	var clicked := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked = true
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		clicked = true

	if clicked:
		if _typewriter.is_playing():
			_typewriter.skip()
		else:
			DialogueManager.narration_advance()
		get_viewport().set_input_as_handled()


func show_narration(speaker: String, text: String, has_next: bool, centered := false, portrait_override := "") -> void:
	_hide_choices()
	speaker_label.text = speaker
	speaker_label.visible = (speaker != "")
	_has_next = has_next
	continue_label.text = "▼ 点击继续" if has_next else "▼ 点击进入游戏"
	continue_label.visible = false
	_apply_layout(centered)
	if portrait_override != "" and ResourceLoader.exists(portrait_override):
		_portrait_rect.texture = load(portrait_override)
		_portrait_rect.visible = true
		_adjust_box_for_portrait(true)
	else:
		_update_portrait(speaker)
	_typewriter.play(text_label, text)
	await _typewriter.finished
	if not _has_choices:
		continue_label.visible = true


func _on_choices_ready(choices: Array) -> void:
	_has_choices = true
	continue_label.visible = false
	_show_choices(choices)


func _show_choices(choices: Array) -> void:
	_hide_choices()
	_has_choices = true
	_choices_container.visible = true
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		# 条件过滤：requires 不满足则跳过
		if choice.has("requires"):
			if not GameManager.evaluate_condition(choice["requires"]):
				continue
		var btn := Button.new()
		btn.text = choice.get("text", "")
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 19)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_choice_style(btn)
		var idx := i
		btn.pressed.connect(func():
			_hide_choices()
			DialogueManager.narration_choose(idx)
		)
		_choices_container.add_child(btn)


func _hide_choices() -> void:
	_has_choices = false
	_choices_container.visible = false
	for child in _choices_container.get_children():
		child.queue_free()


func _apply_choice_style(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color(0.95, 0.88, 0.62, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.78, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1))
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 1))
	btn.add_theme_constant_override("outline_size", 3)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.055, 0.03, 0.90)
	normal.border_color = Color(0.62, 0.48, 0.22, 0.75)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.shadow_color = Color(0, 0, 0, 0.4)
	normal.shadow_size = 6
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.08, 0.04, 0.95)
	hover.border_color = Color(0.88, 0.68, 0.30, 0.95)
	hover.shadow_size = 12
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.06, 0.04, 0.02, 0.98)
	btn.add_theme_stylebox_override("pressed", pressed)


func _apply_layout(centered: bool) -> void:
	_centered_layout = centered
	if centered:
		box.anchor_left = 0.5
		box.anchor_top = 0.5
		box.anchor_right = 0.5
		box.anchor_bottom = 0.5
		box.offset_left = -410
		box.offset_top = -230
		box.offset_right = 410
		box.offset_bottom = 230
		text_label.custom_minimum_size = Vector2(760, 330)
		text_label.add_theme_font_size_override("normal_font_size", 22)
		text_label.add_theme_color_override("default_color", Color(0.92, 0.88, 0.76, 1))
	else:
		box.anchor_left = 0.0
		box.anchor_top = 1.0
		box.anchor_right = 1.0
		box.anchor_bottom = 1.0
		box.offset_top = -260
		box.offset_right = -80
		box.offset_bottom = -40
		text_label.custom_minimum_size = Vector2(0, 150)
		text_label.add_theme_font_size_override("normal_font_size", 22)
		text_label.add_theme_color_override("default_color", Color(0.92, 0.88, 0.76, 1))


func _adjust_box_for_portrait(has_portrait: bool) -> void:
	if _centered_layout:
		return
	if has_portrait:
		box.offset_left = 230
	else:
		box.offset_left = 80


func _update_portrait(speaker: String) -> void:
	if _portrait_rect == null:
		return
	if speaker == "":
		_portrait_rect.visible = false
		_adjust_box_for_portrait(false)
		return

	var portrait_path := _resolve_portrait_for_speaker(speaker)
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		_portrait_rect.texture = load(portrait_path)
		_portrait_rect.visible = true
		_adjust_box_for_portrait(true)
	else:
		_portrait_rect.visible = false
		_adjust_box_for_portrait(false)


func _resolve_portrait_for_speaker(speaker: String) -> String:
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("get_companion_role_name"):
		var companion_name: String = cs.get_companion_role_name()
		if companion_name != "" and speaker == companion_name:
			var p: String = cs.get_companion_portrait()
			if p != "":
				return p

	var casting: Dictionary = AssetResolver.get_casting()
	for npc_id in casting.keys():
		var entry = casting[npc_id]
		if typeof(entry) == TYPE_DICTIONARY:
			if entry.get("role_name", "") == speaker:
				return AssetResolver.get_portrait(npc_id, GameManager.npcs_data)
	return ""
