extends Control
## 序章/叙述框：支持底部对话框与居中提示框两种显示，有 speaker 时显示立绘
## 逐字显示：点击一次 = 显示全文；再次点击 = 翻页

const TypewriterEffectScript = preload("res://scripts/ui/TypewriterEffect.gd")

@onready var box: PanelContainer = $Box
@onready var speaker_label: Label = $Box/VBox/SpeakerName
@onready var text_label: RichTextLabel = $Box/VBox/TextLabel
@onready var continue_label: Label = $Box/VBox/ContinueLabel

var _has_next: bool = true
var _portrait_rect: TextureRect = null
var _typewriter: Node = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	_create_portrait_rect()
	_typewriter = TypewriterEffectScript.new()
	add_child(_typewriter)


func _create_portrait_rect() -> void:
	_portrait_rect = TextureRect.new()
	_portrait_rect.name = "NarrationPortrait"
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 与 DialogueBox Portrait 一致：左侧，200x500
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


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var clicked := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked = true
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		clicked = true
	
	if clicked:
		if _typewriter.is_playing():
			# 文字还在出，点击 = 立即显示全文
			_typewriter.skip()
		else:
			# 文字已全部显示，点击 = 翻到下一页
			DialogueManager.narration_advance()
		get_viewport().set_input_as_handled()


func show_narration(speaker: String, text: String, has_next: bool, centered := false) -> void:
	speaker_label.text = speaker
	speaker_label.visible = (speaker != "")
	_has_next = has_next
	continue_label.text = "▼ 点击继续" if has_next else "▼ 点击进入游戏"
	continue_label.visible = false
	_apply_layout(centered)
	_update_portrait(speaker)
	# 逐字显示
	_typewriter.play(text_label, text)
	await _typewriter.finished
	continue_label.visible = true


func _apply_layout(centered: bool) -> void:
	if centered:
		box.anchor_left = 0.5
		box.anchor_top = 0.5
		box.anchor_right = 0.5
		box.anchor_bottom = 0.5
		box.offset_left = -470
		box.offset_top = -170
		box.offset_right = 470
		box.offset_bottom = 170
		text_label.custom_minimum_size = Vector2(880, 220)
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


## 有立绘时文字框左移，避免遮挡
func _adjust_box_for_portrait(has_portrait: bool) -> void:
	if has_portrait:
		box.offset_left = 230
	else:
		box.offset_left = 80


## 根据 speaker 名字查找并显示立绘
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


## 解析说话人对应的立绘路径
func _resolve_portrait_for_speaker(speaker: String) -> String:
	# 1) 检查是否是助手
	var cs = get_node_or_null("/root/CompanionService")
	if cs and cs.has_method("get_companion_role_name"):
		var companion_name: String = cs.get_companion_role_name()
		if companion_name != "" and speaker == companion_name:
			var p: String = cs.get_companion_portrait()
			if p != "":
				return p

	# 2) 通过 casting 查找 NPC（包括玩家角色）
	var casting: Dictionary = AssetResolver.get_casting()
	for npc_id in casting.keys():
		var entry = casting[npc_id]
		if typeof(entry) == TYPE_DICTIONARY:
			if entry.get("role_name", "") == speaker:
				return AssetResolver.get_portrait(npc_id, GameManager.npcs_data)
	return ""
