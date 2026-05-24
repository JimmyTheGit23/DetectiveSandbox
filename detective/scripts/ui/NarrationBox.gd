extends Control
## 序章/叙述框：支持底部对话框与居中提示框两种显示，有 speaker 时显示立绘
## 逐字显示：点击一次 = 显示全文；再次点击 = 翻页
## 支持叙述中的选项（密室逃脱等交互场景）

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansSC.otf")

@onready var dim_bg: ColorRect = $DimBg
@onready var box: PanelContainer = $Box
@onready var box_vbox: VBoxContainer = $Box/VBox
@onready var speaker_label: Label = $Box/VBox/SpeakerName
@onready var text_label: RichTextLabel = $Box/VBox/TextLabel
@onready var continue_label: Label = $Box/VBox/ContinueLabel

var _has_next: bool = true
var _portrait_rect: TextureRect = null
var _typewriter: Node = null
var _centered_layout: bool = false
var _choices_panel: PanelContainer = null
var _choices_container: VBoxContainer = null
var _has_choices: bool = false
var _narration_run_id: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.scroll_active = false
	_create_portrait_rect()
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)
	_apply_chrome()
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
	_portrait_rect.offset_left = -18
	_portrait_rect.offset_top = -500
	_portrait_rect.offset_right = 272
	_portrait_rect.offset_bottom = 10
	_portrait_rect.visible = false
	add_child(_portrait_rect)


func _apply_chrome() -> void:
	box_vbox.add_theme_constant_override("separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_label.add_theme_font_override("font", UI_FONT)
	speaker_label.add_theme_font_size_override("font_size", 30)
	speaker_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.56, 1.0))
	speaker_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.92))
	speaker_label.add_theme_constant_override("outline_size", 4)
	text_label.add_theme_font_override("normal_font", UI_FONT)
	text_label.add_theme_font_size_override("normal_font_size", 24)
	text_label.add_theme_color_override("default_color", Color(0.95, 0.90, 0.78, 1.0))
	text_label.add_theme_constant_override("line_separation", 10)
	continue_label.add_theme_font_override("font", UI_FONT)
	continue_label.add_theme_font_size_override("font_size", 18)
	continue_label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.62, 0.96))
	continue_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.86))
	continue_label.add_theme_constant_override("outline_size", 2)
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_label.visible = true
	_set_continue_hint_visible(false)


func _create_choices_container() -> void:
	_choices_panel = PanelContainer.new()
	_choices_panel.name = "NarrationChoicesPanel"
	_choices_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_choices_panel.visible = false
	_choices_panel.add_theme_stylebox_override("panel", _make_shell_style(
		Color(0.05, 0.03, 0.015, 0.96),
		Color(0.84, 0.62, 0.22, 0.76),
		26,
		22
	))
	add_child(_choices_panel)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 12)
	_choices_panel.add_child(shell)

	var title := Label.new()
	title.text = "叙事抉择"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UI_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.52, 0.98))
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.90))
	title.add_theme_constant_override("outline_size", 2)
	shell.add_child(title)

	_choices_container = VBoxContainer.new()
	_choices_container.add_theme_constant_override("separation", 10)
	shell.add_child(_choices_container)


func _make_shell_style(bg: Color, border: Color, shadow_size: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 3
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.46)
	style.shadow_size = shadow_size
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _make_choice_style(bg: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 2
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.40)
	style.shadow_size = shadow_size
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _input(event: InputEvent) -> void:
	if not visible:
		return
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
	_narration_run_id += 1
	var run_id := _narration_run_id
	_hide_choices()
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
	_has_next = has_next
	continue_label.text = "▼ 点击继续" if has_next else "▼ 点击进入游戏"
	_set_continue_hint_visible(false)
	_apply_layout(centered)
	if portrait_override != "" and ResourceLoader.exists(portrait_override):
		_portrait_rect.texture = load(portrait_override)
		_portrait_rect.visible = true
		_adjust_box_for_portrait(true)
	else:
		_update_portrait(speaker)
	_typewriter.play(text_label, text)
	await _typewriter.finished
	if run_id != _narration_run_id:
		return
	if not _has_choices:
		_set_continue_hint_visible(true)


func _on_choices_ready(choices: Array) -> void:
	_has_choices = true
	_set_continue_hint_visible(false)
	_show_choices(choices)


func _show_choices(choices: Array) -> void:
	_hide_choices()
	_has_choices = true
	var visible_count := 0
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		if choice.has("requires") and not GameManager.evaluate_condition(choice["requires"]):
			continue
		var btn := Button.new()
		btn.text = choice.get("text", "")
		btn.custom_minimum_size = Vector2(0, 54)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_override("font", UI_FONT)
		btn.add_theme_font_size_override("font_size", 20)
		_apply_choice_style(btn)
		var idx := i
		btn.pressed.connect(func():
			_hide_choices()
			DialogueManager.narration_choose(idx)
		)
		_choices_container.add_child(btn)
		visible_count += 1
	_position_choices_panel(visible_count)
	_choices_panel.visible = true


func _hide_choices() -> void:
	_has_choices = false
	if _choices_panel != null:
		_choices_panel.visible = false
	if _choices_container != null:
		for child in _choices_container.get_children():
			child.queue_free()


func _position_choices_panel(choice_count: int) -> void:
	if _choices_panel == null or _choices_container == null:
		return
	var vp := get_viewport_rect().size
	var panel_w: float = minf(780.0, vp.x * 0.72)
	var btn_height: float = 54.0
	var separation: int = 10
	if choice_count > 5:
		btn_height = 48.0
		separation = 8
	_choices_container.add_theme_constant_override("separation", separation)
	for child in _choices_container.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0, btn_height)
	var visible_count: int = choice_count if choice_count > 0 else 1
	var panel_h: float = minf(360.0, 64.0 + float(visible_count) * (btn_height + float(separation)))
	_choices_panel.size = Vector2(panel_w, panel_h)
	_choices_panel.position = Vector2((vp.x - panel_w) * 0.5, 74.0)


func _set_continue_hint_visible(is_visible: bool) -> void:
	if continue_label == null:
		return
	continue_label.self_modulate = Color(1, 1, 1, 1.0 if is_visible else 0.0)


func _apply_choice_style(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color(0.96, 0.88, 0.64, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.76, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.92, 0.74, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.92))
	btn.add_theme_constant_override("outline_size", 2)
	btn.add_theme_stylebox_override("normal", _make_choice_style(Color(0.13, 0.08, 0.038, 0.96), Color(0.72, 0.54, 0.22, 0.76), 10))
	btn.add_theme_stylebox_override("hover", _make_choice_style(Color(0.18, 0.10, 0.042, 0.98), Color(0.92, 0.70, 0.30, 0.92), 18))
	btn.add_theme_stylebox_override("pressed", _make_choice_style(Color(0.10, 0.06, 0.03, 0.98), Color(0.84, 0.64, 0.28, 0.88), 6))
	btn.add_theme_stylebox_override("focus", _make_choice_style(Color(0.18, 0.10, 0.042, 0.98), Color(0.92, 0.70, 0.30, 0.92), 18))


func _apply_layout(centered: bool) -> void:
	_centered_layout = centered
	if centered:
		dim_bg.color = Color(0.02, 0.01, 0.0, 0.46)
		box.anchor_left = 0.5
		box.anchor_top = 0.5
		box.anchor_right = 0.5
		box.anchor_bottom = 0.5
		box.offset_left = -420
		box.offset_top = -210
		box.offset_right = 420
		box.offset_bottom = 180
		box.add_theme_stylebox_override("panel", _make_shell_style(
			Color(0.05, 0.03, 0.015, 0.97),
			Color(0.86, 0.64, 0.24, 0.80),
			30,
			28
		))
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.custom_minimum_size = Vector2(0, 220)
	else:
		dim_bg.color = Color(0.02, 0.01, 0.0, 0.24)
		box.anchor_left = 0.0
		box.anchor_top = 1.0
		box.anchor_right = 1.0
		box.anchor_bottom = 1.0
		box.offset_left = 76
		box.offset_top = -238
		box.offset_right = -52
		box.offset_bottom = -22
		box.add_theme_stylebox_override("panel", _make_shell_style(
			Color(0.045, 0.028, 0.014, 0.95),
			Color(0.82, 0.60, 0.22, 0.76),
			28,
			26
		))
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.custom_minimum_size = Vector2(0, 126)


func _adjust_box_for_portrait(has_portrait: bool) -> void:
	if _centered_layout:
		return
	box.offset_left = 252 if has_portrait else 76


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
