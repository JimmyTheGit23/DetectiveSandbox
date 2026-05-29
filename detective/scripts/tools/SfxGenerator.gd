## SFX Generator — 程序化音效生成器
##
## 在 Godot 中通过代码生成常见音效，保存为 .wav 文件。
## 用法：
##   1. 在场景树中添加此脚本，或在编辑器中运行
##   2. 调用对应的生成方法
##   3. 音效文件自动保存到 res://assets/cn/sfx/
##
## 也可在 GDScript 控制台中直接调用：
##   SfxGenerator.generate_click()
##   SfxGenerator.generate_ui_confirm()

@tool
extends EditorScript

const SFX_OUTPUT_PATH := "res://assets/cn/sfx/"
const SAMPLE_RATE := 44100
const OUTPUT_FORMAT := AudioStreamWAV.FORMAT_16_BITS

# ============================================================
#  音效生成入口
# ============================================================

## 生成所有常用游戏音效
func generate_all() -> void:
	generate_click()
	generate_ui_confirm()
	generate_ui_cancel()
	generate_ui_hover()
	generate_ui_tab_switch()
	generate_text_blip()
	generate_discovery()
	generate_discovery_big()
	generate_page_flip()
	generate_lock()
	generate_unlock()
	generate_tick()
	generate_notification()
	generate_investigate()
	generate_map_open()
	generate_map_close()
	generate_combat_hit()
	generate_combat_dodge()
	generate_suspense()
	print("[SFX] ✅ 所有音效已生成完毕！")

# ============================================================
#  UI 音效
# ============================================================

## 鼠标点击 / 手指触碰声
func generate_click() -> void:
	var data := _generate_tone_envelope(800.0, 0.06, _envelope_attack_decay(0.005, 0.055), 0.7)
	_save_wav("click.wav", data)
	print("[SFX] click.wav ✅")

## 确认 / 按钮按下
func generate_ui_confirm() -> void:
	var buf := PackedVector2Array()
	var length := 0.15
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(523.0, 784.0, t / length)  # C5 -> G5 上滑
		var env := _envelope_attack_decay(0.01, 0.14)
		var amp := env.sample(t / length) * 0.6
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("ui_confirm.wav", buf)
	print("[SFX] ui_confirm.wav ✅")

## 取消 / 返回
func generate_ui_cancel() -> void:
	var buf := PackedVector2Array()
	var length := 0.12
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(440.0, 330.0, t / length)  # A4 -> E4 下滑
		var env := _envelope_attack_decay(0.01, 0.11)
		var amp := env.sample(t / length) * 0.5
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("ui_cancel.wav", buf)
	print("[SFX] ui_cancel.wav ✅")

## 悬停 / 聚焦
func generate_ui_hover() -> void:
	var data := _generate_tone_envelope(1200.0, 0.04, _envelope_attack_decay(0.005, 0.035), 0.3)
	_save_wav("ui_hover.wav", data)
	print("[SFX] ui_hover.wav ✅")

## 标签页切换
func generate_ui_tab_switch() -> void:
	var buf := PackedVector2Array()
	var length := 0.08
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := 1000.0 + 500.0 * sin(TAU * 20.0 * t)  # 微弱颤音
		var env := _envelope_attack_decay(0.005, 0.075)
		var amp := env.sample(t / length) * 0.4
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("ui_tab_switch.wav", buf)
	print("[SFX] ui_tab_switch.wav ✅")

## 对话打字逐字音效（16-bit RPG 风格方波 blip）
## 生成 3 个变体，播放时随机选取以增加自然感
func generate_text_blip() -> void:
	# 变体 1：标准方波，480Hz
	_generate_single_blip("text_blip_1.wav", 480.0, 0.35)
	# 变体 2：略高，540Hz
	_generate_single_blip("text_blip_2.wav", 540.0, 0.30)
	# 变体 3：略低，420Hz
	_generate_single_blip("text_blip_3.wav", 420.0, 0.28)
	# 也生成一个默认的 text_blip.wav（指向变体 1，兼容旧代码引用）
	_generate_single_blip("text_blip.wav", 480.0, 0.35)
	print("[SFX] text_blip × 4 ✅")


func _generate_single_blip(filename: String, base_freq: float, volume: float) -> void:
	var length := 0.035  # 35ms — 极短促的 blip
	var buf := PackedVector2Array()
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var norm_t := t / length
		# 方波：sign(sin(...)) 产生 16-bit 风格的复古音色
		var phase := sin(TAU * base_freq * t)
		var square_wave := 1.0 if phase >= 0.0 else -1.0
		# 包络：极快 attack (1ms) + 短 decay
		var env := _envelope_attack_decay(0.001, length - 0.001)
		var amp := env.sample(norm_t) * volume
		# 添加极轻微的高频衰减（模拟低通滤波，更柔和）
		var filter_mod := 1.0 - 0.3 * norm_t
		var s := amp * square_wave * filter_mod
		buf.append(Vector2(s, s))
	_save_wav(filename, buf)

# ============================================================
#  游戏事件音效
# ============================================================

## 发现线索 / 调查成功（小）
func generate_discovery() -> void:
	var buf := PackedVector2Array()
	var length := 0.3
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		# 两个音符：C5 -> E5
		var freq := 523.0
		if t > 0.12:
			freq = 659.0
		var env := _envelope_attack_decay(0.01, 0.28)
		var amp := env.sample(t / length) * 0.6
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("discovery.wav", buf)
	print("[SFX] discovery.wav ✅")

## 重大发现 / 关键线索
func generate_discovery_big() -> void:
	var buf := PackedVector2Array()
	var length := 0.5
	var samples := int(SAMPLE_RATE * length)
	# 三连音：C5 -> E5 -> G5
	var notes := [523.0, 659.0, 784.0]
	var note_len := 0.15
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var note_idx := int(t / note_len)
		if note_idx >= notes.size():
			note_idx = notes.size() - 1
		var freq := notes[note_idx]
		var env := _envelope_attack_decay(0.008, 0.14)
		var amp := env.sample(fmod(t, note_len) / note_len) * 0.6
		# 最后一个音符加延音
		if note_idx == notes.size() - 1:
			amp *= clampf(1.0 - (t - note_len * 2) / (length - note_len * 2), 0.0, 1.0)
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("discovery_big.wav", buf)
	print("[SFX] discovery_big.wav ✅")

## 翻页声
func generate_page_flip() -> void:
	var length := 0.15
	var buf := PackedVector2Array()
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		# 带滤波的白噪声模拟纸张声
		var noise := randf_range(-1.0, 1.0)
		var env := _envelope_attack_decay(0.02, 0.13)
		var amp := env.sample(t / length) * 0.35
		# 简单的高通效果：用正弦调制
		var mod := sin(TAU * 3000.0 * t) * 0.5 + 0.5
		buf.append(Vector2(amp * noise * mod, amp * noise * mod))
	_save_wav("page_flip.wav", buf)
	print("[SFX] page_flip.wav ✅")

## 上锁声
func generate_lock() -> void:
	var buf := PackedVector2Array()
	var length := 0.2
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		# 低沉的咔嗒声
		var freq := 200.0 + 100.0 * exp(-30.0 * t)
		var env := _envelope_attack_decay(0.003, 0.197)
		var amp := env.sample(t / length) * 0.7
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("lock.wav", buf)
	print("[SFX] lock.wav ✅")

## 开锁声
func generate_unlock() -> void:
	var buf := PackedVector2Array()
	var length := 0.25
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		# 高频到低频的金属声
		var freq := 800.0 * exp(-8.0 * t) + 150.0
		var env := _envelope_attack_decay(0.005, 0.245)
		var amp := env.sample(t / length) * 0.6
		var noise := randf_range(-0.15, 0.15)
		var s := amp * (sin(TAU * freq * t) + noise)
		buf.append(Vector2(s, s))
	_save_wav("unlock.wav", buf)
	print("[SFX] unlock.wav ✅")

## 滴答声（倒计时 / 时钟）
func generate_tick() -> void:
	var data := _generate_tone_envelope(1800.0, 0.03, _envelope_attack_decay(0.002, 0.028), 0.5)
	_save_wav("tick.wav", data)
	print("[SFX] tick.wav ✅")

## 通知 / 提示音
func generate_notification() -> void:
	var buf := PackedVector2Array()
	var length := 0.25
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := 880.0
		if t > 0.1:
			freq = 1100.0
		var env := _envelope_attack_decay(0.005, 0.245)
		var amp := env.sample(t / length) * 0.5
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("notification.wav", buf)
	print("[SFX] notification.wav ✅")

## 调查 / 检查（放大镜效果音）
func generate_investigate() -> void:
	var buf := PackedVector2Array()
	var length := 0.2
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := 400.0 + 200.0 * sin(TAU * 15.0 * t)
		var env := _envelope_attack_decay(0.02, 0.18)
		var amp := env.sample(t / length) * 0.4
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("investigate.wav", buf)
	print("[SFX] investigate.wav ✅")

## 地图打开
func generate_map_open() -> void:
	var buf := PackedVector2Array()
	var length := 0.2
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(300.0, 600.0, t / length)
		var env := _envelope_attack_decay(0.01, 0.19)
		var amp := env.sample(t / length) * 0.45
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("map_open.wav", buf)
	print("[SFX] map_open.wav ✅")

## 地图关闭
func generate_map_close() -> void:
	var buf := PackedVector2Array()
	var length := 0.15
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(600.0, 300.0, t / length)
		var env := _envelope_attack_decay(0.01, 0.14)
		var amp := env.sample(t / length) * 0.45
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("map_close.wav", buf)
	print("[SFX] map_close.wav ✅")

# ============================================================
#  战斗 / 冒险音效
# ============================================================

## 攻击命中
func generate_combat_hit() -> void:
	var buf := PackedVector2Array()
	var length := 0.12
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := 150.0 * exp(-20.0 * t) + 60.0
		var env := _envelope_attack_decay(0.002, 0.118)
		var amp := env.sample(t / length) * 0.8
		var noise := randf_range(-0.3, 0.3)
		var s := amp * (sin(TAU * freq * t) + noise)
		buf.append(Vector2(s, s))
	_save_wav("combat_hit.wav", buf)
	print("[SFX] combat_hit.wav ✅")

## 闪避
func generate_combat_dodge() -> void:
	var buf := PackedVector2Array()
	var length := 0.1
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(2000.0, 500.0, t / length)
		var env := _envelope_attack_decay(0.005, 0.095)
		var amp := env.sample(t / length) * 0.35
		buf.append(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))
	_save_wav("combat_dodge.wav", buf)
	print("[SFX] combat_dodge.wav ✅")

# ============================================================
#  氛围音效
# ============================================================

## 悬疑 / 紧张氛围（短促）
func generate_suspense() -> void:
	var buf := PackedVector2Array()
	var length := 0.6
	var samples := int(SAMPLE_RATE * length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		# 低频 + 缓慢上升的不和谐音
		var freq1 := 110.0
		var freq2 := 116.0  # 微弱不和谐
		var s1 := sin(TAU * freq1 * t) * 0.4
		var s2 := sin(TAU * freq2 * t) * 0.3
		var env := _envelope_attack_decay(0.1, 0.5)
		var amp := env.sample(t / length)
		# 添加轻微的调幅（wobble）
		var wobble := 1.0 + 0.2 * sin(TAU * 5.0 * t)
		var s := amp * wobble * (s1 + s2)
		buf.append(Vector2(s, s))
	_save_wav("suspense.wav", buf)
	print("[SFX] suspense.wav ✅")

# ============================================================
#  工具函数
# ============================================================

func _generate_tone_envelope(p_freq: float, p_length: float, p_env: Envelope, p_volume: float) -> PackedVector2Array:
	var buf := PackedVector2Array()
	var samples := int(SAMPLE_RATE * p_length)
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var amp := p_env.sample(t / p_length) * p_volume
		var s := amp * sin(TAU * p_freq * t)
		buf.append(Vector2(s, s))
	return buf


func _save_wav(filename: String, data: PackedVector2Array) -> void:
	var wav := AudioStreamWAV.new()
	wav.format = OUTPUT_FORMAT
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = true

	# 转换为 PackedByteArray
	var byte_data := PackedByteArray()
	byte_data.resize(data.size() * 4)  # 16-bit stereo = 4 bytes per sample
	for i in range(data.size()):
		var left := clampi(int(data[i].x * 32767.0), -32768, 32767)
		var right := clampi(int(data[i].y * 32767.0), -32768, 32767)
		byte_data[i * 4 + 0] = left & 0xFF
		byte_data[i * 4 + 1] = (left >> 8) & 0xFF
		byte_data[i * 4 + 2] = right & 0xFF
		byte_data[i * 4 + 3] = (right >> 8) & 0xFF
	wav.data = byte_data

	var path := SFX_OUTPUT_PATH + filename
	var err := ResourceSaver.save(wav, path)
	if err == OK:
		print("[SFX] Saved: ", path)
	else:
		push_error("[SFX] Failed to save: " + path + " error: " + str(err))


class Envelope:
	var _points: PackedVector2Array  # (x, y) where x is 0..1 normalized time

	func _init(points: PackedVector2Array = PackedVector2Array()) -> void:
		_points = points

	func sample(normalized_time: float) -> float:
		if _points.size() == 0:
			return 1.0
		normalized_time = clampf(normalized_time, 0.0, 1.0)
		for i in range(_points.size() - 1):
			var p0 := _points[i]
			var p1 := _points[i + 1]
			if normalized_time >= p0.x and normalized_time <= p1.x:
				var t := (normalized_time - p0.x) / (p1.x - p0.x) if p1.x > p0.x else 0.0
				return lerpf(p0.y, p1.y, t)
		return _points[_points.size() - 1].y


func _envelope_attack_decay(attack_time: float, decay_time: float) -> Envelope:
	var total := attack_time + decay_time
	return Envelope.new(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(attack_time / total, 1.0),
		Vector2(1.0, 0.0)
	]))


func _run() -> void:
	# 在编辑器中运行 EditorScript 时执行
	generate_all()