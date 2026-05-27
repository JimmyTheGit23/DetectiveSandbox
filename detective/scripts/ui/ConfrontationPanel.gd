extends Control
## 对峙面板：逆转裁判式交叉询问
##
## 流程：犯人给出一段证词（多句） → 玩家逐句浏览
## 		两个操作：威慑（追问，安全无惩罚） / 举证（出示证据，选错扣信心）
## 		击破矛盾句后进入下一段证词 → 全部击破=胜利

signal confrontation_finished(result: String, mistakes: int)

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")

# ─── 状态机 ───
enum State {
	TITLE_ANIM,         # "开始对峙" 大字特效
	INTRO,              # 开场对话
	TESTIMONY_INTRO,    # 显示证词标题
	BROWSING,           # 自由浏览证词，可威慑/举证
	PRESSING,           # 正在播放威慑对话
	EVIDENCE_OPEN,      # 证据面板已展开
	BREAK_ANIM,        # 击破动画
	FAIL_ANIM,          # 失败闪红
	VICTORY,            # 全部击破
	DEFEAT              # 信心归零
}
var _state: int = State.TITLE_ANIM

# ─── 数据 ───
var _confrontation_data: Dictionary = {}
var _testimonies: Array = []
var _current_testimony_idx: int = 0
var _statements: Array = []         # 当前证词的语句列表（可动态追加）
var _current_stmt_idx: int = 0
var _pressed_stmts: Dictionary = {} # stmt_id → true (已威慑过)
var _confidence: int = 3
var _max_confidence: int = 3
var _mistakes: int = 0
var _selected_evidence_id: String = ""

# ─── 对话播放 ───
var _dialogue_queue: Array = []
var _dialogue_idx: int = 0
var _click_callback: Callable = Callable()
var _typewriter: Node = null
var _typewriter_playing: bool = false

# ─── 对话头像 ───
var _dlg_portrait_rect: TextureRect = null

# ─── 节点引用 ───
var _panel: Control
var _portrait_rect: TextureRect
var _confidence_label: Label
var _testimony_title_label: Label
var _stmt_counter_label: Label
var _stmt_text_label: RichTextLabel
var _prev_btn: Button
var _next_btn: Button
var _dot_container: HBoxContainer
var _press_btn: Button
var _present_btn: Button
var _evidence_panel: PanelContainer
var _evidence_container: HBoxContainer
var _dialogue_box: PanelContainer
var _dialogue_speaker: Label
var _dialogue_text: RichTextLabel
var _objection_layer: Control
var _action_bar: HBoxContainer

# ─── 立绘 ───
enum PortraitState { NORMAL, SHAKEN, COLLAPSED }
var _portrait_state: int = PortraitState.NORMAL
var _shake_tween: Tween = null

# ─── 风格常量 ───
const CLR_GOLD := Color(0.96, 0.88, 0.65)
const CLR_GOLD_BRIGHT := Color(1.0, 0.92, 0.55)
const CLR_DIM := Color(0.55, 0.50, 0.42, 0.6)
const CLR_RED := Color(0.85, 0.25, 0.18, 0.9)
const CLR_GREEN := Color(0.3, 0.8, 0.35)
const CLR_NEW_DOT := Color(0.4, 0.85, 1.0)


func _ready() -> void:
	# 隐藏右侧菜单，避免遮挡
	var main_scene := get_tree().current_scene
	if main_scene:
		var menu := main_scene.get_node_or_null("RightMenu")
		if menu:
			menu.visible = false

	var _confront_key: String = GameManager.active_confrontation_key
	_confrontation_data = GameManager.case_data.get(_confront_key, {})
	if _confrontation_data.is_empty():
		push_warning("ConfrontationPanel: No confrontation data for key '%s'!" % _confront_key)
		# 尝试直接读取 case.json
		var path := "res://data/cases/%s/case.json" % GameManager.ACTIVE_CASE
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_confrontation_data = parsed.get(_confront_key, {})
	_testimonies = _confrontation_data.get("testimonies", [])
	_max_confidence = int(_confrontation_data.get("confidence", 3))
	_confidence = _max_confidence
	_current_testimony_idx = 0
	_mistakes = 0
	_portrait_state = PortraitState.NORMAL
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)
	# intro 阶段用客栈音乐，证言开始时才切对峙BGM
	var bgm_player := get_node_or_null("/root/BgmPlayer")
	if bgm_player and bgm_player.has_method("play"):
		bgm_player.play("ferry_inn")
	_build_ui()
	_enter_state(State.TITLE_ANIM)


# ═══════════════════════════════════════════════════
#  UI 构建
# ═══════════════════════════════════════════════════

func _build_ui() -> void:
	# ── 全屏背景 ──
	var bg_tex := TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_path: String = _confrontation_data.get("background", "")
	if bg_path == "" or not ResourceLoader.exists(bg_path):
		bg_path = GameManager.current_location_data().get("background", "")
	if bg_path != "" and ResourceLoader.exists(bg_path):
		bg_tex.texture = load(bg_path)
	add_child(bg_tex)

	# 暗色遮罩
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.01, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	# ── 信心条（左上） ──
	_confidence_label = Label.new()
	_confidence_label.anchor_left = 0.0
	_confidence_label.anchor_top = 0.0
	_confidence_label.offset_left = 24
	_confidence_label.offset_top = 16
	_confidence_label.offset_right = 300
	_confidence_label.offset_bottom = 50
	_confidence_label.add_theme_font_size_override("font_size", 24)
	_confidence_label.add_theme_color_override("font_color", Color(0.95, 0.3, 0.25))
	_panel.add_child(_confidence_label)
	_update_confidence_display()

	# ── 证词标题（右上） ──
	_testimony_title_label = Label.new()
	_testimony_title_label.anchor_left = 1.0
	_testimony_title_label.anchor_right = 1.0
	_testimony_title_label.anchor_top = 0.0
	_testimony_title_label.offset_left = -380
	_testimony_title_label.offset_top = 16
	_testimony_title_label.offset_right = -24
	_testimony_title_label.offset_bottom = 50
	_testimony_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_testimony_title_label.add_theme_font_size_override("font_size", 18)
	_testimony_title_label.add_theme_color_override("font_color", CLR_DIM)
	_panel.add_child(_testimony_title_label)

	# ── 犯人立绘（居中，大） ──
	_portrait_rect = TextureRect.new()
	_portrait_rect.anchor_left = 0.5
	_portrait_rect.anchor_right = 0.5
	_portrait_rect.anchor_top = 0.0
	_portrait_rect.anchor_bottom = 1.0
	_portrait_rect.offset_left = -260
	_portrait_rect.offset_top = 30
	_portrait_rect.offset_right = 260
	_portrait_rect.offset_bottom = 80
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_portrait_rect)
	# intro 期间不显示立绘，等进入证言阶段再显示
	_portrait_rect.visible = false

	# ── 证词显示区（中下，带导航箭头） ──
	var stmt_area := PanelContainer.new()
	stmt_area.name = "StmtArea"
	stmt_area.anchor_left = 0.04
	stmt_area.anchor_right = 0.96
	stmt_area.anchor_top = 1.0
	stmt_area.anchor_bottom = 1.0
	stmt_area.offset_top = -280
	stmt_area.offset_bottom = -170
	var stmt_style := StyleBoxFlat.new()
	stmt_style.bg_color = Color(0.04, 0.03, 0.02, 0.94)
	stmt_style.border_color = Color(0.7, 0.5, 0.2, 0.7)
	stmt_style.set_border_width_all(2)
	stmt_style.set_corner_radius_all(6)
	stmt_style.content_margin_left = 16
	stmt_style.content_margin_right = 16
	stmt_style.content_margin_top = 12
	stmt_style.content_margin_bottom = 12
	stmt_area.add_theme_stylebox_override("panel", stmt_style)
	_panel.add_child(stmt_area)

	var stmt_hbox := HBoxContainer.new()
	stmt_hbox.add_theme_constant_override("separation", 10)
	stmt_area.add_child(stmt_hbox)

	# ◀ 按钮
	_prev_btn = Button.new()
	_prev_btn.text = "◀"
	_prev_btn.custom_minimum_size = Vector2(48, 60)
	_prev_btn.add_theme_font_size_override("font_size", 28)
	_prev_btn.add_theme_color_override("font_color", CLR_GOLD)
	_prev_btn.flat = true
	_prev_btn.pressed.connect(func(): _navigate_stmt(-1))
	stmt_hbox.add_child(_prev_btn)

	# 中间：文本 + 圆点
	var stmt_center := VBoxContainer.new()
	stmt_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stmt_center.add_theme_constant_override("separation", 8)
	stmt_hbox.add_child(stmt_center)

	# 句号计数器
	_stmt_counter_label = Label.new()
	_stmt_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stmt_counter_label.add_theme_font_size_override("font_size", 13)
	_stmt_counter_label.add_theme_color_override("font_color", CLR_DIM)
	stmt_center.add_child(_stmt_counter_label)

	# 证词文本
	_stmt_text_label = RichTextLabel.new()
	_stmt_text_label.bbcode_enabled = true
	_stmt_text_label.fit_content = true
	_stmt_text_label.scroll_active = false
	_stmt_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stmt_text_label.add_theme_font_size_override("normal_font_size", 22)
	_stmt_text_label.add_theme_color_override("default_color", Color(1.0, 0.95, 0.8))
	stmt_center.add_child(_stmt_text_label)

	# 圆点指示器
	_dot_container = HBoxContainer.new()
	_dot_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_dot_container.add_theme_constant_override("separation", 8)
	stmt_center.add_child(_dot_container)

	# ▶ 按钮
	_next_btn = Button.new()
	_next_btn.text = "▶"
	_next_btn.custom_minimum_size = Vector2(48, 60)
	_next_btn.add_theme_font_size_override("font_size", 28)
	_next_btn.add_theme_color_override("font_color", CLR_GOLD)
	_next_btn.flat = true
	_next_btn.pressed.connect(func(): _navigate_stmt(1))
	stmt_hbox.add_child(_next_btn)

	# ── 操作按钮栏（底部，始终可见） ──
	_action_bar = HBoxContainer.new()
	_action_bar.name = "ActionBar"
	_action_bar.anchor_left = 0.15
	_action_bar.anchor_right = 0.85
	_action_bar.anchor_top = 1.0
	_action_bar.anchor_bottom = 1.0
	_action_bar.offset_top = -150
	_action_bar.offset_bottom = -95
	_action_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_bar.add_theme_constant_override("separation", 40)
	_panel.add_child(_action_bar)

	# 威慑按钮
	_press_btn = Button.new()
	_press_btn.text = "🔍  威  慑"
	_press_btn.custom_minimum_size = Vector2(180, 50)
	_press_btn.add_theme_font_size_override("font_size", 22)
	_press_btn.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	_press_btn.add_theme_color_override("font_hover_color", Color(0.7, 1.0, 1.0))
	var press_style := StyleBoxFlat.new()
	press_style.bg_color = Color(0.05, 0.08, 0.12, 0.92)
	press_style.border_color = Color(0.3, 0.7, 0.9, 0.8)
	press_style.set_border_width_all(2)
	press_style.set_corner_radius_all(8)
	press_style.content_margin_top = 8
	press_style.content_margin_bottom = 8
	_press_btn.add_theme_stylebox_override("normal", press_style)
	var press_hover := press_style.duplicate() as StyleBoxFlat
	press_hover.bg_color = Color(0.08, 0.12, 0.18, 0.96)
	press_hover.border_color = Color(0.4, 0.85, 1.0, 1.0)
	_press_btn.add_theme_stylebox_override("hover", press_hover)
	_press_btn.pressed.connect(_on_press_clicked)
	_action_bar.add_child(_press_btn)

	# 举证按钮
	_present_btn = Button.new()
	_present_btn.text = "⚡  举  证"
	_present_btn.custom_minimum_size = Vector2(180, 50)
	_present_btn.add_theme_font_size_override("font_size", 22)
	_present_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	_present_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.7))
	var present_style := StyleBoxFlat.new()
	present_style.bg_color = Color(0.14, 0.09, 0.04, 0.92)
	present_style.border_color = Color(0.95, 0.7, 0.2, 0.85)
	present_style.set_border_width_all(2)
	present_style.set_corner_radius_all(8)
	present_style.content_margin_top = 8
	present_style.content_margin_bottom = 8
	_present_btn.add_theme_stylebox_override("normal", present_style)
	var present_hover := present_style.duplicate() as StyleBoxFlat
	present_hover.bg_color = Color(0.18, 0.12, 0.05, 0.96)
	present_hover.border_color = Color(1.0, 0.82, 0.3, 1.0)
	_present_btn.add_theme_stylebox_override("hover", present_hover)
	_present_btn.pressed.connect(_on_present_clicked)
	_action_bar.add_child(_present_btn)

	# ── 证据面板（覆盖底部，默认隐藏） ──
	_evidence_panel = PanelContainer.new()
	_evidence_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_evidence_panel.offset_top = -260
	_evidence_panel.visible = false
	var ev_style := StyleBoxFlat.new()
	ev_style.bg_color = Color(0.04, 0.03, 0.02, 0.97)
	ev_style.border_color = Color(0.6, 0.45, 0.2, 0.7)
	ev_style.set_border_width_all(2)
	ev_style.border_width_top = 3
	ev_style.content_margin_left = 20
	ev_style.content_margin_right = 20
	ev_style.content_margin_top = 14
	ev_style.content_margin_bottom = 14
	_evidence_panel.add_theme_stylebox_override("panel", ev_style)
	_panel.add_child(_evidence_panel)

	_evidence_ev_vbox = VBoxContainer.new()
	_evidence_ev_vbox.add_theme_constant_override("separation", 8)
	_evidence_panel.add_child(_evidence_ev_vbox)

	var ev_title := Label.new()
	ev_title.text = "── 选择证物反驳当前证词 ──"
	ev_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev_title.add_theme_font_size_override("font_size", 17)
	ev_title.add_theme_color_override("font_color", CLR_GOLD)
	_evidence_ev_vbox.add_child(ev_title)

	var ev_scroll := ScrollContainer.new()
	ev_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ev_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ev_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ev_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_evidence_ev_vbox.add_child(ev_scroll)

	_evidence_container = HBoxContainer.new()
	_evidence_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_evidence_container.add_theme_constant_override("separation", 12)
	ev_scroll.add_child(_evidence_container)

	# ── 悬浮信息区（固定在滚动区外，始终可见） ──
	_evidence_info_panel = PanelContainer.new()
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.06, 0.05, 0.03, 0.95)
	info_style.border_color = Color(0.5, 0.4, 0.2, 0.5)
	info_style.set_border_width_all(1)
	info_style.set_corner_radius_all(4)
	info_style.content_margin_left = 16
	info_style.content_margin_right = 16
	info_style.content_margin_top = 8
	info_style.content_margin_bottom = 8
	_evidence_info_panel.add_theme_stylebox_override("panel", info_style)
	_evidence_info_panel.custom_minimum_size = Vector2(0, 44)
	_evidence_ev_vbox.add_child(_evidence_info_panel)

	_evidence_info_label = RichTextLabel.new()
	_evidence_info_label.bbcode_enabled = true
	_evidence_info_label.fit_content = true
	_evidence_info_label.scroll_active = false
	_evidence_info_label.add_theme_font_size_override("normal_font_size", 15)
	_evidence_info_label.add_theme_color_override("default_color", Color(0.8, 0.75, 0.6))
	_evidence_info_label.text = "[color=#666655]悬浮查看详情，点击选择证物[/color]"
	_evidence_info_panel.add_child(_evidence_info_label)

	# ── 按钮行（固定在滚动区外，始终可见） ──
	_evidence_btn_row = HBoxContainer.new()
	_evidence_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_evidence_btn_row.add_theme_constant_override("separation", 24)
	_evidence_ev_vbox.add_child(_evidence_btn_row)

	# ── 对话框（覆盖底部，默认隐藏） ──
	_dialogue_box = PanelContainer.new()
	_dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_box.offset_top = -200
	_dialogue_box.visible = false
	var dlg_style := StyleBoxFlat.new()
	dlg_style.bg_color = Color(0.04, 0.03, 0.02, 0.97)
	dlg_style.border_color = Color(0.6, 0.45, 0.22, 0.8)
	dlg_style.set_border_width_all(2)
	dlg_style.border_width_top = 3
	dlg_style.content_margin_left = 200
	dlg_style.content_margin_right = 30
	dlg_style.content_margin_top = 16
	dlg_style.content_margin_bottom = 16
	_dialogue_box.add_theme_stylebox_override("panel", dlg_style)
	_panel.add_child(_dialogue_box)

	var dlg_vbox := VBoxContainer.new()
	dlg_vbox.add_theme_constant_override("separation", 10)
	_dialogue_box.add_child(dlg_vbox)

	_dialogue_speaker = Label.new()
	_dialogue_speaker.add_theme_font_size_override("font_size", 20)
	_dialogue_speaker.add_theme_color_override("font_color", CLR_GOLD)
	dlg_vbox.add_child(_dialogue_speaker)

	_dialogue_text = RichTextLabel.new()
	_dialogue_text.bbcode_enabled = true
	_dialogue_text.fit_content = true
	_dialogue_text.scroll_active = false
	_dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_text.add_theme_font_size_override("normal_font_size", 21)
	_dialogue_text.add_theme_color_override("default_color", Color(0.92, 0.88, 0.78))
	dlg_vbox.add_child(_dialogue_text)

	var continue_hint := Label.new()
	continue_hint.text = "▼ 点击继续"
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_hint.add_theme_font_size_override("font_size", 13)
	continue_hint.add_theme_color_override("font_color", Color(0.6, 0.55, 0.42, 0.6))
	dlg_vbox.add_child(continue_hint)

	# ── 对话立绘（大半身，在对话框左侧向上延伸，类似 DialogueBox） ──
	_dlg_portrait_rect = TextureRect.new()
	_dlg_portrait_rect.anchor_left = 0.0
	_dlg_portrait_rect.anchor_top = 1.0
	_dlg_portrait_rect.anchor_right = 0.0
	_dlg_portrait_rect.anchor_bottom = 1.0
	_dlg_portrait_rect.offset_left = 20
	_dlg_portrait_rect.offset_top = -420
	_dlg_portrait_rect.offset_right = 200
	_dlg_portrait_rect.offset_bottom = 0
	_dlg_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dlg_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dlg_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dlg_portrait_rect.visible = false
	# 底部渐变淡出 shader
	var fade_shader := load("res://shaders/portrait_bottom_fade.gdshader")
	if fade_shader:
		var mat := ShaderMaterial.new()
		mat.shader = fade_shader
		mat.set_shader_parameter("fade_start", 0.55)
		mat.set_shader_parameter("fade_end", 0.92)
		_dlg_portrait_rect.material = mat
	_panel.add_child(_dlg_portrait_rect)

	# ── 异议特效层 ──
	_objection_layer = Control.new()
	_objection_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_objection_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objection_layer.visible = false
	add_child(_objection_layer)

	# 初始隐藏交互元素
	_set_browsing_visible(false)


# ═══════════════════════════════════════════════════
#  状态机
# ═══════════════════════════════════════════════════

func _enter_state(new_state: int) -> void:
	_state = new_state
	match _state:
		State.TITLE_ANIM:
			_play_title_anim()
		State.INTRO:
			_play_intro()
		State.TESTIMONY_INTRO:
			_play_testimony_intro()
		State.BROWSING:
			_enter_browsing()
		State.PRESSING:
			pass  # 由 _on_press_clicked 驱动
		State.EVIDENCE_OPEN:
			_open_evidence()
		State.BREAK_ANIM:
			_play_break_anim()
		State.FAIL_ANIM:
			_play_fail_anim()
		State.VICTORY:
			_play_victory()
		State.DEFEAT:
			_play_defeat()


# ═══════════════════════════════════════════════════
#  "开始对峙" 大字特效
# ═══════════════════════════════════════════════════

func _play_title_anim() -> void:
	_set_browsing_visible(false)

	# 全屏白闪
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(flash)

	# 居中大字
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(center)

	var title := Label.new()
	title.text = "开 始 对 峙"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 6)
	title.scale = Vector2(0.4, 0.4)
	title.pivot_offset = title.size * 0.5
	title.modulate.a = 0.0
	center.add_child(title)

	# 动画序列：白闪 → 文字缩放进入 → 停留 → 淡出
	var tw := create_tween()
	# 白闪
	tw.tween_property(flash, "color:a", 0.85, 0.08)
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	# 文字进入（与白闪同步）
	tw.parallel().tween_property(title, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(title, "scale", Vector2(1.1, 1.1), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# 回弹
	tw.tween_property(title, "scale", Vector2(1.0, 1.0), 0.1)
	# 停留
	tw.tween_interval(1.2)
	# 淡出
	tw.tween_property(title, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		flash.queue_free()
		center.queue_free()
		_enter_state(State.INTRO)
	)


# ═══════════════════════════════════════════════════
#  开场对话
# ═══════════════════════════════════════════════════

func _play_intro() -> void:
	_set_browsing_visible(false)
	var intro: Array = _confrontation_data.get("intro_dialogue", [])
	if intro.is_empty():
		_enter_state(State.TESTIMONY_INTRO)
		return
	_dialogue_queue = intro
	_dialogue_idx = 0
	_show_dialogue_queue(func(): _enter_state(State.TESTIMONY_INTRO))


# ═══════════════════════════════════════════════════
#  证词标题展示
# ═══════════════════════════════════════════════════

func _play_testimony_intro() -> void:
	if _current_testimony_idx >= _testimonies.size():
		_enter_state(State.VICTORY)
		return
	_set_browsing_visible(false)
	_hide_dialogue()

	var testimony: Dictionary = _testimonies[_current_testimony_idx]
	_statements = testimony.get("statements", []).duplicate(true)
	_current_stmt_idx = 0
	_pressed_stmts.clear()

	_testimony_title_label.text = testimony.get("title", "证词")

	# ── 前言对话（preamble）：里正/主角宣布证人上前 ──
	var preamble: Array = testimony.get("preamble", [])
	if not preamble.is_empty():
		_dialogue_queue = preamble
		_dialogue_idx = 0
		_show_dialogue_queue(func(): _show_testimony_title_card(testimony))
	else:
		_show_testimony_title_card(testimony)


func _show_testimony_title_card(testimony: Dictionary) -> void:
	_hide_dialogue()
	# 证言开始时切换BGM
	var bgm_player := get_node_or_null("/root/BgmPlayer")
	if bgm_player and bgm_player.has_method("play"):
		bgm_player.play("ferry_confrontation")
	# 显示证人立绘
	_portrait_state = PortraitState.NORMAL
	_update_portrait()

	# ── 独立标题特效：淡入 → 停留 → 淡出 ──
	var title_label := Label.new()
	title_label.text = "─ " + testimony.get("title", "") + " ─"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_CENTER)
	title_label.offset_left = -400
	title_label.offset_right = 400
	title_label.offset_top = -30
	title_label.offset_bottom = 30
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.53))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title_label.add_theme_constant_override("outline_size", 4)
	title_label.modulate.a = 0.0
	_panel.add_child(title_label)

	# 动画：淡入 0.4s → 停留 1.5s → 淡出 0.4s
	var tw := create_tween()
	tw.tween_property(title_label, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.5)
	tw.tween_property(title_label, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		title_label.queue_free()
		_play_testimony_readthrough()
	)


func _play_testimony_readthrough() -> void:
	# 逐句朗读证词，然后进入浏览模式
	_dialogue_idx = 0
	_readthrough_next()


func _readthrough_next() -> void:
	if _dialogue_idx >= _statements.size():
		_hide_dialogue()
		# 朗读结束后的提示（让玩家知道该操作了）
		var testimony: Dictionary = _testimonies[_current_testimony_idx]
		var end_hint: Array = testimony.get("readthrough_end_hint", [
			{"speaker": "凌瑶", "text": "（低声）证言说完了。哪句有破绽——你来判断。", "emotion": "determined"}
		])
		_dialogue_queue = end_hint
		_dialogue_idx = 0
		_show_dialogue_queue(func(): _enter_state(State.BROWSING))
		return
	var stmt: Dictionary = _statements[_dialogue_idx]
	var speaker: String = stmt.get("speaker", "")
	if speaker == "你":
		speaker = "陆昭"
	_dialogue_speaker.text = speaker
	_dialogue_box.visible = true

	# 更新对话头像
	_update_dialogue_portrait(speaker, "")

	# 打字机效果
	var text: String = "「" + stmt.get("text", "") + "」"
	_typewriter_playing = true
	_typewriter.play(_dialogue_text, text)
	if _typewriter.is_playing():
		await _typewriter.finished
	_typewriter_playing = false

	_set_waiting_for_click(func():
		_dialogue_idx += 1
		_readthrough_next()
	)


# ═══════════════════════════════════════════════════
#  浏览模式
# ═══════════════════════════════════════════════════

func _enter_browsing() -> void:
	_click_callback = Callable()  # 确保无残留回调吞掉点击
	_hide_dialogue()
	_evidence_panel.visible = false
	# 确保证人立绘可见
	_portrait_state = PortraitState.NORMAL
	_update_portrait()
	_set_browsing_visible(true)
	_refresh_stmt_display()


func _set_browsing_visible(vis: bool) -> void:
	var stmt_area = _panel.get_node_or_null("StmtArea")
	if stmt_area:
		stmt_area.visible = vis
	_action_bar.visible = vis


func _navigate_stmt(delta: int) -> void:
	if _state != State.BROWSING:
		return
	_current_stmt_idx = clampi(_current_stmt_idx + delta, 0, _statements.size() - 1)
	_refresh_stmt_display()


func _refresh_stmt_display() -> void:
	if _statements.is_empty():
		return
	var stmt: Dictionary = _statements[_current_stmt_idx]
	var speaker: String = stmt.get("speaker", "")
	_stmt_text_label.text = "[center]「" + stmt.get("text", "") + "」[/center]"
	_stmt_counter_label.text = "%d / %d" % [_current_stmt_idx + 1, _statements.size()]
	_testimony_title_label.text = _testimonies[_current_testimony_idx].get("title", "")

	# 更新导航按钮
	_prev_btn.disabled = (_current_stmt_idx <= 0)
	_prev_btn.modulate.a = 0.3 if _prev_btn.disabled else 1.0
	_next_btn.disabled = (_current_stmt_idx >= _statements.size() - 1)
	_next_btn.modulate.a = 0.3 if _next_btn.disabled else 1.0

	# 更新圆点指示器
	_refresh_dots()


func _refresh_dots() -> void:
	for c in _dot_container.get_children():
		c.queue_free()

	for i in range(_statements.size()):
		var dot := Label.new()
		var is_current: bool = (i == _current_stmt_idx)
		var stmt_data: Dictionary = _statements[i]
		var stmt_id: String = stmt_data.get("id", "")
		var is_new: bool = stmt_id.contains("b") or stmt_id.contains("_added")
		# 有 press_adds 标记的追加句
		if is_current:
			dot.text = "◉"
			dot.add_theme_font_size_override("font_size", 18)
			dot.add_theme_color_override("font_color", CLR_GOLD_BRIGHT)
		elif is_new:
			dot.text = "●"
			dot.add_theme_font_size_override("font_size", 14)
			dot.add_theme_color_override("font_color", CLR_NEW_DOT)
		else:
			dot.text = "●"
			dot.add_theme_font_size_override("font_size", 14)
			dot.add_theme_color_override("font_color", CLR_DIM)
		_dot_container.add_child(dot)


# ═══════════════════════════════════════════════════
#  威慑
# ═══════════════════════════════════════════════════

func _on_press_clicked() -> void:
	if _state != State.BROWSING:
		return
	_state = State.PRESSING
	_set_browsing_visible(false)

	var stmt: Dictionary = _statements[_current_stmt_idx]
	var stmt_id: String = stmt.get("id", "")
	var press_dlg: Array = stmt.get("press", [])

	if press_dlg.is_empty():
		# 无特殊威慑对话，给个通用反应
		press_dlg = [
			{"speaker": "你", "text": "把这件事再说详细一点。"},
			{"speaker": stmt.get("speaker", "阿贵"), "text": "就……就是我说的那样。没什么好补充的。"}
		]

	_dialogue_queue = press_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func(): _after_press(stmt_id, stmt))


func _after_press(stmt_id: String, stmt: Dictionary) -> void:
	_pressed_stmts[stmt_id] = true

	# 检查是否有追加证词
	if stmt.has("press_adds") and not _pressed_stmts.has(stmt_id + "_added"):
		_pressed_stmts[stmt_id + "_added"] = true
		var adds: Dictionary = stmt.get("press_adds", {})
		var after_id: String = adds.get("after", stmt_id)
		var new_stmt: Dictionary = adds.get("statement", {})
		if not new_stmt.is_empty():
			_insert_statement(after_id, new_stmt)
			# 短暂提示追加了新证词
			_dialogue_queue = [
				{"speaker": "", "text": "[center][color=#66ddff]— 证词发生了变化 —[/color][/center]"}
			]
			_dialogue_idx = 0
			_show_dialogue_queue(func(): _enter_state(State.BROWSING))
			return

	_enter_state(State.BROWSING)


func _insert_statement(after_id: String, new_stmt: Dictionary) -> void:
	# 找到 after_id 的位置，插入其后
	var insert_idx: int = -1
	for i in range(_statements.size()):
		if _statements[i].get("id", "") == after_id:
			insert_idx = i + 1
			break
	if insert_idx == -1:
		insert_idx = _statements.size()
	_statements.insert(insert_idx, new_stmt)
	# 如果当前游标在插入点之后，需要调整
	if _current_stmt_idx >= insert_idx:
		_current_stmt_idx += 1
	# 导航到新插入的句子
	_current_stmt_idx = insert_idx


# ═══════════════════════════════════════════════════
#  举证
# ═══════════════════════════════════════════════════

func _on_present_clicked() -> void:
	print("[DEBUG] 举证按钮被点击, 当前状态=", _state, " BROWSING=", State.BROWSING)
	if _state != State.BROWSING:
		print("[DEBUG] 状态不是BROWSING, 退出")
		return
	print("[DEBUG] 进入EVIDENCE_OPEN, 证据数量=", GameManager.collected_evidence.size())
	_enter_state(State.EVIDENCE_OPEN)


var _evidence_info_label: RichTextLabel = null  # 悬浮信息区
var _evidence_info_panel: PanelContainer = null  # 悬浮信息面板（固定在滚动区外）
var _evidence_btn_row: HBoxContainer = null  # 按钮行（固定在滚动区外）
var _evidence_ev_vbox: VBoxContainer = null  # 证据面板主布局
var _evidence_tab_content: HFlowContainer = null  # 当前标签页内容

func _open_evidence() -> void:
	# 打开证物栏时保持当前证人/嫌疑人立绘可见。
	_portrait_state = PortraitState.NORMAL
	_update_portrait()
	_set_browsing_visible(false)
	_evidence_panel.visible = true
	_selected_evidence_id = ""
	_refresh_evidence_list()


func _on_evidence_cancel() -> void:
	_evidence_panel.visible = false
	_selected_evidence_id = ""
	_enter_state(State.BROWSING)


func _on_evidence_clicked(eid: String) -> void:
	if _state != State.EVIDENCE_OPEN:
		return
	_selected_evidence_id = eid
	_refresh_evidence_list()


func _on_submit_evidence() -> void:
	if _state != State.EVIDENCE_OPEN or _selected_evidence_id == "":
		return
	_evidence_panel.visible = false
	_judge_evidence(_selected_evidence_id)


func _refresh_evidence_list() -> void:
	for c in _evidence_container.get_children():
		c.queue_free()

	# 只显示证物（不显示线索标签页），过滤隐藏条目
	var evidences: Array = []
	for eid in GameManager.collected_evidence:
		var data: Dictionary = GameManager.evidence_data.get(eid, {})
		if not data.is_empty() and data.get("type", "") == "evidence" and not data.get("hidden", false):
			evidences.append(eid)

	for eid in evidences:
		_evidence_container.add_child(_make_evidence_sheet(eid, "evidence"))

	# ── 更新固定按钮行 ──
	for c in _evidence_btn_row.get_children():
		c.queue_free()

	if _selected_evidence_id != "":
		var submit_btn := Button.new()
		submit_btn.text = "⚡ 呈堂"
		submit_btn.custom_minimum_size = Vector2(150, 44)
		submit_btn.add_theme_font_size_override("font_size", 20)
		submit_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
		var sub_style := StyleBoxFlat.new()
		sub_style.bg_color = Color(0.14, 0.09, 0.04, 0.92)
		sub_style.border_color = Color(0.95, 0.7, 0.2, 0.9)
		sub_style.set_border_width_all(2)
		sub_style.set_corner_radius_all(6)
		sub_style.content_margin_top = 8
		sub_style.content_margin_bottom = 8
		submit_btn.add_theme_stylebox_override("normal", sub_style)
		submit_btn.pressed.connect(_on_submit_evidence)
		_evidence_btn_row.add_child(submit_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "✕ 收起"
	cancel_btn.custom_minimum_size = Vector2(120, 44)
	cancel_btn.add_theme_font_size_override("font_size", 17)
	cancel_btn.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	cancel_btn.add_theme_color_override("font_hover_color", Color(0.9, 0.85, 0.7))
	cancel_btn.flat = true
	cancel_btn.pressed.connect(_on_evidence_cancel)
	_evidence_btn_row.add_child(cancel_btn)

	# ── 重置悬浮信息显示 ──
	_evidence_info_label.text = "[center][color=#888870]— 将鼠标悬浮在证物上查看详情 —[/color][/center]"


func _make_evidence_sheet(eid: String, category: String) -> Button:
	var data: Dictionary = GameManager.evidence_data.get(eid, {})
	var is_sel: bool = (eid == _selected_evidence_id)
	var ename: String = data.get("name", eid)
	var edesc: String = data.get("description", "")

	var sheet := Button.new()
	sheet.custom_minimum_size = Vector2(100, 110)
	sheet.clip_text = false
	# 使用透明文字（内容通过子节点绘制）
	sheet.text = ""

	# normal 样式
	var s_style := StyleBoxFlat.new()
	if is_sel:
		s_style.bg_color = Color(0.16, 0.11, 0.04, 0.97)
		s_style.border_color = Color(1.0, 0.75, 0.2, 1.0)
		s_style.set_border_width_all(2)
	else:
		s_style.bg_color = Color(0.06, 0.05, 0.03, 0.9)
		s_style.border_color = Color(0.55, 0.4, 0.15, 0.6)
		s_style.set_border_width_all(1)
	s_style.set_corner_radius_all(6)
	s_style.content_margin_left = 6
	s_style.content_margin_right = 6
	s_style.content_margin_top = 6
	s_style.content_margin_bottom = 6
	sheet.add_theme_stylebox_override("normal", s_style)

	# hover 样式
	var hover_style := s_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.12, 0.09, 0.04, 0.97)
	hover_style.border_color = Color(0.85, 0.6, 0.2, 0.9)
	hover_style.set_border_width_all(2)
	sheet.add_theme_stylebox_override("hover", hover_style)

	# pressed 样式
	var pressed_style := hover_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.18, 0.12, 0.05, 0.98)
	sheet.add_theme_stylebox_override("pressed", pressed_style)

	# ── 内部布局：图标 + 名称 ──
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(vbox)

	# 图标
	var icon_path := "res://assets/ai_processed/objects/evidence_icons/%s.png" % eid
	var has_icon := false
	if ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path)
		if tex:
			has_icon = true
			var img := TextureRect.new()
			img.texture = tex
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.custom_minimum_size = Vector2(64, 64)
			img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(img)
	if not has_icon:
		var placeholder := Label.new()
		placeholder.text = "📜"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.add_theme_font_size_override("font_size", 36)
		placeholder.custom_minimum_size = Vector2(64, 64)
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(placeholder)

	# 名称
	var name_lbl := Label.new()
	name_lbl.text = ename
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_sel:
		name_lbl.add_theme_color_override("font_color", CLR_GOLD_BRIGHT)
	else:
		name_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	vbox.add_child(name_lbl)

	# 选中标记
	if is_sel:
		var sel_lbl := Label.new()
		sel_lbl.text = "▸ 选中"
		sel_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sel_lbl.add_theme_font_size_override("font_size", 11)
		sel_lbl.add_theme_color_override("font_color", CLR_GOLD)
		sel_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(sel_lbl)

	# 信号连接
	var ev_id: String = eid
	var ev_desc: String = edesc
	var ev_name: String = ename
	var ev_cat: String = category
	sheet.pressed.connect(func(): _on_evidence_clicked(ev_id))
	sheet.mouse_entered.connect(func(): _on_sheet_hover(ev_name, ev_desc, ev_cat))
	sheet.mouse_exited.connect(func(): _on_sheet_hover_exit())

	return sheet


func _on_sheet_hover(ename: String, edesc: String, category: String) -> void:
	if _evidence_info_label == null:
		return
	var color_tag: String = "#ffcc55" if category == "evidence" else "#77ccee"
	var icon: String = "📜" if category == "evidence" else "🔍"
	_evidence_info_label.text = "[b][color=" + color_tag + "]" + icon + " " + ename + "[/color][/b]\n" + edesc


func _on_sheet_hover_exit() -> void:
	if _evidence_info_label == null:
		return
	_evidence_info_label.text = "[center][color=#888870]— 将鼠标悬浮在证物上查看详情 —[/color][/center]"


# ═══════════════════════════════════════════════════
#  判定
# ═══════════════════════════════════════════════════

func _judge_evidence(eid: String) -> void:
	var stmt: Dictionary = _statements[_current_stmt_idx]
	var is_contradiction: bool = stmt.get("is_contradiction", false)
	var counter: String = stmt.get("counter_evidence", "")
	var alt: Array = stmt.get("alt_evidence", [])

	if is_contradiction and (eid == counter or alt.has(eid)):
		_enter_state(State.BREAK_ANIM)
	else:
		_enter_state(State.FAIL_ANIM)


# ═══════════════════════════════════════════════════
#  击破动画
# ═══════════════════════════════════════════════════

func _play_break_anim() -> void:
	_set_browsing_visible(false)
	_evidence_panel.visible = false

	await _play_objection_fx()

	# 击破时切换BGM（数据驱动，默认 "pursuit"）
	var break_bgm: String = _confrontation_data.get("bgm_break", "pursuit")
	if break_bgm != "":
		var bgm_player := get_node_or_null("/root/BgmPlayer")
		if bgm_player and bgm_player.has_method("play"):
			bgm_player.play(break_bgm)

	# 击破闪屏效果
	_flash_screen_white()

	# 立绘动摇
	_portrait_state = PortraitState.SHAKEN
	_update_portrait()
	_shake_portrait()

	# 播放击破对话
	var stmt: Dictionary = _statements[_current_stmt_idx]
	var break_dlg: Array = stmt.get("break_dialogue", [])
	_dialogue_queue = break_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func(): _after_break_dialogue())


func _after_break_dialogue() -> void:
	# 检查当前证词是否有过渡对话（transition_dialogue）
	var testimony: Dictionary = _testimonies[_current_testimony_idx]
	var transition_dlg: Array = testimony.get("transition_dialogue", [])
	if not transition_dlg.is_empty():
		# 证人退场效果：立绘淡出
		_portrait_state = PortraitState.SHAKEN
		_update_portrait()
		var fade_tw := create_tween()
		fade_tw.tween_property(_portrait_rect, "modulate:a", 0.0, 0.3)
		fade_tw.tween_callback(func():
			_portrait_rect.visible = false
			# 播放过渡对话
			_dialogue_queue = transition_dlg
			_dialogue_idx = 0
			_show_dialogue_queue(func(): _advance_to_next_testimony())
		)
	else:
		_advance_to_next_testimony()


func _advance_to_next_testimony() -> void:
	_current_testimony_idx += 1
	if _current_testimony_idx >= _testimonies.size():
		_enter_state(State.VICTORY)
	else:
		_portrait_state = PortraitState.NORMAL
		_update_portrait()
		# 进入新证词轮时切换BGM
		var bgm_player := get_node_or_null("/root/BgmPlayer")
		if bgm_player and bgm_player.has_method("play"):
			if _current_testimony_idx == _testimonies.size() - 1:
				# 最后一轮：切换到紧张BGM
				var final_bgm: String = _confrontation_data.get("bgm_final_round", "confrontation_final")
				bgm_player.play(final_bgm)
			else:
				# 非最后轮：从 pursuit 恢复到对峙基础BGM
				var base_bgm: String = _confrontation_data.get("bgm", "accuse")
				bgm_player.play(base_bgm)
		_enter_state(State.TESTIMONY_INTRO)


# ═══════════════════════════════════════════════════
#  失败动画
# ═══════════════════════════════════════════════════

func _play_fail_anim() -> void:
	_mistakes += 1
	_confidence = max(0, _confidence - 1)
	_update_confidence_display()
	_set_browsing_visible(false)

	await _play_red_flash()

	# 优先使用当前陈述的角色化错误反馈（wrong_reactions）
	var stmt: Dictionary = _statements[_current_stmt_idx]
	var wrong_reactions: Dictionary = stmt.get("wrong_reactions", {})
	var fail_dlg: Array = []
	if not wrong_reactions.is_empty() and _selected_evidence_id != "":
		if wrong_reactions.has(_selected_evidence_id):
			fail_dlg = wrong_reactions[_selected_evidence_id]
		elif wrong_reactions.has("_default"):
			fail_dlg = wrong_reactions["_default"]
	# 回退到证词级别的通用 fail_dialogue
	if fail_dlg.is_empty():
		var testimony: Dictionary = _testimonies[_current_testimony_idx]
		fail_dlg = testimony.get("fail_dialogue", [])
	_dialogue_queue = fail_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func():
		if _confidence <= 0:
			_enter_state(State.DEFEAT)
		else:
			_enter_state(State.BROWSING)
	)


# ═══════════════════════════════════════════════════
#  胜利 / 失败
# ═══════════════════════════════════════════════════

func _play_victory() -> void:
	_set_browsing_visible(false)
	_portrait_state = PortraitState.COLLAPSED
	_update_portrait()

	var victory_dlg: Array = _confrontation_data.get("victory_dialogue", [])
	_dialogue_queue = victory_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func(): _play_epilogue_text())


func _play_epilogue_text() -> void:
	# 黑屏收尾文字（逐段显示）
	var epilogue_lines: Array = _confrontation_data.get("epilogue_text", [])
	if epilogue_lines.is_empty():
		confrontation_finished.emit("victory", _mistakes)
		return

	_hide_dialogue()
	# 隐藏所有UI元素，只留黑屏
	_panel.visible = false

	var epilogue_layer := Control.new()
	epilogue_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(epilogue_layer)

	# 纯黑背景
	var black_bg := ColorRect.new()
	black_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_bg.color = Color(0.02, 0.015, 0.01, 1.0)
	epilogue_layer.add_child(black_bg)

	# 居中文字区
	var text_label := RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.anchor_left = 0.1
	text_label.anchor_right = 0.9
	text_label.anchor_top = 0.2
	text_label.anchor_bottom = 0.8
	text_label.offset_left = 0
	text_label.offset_right = 0
	text_label.offset_top = 0
	text_label.offset_bottom = 0
	text_label.add_theme_font_size_override("normal_font_size", 22)
	text_label.add_theme_color_override("default_color", Color(0.85, 0.8, 0.65))
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	epilogue_layer.add_child(text_label)

	# 提示
	var hint_label := Label.new()
	hint_label.text = "▼ 点击继续"
	hint_label.anchor_left = 1.0
	hint_label.anchor_right = 1.0
	hint_label.anchor_top = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_left = -150
	hint_label.offset_top = -40
	hint_label.offset_right = -20
	hint_label.offset_bottom = -10
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.42, 0.6))
	epilogue_layer.add_child(hint_label)

	# 逐段播放epilogue文字
	_play_epilogue_lines(epilogue_lines, 0, text_label, epilogue_layer)


func _play_epilogue_lines(lines: Array, idx: int, label: RichTextLabel, layer: Control) -> void:
	if idx >= lines.size():
		# 全部播完，发出结束信号
		await get_tree().create_timer(1.0).timeout
		confrontation_finished.emit("victory", _mistakes)
		return

	var line: String = lines[idx]
	label.text = ""
	label.modulate.a = 0.0

	# 淡入
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.5)
	await tw.finished

	# 打字机效果
	_typewriter_playing = true
	_typewriter.play(label, "[center]" + line + "[/center]")
	if _typewriter.is_playing():
		await _typewriter.finished
	_typewriter_playing = false

	# 等待点击
	_set_waiting_for_click(func():
		# 淡出
		var tw_out := create_tween()
		tw_out.tween_property(label, "modulate:a", 0.0, 0.3)
		tw_out.tween_callback(func():
			_play_epilogue_lines(lines, idx + 1, label, layer)
		)
	)


func _play_defeat() -> void:
	_set_browsing_visible(false)
	var defeat_dlg: Array = _confrontation_data.get("defeat_dialogue", [])
	_dialogue_queue = defeat_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func():
		confrontation_finished.emit("defeat", _mistakes)
	)


# ═══════════════════════════════════════════════════
#  对话播放系统
# ═══════════════════════════════════════════════════

func _show_dialogue_queue(on_done: Callable) -> void:
	_show_next_dialogue_line(on_done)


func _hide_dialogue() -> void:
	_dialogue_box.visible = false
	if _dlg_portrait_rect:
		_dlg_portrait_rect.visible = false


func _show_next_dialogue_line(on_done: Callable) -> void:
	if _dialogue_idx >= _dialogue_queue.size():
		_hide_dialogue()
		on_done.call()
		return
	var line = _dialogue_queue[_dialogue_idx]
	var speaker: String = ""
	var text: String = ""
	var emotion: String = ""
	if line is Dictionary:
		speaker = str(line.get("speaker", ""))
		text = str(line.get("text", ""))
		emotion = str(line.get("emotion", ""))
	else:
		text = str(line)

	if speaker == "你":
		speaker = "陆昭"

	_dialogue_speaker.text = speaker
	_dialogue_box.visible = true

	# 更新对话头像
	_update_dialogue_portrait(speaker, emotion)

	# 打字机效果
	_typewriter_playing = true
	_typewriter.play(_dialogue_text, text)
	if _typewriter.is_playing():
		await _typewriter.finished
	_typewriter_playing = false

	_set_waiting_for_click(func():
		_dialogue_idx += 1
		_show_next_dialogue_line(on_done)
	)


# ═══════════════════════════════════════════════════
#  点击事件
# ═══════════════════════════════════════════════════

func _set_waiting_for_click(cb: Callable) -> void:
	_click_callback = cb


func _input(event: InputEvent) -> void:
	# 浏览/举证状态下不拦截鼠标，确保按钮可点击
	if _state == State.BROWSING or _state == State.EVIDENCE_OPEN:
		_click_callback = Callable()
		return
	var trigger: bool = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		trigger = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		trigger = true
	if not trigger:
		return
	# 打字机正在播放 → 跳过当前文字动画
	if _typewriter_playing and _typewriter != null:
		_typewriter.skip()
		get_viewport().set_input_as_handled()
		return
	if not _click_callback.is_valid():
		return
	get_viewport().set_input_as_handled()
	var cb := _click_callback
	_click_callback = Callable()
	cb.call()


# ═══════════════════════════════════════════════════
#  信心值
# ═══════════════════════════════════════════════════

func _update_confidence_display() -> void:
	var hearts := ""
	for i in range(_max_confidence):
		if i < _confidence:
			hearts += "❤ "
		else:
			hearts += "♡ "
	_confidence_label.text = "信心 " + hearts


# ═══════════════════════════════════════════════════
#  立绘
# ═══════════════════════════════════════════════════

func _update_portrait() -> void:
	# 优先使用当前证词轮次指定的 witness，回退到全局 suspect
	var witness_id: String = ""
	if _current_testimony_idx >= 0 and _current_testimony_idx < _testimonies.size():
		witness_id = _testimonies[_current_testimony_idx].get("witness", "")
	if witness_id == "":
		witness_id = _confrontation_data.get("suspect", "")
	if witness_id == "":
		return
	var portrait_path: String = AssetResolver.get_portrait(witness_id, GameManager.npcs_data)
	if portrait_path == "":
		var npc_data: Dictionary = GameManager.get_npc_data(witness_id)
		portrait_path = npc_data.get("portrait", "")
	if portrait_path == "":
		return
	var confront_base: String = portrait_path.replace(".png", "_confrontation.png")
	var mapped_base := AssetResolver.resolve_portrait_expression(portrait_path, "confrontation")
	var path := mapped_base if mapped_base != "" else (confront_base if ResourceLoader.exists(confront_base) else portrait_path)
	match _portrait_state:
		PortraitState.SHAKEN:
			var mapped_shaken := AssetResolver.resolve_portrait_expression(portrait_path, "confrontation_shaken")
			if mapped_shaken != "":
				path = mapped_shaken
			else:
				var alt := confront_base.replace(".png", "_shaken.png")
				if ResourceLoader.exists(alt):
					path = alt
				else:
					alt = portrait_path.replace(".png", "_shaken.png")
					if ResourceLoader.exists(alt):
						path = alt
		PortraitState.COLLAPSED:
			var mapped_collapsed := AssetResolver.resolve_portrait_expression(portrait_path, "confrontation_collapsed")
			if mapped_collapsed != "":
				path = mapped_collapsed
			else:
				var alt := confront_base.replace(".png", "_collapsed.png")
				if ResourceLoader.exists(alt):
					path = alt
				else:
					alt = portrait_path.replace(".png", "_collapsed.png")
					if ResourceLoader.exists(alt):
						path = alt
	if ResourceLoader.exists(path):
		_portrait_rect.texture = load(path)
		_portrait_rect.visible = true
	# 视觉效果
	_portrait_rect.rotation = 0.0
	_portrait_rect.modulate = Color(1, 1, 1, 1)
	match _portrait_state:
		PortraitState.SHAKEN:
			_portrait_rect.modulate = Color(1.0, 0.95, 0.85, 1.0)
		PortraitState.COLLAPSED:
			_portrait_rect.rotation = -0.04
			_portrait_rect.modulate = Color(0.7, 0.7, 0.7, 0.85)


# ═══════════════════════════════════════════════════
#  特效
# ═══════════════════════════════════════════════════

func _play_objection_fx() -> void:
	_objection_layer.visible = true
	_objection_layer.mouse_filter = Control.MOUSE_FILTER_STOP

	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objection_layer.add_child(flash)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objection_layer.add_child(center)

	var label := Label.new()
	label.text = "异  议！"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 6)
	label.scale = Vector2(0.3, 0.3)
	label.modulate.a = 0.0
	center.add_child(label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "color:a", 0.9, 0.06)
	tw.tween_property(label, "modulate:a", 1.0, 0.06)
	tw.tween_property(label, "scale", Vector2(1.15, 1.15), 0.12)
	tw.chain()
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.08)
	tw.tween_interval(0.6)
	tw.set_parallel(true)
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_property(label, "modulate:a", 0.0, 0.3)
	tw.chain()
	tw.tween_callback(func():
		_objection_layer.visible = false
		_objection_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for c in _objection_layer.get_children():
			c.queue_free()
	)
	await tw.finished


func _play_red_flash() -> void:
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.8, 0.1, 0.05, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	move_child(flash, get_child_count() - 1)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.45, 0.08)
	tw.tween_property(flash, "color:a", 0.0, 0.25)
	tw.tween_callback(flash.queue_free)
	await tw.finished


func _shake_portrait() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	var orig_x := _portrait_rect.position.x
	for i in range(8):
		var offset_x := 10.0 if i % 2 == 0 else -10.0
		_shake_tween.tween_property(_portrait_rect, "position:x", orig_x + offset_x, 0.035)
	_shake_tween.tween_property(_portrait_rect, "position:x", orig_x, 0.05)


func _flash_screen_white() -> void:
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0.8)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(flash.queue_free)


# ═══════════════════════════════════════════════════
#  对话头像（陆昭/凌瑶）
# ═══════════════════════════════════════════════════

func _update_dialogue_portrait(speaker: String, emotion: String) -> void:
	if _dlg_portrait_rect == null:
		return
	var portrait_path: String = ""
	if speaker == "陆昭" or speaker == "你":
		# 对峙中陆昭默认表情为 serious；不再隐藏中央 NPC 立绘，保证举证/击破时目标仍在场。
		var emo: String = emotion if emotion != "" and emotion != "normal" else "serious"
		portrait_path = _resolve_speaker_portrait("res://assets/cn/portraits/prologue_lu_zhao.png", emo)
	elif speaker == "凌瑶":
		portrait_path = _resolve_speaker_portrait("res://assets/cn/portraits/companion_lingyao.png", emotion)
	elif speaker != "" and emotion != "narration" and emotion != "inner_thought":
		# NPC 说话：尝试显示他们的居中立绘
		_dlg_portrait_rect.visible = false
		var npc_id := _find_npc_id_by_speaker(speaker)
		if npc_id != "":
			var npc_portrait: String = AssetResolver.get_portrait(npc_id, GameManager.npcs_data)
			if npc_portrait != "" and ResourceLoader.exists(npc_portrait):
				_portrait_rect.texture = load(npc_portrait)
				_portrait_rect.visible = true
		return

	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		_dlg_portrait_rect.texture = load(portrait_path)
		_dlg_portrait_rect.visible = true
	else:
		_dlg_portrait_rect.visible = false


func _find_npc_id_by_speaker(speaker_name: String) -> String:
	"""通过显示名查找 NPC ID"""
	# 直接映射常见名字
	var name_map := {
		"钱里正": "li_zheng",
		"阿贵": "agui",
		"老范": "lao_fan",
		"周氏": "zhou_wife",
		"王大爷": "fisherman_wang",
		"沈清月": "shen_qingyue",
	}
	if name_map.has(speaker_name):
		return name_map[speaker_name]
	# 回退：遍历 npcs_data 查找
	for npc_id in GameManager.npcs_data.keys():
		if GameManager.get_npc_display_name(str(npc_id)) == speaker_name:
			return str(npc_id)
	return ""


func _resolve_speaker_portrait(base_path: String, emotion: String) -> String:
	if emotion == "" or emotion == "normal":
		return base_path
	# 尝试直接匹配情绪变体文件
	var variant := base_path.replace(".png", "_%s.png" % emotion)
	if ResourceLoader.exists(variant):
		return variant
	# 映射到近似情绪
	var mapped_emotion: String = ""
	match emotion:
		"accusatory", "piercing", "serious", "firm":
			mapped_emotion = "serious"
		"cold", "stern", "angry":
			mapped_emotion = "cold"
		"thinking", "alert", "ponder":
			mapped_emotion = "worried"
		"determined", "resolute":
			mapped_emotion = "determined"
		"nervous", "panic", "anxious", "uneasy":
			mapped_emotion = "anxious"
		"surprised", "shock", "startled":
			mapped_emotion = "shocked"
		"worried", "concerned", "sad":
			mapped_emotion = "worried"
		"cheerful", "happy", "relief":
			mapped_emotion = "cheerful"
	if mapped_emotion != "":
		variant = base_path.replace(".png", "_%s.png" % mapped_emotion)
		if ResourceLoader.exists(variant):
			return variant
	return base_path
