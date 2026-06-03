# 回归测试 SOP

> **用途**: 每次完成一个任务（M2 / M1.x / 新案件 / 资产改造 / UI 改造 …）后**必跑**的回归基线。  
> **目的**: 防止"这次改了 A 顺便改坏了 B"——尤其当改动跨越数据层 / 运行时 / 工具链时。  
> **执行者**: AI 助手（CodeBuddy 等）应在任务结尾**主动调用**这套回归。

---

## 二层结构

| 层 | 是什么 | 何时跑 | 失败如何处理 |
|----|--------|-------|------------|
| **L1 静态回归** | Python 脚本，不依赖 Godot | **每次任务必跑** | 必须修复后才能交付 |
| **L2 运行时回归** | MCP 调用 + GDScript 注入 | 关键变更（autoload / 资产路径 / 主菜单 / 主场景）才跑 | 必须修复后才能交付 |

---

## L1 静态回归 — `tools/regression/run_static.py`

### 执行

```bash
cd <project_root>
python3 tools/regression/run_static.py
```

退出码：`0` 全绿；非 0 说明哪一段失败，详情见 stderr。

### 检查项

1. **资产注册表 + 案件引用**（`tools/validate_registry.py`）
   - 三大注册表中的所有 portrait/background/wav 文件实际存在
   - 案件 `casting.json` 的 actor_id 引用合法
   - 案件 `locations.json.scene_type` 引用合法
   - 案件 `bgm_config.json` 的 `mood:`/`track:` 引用合法

2. **案件目录必备文件**
   - 每个 `data/cases/<case_id>/` 必须有 11 份基础 JSON + `dialogues/` 目录
   - 缺一不可（PCG 生成的案件也必须达标）

3. **casting 与 npcs.json 角色集对齐**
   - `npcs.json` 中的 NPC 必须全部出现在 `casting.json`
   - `dialogues/<id>.json` 的 `id` 必须对应 `casting` 中的角色
   - casting 多于 npcs 是允许的（玩家或纯叙事角色）

4. **PCG 模板 schema + 健康检查**
   - 所有 `tools/pcg/templates/*.json` 通过 `tools/pcg/schemas/template_schema.json` 校验
   - 所有模板通过 `tools/pcg/inspect_template.py --all --brief` 的 10 条健康规则

5. **语音清单刷新**
   - 自动跑 `tools/audit_voices.py`，刷新 `docs/MISSING_VOICES.md`
   - 缺失语音不算 FAIL，仅做记录（语音通常滞后于剧情）

---

## L2 运行时回归 — Godot MCP

### 前置条件

- Godot 4.5+ 编辑器已打开本项目
- `Godot MCP Pro` 插件已启用，底部面板绿点
- AI 助手已能调用 `godot-mcp-pro` MCP server

### 步骤（AI agent 按此调度）

**Step 1：环境检查**
```
mcp_call_tool godot-mcp-pro.get_project_info
mcp_call_tool godot-mcp-pro.get_editor_errors  # 必须 errors=[]
```

**Step 2：启动主场景**
```
mcp_call_tool godot-mcp-pro.play_scene  args={"mode":"main"}
```

**Step 3：截屏（标题画面基线）**
```
mcp_call_tool godot-mcp-pro.get_game_screenshot  args={"save_path":"res://.codebuddy/regression_title.png"}
```

**Step 4：注入运行时回归脚本**

读取 `tools/regression/runtime_check.gd` 的全部内容（除注释外的代码部分），作为 `code` 参数传入：

```
mcp_call_tool godot-mcp-pro.execute_game_script  args={"code": "<runtime_check.gd 内容>"}
```

**期望输出（关键判定）**：
```
case_id=<当前案件>
actors_count=8
scenes_count=9
tracks_count=8
casting_count=<案件 casting 角色数>
bad_npc=0          ← 必须为 0
bad_loc=0          ← 必须为 0
bgm_keys=<数量>
bad_bgm=0          ← 必须为 0
bgm_current=<当前播放的曲目 id，非空>
REGRESSION=PASS    ← 关键标志
```

**Step 5：可选——验证主场景截图（玩家进入序章后）**

如果回归任务覆盖到主玩法，调用 `click_button_by_text` 进序章 → 等帧 → 再截图。

**Step 6：清理**
```
mcp_call_tool godot-mcp-pro.stop_scene
```

### 多案件回归（推荐）

当改动了案件加载逻辑（`GameManager.switch_case`、`_index.json`、AssetResolver 等），应**对每个已注册的案件各跑一次 L2 回归**：

```
对每个 case_id in data/cases/_index.json.cases:
  1) execute_editor_script: 修改 user://current_case.json 写入目标 case_id（或调 GameManager.switch_case）
  2) play_scene
  3) 跑 runtime_check.gd
  4) 比较 case_id == 期望
  5) stop_scene
```

---

## 何时该跑哪一层？

| 任务类型 | L1 | L2 | 备注 |
|---------|:---:|:---:|------|
| 改 PCG 模板（添加 / 修改 .json） | ✅ | — | 静态层即可覆盖 |
| 改 AssetResolver / VoicePlayer / BgmPlayer | ✅ | ✅ | 运行时强相关 |
| 新增案件数据 | ✅ | ✅ | L2 跑该案件即可 |
| 改 GDD 文档 / README | ✅ | — | 仅静态层（防止链接断、行号错） |
| 改 Godot UI（MainGame.gd / 任何 .tscn） | ✅ | ✅ | 视觉变化必截图比对 |
| 改资产注册表（actors/scenes/bgm registry） | ✅ | ✅ | 影响所有运行时解析 |
| 改 GameManager 案件加载 / 存档逻辑 | ✅ | ✅（多案件） | 必须每个案件都跑 |

---

## 失败处理

L1 / L2 任一层失败：

1. **不要继续推进新任务**。先把回归修绿。
2. 在 todo 列表里把"修复 X 回归"作为 in_progress 任务。
3. 修复后**重新跑完整层级的回归**（不止跑失败那一项），确保没有连锁破坏。
4. 把根因（什么改动引入了什么破坏）写进任务总结。

---

## 当前基线（M1.1 + 浔阳楼案完成时）

```
L1:
  validate_registry: actors=8 / scenes=9 / bgm=8 / 案件=2（_smoke_test 为模板，不计入）
  case_files: linchuan_inn ✅ / xunyang_pavilion ✅
  casting_alignment: 全 OK
  template_schema: 3/3 OK
  template_health: 3/3 OK
  audit_voices: linchuan_inn 全量 / xunyang_pavilion 缺 36 条（已记录）

L2 (linchuan_inn):
  npc=0/8 / loc=0/6 / bgm=0/11
  current_bgm=main_theme（mood:mysterious 解析）
  REGRESSION=PASS

L2 (xunyang_pavilion):
  npc=0/8（全部 8 个角色复用现有演员，零美术）
  loc=0/6（全部 6 个地点复用现有 scene_type）
  bgm=0/12（全部 12 个 BGM 键走 mood 标签）
  current_bgm=main_theme
  REGRESSION=PASS
```

新增案件 / 改运行时后，**新基线必须不劣于此**。

---

## 已知陷阱 / 经验记录

写 runtime_check.gd 时踩过的坑（写新回归脚本时避开）：

1. **JSON 顶层 `_comment` 必须过滤**：`locations.json` / `npcs.json` 都允许 `_comment: "..."` 元字段，类型是 String 而非 Dictionary，遍历前必须 `if key.begins_with("_"): continue` 否则 `typeof(v) != TYPE_DICTIONARY` 会撞 SCRIPT ERROR。
2. **`var ldata : Dictionary = dict[k]` 强类型断言在 sandbox 中不可用**：会触发"Trying to assign value of type 'String' to a variable of type 'Dictionary'"。改用 `var ldata = dict[k]` + 运行时 `typeof()` 检查。
3. **`for k in dict.keys()` 在某些版本下 k 的类型推断异常**：改用 `for i in range(keys.size())` + `var k : String = keys[i]` 更稳。
4. **`(nid as String).begins_with("_")` 在 sandbox 中可能失败**：改用 `var nid : String = ...` 然后直接 `.begins_with("_")`。
5. **`execute_game_script` 一旦内部 SCRIPT ERROR，整次调用静默失败**：MCP 返回 "MCP tool execution failed" 但没有详细信息。**必须**配合 `get_output_log` 查 Godot 实际日志找根因。
6. **案件切换的存档隔离**：每个案件有自己的 `user://saves/<case_id>.json`。切换案件后"继续游戏"按钮根据**该案件**是否有存档决定显示。
7. **`current_case.json` 写入需要在 game 启动之前完成**：用 `execute_editor_script` 写，然后才 `play_scene`。游戏启动时 `GameManager._ready()` 才读这个文件。
