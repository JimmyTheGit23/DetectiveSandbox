extends Control
## NPC 对话框：底部显示立绘、名字和文本；文字播完后才在画面上方显示选项。

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")

@onready var dim_bg: PanelContainer = $DimBg
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
var _log_button: Button = null
var _log_panel: PanelContainer = null
var _log_text: RichTextLabel = null
var _dialogue_pages: Array = []
var _dialogue_page_index: int = 0
var _dialogue_options: Array = []
var _waiting_for_advance: bool = false
var _dialogue_run_id: int = 0
var _dialogue_log: Array[String] = []
var _last_speaker: String = ""
var _last_emotion: String = ""
var _portrait_tween: Tween = null

const DEFAULT_PORTRAIT_POSITION := Vector2(34, -200)
const DEFAULT_PORTRAIT_SIZE := Vector2(200, 500)
const OPERA_PERFORMER_PORTRAIT_POSITION := Vector2(-66, -200)
const OPERA_PERFORMER_PORTRAIT_SIZE := Vector2(300, 500)
const SENIOR_PREFECT_PORTRAIT_POSITION := Vector2(-18, -160)
const SENIOR_PREFECT_PORTRAIT_SIZE := Vector2(250, 470)
const CLR_GOLD := Color(0.96, 0.84, 0.46, 1.0)
const CLR_PAPER := Color(0.12, 0.075, 0.04, 0.94)
const CLR_INK := Color(0.92, 0.86, 0.72, 1.0)
const KEYWORD_HIGHLIGHTS := [
	"船板", "撞礁", "暗礁", "水涨", "破洞", "凿痕", "钉眼", "浮囊", "包袱",
	"二两", "十二年", "遣散", "赌债", "四十二两", "不到一刻钟", "半个时辰", "夜船"
]


func _ready() -> void:
	legacy_options.visible = false
	exit_btn.visible = false
	text_label.anchor_bottom = 1.0
	text_label.offset_bottom = -46.0
	text_label.bbcode_enabled = true
	text_label.scroll_active = false
	text_label.add_theme_font_size_override("normal_font_size", 22)
	text_label.add_theme_color_override("default_color", CLR_INK)
	text_label.add_theme_constant_override("line_separation", 6)
	_apply_dialogue_chrome()
	_build_choice_hint()
	_build_log_controls()
	_build_top_options_panel()
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _log_panel != null and _log_panel.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_log_panel.visible = false
			get_viewport().set_input_as_handled()
		return
	var advance_pressed := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_click_on_log_button(event.position):
			return
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
	if _log_panel != null:
		_log_panel.visible = false
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
	_apply_speaker(page.get("speaker", ""), page.get("portrait", ""), page.get("emotion", ""))
	var page_text: String = page.get("text", "")
	_append_dialogue_log(page.get("speaker", ""), page_text)
	_typewriter.play(text_label, _decorate_text(page_text, page.get("highlight", [])))
	await _typewriter.finished
	if run_id != _dialogue_run_id:
		return
	if _page_has_record(page):
		_record_page_to_notebook(page)
		await _play_record_fx(page)
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


func _apply_speaker(speaker: String, portrait_path: String, emotion: String = "") -> void:
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
	portrait_rect.position = DEFAULT_PORTRAIT_POSITION
	portrait_rect.size = DEFAULT_PORTRAIT_SIZE
	portrait_rect.pivot_offset = portrait_rect.size * 0.5
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if portrait_path.ends_with("actor_opera_performer.png"):
		portrait_rect.position = OPERA_PERFORMER_PORTRAIT_POSITION
		portrait_rect.size = OPERA_PERFORMER_PORTRAIT_SIZE
		portrait_rect.pivot_offset = portrait_rect.size * 0.5
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	elif portrait_path.ends_with("actor_senior_prefect.png"):
		portrait_rect.position = SENIOR_PREFECT_PORTRAIT_POSITION
		portrait_rect.size = SENIOR_PREFECT_PORTRAIT_SIZE
		portrait_rect.pivot_offset = portrait_rect.size * 0.5
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var resolved_portrait := _resolve_emotion_portrait(portrait_path, emotion)
	var target_modulate := _emotion_modulate(emotion)
	var target_rotation := _emotion_rotation(emotion)
	var target_scale := _emotion_scale(emotion)
	var base_position := portrait_rect.position
	var changed := speaker != _last_speaker or emotion != _last_emotion
	_last_speaker = speaker
	_last_emotion = emotion
	if resolved_portrait != "" and ResourceLoader.exists(resolved_portrait):
		portrait_rect.texture = load(resolved_portrait)
		portrait_rect.visible = true
		if _portrait_tween != null and _portrait_tween.is_valid():
			_portrait_tween.kill()
		portrait_rect.rotation = target_rotation
		portrait_rect.scale = target_scale
		if changed:
			portrait_rect.position = base_position + Vector2(-18, 0)
			portrait_rect.modulate = Color(target_modulate.r, target_modulate.g, target_modulate.b, 0.45)
			_portrait_tween = create_tween()
			_portrait_tween.set_parallel(true)
			_portrait_tween.tween_property(portrait_rect, "position", base_position, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_portrait_tween.tween_property(portrait_rect, "modulate", target_modulate, 0.18)
		else:
			portrait_rect.position = base_position
			portrait_rect.modulate = target_modulate
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
		var sentences := _split_dialogue_text(line_text)
		for idx in range(sentences.size()):
			var page := {
				"speaker": speaker,
				"portrait": portrait,
				"text": sentences[idx],
				"type": raw_page.get("type", ""),
				"emotion": raw_page.get("emotion", raw_page.get("mood", "")),
				"highlight": raw_page.get("highlight", [])
			}
			if idx == sentences.size() - 1:
				_copy_record_meta(raw_page, page)
			pages.append(page)
	return pages


func _copy_record_meta(src: Dictionary, dst: Dictionary) -> void:
	for key in ["record", "record_type", "record_title", "record_text", "record_id"]:
		if src.has(key):
			dst[key] = src[key]


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


func _apply_dialogue_chrome() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.045, 0.03, 0.018, 0.88)
	bg_style.border_color = Color(0.66, 0.48, 0.22, 0.42)
	bg_style.set_border_width_all(1)
	bg_style.shadow_color = Color(0, 0, 0, 0.42)
	bg_style.shadow_size = 18
	bg_style.content_margin_left = 12
	bg_style.content_margin_right = 12
	bg_style.content_margin_top = 10
	bg_style.content_margin_bottom = 10
	dim_bg.add_theme_stylebox_override("panel", bg_style)
	speaker_label.add_theme_font_size_override("font_size", 27)
	speaker_label.add_theme_color_override("font_color", CLR_GOLD)
	speaker_label.add_theme_color_override("font_outline_color", Color(0.025, 0.012, 0.0, 1))
	speaker_label.add_theme_constant_override("outline_size", 4)


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


func _build_log_controls() -> void:
	_log_button = Button.new()
	_log_button.text = "卷宗回看"
	_log_button.anchor_left = 1.0
	_log_button.anchor_right = 1.0
	_log_button.offset_left = -118.0
	_log_button.offset_top = 0.0
	_log_button.offset_right = -2.0
	_log_button.offset_bottom = 34.0
	_log_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_log_button.z_index = 20
	_log_button.add_theme_font_size_override("font_size", 15)
	_log_button.add_theme_color_override("font_color", Color(0.92, 0.82, 0.58, 0.95))
	_log_button.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_toggle_dialogue_log()
			_log_button.accept_event()
	)
	_apply_plain_button_style(_log_button, Color(0.09, 0.055, 0.025, 0.9), Color(0.58, 0.42, 0.2, 0.55))
	$Box.add_child(_log_button)

	_log_panel = PanelContainer.new()
	_log_panel.name = "DialogueLogPanel"
	_log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_log_panel.anchor_left = 1.0
	_log_panel.anchor_top = 0.0
	_log_panel.anchor_right = 1.0
	_log_panel.anchor_bottom = 0.0
	_log_panel.offset_left = -500.0
	_log_panel.offset_top = -390.0
	_log_panel.offset_right = -22.0
	_log_panel.offset_bottom = -28.0
	_log_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.048, 0.026, 0.96)
	panel_style.border_color = Color(0.78, 0.56, 0.26, 0.72)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 22
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	_log_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_log_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_log_panel.add_child(vbox)
	var hb := HBoxContainer.new()
	vbox.add_child(hb)
	var title := Label.new()
	title.text = "── 对话卷宗 ──"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", CLR_GOLD)
	hb.add_child(title)
	var close := Button.new()
	close.text = "收起"
	close.add_theme_font_size_override("font_size", 14)
	close.pressed.connect(func(): _log_panel.visible = false)
	_apply_plain_button_style(close, Color(0.10, 0.06, 0.03, 0.9), Color(0.58, 0.42, 0.2, 0.55))
	hb.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_log_text = RichTextLabel.new()
	_log_text.bbcode_enabled = true
	_log_text.fit_content = true
	_log_text.scroll_active = false
	_log_text.add_theme_font_size_override("normal_font_size", 17)
	_log_text.add_theme_color_override("default_color", Color(0.9, 0.84, 0.72, 1))
	scroll.add_child(_log_text)


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
	if _log_button != null:
		_log_button.visible = true
	if _top_options_panel:
		_top_options_panel.visible = false
	if _top_options_vbox:
		for child in _top_options_vbox.get_children():
			child.queue_free()
	for child in options_vbox.get_children():
		child.queue_free()


func _show_options(options: Array) -> void:
	_hide_options()
	var action_items: Array = []
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var goto_val: String = opt.get("goto", "")
		if goto_val == "__exit__":
			continue
		var option_text: String = opt.get("text", "")
		if opt.get("_visited", false):
			option_text = "✓ " + option_text
		var info := _option_type_info(option_text, opt)
		action_items.append({"idx": i, "opt": opt, "text": option_text, "type": info.get("type", "ask")})
	var visible_count := 0
	if _should_group_options(action_items):
		visible_count = _show_grouped_options(action_items)
	else:
		visible_count = _show_flat_options(action_items)
	var close_btn := _make_option_button("先告辞，待会再来", {"type": "leave"})
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.pressed.connect(func():
		_hide_options()
		_choice_hint_label.visible = false
		DialogueManager.end_dialogue(false)
	)
	_top_options_vbox.add_child(close_btn)
	visible_count += 1
	_position_top_options(visible_count)
	_top_options_panel.visible = true
	# 选项阶段隐藏卷宗回看按钮，避免和选项/对话文本抢视觉焦点。
	if _log_button != null:
		_log_button.visible = false
	if _log_panel != null and _log_panel.visible:
		_raise_log_panel()


func _show_flat_options(items: Array) -> int:
	var visible_count := 0
	for item in items:
		var opt: Dictionary = item.get("opt", {})
		var btn := _make_option_button(item.get("text", ""), opt)
		if _is_evidence_option(opt):
			_apply_evidence_option_style(btn)
		var idx: int = item.get("idx", 0)
		btn.pressed.connect(func():
			_on_option_pressed(idx, opt)
		)
		_top_options_vbox.add_child(btn)
		visible_count += 1
	return visible_count


func _show_grouped_options(items: Array) -> int:
	var ask_items: Array = []
	var action_items: Array = []
	var other_items: Array = []
	for item in items:
		var option_type := str(item.get("type", "ask"))
		if option_type == "ask":
			ask_items.append(item)
		elif option_type in ["press", "observe", "probe", "record", "evidence"]:
			action_items.append(item)
		else:
			other_items.append(item)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	_top_options_vbox.add_child(row)
	var group_count := 0
	if not ask_items.is_empty():
		row.add_child(_make_option_group("问话", ask_items))
		group_count += 1
	if not action_items.is_empty():
		row.add_child(_make_option_group("追问 / 观察", action_items))
		group_count += 1
	if group_count == 0:
		_top_options_vbox.remove_child(row)
		row.queue_free()
	var visible_count: int = max(ask_items.size(), action_items.size()) + 1
	for item in other_items:
		var opt: Dictionary = item.get("opt", {})
		var btn := _make_option_button(item.get("text", ""), opt)
		var idx: int = item.get("idx", 0)
		btn.pressed.connect(func(): _on_option_pressed(idx, opt))
		_top_options_vbox.add_child(btn)
		visible_count += 1
	return visible_count


func _make_option_group(title_text: String, items: Array) -> PanelContainer:
	var group := PanelContainer.new()
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.022, 0.012, 0.30)
	style.border_color = Color(0.62, 0.45, 0.22, 0.42)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	group.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	group.add_child(box)
	var title := Label.new()
	title.text = "── %s ──" % title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.92, 0.78, 0.44, 0.92))
	box.add_child(title)
	for item in items:
		var opt: Dictionary = item.get("opt", {})
		var btn := _make_option_button(item.get("text", ""), opt)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _is_evidence_option(opt):
			_apply_evidence_option_style(btn)
		var idx: int = item.get("idx", 0)
		btn.pressed.connect(func(): _on_option_pressed(idx, opt))
		box.add_child(btn)
	return group


func _should_group_options(items: Array) -> bool:
	if items.size() < 4:
		return false
	var ask_count := 0
	var action_count := 0
	for item in items:
		var option_type := str(item.get("type", "ask"))
		if option_type == "ask":
			ask_count += 1
		elif option_type in ["press", "observe", "probe", "record", "evidence"]:
			action_count += 1
	return ask_count > 0 and action_count > 0


func _make_option_button(text: String, opt: Dictionary = {}) -> Button:
	var info := _option_type_info(text, opt)
	var btn := Button.new()
	btn.text = info.get("label", text)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 18)
	_apply_option_button_style(btn, info.get("type", "ask"))
	return btn


func _option_type_info(text: String, opt: Dictionary) -> Dictionary:
	var clean := text.strip_edges()
	var visited := false
	if clean.begins_with("✓ "):
		visited = true
		clean = clean.substr(2).strip_edges()
	var option_type: String = str(opt.get("type", "")).strip_edges()
	if option_type == "":
		if clean.begins_with("追问"):
			option_type = "press"
		elif clean.begins_with("观察"):
			option_type = "observe"
		elif clean.begins_with("试探"):
			option_type = "probe"
		elif clean.begins_with("记录"):
			option_type = "record"
		elif clean.begins_with("继续"):
			option_type = "continue"
		elif clean.begins_with("先告辞") or clean.begins_with("离开"):
			option_type = "leave"
		elif _is_evidence_option(opt):
			option_type = "evidence"
		else:
			option_type = "ask"
	var prefix := "〔问〕"
	match option_type:
		"press":
			prefix = "〔追问〕"
		"observe":
			prefix = "〔观察〕"
		"probe":
			prefix = "〔试探〕"
		"record":
			prefix = "〔记录〕"
		"continue":
			prefix = "〔续问〕"
		"leave":
			prefix = "〔离开〕"
		"evidence":
			prefix = "〔呈证〕"
	var label := "%s  %s" % [prefix, _strip_option_prefix(clean)]
	if visited:
		label = "✓ " + label
	return {"type": option_type, "label": label}


func _strip_option_prefix(text: String) -> String:
	for p in ["追问", "观察", "试探", "记录", "问", "离开"]:
		if text.begins_with(p):
			return text.substr(p.length()).strip_edges()
	return text


func _apply_option_button_style(btn: Button, option_type: String) -> void:
	var bg := Color(0.085, 0.055, 0.03, 0.88)
	var border := Color(0.55, 0.42, 0.22, 0.66)
	var font := Color(0.95, 0.86, 0.62, 1)
	match option_type:
		"press":
			bg = Color(0.12, 0.065, 0.032, 0.92)
			border = Color(0.92, 0.56, 0.22, 0.88)
			font = Color(1.0, 0.82, 0.48, 1)
		"observe":
			bg = Color(0.055, 0.075, 0.08, 0.9)
			border = Color(0.48, 0.68, 0.72, 0.72)
			font = Color(0.78, 0.92, 0.95, 1)
		"probe":
			bg = Color(0.11, 0.04, 0.035, 0.92)
			border = Color(0.82, 0.28, 0.22, 0.76)
			font = Color(1.0, 0.72, 0.58, 1)
		"record":
			bg = Color(0.10, 0.08, 0.045, 0.92)
			border = Color(0.82, 0.66, 0.34, 0.78)
			font = Color(0.98, 0.9, 0.62, 1)
		"leave", "continue":
			font = Color(0.72, 0.66, 0.54, 1)
	btn.add_theme_color_override("font_color", font)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.72, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1))
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 1))
	btn.add_theme_constant_override("outline_size", 2)
	_apply_plain_button_style(btn, bg, border)


func _apply_plain_button_style(btn: Button, bg: Color, border: Color) -> void:
	var normal := _make_button_style(bg, border, 4)
	var hover := _make_button_style(Color(bg.r + 0.035, bg.g + 0.025, bg.b + 0.015, bg.a), Color(border.r + 0.18, border.g + 0.14, border.b + 0.08, min(1.0, border.a + 0.2)), 10)
	var pressed := _make_button_style(Color(bg.r * 0.72, bg.g * 0.72, bg.b * 0.72, min(1.0, bg.a + 0.06)), border, 2)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)


func _make_button_style(bg: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = shadow_size
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


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
	var had_visited := btn.text.begins_with("✓")
	btn.text = ("✓ " if had_visited else "") + "〔呈证〕  " + _strip_evidence_label(btn.text)
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


func _strip_evidence_label(text: String) -> String:
	var out := text
	for prefix in ["✓ 〔呈证〕", "〔呈证〕", "✓ 〔问〕", "〔问〕"]:
		if out.begins_with(prefix):
			out = out.substr(prefix.length()).strip_edges()
	return out


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


func _decorate_text(text: String, extra_highlights = []) -> String:
	var out := text
	var words: Array = []
	for kw in KEYWORD_HIGHLIGHTS:
		words.append(kw)
	if extra_highlights is Array:
		for kw in extra_highlights:
			words.append(str(kw))
	elif extra_highlights is String and str(extra_highlights) != "":
		words.append(str(extra_highlights))
	for kw in words:
		if kw == "":
			continue
		if out.find(kw) >= 0 and out.find("[font_size=28][color=#e84a36][b]" + kw) < 0:
			out = out.replace(kw, "[font_size=28][color=#e84a36][b]%s[/b][/color][/font_size]" % kw)
	if out.begins_with("（") and out.ends_with("）"):
		out = "[color=#b9aa8a]%s[/color]" % out
	return out


func _append_dialogue_log(speaker: String, text: String) -> void:
	if text.strip_edges() == "":
		return
	var who := speaker
	if who == "":
		who = "旁白"
	var entry := "[color=#f2c15a]%s[/color]：%s" % [who, text]
	_dialogue_log.append(entry)
	while _dialogue_log.size() > 120:
		_dialogue_log.pop_front()
	if GameManager != null and GameManager.has_method("add_dialogue_record"):
		GameManager.add_dialogue_record(who, text)
	_update_log_text()


func _update_log_text() -> void:
	if _log_text == null:
		return
	var entries: Array[String] = []
	var saved_records = GameManager.get("dialogue_records") if GameManager != null else []
	if saved_records is Array:
		for record in saved_records:
			if typeof(record) != TYPE_DICTIONARY:
				continue
			entries.append("[color=#f2c15a]%s[/color]：%s" % [record.get("speaker", "旁白"), record.get("text", "")])
	if entries.is_empty():
		entries = _dialogue_log.duplicate()
	_log_text.text = "\n\n".join(entries)


func _is_click_on_log_button(pos: Vector2) -> bool:
	return _log_button != null and _log_button.visible and _log_button.get_global_rect().has_point(pos)


func _toggle_dialogue_log() -> void:
	if _log_panel == null:
		return
	_update_log_text()
	_log_panel.visible = not _log_panel.visible
	if _log_panel.visible:
		_raise_log_panel()


func _raise_log_panel() -> void:
	if _log_panel != null and _log_panel.get_parent() == self:
		move_child(_log_panel, get_child_count() - 1)


func _page_has_record(page: Dictionary) -> bool:
	if page.has("record"):
		return bool(page.get("record", false))
	return str(page.get("record_type", "")).strip_edges() != "" or str(page.get("record_title", "")).strip_edges() != ""


func _record_page_to_notebook(page: Dictionary) -> void:
	if GameManager == null or not GameManager.has_method("add_case_record"):
		return
	var record_type := str(page.get("record_type", "testimony"))
	var title := str(page.get("record_title", ""))
	if title == "":
		title = "证词记录" if record_type == "testimony" else "关键信息"
	var text := str(page.get("record_text", page.get("text", ""))).strip_edges()
	GameManager.add_case_record({
		"id": str(page.get("record_id", "%s|%s" % [title, text])),
		"type": record_type,
		"title": title,
		"text": text,
		"source": str(page.get("speaker", "")),
	})


func _play_record_fx(page: Dictionary) -> void:
	var root := get_tree().current_scene
	if root == null:
		root = self
	var layer := Control.new()
	layer.name = "TestimonyRecordFX"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(layer)
	root.move_child(layer, root.get_child_count() - 1)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 112)
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -560.0
	panel.offset_top = 94.0
	panel.offset_right = -34.0
	panel.offset_bottom = 220.0
	panel.modulate.a = 0.0
	panel.position.x += 38.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.085, 0.04, 0.96)
	style.border_color = Color(0.92, 0.68, 0.32, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 18
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	var record_type := str(page.get("record_type", "testimony"))
	var title_text := str(page.get("record_title", ""))
	if title_text == "":
		title_text = "证词记录" if record_type == "testimony" else "疑点记录"
	var title := Label.new()
	title.text = "── %s ──" % title_text
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", CLR_GOLD)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 2)
	vbox.add_child(title)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.add_theme_font_size_override("normal_font_size", 18)
	body.add_theme_color_override("default_color", Color(0.92, 0.86, 0.72, 1))
	var record_text := str(page.get("record_text", page.get("text", "")))
	body.text = _decorate_text(record_text, page.get("highlight", []))
	vbox.add_child(body)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	tw.tween_property(panel, "position:x", panel.position.x - 38.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.72).timeout
	var tw_out := create_tween()
	tw_out.set_parallel(true)
	tw_out.tween_property(panel, "modulate:a", 0.0, 0.18)
	tw_out.tween_property(panel, "position:x", panel.position.x + 18.0, 0.18)
	await tw_out.finished
	if is_instance_valid(layer):
		layer.queue_free()


func _resolve_emotion_portrait(base_path: String, emotion: String) -> String:
	if base_path == "" or emotion == "" or emotion == "normal":
		return base_path
	var candidates: Array[String] = []
	candidates.append(base_path.replace(".png", "_%s.png" % emotion))
	if emotion in ["nervous", "panic", "defensive", "cornered", "shaken"]:
		candidates.append(base_path.replace(".png", "_shaken.png"))
	if emotion in ["breakdown", "collapsed"]:
		candidates.append(base_path.replace(".png", "_collapsed.png"))
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return base_path


func _emotion_modulate(emotion: String) -> Color:
	match emotion:
		"nervous", "panic":
			return Color(1.0, 0.94, 0.78, 1.0)
		"defensive", "angry":
			return Color(1.0, 0.82, 0.74, 1.0)
		"shaken", "cornered":
			return Color(0.92, 0.9, 0.78, 1.0)
		"breakdown", "collapsed":
			return Color(0.74, 0.72, 0.68, 0.92)
		_:
			return Color(1, 1, 1, 1)


func _emotion_rotation(emotion: String) -> float:
	match emotion:
		"shaken", "cornered":
			return -0.025
		"breakdown", "collapsed":
			return -0.06
		_:
			return 0.0


func _emotion_scale(emotion: String) -> Vector2:
	match emotion:
		"angry", "defensive":
			return Vector2(1.025, 1.025)
		"breakdown", "collapsed":
			return Vector2(0.98, 0.98)
		_:
			return Vector2(1, 1)


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
