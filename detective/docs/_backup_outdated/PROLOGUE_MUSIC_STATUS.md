# 序章音乐资源状态分析

## 概述

分析序章「渡口沉舟」从探索到两次对峙的完整流程中，所有音乐/BGM资源的状态。

---

## 1. 序章音乐需求

### 1.1 直接引用的BGM

| 音乐ID | 用途 | 文件 | 状态 |
|--------|------|------|------|
| `ferry_prologue_escape` | 沉船逃生 | `ferry_prologue_escape.mp3` | ✅ |
| `ferry_prologue_shore` | 岸边救援 | `ferry_prologue_shore.mp3` | ✅ |
| `ferry_inn_investigation` | 客栈调查 | `ferry_inn_investigation.mp3` | ✅ |
| `ferry_dock_investigation` | 码头调查 | `ferry_dock_investigation.mp3` | ✅ |
| `accuse_tension` | 指认紧张 | `accuse_tension.wav` | ✅ |
| `ferry_confrontation` | 阿贵对峙 | `ferry_confrontation.mp3` | ✅ |
| `ferry_court_opening` | 法庭开场 | `Prelogue_Confrontation_Intro.mp3` | ✅ |
| `shen_corridor_theme` | 沈清月走廊 | `shen_corridor_theme.wav` | ✅ |
| `confrontation_final` | 最终对峙 | `confrontation_final.mp3` | ✅ |

**总计：9个直接引用，全部存在 ✅**

### 1.2 通过Mood标签引用的BGM

| Mood标签 | 映射的音乐 | 用途 | 状态 |
|----------|-----------|------|------|
| `mood:cabin_panic` | `ferry_prologue_escape` | 船舱恐慌 | ✅ |
| `mood:cold_relief` | `ferry_prologue_shore` | 冷静解脱 | ✅ |
| `mood:ferry_inn` | `ferry_inn_investigation` | 客栈氛围 | ✅ |
| `mood:ferry_dock` | `ferry_dock_investigation` | 码头氛围 | ✅ |
| `mood:ferry_climax` | `ferry_confrontation` | 对峙高潮 | ✅ |
| `mood:ferry_climax_final` | `confrontation_final` | 最终高潮 | ✅ |
| `mood:mystery` | `main_theme` | 神秘主题 | ✅ |
| `mood:ending_good` | `ending_warm` | 好结局 | ✅ |
| `mood:ending_bad` | `ending_cold` | 坏结局 | ✅ |

**总计：9个Mood映射，全部存在 ✅**

---

## 2. 序章流程与音乐对应

### 2.1 开场沉船逃生

| 场景 | 音乐 | 状态 |
|------|------|------|
| 独白开场 | `main_theme` (mood:mysterious) | ✅ |
| 船舱恐慌 | `ferry_prologue_escape` | ✅ |
| 岸边救援 | `ferry_prologue_shore` | ✅ |

### 2.2 客栈暖场

| 场景 | 音乐 | 状态 |
|------|------|------|
| 客栈大堂 | `ferry_inn_investigation` | ✅ |
| 夜晚对话 | `ferry_inn_investigation` | ✅ |

### 2.3 探索阶段（Phase 1）

| 地点 | 音乐 | 状态 |
|------|------|------|
| 客栈大堂 | `ferry_inn_investigation` (mood:ferry_inn) | ✅ |
| 周氏房间 | `ferry_inn_investigation` (mood:ferry_inn) | ✅ |
| 阿贵住处 | `ferry_inn_investigation` (mood:ferry_inn) | ✅ |
| 客栈走廊 | `shen_corridor_theme` | ✅ |
| 码头 | `ferry_dock_investigation` (mood:ferry_dock) | ✅ |
| 沉船打捞处 | `ferry_dock_investigation` (mood:ferry_dock) | ✅ |

### 2.4 探索阶段（Phase 2）

| 地点 | 音乐 | 状态 |
|------|------|------|
| 江湾渔村 | `ferry_dock_investigation` (mood:ferry_dock) | ✅ |

### 2.5 发现尸体

| 场景 | 音乐 | 状态 |
|------|------|------|
| 码头骚动 | `ferry_dock_investigation` | ✅ |
| 指认紧张 | `accuse_tension` | ✅ |

### 2.6 阿贵对峙（中BOSS）

| 场景 | 音乐 | 状态 |
|------|------|------|
| 对峙开场 | `ferry_court_opening` | ✅ |
| 对峙进行 | `ferry_confrontation` | ✅ |
| 对峙击破 | `ferry_confrontation` | ✅ |

### 2.7 探索阶段（Phase 3）

| 地点 | 音乐 | 状态 |
|------|------|------|
| 沈清月房间 | `shen_corridor_theme` | ✅ |
| 赌坊 | `ferry_dock_investigation` (mood:ferry_dock) | ✅ |

### 2.8 沈清月对峙（FINAL BOSS）

| 场景 | 音乐 | 状态 |
|------|------|------|
| 对峙开场 | `ferry_court_opening` | ✅ |
| 对峙进行 | `ferry_confrontation` | ✅ |
| 最终击破 | `confrontation_final` | ✅ |

### 2.9 结局

| 场景 | 音乐 | 状态 |
|------|------|------|
| 完美结局 | `ending_warm` (mood:ending_good) | ✅ |
| 坏结局 | `ending_cold` (mood:ending_bad) | ✅ |

---

## 3. 音乐文件清单

### 3.1 序章专属音乐（9个）

| 文件名 | 格式 | 大小 | 用途 |
|--------|------|------|------|
| `ferry_prologue_escape.mp3` | MP3 | - | 沉船逃生 |
| `ferry_prologue_shore.mp3` | MP3 | - | 岸边救援 |
| `ferry_inn_investigation.mp3` | MP3 | - | 客栈调查 |
| `ferry_dock_investigation.mp3` | MP3 | - | 码头调查 |
| `ferry_confrontation.mp3` | MP3 | - | 对峙 |
| `confrontation_final.mp3` | MP3 | - | 最终对峙 |
| `Prelogue_Confrontation_Intro.mp3` | MP3 | - | 对峙开场 |
| `shen_corridor_theme.wav` | WAV | - | 沈清月主题 |
| `accuse_tension.wav` | WAV | - | 指认紧张 |

### 3.2 共享音乐（3个）

| 文件名 | 格式 | 用途 |
|--------|------|------|
| `main_theme.wav` | WAV | 主题曲/神秘氛围 |
| `ending_warm.wav` | WAV | 好结局 |
| `ending_cold.wav` | WAV | 坏结局 |

---

## 4. 音乐配置分析

### 4.1 bgm_config.json 配置

```json
{
  "locations": {
    "ferry_inn": "mood:ferry_inn",
    "zhou_room": "mood:ferry_inn",
    "agui_room": "mood:ferry_inn",
    "inn_corridor": "track:shen_corridor_theme",
    "shen_room": "track:shen_corridor_theme",
    "gambling_alley": "mood:ferry_dock",
    "ferry_dock": "mood:ferry_dock",
    "wreck_site": "mood:ferry_dock",
    "river_bend": "mood:ferry_dock"
  },
  "states": {
    "prologue": "mood:cabin_panic",
    "main_theme": "mood:cold_relief",
    "accuse": "mood:ferry_climax",
    "ending_perfect": "mood:ending_good",
    "ending_good": "mood:ending_good",
    "ending_bad": "mood:ending_bad",
    "epilogue_meta": "mood:mystery",
    "confrontation_final": "mood:ferry_climax_final"
  }
}
```

**配置完整性：✅ 全部正确**

### 4.2 Confrontations.csv 配置

| 对峙ID | bgm | bgm_break | bgm_break_actual | bgm_final_round | 状态 |
|--------|-----|-----------|------------------|-----------------|------|
| confrontation_wang | `ferry_confrontation` | `ferry_court_opening` | `ferry_court_opening` | `ferry_confrontation` | ✅ |
| confrontation | `ferry_confrontation` | `ferry_court_opening` | `ferry_court_opening` | `ferry_confrontation` | ✅ |
| confrontation_final | `confrontation_final` | `ferry_court_opening` | `ferry_court_opening` | `confrontation_final` | ✅ |

**注意：** `bgm_break` 保留给开场阶段兼容旧流程；击破证词后的实际切曲使用 `bgm_break_actual`。

---

## 5. 配置确认

### 5.1 击破后的仪式感开场曲

`ferry_court_opening` 已在 registry.json 中注册，并通过 `bgm_break_actual` 作为击破证词后的背景音乐，气质偏庄重公堂开场。

---

## 6. 总结

### 6.1 资源统计

| 类别 | 数量 | 状态 |
|------|------|------|
| 序章专属音乐 | 9个 | ✅ 全部存在 |
| 共享音乐 | 3个 | ✅ 全部存在 |
| **总计** | **12个** | ✅ **全部齐全** |

### 6.2 结论

**序章的所有音乐资源都已经完整存在，没有缺失。**

从开场沉船逃生、客栈暖场、三阶段探索、到两次对峙（阿贵、沈清月），所有BGM都已经齐全。

### 6.3 建议维护

1. **击破曲配置**：新增对峙时优先使用 `bgm_break_actual` 表示击破证词后的背景音乐，避免和开场音乐混用。

---

*文档版本：1.0*
*最后更新：2026-06-07*
