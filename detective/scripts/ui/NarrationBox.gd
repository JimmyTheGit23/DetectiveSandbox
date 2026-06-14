extends Control
## 序章/叙述框：支持底部对话框与居中提示框两种显示，有 speaker 时显示立绘
## 逐字显示：点击一次 = 显示全文；再次点击 = 翻页
## 支持叙述中的选项（密室逃脱等交互场景）

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")
const TextUtilsScript = preload("res://scripts/core/TextUtils.gd")
var UI_FONT: Font = null

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
	# 左下角显示（与 DialogueBox 的头像位置一致）
	_portrait_rect.anchor_left = 0.0
	_portrait_rect.anchor_top = 1.0
	_portrait_rect.anchor_right = 0.0
	_portrait_rect.anchor_bottom = 1.0
	_portrait_rect.offset_left = -18
	_portrait_rect.offset_top = -500
	_portrait_rect.offset_right = 272
	_portrait_rect.offset_bottom = 10
	_portrait_rect.visible = false
	# 应用边缘渐隐 shader
	var shader = load("res://assets/cn/portrait_fade.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("fade_bottom", 0.25)
		mat.set_shader_parameter("fade_top", 0.0)
		mat.set_shader_parameter("fade_left", 0.0)
		mat.set_shader_parameter("fade_right", 0.18)
		_portrait_rect.material = mat
	add_child(_portrait_rect)


func _apply_chrome() -> void:
	box_vbox.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_label.add_theme_font_size_override("font_size", 24)
	speaker_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.56, 1.0))
	speaker_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.84))
	speaker_label.add_theme_constant_override("outline_size", 2)
	text_label.add_theme_font_size_override("normal_font_size", 21)
	text_label.add_theme_color_override("default_color", Color(0.95, 0.90, 0.78, 1.0))
	text_label.add_theme_constant_override("line_separation", 6)
	continue_label.add_theme_font_size_override("font_size", 16)
	continue_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.60, 0.80))
	continue_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.86))
	continue_label.add_theme_constant_override("outline_size", 0)
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
	shell.add_theme_constant_override("separation", 8)
	_choices_panel.add_child(shell)

	var title := Label.new()
	title.text = "叙事抉择"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.52, 0.98))
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.90))
	title.add_theme_constant_override("outline_size", 2)
	shell.add_child(title)

	_choices_container = VBoxContainer.new()
	_choices_container.add_theme_constant_override("separation", 6)
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
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = shadow_size
	style.content_margin_left = 20
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
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
	# 去掉多余空行，保持与 DialogueBox 一致的紧凑显示
	var display_text := TextUtilsScript.strip_stage_directions(text).replace("\r\n", "\n").replace("\r", "\n")
	display_text = display_text.strip_edges()
	# 双换行变单换行，单换行保留
	while display_text.find("\n\n") >= 0:
		display_text = display_text.replace("\n\n", "\n")
	display_text = TextUtilsScript.color_inner_thoughts(display_text)
	# 叙述模式不播放打字电子音（物品描述等场景不需要）
	_typewriter.typing_sound_enabled = false
	_typewriter.play(text_label, display_text)
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
		btn.custom_minimum_size = Vector2(0, 44)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 18)
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
	var panel_w: float = clampf(vp.x - 120.0, 560.0, 820.0)
	var btn_height: float = 44.0
	var separation: int = 6
	if choice_count > 5:
		btn_height = 40.0
		separation = 4
	_choices_container.add_theme_constant_override("separation", separation)
	for child in _choices_container.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0, btn_height)
	var visible_count: int = maxi(choice_count, 1)
	var panel_h: float = minf(vp.y * 0.44, 58.0 + float(visible_count) * btn_height + float(maxi(visible_count - 1, 0) * separation))
	var bottom_limit: float = vp.y - 260.0
	var panel_y: float = clampf(52.0, 20.0, maxf(20.0, bottom_limit - panel_h))
	_choices_panel.size = Vector2(panel_w, panel_h)
	_choices_panel.position = Vector2((vp.x - panel_w) * 0.5, panel_y)


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
	box.clip_contents = true
	if centered:
		dim_bg.color = Color(0.02, 0.01, 0.0, 0.46)
		box.anchor_left = 0.0
		box.anchor_top = 1.0
		box.anchor_right = 1.0
		box.anchor_bottom = 1.0
		box.offset_left = 28
		box.offset_top = -240
		box.offset_right = -28
		box.offset_bottom = -18
		box.add_theme_stylebox_override("panel", _make_shell_style(
			Color(0.035, 0.022, 0.012, 0.94),
			Color(0.76, 0.58, 0.26, 0.78),
			20,
			22
		))
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.custom_minimum_size = Vector2(0, 0)
	else:
		dim_bg.color = Color(0.02, 0.01, 0.0, 0.24)
		box.anchor_left = 0.0
		box.anchor_top = 1.0
		box.anchor_right = 1.0
		box.anchor_bottom = 1.0
		box.offset_left = 28
		box.offset_top = -240
		box.offset_right = -28
		box.offset_bottom = -18
		box.add_theme_stylebox_override("panel", _make_shell_style(
			Color(0.035, 0.022, 0.012, 0.94),
			Color(0.76, 0.58, 0.26, 0.78),
			20,
			22
		))
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.custom_minimum_size = Vector2(0, 0)


func _adjust_box_for_portrait(has_portrait: bool) -> void:
	if _centered_layout:
		return
	box.offset_left = 264 if has_portrait else 28


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
