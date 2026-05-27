extends Control
## NPC 对话框：全屏居中大立绘 + 底部窄条文本（逆转裁判风格）
## 支持多帧动画循环（说话/待机），为 AI 生成动画帧做准备。

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansSC.otf")

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

const CLR_GOLD := Color(0.96, 0.84, 0.46, 1.0)
const CLR_PAPER := Color(0.12, 0.075, 0.04, 0.94)
const CLR_INK := Color(0.92, 0.86, 0.72, 1.0)
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
const DIALOGUE_FRAME_HEIGHT := 222.0
const DIALOGUE_TEXT_LEFT_DEFAULT := 48.0
const DIALOGUE_TEXT_LEFT_WITH_AVATAR := 264.0
const DIALOGUE_TEXT_TOP_OFFSET := -202.0
const DIALOGUE_TEXT_BOTTOM_OFFSET := -34.0
const AVATAR_SIZE := Vector2(286, 520)
const AVATAR_OFFSET_LEFT := 10.0
const AVATAR_OFFSET_TOP := -520.0
const AVATAR_OFFSET_RIGHT := 296.0
const AVATAR_OFFSET_BOTTOM := 0.0


func _ready() -> void:
	legacy_options.visible = false
	exit_btn.visible = false
	# ── 立绘区域设置（全屏居中大图） ──
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_rect.pivot_offset = Vector2(320, 330)  # center of 640x660
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
	text_label.add_theme_font_override("normal_font", UI_FONT)
	text_label.add_theme_font_size_override("normal_font_size", 22)
	text_label.add_theme_color_override("default_color", CLR_INK)
	text_label.add_theme_constant_override("line_separation", 6)
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
		if _narration_mode:
			DialogueManager.narration_advance()
		else:
			_dialogue_page_index += 1
			_play_current_page(_dialogue_run_id)
		get_viewport().set_input_as_handled()



# ═══════════════════════════════════════════════════════════════
# ███  叙述模式（替代 NarrationBox）
# ═══════════════════════════════════════════════════════════════

func show_narration(speaker: String, text: String, has_next: bool, portrait: String = "") -> void:
	"""叙述模式：与 DialogueManager 的 narration 信号对接，点击推进"""
	_narration_mode = true
	_narration_has_next = has_next
	_dialogue_run_id += 1
	_hide_options()
	if _log_panel != null:
		_log_panel.visible = false
	_set_choice_hint("", false)
	_waiting_for_advance = false
	# 去掉多余空行，限制显示不超过3行（约60字）
	var display_text := text.replace("\r\n", "\n").replace("\r", "\n").strip_edges()
	while display_text.find("\n\n") >= 0:
		display_text = display_text.replace("\n\n", "\n")
	# 如果文字包含换行且超过3行，只显示前3行
	var lines := display_text.split("\n")
	if lines.size() > 3:
		display_text = "\n".join(lines.slice(0, 3))
	# 显示说话者和立绘
	_apply_narration_speaker(speaker, portrait)
	# 打字机播放文字（不调用说话动画，避免立绘偏移）
	_typewriter.play(text_label, display_text)
	await _typewriter.finished
	# 文字播完后启动眨眼循环
	_start_blink_loop()
	# 文字播放完毕，等待点击
	var hint := "▼ 点击继续" if has_next else "▼ 点击进入游戏"
	_set_choice_hint(hint, true)
	_waiting_for_advance = true


func _apply_narration_speaker(speaker: String, portrait: String) -> void:
	"""叙述模式的说话者/立绘处理"""
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
	# 文字位置始终与 NPC 对话一致
	text_label.offset_top = 56.0 if speaker != "" else 16.0
	if speaker == "":
		# 纯叙述：无立绘
		portrait_rect.visible = false
		_hide_avatar()
		return
	# 如果没有提供 portrait，尝试自动解析
	var resolved := portrait
	if resolved == "" or not ResourceLoader.exists(resolved):
		resolved = _resolve_portrait_for_speaker(speaker)
	# 有说话者：走立绘规则
	if _is_protagonist_or_companion(speaker):
		# 主角或助手（非讨论模式）→ 左下角头像
		_show_avatar(speaker, resolved, "")
		_load_animation_frames(resolved, "")
		portrait_rect.visible = false
	elif resolved != "" and ResourceLoader.exists(resolved):
		# 指定了立绘 → 居中显示
		portrait_rect.texture = load(resolved)
		portrait_rect.visible = true
		portrait_rect.modulate.a = 1.0
		portrait_rect.scale = Vector2(1.0, 1.0)
		_load_animation_frames(resolved, "")
		_hide_avatar()
	else:
		portrait_rect.visible = false
		_hide_avatar()


func _resolve_portrait_for_speaker(speaker_name: String) -> String:
	"""根据说话者名字解析立绘路径"""
	# 助手
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("get_companion_role_name"):
		var companion_name: String = cs.get_companion_role_name()
		if companion_name != "" and speaker_name == companion_name:
			return cs.get_companion_portrait()
	# 通过 casting 查找 NPC
	var casting: Dictionary = AssetResolver.get_casting()
	for npc_id in casting.keys():
		var entry = casting[npc_id]
		if typeof(entry) == TYPE_DICTIONARY:
			if entry.get("role_name", "") == speaker_name:
				return AssetResolver.get_portrait(npc_id, GameManager.npcs_data)
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


func end_narration_mode() -> void:
	"""退出叙述模式"""
	_narration_mode = false
	_narration_has_next = false
	_waiting_for_advance = false
	_hide_options()
	portrait_rect.visible = false
	_hide_avatar()



## 跳过下一次立绘入场动画（NPC 已在 NpcSceneLayer 可见时调用）
func skip_portrait_intro() -> void:
	_skip_next_portrait_animation = true


func show_dialogue(speaker: String, portrait_path: String, text: String, options: Array, pages: Array = []) -> void:
	_narration_mode = false
	_dialogue_run_id += 1
	_hide_options()
	if _log_panel != null:
		_log_panel.visible = false
	_set_choice_hint("", false)
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
	_set_choice_hint("", false)
	_waiting_for_advance = false
	var page: Dictionary = _dialogue_pages[_dialogue_page_index]
	_apply_speaker(page.get("speaker", ""), page.get("portrait", ""), page.get("emotion", ""))
	var page_text: String = page.get("text", "")
	_append_dialogue_log(page.get("speaker", ""), page_text)
	_start_talk_animation()
	_typewriter.play(text_label, _decorate_text(page_text, page.get("highlight", [])))
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
	# 主角/同伴：左下角头像 + 文字右移
	if _is_protagonist_or_companion(speaker):
		speaker_label.text = speaker
		speaker_label.visible = speaker != ""
		_last_speaker = speaker
		_show_avatar(speaker, portrait_path, emotion)
		return

	# NPC：居中立绘 + 底部对话框
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
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
	if _resolved_portrait != "" and ResourceLoader.exists(_resolved_portrait):
		portrait_rect.texture = load(_resolved_portrait)
		portrait_rect.visible = true
		if _skip_next_portrait_animation:
			# NPC 已在场景层可见，直接显示不做动画（避免拖动/跳动感）
			_skip_next_portrait_animation = false
			portrait_rect.modulate.a = 1.0
			portrait_rect.scale = Vector2(1.0, 1.0)
			if _portrait_tween != null and _portrait_tween.is_valid():
				_portrait_tween.kill()
		elif _changed:
			portrait_rect.modulate.a = 0.0
			portrait_rect.scale = Vector2(0.96, 0.96)
			if _portrait_tween != null and _portrait_tween.is_valid():
				_portrait_tween.kill()
			_portrait_tween = create_tween()
			_portrait_tween.set_parallel(true)
			_portrait_tween.tween_property(portrait_rect, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_portrait_tween.tween_property(portrait_rect, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			if portrait_rect.modulate.a < 1.0:
				if _portrait_tween != null and _portrait_tween.is_valid():
					_portrait_tween.kill()
				_portrait_tween = create_tween()
				_portrait_tween.tween_property(portrait_rect, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		portrait_rect.visible = false


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
		mat.set_shader_parameter("fade_top", 0.03)
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
	# 讨论模式下，助手作为“NPC角色”居中显示，不走头像路径
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
		_avatar_rect.texture = load(resolved_portrait)
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
			_talk_frames.append(load(path))
		else:
			break
	# 尝试加载待机帧：actor_xxx_idle_0.png, _idle_1.png ...
	var idle_base := base_path.replace(".png", "_idle_%d.png")
	for i in range(10):
		var path := idle_base % i
		if ResourceLoader.exists(path):
			_idle_frames.append(load(path))
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


## 眨眼循环：每 2-5 秒眨一次眼，偶尔双眨
func _start_blink_loop() -> void:
	_is_blinking = false
	if _idle_frames.size() < 2:
		return
	var delay := randf_range(2.5, 5.0)
	_blink_timer.start(delay)


func _stop_blink_loop() -> void:
	_blink_timer.stop()
	_is_blinking = false


func _do_blink() -> void:
	if _is_talking or not visible or _idle_frames.size() < 2:
		return
	_is_blinking = true

	if _idle_frames.size() >= 5:
		# 多帧眨眼序列（逆转裁判级别）：闭合快、张开慢
		var close_timing := [0.035, 0.035, 0.04, 0.06]   # 帧1→2→3→4，渐快+hold
		var open_timing := [0.045, 0.05, 0.05]            # 帧3→2→1→0，稍慢

		# 闭合阶段: 0 → 1 → 2 → 3 → 4
		for i in range(1, _idle_frames.size()):
			if _is_talking or not visible:
				break
			portrait_rect.texture = _idle_frames[i]
			var t_idx := mini(i - 1, close_timing.size() - 1)
			await get_tree().create_timer(close_timing[t_idx]).timeout

		# 张开阶段: 4 → 3 → 2 → 1 → 0
		for i in range(_idle_frames.size() - 2, -1, -1):
			if _is_talking or not visible:
				break
			portrait_rect.texture = _idle_frames[i]
			var t_idx := mini(_idle_frames.size() - 2 - i, open_timing.size() - 1)
			await get_tree().create_timer(open_timing[t_idx]).timeout
	else:
		# 2帧 fallback（兼容旧资源）
		portrait_rect.texture = _idle_frames[1]
		await get_tree().create_timer(0.1).timeout
		if not _is_talking and visible and not _idle_frames.is_empty():
			portrait_rect.texture = _idle_frames[0]

	_is_blinking = false
	# 安排下一次眨眼（偶尔双眨）
	if not _is_talking and visible and _idle_frames.size() >= 2:
		var double_blink := randf() < 0.15  # 15% 概率双眨
		var next_delay := 0.2 if double_blink else randf_range(2.5, 5.0)
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
	tw.tween_property(portrait_rect, "scale", Vector2(target_scale, target_scale), duration * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(portrait_rect, "scale", Vector2(1.0, 1.0), duration * 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


# ═══════════════════════════════════════════════════════════════
# ███  底部文本框外观
# ═══════════════════════════════════════════════════════════════

func _build_dialogue_frame() -> void:
	if _speaker_plate != null:
		return
	_speaker_plate = PanelContainer.new()
	_speaker_plate.name = "SpeakerPlate"
	_speaker_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker_plate.anchor_left = 0.0
	_speaker_plate.anchor_top = 0.0
	_speaker_plate.anchor_right = 0.0
	_speaker_plate.anchor_bottom = 0.0
	_speaker_plate.offset_left = 8.0
	_speaker_plate.offset_top = 4.0
	_speaker_plate.offset_right = 252.0
	_speaker_plate.offset_bottom = 52.0
	_speaker_plate.visible = false
	box.add_child(_speaker_plate)
	box.move_child(_speaker_plate, 0)


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

	speaker_label.offset_left = 16.0
	speaker_label.offset_top = 10.0
	speaker_label.offset_right = 260.0
	speaker_label.offset_bottom = 42.0
	speaker_label.add_theme_font_override("font", UI_FONT)
	speaker_label.add_theme_font_size_override("font_size", 24)
	speaker_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.56, 1.0))
	speaker_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.84))
	speaker_label.add_theme_constant_override("outline_size", 2)

	text_label.offset_left = 18.0
	text_label.offset_top = 56.0
	text_label.offset_right = -20.0
	text_label.offset_bottom = -24.0
	text_label.add_theme_font_override("normal_font", UI_FONT)
	text_label.add_theme_font_size_override("normal_font_size", 21)
	text_label.add_theme_color_override("default_color", Color(0.95, 0.90, 0.78, 1.0))
	text_label.add_theme_constant_override("line_separation", 6)



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
	_choice_hint_label.add_theme_font_override("font", UI_FONT)
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
	_log_button.add_theme_font_override("font", UI_FONT)
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
	title.add_theme_font_override("font", UI_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", CLR_GOLD)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.0, 0.88))
	title.add_theme_constant_override("outline_size", 2)
	hb.add_child(title)
	var close := Button.new()
	close.text = "收起"
	close.add_theme_font_override("font", UI_FONT)
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
	_log_text.add_theme_font_override("normal_font", UI_FONT)
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

	_top_options_vbox = VBoxContainer.new()
	_top_options_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(_top_options_vbox)
	_top_options_panel.visible = false


func _position_top_options(option_count: int) -> void:
	var vp := get_viewport_rect().size
	var panel_w: float = minf(720.0, vp.x * 0.58)
	var btn_height: float = 44.0
	var separation: int = 8
	if option_count > 6:
		btn_height = 40.0
		separation = 6
	_top_options_vbox.add_theme_constant_override("separation", separation)
	for child in _top_options_vbox.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0, btn_height)
	var visible_count: int = option_count if option_count > 0 else 1
	var panel_h: float = minf(320.0, 24.0 + float(visible_count) * (btn_height + float(separation)))
	_top_options_panel.size = Vector2(panel_w, panel_h)
	var dialogue_box_top: float = dim_bg.get_rect().position.y
	var target_y: float = dialogue_box_top - panel_h - 12.0
	if target_y < 24.0:
		target_y = 24.0
	var target_x: float = (vp.x - panel_w) * 0.5
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
	title.add_theme_font_override("font", UI_FONT)
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
	btn.text = info.get("label", text)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 52)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", UI_FONT)
	btn.add_theme_font_size_override("font_size", 19)
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
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
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
	btn.text = ("✓ " if had_visited else "") + "〔呈证〕  " + _strip_evidence_label(btn.text)
	btn.add_theme_font_override("font", UI_FONT)
	btn.add_theme_font_size_override("font_size", 20)
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
	for prefix in ["✓ 〔呈证〕", "〔呈证〕", "✓ 〔问〕", "〔问〕"]:
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
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
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


# ═══════════════════════════════════════════════════════════════
# ███  表情/动画资源解析
# ═══════════════════════════════════════════════════════════════

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
