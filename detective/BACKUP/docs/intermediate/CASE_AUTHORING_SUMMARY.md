# 案例创作体系总结

## 概述

本文档总结了侦探沙盒游戏的案例创作规范体系，包括所有相关文档、工具和模板。

---

## 文档体系

### 核心文档

| 文档 | 位置 | 说明 |
|------|------|------|
| **案例数据规范** | [CASE_DATA_SPEC.md](CASE_DATA_SPEC.md) | 完整的数据格式说明，包括所有 CSV 字段定义、条件语法、最佳实践 |
| **验证指南** | [VALIDATION_GUIDE.md](VALIDATION_GUIDE.md) | 数据验证工具使用说明，包括常见错误及修复 |
| **Markdown 写作指南** | [MARKDOWN_AUTHORING_GUIDE.md](MARKDOWN_AUTHORING_GUIDE.md) | 使用 Markdown 格式编写案例内容的指南 |
| **案例创作指南** | [CASE_AUTHORING_GUIDE.md](CASE_AUTHORING_GUIDE.md) | 案例创作的完整流程和技巧 |
| **README** | [README.md](README.md) | 文档目录和快速入门 |

### 参考文档

| 文档 | 说明 |
|------|------|
| [DATA_DRIVEN_AUTHORING_DESIGN.md](DATA_DRIVEN_AUTHORING_DESIGN.md) | 数据驱动设计说明 |
| [DATA_SCHEMA_REFERENCE.md](DATA_SCHEMA_REFERENCE.md) | 数据架构参考 |
| [GDD_03_DialogueSystem.md](GDD_03_DialogueSystem.md) | 对话系统设计文档 |
| [PROLOGUE_SCRIPT_FRAMEWORK.md](PROLOGUE_SCRIPT_FRAMEWORK.md) | 序章剧本框架 |
| [序章_渡口沉舟_剧本.md](序章_渡口沉舟_剧本.md) | 序章完整剧本 |

---

## 模板文件

### 位置

`docs/case_template/`

### 包含文件

| 文件 | 说明 |
|------|------|
| `case_info.csv` | 案例基本信息模板 |
| `case_meta.csv` | 案例元数据模板（凶手、动机、结局） |
| `characters.csv` | 角色定义模板 |
| `locations.csv` | 地点定义模板 |
| `search_points.csv` | 搜索点模板 |
| `search_results.csv` | 搜索结果模板 |
| `evidence_items.csv` | 证据/线索模板 |
| `dialogue_nodes.csv` | 对话节点模板 |
| `dialogue_lines.csv` | 对话台词模板 |
| `dialogue_options.csv` | 对话选项模板 |
| `day_events.csv` | 日间事件模板 |
| `prologue_nodes.csv` | 序章节点模板 |
| `prologue_lines.csv` | 序章台词模板 |
| `prologue_choices.csv` | 序章选项模板 |

---

## 工具链

### 数据编译工具

| 工具 | 位置 | 功能 |
|------|------|------|
| `compile_case.py` | `tools/data_compiler/` | 将 CSV 编译为 JSON |
| `validate_case_tables.py` | `tools/data_compiler/` | 验证数据完整性 |
| `export_case_tables.py` | `tools/data_compiler/` | 从 JSON 导出为 CSV |
| `dsl.py` | `tools/data_compiler/` | 条件解析库 |

### 分析工具

| 工具 | 位置 | 功能 |
|------|------|------|
| `analyze_dialogue_paths.py` | `tools/regression/` | 对话路径分析 |
| `run_static.py` | `tools/regression/` | 静态验证 |
| `run_dialogue_tests.py` | `tools/regression/` | 对话测试 |
| `generate_final_report.py` | `tools/regression/` | 生成测试报告 |

### 辅助工具

| 工具 | 位置 | 功能 |
|------|------|------|
| `extract_text_to_csv.py` | `tools/` | 从剧本提取文本到 CSV |
| `write_xunyang_dialogues.py` | `tools/` | 对话生成示例 |
| `build_xunyang_dynamic.py` | `tools/` | 动态构建示例 |

---

## 参考案例

### 序章「渡口沉舟」

**位置：** `data/case_tables/prologue_ferry/`

**特点：**
- 完整的教学案例
- 包含所有系统示例
- 推荐新手参考

**包含内容：**
- 9 个角色
- 10 个地点
- 24 个证据/线索
- 45+ 对话节点
- 12 个日间事件
- 5 种结局

### 第一章「浔阳水阁」

**位置：** `data/case_tables/xunyang_pavilion/`

**特点：**
- 更复杂的案例
- 包含多嫌疑人设计
- 进阶参考

---

## 开发流程

### 快速开始

```bash
# 1. 复制模板
cp -r docs/case_template data/case_tables/your_case_id

# 2. 编辑 CSV 文件
# 按照 CASE_DATA_SPEC.md 规范编辑

# 3. 验证数据
python tools/data_compiler/validate_case_tables.py your_case_id

# 4. 编译生成
python tools/data_compiler/compile_case.py your_case_id --write-runtime

# 5. 测试案例
# 启动游戏，选择案例进行测试
```

### 详细流程

1. **规划阶段**
   - 确定案件主题和背景
   - 设计角色和关系
   - 构建剧情和证据链
   - 规划地点和搜索点

2. **数据编写**
   - 使用模板创建 CSV 文件
   - 按照规范填写数据
   - 或使用 Markdown 编写后转换

3. **验证调试**
   - 运行验证工具
   - 修复错误和警告
   - 编译并测试

4. **优化完善**
   - 润色对话台词
   - 调整游戏节奏
   - 添加配音标记

---

## 数据结构

### 核心数据表

```
case_info.csv          ← 案例元数据
case_meta.csv          ← 凶手、动机、结局
characters.csv         ← 角色定义
evidence_items.csv     ← 证据和线索
locations.csv          ← 地点定义
search_points.csv      ← 搜索点
search_results.csv     ← 搜索结果
```

### 对话系统

```
dialogue_nodes.csv     ← 对话节点
dialogue_lines.csv     ← 对话台词
dialogue_options.csv   ← 对话选项
confrontations.csv     ← 对峙配置
confrontation_lines.csv ← 对峙台词
testimony_*.csv        ← 证词系统
```

### 事件系统

```
day_events.csv         ← 日间事件
day_event_lines.csv    ← 事件台词
progression_phases.csv ← 进度阶段
progression_unlocks.csv ← 进度解锁
```

### 序章系统

```
prologue_nodes.csv     ← 序章节点
prologue_lines.csv     ← 序章台词
prologue_choices.csv   ← 序章选项
```

---

## 条件语法速查

### 基本条件

```json
// 拥有证据
{"evidence": "evidence_id"}

// 拥有线索
{"clue": "clue_id"}

// 标志位为真
{"flag": "flag_name"}

// 标志位为假
{"not": {"flag": "flag_name"}}
```

### 组合条件

```json
// 所有条件都满足
{"all": [condition1, condition2, ...]}

// 任一条件满足
{"any": [condition1, condition2, ...]}
```

### 数值条件

```json
// 证据数量 >= N
{"evidence_count_gte": N}

// 天数 >= N
{"day_gte": N}

// 当前在某地点
{"location": "location_id"}
```

### 访问条件

```json
// 已访问对话节点
{"visited": "npc_id.node_id"}

// 未访问对话节点
{"not": {"visited": "npc_id.node_id"}}
```

---

## 常见任务

### 添加新 NPC

1. 在 `characters.csv` 添加角色定义
2. 在 `dialogue_nodes.csv` 添加对话节点
3. 在 `dialogue_lines.csv` 添加台词
4. 在 `dialogue_options.csv` 添加选项
5. 在 `locations.csv` 中指定出现地点
6. 在 `casting.json` 中添加配音配置（可选）

### 添加新证据

1. 在 `evidence_items.csv` 添加证据定义
2. 在 `search_results.csv` 添加获取途径
3. 在 `dialogue_nodes.csv` 中添加 `gain_evidence` 字段
4. 在 `day_events.csv` 中添加相关事件（可选）

### 添加新地点

1. 在 `locations.csv` 添加地点定义
2. 在 `location_links.csv` 添加地点连接
3. 在 `search_points.csv` 添加搜索点
4. 在 `search_results.csv` 添加搜索结果

### 添加新事件

1. 在 `day_events.csv` 添加事件定义
2. 在 `day_event_lines.csv` 添加事件台词（可选）
3. 在 `progression_unlocks.csv` 添加解锁条件（可选）

---

## 最佳实践

### 命名规范

- **ID 命名**：小写字母 + 下划线
  - ✅ `agui`, `evidence_hull_hole`, `ferry_inn`
  - ❌ `Agui`, `Evidence1`, `Location-A`

- **文件命名**：与 ID 保持一致
  - ✅ `agui.json`, `evidence_hull_hole.json`
  - ❌ `Agui.json`, `evidence1.json`

### 对话设计

1. **Hub 节点**：每个 NPC 应有 `hub` 节点作为对话入口
2. **选项分层**：
   - `ask`：基础询问，无条件
   - `press`：追问，需要前置条件
   - `observe`：观察，需要特定证据
3. **退出选项**：每个节点都应有 `__exit__` 选项
4. **循环设计**：使用 `hub` 节点实现对话循环

### 证据设计

1. **证据分级**：
   - 核心证据：直接指向凶手或手法
   - 辅助证据：提供背景信息
   - 红鲱鱼：误导性信息

2. **获取途径**：每个证据至少有一个明确的获取途径

3. **描述质量**：描述应具体、有细节

### 事件设计

1. **触发条件**：避免过于复杂的条件组合
2. **防重复**：使用 `not` 条件防止事件重复触发
3. **效果明确**：事件效果应清晰

---

## 验证检查清单

### 提交前检查

- [ ] 运行验证工具：`python tools/data_compiler/validate_case_tables.py case_id`
- [ ] 修复所有错误（[FAIL]）
- [ ] 处理或记录所有警告（[WARN]）
- [ ] 编译成功：`python tools/data_compiler/compile_case.py case_id`
- [ ] 游戏内测试通过

### 数据完整性

- [ ] 所有必填字段已填写
- [ ] 所有 ID 唯一且一致
- [ ] 所有引用有效
- [ ] 对话图完整
- [ ] 证据链可达成

### 内容质量

- [ ] 对话自然流畅
- [ ] 证据描述具体
- [ ] 地点描写生动
- [ ] 事件触发合理

---

## 相关资源

### 官方文档

- [案例数据规范](CASE_DATA_SPEC.md)
- [验证指南](VALIDATION_GUIDE.md)
- [Markdown 写作指南](MARKDOWN_AUTHORING_GUIDE.md)
- [案例创作指南](CASE_AUTHORING_GUIDE.md)

### 参考案例

- [序章「渡口沉舟」](../data/case_tables/prologue_ferry/)
- [第一章「浔阳水阁」](../data/case_tables/xunyang_pavilion/)

### 设计文档

- [数据驱动设计](DATA_DRIVEN_AUTHORING_DESIGN.md)
- [对话系统设计](GDD_03_DialogueSystem.md)
- [序章剧本框架](PROLOGUE_SCRIPT_FRAMEWORK.md)

---

## 常见问题

### Q: 如何开始创建新案例？

1. 阅读 [案例数据规范](CASE_DATA_SPEC.md)
2. 复制模板：`cp -r docs/case_template data/case_tables/your_case_id`
3. 参考序章案例：`data/case_tables/prologue_ferry/`
4. 按照规范编辑 CSV 文件

### Q: 如何验证数据是否正确？

```bash
python tools/data_compiler/validate_case_tables.py your_case_id
```

### Q: 如何编译生成游戏数据？

```bash
python tools/data_compiler/compile_case.py your_case_id --write-runtime
```

### Q: 如何添加条件对话？

在 `dialogue_options.csv` 中使用 `requires` 字段：

```csv
requires
"[{""flag"":""some_flag""}]"
"[{""evidence"":""evidence_1""}]"
```

### Q: 如何实现多结局？

在 `case_meta.csv` 的 `endings` 中定义所有结局，通过证据组合和标志位触发不同结局。

### Q: 如何使用 Markdown 编写内容？

参考 [Markdown 写作指南](MARKDOWN_AUTHORING_GUIDE.md)，按照指定格式编写，然后转换为 CSV。

---

## 联系方式

如有疑问，请联系开发团队。

---

*文档版本：1.0*
*最后更新：2026-05-30*