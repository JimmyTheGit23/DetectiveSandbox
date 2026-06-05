# 对话界面（DialogueBox）优化空间深度分析

> 基于 [`DialogueBox.gd`](scripts/ui/DialogueBox.gd:1) 全量 1869 行代码审查

---

## 一、当前对话界面能力清单

### 1.1 已实现的功能

| 功能 | 代码位置 | 完成度 |
|------|---------|--------|
| 底部对话框（金边纸色） | [`_apply_dialogue_chrome()`](scripts/ui/DialogueBox.gd:786) | ✅ 完成 |
| 说话人名字牌 | [`_build_dialogue_frame()`](scripts/ui/DialogueBox.gd:738) | ✅ 完成 |
| 打字机逐字显示 | [`TypewriterEffect.gd`](scripts/ui/TypewriterEffect.gd:1) | ✅ 完成 |
| 打字音效（角色profile） | [`_resolve_blip_profile()`](scripts/ui/DialogueBox.gd:255) | ✅ 完成 |
| NPC居中大立绘 | [`_apply_speaker()`](scripts/ui/DialogueBox.gd:437) | ✅ 完成 |
| 主角/助手左下角头像 | [`_show_avatar()`](scripts/ui/DialogueBox.gd:551) | ✅ 完成 |
| 说话动画帧循环 | [`_start_talk_animation()`](scripts/ui/DialogueBox.gd:621) | ✅ 完成 |
| 眨眼循环 | [`_start_blink_loop()`](scripts/ui/DialogueBox.gd:663) | ✅ 完成 |
| 立绘表情切换 | [`_resolve_emotion_portrait()`](scripts/ui/DialogueBox.gd:1498) | ✅ 完成 |
| 选项系统（分类/分组） | [`_show_options()`](scripts/ui/DialogueBox.gd:1045) | ✅ 完成 |
| 选项类型标签（问/追问/观察/呈证） | [`_option_type_info()`](scripts/ui/DialogueBox.gd:1193) | ✅ 完成 |
| 已读选项✓标记 | [`_show_options()`](scripts/ui/DialogueBox.gd:1054) | ✅ 完成 |
| 对话日志面板 | [`_build_log_controls()`](scripts/ui/DialogueBox.gd:902) | ✅ 完成 |
| 叙述模式 | [`show_narration()`](scripts/ui/DialogueBox.gd:175) | ✅ 完成 |
| 叙述选项 | [`show_narration_choices()`](scripts/ui/DialogueBox.gd:319) | ✅ 完成 |
| 全屏闪白/闪红 | [`flash_screen()`](scripts/ui/DialogueBox.gd:708) | ✅ 完成 |
| 角色震动 | [`shake_character()`](scripts/ui/DialogueBox.gd:715) | ✅ 完成 |
| 角色特写放大 | [`zoom_character()`](scripts/ui/DialogueBox.gd:728) | ✅ 完成 |
| 关键词高亮（红色加粗） | [`_decorate_text()`](scripts/ui/DialogueBox.gd:1474) | ✅ 完成 |
| 括号内容变色（旁白/动作） | [`_decorate_text()`](scripts/ui/DialogueBox.gd:1489) | ✅ 完成 |
| 证物出示演出 | [`_play_evidence_present_fx()`](scripts/ui/DialogueBox.gd:1782) | ✅ 完成 |
| 笔记记录演出 | [`_play_record_fx()`](scripts/ui/DialogueBox.gd:1702) | ✅ 完成 |
| 立绘透明像素裁剪 | [`_crop_texture_to_visible_alpha()`](scripts/ui/DialogueBox.gd:1599) | ✅ 完成 |
| 立绘缓存系统 | [`_portrait_texture_cache`](scripts/ui/DialogueBox.gd:93) | ✅ 完成 |
| 边缘渐隐shader | [`_setup_avatar_portrait()`](scripts/ui/DialogueBox.gd:501) | ✅ 完成 |

### 1.2 功能完成度评估

**对话界面功能完成度约 85%**，核心交互链路（说话→打字→点击→选项→反馈）已完整。剩余 15% 主要是演出效果和体验细节。

---

## 二、可优化项（按影响/工作量矩阵排序）

### 🔴 高影响 · 低工作量

#### 1. 对话框缺少"点击继续"指示器动画

**现状**：[`_choice_hint_label`](scripts/ui/DialogueBox.gd:872) 显示静态文字 "▼ 点击继续"

**问题**：静态 ▼ 符号容易被忽略，玩家可能不知道该点哪里

**建议**：让 ▼ 做上下脉动动画（与逆转裁判一致）

```gdscript
# 在 _set_choice_hint 中，当 is_visible=true 时启动脉动
func _start_hint_pulse() -> void:
    if _choice_hint_tween and _choice_hint_tween.is_valid():
        _choice_hint_tween.kill()
    _choice_hint_tween = create_tween().set_loops()
    _choice_hint_tween.tween_property(_choice_hint_label, "offset:y",
        _choice_hint_label.offset_top - 3.0, 0.5)
    _choice_hint_tween.tween_property(_choice_hint_label, "offset:y",
        _choice_hint_label.offset_top, 0.5)
```

**工作量**：0.5小时

---

#### 2. 叙述模式与普通对话缺少视觉差异化

**现状**：[`show_narration()`](scripts/ui/DialogueBox.gd:175) 复用同一个对话框，仅隐藏立绘

**问题**：玩家难以区分"NPC说话"和"旁白叙述"

**建议**：
- 叙述模式下对话框背景色偏暗/偏灰（如 `Color(0.02, 0.015, 0.01, 0.88)`）
- 叙述模式下文字颜色改为斜体风格（`[i]` 标签）
- 叙述模式下说话人名字改为"——"或隐藏

**工作量**：1小时

---

#### 3. 选项按钮缺少悬浮音效

**现状**：[`_make_option_button()`](scripts/ui/DialogueBox.gd:1180) 无鼠标悬浮音效

**问题**：选项交互缺少声音反馈，降低沉浸感

**建议**：在 `mouse_entered` 时播放 `ui_hover.wav`（资源已存在于 `assets/cn/sfx/`）

```gdscript
btn.mouse_entered.connect(func():
    var sfx = load("res://assets/cn/sfx/ui_hover.wav")
    if sfx:
        var player = AudioStreamPlayer.new()
        player.stream = sfx
        player.volume_db = -8
        player.play()
        player.finished.connect(player.queue_free)
)
```

**工作量**：0.5小时

---

#### 4. 立绘切换缺少过渡动画

**现状**：[`_apply_speaker()`](scripts/ui/DialogueBox.gd:437) 中 NPC 立绘切换时有淡入动画（0.25s），但**没有淡出**——新立绘直接覆盖旧立绘

**问题**：说话人切换时画面闪烁感，不像逆转裁判那样平滑

**建议**：
- 旧立绘先淡出（0.15s）→ 新立绘淡入（0.25s）
- 或使用 crossfade：旧立绘淡出的同时新立绘淡入

**工作量**：2小时

---

### ⚠️ 中影响 · 中工作量

#### 5. 对话日志面板位置/交互不直观

**现状**：
- 日志按钮 [`_log_button`](scripts/ui/DialogueBox.gd:903) 在对话框右上角，文字"卷宗回看"
- 日志面板 [`_log_panel`](scripts/ui/DialogueBox.gd:927) 在屏幕右上角浮动

**问题**：
- 按钮位置隐蔽，玩家可能不知道有此功能
- 面板尺寸固定（516×380），长对话时需要滚动
- 面板遮挡对话区域

**建议**：
- 日志按钮改为对话框内左上角（说话人名字旁边），用 📜 图标
- 面板改为从右侧滑入的全屏半透明层（类似逆转裁判的法庭记录）
- 添加搜索功能（按说话人/关键词过滤）

**工作量**：4小时

---

#### 6. 关键词高亮系统需要数据驱动

**现状**：[`KEYWORD_HIGHLIGHTS`](scripts/ui/DialogueBox.gd:66) 硬编码了15个关键词

**问题**：
- 新增关键词需要改代码
- 不同案件的关键词不同
- 高亮样式固定（红色加粗 28px），无法按重要度分级

**建议**：
- 关键词从 CSV/JSON 配置加载
- 支持多级高亮：
  - **一级**（红色加粗）：决定性证据关键词
  - **二级**（金色下划线）：线索关键词
  - **三级**（灰色斜体）：背景信息

**工作量**：3小时

---

#### 7. 主角/助手头像缺少入场动画

**现状**：[`_show_avatar()`](scripts/ui/DialogueBox.gd:551) 注释写"无动画直接显示"，直接设置 `modulate.a = 1.0`

**问题**：主角说话时头像突然出现，缺乏过渡

**建议**：添加从左滑入+淡入的动画（类似逆转裁判主角从左侧切入）

```gdscript
func _show_avatar(speaker: String, portrait_path: String, emotion: String = "") -> void:
    # ... 设置 texture ...
    _avatar_rect.modulate.a = 0.0
    _avatar_rect.position.x = AVATAR_OFFSET_LEFT - 40.0  # 从左侧偏移开始
    var tw := create_tween().set_parallel(true)
    tw.tween_property(_avatar_rect, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC)
    tw.tween_property(_avatar_rect, "position:x", AVATAR_OFFSET_LEFT, 0.2).set_trans(Tween.TRANS_CUBIC)
```

**工作量**：1小时

---

#### 8. 选项列表滚动支持

**现状**：[`_top_options_panel`](scripts/ui/DialogueBox.gd:983) 使用固定高度，选项多时（>8个）通过缩小按钮高度和间距适配

**问题**：选项过多时按钮变得很小，阅读困难

**建议**：
- 当选项 > 6 个时，将 `_top_options_vbox` 包裹在 `ScrollContainer` 中
- 限制面板最大高度为 viewport 高度的 50%
- 保持当前选项的分类逻辑（问话/追问/观察分组）

**工作量**：2小时

---

#### 9. 对话框"名字牌"样式增强

**现状**：[`_speaker_plate`](scripts/ui/DialogueBox.gd:741) 是透明背景的 PanelContainer，名字直接写在对话框内

**问题**：说话人名字与正文视觉层级不够分明

**建议**：
- 给名字牌添加半透明深色背景（与逆转裁判一致）
- 名字牌左侧添加竖线装饰（金色 2px）
- 不同角色名字使用不同颜色（主角=金、助手=青、NPC=白、旁白=灰）

```gdscript
# 名字牌样式
plate_style.bg_color = Color(0.08, 0.05, 0.02, 0.75)
plate_style.border_width_left = 3  # 左侧金色竖线
plate_style.border_color = Color(0.85, 0.65, 0.25, 0.9)
```

**工作量**：1小时

---

### 💡 低影响 · 锦上添花

#### 10. 打字速度可调（快进模式）

**现状**：[`TypewriterEffect.gd`](scripts/ui/TypewriterEffect.gd:27) 的 `base_char_delay = 0.04` 固定

**建议**：
- 长按空格/点击时临时加速 2x
- 设置面板中添加"文字速度"滑块（慢/中/快/极快）
- 已读对话自动快进（与逆转裁判重制版一致）

**工作量**：3小时

---

#### 11. 对话框边缘装饰

**现状**：对话框是纯色 `StyleBoxFlat`（[`_apply_dialogue_chrome()`](scripts/ui/DialogueBox.gd:786)）

**建议**：
- 对话框顶部添加金色细线装饰（与 RightMenu 的 TopTrim 一致）
- 对话框四角添加小花纹（用 9-patch 纹理替代纯圆角）
- 对话框底部添加轻微渐变（与场景融合）

**工作量**：4小时（需要新纹理资源）

---

#### 12. 立绘"情绪粒子"效果

**现状**：[`SceneFXLayer.gd`](scripts/ui/SceneFXLayer.gd) 已有场景粒子系统

**建议**：
- 角色情绪激动时（如 `emotion: angry`），在立绘周围添加红色粒子
- 角色紧张时（`emotion: nervous`），添加汗滴粒子
- 角色悲伤时（`emotion: sad`），添加雨滴粒子

**工作量**：6小时（需要粒子模板）

---

#### 13. 对话框自适应高度

**现状**：[`DIALOGUE_FRAME_HEIGHT = 222.0`](scripts/ui/DialogueBox.gd:79) 固定

**建议**：
- 短文本（<20字）时对话框缩小高度
- 长文本（>80字）时对话框扩大高度
- 过渡动画平滑调整

**工作量**：2小时

---

#### 14. 快捷键提示

**现状**：对话界面无快捷键提示

**建议**：在对话框右下角显示小字提示：
- 空格/回车 = 继续
- Tab = 笔记本
- Esc = 设置
- L = 对话日志

**工作量**：1小时

---

## 三、优化优先级路线图

### Phase 1：立即可做（1-2天）

| # | 优化项 | 工作量 | 预期效果 |
|---|-------|--------|---------|
| 1 | ▼ 继续指示器脉动动画 | 0.5h | 玩家明确知道"该点了" |
| 2 | 叙述模式视觉差异化 | 1h | 区分旁白和对话 |
| 3 | 选项悬浮音效 | 0.5h | 交互反馈感 |
| 9 | 名字牌样式增强 | 1h | 说话人辨识度 |
| 14 | 快捷键提示 | 1h | 新手引导 |
| **小计** | | **4h** | |

### Phase 2：核心体验提升（3-5天）

| # | 优化项 | 工作量 | 预期效果 |
|---|-------|--------|---------|
| 4 | 立绘切换过渡动画 | 2h | 对话流畅度 |
| 5 | 日志面板重构 | 4h | 信息管理体验 |
| 7 | 主角头像入场动画 | 1h | 角色存在感 |
| 8 | 选项列表滚动支持 | 2h | 多选项场景 |
| **小计** | | **9h** | |

### Phase 3：系统级改进（1-2周）

| # | 优化项 | 工作量 | 预期效果 |
|---|-------|--------|---------|
| 6 | 关键词高亮数据驱动 | 3h | 可维护性 |
| 10 | 打字速度可调/快进 | 3h | 重玩体验 |
| 11 | 对话框边缘装饰 | 4h | 视觉品质 |
| 13 | 对话框自适应高度 | 2h | 布局灵活性 |
| **小计** | | **12h** | |

### Phase 4：锦上添花（可选）

| # | 优化项 | 工作量 | 预期效果 |
|---|-------|--------|---------|
| 12 | 情绪粒子效果 | 6h | 沉浸感 |

---

## 四、与逆转裁判对话界面对比总结

| 维度 | 逆转裁判 | 本作当前 | 优化后预期 |
|------|---------|---------|-----------|
| 对话框外观 | 金边黑底+名字牌 | ✅ 一致 | ✅ 增强名字牌 |
| 打字机效果 | 逐字+音效 | ✅ **超越**（节奏控制更精细） | — |
| 继续指示器 | ▼ 脉动 | ⚠️ 静态 ▼ | ✅ 脉动动画 |
| 选项系统 | 无（纯线性） | ✅ **超越**（分类+分组+已读标记） | — |
| 立绘切换 | 淡入淡出 | ⚠️ 仅淡入无淡出 | ✅ 交叉淡入淡出 |
| 主角出场 | 从左滑入 | ⚠️ 直接出现 | ✅ 滑入动画 |
| 叙述模式 | 独立视觉风格 | ⚠️ 复用对话框 | ✅ 暗色+斜体 |
| 对话日志 | 重制版有 | ✅ 有 | ⚠️ 位置/交互需优化 |
| 快进功能 | 长按快进 | ❌ 无 | 待实现 |
| 情绪演出 | 表情变化+抖动 | ✅ 有 | ✅ 可加粒子 |

**结论**：对话界面核心功能已完善，主要差距在**演出细节**（过渡动画、视觉差异化、交互反馈）。Phase 1 的 4 小时优化即可显著提升体验。
