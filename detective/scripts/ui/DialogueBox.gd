extends Control
## NPC 对话框：底部只显示立绘、名字和文本；文字播完后才在画面上方显示选项。

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")

@onready var portrait_rect: TextureRect = $Portrait
@onready var speaker_label: Label = $Box/SpeakerName
@onready var text_label: RichTextLabel = $Box/TextLabel
@onready var legacy_options: ScrollContainer = $Box/Options
@onready var options_vbox: VBoxContainer = $Box/Options/OptionsVBox
@onready var exit_btn: Button = $Box/ExitBtn

var _typewriter: Node = null
var _top_options_panel: PanelContainer = null
var _top_options_vbox: VBoxContainer = null
var _choice_hint_label: Label = null
var _dialogue_pages: Array = []
var _dialogue_page_index: int = 0
var _dialogue_options: Array = []
var _waiting_for_advance: bool = false
var _dialogue_run_id: int = 0

const DEFAULT_PORTRAIT_POSITION := Vector2(34, -200)
const DEFAULT_PORTRAIT_SIZE := Vector2(200, 500)
const OPERA_PERFORMER_PORTRAIT_POSITION := Vector2(-66, -200)
const OPERA_PERFORMER_PORTRAIT_SIZE := Vector2(300, 500)
const SENIOR_PREFECT_PORTRAIT_POSITION := Vector2(-18, -160)
const SENIOR_PREFECT_PORTRAIT_SIZE := Vector2(250, 470)


func _ready() -> void:
	legacy_options.visible = false
	exit_btn.visible = false
	text_label.anchor_bottom = 1.0
	text_label.offset_bottom = -46.0
	text_label.add_theme_font_size_override("normal_font_size", 22)
	_build_choice_hint()
	_build_top_options_panel()
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var advance_pressed := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_pressed = true
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		advance_pressed = true
	if not advance_pressed:
		return
	# 文字出字中点击 → 立即显示当前句全文。
	if _typewriter.is_playing():
		_typewriter.skip()
		get_viewport().set_input_as_handled()
		return
	# 当前句播完后点击 → 下一句；最后一句播完后才显示选项。
	if _waiting_for_advance:
		_waiting_for_advance = false
		_dialogue_page_index += 1
		_play_current_page(_dialogue_run_id)
		get_viewport().set_input_as_handled()


func show_dialogue(speaker: String, portrait_path: String, text: String, options: Array, pages: Array = []) -> void:
	_dialogue_run_id += 1
	_hide_options()
	_choice_hint_label.visible = false
	_waiting_for_advance = false
	_dialogue_options = options
	_dialogue_pages = _build_dialogue_pages(speaker, portrait_path, text, pages)
	if _dialogue_pages.is_empty():
		_dialogue_pages.append({"speaker": speaker, "portrait": portrait_path, "text": ""})
	_dialogue_page_index = 0
	_play_current_page(_dialogue_run_id)


func _play_current_page(run_id: int) -> void:
	if run_id != _dialogue_run_id:
		return
	_hide_options()
	_choice_hint_label.visible = false
	_waiting_for_advance = false
	var page: Dictionary = _dialogue_pages[_dialogue_page_index]
	_apply_speaker(page.get("speaker", ""), page.get("portrait", ""))
	var page_text: String = page.get("text", "")
	_typewriter.play(text_label, page_text)
	await _typewriter.finished
	if run_id != _dialogue_run_id:
		return
	if _dialogue_page_index < _dialogue_pages.size() - 1:
		_choice_hint_label.text = "▼ 点击继续"
		_choice_hint_label.visible = true
		_waiting_for_advance = true
	else:
		_choice_hint_label.text = "▼ 请选择回应"
		_choice_hint_label.visible = true
		_show_options(_dialogue_options)


func _apply_speaker(speaker: String, portrait_path: String) -> void:
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
	portrait_rect.position = DEFAULT_PORTRAIT_POSITION
	portrait_rect.size = DEFAULT_PORTRAIT_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if portrait_path.ends_with("actor_opera_performer.png"):
		portrait_rect.position = OPERA_PERFORMER_PORTRAIT_POSITION
		portrait_rect.size = OPERA_PERFORMER_PORTRAIT_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	elif portrait_path.ends_with("actor_senior_prefect.png"):
		portrait_rect.position = SENIOR_PREFECT_PORTRAIT_POSITION
		portrait_rect.size = SENIOR_PREFECT_PORTRAIT_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false


func _build_dialogue_pages(default_speaker: String, default_portrait: String, text: String, raw_pages: Array) -> Array:
	var pages: Array = []
	if raw_pages.is_empty():
		raw_pages = [{"speaker": default_speaker, "portrait": default_portrait, "text": text}]
	for raw_page in raw_pages:
		if typeof(raw_page) != TYPE_DICTIONARY:
			continue
		var speaker: String = raw_page.get("speaker", default_speaker)
		var portrait: String = raw_page.get("portrait", default_portrait)
		var line_text: String = raw_page.get("text", "")
		for sentence in _split_dialogue_text(line_text):
			pages.append({"speaker": speaker, "portrait": portrait, "text": sentence})
	return pages


func _split_dialogue_text(text: String) -> Array[String]:
	var pages: Array[String] = []
	var normalized := text.replace("\r\n", "\n").replace("\r", "\n")
	for block in normalized.split("\n\n", false):
		var block_text := str(block).strip_edges()
		if block_text == "":
			continue
		for sentence in _split_block_into_sentences(block_text):
			var clean_sentence := sentence.strip_edges()
			if clean_sentence != "":
				pages.append(clean_sentence)
	return pages


func _split_block_into_sentences(block: String) -> Array[String]:
	var sentences: Array[String] = []
	var buf := ""
	var i := 0
	while i < block.length():
		var ch := block[i]
		buf += ch
		if ch in ["。", "！", "？", "!", "?"]:
			var next_i := i + 1
			while next_i < block.length() and block[next_i] in ["”", "’", "）", ")"]:
				buf += block[next_i]
				next_i += 1
			sentences.append(buf.strip_edges())
			buf = ""
			i = next_i
			continue
		i += 1
	if buf.strip_edges() != "":
		sentences.append(buf.strip_edges())
	return sentences


func _build_choice_hint() -> void:
	_choice_hint_label = Label.new()
	_choice_hint_label.text = "▼ 请选择回应"
	_choice_hint_label.anchor_left = 0.0
	_choice_hint_label.anchor_top = 1.0
	_choice_hint_label.anchor_right = 1.0
	_choice_hint_label.anchor_bottom = 1.0
	_choice_hint_label.offset_top = -34.0
	_choice_hint_label.offset_bottom = -6.0
	_choice_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_choice_hint_label.add_theme_font_size_override("font_size", 16)
	_choice_hint_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.6, 0.8))
	_choice_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_hint_label.visible = false
	$Box.add_child(_choice_hint_label)


func _build_top_options_panel() -> void:
	_top_options_panel = PanelContainer.new()
	_top_options_panel.name = "TopOptionsPanel"
	_top_options_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# 顶部选项不使用外层底框，只保留按钮自身的边框。
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0)
	panel_style.border_color = Color(0, 0, 0, 0)
	panel_style.set_border_width_all(0)
	panel_style.content_margin_left = 0
	panel_style.content_margin_right = 0
	panel_style.content_margin_top = 0
	panel_style.content_margin_bottom = 0
	_top_options_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_top_options_panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	_top_options_panel.add_child(margin)
	
	_top_options_vbox = VBoxContainer.new()
	_top_options_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(_top_options_vbox)
	_top_options_panel.visible = false


func _position_top_options(option_count: int) -> void:
	var vp := get_viewport_rect().size
	var panel_w: float = min(880.0, vp.x * 0.80)
	# 根据选项数量动态调整按钮高度和间距
	var btn_height: float = 44.0
	var separation: int = 10
	if option_count > 6:
		btn_height = 36.0
		separation = 6
	if option_count > 8:
		btn_height = 32.0
		separation = 4
	_top_options_vbox.add_theme_constant_override("separation", separation)
	for child in _top_options_vbox.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0, btn_height)
	var panel_h: float = min(380.0, max(1, option_count) * (btn_height + separation) + separation)
	_top_options_panel.size = Vector2(panel_w, panel_h)
	# 选项少时，不贴顶显示；在顶部可用区域内尽量垂直居中。
	var top_margin := 56.0
	var bottom_margin := 18.0
	var dialogue_top := global_position.y
	if dialogue_top <= 0.0:
		dialogue_top = vp.y - 320.0
	var upper_area_h: float = max(panel_h, dialogue_top - top_margin - bottom_margin)
	var target_global_y: float
	if option_count <= 4:
		target_global_y = top_margin + (upper_area_h - panel_h) * 0.5
	elif option_count <= 6:
		target_global_y = top_margin + (upper_area_h - panel_h) * 0.35
	else:
		target_global_y = top_margin
	var target_global_x := (vp.x - panel_w) * 0.5
	_top_options_panel.position = Vector2(target_global_x - global_position.x, target_global_y - global_position.y)


func _hide_options() -> void:
	legacy_options.visible = false
	exit_btn.visible = false
	if _top_options_panel:
		_top_options_panel.visible = false
	if _top_options_vbox:
		for child in _top_options_vbox.get_children():
			child.queue_free()
	for child in options_vbox.get_children():
		child.queue_free()


func _show_options(options: Array) -> void:
	_hide_options()
	var visible_count := 0
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var goto_val: String = opt.get("goto", "")
		if goto_val == "__exit__":
			continue
		var option_text: String = opt.get("text", "")
		if opt.get("_visited", false):
			option_text = "✓ " + option_text
		var btn := _make_option_button(option_text)
		if _is_evidence_option(opt):
			_apply_evidence_option_style(btn)
		var idx := i
		btn.pressed.connect(func():
			_on_option_pressed(idx, opt)
		)
		_top_options_vbox.add_child(btn)
		visible_count += 1
	var close_btn := _make_option_button("（先告辞，待会再来）  ✕")
	close_btn.pressed.connect(func():
		_hide_options()
		_choice_hint_label.visible = false
		DialogueManager.end_dialogue(false)
	)
	_top_options_vbox.add_child(close_btn)
	visible_count += 1
	_position_top_options(visible_count)
	_top_options_panel.visible = true


func _make_option_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.72, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1))
	return btn


func _on_option_pressed(idx: int, opt: Dictionary) -> void:
	_hide_options()
	_choice_hint_label.visible = false
	if _is_evidence_option(opt):
		await _play_evidence_present_fx(_evidence_title(opt))
	DialogueManager.choose_option(idx)


func _is_evidence_option(opt: Dictionary) -> bool:
	var option_text: String = opt.get("text", "")
	if option_text.find("出示") >= 0 or option_text.find("证据") >= 0:
		return true
	if opt.get("requires_evidence", "") != "":
		return true
	for req in opt.get("requires", []):
		if req is Dictionary and req.has("evidence"):
			return true
	return false


func _evidence_title(opt: Dictionary) -> String:
	var option_text: String = opt.get("text", "")
	var start := option_text.find("【出示")
	if start >= 0:
		var end := option_text.find("】", start)
		if end > start:
			return option_text.substr(start + 3, end - start - 3)
	if option_text != "":
		return option_text.replace("【", "").replace("】", "")
	return "关键证据"


func _apply_evidence_option_style(btn: Button) -> void:
	btn.text = "⚖  " + btn.text
	btn.add_theme_font_size_override("font_size", 19)
	btn.add_theme_color_override("font_color", Color(1.0, 0.86, 0.44, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.68, 1))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_color_override("font_outline_color", Color(0.03, 0.015, 0.0, 1))
	var normal := _make_evidence_button_style(Color(0.13, 0.07, 0.035, 0.90), Color(0.95, 0.58, 0.22, 0.80), 12)
	var hover := _make_evidence_button_style(Color(0.18, 0.09, 0.04, 0.96), Color(1.0, 0.78, 0.34, 1.0), 18)
	var pressed := _make_evidence_button_style(Color(0.09, 0.045, 0.025, 0.98), Color(1.0, 0.88, 0.46, 1.0), 10)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)


func _make_evidence_button_style(bg: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(1.0, 0.48, 0.18, 0.26)
	style.shadow_size = shadow_size
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _play_evidence_present_fx(evidence_name: String) -> void:
	var root := get_tree().current_scene
	if root == null:
		root = self
	var layer := Control.new()
	layer.name = "EvidencePresentFX"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(layer)
	root.move_child(layer, root.get_child_count() - 1)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.005, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)

	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.72, 0.28, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 128)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.055, 0.025, 0.94)
	style.border_color = Color(0.95, 0.67, 0.28, 0.96)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.62)
	style.shadow_size = 24
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "呈 上 证 据"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.46, 1))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "「%s」" % evidence_name
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.92, 0.82, 0.64, 1))
	subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	subtitle.add_theme_constant_override("outline_size", 2)
	vbox.add_child(subtitle)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "color:a", 0.58, 0.16)
	tw.tween_property(flash, "color:a", 0.22, 0.08)
	tw.tween_property(panel, "modulate:a", 1.0, 0.16)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	var tw_flash := create_tween()
	tw_flash.tween_property(flash, "color:a", 0.0, 0.22)
	await get_tree().create_timer(0.42).timeout
	var tw_out := create_tween()
	tw_out.set_parallel(true)
	tw_out.tween_property(dim, "color:a", 0.0, 0.18)
	tw_out.tween_property(panel, "modulate:a", 0.0, 0.14)
	tw_out.tween_property(panel, "scale", Vector2(1.04, 1.04), 0.14)
	await tw_out.finished
	if is_instance_valid(layer):
		layer.queue_free()
