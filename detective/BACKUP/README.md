# 美术资源清理备份报告

**日期**: 2026-06-02
**备份位置**: `BACKUP/`
**总计**: 218 个文件, 194.86 MB

---

## 备份清单

### 1. BGM (`BACKUP/bgm/`)
| 文件 | 原因 |
|------|------|
| `Prelogue_Confrontation_Intro.mp3` | 拼写错误(Prelogue)，未在 bgm/registry.json 中注册 |
| `_old_backup/` (42 files) | 旧备份文件夹 |
| `backup/` (6 files) | 备份文件夹 |

### 2. 立绘 (`BACKUP/portraits/`)
| 文件/目录 | 原因 |
|-----------|------|
| `_backup_before_rembg/` (16 files) | 旧备份文件夹 |
| `_backup_xunyang_fix/` (20 files) | 旧备份文件夹 |
| `anim_test/` (6 files) | 动画测试文件 |
| `avatars/` (20 files) | 未被任何代码/数据引用 (头像由代码动态生成) |
| `actor_dock_servant.png` | 未在 actors/registry.json 中注册 |
| `xiao_cui_idle_0.png` | 未被引用 |
| `xiao_cui_idle_1.png` | 未被引用 |
| `prologue_agui_broken.png` | 未在 portrait_expressions.json 中注册 |
| `lu_zhao_cold.png` | 未被引用 (仅 `prologue_lu_zhao_cold.png` 被使用) |
| `lu_zhao_serious.png` | 未被引用 (仅 `prologue_lu_zhao_serious.png` 被使用) |
| `lu_zhao_surprised.png` | 未被引用 (仅 `prologue_lu_zhao_surprised.png` 被使用) |
| `lu_zhao_confrontation_pose.png` | 未被引用 |
| `prologue_lu_zhao.png.import45105557904.tmp` | 临时文件 |

### 3. 场景 (`BACKUP/scenes/`)
| 文件 | 原因 |
|------|------|
| `_backup_prologue_cg_zhou_kneel.png` | 旧备份 |
| `Chinese_ink_wash_painting_styl_2026-05-20T03-27-08.png` | AI 生成测试 |
| `Chinese_ink_wash_painting_styl_2026-05-20T03-27-14.png` | AI 生成测试 |
| `body_overlay.png` | 未被引用 |
| `drugshop_overlay.png` | 未被引用 |
| `ledger_overlay.png` | 未被引用 |
| `title_screen.png.bak` | 备份文件 |

### 4. UI 图标 (`BACKUP/ui/`)
| 文件 | 原因 |
|------|------|
| `icon_accuse.png` | 未被引用 (仅 `icon_settings_seal.png` 被 MainGame.gd 使用) |
| `icon_discuss.png` / `icon_discuss_old.png` | 未被引用 |
| `icon_map.png` | 未被引用 |
| `icon_move.png` / `icon_move_old.png` | 未被引用 |
| `icon_notebook.png` / `icon_notebook_old.png` | 未被引用 |
| `icon_search.png` / `icon_search_old.png` | 未被引用 |
| `icon_settings.png` / `icon_settings_old.png` | 未被引用 |
| `icon_talk.png` / `icon_talk_old.png` | 未被引用 |

### 5. AI 处理对象 (`BACKUP/ai_processed_objects/`)
| 文件 | 原因 |
|------|------|
| `barrel.png` | 维多利亚风格道具，未被引用 |
| `evidence_marker.png` | 未被引用 |
| `fountain.png` | 未被引用 |
| `gas_lamp.png` | 未被引用 |
| `manhole.png` | 未被引用 |
| `notice_board.png` | 未被引用 |
| `park_bench.png` | 未被引用 |
| `police_tape.png` | 未被引用 |
| `shop_building.png` | 未被引用 |
| `wall_sconce.png` | 未被引用 |

### 6. AI 原始肖像 (`BACKUP/ai_raw_portraits/`)
- 28 个文件 — AI 生成的原始肖像源文件，处理后的版本在 `ai_processed/` 中

---

## 因文件锁定未能移动

以下文件因 Godot 编辑器正在使用而无法移动，需关闭编辑器后手动处理：

- `assets/cn/scenes/incense_overlay.png` (及 .import)
- `assets/cn/ui/icon_search.png.import`
- `assets/cn/ui/icon_settings.png.import`

---

## 保留的在用资源

以下资源经确认在游戏中被引用，**未移动**：

- `assets/cn/bgm/` — 24 首 BGM (全部在 registry.json 中注册)
- `assets/cn/portraits/` — 演员立绘 + 序章角色立绘 + 凌瑶表情变体
- `assets/cn/scenes/` — 所有场景背景 (registry.json + locations.json + prologue.json 引用)
- `assets/cn/sfx/` — 音效文件 (动态加载)
- `assets/cn/voices/` — 语音文件 (按案件隔离加载)
- `assets/cn/title_props/` — 标题画面道具 (MainGame.gd 引用)
- `assets/cn/ui/icon_settings_seal.png` — 唯一被引用的 UI 图标
- `assets/cn/era_backgrounds/` — 时代选择背景 (CaseSelectPanel.gd 引用)
- `assets/cn/theme.tres` — 全局主题 (project.godot 引用)
- `assets/cn/portrait_fade.gdshader` — 立绘淡入淡出着色器
- `assets/ai_processed/objects/evidence_icons/` — 证据图标 (动态加载)
