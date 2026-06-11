# Phase 3 搜索点缺陷报告

> 归档时间：2026-06-12 | 严重程度：P0 | 影响：Phase 3（阿贵认罪后→最终对峙前）

## 问题概述

阿贵对峙完成后，Phase 3 解锁 `shen_room` 和 `gambling_alley` 两个新场景，共定义 5 个搜索点，但 `search_results.json` 中仅存在 1 个对应条目，其余 4 个搜索点点击后将无响应/报错。

## 受影响的搜索点

| 场景 | 搜索点 | locations.json | search_results.json | future |
|---|---|---|---|---|
| shen_room | `shen_desk`（桌上账册） | ✅ 有定义 | ❌ 无结果 | 需补 |
| shen_room | `shen_window`（窗口望码头） | ✅ 有定义 | ❌ 无结果 | 需补 |
| shen_room | `shen_bedside`（床边草屑） | ✅ 有定义 | ✅ 有结果 | 正常（但需 `evidence_blue_herb_residue` 解锁） |
| gambling_alley | `gambling_den`（赌坊柜台） | ✅ 有定义 | ❌ 无结果 | 需补 |
| gambling_alley | `gambling_alley_wall`（后巷墙角） | ✅ 有定义 | ❌ 无结果 | 需补 |

**另外** `progression.json` 中 `gambling_alley.gambling_alley_wall` 的解锁条件拼写也指向了这个搜索点（当前无内容）。

## 最终对峙证据溯源

终极对峙 `confrontation_final` 需要 **7 件证据**，全部不来自 Phase 3 搜索点：

| 证据 | 来源 | 阶段 |
|---|---|---|
| `evidence_dock_timing` | `day_events.json` evt_phase3_transition 自动发放 | Phase 3 |
| `evidence_cargo_silver` | `wreck_site.wreck_cargo_area` 搜索 | Phase 2 |
| `evidence_drug_capsule_shell` | `wreck_site.wreck_debris` 子选项 | Phase 2 |
| `evidence_tongue_herb_residue` | `ferry_dock.dock_body_examine` 子选项 | Phase 1/2 |
| `evidence_oil_lock_residue` | `zhou_room.zhou_luggage` 或 `dock_body_examine` 子选项 | Phase 1/2 |
| `evidence_salvage_mark` | `fisherman_wang` 对话 ask_dawn_sighting | Phase 2 |
| `evidence_shen_connection` | `lao_fan` 对话 press_shen_connection | Phase 2 |

**结论**：Phase 3 新增的两个场景目前几乎无实质内容，玩家必须返回 Phase 1/2 旧场景收集证据。

## 隐藏风险

`shen_bedside` 解锁需要 `evidence_blue_herb_residue`（来源：`ferry_dock.dock_body_examine` 子选项"检查指甲缝隙"）。若玩家在 Phase 2 漏掉此选项，shen_bedside **永久锁死**。

## 修复建议

1. 为 `shen_desk`、`shen_window`、`gambling_den`、`gambling_alley_wall` 补充 `search_results.json` 条目
2. 将部分 Phase 3 所需证据的获取入口搬到 shen_room/gambling_alley，减少回退依赖
3. 考虑 `evt_shen_evidence_ready` 加入 `auto_start_confrontation: confrontation_final`（目前缺失）
4. `shen_bedside` 的 `evidence_blue_herb_residue` 前置条件可改弱或提供替代获取途径

## 相关文件

- `data/cases/prologue_ferry/locations.json` — 搜索点定义
- `data/cases/prologue_ferry/search_results.json` — 搜索结果内容
- `data/cases/prologue_ferry/progression.json` — 解锁条件
- `data/cases/prologue_ferry/day_events.json` — 事件触发
- `data/cases/prologue_ferry/evidence.json` — 证据/线索定义
