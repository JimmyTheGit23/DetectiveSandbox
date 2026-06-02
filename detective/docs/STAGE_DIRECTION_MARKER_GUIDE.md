# 舞台指示标记规范

> 创建时间：2026-06-02 09:20
> 状态：待实装

---

## 问题

对话文本中混有大量括号舞台指示，如：
- `（低声）`
- `（看着香囊，忽然笑了）`
- `（转身向门外走去）`
- `（猛地站起来，指着陆昭）`

这些**不应作为对话文字显示给玩家**，而应转化为表情/动作触发。

---

## 标记规范

### 格式

将舞台指示从对话文本中提取，用 `[stage:...]` 标记包裹：

**旧格式（当前）：**
```json
{
  "text": "（低声）先让王大爷把那天夜里看到的东西说出来。"
}
```

**新格式（目标）：**
```json
{
  "text": "先让王大爷把那天夜里看到的东西说出来。",
  "stage_direction": "低声"
}
```

### 分类

舞台指示分为三类：

| 类型 | 示例 | 用途 |
|------|------|------|
| **语气/音量** | 低声、大声、叹气、冷笑 | 触发语音音量/语调变化 |
| **表情/动作** | 看着香囊笑了、猛地站起来、双手抱头 | 触发立绘表情差分/动画 |
| **环境/叙述** | 雨声压在屋檐上、人群一阵骚动 | 触发场景效果/BGM切换 |

### 渲染规则

- 有 `stage_direction` 字段时：文本只显示 `"text"` 内容，`stage_direction` 用于触发表情/动作
- 无 `stage_direction` 字段时：若 text 中包含 `（...）`，引擎应自动提取并隐藏括号内容

---

## 影响范围

| 文件 | 括号舞台指示数量 | 优先级 |
|------|----------------|--------|
| `case.json`（对峙系统） | ~296 处 | 高 |
| `dialogues/shen_qingyue.json` | ~5 处 | 高 |
| `dialogues/zhou_wife.json` | ~3 处 | 中 |
| `dialogues/agui_cabin.json` | ~2 处 | 中 |
| `dialogues/lao_fan_cabin.json` | ~3 处 | 中 |
| `dialogues/zhou_de_gui_cabin.json` | ~2 处 | 中 |
| `prologue.json`（开场脚本） | ~10 处 | 中 |

**总计：约 320+ 处**

---

## 实施计划

### Phase 1：自动提取（推荐）
在对话渲染引擎中添加自动处理：
```gdscript
func _process_stage_direction(text: String) -> Dictionary:
    var regex = RegEx.new()
    regex.compile("^(（[^）]+）)(.*)$")
    var result = regex.search(text.strip_edges())
    if result:
        return {
            "stage": result.get_string(1).trim_prefix("（").trim_suffix("）"),
            "clean_text": result.get_string(2).strip_edges()
        }
    return {"stage": "", "clean_text": text}
```

### Phase 2：手动标记关键指示
对高优先级文件（case.json 对峙、shen_qingyue.json），手动添加 `stage_direction` 字段。

### Phase 3：表情差分联动
将舞台指示映射到立绘表情差分：
- "低声" → whisper 表情
- "笑了" → smile 表情  
- "猛地站起来" → stand_up 动画
- "双手抱头" → collapse 表情

---

## 备注

- 当前所有括号指示均保留原样，不做批量删除
- 待表情系统就绪后统一处理
- 游戏引擎渲染时可先用正则自动隐藏括号内容
