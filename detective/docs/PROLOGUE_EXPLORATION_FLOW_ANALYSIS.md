# 序章「渡口沉舟」探索流程分析

> 归档日期：2026-06-02
> 基于：CANON 剧本基准 + CSV 数据验证

---

## 一、最终流程确认

```
船舱阶段（phase_0）——教学+初探
    ↓
王大爷对峙（第一轮，由沉船事件自动触发）
    ↓
探索环节A（phase_1 + phase_2）——收集老范/阿贵相关证据
    ↓
老范对峙（第二轮，崩溃甩锅阿贵）
    ↓
阿贵对峙（第三轮，认罪供出"有人教"）
    ↓
[凌瑶2-3句分析过渡]
    ↓
探索环节B（phase_3）——收集沈清月相关证据
    ↓
沈清月对峙（第四轮·终局）
```

---

## 二、两次探索的必要性

### 为什么一次探索不够？

沈清月的4条关键证据（打捞痕迹、草药香囊、沈父药账、赌坊中间人）**在阿贵招供之前根本不存在于游戏世界中**：

| 证据 | 来源 | 解锁条件 |
|------|------|---------|
| evidence_salvage_mark | fisherman_wang.ask_dawn_sighting | flag: agui_confessed_mastermind |
| evidence_herb_sachet | shen_room.shen_bedside | flag: agui_confessed_mastermind |
| evidence_father_ledger | shen_room.shen_desk | flag: agui_confessed_mastermind |
| evidence_shen_connection | lao_fan.press_shen_connection | flag: agui_confessed_mastermind |

渔村（phase_2）和沈清月房间（phase_3）都是条件解锁的。阿贵不招，这些地方去不了、东西拿不到。

### 探索环节A（phase_1/2）收集什么？

支撑老范+阿贵两轮对峙的全部证据：
- 沉船物证（破洞、钉痕、浮囊）
- 赌债字据
- 遣散字据
- 验尸报告（无钝器伤）
- 王大爷的各种证词（航道、密谈、时间矛盾）

### 探索环节B（phase_3）收集什么？

支撑沈清月终局对峙的证据：
- 草药香囊（沈清月房间床边）
- 沈父药账（沈清月房间桌案）
- 赌坊中间人线索（老范崩溃后吐露）
- 下游打捞痕迹（王大爷新对话分支）

---

## 三、阿贵→沈清月的过渡设计

老范对峙后他已经崩溃并甩锅阿贵，堂上气氛是"两个骗子互咬"。此时停下来探索会冷掉节奏。

阿贵对峙后，建议加一个**2-3句的凌瑶分析独白**作为节奏缓冲：

> 凌瑶："阿贵说有人教他凿船的位置、选航道……老范？他连自己的赌债都理不清。教阿贵的人，在堂下坐着呢。"

然后玩家进入探索环节B，最后直面沈清月。

---

## 四、对峙解锁条件（来自 progression_unlocks.csv）

### 阿贵对峙（confrontation）
```json
{
  "all": [
    "evidence_hull_hole",
    "evidence_float_bladder",
    "evidence_no_blunt_trauma",
    "evidence_wrong_channel",
    "clue_fan_alibi_hole",
    "evidence_dismissal_note",
    "evidence_gambling_iou"
  ]
}
```

### 沈清月终局（confrontation_final）
```json
{
  "all": [
    "flag: agui_confessed_mastermind",
    "evidence_cargo_silver",
    "evidence_salvage_mark",
    "evidence_shen_connection",
    "evidence_dock_timing",
    "evidence_herb_sachet"
  ]
}
```

---

## 五、已知差距（需修复）

| 编号 | 问题 | 严重度 | 修复方案 |
|------|------|--------|---------|
| GAP-1 | evidence_father_ledger 无获取来源 | P0 | 在 shen_room.shen_desk 的 search_results 中添加 |
| GAP-2 | gambling_alley 2个搜索点无 search_results | P0 | 补充赌坊场景的搜索产出（中间人线索/赌坊账册等） |
| GAP-3 | gambling_alley 无 NPC | P1 | 确认是否需要赌坊NPC或仅搜索场景 |
