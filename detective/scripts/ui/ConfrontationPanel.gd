extends Control
## 对峙面板：逆转裁判式交叉询问
##
## 流程：犯人给出一段证词（多句） → 玩家逐句浏览
## 		两个操作：威慑（追问，安全无惩罚） / 举证（出示证据，选错扣信心）
## 		击破矛盾句后进入下一段证词 → 全部击破=胜利

signal confrontation_finished(result: String, mistakes: int)

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")
const TextUtilsScript = preload("res://scripts/core/TextUtils.gd")

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
	PROOF_SUCCESS,      # 强制自证成功后的对话
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
var _hovered_evidence_id: String = ""   # 鼠标悬浮时的证物ID（仅用于详情预览）
var _forced_proof_active: bool = false

# ─── 对话播放 ───
var _dialogue_queue: Array = []
var _dialogue_idx: int = 0
var _click_callback: Callable = Callable()
var _typewriter: Node = null
var _typewriter_playing: bool = false
var _input_locked_until_msec := 0

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
# ─── 证物册分页 ───
const EVIDENCE_PER_PAGE := 18
const EVIDENCE_GRID_COLUMNS := 6
var _evidence_items_cache: Array = []       # 缓存当前可出示证物ID列表
var _selected_evidence_index: int = 0       # 全局选中索引（跨页）
var _evidence_page_index: int = 0           # 当前页
var _evidence_grid: GridContainer = null
var _evidence_detail_icon: TextureRect = null
var _evidence_detail_name: Label = null
var _evidence_detail_desc: RichTextLabel = null
var _evidence_detail_category: Label = null
var _evidence_page_label: Label = null
var _evidence_statement_quote: RichTextLabel = null  # 当前证词引用
var _evidence_cancel_btn: Button = null
var _evidence_hint_label: Label = null
var _dialogue_box: PanelContainer
var _dialogue_speaker: Label
var _dialogue_text: RichTextLabel
var _objection_layer: Control
var _action_bar: HBoxContainer

# ─── 功能开关 ───
## 启用后，对话时镜头会切换：NPC说话=NPC居中；主角/搭档说话=从左侧滑入
const CAMERA_SWITCH_ENABLED := true

# ─── 立绘 ───
enum PortraitState { NORMAL, SHAKEN, COLLAPSED }
const PORTRAIT_SLOT_WIDTH := 560.0
const PORTRAIT_SLOT_TOP := 60.0
const PORTRAIT_SLOT_BOTTOM := 0.0
const PORTRAIT_SLOT_SIDE_INSET := 24.0
const PORTRAIT_SLOT_OFFSCREEN_GAP := 90.0
const DEFAULT_PORTRAIT_CROP_PADDING_RATIO := 0.02
const DEFAULT_PORTRAIT_CROP_MIN_PADDING := 8
const DEFAULT_PORTRAIT_CROP_MIN_HEIGHT_RATIO := 0.78
var _center_portrait_frame := {
	"offset_left": -320.0,
	"offset_top": 60.0,
	"offset_right": 320.0,
	"offset_bottom": 0.0,
	"pivot_x": 320.0,
}
var _portrait_texture_cache: Dictionary = {}
var _portrait_state: int = PortraitState.NORMAL
var _shake_tween: Tween = null

# ─── 主角/搭档立绘（镜头切换） ───
var _protagonist_rect: TextureRect = null   # 陆昭立绘
var _companion_rect: TextureRect = null     # 凌瑶立绘
var _opponent_rect: TextureRect = null      # 右侧对手立绘（辩护方/沈清月等）
var _camera_tween: Tween = null             # 镜头滑动动画
var _current_camera_view: String = "npc"    # "npc" | "protagonist" | "companion" | "opponent" | "clash"
var _protagonist_portrait_data: Dictionary = {}
var _companion_portrait_data: Dictionary = {}
var _opponent_portrait_data: Dictionary = {}

# ─── 对手立绘位（数据驱动，可扩展辩护方角色） ───
var _opponent_speaker_ids := {"shen_qingyue": true}

# ─── 风格常量 ───
const CLR_GOLD := Color(0.96, 0.88, 0.65)
const CLR_GOLD_BRIGHT := Color(1.0, 0.92, 0.55)
const CLR_DIM := Color(0.55, 0.50, 0.42, 0.6)
const CLR_RED := Color(0.85, 0.25, 0.18, 0.9)
const CLR_GREEN := Color(0.3, 0.8, 0.35)
const EVIDENCE_ACQUIRED_LOCK_SECONDS := 2.0

# ─── 威慑语音台词池 ───
## 符合陆昭性格：冷静、简洁、逻辑压迫感强
const PROTAGONIST_PRESS_LINES: Array = [
	"慢着。",
	"把话说清楚。",
	"这件事，没那么简单。",
	"你确定吗？",
	"再说一遍。",
	"细节。我需要细节。",
	"这话，你自己信吗？",
	"有意思。继续。",
	"等一下——我有问题。",
	"你漏了什么。",
]


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
		var parsed: Dictionary = CaseTableLoader.load_case(GameManager.ACTIVE_CASE).get("case", {})
		_confrontation_data = parsed.get(_confront_key, {})
	_testimonies = _confrontation_data.get("testimonies", [])
	_max_confidence = int(_confrontation_data.get("confidence", 3))
	_confidence = _max_confidence
	_current_testimony_idx = 0
	_mistakes = 0
	_portrait_state = PortraitState.NORMAL
	_refresh_center_portrait_frame()
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)
	_forced_proof_active = false
	# intro 阶段用开庭音乐，证言开始时切正式对峙 BGM。
	_play_confrontation_bgm(_confrontation_intro_bgm())
	_build_ui()
	_enter_state(State.TITLE_ANIM)


func _play_confrontation_bgm(bgm_id: String) -> void:
	if bgm_id == "":
		return
	var bgm_player := get_node_or_null("/root/BgmPlayer")
	if bgm_player and bgm_player.has_method("play"):
		bgm_player.play(bgm_id)


func _refresh_center_portrait_frame() -> void:
	if AssetResolver != null and AssetResolver.has_method("get_center_portrait_standard_frame"):
		var resolved = AssetResolver.get_center_portrait_standard_frame()
		if typeof(resolved) == TYPE_DICTIONARY and not resolved.is_empty():
			_center_portrait_frame = resolved.duplicate(true)


func _confrontation_intro_bgm() -> String:
	var configured := str(_confrontation_data.get("bgm_intro", ""))
	if configured != "":
		return configured
	configured = str(_confrontation_data.get("bgm_break", ""))
	return configured if configured != "" else "ferry_inn_investigation"


func _confrontation_testimony_bgm() -> String:
	var configured := str(_confrontation_data.get("bgm", ""))
	return configured if configured != "" else "ferry_confrontation"


func _confrontation_break_bgm() -> String:
	var configured := str(_confrontation_data.get("bgm_break_actual", ""))
	if configured != "":
		return configured
	var legacy_break := str(_confrontation_data.get("bgm_break", ""))
	if legacy_break != "" and legacy_break != _confrontation_intro_bgm():
		return legacy_break
	return _confrontation_testimony_bgm()


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
	_apply_portrait_layout(_portrait_rect, _get_center_portrait_layout(""))
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_portrait_rect)
	# intro 期间不显示立绘，等进入证言阶段再显示
	_portrait_rect.visible = false

	# ── 主角/搭档立绘（镜头切换用，初始在屏幕外） ──
	# 注意：搭档先添加，主角后添加 → 主角始终在搭档前面（z-order）
	if CAMERA_SWITCH_ENABLED:
		# 搭档立绘（初始在屏幕外）
		_companion_rect = TextureRect.new()
		_companion_rect.anchor_left = 0.0
		_companion_rect.anchor_right = 0.0
		_companion_rect.anchor_top = 0.0
		_companion_rect.anchor_bottom = 1.0
		_apply_portrait_layout(_companion_rect, _offscreen_left_portrait_layout())
		_companion_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_companion_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_companion_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_companion_rect.visible = false
		_companion_rect.modulate = Color(1, 1, 1, 0)
		_companion_rect.flip_h = true  # 搭档脸朝右（朝向对话文字）
		_panel.add_child(_companion_rect)

		# 主角立绘（前方，左侧，初始在屏幕外）
		_protagonist_rect = TextureRect.new()
		_protagonist_rect.anchor_left = 0.0
		_protagonist_rect.anchor_right = 0.0
		_protagonist_rect.anchor_top = 0.0
		_protagonist_rect.anchor_bottom = 1.0
		_apply_portrait_layout(_protagonist_rect, _offscreen_left_portrait_layout())
		_protagonist_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_protagonist_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_protagonist_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_protagonist_rect.visible = false
		_protagonist_rect.modulate = Color(1, 1, 1, 0)
		_panel.add_child(_protagonist_rect)

		# 对手立绘（右侧，辩护方/沈清月，初始在屏幕右侧外）
		_opponent_rect = TextureRect.new()
		_opponent_rect.anchor_left = 1.0
		_opponent_rect.anchor_right = 1.0
		_opponent_rect.anchor_top = 0.0
		_opponent_rect.anchor_bottom = 1.0
		_apply_portrait_layout(_opponent_rect, _offscreen_right_portrait_layout())
		_opponent_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_opponent_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_opponent_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_opponent_rect.visible = false
		_opponent_rect.modulate = Color(1, 1, 1, 0)
		_opponent_rect.flip_h = true  # 对手脸朝左（面向中央/对话文字）
		_panel.add_child(_opponent_rect)

	# ── 证词显示区（中下，带导航箭头） ──
	var stmt_area := PanelContainer.new()
	stmt_area.name = "StmtArea"
	stmt_area.anchor_left = 0.06
	stmt_area.anchor_right = 0.94
	stmt_area.anchor_top = 1.0
	stmt_area.anchor_bottom = 1.0
	stmt_area.offset_top = -240
	stmt_area.offset_bottom = -60
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

	# ── 操作按钮栏（底部，始终可见，紧跟证词区） ──
	_action_bar = HBoxContainer.new()
	_action_bar.name = "ActionBar"
	_action_bar.anchor_left = 0.0
	_action_bar.anchor_right = 1.0
	_action_bar.anchor_top = 1.0
	_action_bar.anchor_bottom = 1.0
	_action_bar.offset_top = -55
	_action_bar.offset_bottom = -10
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

	# ════════════════════════════════════════════
	#  证物册弹窗（居中，默认隐藏）
	# ════════════════════════════════════════════
	_evidence_panel = PanelContainer.new()
	_evidence_panel.set_anchors_preset(Control.PRESET_CENTER)
	_evidence_panel.offset_left = -480
	_evidence_panel.offset_top = -360
	_evidence_panel.offset_right = 480
	_evidence_panel.offset_bottom = 360
	_evidence_panel.visible = false
	var ev_style := StyleBoxFlat.new()
	ev_style.bg_color = Color(0.05, 0.04, 0.025, 0.98)
	ev_style.border_color = Color(0.65, 0.50, 0.22, 0.85)
	ev_style.set_border_width_all(3)
	ev_style.set_corner_radius_all(8)
	ev_style.content_margin_left = 24
	ev_style.content_margin_right = 24
	ev_style.content_margin_top = 18
	ev_style.content_margin_bottom = 18
	_evidence_panel.add_theme_stylebox_override("panel", ev_style)
	_panel.add_child(_evidence_panel)

	var ev_main_vbox := VBoxContainer.new()
	ev_main_vbox.add_theme_constant_override("separation", 10)
	_evidence_panel.add_child(ev_main_vbox)

	# ── 标题行 ──
	var ev_title_row := HBoxContainer.new()
	ev_title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ev_main_vbox.add_child(ev_title_row)

	var ev_title := Label.new()
	ev_title.text = "呈 堂 证 供"
	ev_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev_title.add_theme_font_size_override("font_size", 22)
	ev_title.add_theme_color_override("font_color", CLR_GOLD)
	ev_title_row.add_child(ev_title)

	# ── 当前证词引用 ──
	_evidence_statement_quote = RichTextLabel.new()
	_evidence_statement_quote.bbcode_enabled = true
	_evidence_statement_quote.fit_content = true
	_evidence_statement_quote.scroll_active = false
	_evidence_statement_quote.custom_minimum_size = Vector2(0, 36)
	_evidence_statement_quote.add_theme_font_size_override("normal_font_size", 15)
	_evidence_statement_quote.add_theme_color_override("default_color", Color(0.85, 0.80, 0.65))
	_evidence_statement_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev_main_vbox.add_child(_evidence_statement_quote)

	# ── 分隔线 ──
	var sep1 := HSeparator.new()
	sep1.add_theme_stylebox_override("separator", _make_line_style(Color(0.5, 0.4, 0.18, 0.5)))
	ev_main_vbox.add_child(sep1)

	# ── 中间主体：左侧详情 + 右侧网格 ──
	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 18)
	ev_main_vbox.add_child(body_hbox)

	# ── 左侧：证物详情 ──
	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(240, 0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(0.035, 0.025, 0.015, 0.95)
	detail_style.border_color = Color(0.45, 0.35, 0.15, 0.5)
	detail_style.set_border_width_all(1)
	detail_style.set_corner_radius_all(4)
	detail_style.content_margin_left = 14
	detail_style.content_margin_right = 14
	detail_style.content_margin_top = 12
	detail_style.content_margin_bottom = 12
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	body_hbox.add_child(detail_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_vbox.add_theme_constant_override("separation", 8)
	detail_panel.add_child(detail_vbox)

	_evidence_detail_icon = TextureRect.new()
	_evidence_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_evidence_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_evidence_detail_icon.custom_minimum_size = Vector2(180, 180)
	_evidence_detail_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_evidence_detail_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_evidence_detail_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_evidence_detail_icon.visible = false
	detail_vbox.add_child(_evidence_detail_icon)

	# 无图占位
	var _detail_placeholder := Label.new()
	_detail_placeholder.text = "📜"
	_detail_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_placeholder.add_theme_font_size_override("font_size", 64)
	_detail_placeholder.custom_minimum_size = Vector2(200, 120)
	_detail_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_placeholder.name = "DetailPlaceholder"
	detail_vbox.add_child(_detail_placeholder)

	_evidence_detail_category = Label.new()
	_evidence_detail_category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_evidence_detail_category.add_theme_font_size_override("font_size", 13)
	_evidence_detail_category.add_theme_color_override("font_color", Color(0.6, 0.55, 0.4))
	detail_vbox.add_child(_evidence_detail_category)

	_evidence_detail_name = Label.new()
	_evidence_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_evidence_detail_name.add_theme_font_size_override("font_size", 20)
	_evidence_detail_name.add_theme_color_override("font_color", CLR_GOLD_BRIGHT)
	detail_vbox.add_child(_evidence_detail_name)

	_evidence_detail_desc = RichTextLabel.new()
	_evidence_detail_desc.bbcode_enabled = true
	_evidence_detail_desc.fit_content = true
	_evidence_detail_desc.scroll_active = false
	_evidence_detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_evidence_detail_desc.add_theme_font_size_override("normal_font_size", 15)
	_evidence_detail_desc.add_theme_color_override("default_color", Color(0.82, 0.77, 0.62))
	detail_vbox.add_child(_evidence_detail_desc)

	# ── 右侧：证物网格 + 分页 ──
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 8)
	body_hbox.add_child(right_vbox)

	_evidence_grid = GridContainer.new()
	_evidence_grid.columns = EVIDENCE_GRID_COLUMNS
	_evidence_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_evidence_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_evidence_grid.add_theme_constant_override("h_separation", 10)
	_evidence_grid.add_theme_constant_override("v_separation", 10)
	right_vbox.add_child(_evidence_grid)

	# ── 分页行 ──
	var page_row := HBoxContainer.new()
	page_row.alignment = BoxContainer.ALIGNMENT_CENTER
	page_row.add_theme_constant_override("separation", 20)
	right_vbox.add_child(page_row)

	var prev_page_btn := Button.new()
	prev_page_btn.text = "◀ 上页"
	prev_page_btn.custom_minimum_size = Vector2(100, 34)
	prev_page_btn.add_theme_font_size_override("font_size", 15)
	prev_page_btn.add_theme_color_override("font_color", CLR_GOLD)
	prev_page_btn.flat = true
	prev_page_btn.pressed.connect(func(): _evidence_change_page(-1))
	prev_page_btn.name = "PrevPageBtn"
	page_row.add_child(prev_page_btn)

	_evidence_page_label = Label.new()
	_evidence_page_label.add_theme_font_size_override("font_size", 15)
	_evidence_page_label.add_theme_color_override("font_color", CLR_DIM)
	_evidence_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_evidence_page_label.custom_minimum_size = Vector2(100, 34)
	page_row.add_child(_evidence_page_label)

	var next_page_btn := Button.new()
	next_page_btn.text = "下页 ▶"
	next_page_btn.custom_minimum_size = Vector2(100, 34)
	next_page_btn.add_theme_font_size_override("font_size", 15)
	next_page_btn.add_theme_color_override("font_color", CLR_GOLD)
	next_page_btn.flat = true
	next_page_btn.pressed.connect(func(): _evidence_change_page(1))
	next_page_btn.name = "NextPageBtn"
	page_row.add_child(next_page_btn)

	# ── 分隔线 ──
	var sep2 := HSeparator.new()
	sep2.add_theme_stylebox_override("separator", _make_line_style(Color(0.5, 0.4, 0.18, 0.5)))
	ev_main_vbox.add_child(sep2)

	# ── 底部操作行 ──
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 30)
	ev_main_vbox.add_child(action_row)

	var submit_btn := Button.new()
	submit_btn.text = "⚡ 呈堂"
	submit_btn.custom_minimum_size = Vector2(150, 44)
	submit_btn.add_theme_font_size_override("font_size", 20)
	submit_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	submit_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.7))
	var sub_style := StyleBoxFlat.new()
	sub_style.bg_color = Color(0.14, 0.09, 0.04, 0.92)
	sub_style.border_color = Color(0.95, 0.7, 0.2, 0.9)
	sub_style.set_border_width_all(2)
	sub_style.set_corner_radius_all(6)
	sub_style.content_margin_top = 8
	sub_style.content_margin_bottom = 8
	submit_btn.add_theme_stylebox_override("normal", sub_style)
	var sub_hover := sub_style.duplicate() as StyleBoxFlat
	sub_hover.bg_color = Color(0.18, 0.12, 0.05, 0.96)
	sub_hover.border_color = Color(1.0, 0.82, 0.3, 1.0)
	submit_btn.add_theme_stylebox_override("hover", sub_hover)
	submit_btn.pressed.connect(_on_submit_evidence)
	submit_btn.name = "SubmitBtn"
	action_row.add_child(submit_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "✕ 返回"
	cancel_btn.custom_minimum_size = Vector2(120, 44)
	cancel_btn.add_theme_font_size_override("font_size", 17)
	cancel_btn.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	cancel_btn.add_theme_color_override("font_hover_color", Color(0.9, 0.85, 0.7))
	cancel_btn.flat = true
	cancel_btn.pressed.connect(_on_evidence_cancel)
	cancel_btn.name = "CancelBtn"
	_evidence_cancel_btn = cancel_btn
	action_row.add_child(cancel_btn)

	# ── 键盘操作提示 ──
	var hint_row := HBoxContainer.new()
	hint_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hint_row.add_theme_constant_override("separation", 24)
	ev_main_vbox.add_child(hint_row)

	var hint_text := Label.new()
	hint_text.text = "← → 选择    Q/E 翻页    Enter 呈堂    Esc 返回"
	hint_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_text.add_theme_font_size_override("font_size", 13)
	hint_text.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35, 0.7))
	_evidence_hint_label = hint_text
	hint_row.add_child(hint_text)

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
	_dlg_portrait_rect.flip_h = true  # 左侧立绘默认水平翻转，脸朝右（朝向对话文字）
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

	# ── 氛围层：暖色静态叠加（烛光底色，不闪烁）──
	var candle_overlay := ColorRect.new()
	candle_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	candle_overlay.color = Color(1.0, 0.55, 0.25, 0.04)
	candle_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	candle_overlay.z_index = 50
	candle_overlay.name = "CandleOverlay"
	_panel.add_child(candle_overlay)

	# ── 氛围层：暗角 vignette（四角压暗，增强压迫感）──
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.z_index = 51
	vignette.name = "VignetteOverlay"
	var vignette_shader_code := """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
void fragment() {
	vec2 uv = UV;
	float dist = distance(uv, vec2(0.5));
	float vignette = smoothstep(0.3, 0.85, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vignette * intensity);
}
"""
	var vignette_shader := Shader.new()
	vignette_shader.code = vignette_shader_code
	var vignette_mat := ShaderMaterial.new()
	vignette_mat.shader = vignette_shader
	vignette_mat.set_shader_parameter("intensity", 0.45)
	vignette.material = vignette_mat
	_panel.add_child(vignette)

	# ── 环境音：雨声循环 ──
	var sfx_player := get_node_or_null("/root/SfxPlayer")
	if sfx_player and sfx_player.has_method("play_ambient"):
		sfx_player.play_ambient("rain_ambient")

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
		_show_dialogue_queue(func(): _after_testimony_preamble(testimony))
	else:
		_after_testimony_preamble(testimony)


func _after_testimony_preamble(testimony: Dictionary) -> void:
	if bool(testimony.get("skip_title_card", false)):
		_hide_dialogue()
		_play_confrontation_bgm(_confrontation_testimony_bgm())
		_portrait_state = PortraitState.NORMAL
		_update_portrait()
		_play_testimony_readthrough()
	else:
		_show_testimony_title_card(testimony)


func _show_testimony_title_card(testimony: Dictionary) -> void:
	_hide_dialogue()
	# 证言开始时切换BGM
	_play_confrontation_bgm(_confrontation_testimony_bgm())
	# 显示证人立绘
	_portrait_state = PortraitState.NORMAL
	_update_portrait()

	# ── 独立标题特效：淡入 → 停留 → 淡出 ──
	var title_label := Label.new()
	title_label.text = "─ " + str(testimony.get("title", "")) + " ─"
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
		var testimony: Dictionary = _testimonies[_current_testimony_idx]
		if _is_forced_proof_testimony(testimony):
			var proof_hint: Array = testimony.get("readthrough_end_hint", [])
			if proof_hint.is_empty():
				_begin_forced_proof()
			else:
				_dialogue_queue = proof_hint
				_dialogue_idx = 0
				_show_dialogue_queue(func(): _begin_forced_proof())
			return
		# 朗读结束后的提示（让玩家知道该操作了）
		var end_hint: Array = testimony.get("readthrough_end_hint", [
			{"speaker": "凌瑶", "text": "（低声）证言说完了。哪句有破绽——你来判断。", "emotion": "determined"}
		])
		_dialogue_queue = end_hint
		_dialogue_idx = 0
		_show_dialogue_queue(func(): _enter_state(State.BROWSING))
		return
	var stmt: Dictionary = _statements[_dialogue_idx]
	var speaker: String = str(stmt.get("speaker", ""))
	if speaker == "你":
		speaker = "陆昭"
	_dialogue_speaker.text = speaker
	_dialogue_box.visible = true

	if _is_forced_proof_testimony():
		_auto_camera_switch(speaker, str(stmt.get("emotion", "")), stmt)

	# 更新对话头像
	_update_dialogue_portrait(speaker, str(stmt.get("emotion", "")), stmt)

	# 打字机效果
	var text: String = "「" + _statement_plain_text(stmt) + "」"
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
	# 镜头回到NPC居中
	_camera_ensure_browsing()
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
	var stmt_text := _statement_plain_text(stmt)
	_stmt_text_label.text = "[center]「" + stmt_text + "」[/center]"
	_stmt_counter_label.text = "%d / %d" % [_current_stmt_idx + 1, _statements.size()]
	_testimony_title_label.text = str(_testimonies[_current_testimony_idx].get("title", ""))

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
		if is_current:
			dot.text = "◉"
			dot.add_theme_font_size_override("font_size", 18)
			dot.add_theme_color_override("font_color", CLR_GOLD)
		else:
			dot.text = "●"
			dot.add_theme_font_size_override("font_size", 14)
			dot.add_theme_color_override("font_color", CLR_GOLD)
		_dot_container.add_child(dot)


func _statement_plain_text(stmt: Dictionary) -> String:
	var text := str(stmt.get("text", ""))
	text = TextUtilsScript.strip_stage_directions(text)
	var bbcode_tag := RegEx.new()
	var compile_err := bbcode_tag.compile("\\[[^\\]]+\\]")
	if compile_err == OK:
		text = bbcode_tag.sub(text, "", true)
	return text


func _current_testimony() -> Dictionary:
	if _current_testimony_idx >= 0 and _current_testimony_idx < _testimonies.size():
		return _testimonies[_current_testimony_idx]
	return {}


func _is_forced_proof_testimony(testimony: Dictionary = {}) -> bool:
	var t := testimony
	if t.is_empty():
		t = _current_testimony()
	return str(t.get("mode", "")) == "forced_proof"


func _forced_proof_statement_index(testimony: Dictionary) -> int:
	var statements: Array = testimony.get("statements", [])
	if statements.is_empty():
		return 0
	var proof_statement_id := str(testimony.get("proof_statement_id", ""))
	if proof_statement_id != "":
		for i in range(statements.size()):
			if str(statements[i].get("id", "")) == proof_statement_id:
				return i
	var proof_evidence := str(testimony.get("proof_evidence", ""))
	if proof_evidence != "":
		for i in range(statements.size()):
			var stmt: Dictionary = statements[i]
			var alt: Array = stmt.get("alt_evidence", [])
			if str(stmt.get("counter_evidence", "")) == proof_evidence or alt.has(proof_evidence):
				return i
	return statements.size() - 1


func _forced_proof_expected_evidence(testimony: Dictionary = {}) -> Array:
	var t := testimony
	if t.is_empty():
		t = _current_testimony()
	var expected: Array = []
	var proof_evidence := str(t.get("proof_evidence", ""))
	if proof_evidence != "":
		expected.append(proof_evidence)
	var proof_alt: Array = t.get("proof_alt_evidence", [])
	for eid in proof_alt:
		var ev_id := str(eid)
		if ev_id != "" and not expected.has(ev_id):
			expected.append(ev_id)
	if expected.is_empty():
		var idx := _forced_proof_statement_index(t)
		var statements: Array = t.get("statements", [])
		if idx >= 0 and idx < statements.size():
			var stmt: Dictionary = statements[idx]
			var counter := str(stmt.get("counter_evidence", ""))
			if counter != "":
				expected.append(counter)
			var alt: Array = stmt.get("alt_evidence", [])
			for eid in alt:
				var ev_id := str(eid)
				if ev_id != "" and not expected.has(ev_id):
					expected.append(ev_id)
	return expected


# ═══════════════════════════════════════════════════
#  威慑
# ═══════════════════════════════════════════════════

func _on_press_clicked() -> void:
	if _state != State.BROWSING:
		return
	_state = State.PRESSING
	_set_browsing_visible(false)

	# 固定威慑台词
	var stmt: Dictionary = _statements[_current_stmt_idx]
	var voice_line: String = str(stmt.get("press_voice_line", "慢着！"))

	# ── 威慑演出：定格 + 主角特写 + 冲击特效 + 语音 ──
	_play_press_effect(voice_line, stmt)


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


	# （旧变量已移除，证物册相关变量见类头部声明）

func _begin_forced_proof() -> void:
	var testimony := _current_testimony()
	if testimony.is_empty():
		return
	_forced_proof_active = true
	_current_stmt_idx = _forced_proof_statement_index(testimony)
	_enter_state(State.EVIDENCE_OPEN)


func _open_evidence() -> void:
	_portrait_state = PortraitState.NORMAL
	_update_portrait()
	_set_browsing_visible(false)
	_evidence_panel.visible = true
	if _evidence_cancel_btn != null and is_instance_valid(_evidence_cancel_btn):
		_evidence_cancel_btn.visible = not _forced_proof_active
		_evidence_cancel_btn.disabled = _forced_proof_active
	if _evidence_hint_label != null and is_instance_valid(_evidence_hint_label):
		if _forced_proof_active:
			_evidence_hint_label.text = "← → 选择    Q/E 翻页    Enter 呈堂"
		else:
			_evidence_hint_label.text = "← → 选择    Q/E 翻页    Enter 呈堂    Esc 返回"

	# 缓存可出示条目：物证优先，随后是证言/线索记录。
	_evidence_items_cache.clear()
	var presentable_ids: Array = []
	presentable_ids.append_array(GameManager.collected_evidence)
	presentable_ids.append_array(GameManager.collected_clues)
	for eid in presentable_ids:
		if _evidence_items_cache.has(eid):
			continue
		var data: Dictionary = GameManager.evidence_data.get(eid, {})
		var item_type: String = data.get("type", "")
		if not data.is_empty() and item_type in ["evidence", "clue"] and not data.get("hidden", false):
			_evidence_items_cache.append(eid)

	_selected_evidence_index = 0
	_evidence_page_index = 0
	_hovered_evidence_id = ""
	if not _evidence_items_cache.is_empty():
		_selected_evidence_id = _evidence_items_cache[0]
	else:
		_selected_evidence_id = ""

	# 显示当前证词引用
	if not _statements.is_empty():
		var stmt: Dictionary = _statements[_current_stmt_idx]
		if _forced_proof_active:
			var proof_prompt := str(_current_testimony().get("proof_prompt", ""))
			if proof_prompt == "":
				proof_prompt = "「" + _statement_plain_text(stmt) + "」"
			_evidence_statement_quote.text = "[color=#aa9966]自证焦点：[/color]" + proof_prompt
		else:
			_evidence_statement_quote.text = "[color=#aa9966]当前证词：[/color]「" + _statement_plain_text(stmt) + "」"
	else:
		_evidence_statement_quote.text = ""

	_render_evidence_page()


func _on_evidence_cancel() -> void:
	if _forced_proof_active:
		return
	_evidence_panel.visible = false
	_selected_evidence_id = ""
	_enter_state(State.BROWSING)


func _on_evidence_clicked(eid: String) -> void:
	if _state != State.EVIDENCE_OPEN:
		return
	_selected_evidence_id = eid
	_hovered_evidence_id = eid
	# 更新全局索引
	for i in range(_evidence_items_cache.size()):
		if _evidence_items_cache[i] == eid:
			_selected_evidence_index = i
			break
	_render_evidence_page()


func _on_submit_evidence() -> void:
	if _state != State.EVIDENCE_OPEN or _selected_evidence_id == "":
		return
	_evidence_panel.visible = false
	_judge_evidence(_selected_evidence_id)


func _evidence_change_page(delta: int) -> void:
	var max_page := maxi(0, (_evidence_items_cache.size() - 1) / EVIDENCE_PER_PAGE)
	_evidence_page_index = clampi(_evidence_page_index + delta, 0, max_page)
	# 将选中索引调整到新页范围内
	var page_start := _evidence_page_index * EVIDENCE_PER_PAGE
	var page_end := mini(page_start + EVIDENCE_PER_PAGE, _evidence_items_cache.size())
	if _selected_evidence_index < page_start:
		_selected_evidence_index = page_start
	elif _selected_evidence_index >= page_end:
		_selected_evidence_index = page_end - 1
	_render_evidence_page()


func _evidence_navigate(dx: int, dy: int) -> void:
	if _evidence_items_cache.is_empty():
		return
	var page_start := _evidence_page_index * EVIDENCE_PER_PAGE
	var page_end := mini(page_start + EVIDENCE_PER_PAGE, _evidence_items_cache.size())
	var page_count := page_end - page_start
	if page_count <= 0:
		return

	# 计算当前在页内的局部行列
	var local_idx := _selected_evidence_index - page_start
	var cur_row := local_idx / EVIDENCE_GRID_COLUMNS
	var cur_col := local_idx % EVIDENCE_GRID_COLUMNS

	var new_row := clampi(cur_row + dy, 0, (page_count - 1) / EVIDENCE_GRID_COLUMNS)
	var new_col := clampi(cur_col + dx, 0, mini(EVIDENCE_GRID_COLUMNS, page_count - new_row * EVIDENCE_GRID_COLUMNS) - 1)
	var new_local := new_row * EVIDENCE_GRID_COLUMNS + new_col
	new_local = clampi(new_local, 0, page_count - 1)

	_selected_evidence_index = page_start + new_local
	_selected_evidence_id = _evidence_items_cache[_selected_evidence_index]
	_hovered_evidence_id = _selected_evidence_id
	_render_evidence_page()


func _render_evidence_page() -> void:
	# 清空网格
	for c in _evidence_grid.get_children():
		c.queue_free()

	var page_start := _evidence_page_index * EVIDENCE_PER_PAGE
	var page_end := mini(page_start + EVIDENCE_PER_PAGE, _evidence_items_cache.size())

	for i in range(page_start, page_end):
		var eid: String = _evidence_items_cache[i]
		_evidence_grid.add_child(_make_evidence_card(eid, eid == _selected_evidence_id))

	# 补空格子保持布局
	var page_count := page_end - page_start
	var remainder := page_count % EVIDENCE_GRID_COLUMNS
	if remainder > 0:
		for _j in range(EVIDENCE_GRID_COLUMNS - remainder):
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(100, 90)
			_evidence_grid.add_child(spacer)

	# 更新分页标签
	var max_page := maxi(0, (_evidence_items_cache.size() - 1) / EVIDENCE_PER_PAGE)
	_evidence_page_label.text = "第 %d / %d 页" % [_evidence_page_index + 1, max_page + 1]

	# 更新详情
	_update_evidence_detail()


func _update_evidence_detail() -> void:
	# 优先使用悬浮ID显示详情，回退到选中ID
	var display_id := _hovered_evidence_id if _hovered_evidence_id != "" else _selected_evidence_id
	if display_id == "" or _evidence_items_cache.is_empty():
		_evidence_detail_icon.visible = false
		var placeholder = _evidence_panel.find_child("DetailPlaceholder", true, false)
		if placeholder:
			placeholder.visible = true
		_evidence_detail_name.text = "— 选择证物 —"
		_evidence_detail_desc.text = ""
		_evidence_detail_category.text = ""
		return

	var data: Dictionary = GameManager.evidence_data.get(display_id, {})
	var ename: String = data.get("name", display_id)
	var edesc: String = data.get("description", "")
	var ecat: String = data.get("type", "evidence")

	_evidence_detail_name.text = ename
	_evidence_detail_desc.text = edesc
	var ecategory: String = data.get("category", "")
	if ecategory != "":
		_evidence_detail_category.text = ecategory
	else:
		_evidence_detail_category.text = "物证" if ecat == "evidence" else "线索"

	# 更新大图
	var icon_path := "res://assets/ai_processed/objects/evidence_icons/%s.png" % display_id
	var placeholder = _evidence_panel.find_child("DetailPlaceholder", true, false)
	if ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path)
		if tex:
			_evidence_detail_icon.texture = tex
			_evidence_detail_icon.visible = true
			if placeholder:
				placeholder.visible = false
			return
	_evidence_detail_icon.visible = false
	if placeholder:
		placeholder.visible = true


func _make_evidence_card(eid: String, is_sel: bool) -> Button:
	var data: Dictionary = GameManager.evidence_data.get(eid, {})
	var ename: String = data.get("name", eid)

	var card := Button.new()
	card.custom_minimum_size = Vector2(100, 90)
	card.text = ""

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
	card.add_theme_stylebox_override("normal", s_style)

	var hover_style := s_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.10, 0.07, 0.03, 0.95)
	hover_style.border_color = Color(0.7, 0.55, 0.2, 0.8)
	hover_style.set_border_width_all(1)
	card.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := hover_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.18, 0.12, 0.05, 0.98)
	card.add_theme_stylebox_override("pressed", pressed_style)

	# 内部布局：图标 + 名称
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

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
			img.custom_minimum_size = Vector2(50, 50)
			img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(img)
	if not has_icon:
		var ph := Label.new()
		ph.text = "📜"
		ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ph.add_theme_font_size_override("font_size", 32)
		ph.custom_minimum_size = Vector2(50, 50)
		ph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(ph)

	# 名称（卡片上最多显示5字，超出截断加省略号）
	var display_name: String = ename
	if display_name.length() > 5:
		display_name = display_name.substr(0, 5) + "…"
	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_sel:
		name_lbl.add_theme_color_override("font_color", CLR_GOLD_BRIGHT)
	else:
		name_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	vbox.add_child(name_lbl)

	# 信号
	var ev_id: String = eid
	card.pressed.connect(func(): _on_evidence_clicked(ev_id))
	card.mouse_entered.connect(func(): _on_card_hover(ev_id))

	return card


func _on_card_hover(eid: String) -> void:
	# 鼠标悬浮/聚焦时只更新悬浮ID，不改变实际选中ID
	if _state != State.EVIDENCE_OPEN:
		return
	_hovered_evidence_id = eid
	# 只更新详情预览，不改变 _selected_evidence_id
	_update_evidence_detail()


func _update_card_selection_highlight() -> void:
	# 轻量更新网格中卡片选中态，避免整页重渲
	var page_start := _evidence_page_index * EVIDENCE_PER_PAGE
	var cards := _evidence_grid.get_children()
	for i in range(cards.size()):
		var card: Control = cards[i]
		if not card is Button:
			continue
		var card_idx := page_start + i
		var is_sel: bool = (card_idx < _evidence_items_cache.size() and
							_evidence_items_cache[card_idx] == _selected_evidence_id)
		var style: StyleBoxFlat = card.get_theme_stylebox("normal") as StyleBoxFlat
		if not style:
			continue
		if is_sel:
			style.bg_color = Color(0.16, 0.11, 0.04, 0.97)
			style.border_color = Color(1.0, 0.75, 0.2, 1.0)
			style.set_border_width_all(2)
		else:
			style.bg_color = Color(0.06, 0.05, 0.03, 0.9)
			style.border_color = Color(0.55, 0.4, 0.15, 0.6)
			style.set_border_width_all(1)
		# 更新名称颜色
		for child in card.get_children():
			if child is VBoxContainer:
				for sub in child.get_children():
					if sub is Label and sub.text != "📜" and not sub.text.begins_with("▸"):
						sub.add_theme_color_override("font_color",
							CLR_GOLD_BRIGHT if is_sel else Color(0.85, 0.8, 0.65))


# ═══════════════════════════════════════════════════
#  判定
# ═══════════════════════════════════════════════════

func _judge_evidence(eid: String) -> void:
	if _forced_proof_active:
		var expected := _forced_proof_expected_evidence()
		if expected.has(eid):
			_play_forced_proof_success()
		else:
			_enter_state(State.FAIL_ANIM)
		return

	var stmt: Dictionary = _statements[_current_stmt_idx]
	var is_contradiction: bool = stmt.get("is_contradiction", false)
	var counter: String = stmt.get("counter_evidence", "")
	var alt: Array = stmt.get("alt_evidence", [])

	if is_contradiction and (eid == counter or alt.has(eid)):
		_enter_state(State.BREAK_ANIM)
	else:
		_enter_state(State.FAIL_ANIM)


func _play_forced_proof_success() -> void:
	_state = State.PROOF_SUCCESS
	_set_browsing_visible(false)
	_evidence_panel.visible = false
	_play_evidence_present_fx(_selected_evidence_id)
	await get_tree().create_timer(0.35).timeout
	_flash_screen_white()
	_shake_screen(8.0, 5, 0.025)

	var stmt: Dictionary = _statements[_current_stmt_idx]
	var success_dlg: Array = stmt.get("break_dialogue", [])
	_dialogue_queue = success_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func(): _after_forced_proof_success())


func _after_forced_proof_success() -> void:
	var testimony: Dictionary = _current_testimony()
	_forced_proof_active = false
	var transition_dlg: Array = testimony.get("transition_dialogue", [])
	if not transition_dlg.is_empty():
		_dialogue_queue = transition_dlg
		_dialogue_idx = 0
		_show_dialogue_queue(func(): _advance_to_next_testimony())
	else:
		_advance_to_next_testimony()


# ═══════════════════════════════════════════════════
#  击破动画
# ═══════════════════════════════════════════════════

func _play_break_anim() -> void:
	_set_browsing_visible(false)
	_evidence_panel.visible = false

	# ── 举证成功特效：证据图标飞入 → 闪光 ──
	_play_evidence_present_fx(_selected_evidence_id)
	await get_tree().create_timer(0.4).timeout

	# ── 异议特效 + 集中线 + Hit Stop ──
	_play_focus_lines(1.0)
	await _play_objection_fx()

	# Hit Stop 定格
	await _play_hit_stop(0.12)

	# 击破时维持或切换到击破 BGM。旧数据把 bgm_break 用作开庭曲时，不在这里重播。
	_play_confrontation_bgm(_confrontation_break_bgm())

	# 击破闪屏效果 + 全屏震动
	_flash_screen_white()
	_shake_screen(18.0, 10, 0.035)

	# 立绘动摇 + 特写放大
	_portrait_state = PortraitState.SHAKEN
	_update_portrait()
	_shake_portrait()

	# ── 击破瞬间：立绘特写放大 → 定格 → 回弹 ──
	var base_scale := Vector2(1.0, 1.0)
	var zoom_tw := create_tween()
	zoom_tw.tween_property(_portrait_rect, "scale", base_scale * 1.15, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	zoom_tw.tween_interval(0.25)
	zoom_tw.tween_property(_portrait_rect, "scale", base_scale, 0.15).set_ease(Tween.EASE_IN_OUT)

	# 播放击破对话
	var stmt: Dictionary = _statements[_current_stmt_idx]
	var break_dlg: Array = stmt.get("break_dialogue", [])
	_dialogue_queue = break_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func(): _after_break_dialogue())


func _after_break_dialogue() -> void:
	var testimony: Dictionary = _testimonies[_current_testimony_idx]

	# ── 中途授予条目：击破证词后按类型加入物证或线索 ──
	var grant_id: String = testimony.get("grant_evidence", "")
	if grant_id != "":
		var grant_data: Dictionary = GameManager.evidence_data.get(grant_id, {})
		var grant_type: String = grant_data.get("type", "evidence")
		var added := false
		if grant_type == "clue":
			added = GameManager.add_clue(grant_id)
		else:
			added = GameManager.add_evidence(grant_id)
		if added and not GameManager.suppress_evidence_obtain_hold:
			await _show_evidence_acquired_fx(grant_id)

	# 检查当前证词是否有过渡对话（transition_dialogue）
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


## 中途获得新条目的演出：金色闪光 + 条目名 + 类型化标题
func _show_evidence_acquired_fx(evidence_id: String) -> void:
	var data: Dictionary = GameManager.evidence_data.get(evidence_id, {})
	var ename: String = data.get("name", evidence_id)
	_lock_input_for(EVIDENCE_ACQUIRED_LOCK_SECONDS)

	var fx_layer := Control.new()
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	fx_layer.z_index = 105
	_panel.add_child(fx_layer)

	# 金色闪光背景
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.88, 0.4, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(flash)

	# 居中容器
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	# "获得证物" 标题
	var title_lbl := Label.new()
	var item_type: String = data.get("type", "evidence")
	title_lbl.text = "获得证物" if item_type == "evidence" else "获得线索"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_lbl.add_theme_constant_override("outline_size", 4)
	title_lbl.modulate.a = 0.0
	vbox.add_child(title_lbl)

	# 证物名称
	var name_lbl := Label.new()
	name_lbl.text = ename
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_lbl.add_theme_constant_override("outline_size", 5)
	name_lbl.scale = Vector2(0.5, 0.5)
	name_lbl.modulate.a = 0.0
	vbox.add_child(name_lbl)

	# 动画：闪光 → 文字缩放进入 → 停留 → 淡出
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.6, 0.1)
	tw.tween_property(flash, "color:a", 0.15, 0.3)
	tw.parallel().tween_property(title_lbl, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(name_lbl, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(name_lbl, "scale", Vector2(1.05, 1.05), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(name_lbl, "scale", Vector2(1.0, 1.0), 0.1)
	# 震屏
	tw.parallel().tween_callback(func(): _shake_screen(6.0, 4, 0.02))
	# 固定停留 2 秒
	tw.tween_interval(2.0)
	# 淡出
	tw.tween_property(flash, "color:a", 0.0, 0.4)
	tw.parallel().tween_property(title_lbl, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(name_lbl, "modulate:a", 0.0, 0.3)
	tw.tween_callback(fx_layer.queue_free)
	await tw.finished


func _lock_input_for(seconds: float) -> void:
	var duration_msec := int(maxf(seconds, 0.0) * 1000.0)
	if duration_msec <= 0:
		return
	_input_locked_until_msec = maxi(
		_input_locked_until_msec,
		Time.get_ticks_msec() + duration_msec
	)


func _is_input_locked() -> bool:
	return Time.get_ticks_msec() < _input_locked_until_msec


func _advance_to_next_testimony() -> void:
	_forced_proof_active = false
	_current_testimony_idx += 1
	if _current_testimony_idx >= _testimonies.size():
		_enter_state(State.VICTORY)
	else:
		_portrait_state = PortraitState.NORMAL
		_update_portrait()
		# 进入新证词轮时切换BGM
		if _current_testimony_idx == _testimonies.size() - 1:
			_play_confrontation_bgm(str(_confrontation_data.get("bgm_final_round", _confrontation_testimony_bgm())))
		else:
			_play_confrontation_bgm(_confrontation_testimony_bgm())
		_enter_state(State.TESTIMONY_INTRO)


# ═══════════════════════════════════════════════════
#  失败动画
# ═══════════════════════════════════════════════════

func _play_fail_anim() -> void:
	_mistakes += 1
	_confidence = max(0, _confidence - 1)
	_set_browsing_visible(false)

	# ── 失败举证特效：红色冲击波 + 犯人退缩 ──
	_play_evidence_fail_fx()

	# ── 红闪 + 全屏震动 ──
	await _play_red_flash()
	_shake_screen(10.0, 6, 0.03)

	# ── 信心值脉冲动画（扣血后更新显示）──
	_update_confidence_display()
	_play_confidence_pulse()

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
			_forced_proof_active = false
			_enter_state(State.DEFEAT)
		elif _forced_proof_active:
			_begin_forced_proof()
		else:
			_enter_state(State.BROWSING)
	)


# ═══════════════════════════════════════════════════
#  胜利 / 失败
# ═══════════════════════════════════════════════════

func _play_victory() -> void:
	_set_browsing_visible(false)

	# ── 判决/击破大字特效。按对峙类型选择不同的大字：
	#   confrontation_wang: 自证清白，不涉及定罪，显示"指认推翻"
	#   confrontation_final: 序章终局是机制胜利、剧情败局，显示"真相抵岸"
	#   其他（如阿贵对峙）: 定罪，显示"有罪"
	var verdict_text := "有  罪"
	match GameManager.active_confrontation_key:
		"confrontation_wang":
			verdict_text = "指认推翻"
		"confrontation_final":
			verdict_text = "真相抵岸"
	await _play_guilty_verdict(verdict_text)

	# 击破闪屏 + 震屏
	_flash_screen_white()
	_shake_screen(20.0, 12, 0.03)

	# 犯人崩潰立绘
	_portrait_state = PortraitState.COLLAPSED
	_update_portrait()

	# BGM 切回开庭/收束氛围
	_play_confrontation_bgm(str(_confrontation_data.get("bgm_victory", _confrontation_intro_bgm())))

	var victory_dlg: Array = _confrontation_data.get("victory_dialogue", [])
	_dialogue_queue = victory_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func(): _play_epilogue_text())


func _play_epilogue_text() -> void:
	# 只有最终对峙播放黑屏结局文字；中间对峙胜利后直接返回调查阶段。
	if not bool(_confrontation_data.get("is_final", false)):
		confrontation_finished.emit("victory", _mistakes)
		return

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
	_typewriter.play(label, "[center]" + TextUtilsScript.strip_stage_directions(line) + "[/center]")
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

	# ── 失败演出：红屏渐暗 → "证据不足"大字 ──
	var defeat_layer := Control.new()
	defeat_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	defeat_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	defeat_layer.z_index = 110
	_panel.add_child(defeat_layer)

	var red_bg := ColorRect.new()
	red_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	red_bg.color = Color(0.3, 0.05, 0.05, 0.0)
	red_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	defeat_layer.add_child(red_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	defeat_layer.add_child(center)

	var fail_text := Label.new()
	fail_text.text = "证 据 不 足"
	fail_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fail_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fail_text.add_theme_font_size_override("font_size", 72)
	fail_text.add_theme_color_override("font_color", Color(0.9, 0.3, 0.25, 1.0))
	fail_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	fail_text.add_theme_constant_override("outline_size", 6)
	fail_text.scale = Vector2(0.5, 0.5)
	fail_text.modulate.a = 0.0
	center.add_child(fail_text)

	var tw := create_tween()
	# 红色背景渐入
	tw.tween_property(red_bg, "color:a", 0.7, 0.3)
	# 文字缩放进入
	tw.tween_property(fail_text, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(fail_text, "scale", Vector2(1.05, 1.05), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(fail_text, "scale", Vector2(1.0, 1.0), 0.1)
	# 震屏
	tw.parallel().tween_callback(func(): _shake_screen(12.0, 6, 0.03))
	# 停留
	tw.tween_interval(1.2)
	# 淡出
	tw.tween_property(fail_text, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(red_bg, "color:a", 0.0, 0.4)
	tw.tween_callback(defeat_layer.queue_free)
	await tw.finished

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
	_hide_speaking_portraits(true)


func _hide_speaking_portraits(kill_tween := false) -> void:
	if kill_tween and _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()
	for rect in [_protagonist_rect, _companion_rect, _opponent_rect]:
		if rect == null:
			continue
		rect.visible = false
		rect.modulate.a = 0.0
	_current_camera_view = "npc"


func _show_next_dialogue_line(on_done: Callable) -> void:
	if _dialogue_idx >= _dialogue_queue.size():
		_hide_dialogue()
		on_done.call()
		return
	var line = _dialogue_queue[_dialogue_idx]
	var line_data: Dictionary = {}
	var speaker: String = ""
	var text: String = ""
	var emotion: String = ""
	if line is Dictionary:
		line_data = line
		speaker = str(line_data.get("speaker", ""))
		text = str(line_data.get("text", ""))
		emotion = str(line_data.get("emotion", ""))
	else:
		text = str(line)

	if speaker == "你":
		speaker = "陆昭"
	var is_inner_thought := emotion == "inner_thought" or str(line_data.get("type", "")).to_lower() == "inner_thought"
	var display_text := TextUtilsScript.format_dialogue_text(text, is_inner_thought)
	# 对峙阶段 inner_thought 仍显示说话人名字
	if is_inner_thought and speaker == "":
		speaker = ""

	_dialogue_speaker.text = speaker
	_dialogue_box.visible = true

	# 镜头切换（在更新头像之前，这样头像逻辑可以参考镜头状态）
	_auto_camera_switch(speaker, emotion, line_data)

	# 更新对话头像
	_update_dialogue_portrait(speaker, emotion, line_data)

	# 辩护式打断：先播放集中线/“我反对”特效，再进入台词
	if emotion == "objection":
		_play_focus_lines(0.8)
		await _play_objection_fx()

	# 打字机效果
	_typewriter_playing = true
	_typewriter.play(_dialogue_text, display_text)
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


func _handle_browsing_mouse_click(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton):
		return false
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return false
	var pos: Vector2 = event.position
	if _prev_btn != null and is_instance_valid(_prev_btn) and not _prev_btn.disabled and _prev_btn.get_global_rect().has_point(pos):
		_navigate_stmt(-1)
		return true
	if _next_btn != null and is_instance_valid(_next_btn) and not _next_btn.disabled and _next_btn.get_global_rect().has_point(pos):
		_navigate_stmt(1)
		return true
	if _press_btn != null and is_instance_valid(_press_btn) and _press_btn.get_global_rect().has_point(pos):
		_on_press_clicked()
		return true
	if _present_btn != null and is_instance_valid(_present_btn) and _present_btn.get_global_rect().has_point(pos):
		_on_present_clicked()
		return true
	return false


func _input(event: InputEvent) -> void:
	if _is_input_locked():
		if event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch:
			get_viewport().set_input_as_handled()
		return
	# 浏览状态下手动兜底处理关键按钮区域。
	if _state == State.BROWSING:
		_click_callback = Callable()
		if _handle_browsing_mouse_click(event):
			get_viewport().set_input_as_handled()
		return

	# ── 证物册键盘导航 ──
	if _state == State.EVIDENCE_OPEN:
		_click_callback = Callable()
		if event is InputEventKey and event.pressed:
			var handled := true
			match event.keycode:
				KEY_LEFT, KEY_A:
					_evidence_navigate(-1, 0)
				KEY_RIGHT, KEY_D:
					_evidence_navigate(1, 0)
				KEY_UP, KEY_W:
					_evidence_navigate(0, -1)
				KEY_DOWN, KEY_S:
					_evidence_navigate(0, 1)
				KEY_Q:
					_evidence_change_page(-1)
				KEY_E:
					_evidence_change_page(1)
				KEY_ENTER, KEY_SPACE:
					_on_submit_evidence()
				KEY_ESCAPE, KEY_BACKSPACE:
					_on_evidence_cancel()
				_:
					handled = false
			if handled:
				get_viewport().set_input_as_handled()
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


func _make_line_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(0)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	return s


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
#  镜头切换系统（逆转裁判式）
# ═══════════════════════════════════════════════════

## 判断说话人是否为"我方"（陆昭/凌瑶/叙述中的陆昭）
func _is_protagonist_speaker(speaker: String, line_data: Dictionary = {}) -> bool:
	if speaker == "陆昭" or speaker == "你":
		return true
	var sid: String = str(line_data.get("speaker_id", ""))
	if sid == "lu_zhao" or sid == "you" or sid == "player":
		return true
	return false

## 判断说话人是否为搭档（凌瑶）
func _is_companion_speaker(speaker: String, line_data: Dictionary = {}) -> bool:
	if speaker == "凌瑶":
		return true
	var sid: String = str(line_data.get("speaker_id", ""))
	if sid == "xia_lingyao" or sid == "lingyao":
		return true
	return false

## 判断说话人是否为对手方（辩护方/沈清月等）
## 仅当该对手不是当前受审证人时返回 true
func _is_opponent_speaker(speaker: String, line_data: Dictionary = {}) -> bool:
	var speaker_id := _speaker_id_from_line(speaker, line_data)
	if not _opponent_speaker_ids.has(speaker_id):
		return false
	# 关键守卫：如果该对手正是当前受审证人，走正常 NPC 中央逻辑
	if speaker_id == _current_center_portrait_id():
		return false
	return true


## 切换到对手镜头：受审证人滑出，对手从右侧滑入独占特写
func _camera_switch_to_opponent(speaker_id: String, emotion: String = "normal", duration: float = 0.3) -> void:
	if not CAMERA_SWITCH_ENABLED:
		return
	if _current_camera_view == "opponent":
		# 已经在对手镜头，只更新纹理，并确保其他角色不可见
		var portrait_data := _update_opponent_portrait(speaker_id, emotion)
		if not portrait_data.is_empty():
			_apply_portrait_layout(_opponent_rect, _right_portrait_layout(
				PORTRAIT_SLOT_SIDE_INSET,
				str(portrait_data.get("npc_id", speaker_id)),
				str(portrait_data.get("layout_emotion", portrait_data.get("emotion", emotion))),
				str(portrait_data.get("path", ""))
			))
		if _portrait_rect:
			_portrait_rect.visible = false
		if _protagonist_rect:
			_protagonist_rect.visible = false
		if _companion_rect:
			_companion_rect.visible = false
		return
	_current_camera_view = "opponent"

	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# 独占镜头：对手说话时，立刻隐藏受审证人与主角/搭档，避免同屏
	if _portrait_rect:
		_portrait_rect.visible = false
		_portrait_rect.modulate.a = 0.0
	if _protagonist_rect:
		_protagonist_rect.visible = false
		_protagonist_rect.modulate.a = 0.0
	if _companion_rect:
		_companion_rect.visible = false
		_companion_rect.modulate.a = 0.0

	# 对手从右侧滑入
	if _opponent_rect:
		_opponent_rect.visible = true
		var portrait_data := _update_opponent_portrait(speaker_id, emotion)
		_tween_portrait_layout(_camera_tween, _opponent_rect, _right_portrait_layout(
			PORTRAIT_SLOT_SIDE_INSET,
			str(portrait_data.get("npc_id", speaker_id)),
			str(portrait_data.get("layout_emotion", portrait_data.get("emotion", emotion))),
			str(portrait_data.get("path", ""))
		), duration)
		_camera_tween.tween_property(_opponent_rect, "modulate:a", 1.0, duration * 0.5)

	_dlg_portrait_rect.visible = false

	_camera_tween.chain().tween_callback(func():
		_portrait_rect.visible = false
		if _protagonist_rect:
			_protagonist_rect.visible = false
		if _companion_rect:
			_companion_rect.visible = false
	)


## 更新对手立绘纹理
func _update_opponent_portrait(speaker_id: String, emotion: String = "normal") -> Dictionary:
	if not _opponent_rect:
		return {}
	var portrait_data := _resolve_opponent_portrait_data(speaker_id, emotion)
	var path := str(portrait_data.get("path", ""))
	if path != "" and ResourceLoader.exists(path):
		_set_portrait_texture(_opponent_rect, path)
		_opponent_portrait_data = portrait_data
		return portrait_data
	return {}


## 切换到NPC镜头：NPC居中，主角/搭档退出
func _camera_switch_to_npc(duration: float = 0.3, target_npc_id: String = "", target_emotion: String = "", target_portrait_path: String = "") -> void:
	if not CAMERA_SWITCH_ENABLED:
		return
	# 即使已经是NPC镜头，也要确保搭档/主角/对手立绘被隐藏
	if _protagonist_rect and _protagonist_rect.visible:
		_protagonist_rect.visible = false
	if _companion_rect and _companion_rect.visible:
		_companion_rect.visible = false
	if _opponent_rect and _opponent_rect.visible:
		_opponent_rect.visible = false
	var already_npc_view := _current_camera_view == "npc"
	if already_npc_view and target_npc_id == "" and target_portrait_path == "":
		return
	_current_camera_view = "npc"
	# 确保搭档立绘在NPC镜头下不可见
	if _companion_rect:
		_companion_rect.visible = false

	# 杀死之前的镜头动画
	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()

	# NPC 滑回居中
	_portrait_rect.visible = true
	var center_id := target_npc_id
	var center_emotion := target_emotion
	var center_path := target_portrait_path
	if center_id == "":
		center_id = _current_center_portrait_id()
		var portrait_variant := _resolve_center_portrait_variant(center_id)
		center_emotion = str(portrait_variant.get("emotion", "confrontation"))
		center_path = str(portrait_variant.get("path", ""))
	if center_path != "" and ResourceLoader.exists(center_path):
		_set_portrait_texture(_portrait_rect, center_path)
	var layout := _get_center_portrait_layout(
		center_id,
		center_emotion,
		center_path
	)
	if already_npc_view:
		_apply_portrait_layout(_portrait_rect, layout)
		_portrait_rect.rotation = 0.0
		_portrait_rect.modulate = Color(1, 1, 1, 1)
		_dlg_portrait_rect.visible = false
		return
	_camera_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween_portrait_layout(_camera_tween, _portrait_rect, layout, duration)
	_camera_tween.tween_property(_portrait_rect, "modulate:a", 1.0, duration * 0.5)

	# 主角滑出左侧
	if _protagonist_rect:
		_tween_portrait_layout(_camera_tween, _protagonist_rect, _offscreen_left_portrait_layout(
			str(_protagonist_portrait_data.get("npc_id", "")),
			str(_protagonist_portrait_data.get("emotion", "")),
			str(_protagonist_portrait_data.get("path", ""))
		), duration)
		_camera_tween.tween_property(_protagonist_rect, "modulate:a", 0.0, duration * 0.6)

	# 搭档滑出左侧
	if _companion_rect:
		_tween_portrait_layout(_camera_tween, _companion_rect, _offscreen_left_portrait_layout(
			str(_companion_portrait_data.get("npc_id", "")),
			str(_companion_portrait_data.get("emotion", "")),
			str(_companion_portrait_data.get("path", ""))
		), duration)
		_camera_tween.tween_property(_companion_rect, "modulate:a", 0.0, duration * 0.6)

	# 对手滑出右侧复位
	if _opponent_rect:
		_tween_portrait_layout(_camera_tween, _opponent_rect, _offscreen_right_portrait_layout(
			str(_opponent_portrait_data.get("npc_id", "")),
			str(_opponent_portrait_data.get("emotion", "")),
			str(_opponent_portrait_data.get("path", ""))
		), duration)
		_camera_tween.tween_property(_opponent_rect, "modulate:a", 0.0, duration * 0.6)

	# 隐藏小头像（NPC镜头下不需要）
	_dlg_portrait_rect.visible = false

	# 等动画完成后隐藏左侧/右侧角色
	_camera_tween.chain().tween_callback(func():
		if _protagonist_rect:
			_protagonist_rect.visible = false
		if _companion_rect:
			_companion_rect.visible = false
		if _opponent_rect:
			_opponent_rect.visible = false
	)


## 切换到主角镜头：NPC滑出右侧，说话角色从左侧滑入
## show_both=true 时同时显示搭档（两人同框）
func _camera_switch_to_protagonist(speaker_id: String, duration: float = 0.3, show_both: bool = false) -> void:
	if not CAMERA_SWITCH_ENABLED:
		return
	if _current_camera_view == "protagonist":
		var protagonist_data := _update_protagonist_portraits(speaker_id)
		if not protagonist_data.is_empty():
			_apply_portrait_layout(_protagonist_rect, _left_portrait_layout(
				PORTRAIT_SLOT_SIDE_INSET,
				str(protagonist_data.get("npc_id", speaker_id)),
				str(protagonist_data.get("layout_emotion", protagonist_data.get("emotion", "serious"))),
				str(protagonist_data.get("path", ""))
			))
		# 独占镜头：主角连续台词也要确保其他角色不可见
		if _portrait_rect:
			_portrait_rect.visible = false
		if _opponent_rect:
			_opponent_rect.visible = false
		if _companion_rect:
			if show_both:
				_companion_rect.visible = true
				var companion_data := _update_companion_portrait()
				_apply_portrait_layout(_companion_rect, _left_portrait_layout(
					350.0,
					str(companion_data.get("npc_id", "xia_lingyao")),
					str(companion_data.get("layout_emotion", companion_data.get("emotion", "confrontation_normal"))),
					str(companion_data.get("path", ""))
				))
				_companion_rect.modulate = Color(1, 1, 1, 0.9)
			else:
				_companion_rect.visible = false
		return
	_current_camera_view = "protagonist"

	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# 独占镜头：主角说话时，立刻隐藏受审证人与对手
	if _portrait_rect:
		_portrait_rect.visible = false
		_portrait_rect.modulate.a = 0.0
	if _opponent_rect:
		_opponent_rect.visible = false
		_opponent_rect.modulate.a = 0.0

	# 主角从左侧滑入
	if _protagonist_rect:
		_protagonist_rect.visible = true
		var protagonist_data := _update_protagonist_portraits(speaker_id)
		_tween_portrait_layout(_camera_tween, _protagonist_rect, _left_portrait_layout(
			PORTRAIT_SLOT_SIDE_INSET,
			str(protagonist_data.get("npc_id", speaker_id)),
			str(protagonist_data.get("layout_emotion", protagonist_data.get("emotion", "serious"))),
			str(protagonist_data.get("path", ""))
		), duration)
		_camera_tween.tween_property(_protagonist_rect, "modulate:a", 1.0, duration * 0.5)

		if _companion_rect:
			if show_both:
				_companion_rect.visible = true
				var companion_data := _update_companion_portrait()
				_tween_portrait_layout(_camera_tween, _companion_rect, _left_portrait_layout(
					350.0,
					str(companion_data.get("npc_id", "xia_lingyao")),
					str(companion_data.get("layout_emotion", companion_data.get("emotion", "confrontation_normal"))),
					str(companion_data.get("path", ""))
				), duration)
				_camera_tween.tween_property(_companion_rect, "modulate:a", 0.9, duration * 0.5)
			else:
				# 只显示主角，搭档淡出
				_camera_tween.tween_property(_companion_rect, "modulate:a", 0.0, duration * 0.4)

	_camera_tween.chain().tween_callback(func():
		_portrait_rect.visible = false
		if _companion_rect and not show_both:
			_companion_rect.visible = false
		if _opponent_rect:
			_opponent_rect.visible = false
	)

	_dlg_portrait_rect.visible = false


## 切换到搭档单独镜头：只显示搭档从左侧滑入
func _camera_switch_to_companion_only(duration: float = 0.3) -> void:
	if not CAMERA_SWITCH_ENABLED:
		return
	_current_camera_view = "companion"

	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# 独占镜头：搭档说话时，立刻隐藏受审证人/主角/对手
	if _portrait_rect:
		_portrait_rect.visible = false
		_portrait_rect.modulate.a = 0.0
	if _protagonist_rect:
		_protagonist_rect.visible = false
		_protagonist_rect.modulate.a = 0.0
	if _opponent_rect:
		_opponent_rect.visible = false
		_opponent_rect.modulate.a = 0.0

	# 搭档从左侧滑入，使用与主角一致的单人镜头尺寸。
	if _companion_rect:
		_companion_rect.visible = true
		var companion_data := _update_companion_portrait()
		_tween_portrait_layout(_camera_tween, _companion_rect, _left_portrait_layout(
			PORTRAIT_SLOT_SIDE_INSET,
			str(companion_data.get("npc_id", "xia_lingyao")),
			str(companion_data.get("emotion", "confrontation_normal")),
			str(companion_data.get("path", ""))
		), duration)
		_camera_tween.tween_property(_companion_rect, "modulate:a", 1.0, duration * 0.5)

	_camera_tween.chain().tween_callback(func():
		_portrait_rect.visible = false
		if _protagonist_rect:
			_protagonist_rect.visible = false
		if _opponent_rect:
			_opponent_rect.visible = false
	)

	_dlg_portrait_rect.visible = false


func _resolve_protagonist_portrait_data(speaker_id: String) -> Dictionary:
	var npc_id := speaker_id if speaker_id != "" else "lu_zhao"
	var emotion := "serious"
	var path := AssetResolver.resolve_case_portrait(npc_id, emotion, GameManager.npcs_data, "confrontation")
	if path != "" and ResourceLoader.exists(path):
		return {
			"npc_id": npc_id,
			"emotion": emotion,
			"layout_emotion": _default_layout_emotion_for_portrait(npc_id, emotion),
			"path": path
		}
	emotion = "normal"
	path = AssetResolver.resolve_case_portrait(npc_id, emotion, GameManager.npcs_data, "dialogue")
	if path != "" and ResourceLoader.exists(path):
		return {
			"npc_id": npc_id,
			"emotion": emotion,
			"layout_emotion": _default_layout_emotion_for_portrait(npc_id, emotion),
			"path": path
		}
	return {
		"npc_id": npc_id,
		"emotion": emotion,
		"layout_emotion": _default_layout_emotion_for_portrait(npc_id, emotion),
		"path": ""
	}


func _resolve_companion_portrait_data() -> Dictionary:
	var npc_id := "xia_lingyao"
	var emotion := "confrontation_normal"
	var path := AssetResolver.resolve_case_portrait(npc_id, emotion, GameManager.npcs_data, "confrontation")
	if path != "" and ResourceLoader.exists(path):
		return {
			"npc_id": npc_id,
			"emotion": emotion,
			"layout_emotion": _default_layout_emotion_for_portrait(npc_id, emotion),
			"path": path
		}
	emotion = "anxious"
	path = AssetResolver.resolve_case_portrait(npc_id, emotion, GameManager.npcs_data, "dialogue")
	if path != "" and ResourceLoader.exists(path):
		return {
			"npc_id": npc_id,
			"emotion": emotion,
			"layout_emotion": _default_layout_emotion_for_portrait(npc_id, emotion),
			"path": path
		}
	emotion = "normal"
	path = AssetResolver.resolve_case_portrait(npc_id, emotion, GameManager.npcs_data, "dialogue")
	if path != "" and ResourceLoader.exists(path):
		return {
			"npc_id": npc_id,
			"emotion": emotion,
			"layout_emotion": _default_layout_emotion_for_portrait(npc_id, emotion),
			"path": path
		}
	return {
		"npc_id": npc_id,
		"emotion": emotion,
		"layout_emotion": _default_layout_emotion_for_portrait(npc_id, emotion),
		"path": ""
	}


func _resolve_opponent_portrait_data(speaker_id: String, emotion: String = "normal") -> Dictionary:
	var npc_id := speaker_id
	var portrait_emotion := emotion if emotion != "" else "normal"
	var path := AssetResolver.resolve_case_portrait(npc_id, portrait_emotion, GameManager.npcs_data, "confrontation")
	if path != "" and ResourceLoader.exists(path):
		return {
			"npc_id": npc_id,
			"emotion": portrait_emotion,
			"layout_emotion": _default_layout_emotion_for_portrait(npc_id, portrait_emotion),
			"path": path
		}
	path = AssetResolver.resolve_case_portrait(npc_id, portrait_emotion, GameManager.npcs_data, "dialogue")
	if path != "" and ResourceLoader.exists(path):
		return {
			"npc_id": npc_id,
			"emotion": portrait_emotion,
			"layout_emotion": _default_layout_emotion_for_portrait(npc_id, portrait_emotion),
			"path": path
		}
	portrait_emotion = "normal"
	path = AssetResolver.resolve_case_portrait(npc_id, portrait_emotion, GameManager.npcs_data, "dialogue")
	if path != "" and ResourceLoader.exists(path):
		return {
			"npc_id": npc_id,
			"emotion": portrait_emotion,
			"layout_emotion": _default_layout_emotion_for_portrait(npc_id, portrait_emotion),
			"path": path
		}
	return {
		"npc_id": npc_id,
		"emotion": portrait_emotion,
		"layout_emotion": _default_layout_emotion_for_portrait(npc_id, portrait_emotion),
		"path": ""
	}


## 更新主角立绘纹理
func _update_protagonist_portraits(speaker_id: String) -> Dictionary:
	if not _protagonist_rect:
		return {}
	var portrait_data := _resolve_protagonist_portrait_data(speaker_id)
	var path := str(portrait_data.get("path", ""))
	if path != "" and ResourceLoader.exists(path):
		_set_portrait_texture(_protagonist_rect, path)
		_protagonist_portrait_data = portrait_data
		return portrait_data
	return {}

## 更新搭档立绘纹理（对峙模式使用 confrontation_pose 立绘）
func _update_companion_portrait() -> Dictionary:
	if not _companion_rect:
		return {}
	var portrait_data := _resolve_companion_portrait_data()
	var path := str(portrait_data.get("path", ""))
	if path != "" and ResourceLoader.exists(path):
		_set_portrait_texture(_companion_rect, path)
		_companion_portrait_data = portrait_data
		return portrait_data
	return {}

## 镜头恢复到NPC：用于浏览模式和对话结束后
func _camera_reset_to_npc() -> void:
	if not CAMERA_SWITCH_ENABLED:
		return
	_camera_switch_to_npc(0.3)

## 在对话行播放前自动切换镜头
## 对峙中采用独占镜头：谁说话就只显示谁，避免辩护方/证人/同伴同屏
func _auto_camera_switch(speaker: String, emotion: String, line_data: Dictionary = {}) -> void:
	if not CAMERA_SWITCH_ENABLED:
		return
	# 叙述 → 隐藏立绘，不切换镜头（inner_thought 照常切换）
	if emotion == "narration" or speaker == "":
		# 隐藏主角立绘
		if _protagonist_rect and _protagonist_rect.visible:
			_protagonist_rect.visible = false
		# 隐藏搭档立绘
		if _companion_rect and _companion_rect.visible:
			_companion_rect.visible = false
		# 隐藏对手立绘
		if _opponent_rect and _opponent_rect.visible:
			_opponent_rect.visible = false
		# 对话小头像已在 _update_dialogue_portrait 中处理
		return
	# 对峙镜头不允许同框，即使数据里配置了 show_both 也忽略
	var show_both := false
	# 主角说话 → 切到主角镜头
	if _is_protagonist_speaker(speaker, line_data):
		var speaker_id: String = "lu_zhao"
		var sid: String = str(line_data.get("speaker_id", ""))
		if sid != "":
			speaker_id = _normalize_speaker_id(sid)
		_camera_switch_to_protagonist(speaker_id, 0.3, show_both)
	elif _is_companion_speaker(speaker, line_data):
		if show_both:
			# 两人同框：主角+搭档都可见
			_camera_switch_to_protagonist("lu_zhao", 0.3, true)
			if _companion_rect:
				_companion_rect.modulate = Color(1, 1, 1, 1.0)
			if _protagonist_rect:
				_protagonist_rect.modulate = Color(0.7, 0.7, 0.7, 0.8)
		else:
			# 只显示搭档
			_camera_switch_to_companion_only(0.3)
	# 对手方说话（辩护方/沈清月等）→ 切到右侧对手镜头（独占特写）
	elif _is_opponent_speaker(speaker, line_data):
		var opp_sid := _speaker_id_from_line(speaker, line_data)
		_camera_switch_to_opponent(opp_sid, emotion, 0.3)
	# NPC/其他人说话 → 切到NPC镜头
	else:
		var speaker_id := _speaker_id_from_line(speaker, line_data)
		var portrait_emotion := str(line_data.get("portrait_emotion", ""))
		if portrait_emotion == "":
			portrait_emotion = emotion
		var portrait_layout_emotion := str(line_data.get("portrait_layout_emotion", ""))
		if portrait_layout_emotion == "":
			portrait_layout_emotion = _default_layout_emotion_for_portrait(speaker_id, portrait_emotion)
		var portrait_override := str(line_data.get("portrait_override", ""))
		var portrait_path := AssetResolver.resolve_case_portrait(speaker_id, portrait_emotion, GameManager.npcs_data, "dialogue", portrait_override)
		_camera_switch_to_npc(0.3, speaker_id, portrait_layout_emotion, portrait_path)
		# NPC镜头下不需要显示搭档/主角立绘，由 _camera_switch_to_npc 处理隐藏

## 在浏览模式进入时确保NPC镜头
func _camera_ensure_browsing() -> void:
	if CAMERA_SWITCH_ENABLED:
		_camera_reset_to_npc()


# ═══════════════════════════════════════════════════
#  立绘
# ═══════════════════════════════════════════════════

func _left_portrait_layout(inset: float, npc_id: String = "", emotion: String = "", portrait_path: String = "") -> Dictionary:
	var layout := {
		"left": inset,
		"top": PORTRAIT_SLOT_TOP,
		"right": inset + PORTRAIT_SLOT_WIDTH,
		"bottom": PORTRAIT_SLOT_BOTTOM
	}
	return _apply_portrait_presentation_to_layout(layout, npc_id, emotion, portrait_path)


func _right_portrait_layout(inset: float, npc_id: String = "", emotion: String = "", portrait_path: String = "") -> Dictionary:
	var layout := {
		"left": -inset - PORTRAIT_SLOT_WIDTH,
		"top": PORTRAIT_SLOT_TOP,
		"right": -inset,
		"bottom": PORTRAIT_SLOT_BOTTOM
	}
	return _apply_portrait_presentation_to_layout(layout, npc_id, emotion, portrait_path)


func _offscreen_left_portrait_layout(npc_id: String = "", emotion: String = "", portrait_path: String = "") -> Dictionary:
	return _left_portrait_layout(-PORTRAIT_SLOT_WIDTH - PORTRAIT_SLOT_OFFSCREEN_GAP, npc_id, emotion, portrait_path)


func _offscreen_right_portrait_layout(npc_id: String = "", emotion: String = "", portrait_path: String = "") -> Dictionary:
	var layout := {
		"left": PORTRAIT_SLOT_OFFSCREEN_GAP,
		"top": PORTRAIT_SLOT_TOP,
		"right": PORTRAIT_SLOT_OFFSCREEN_GAP + PORTRAIT_SLOT_WIDTH,
		"bottom": PORTRAIT_SLOT_BOTTOM
	}
	return _apply_portrait_presentation_to_layout(layout, npc_id, emotion, portrait_path)


func _apply_portrait_layout(rect: TextureRect, layout: Dictionary) -> void:
	if rect == null:
		return
	rect.offset_left = float(layout.get("left", 0.0))
	rect.offset_top = float(layout.get("top", PORTRAIT_SLOT_TOP))
	rect.offset_right = float(layout.get("right", PORTRAIT_SLOT_WIDTH))
	rect.offset_bottom = float(layout.get("bottom", PORTRAIT_SLOT_BOTTOM))
	rect.scale = Vector2.ONE * float(layout.get("scale", 1.0))
	var pivot_y := float(layout.get("pivot_y", (rect.offset_bottom - rect.offset_top) * 0.5))
	var pivot_x := float(layout.get("pivot_x", (rect.offset_right - rect.offset_left) * 0.5))
	rect.pivot_offset = Vector2(
		pivot_x,
		pivot_y
	)


func _tween_portrait_layout(tween: Tween, rect: TextureRect, layout: Dictionary, duration: float) -> void:
	if tween == null or rect == null:
		return
	tween.tween_property(rect, "offset_left", float(layout.get("left", rect.offset_left)), duration)
	tween.tween_property(rect, "offset_top", float(layout.get("top", rect.offset_top)), duration)
	tween.tween_property(rect, "offset_right", float(layout.get("right", rect.offset_right)), duration)
	tween.tween_property(rect, "offset_bottom", float(layout.get("bottom", rect.offset_bottom)), duration)
	tween.tween_property(rect, "scale", Vector2.ONE * float(layout.get("scale", 1.0)), duration)
	rect.pivot_offset = Vector2(
		float(layout.get("pivot_x", (float(layout.get("right", rect.offset_right)) - float(layout.get("left", rect.offset_left))) * 0.5)),
		float(layout.get("pivot_y", rect.pivot_offset.y))
	)


func _set_portrait_texture(rect: TextureRect, path: String) -> bool:
	if rect == null:
		return false
	var texture := _load_normalized_portrait_texture(path)
	if texture == null:
		return false
	rect.texture = texture
	return true


func _load_normalized_portrait_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var cached = _portrait_texture_cache.get(path, null)
	if cached is Texture2D:
		return cached
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	var normalized := _crop_texture_to_visible_alpha(texture)
	_portrait_texture_cache[path] = normalized
	return normalized


func _crop_texture_to_visible_alpha(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image == null:
		return texture
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return texture
	var image_size := image.get_size()
	var normalize_cfg := _get_portrait_normalize_config()
	if float(used.size.y) / float(image_size.y) < float(normalize_cfg.get("crop_min_height_ratio", DEFAULT_PORTRAIT_CROP_MIN_HEIGHT_RATIO)):
		return texture
	var pad_ratio := float(normalize_cfg.get("crop_padding_ratio", DEFAULT_PORTRAIT_CROP_PADDING_RATIO))
	var min_padding := int(normalize_cfg.get("crop_min_padding", DEFAULT_PORTRAIT_CROP_MIN_PADDING))
	var pad_x: int = max(min_padding, int(ceil(float(used.size.x) * pad_ratio)))
	var pad_y: int = max(min_padding, int(ceil(float(used.size.y) * pad_ratio)))
	var x1: int = max(0, used.position.x - pad_x)
	var y1: int = max(0, used.position.y - pad_y)
	var x2: int = min(image_size.x, used.position.x + used.size.x + pad_x)
	var y2: int = min(image_size.y, used.position.y + used.size.y + pad_y)
	if x1 == 0 and y1 == 0 and x2 == image_size.x and y2 == image_size.y:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(float(x1), float(y1), float(x2 - x1), float(y2 - y1))
	return atlas


func _current_center_portrait_id() -> String:
	# 优先使用当前证词轮次指定的 witness，回退到全局 suspect
	var witness_id: String = ""
	if _current_testimony_idx >= 0 and _current_testimony_idx < _testimonies.size():
		witness_id = _testimonies[_current_testimony_idx].get("witness", "")
	if witness_id == "":
		witness_id = _confrontation_data.get("suspect", "")
	return witness_id


func _get_center_portrait_layout(npc_id: String, emotion: String = "", portrait_path: String = "") -> Dictionary:
	var layout := {
		"left": float(_center_portrait_frame.get("offset_left", -320.0)),
		"top": float(_center_portrait_frame.get("offset_top", PORTRAIT_SLOT_TOP)),
		"right": float(_center_portrait_frame.get("offset_right", 320.0)),
		"bottom": float(_center_portrait_frame.get("offset_bottom", PORTRAIT_SLOT_BOTTOM)),
		"pivot_x": float(_center_portrait_frame.get("pivot_x", 320.0)),
	}
	return _apply_portrait_presentation_to_layout(layout, npc_id, emotion, portrait_path)


func _apply_portrait_presentation_to_layout(layout: Dictionary, npc_id: String, emotion: String = "", portrait_path: String = "") -> Dictionary:
	var presentation := AssetResolver.get_center_portrait_surface_presentation("confrontation", npc_id, emotion, portrait_path)
	var offset_y := float(presentation.get("offset_y", 0.0))
	layout["top"] = float(layout.get("top", PORTRAIT_SLOT_TOP)) + offset_y
	layout["bottom"] = float(layout.get("bottom", PORTRAIT_SLOT_BOTTOM)) + offset_y
	layout["scale"] = float(presentation.get("screen_scale", layout.get("scale", 1.0)))
	layout["pivot_y"] = float(presentation.get("pivot_y", layout.get("pivot_y", 330.0)))
	return layout


func _get_portrait_normalize_config() -> Dictionary:
	if AssetResolver != null and AssetResolver.has_method("get_center_portrait_texture_normalize_config"):
		var resolved = AssetResolver.get_center_portrait_texture_normalize_config("confrontation")
		if typeof(resolved) == TYPE_DICTIONARY and not resolved.is_empty():
			return resolved
	return {
		"crop_padding_ratio": DEFAULT_PORTRAIT_CROP_PADDING_RATIO,
		"crop_min_padding": DEFAULT_PORTRAIT_CROP_MIN_PADDING,
		"crop_min_height_ratio": DEFAULT_PORTRAIT_CROP_MIN_HEIGHT_RATIO,
	}


func _apply_center_portrait_layout(npc_id: String, emotion: String = "", portrait_path: String = "") -> void:
	if _portrait_rect == null:
		return
	var layout := _get_center_portrait_layout(npc_id, emotion, portrait_path)
	_apply_portrait_layout(_portrait_rect, layout)


func _resolve_center_portrait_variant(npc_id: String) -> Dictionary:
	var emotion_key := "confrontation"
	match _portrait_state:
		PortraitState.SHAKEN:
			emotion_key = "confrontation_shaken"
		PortraitState.COLLAPSED:
			emotion_key = "confrontation_collapsed"
	var path := AssetResolver.resolve_case_portrait(npc_id, emotion_key, GameManager.npcs_data, "confrontation")
	return {
		"emotion": emotion_key,
		"path": path,
	}


func _update_portrait() -> void:
	var witness_id := _current_center_portrait_id()
	if witness_id == "":
		return
	var portrait_variant := _resolve_center_portrait_variant(witness_id)
	var emotion_key := str(portrait_variant.get("emotion", "confrontation"))
	var path := str(portrait_variant.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	_set_portrait_texture(_portrait_rect, path)
	_apply_center_portrait_layout(witness_id, emotion_key, path)
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

	var label := Label.new()
	label.text = "我 反 对！"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 6)
	# 使用 PRESET_CENTER + pivot_offset 让缩放从中心开始
	# 修改 offset_top/offset_bottom 即可上下移动
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -300
	label.offset_right = 300
	label.offset_top = -200    # 改这个值来上下移动（负=上，正=下）
	label.offset_bottom = -100
	label.pivot_offset = Vector2(300, 50)
	label.scale = Vector2(0.3, 0.3)
	label.modulate.a = 0.0
	_objection_layer.add_child(label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "color:a", 0.9, 0.06)
	tw.tween_property(label, "modulate:a", 1.0, 0.06)
	tw.tween_property(label, "scale", Vector2(1.15, 1.15), 0.12)
	tw.chain()
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.08)
	# 停留至少1.5秒后再淡出
	tw.tween_interval(1.5)
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
#  对话头像 / 说话人立绘
# ═══════════════════════════════════════════════════

func _update_dialogue_portrait(speaker: String, emotion: String, line_data: Dictionary = {}) -> void:
	if _dlg_portrait_rect == null:
		return
	if speaker == "" or emotion == "narration":
		_dlg_portrait_rect.visible = false
		return
	# inner_thought 在对峙阶段照常显示头像（用 serious 表情）
	if emotion == "inner_thought":
		emotion = "serious"
	var speaker_id := _speaker_id_from_line(speaker, line_data)
	if speaker_id == "":
		_dlg_portrait_rect.visible = false
		return
	var portrait_emotion := str(line_data.get("portrait_emotion", ""))
	if portrait_emotion == "":
		portrait_emotion = emotion
	if (speaker_id == "lu_zhao" or speaker == "陆昭" or speaker == "你") and (portrait_emotion == "" or portrait_emotion == "normal"):
		portrait_emotion = "serious"
	var portrait_layout_emotion := str(line_data.get("portrait_layout_emotion", ""))
	if portrait_layout_emotion == "":
		portrait_layout_emotion = _default_layout_emotion_for_portrait(speaker_id, portrait_emotion)
	var portrait_override := str(line_data.get("portrait_override", ""))
	var portrait_path := AssetResolver.resolve_case_portrait(speaker_id, portrait_emotion, GameManager.npcs_data, "dialogue", portrait_override)
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		_dlg_portrait_rect.visible = false
		return
	# 镜头切换模式下：主角和搭档已经在屏幕上了，不需要小头像
	if CAMERA_SWITCH_ENABLED and (speaker_id == "lu_zhao" or speaker_id == "xia_lingyao" or speaker_id == "lingyao"):
		_dlg_portrait_rect.visible = false
		# 主角/搭档的立绘由镜头系统管理，这里不额外处理
	elif CAMERA_SWITCH_ENABLED and _is_opponent_speaker(speaker, line_data):
		# 对手方立绘由 _camera_switch_to_opponent 管理，不得顶替中央证人
		_dlg_portrait_rect.visible = false
	else:
		# 非镜头切换模式，或NPC说话时的传统逻辑
		if speaker_id == "lu_zhao" or speaker_id == "xia_lingyao" or speaker_id == "lingyao":
			_dlg_portrait_rect.visible = _set_portrait_texture(_dlg_portrait_rect, portrait_path)
		else:
			# NPC 台词仍显示在中央立绘位，但立绘路径同样走统一 resolver。
			_dlg_portrait_rect.visible = false
			_set_portrait_texture(_portrait_rect, portrait_path)
			_apply_center_portrait_layout(speaker_id, portrait_layout_emotion, portrait_path)
			_portrait_rect.rotation = 0.0
			_portrait_rect.modulate = Color(1, 1, 1, 1)
			_portrait_rect.visible = true


func _speaker_id_from_line(speaker: String, line_data: Dictionary) -> String:
	var speaker_id := str(line_data.get("speaker_id", ""))
	if speaker_id != "":
		return _normalize_speaker_id(speaker_id)
	return _find_npc_id_by_speaker(speaker)


func _normalize_speaker_id(speaker_id: String) -> String:
	match speaker_id:
		"you", "player", "陆昭", "你":
			return "lu_zhao"
		"凌瑶", "lingyao":
			return "xia_lingyao"
	return speaker_id


func _default_layout_emotion_for_portrait(speaker_id: String, portrait_emotion: String) -> String:
	if portrait_emotion.begins_with("confrontation"):
		return portrait_emotion
	if AssetResolver != null and AssetResolver.has_method("get_center_npc_emotions"):
		var configured_emotions: Array = AssetResolver.get_center_npc_emotions(speaker_id)
		if configured_emotions.has(portrait_emotion):
			return portrait_emotion
	match speaker_id:
		"li_zheng", "shen_qingyue", "lu_zhao", "xia_lingyao", "lingyao":
			return "base"
	return portrait_emotion if portrait_emotion != "" else "base"


func _find_npc_id_by_speaker(speaker_name: String) -> String:
	"""通过显示名查找 NPC ID。CSV 里有 speaker_id 时优先使用 speaker_id，这里只兜底兼容旧表。"""
	var normalized_name := speaker_name
	if normalized_name == "你":
		normalized_name = "陆昭"
	var name_map := {
		"陆昭": "lu_zhao",
		"凌瑶": "xia_lingyao",
		"钱里正": "li_zheng",
		"阿贵": "agui",
		"老范": "lao_fan",
		"周氏": "zhou_wife",
		"王大爷": "fisherman_wang",
		"沈清月": "shen_qingyue",
	}
	if name_map.has(normalized_name):
		return name_map[normalized_name]
	# 回退：遍历 npcs_data 查找
	for npc_id in GameManager.npcs_data.keys():
		if GameManager.get_npc_display_name(str(npc_id)) == normalized_name:
			return str(npc_id)
	return ""


# ═══════════════════════════════════════════════════
#  TTS 语音合成
# ═══════════════════════════════════════════════════

## 为主角（陆昭）播放 TTS 语音，用于威慑等动作时的喊话
## 威慑完整演出：定格 + 主角特写 + 语音 + 台词屏幕显示 + NPC 反应
func _play_press_effect(voice_line: String, stmt: Dictionary) -> void:
	var stmt_id: String = stmt.get("id", "")
	var press_dlg: Array = stmt.get("press", [])

	# ── 1. 集中线特效（定格感）──
	_play_focus_lines(1.2)

	# ── 2. 镜头切到主角特写 ──
	_camera_switch_to_protagonist("lu_zhao", 0.2)

	# ── 3. Hit Stop 短暂定格 ──
	await _play_hit_stop(0.08)

	# ── 4. 全屏白闪 ──
	_flash_screen_white()

	# ── 5. 轻微震屏 ──
	_shake_screen(8.0, 4, 0.03)

	# ── 6. 主角台词大字显示在屏幕上 ──
	_show_press_subtitle(voice_line)

	# ── 7. TTS 语音播放（与字幕同步，异步不阻塞）──
	_play_protagonist_tts(voice_line)
	await get_tree().create_timer(0.3).timeout

	# ── 8. NPC 立绘受冲击 ──
	if _portrait_rect.visible:
		_portrait_state = PortraitState.SHAKEN
		_update_portrait()
		_shake_portrait()

	# ── 9. 等台词显示结束后，进入威慑对话 ──
	if press_dlg.is_empty():
		press_dlg = [
			{"speaker": "你", "text": voice_line},
			{"speaker": stmt.get("speaker", "阿贵"), "text": "就……就是我说的那样。没什么好补充的。"}
		]

	_dialogue_queue = press_dlg
	_dialogue_idx = 0
	_show_dialogue_queue(func(): _after_press(stmt_id, stmt))


## 屏幕上方居中显示主角台词（大字 + 淡入淡出）
func _show_press_subtitle(text: String) -> void:
	var subtitle_layer := Control.new()
	subtitle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	subtitle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle_layer.z_index = 120
	_panel.add_child(subtitle_layer)

	var label := Label.new()
	label.text = "「" + text + "」"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -500
	label.offset_right = 500
	label.offset_top = -200
	label.offset_bottom = -130
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.modulate.a = 0.0
	subtitle_layer.add_child(label)

	# 淡入 → 停留 → 淡出
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.2)
	tw.tween_property(label, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(subtitle_layer.queue_free)


func _play_protagonist_tts(text: String) -> void:
	var tts := get_node_or_null("/root/TTSService")
	if tts == null or not tts.is_available():
		return
	# 威慑语音风格：中年男性，沉稳冷静，威严有力
	var style_hint := "用沉稳有力的中年男性声音大声喝断对方，语气严厉但不急躁，带着御史台官员特有的威严和压迫感。音调偏低沉，共鸣饱满，每个字都掷地有声，像惊堂木一拍。不拖沓，干净利落。"
	tts.request_tts_speaker("陆昭", text, "lu_zhao", style_hint)


# ═══════════════════════════════════════════════════
#  阶段一：冲击力强化 — 新增特效方法
# ═══════════════════════════════════════════════════

## Hit Stop：短暂冻结画面，模拟打击感
func _play_hit_stop(duration: float = 0.15) -> void:
	var prev_scale := Engine.time_scale
	# 收集并暂停所有活跃 tween
	var paused_tweens: Array[Tween] = []
	for tw in get_tree().get_processed_tweens():
		if tw.is_valid() and tw.is_running():
			paused_tweens.append(tw)
			tw.pause()
	Engine.time_scale = 0.02
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = prev_scale
	for tw in paused_tweens:
		if tw.is_valid():
			tw.play()


## 全屏震动（UI 级别，不依赖 Camera2D）
func _shake_screen(intensity: float = 15.0, count: int = 8, single_dur: float = 0.04) -> void:
	var original_pos := _panel.position
	var tw := create_tween()
	for i in range(count):
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity * 0.5, intensity * 0.5)
		)
		tw.tween_property(_panel, "position", original_pos + offset, single_dur)
	tw.tween_property(_panel, "position", original_pos, single_dur)


## 集中线/速度线特效：从画面四角向中心汇聚的放射线
func _play_focus_lines(duration: float = 0.8) -> void:
	var focus_layer := Control.new()
	focus_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	focus_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_layer.z_index = 100
	_panel.add_child(focus_layer)

	var vp_size := get_viewport_rect().size
	var center := vp_size * 0.5

	# 创建放射线
	var line_count := 24
	var draw_node := _FocusLinesDraw.new()
	draw_node.center = center
	draw_node.line_count = line_count
	draw_node.intensity = 1.0
	draw_node.focus_color = Color(1.0, 0.92, 0.55, 0.0)  # 金色，初始透明
	focus_layer.add_child(draw_node)

	# 动画：淡入 → 停留 → 淡出
	var tw := create_tween()
	tw.tween_property(draw_node, "focus_color:a", 0.6, 0.12)
	tw.tween_property(draw_node, "intensity", 0.4, duration * 0.6).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(draw_node, "focus_color:a", 0.0, duration * 0.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		focus_layer.queue_free()
	)


## 信心值扣减动画：心形脉冲 + 屏幕边缘红光
func _play_confidence_pulse() -> void:
	# 心形文字脉冲
	var original_size := 24
	var tw := create_tween()
	tw.tween_property(_confidence_label, "theme_override_font_sizes/font_size", 36, 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(_confidence_label, "theme_override_font_sizes/font_size", 20, 0.12).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_confidence_label, "theme_override_font_sizes/font_size", original_size, 0.15).set_ease(Tween.EASE_OUT)

	# 红色边框脉冲（屏幕边缘闪烁）
	var red_border := ColorRect.new()
	red_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	red_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_border.color = Color(0.85, 0.15, 0.1, 0.0)
	red_border.z_index = 90
	_panel.add_child(red_border)

	var border_tw := create_tween()
	border_tw.tween_property(red_border, "color:a", 0.3, 0.06)
	border_tw.tween_property(red_border, "color:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	border_tw.tween_callback(red_border.queue_free)


## 举证成功特效：证据图标飞入中央 → 放大闪光
func _play_evidence_present_fx(evidence_id: String) -> void:
	var fx_layer := Control.new()
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.z_index = 95
	_panel.add_child(fx_layer)

	# 获取证物名称
	var data: Dictionary = GameManager.evidence_data.get(evidence_id, {})
	var ename: String = data.get("name", evidence_id)

	# ── 证物图标（上方偏移） ──
	var icon := TextureRect.new()
	var icon_path := "res://assets/ai_processed/objects/evidence_icons/%s.png" % evidence_id
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	else:
		# 无图时用文字占位
		var placeholder := Label.new()
		placeholder.text = "📜"
		placeholder.add_theme_font_size_override("font_size", 48)
		placeholder.set_anchors_preset(Control.PRESET_CENTER)
		placeholder.offset_left = -30
		placeholder.offset_right = 30
		placeholder.offset_top = -60
		placeholder.offset_bottom = 0
		fx_layer.add_child(placeholder)
		# 名称标签
		var name_label := _make_evidence_present_name(ename, fx_layer)
		_play_evidence_present_anim(fx_layer, placeholder, name_label)
		return

	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(128, 128)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -64
	icon.offset_right = 64
	icon.offset_top = -120
	icon.offset_bottom = 8
	icon.scale = Vector2(0.5, 0.5)
	icon.modulate.a = 0.0
	fx_layer.add_child(icon)

	# ── 证物名称标签（图标下方） ──
	var name_label := _make_evidence_present_name(ename, fx_layer)

	_play_evidence_present_anim(fx_layer, icon, name_label)


## 创建举证时的证物名称标签
func _make_evidence_present_name(ename: String, parent: Control) -> Label:
	var name_label := Label.new()
	name_label.text = ename
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.set_anchors_preset(Control.PRESET_CENTER)
	name_label.offset_left = -250
	name_label.offset_right = 250
	name_label.offset_top = 20
	name_label.offset_bottom = 70
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.modulate.a = 0.0
	parent.add_child(name_label)
	return name_label


func _play_evidence_present_anim(fx_layer: Control, icon_node: Control, name_label: Label = null) -> void:
	# 飞入 → 放大 → 闪光 → 停留至少1.5秒 → 淡出
	var tw := create_tween()
	tw.tween_property(icon_node, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(icon_node, "scale", Vector2(1.2, 1.2), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# 名称标签同步淡入
	if name_label:
		tw.parallel().tween_property(name_label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(0.3)

	# 白色闪光爆发
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(flash)
	tw.tween_property(flash, "color:a", 0.7, 0.06)
	tw.tween_property(icon_node, "scale", Vector2(1.5, 1.5), 0.1)
	tw.tween_property(flash, "color:a", 0.0, 0.2)
	# 证物和名称至少停留1.5秒
	tw.tween_interval(1.5)
	# 淡出
	tw.parallel().tween_property(icon_node, "modulate:a", 0.0, 0.3)
	if name_label:
		tw.parallel().tween_property(name_label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(fx_layer.queue_free)


## 举证失败特效：证据碎裂 + 红色冲击
func _play_evidence_fail_fx() -> void:
	var vp_size := get_viewport_rect().size

	# 红色冲击波
	var shockwave := ColorRect.new()
	shockwave.set_anchors_preset(Control.PRESET_FULL_RECT)
	shockwave.color = Color(0.8, 0.1, 0.05, 0.0)
	shockwave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shockwave.z_index = 95
	_panel.add_child(shockwave)

	var tw := create_tween()
	tw.tween_property(shockwave, "color:a", 0.35, 0.05)
	tw.tween_property(shockwave, "color:a", 0.0, 0.3)
	tw.tween_callback(shockwave.queue_free)

	# 犯人立绘微退缩（威慑感）
	if _portrait_rect.visible:
		var orig_x := _portrait_rect.offset_left
		var shake_tw := create_tween()
		shake_tw.tween_property(_portrait_rect, "offset_left", orig_x + 15.0, 0.06)
		shake_tw.tween_property(_portrait_rect, "offset_left", orig_x - 5.0, 0.04)
		shake_tw.tween_property(_portrait_rect, "offset_left", orig_x, 0.06)


## 判决/击破大字特效
func _play_guilty_verdict(verdict_text: String = "有  罪") -> void:
	var verdict_layer := Control.new()
	verdict_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	verdict_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	verdict_layer.z_index = 110
	_panel.add_child(verdict_layer)

	# 黑幕
	var black := ColorRect.new()
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.color = Color(0.0, 0.0, 0.0, 0.0)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	verdict_layer.add_child(black)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	verdict_layer.add_child(center)

	var verdict := Label.new()
	verdict.text = verdict_text
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	verdict.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	verdict.add_theme_font_size_override("font_size", 96)
	verdict.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	verdict.add_theme_color_override("font_outline_color", Color(0.8, 0.2, 0.1, 1.0))
	verdict.add_theme_constant_override("outline_size", 8)
	verdict.scale = Vector2(2.5, 2.5)
	verdict.modulate.a = 0.0
	center.add_child(verdict)

	var tw := create_tween()
	# 黑幕渐入
	tw.tween_property(black, "color:a", 0.85, 0.2)
	# 大字砸下（弹性）
	tw.tween_property(verdict, "modulate:a", 1.0, 0.08)
	tw.parallel().tween_property(verdict, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	# 屏幕震动
	tw.parallel().tween_callback(func(): _shake_screen(12.0, 6, 0.03))
	# 停留
	tw.tween_interval(1.5)
	# 淡出
	tw.tween_property(verdict, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(black, "color:a", 0.0, 0.4)
	tw.tween_callback(verdict_layer.queue_free)
	await tw.finished


# ─── 内部辅助类：集中线绘制 ───
class _FocusLinesDraw extends Control:
	var center: Vector2 = Vector2.ZERO
	var line_count: int = 24
	var intensity: float = 1.0
	var focus_color: Color = Color(1, 1, 1, 0.6)

	func _draw() -> void:
		var vp_size := get_viewport_rect().size
		var max_dist := vp_size.length() * 0.6
		for i in range(line_count):
			var angle := float(i) / float(line_count) * TAU
			var inner_radius := max_dist * 0.15 * intensity
			var outer_radius := max_dist * (0.4 + 0.6 * intensity)
			var start_pt := center + Vector2(cos(angle), sin(angle)) * inner_radius
			var end_pt := center + Vector2(cos(angle), sin(angle)) * outer_radius
			var width := 2.0 + randf() * 2.0
			draw_line(start_pt, end_pt, focus_color, width)
