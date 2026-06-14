extends Control
## NPC 对话框：全屏居中大立绘 + 底部窄条文本（逆转裁判风格）
## 支持多帧动画循环（说话/待机），为 AI 生成动画帧做准备。

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")
const TextUtilsScript = preload("res://scripts/core/TextUtils.gd")
# 字体通过 theme.tres 的 default_font 统一管理，不再硬编码
var UI_FONT: Font = null

@onready var dim_bg: PanelContainer = $DimBg
@onready var box: Control = $Box
@onready var portrait_rect: TextureRect = $Portrait
@onready var speaker_label: Label = $Box/SpeakerName
@onready var text_label: RichTextLabel = $Box/TextLabel
@onready var legacy_options: ScrollContainer = $Box/Options
@onready var options_vbox: VBoxContainer = $Box/Options/OptionsVBox
@onready var exit_btn: Button = $Box/ExitBtn

var _typewriter: Node = null
var _top_options_panel: PanelContainer = null
var _top_options_scroll: ScrollContainer = null
var _top_options_vbox: VBoxContainer = null
var _choice_hint_label: Label = null
var _choice_hint_plate: PanelContainer = null
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
var _avatar_tween: Tween = null
var _current_portrait_display_scale: float = 1.0
var _current_portrait_offset_y: float = 0.0
var _advance_locked_until_msec := 0
var _typewriter_skip_disabled := false
var _next_narration_typewriter_skip_disabled := false
var _next_narration_typewriter_char_delay := -1.0

# ─── 叙述模式 ───
var _narration_mode: bool = false
var _narration_has_next: bool = false

# ─── 立绘显示持久化系统 ───
var _current_center_portrait_speaker: String = ""
var _current_center_portrait_path: String = ""
var _current_center_emotion: String = ""
var _avatar_rect: TextureRect = null
var _speaker_plate: PanelContainer = null

# ─── 动画帧系统 ───
var _talk_frames: Array[Texture2D] = []
var _idle_frames: Array[Texture2D] = []
var _talk_timer: Timer = null
var _talk_frame_index: int = 0
var _is_talking: bool = false
var _talk_bounce_tween: Tween = null
var _blink_timer: Timer = null
var _is_blinking: bool = false

# ─── 全屏演出效果 ───
var _flash_rect: ColorRect = null
var _screen_shake_tween: Tween = null
var _skip_next_portrait_animation: bool = false
const DEFAULT_TYPEWRITER_CHAR_DELAY := 0.04

const CLR_GOLD := Color(0.96, 0.84, 0.46, 1.0)
const CLR_PAPER := Color(0.12, 0.075, 0.04, 0.94)
const CLR_INK := Color(0.92, 0.86, 0.72, 1.0)
const CLR_TIME_CARD := Color(0.46, 1.0, 0.62, 1.0)
const KEYWORD_HIGHLIGHTS := [
	"船板", "撞礁", "暗礁", "水涨", "破洞", "凿痕", "钉眼", "浮囊", "包袱",
	"二两", "十二两", "遣散", "赌债", "四十二两", "不到一刻钟", "半个时辰", "夜船"
]

# 说话动画帧间隔（秒）
const TALK_FRAME_INTERVAL := 0.12
# 无多帧资源时说话微抖动幅度
const TALK_BOUNCE_AMOUNT := 2.0


const DIALOGUE_FRAME_SIDE_MARGIN := 28.0
const DIALOGUE_FRAME_BOTTOM_MARGIN := 18.0
const DIALOGUE_FRAME_HEIGHT := 246.0
const DIALOGUE_TEXT_LEFT_DEFAULT := 48.0
const DIALOGUE_TEXT_LEFT_WITH_AVATAR := 264.0
const DIALOGUE_TEXT_TOP_OFFSET := -224.0
const DIALOGUE_TEXT_BOTTOM_OFFSET := -34.0
const DEFAULT_CENTER_PORTRAIT_FRAME := {
	"offset_left": -320.0,
	"offset_top": 60.0,
	"offset_right": 320.0,
	"offset_bottom": 0.0,
	"pivot_x": 320.0,
}
const AVATAR_SIZE := Vector2(286, 520)
const AVATAR_OFFSET_LEFT := 10.0
const AVATAR_OFFSET_TOP := -520.0
const AVATAR_OFFSET_RIGHT := 296.0
const AVATAR_OFFSET_BOTTOM := 0.0
const PORTRAIT_CROP_PADDING_RATIO := 0.02
const PORTRAIT_CROP_MIN_PADDING := 8
const PORTRAIT_CROP_MIN_HEIGHT_RATIO := 0.78

var _portrait_texture_cache: Dictionary = {}
var _center_portrait_frame: Dictionary = DEFAULT_CENTER_PORTRAIT_FRAME.duplicate(true)


func _ready() -> void:
	# 动态加载字体（避免 preload 在编辑器未导入时失败）
	if ResourceLoader.exists("res://assets/fonts/SourceHanMonoSC-Regular.otf"):
		UI_FONT = load("res://assets/fonts/SourceHanMonoSC-Regular.otf")
	elif ResourceLoader.exists("res://assets/fonts/NotoSerifSC.ttf"):
		UI_FONT = load("res://assets/fonts/NotoSerifSC.ttf")
	elif ResourceLoader.exists("res://assets/fonts/NotoSansSC.otf"):
		UI_FONT = load("res://assets/fonts/NotoSansSC.otf")
	legacy_options.visible = false
	exit_btn.visible = false
	_refresh_center_portrait_frame()
	# ── 立绘区域设置（全屏居中大图） ──
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_rect.anchor_left = 0.5
	portrait_rect.anchor_right = 0.5
	portrait_rect.anchor_top = 0.0
	portrait_rect.anchor_bottom = 1.0
	portrait_rect.offset_left = float(_center_portrait_frame.get("offset_left", -320.0))
	portrait_rect.offset_top = float(_center_portrait_frame.get("offset_top", 60.0))
	portrait_rect.offset_right = float(_center_portrait_frame.get("offset_right", 320.0))
	portrait_rect.offset_bottom = float(_center_portrait_frame.get("offset_bottom", 0.0))
	portrait_rect.pivot_offset = Vector2(float(_center_portrait_frame.get("pivot_x", 320.0)), 330.0)
	# 立绘层级在对话框下面（下半身被对话框自然遮挡）
	move_child(portrait_rect, 0)
	# ── 文本区域设置 ──
	text_label.anchor_bottom = 1.0
	text_label.offset_bottom = -40.0
	text_label.bbcode_enabled = true
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.fit_content = false
	text_label.scroll_active = false
	text_label.custom_minimum_size = Vector2(0, 112)
	# 字体由 theme.tres 的 default_font 统一管理
	text_label.add_theme_font_size_override("normal_font_size", 22)
	text_label.add_theme_color_override("default_color", CLR_INK)
	text_label.add_theme_constant_override("line_separation", 8)
	_build_dialogue_frame()
	_apply_dialogue_chrome()
	_build_choice_hint()
	_build_log_controls()
	_build_top_options_panel()
	_build_flash_rect()
	_setup_talk_timer()
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)
	_setup_avatar_portrait()


func _refresh_center_portrait_frame() -> void:
	_center_portrait_frame = DEFAULT_CENTER_PORTRAIT_FRAME.duplicate(true)
	if AssetResolver != null and AssetResolver.has_method("get_center_portrait_standard_frame"):
		var resolved = AssetResolver.get_center_portrait_standard_frame()
		if typeof(resolved) == TYPE_DICTIONARY and not resolved.is_empty():
			_center_portrait_frame = resolved.duplicate(true)


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
	if _is_advance_locked():
		get_viewport().set_input_as_handled()
		return
	# 文字出字中点击 → 立即显示当前句全文；仅特殊演出可禁用跳过。
	if _typewriter.is_playing():
		if not _typewriter_skip_disabled:
			_typewriter.skip()
		get_viewport().set_input_as_handled()
		return
	# 当前句播完后点击 → 下一句；最后一句播完后才显示选项。
	if _waiting_for_advance:
		_waiting_for_advance = false
		if _narration_mode:
			DialogueManager.narration_advance()
		else:
			_dialogue_page_index += 1
			_play_current_page(_dialogue_run_id)
		get_viewport().set_input_as_handled()


func lock_advance_for(seconds: float) -> void:
	var unlock_at := Time.get_ticks_msec() + int(maxf(seconds, 0.0) * 1000.0)
	_advance_locked_until_msec = maxi(_advance_locked_until_msec, unlock_at)


func _is_advance_locked() -> bool:
	return Time.get_ticks_msec() < _advance_locked_until_msec


func set_next_narration_typewriter_skip_disabled(disabled: bool) -> void:
	_next_narration_typewriter_skip_disabled = disabled
	_next_narration_typewriter_char_delay = -1.0


func set_next_narration_typewriter_settings(skip_disabled: bool, char_delay: float = -1.0) -> void:
	_next_narration_typewriter_skip_disabled = skip_disabled
	_next_narration_typewriter_char_delay = char_delay



# ═══════════════════════════════════════════════════════════════
# ███  叙述模式（替代 NarrationBox）
# ═══════════════════════════════════════════════════════════════

func show_narration(speaker: String, text: String, has_next: bool, portrait: String = "", meta: Dictionary = {}) -> void:
	"""叙述模式：与 DialogueManager 的 narration 信号对接，点击推进"""
	print("[DialogueBox] show_narration called. speaker='%s' has_next=%s run_id=%d" % [speaker, has_next, _dialogue_run_id + 1])
	_narration_mode = true
	_narration_has_next = has_next
	_dialogue_run_id += 1
	_typewriter_skip_disabled = _next_narration_typewriter_skip_disabled
	var custom_char_delay := _next_narration_typewriter_char_delay
	_next_narration_typewriter_skip_disabled = false
	_next_narration_typewriter_char_delay = -1.0
	var my_run_id := _dialogue_run_id
	_hide_options()
	if _log_panel != null:
		_log_panel.visible = false
	_set_choice_hint("", false)
	_waiting_for_advance = false
	var is_time_card := _is_time_card_meta(meta)
	var is_inner_thought := (_is_inner_thought_meta(meta) or _is_mind_voice_speaker(speaker)) and not is_time_card
	if is_time_card:
		_typewriter_skip_disabled = true
		if custom_char_delay <= 0.0:
			custom_char_delay = 0.14
	else:
		# time_card 이외의 행은 무조건 skip 가능으로 초기화
		# (이전 time_card의 disable_typewriter_skip 효과가 전파되지 않도록)
		_typewriter_skip_disabled = false
		if is_inner_thought:
			custom_char_delay = -1.0
	# 去掉多余空行，限制显示不超过3行（约60字）
	var display_text := TextUtilsScript.prepare_dialogue_plain_text(text, is_inner_thought)
	# 如果文字包含换行且超过3行，只显示前3行
	var lines := display_text.split("\n")
	if lines.size() > 3:
		display_text = "\n".join(lines.slice(0, 3))
		if is_inner_thought and display_text.begins_with("（") and not display_text.ends_with("）"):
			display_text += "）"
	var rich_display_text := ""
	if is_time_card:
		rich_display_text = display_text
	elif is_inner_thought:
		rich_display_text = TextUtilsScript.color_inner_thoughts(display_text)
	else:
		rich_display_text = TextUtilsScript.strip_all_parentheticals(display_text)
	if is_time_card:
		_apply_time_card_narration_style()
	else:
		_apply_normal_narration_style()
	var hide_portrait := bool(meta.get("effect", {}).get("hide_portrait", false))
	if is_time_card or is_inner_thought or hide_portrait:
		# 心理活动或明确要求隐藏立绘：只显示说话人名字，不显示头像/立绘
		_apply_narration_speaker(_normalize_visible_speaker(speaker), "", true)
	else:
		_apply_narration_speaker(_normalize_visible_speaker(speaker), portrait)
	_typewriter.base_char_delay = custom_char_delay if custom_char_delay > 0.0 else DEFAULT_TYPEWRITER_CHAR_DELAY
	# 根据说话人角色切换打字音效 profile
	_typewriter.set_blip_profile(_resolve_blip_profile(_normalize_visible_speaker(speaker)))
	# 叙述模式不播放打字电子音（物品描述等场景不需要）
	_typewriter.typing_sound_enabled = false
	# 打字机播放文字（不调用说话动画，避免立绘偏移）
	_typewriter.play(text_label, rich_display_text)
	await _typewriter.finished
	print("[DialogueBox] typewriter finished. my_run_id=%d current_run_id=%d" % [my_run_id, _dialogue_run_id])
	if my_run_id != _dialogue_run_id:
		print("[DialogueBox] !!! RUN ID MISMATCH - another show_narration was called during await!")
		return
	# 文字播放完毕；部分强制衔接段落允许自动推进，避免不同机器上最后一次点击被其他输入层吞掉。
	var effect_meta = meta.get("effect", {})
	var auto_advance_cfg = null
	if typeof(effect_meta) == TYPE_DICTIONARY:
		auto_advance_cfg = effect_meta.get("auto_advance", null)
	var auto_advance_seconds := -1.0
	if typeof(auto_advance_cfg) == TYPE_BOOL and bool(auto_advance_cfg):
		auto_advance_seconds = 0.18
	elif typeof(auto_advance_cfg) == TYPE_INT or typeof(auto_advance_cfg) == TYPE_FLOAT:
		auto_advance_seconds = maxf(float(auto_advance_cfg), 0.0)
	if auto_advance_seconds >= 0.0 and _narration_mode:
		_set_choice_hint("", false)
		_waiting_for_advance = false
		if auto_advance_seconds > 0.0:
			await get_tree().create_timer(auto_advance_seconds).timeout
			if my_run_id != _dialogue_run_id:
				return
		DialogueManager.narration_advance()
		return
	var hint := "▼ 点击继续" if has_next or is_time_card else "▼ 点击进入游戏"
	_set_choice_hint(hint, true)
	_waiting_for_advance = true
	print("[DialogueBox] _waiting_for_advance = true")


## 检测是否为心理活动（心声）说话者标记
func _is_mind_voice_speaker(speaker: String) -> bool:
	var s := speaker.strip_edges()
	if s == "心声" or s.ends_with("·心声") or s.ends_with("· 心声"):
		return true
	if s.begins_with("心声") and s.length() > 2:
		return true
	# 支持 CSV 中用 "mind_voice" 标记
	if s.to_lower() == "mind_voice" or s.to_lower().ends_with(":mind_voice"):
		return true
	return false


func _is_inner_thought_meta(meta: Dictionary) -> bool:
	var line_type := str(meta.get("type", "")).strip_edges().to_lower()
	var emotion := str(meta.get("emotion", meta.get("mood", ""))).strip_edges().to_lower()
	return line_type == "inner_thought" or emotion == "inner_thought"


func _is_time_card_meta(meta: Dictionary) -> bool:
	var line_type := str(meta.get("type", "")).strip_edges().to_lower()
	var effect = meta.get("effect", {})
	var effect_is_time_card := typeof(effect) == TYPE_DICTIONARY and bool(effect.get("time_card", false))
	return line_type == "time_card" or effect_is_time_card


func _is_inner_thought_page(page: Dictionary) -> bool:
	return _is_inner_thought_meta(page) or _is_mind_voice_speaker(str(page.get("speaker", "")))


## 恢复普通叙述模式的文字样式
func _apply_normal_narration_style() -> void:
	text_label.add_theme_color_override("default_color", CLR_INK)
	text_label.add_theme_font_size_override("normal_font_size", 22)
	speaker_label.add_theme_color_override("font_color", CLR_INK)


func _apply_time_card_narration_style() -> void:
	text_label.add_theme_color_override("default_color", CLR_TIME_CARD)
	text_label.add_theme_font_size_override("normal_font_size", 24)
	speaker_label.add_theme_color_override("font_color", CLR_TIME_CARD)


func _apply_narration_speaker(speaker: String, portrait: String, force_hide_portrait: bool = false) -> void:
	"""叙述模式的说话者/立绘处理"""
	_set_speaker_name(speaker)
	if speaker == "":
		# 纯叙述：无立绘
		portrait_rect.visible = false
		_hide_avatar()
		return
	# 主角陆昭：非对峙阶段只显示名字，不显示头像/立绘
	# 对峙阶段由 ConfrontationPanel 独立渲染，不经过此函数
	if speaker == "陆昭" or speaker == "lu_zhao":
		portrait_rect.visible = false
		_hide_avatar()
		return
	# hide_portrait 效果：强制不显示任何立绘
	if force_hide_portrait:
		portrait_rect.visible = false
		_hide_avatar()
		return
	# 如果没有提供 portrait，尝试自动解析
	var resolved := portrait
	if resolved == "" or not ResourceLoader.exists(resolved):
		resolved = _resolve_portrait_for_speaker(speaker)
	# 有说话者：走立绘规则
	# 注意：portrait 由外部明确传入（非自动解析）时，优先居中显示，不走同伴头像路径
	# 这用于处理 ??? 说话人但实际是 NPC（如沈清月初登场）的情况
	var portrait_was_explicit := portrait != "" and ResourceLoader.exists(portrait)
	if _is_protagonist_or_companion(speaker) and not portrait_was_explicit:
		# 同伴（非讨论模式）→ 左下角头像
		_show_avatar(speaker, resolved, "")
		portrait_rect.visible = false
	elif resolved != "" and ResourceLoader.exists(resolved):
		# 指定了立绘 → 居中显示
		_apply_center_portrait_presentation(_resolve_npc_id_for_speaker(speaker), resolved, "")
		portrait_rect.visible = _set_portrait_texture(portrait_rect, resolved)
		portrait_rect.modulate.a = 1.0
		portrait_rect.scale = Vector2(_current_portrait_display_scale, _current_portrait_display_scale)
		_hide_avatar()
	else:
		_current_portrait_display_scale = 1.0
		portrait_rect.visible = false
		_hide_avatar()


func _set_speaker_name(speaker: String) -> void:
	var visible_speaker := _normalize_visible_speaker(speaker)
	var has_speaker := visible_speaker != ""
	speaker_label.text = visible_speaker
	speaker_label.visible = has_speaker
	if _speaker_plate != null:
		_speaker_plate.visible = has_speaker
	# 名字直接写在对话框内：有名字时正文下移，避免重叠。
	text_label.offset_top = 52.0 if has_speaker else 18.0


## 根据说话者名字解析打字音效 profile
func _resolve_blip_profile(speaker: String) -> String:
	var visible_speaker := _normalize_visible_speaker(speaker)
	if visible_speaker == "":
		return "default"
	if visible_speaker == "陆昭" or visible_speaker == "lu_zhao":
		return "default"
	var reg_path := "res://data/actors/registry.json"
	var actors: Dictionary = {}
	if ResourceLoader.exists(reg_path):
		var reg_data = load(reg_path)
		if reg_data is Dictionary:
			actors = reg_data.get("actors", {})
	var casting: Dictionary = AssetResolver.get_casting()
	var actor_id: String = ""
	for npc_id in casting.keys():
		var entry = casting[npc_id]
		if typeof(entry) == TYPE_DICTIONARY:
			if entry.get("role_name", "") == visible_speaker:
				actor_id = entry.get("actor_id", "")
				break
	if actor_id == "" and actors.has(visible_speaker):
		actor_id = visible_speaker
	if actor_id == "" or not actors.has(actor_id):
		return "default"
	var actor: Dictionary = actors[actor_id]
	var tags: Array = actor.get("tags", [])
	if "male" in tags:
		if "rough" in tags or "constable" in tags:
			return "male_rough"
		if "young" in tags or "young_teen" in tags:
			return "male_young"
		if "elder" in tags:
			return "male_elder"
		return "male_middle"
	elif "female" in tags:
		if "young" in tags or "young_teen" in tags:
			return "female_young"
		if "elder" in tags:
			return "female_elder"
		return "female_middle"
	return "default"


func _resolve_portrait_for_speaker(speaker_name: String) -> String:
	"""根据说话者名字解析立绘路径"""
	speaker_name = _normalize_visible_speaker(speaker_name)
	if speaker_name == "":
		return ""
	# ??? 是同伴（凌瑶）的隐藏身份：只有当前同伴确实是凌瑶时才走同伴路径
	var lookup_name := speaker_name
	if speaker_name == "???":
		var cs2 = get_node_or_null("/root/CompanionService")
		if cs2 and cs2.has_method("get_companion_role_name"):
			lookup_name = cs2.get_companion_role_name()
		if lookup_name == "???":
			return ""
	# 助手
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("get_companion_role_name"):
		var companion_name: String = cs.get_companion_role_name()
		if companion_name != "" and lookup_name == companion_name:
			return cs.get_companion_portrait()
	# 通过 casting 查找 NPC
	var casting: Dictionary = AssetResolver.get_casting()
	for npc_id in casting.keys():
		var entry = casting[npc_id]
		if typeof(entry) == TYPE_DICTIONARY:
			if entry.get("role_name", "") == speaker_name:
				return AssetResolver.get_portrait(npc_id, GameManager.npcs_data)
	return ""


func _resolve_npc_id_for_speaker(speaker_name: String) -> String:
	var visible_name := _normalize_visible_speaker(speaker_name)
	if visible_name == "":
		return ""
	if visible_name == "陆昭" or visible_name == "你" or visible_name == "lu_zhao":
		return "lu_zhao"
	if visible_name == "凌瑶" or visible_name == "xia_lingyao" or visible_name == "lingyao":
		return "xia_lingyao"
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("get_companion_role_name"):
		var companion_name: String = cs.get_companion_role_name()
		if companion_name != "" and visible_name == companion_name:
			if cs.has_method("get_companion_id"):
				var companion_id := str(cs.get_companion_id())
				if companion_id != "":
					return companion_id
			return "xia_lingyao"
	var casting: Dictionary = AssetResolver.get_casting()
	if casting.has(visible_name):
		return visible_name
	for npc_id in casting.keys():
		var entry = casting[npc_id]
		if typeof(entry) == TYPE_DICTIONARY and entry.get("role_name", "") == visible_name:
			return str(npc_id)
	return ""


func show_narration_choices(choices: Array) -> void:
	"""显示叙述选项（复用 TopOptionsPanel）"""
	_set_choice_hint("", false)
	_waiting_for_advance = false
	_hide_options()
	var visible_count := 0
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		# 过滤不满足条件的选项（与 NarrationBox._show_choices 保持一致）
		if choice.has("requires") and not GameManager.evaluate_condition(choice["requires"]):
			continue
		var btn := _make_option_button(choice.get("text", ""), {})
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := i
		btn.pressed.connect(func():
			_hide_options()
			DialogueManager.narration_choose(idx)
		)
		_top_options_vbox.add_child(btn)
		visible_count += 1
	_position_top_options(visible_count)
	_top_options_panel.visible = true


func clear_for_transition() -> void:
	"""打断当前打字与显示，避免时间卡或强制切场时闪出旧文本。"""
	_dialogue_run_id += 1
	_waiting_for_advance = false
	_typewriter_skip_disabled = false
	_next_narration_typewriter_skip_disabled = false
	_next_narration_typewriter_char_delay = -1.0
	_hide_options()
	_set_choice_hint("", false)
	if _typewriter != null and _typewriter.is_playing():
		_typewriter.skip()
	_stop_talk_animation()
	text_label.text = ""
	text_label.visible_characters = -1
	_set_speaker_name("")
	portrait_rect.visible = false
	_hide_avatar()


func end_narration_mode() -> void:
	"""退出叙述模式"""
	_narration_mode = false
	_narration_has_next = false
	_waiting_for_advance = false
	_typewriter_skip_disabled = false
	_next_narration_typewriter_skip_disabled = false
	_next_narration_typewriter_char_delay = -1.0
	if _typewriter:
		_typewriter.base_char_delay = DEFAULT_TYPEWRITER_CHAR_DELAY
	_apply_normal_narration_style()
	_hide_options()
	portrait_rect.visible = false
	_hide_avatar()



## 跳过下一次立绘入场动画（NPC 已在 NpcSceneLayer 可见时调用）
func skip_portrait_intro() -> void:
	_skip_next_portrait_animation = true


func show_dialogue(speaker: String, portrait_path: String, text: String, options: Array, pages: Array = []) -> void:
	_narration_mode = false
	_dialogue_run_id += 1
	_typewriter_skip_disabled = false
	_next_narration_typewriter_skip_disabled = false
	_next_narration_typewriter_char_delay = -1.0
	if _typewriter:
		_typewriter.base_char_delay = DEFAULT_TYPEWRITER_CHAR_DELAY
	_hide_options()
	if _log_panel != null:
		_log_panel.visible = false
	_set_choice_hint("", false)
	_waiting_for_advance = false
	_dialogue_options = options
	_dialogue_pages = _build_dialogue_pages(speaker, portrait_path, text, pages)
	if _dialogue_pages.is_empty():
		_show_dialogue_options_only(speaker, portrait_path)
		return
	_dialogue_page_index = 0
	_play_current_page(_dialogue_run_id)


func _show_dialogue_options_only(speaker: String, portrait_path: String) -> void:
	_apply_speaker(speaker, portrait_path, "")
	_stop_talk_animation()
	text_label.text = ""
	text_label.visible_characters = -1
	_set_choice_hint("▼ 请选择回应", true)
	_show_options(_dialogue_options)


func _play_current_page(run_id: int) -> void:
	if run_id != _dialogue_run_id:
		return
	if _dialogue_pages.is_empty() or _dialogue_page_index >= _dialogue_pages.size():
		return
	_hide_options()
	_set_choice_hint("", false)
	_waiting_for_advance = false
	var page: Dictionary = _dialogue_pages[_dialogue_page_index]
	var page_is_inner_thought := _is_inner_thought_page(page)
	if page_is_inner_thought:
		# 心理活动显示主角名字（不显示头像），与 show_narration 保持一致
		_apply_speaker(page.get("speaker", ""), "", "")
	else:
		_apply_speaker(page.get("speaker", ""), page.get("portrait", ""), page.get("emotion", ""))
	var page_text: String = page.get("text", "")
	var display_page_text := TextUtilsScript.prepare_dialogue_plain_text(page_text, page_is_inner_thought)
	var log_speaker := "" if page_is_inner_thought else str(page.get("speaker", ""))
	_append_dialogue_log(log_speaker, display_page_text)
	_typewriter.set_blip_profile(_resolve_blip_profile(page.get("speaker", "")))
	if not page_is_inner_thought:
		_start_talk_animation()
	# 基于 display_page_text（已完成括号处理）只做高亮+染色，避免重复调 prepare_dialogue_plain_text 导致双重括号
	var play_text := _highlight_and_color_text(display_page_text, page.get("highlight", []), page_is_inner_thought)
	_typewriter.play(text_label, play_text)
	await _typewriter.finished
	_stop_talk_animation()
	if run_id != _dialogue_run_id:
		return
	if _page_has_record(page):
		_record_page_to_notebook(page)
		await _play_record_fx(page)
	if run_id != _dialogue_run_id:
		return
	if _dialogue_page_index < _dialogue_pages.size() - 1:
		_set_choice_hint("▼ 点击继续", true)
		_waiting_for_advance = true
	else:
		_set_choice_hint("▼ 请选择回应", true)
		_show_options(_dialogue_options)


# ═══════════════════════════════════════════════════════════════
# ███  全屏居中角色展示（逆转裁判风格）
# ═══════════════════════════════════════════════════════════════

func _apply_speaker(speaker: String, portrait_path: String, emotion: String = "") -> void:
	_set_speaker_name(speaker)
	if speaker == "":
		# narrator 行：隐藏所有头像/立绘，只留纯文字
		_hide_avatar()
		portrait_rect.visible = false
		return
	# DialogueBox 不属于对峙阶段，陆昭在此只显示名字，不显示头像
	# 对峙阶段由 ConfrontationPanel 独立渲染，不经过此函数
	if speaker == "陆昭" or speaker == "lu_zhao":
		_hide_avatar()
		# 保持 NPC 居中立绘显示（如果已设置），不隐藏
		box.offset_left = DIALOGUE_TEXT_LEFT_DEFAULT
		_last_speaker = speaker
		return
	# 主角/同伴：左下角头像 + 文字右移（仅叙述模式或对峙内调用）
	if _is_protagonist_or_companion(speaker):
		_last_speaker = speaker
		_show_avatar(speaker, portrait_path, emotion)
		return

	# NPC：居中立绘 + 底部对话框
	var _resolved_portrait := _resolve_emotion_portrait(portrait_path, emotion)
	var was_returning_from_companion = _is_protagonist_or_companion(_last_speaker) and speaker == _current_center_portrait_speaker
	_current_center_portrait_speaker = speaker
	_current_center_portrait_path = portrait_path
	_current_center_emotion = emotion
	var _changed := not was_returning_from_companion and (speaker != _last_speaker or emotion != _last_emotion)
	_last_speaker = speaker
	_last_emotion = emotion
	_load_animation_frames(portrait_path, emotion)
	_hide_avatar()  # 切换回 NPC 时隐藏头像
	# 显示 NPC 居中立绘
	var scale_value := _apply_center_portrait_presentation(_resolve_npc_id_for_speaker(speaker), _resolved_portrait, emotion)
	_current_portrait_display_scale = scale_value
	var target_scale := Vector2(scale_value, scale_value)
	if _resolved_portrait != "" and ResourceLoader.exists(_resolved_portrait):
		portrait_rect.visible = _set_portrait_texture(portrait_rect, _resolved_portrait)
		if _skip_next_portrait_animation:
			# NPC 已在场景层可见，直接显示不做动画（避免拖动/跳动感）
			_skip_next_portrait_animation = false
		portrait_rect.modulate.a = 1.0
		portrait_rect.scale = target_scale
		if _portrait_tween != null and _portrait_tween.is_valid():
			_portrait_tween.kill()
	elif _changed:
		portrait_rect.modulate.a = 0.0
		portrait_rect.scale = target_scale * 0.96
		if _portrait_tween != null and _portrait_tween.is_valid():
			_portrait_tween.kill()
		_portrait_tween = create_tween()
		_portrait_tween.set_parallel(true)
		_portrait_tween.tween_property(portrait_rect, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_portrait_tween.tween_property(portrait_rect, "scale", target_scale, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		if portrait_rect.modulate.a < 1.0:
			if _portrait_tween != null and _portrait_tween.is_valid():
				_portrait_tween.kill()
			_portrait_tween = create_tween()
			_portrait_tween.tween_property(portrait_rect, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _apply_center_portrait_presentation(npc_id: String, portrait_path: String, emotion: String) -> float:
	var presentation := AssetResolver.get_center_portrait_surface_presentation("dialogue", npc_id, emotion, portrait_path)
	_current_portrait_display_scale = float(presentation.get("screen_scale", 1.0))
	_current_portrait_offset_y = float(presentation.get("offset_y", 0.0))
	portrait_rect.pivot_offset = Vector2(float(_center_portrait_frame.get("pivot_x", 320.0)), float(presentation.get("pivot_y", 330.0)))
	portrait_rect.offset_left = float(_center_portrait_frame.get("offset_left", -320.0))
	portrait_rect.offset_top = float(_center_portrait_frame.get("offset_top", 60.0)) + _current_portrait_offset_y
	portrait_rect.offset_right = float(_center_portrait_frame.get("offset_right", 320.0))
	portrait_rect.offset_bottom = float(_center_portrait_frame.get("offset_bottom", 0.0)) + _current_portrait_offset_y
	return _current_portrait_display_scale


# ═══════════════════════════════════════════════════════════════
# ███  立绘显示持久化系统辅助方法
# ═══════════════════════════════════════════════════════════════

func _setup_avatar_portrait() -> void:
	"""创建大立绘显示区域（用于主角/同伴），显示在画面左下角，带边缘渐隐"""
	if _avatar_rect != null:
		return
	_avatar_rect = TextureRect.new()
	_avatar_rect.name = "AvatarPortrait"
	_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_avatar_rect.custom_minimum_size = AVATAR_SIZE
	_avatar_rect.modulate.a = 0.0
	_avatar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 位置：画面左下角大立绘（较小尺寸，不遮挡文字）
	_avatar_rect.anchor_left = 0.0
	_avatar_rect.anchor_top = 1.0
	_avatar_rect.anchor_right = 0.0
	_avatar_rect.anchor_bottom = 1.0
	_avatar_rect.offset_left = AVATAR_OFFSET_LEFT
	_avatar_rect.offset_top = AVATAR_OFFSET_TOP
	_avatar_rect.offset_right = AVATAR_OFFSET_RIGHT
	_avatar_rect.offset_bottom = AVATAR_OFFSET_BOTTOM
	_avatar_rect.pivot_offset = Vector2(AVATAR_SIZE.x * 0.5, AVATAR_SIZE.y)
	# 应用边缘渐隐 shader（与 NPC 立绘相同的 portrait_fade.gdshader）
	var shader = load("res://assets/cn/portrait_fade.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("fade_bottom", 0.25)
		mat.set_shader_parameter("fade_top", 0.0)
		mat.set_shader_parameter("fade_left", 0.0)
		mat.set_shader_parameter("fade_right", 0.18)
		_avatar_rect.material = mat
	# 插入到 DimBg 和 Box 之间（在暗背景之上，不影响文字渲染）
	add_child(_avatar_rect)
	var dim_idx := dim_bg.get_index()
	move_child(_avatar_rect, dim_idx + 1)


func _is_protagonist_or_companion(speaker_name: String) -> bool:
	"""检查说话者是否为主角或同伴"""
	if speaker_name == "陆昭" or speaker_name == "lu_zhao":
		return true
	# ??? 是同伴（凌瑶）的隐藏身份：只有当前同伴确实是凌瑶时才走同伴头像路径
	if speaker_name == "???":
		var companion_role := CompanionService.get_companion_role_name()
		return companion_role == "凌瑶"
	# 讨论模式下，助手作为"NPC角色"居中显示，不走头像路径
	if DialogueManager.is_discuss_mode():
		return false
	var companion_role_name = CompanionService.get_companion_role_name()
	var companion_id = CompanionService.get_companion_id()
	if speaker_name == companion_role_name or speaker_name == companion_id:
		return true
	return false



func _show_avatar(_speaker: String, portrait_path: String, emotion: String = "") -> void:
	"""显示主角/同伴的立绘（画面左下角），无动画直接显示"""
	if _avatar_rect == null:
		return
	var resolved_portrait := _resolve_emotion_portrait(portrait_path, emotion)
	if resolved_portrait != "" and ResourceLoader.exists(resolved_portrait):
		if not _set_portrait_texture(_avatar_rect, resolved_portrait):
			return
		# NPC中央立绘略微变暗
		if portrait_rect.visible:
			portrait_rect.modulate.a = 0.5
		# 右移文字区域给立绘腾空间
		box.offset_left = DIALOGUE_TEXT_LEFT_WITH_AVATAR
		# 直接显示头像（无动画）
		_avatar_rect.modulate.a = 1.0
		_avatar_rect.scale = Vector2(1.0, 1.0)

func _hide_avatar() -> void:
	"""隐藏主角/同伴立绘，恢复文字位置"""
	if _avatar_rect == null or _avatar_rect.modulate.a < 0.01:
		return
	_avatar_rect.modulate.a = 0.0
	# 恢复文字区域到原始位置
	box.offset_left = DIALOGUE_TEXT_LEFT_DEFAULT


# ═══════════════════════════════════════════════════════════════
# ███  说话动画帧系统
# ═══════════════════════════════════════════════════════════════

func _setup_talk_timer() -> void:
	_talk_timer = Timer.new()
	_talk_timer.wait_time = TALK_FRAME_INTERVAL
	_talk_timer.one_shot = false
	_talk_timer.timeout.connect(_on_talk_frame_tick)
	add_child(_talk_timer)
	# 眨眼定时器
	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_do_blink)
	add_child(_blink_timer)


func _load_animation_frames(base_path: String, _emotion: String) -> void:
	_talk_frames.clear()
	_idle_frames.clear()
	if base_path == "":
		return
	# 尝试加载说话帧：actor_xxx_talk_0.png, _talk_1.png ...
	var talk_base := base_path.replace(".png", "_talk_%d.png")
	for i in range(10):
		var path := talk_base % i
		if ResourceLoader.exists(path):
			var frame := _load_normalized_portrait_texture(path)
			if frame != null:
				_talk_frames.append(frame)
		else:
			break
	# 尝试加载待机帧：actor_xxx_idle_0.png, _idle_1.png ...
	var idle_base := base_path.replace(".png", "_idle_%d.png")
	for i in range(10):
		var path := idle_base % i
		if ResourceLoader.exists(path):
			var frame := _load_normalized_portrait_texture(path)
			if frame != null:
				_idle_frames.append(frame)
		else:
			break


func _start_talk_animation() -> void:
	_is_talking = true
	_stop_blink_loop()
	if not _talk_frames.is_empty():
		# 有多帧说话动画 → 帧循环
		_talk_frame_index = 0
		_talk_timer.start()
	else:
		# 无多帧 → 微幅抖动模拟说话
		_start_talk_bounce()


func _stop_talk_animation() -> void:
	_is_talking = false
	_talk_timer.stop()
	_stop_talk_bounce()
	# 切回待机帧（如果有）并启动眨眼循环
	if not _idle_frames.is_empty():
		portrait_rect.texture = _idle_frames[0]
		_start_blink_loop()


func _on_talk_frame_tick() -> void:
	if _talk_frames.is_empty() or not _is_talking:
		_talk_timer.stop()
		return
	_talk_frame_index = (_talk_frame_index + 1) % _talk_frames.size()
	portrait_rect.texture = _talk_frames[_talk_frame_index]


func _start_talk_bounce() -> void:
	# 禁用说话抖动 — 立绘保持静止
	pass


func _stop_talk_bounce() -> void:
	if _talk_bounce_tween != null and _talk_bounce_tween.is_valid():
		_talk_bounce_tween.kill()
		_talk_bounce_tween = null


## 眨眼循环：每 2-4 秒眨一次眼
func _start_blink_loop() -> void:
	_is_blinking = false
	if _idle_frames.size() < 2:
		return
	var delay := randf_range(2.0, 4.0)
	_blink_timer.start(delay)


func _stop_blink_loop() -> void:
	_blink_timer.stop()
	_is_blinking = false


func _do_blink() -> void:
	if _is_talking or not visible or _idle_frames.size() < 2:
		return
	_is_blinking = true
	# 显示闭眼帧
	portrait_rect.texture = _idle_frames[1]
	# 0.12 秒后恢复睁眼
	await get_tree().create_timer(0.12).timeout
	if not _is_talking and visible and not _idle_frames.is_empty():
		portrait_rect.texture = _idle_frames[0]
	_is_blinking = false
	# 安排下一次眨眼
	if not _is_talking and visible and _idle_frames.size() >= 2:
		var next_delay := randf_range(2.5, 5.0)
		_blink_timer.start(next_delay)


# ═══════════════════════════════════════════════════════════════
# ███  全屏演出效果
# ═══════════════════════════════════════════════════════════════

func _build_flash_rect() -> void:
	_flash_rect = ColorRect.new()
	_flash_rect.name = "FlashOverlay"
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.z_index = 50
	add_child(_flash_rect)


## 全屏闪白/闪红（追问命中时）
func flash_screen(color: Color = Color.WHITE, duration: float = 0.15) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, 0.6)
	var tw := create_tween()
	tw.tween_property(_flash_rect, "color:a", 0.0, duration)


## 角色震动（揭穿谎言时）
func shake_character(intensity: float = 8.0, duration: float = 0.5) -> void:
	if _screen_shake_tween != null and _screen_shake_tween.is_valid():
		_screen_shake_tween.kill()
	var original_x := portrait_rect.position.x
	_screen_shake_tween = create_tween()
	var steps := int(duration / 0.06)
	for i in range(steps):
		var offset: float = intensity * (1.0 if i % 2 == 0 else -1.0) * (1.0 - float(i) / steps)
		_screen_shake_tween.tween_property(portrait_rect, "position:x", original_x + offset, 0.06)
	_screen_shake_tween.tween_property(portrait_rect, "position:x", original_x, 0.06)


## 角色特写放大（情绪高潮时）
func zoom_character(target_scale: float = 1.08, duration: float = 0.3) -> void:
	var tw := create_tween()
	var base_scale := _current_portrait_display_scale
	tw.tween_property(portrait_rect, "scale", Vector2(base_scale * target_scale, base_scale * target_scale), duration * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(portrait_rect, "scale", Vector2(base_scale, base_scale), duration * 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


# ═══════════════════════════════════════════════════════════════
# ███  底部文本框外观
# ═══════════════════════════════════════════════════════════════

func _build_dialogue_frame() -> void:
	if _speaker_plate != null:
		return
	_speaker_plate = PanelContainer.new()
	_speaker_plate.name = "SpeakerPlate"
	_speaker_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 名字直接写在对话框内，不再浮出独立名字牌。
	_speaker_plate.anchor_left = 0.0
	_speaker_plate.anchor_top = 0.0
	_speaker_plate.anchor_right = 0.0
	_speaker_plate.anchor_bottom = 0.0
	_speaker_plate.offset_left = 18.0
	_speaker_plate.offset_top = 6.0
	_speaker_plate.offset_right = 300.0
	_speaker_plate.offset_bottom = 42.0
	# 名字不再显示独立框，只保留文字；PanelContainer 仅用于跟随可见性和布局。
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color(0, 0, 0, 0)
	plate_style.border_width_left = 0
	plate_style.border_width_top = 0
	plate_style.border_width_right = 0
	plate_style.border_width_bottom = 0
	plate_style.content_margin_left = 0
	plate_style.content_margin_right = 0
	plate_style.content_margin_top = 0
	plate_style.content_margin_bottom = 0
	_speaker_plate.add_theme_stylebox_override("panel", plate_style)
	_speaker_plate.visible = false
	box.add_child(_speaker_plate)
	# Reparent speaker_label inside the plate so the plate auto-sizes to the name
	if speaker_label.get_parent() != null:
		speaker_label.get_parent().remove_child(speaker_label)
	# 解除原 anchor/offset，由 PanelContainer 自己布局
	speaker_label.anchor_left = 0
	speaker_label.anchor_top = 0
	speaker_label.anchor_right = 0
	speaker_label.anchor_bottom = 0
	speaker_label.offset_left = 0
	speaker_label.offset_top = 0
	speaker_label.offset_right = 0
	speaker_label.offset_bottom = 0
	_speaker_plate.add_child(speaker_label)
	# Plate visibility follows speaker_label
	speaker_label.visibility_changed.connect(func() -> void:
		_speaker_plate.visible = speaker_label.visible and speaker_label.text != ""
	)


func _apply_dialogue_chrome() -> void:
	dim_bg.offset_left = DIALOGUE_FRAME_SIDE_MARGIN
	dim_bg.offset_top = -(DIALOGUE_FRAME_HEIGHT + DIALOGUE_FRAME_BOTTOM_MARGIN)
	dim_bg.offset_right = -DIALOGUE_FRAME_SIDE_MARGIN
	dim_bg.offset_bottom = -DIALOGUE_FRAME_BOTTOM_MARGIN
	var bg_style := _make_shell_style(
		Color(0.035, 0.022, 0.012, 0.94),
		Color(0.76, 0.58, 0.26, 0.78),
		Color(0, 0, 0, 0.42),
		20,
		22
	)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 3
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.content_margin_left = 20
	bg_style.content_margin_right = 22
	bg_style.content_margin_top = 16
	bg_style.content_margin_bottom = 16
	dim_bg.add_theme_stylebox_override("panel", bg_style)

	box.offset_left = DIALOGUE_TEXT_LEFT_DEFAULT
	box.offset_top = DIALOGUE_TEXT_TOP_OFFSET
	box.offset_right = -42.0
	box.offset_bottom = DIALOGUE_TEXT_BOTTOM_OFFSET

	# speaker_label 的位置由 _build_dialogue_frame 中的透明 SpeakerPlate 自动布局。
	speaker_label.add_theme_font_size_override("font_size", 22)
	speaker_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.56, 1.0))
	speaker_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.84))
	speaker_label.add_theme_constant_override("outline_size", 2)

	# 正文默认顶部留白；显示说话人时由 _set_speaker_name() 下移。
	text_label.offset_left = 24.0
	text_label.offset_top = 22.0
	text_label.offset_right = -28.0
	text_label.offset_bottom = -32.0
	# 字体由 theme.tres 的 default_font 统一管理
	text_label.add_theme_font_size_override("normal_font_size", 21)
	text_label.add_theme_color_override("default_color", Color(0.95, 0.90, 0.78, 1.0))
	text_label.add_theme_constant_override("line_separation", 8)



func _make_shell_style(bg: Color, border: Color, shadow: Color, shadow_size: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 3
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(radius)
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 20
	return style


func _make_badge_style(bg: Color, border: Color, shadow: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 2
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _build_choice_hint() -> void:
	_choice_hint_plate = null
	_choice_hint_label = Label.new()
	_choice_hint_label.text = "▼ 请选择回应"
	_choice_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_hint_label.anchor_left = 0.0
	_choice_hint_label.anchor_top = 1.0
	_choice_hint_label.anchor_right = 1.0
	_choice_hint_label.anchor_bottom = 1.0
	_choice_hint_label.offset_left = 0.0
	_choice_hint_label.offset_top = -34.0
	_choice_hint_label.offset_right = -8.0
	_choice_hint_label.offset_bottom = -6.0
	_choice_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_choice_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_choice_hint_label.add_theme_font_size_override("font_size", 16)
	_choice_hint_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.60, 0.80))
	_choice_hint_label.add_theme_constant_override("outline_size", 0)
	_choice_hint_label.visible = false
	box.add_child(_choice_hint_label)


func _set_choice_hint(text: String, is_visible: bool) -> void:
	if _choice_hint_label != null:
		if text != "":
			_choice_hint_label.text = text
	if _choice_hint_plate != null:
		_choice_hint_plate.visible = is_visible
	elif _choice_hint_label != null:
		_choice_hint_label.visible = is_visible


func _build_log_controls() -> void:
	_log_button = Button.new()
	_log_button.text = "卷宗回看"
	_log_button.anchor_left = 1.0
	_log_button.anchor_right = 1.0
	_log_button.offset_left = -142.0
	_log_button.offset_top = 6.0
	_log_button.offset_right = -6.0
	_log_button.offset_bottom = 42.0
	_log_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_log_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_log_button.z_index = 20
	_log_button.add_theme_font_size_override("font_size", 15)
	_log_button.add_theme_color_override("font_color", Color(0.94, 0.84, 0.62, 0.96))
	_log_button.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.84))
	_log_button.add_theme_constant_override("outline_size", 2)
	_log_button.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_toggle_dialogue_log()
			_log_button.accept_event()
	)
	_apply_plain_button_style(_log_button, Color(0.09, 0.055, 0.025, 0.94), Color(0.72, 0.54, 0.22, 0.72))
	_log_button.visible = false
	box.add_child(_log_button)

	_log_panel = PanelContainer.new()
	_log_panel.name = "DialogueLogPanel"
	_log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_log_panel.anchor_left = 1.0
	_log_panel.anchor_top = 0.0
	_log_panel.anchor_right = 1.0
	_log_panel.anchor_bottom = 0.0
	_log_panel.offset_left = -540.0
	_log_panel.offset_top = -404.0
	_log_panel.offset_right = -24.0
	_log_panel.offset_bottom = -24.0
	_log_panel.visible = false
	_log_panel.add_theme_stylebox_override("panel", _make_shell_style(
		Color(0.055, 0.034, 0.018, 0.97),
		Color(0.84, 0.62, 0.24, 0.78),
		Color(0, 0, 0, 0.60),
		28,
		20
	))
	add_child(_log_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_log_panel.add_child(vbox)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vbox.add_child(hb)
	var title := Label.new()
	title.text = "对话卷宗"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", CLR_GOLD)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.88))
	title.add_theme_constant_override("outline_size", 2)
	hb.add_child(title)
	var close := Button.new()
	close.text = "收起"
	close.add_theme_font_size_override("font_size", 14)
	close.pressed.connect(func(): _log_panel.visible = false)
	_apply_plain_button_style(close, Color(0.10, 0.06, 0.03, 0.94), Color(0.70, 0.52, 0.20, 0.68))
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
	_log_text.add_theme_color_override("default_color", Color(0.92, 0.86, 0.74, 1.0))
	_log_text.add_theme_constant_override("line_separation", 8)
	scroll.add_child(_log_text)


func _build_top_options_panel() -> void:
	_top_options_panel = PanelContainer.new()
	_top_options_panel.name = "TopOptionsPanel"
	_top_options_panel.mouse_filter = Control.MOUSE_FILTER_STOP
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

	_top_options_scroll = ScrollContainer.new()
	_top_options_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(_top_options_scroll)

	_top_options_vbox = VBoxContainer.new()
	_top_options_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_options_vbox.add_theme_constant_override("separation", 12)
	_top_options_scroll.add_child(_top_options_vbox)
	_top_options_panel.visible = false


func _position_top_options(option_count: int) -> void:
	var vp := get_viewport_rect().size
	var panel_w: float = minf(vp.x - 48.0, minf(920.0, maxf(720.0, vp.x * 0.70)))
	var btn_height: float = 60.0
	var separation: int = 12
	if option_count > 6:
		btn_height = 54.0
		separation = 9
	_top_options_vbox.add_theme_constant_override("separation", separation)
	for child in _top_options_vbox.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0, btn_height)
	var visible_count: int = option_count if option_count > 0 else 1
	var panel_h: float = minf(380.0, float(visible_count) * btn_height + float(maxi(0, visible_count - 1) * separation))
	_top_options_panel.size = Vector2(panel_w, panel_h)
	if _top_options_scroll:
		_top_options_scroll.custom_minimum_size = Vector2(panel_w, panel_h)
	var dialogue_box_top: float = dim_bg.get_rect().position.y
	var target_y: float = dialogue_box_top - panel_h - 22.0
	if target_y < 24.0:
		target_y = 24.0
	# 选项面板居中于对话框区域（box 可能因陆昭/头像设置而有偏移）
	var target_x: float = box.global_position.x + (box.size.x - panel_w) / 2.0
	target_x = clampf(target_x, 24.0, vp.x - panel_w - 24.0)
	_top_options_panel.position = Vector2(target_x, target_y)


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
	var action_items: Array = []
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var goto_val: String = opt.get("goto", "")
		if goto_val == "__exit__":
			continue
		var option_text: String = opt.get("text", "")
		if opt.get("_visited", false):
			option_text = "✓ 已完成 " + option_text
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
		_set_choice_hint("", false)
		DialogueManager.end_dialogue(false)
	)
	_top_options_vbox.add_child(close_btn)
	visible_count += 1
	_position_top_options(visible_count)
	_top_options_panel.visible = true
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
		row.add_child(_make_option_group("追问", action_items))
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
	group.add_theme_stylebox_override("panel", _make_shell_style(
		Color(0.055, 0.034, 0.018, 0.82),
		Color(0.68, 0.50, 0.20, 0.56),
		Color(0, 0, 0, 0.22),
		12,
		18
	))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	group.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48, 0.96))
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.88))
	title.add_theme_constant_override("outline_size", 2)
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
	var label: String = info.get("label", text)
	btn.text = label
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 60)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.tooltip_text = label
	btn.add_theme_font_size_override("font_size", _option_font_size_for(label))
	_apply_option_button_style(btn, info.get("type", "ask"))
	return btn


func _option_font_size_for(label: String) -> int:
	if label.length() >= 32:
		return 16
	if label.length() >= 24:
		return 17
	return 18


func _option_type_info(text: String, opt: Dictionary) -> Dictionary:
	var clean := text.strip_edges()
	var visited := false
	if clean.begins_with("✓ 已完成 "):
		visited = true
		clean = clean.substr("✓ 已完成 ".length()).strip_edges()
	elif clean.begins_with("✓ "):
		visited = true
		clean = clean.substr(2).strip_edges()
	var option_type: String = str(opt.get("type", "")).strip_edges()
	if option_type == "":
		if clean.begins_with("追问"):
			option_type = "press"
		elif clean.begins_with("观察"):
			option_type = "press"
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
	if option_type == "observe":
		option_type = "press"
	var prefix := "〔问〕"
	match option_type:
		"press":
			prefix = "〔追问〕"
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
		label = "✓ 已完成 " + label
	return {"type": option_type, "label": label}


func _strip_option_prefix(text: String) -> String:
	for p in ["追问", "观察", "试探", "记录", "问", "离开"]:
		if text.begins_with(p):
			return text.substr(p.length()).strip_edges()
	return text


func _apply_option_button_style(btn: Button, option_type: String) -> void:
	var bg := Color(0.13, 0.08, 0.038, 0.96)
	var border := Color(0.72, 0.54, 0.22, 0.76)
	var font := Color(0.96, 0.87, 0.64, 1.0)
	match option_type:
		"press":
			bg = Color(0.16, 0.08, 0.035, 0.97)
			border = Color(0.94, 0.58, 0.22, 0.92)
			font = Color(1.0, 0.84, 0.50, 1.0)
		"observe":
			bg = Color(0.085, 0.10, 0.09, 0.96)
			border = Color(0.60, 0.78, 0.76, 0.82)
			font = Color(0.86, 0.96, 0.92, 1.0)
		"probe":
			bg = Color(0.15, 0.055, 0.045, 0.97)
			border = Color(0.86, 0.36, 0.24, 0.86)
			font = Color(1.0, 0.76, 0.62, 1.0)
		"record":
			bg = Color(0.13, 0.10, 0.05, 0.97)
			border = Color(0.88, 0.70, 0.34, 0.84)
			font = Color(0.98, 0.92, 0.68, 1.0)
		"leave", "continue":
			bg = Color(0.09, 0.06, 0.035, 0.94)
			border = Color(0.56, 0.44, 0.22, 0.58)
			font = Color(0.80, 0.72, 0.58, 1.0)
	btn.add_theme_color_override("font_color", font)
	btn.add_theme_color_override("font_hover_color", font.lightened(0.10))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.92, 0.74, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.94))
	btn.add_theme_constant_override("outline_size", 2)
	_apply_plain_button_style(btn, bg, border)


func _apply_plain_button_style(btn: Button, bg: Color, border: Color) -> void:
	var normal := _make_button_style(bg, border, 10)
	var hover := _make_button_style(bg.lightened(0.08), border.lightened(0.14), 18)
	var pressed := _make_button_style(bg.darkened(0.14), border.lightened(0.06), 6)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)


func _make_button_style(bg: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
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
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = shadow_size
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _on_option_pressed(idx: int, opt: Dictionary) -> void:
	_hide_options()
	_set_choice_hint("", false)
	if _is_evidence_option(opt):
		await _play_evidence_present_fx(_evidence_title(opt))
	DialogueManager.choose_option(idx)


func _is_evidence_option(opt: Dictionary) -> bool:
	var explicit_type: String = opt.get("type", "")
	if explicit_type != "" and explicit_type != "evidence":
		return false
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
	btn.text = ("✓ 已完成 " if had_visited else "") + "〔呈证〕  " + _strip_evidence_label(btn.text)
	btn.add_theme_font_size_override("font_size", _option_font_size_for(btn.text))
	btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.70, 1.0))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_color_override("font_outline_color", Color(0.03, 0.015, 0.0, 0.96))
	var normal := _make_evidence_button_style(Color(0.16, 0.08, 0.036, 0.96), Color(0.98, 0.62, 0.22, 0.90), 16)
	var hover := _make_evidence_button_style(Color(0.22, 0.10, 0.04, 0.98), Color(1.0, 0.82, 0.36, 1.0), 22)
	var pressed := _make_evidence_button_style(Color(0.11, 0.055, 0.028, 0.98), Color(1.0, 0.88, 0.46, 1.0), 10)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)


func _strip_evidence_label(text: String) -> String:
	var out := text
	for prefix in ["✓ 已完成 〔呈证〕", "✓ 〔呈证〕", "〔呈证〕", "✓ 已完成 〔问〕", "✓ 〔问〕", "〔问〕"]:
		if out.begins_with(prefix):
			out = out.substr(prefix.length()).strip_edges()
	return out


func _make_evidence_button_style(bg: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 3
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(1.0, 0.54, 0.18, 0.30)
	style.shadow_size = shadow_size
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


# ═══════════════════════════════════════════════════════════════
# ███  对话页面构建
# ═══════════════════════════════════════════════════════════════

func _build_dialogue_pages(default_speaker: String, default_portrait: String, text: String, raw_pages: Array) -> Array:
	var pages: Array = []
	if raw_pages.is_empty():
		raw_pages = [{"speaker": default_speaker, "portrait": default_portrait, "text": text}]
	for raw_page in raw_pages:
		if typeof(raw_page) != TYPE_DICTIONARY:
			continue
		var speaker: String = raw_page.get("speaker", default_speaker)
		var portrait: String = raw_page.get("portrait_override", raw_page.get("portrait", default_portrait))
		if _normalize_visible_speaker(speaker) == "" and portrait == "":
			portrait = default_portrait
		var line_text: String = raw_page.get("text", "")
		var page_emotion: String = raw_page.get("portrait_emotion", raw_page.get("emotion", raw_page.get("mood", "")))
		var sentences := _split_dialogue_text(line_text)
		for idx in range(sentences.size()):
			var page := {
				"speaker": speaker,
				"portrait": portrait,
				"text": sentences[idx],
				"type": raw_page.get("type", ""),
				"emotion": page_emotion,
				"highlight": raw_page.get("highlight", [])
			}
			if idx == sentences.size() - 1:
				_copy_record_meta(raw_page, page)
			pages.append(page)
	return pages


func _normalize_visible_speaker(speaker: String) -> String:
	var cleaned := speaker.strip_edges()
	var lowered := cleaned.to_lower()
	if cleaned == "旁白" or lowered == "narrator" or lowered == "_narrator" or lowered == "narrtator":
		return ""
	return cleaned


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
			var _close_quotes := String.chr(0x201D) + String.chr(0x2019) + String.chr(0xFF09) + ")"
			while next_i < block.length() and _close_quotes.find(block[next_i]) >= 0:
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


func _decorate_text(text: String, extra_highlights = [], force_inner_thought := false) -> String:
	var out := TextUtilsScript.prepare_dialogue_plain_text(text, force_inner_thought)
	var words: Array = []
	for kw in KEYWORD_HIGHLIGHTS:
		words.append(kw)
	if extra_highlights is Array:
		for kw in extra_highlights:
			words.append(str(kw))
	elif extra_highlights is String and str(extra_highlights) != "":
		words.append(str(extra_highlights))
	out = _highlight_keywords_outside_thoughts(out, words)
	out = TextUtilsScript.color_inner_thoughts(out) if force_inner_thought else TextUtilsScript.strip_all_parentheticals(out)
	return out


## 轻量级文本装饰：仅高亮+染色，不复执行 prepare_dialogue_plain_text（避免双重括号）。
## 入参 text 应当是已经过 prepare_dialogue_plain_text 处理的文本。
func _highlight_and_color_text(text: String, extra_highlights = [], is_inner_thought := false) -> String:
	var out := text
	var words: Array = []
	for kw in KEYWORD_HIGHLIGHTS:
		words.append(kw)
	if extra_highlights is Array:
		for kw in extra_highlights:
			words.append(str(kw))
	elif extra_highlights is String and str(extra_highlights) != "":
		words.append(str(extra_highlights))
	out = _highlight_keywords_outside_thoughts(out, words)
	out = TextUtilsScript.color_inner_thoughts(out) if is_inner_thought else TextUtilsScript.strip_all_parentheticals(out)
	return out


func _highlight_keywords_outside_thoughts(text: String, words: Array) -> String:
	var out := ""
	var i := 0
	while i < text.length():
		if text[i] == "（":
			var end := text.find("）", i + 1)
			if end > i:
				out += text.substr(i, end - i + 1)
				i = end + 1
				continue
		var next_thought := text.find("（", i)
		var chunk_len := text.length() - i if next_thought < 0 else next_thought - i
		if chunk_len <= 0:
			out += text[i]
			i += 1
			continue
		out += _highlight_keywords_in_chunk(text.substr(i, chunk_len), words)
		i += chunk_len
	return out


func _highlight_keywords_in_chunk(text: String, words: Array) -> String:
	var out := text
	for kw in words:
		if kw == "":
			continue
		if out.find(kw) >= 0 and out.find("[font_size=28][color=#e84a36][b]" + kw) < 0:
			out = out.replace(kw, "[font_size=28][color=#e84a36][b]%s[/b][/color][/font_size]" % kw)
	return out


# ═══════════════════════════════════════════════════════════════
# ███  表情/动画资源解析
# ═══════════════════════════════════════════════════════════════

func _resolve_emotion_portrait(base_path: String, emotion: String) -> String:
	if base_path == "" or emotion == "" or emotion == "normal":
		return base_path
	var mapped: String = AssetResolver.resolve_portrait_expression(base_path, emotion)
	if mapped != "":
		return mapped
	var candidates: Array[String] = []
	candidates.append(base_path.replace(".png", "_%s.png" % emotion))
	# 回退映射：多个语义相近的 emotion 映射到同一张立绘
	if emotion in ["nervous", "panic", "defensive", "cornered", "shaken", "guarded"]:
		candidates.append(base_path.replace(".png", "_shaken.png"))
		candidates.append(base_path.replace(".png", "_nervous.png"))
		candidates.append(base_path.replace(".png", "_trembling.png"))
	if emotion in ["breakdown", "collapsed", "defeated"]:
		candidates.append(base_path.replace(".png", "_collapsed.png"))
		candidates.append(base_path.replace(".png", "_silent.png"))
	if emotion in ["grief", "crying", "sobbing", "sad"]:
		candidates.append(base_path.replace(".png", "_crying.png"))
		candidates.append(base_path.replace(".png", "_screaming.png"))
		candidates.append(base_path.replace(".png", "_trembling.png"))
	if emotion in ["angry", "screaming", "rage", "furious"]:
		candidates.append(base_path.replace(".png", "_screaming.png"))
		candidates.append(base_path.replace(".png", "_stern.png"))
		candidates.append(base_path.replace(".png", "_sneering.png"))
	if emotion in ["shocked", "surprised", "stunned", "frozen"]:
		candidates.append(base_path.replace(".png", "_shocked.png"))
		candidates.append(base_path.replace(".png", "_frozen.png"))
		candidates.append(base_path.replace(".png", "_screaming.png"))
	if emotion in ["suspicious", "stern", "cold", "hostile", "cold_fury"]:
		candidates.append(base_path.replace(".png", "_stern.png"))
		candidates.append(base_path.replace(".png", "_cold_smile.png"))
		candidates.append(base_path.replace(".png", "_trembling.png"))
	if emotion in ["evasive", "guilty", "avoidant"]:
		candidates.append(base_path.replace(".png", "_evasive.png"))
		candidates.append(base_path.replace(".png", "_nervous.png"))
	if emotion in ["sighing", "resigned", "tired", "weary"]:
		candidates.append(base_path.replace(".png", "_sighing.png"))
		candidates.append(base_path.replace(".png", "_silent.png"))
	if emotion in ["sneering", "contempt", "mocking", "dismissive", "smirk"]:
		candidates.append(base_path.replace(".png", "_sneering.png"))
		candidates.append(base_path.replace(".png", "_cold_smile.png"))
	if emotion in ["bold", "sharp", "confident", "deflecting", "cooperative"]:
		candidates.append(base_path.replace(".png", "_cold_smile.png"))
		candidates.append(base_path.replace(".png", "_sneering.png"))
	if emotion in ["gossip", "chatty", "casual"]:
		candidates.append(base_path.replace(".png", "_nervous.png"))
		candidates.append(base_path.replace(".png", "_sighing.png"))
	if emotion in ["cracking", "vulnerable", "breaking"]:
		candidates.append(base_path.replace(".png", "_cracking.png"))
		candidates.append(base_path.replace(".png", "_crying.png"))
		candidates.append(base_path.replace(".png", "_trembling.png"))
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return base_path


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
	var cache_key := _portrait_cache_key(path)
	var cached = _portrait_texture_cache.get(cache_key, null)
	if cached is Texture2D:
		return cached
	var texture := _load_source_portrait_texture(path)
	if texture == null:
		texture = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if texture == null:
		return null
	var normalized := _crop_texture_to_visible_alpha(texture)
	_portrait_texture_cache[cache_key] = normalized
	return normalized


func _load_source_portrait_texture(path: String) -> Texture2D:
	var source_path := ProjectSettings.globalize_path(path)
	if source_path == "" or not FileAccess.file_exists(source_path):
		return null
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _portrait_cache_key(path: String) -> String:
	var modified_time := FileAccess.get_modified_time(path)
	if modified_time == 0:
		modified_time = FileAccess.get_modified_time(ProjectSettings.globalize_path(path))
	return "%s:%d" % [path, modified_time]


func _crop_texture_to_visible_alpha(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image == null:
		return texture
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return texture
	var image_size := image.get_size()
	if float(used.size.y) / float(image_size.y) < PORTRAIT_CROP_MIN_HEIGHT_RATIO:
		return texture
	var pad_x: int = max(PORTRAIT_CROP_MIN_PADDING, int(ceil(float(used.size.x) * PORTRAIT_CROP_PADDING_RATIO)))
	var pad_y: int = max(PORTRAIT_CROP_MIN_PADDING, int(ceil(float(used.size.y) * PORTRAIT_CROP_PADDING_RATIO)))
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


# ═══════════════════════════════════════════════════════════════
# ███  对话记录日志
# ═══════════════════════════════════════════════════════════════

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


# ═══════════════════════════════════════════════════════════════
# ███  笔记本记录
# ═══════════════════════════════════════════════════════════════

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
	var record_text := TextUtilsScript.strip_stage_directions(str(page.get("record_text", page.get("text", ""))))
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


# ═══════════════════════════════════════════════════════════════
# ███  呈证演出
# ═══════════════════════════════════════════════════════════════

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
