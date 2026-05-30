# 数据验证指南

## 概述

本指南介绍如何使用验证工具检查案例数据表的完整性和正确性。

## 验证工具

### 1. validate_case_tables.py

主要的数据验证工具，检查 CSV 数据表的完整性。

**位置：** `tools/data_compiler/validate_case_tables.py`

### 2. compile_case.py

编译工具，将 CSV 转换为 JSON。编译过程也会进行基本验证。

**位置：** `tools/data_compiler/compile_case.py`

---

## 使用方法

### 验证单个案例

```bash
# 验证指定案例
python tools/data_compiler/validate_case_tables.py prologue_ferry

# 验证并显示详细信息
python tools/data_compiler/validate_case_tables.py prologue_ferry --verbose
```

### 验证所有案例

```bash
python tools/data_compiler/validate_case_tables.py --all
```

### 编译并验证

```bash
# 编译到预览目录（安全）
python tools/data_compiler/compile_case.py prologue_ferry

# 编译到运行时目录
python tools/data_compiler/compile_case.py prologue_ferry --write-runtime
```

---

## 验证检查项

### 1. 必填字段检查

验证所有必填字段不为空：

| 文件 | 必填字段 |
|------|---------|
| `case_info.csv` | `id`, `title`, `difficulty`, `estimated_days`, `max_days`, `main_scene` |
| `characters.csv` | `npc_id`, `name` |
| `evidence_items.csv` | `item_id`, `type`, `name` |
| `locations.csv` | `location_id`, `name` |
| `search_points.csv` | `location_id`, `point_id`, `name` |
| `dialogue_nodes.csv` | `npc_id`, `node_id` |
| `dialogue_lines.csv` | `npc_id`, `node_id`, `order`, `text` |
| `dialogue_options.csv` | `npc_id`, `node_id`, `order`, `text`, `goto` |

### 2. ID 唯一性检查

确保以下 ID 在各自文件中唯一：

- `characters.csv` → `npc_id`
- `evidence_items.csv` → `item_id`
- `locations.csv` → `location_id`
- `search_points.csv` → `location_id` + `point_id` 组合
- `dialogue_nodes.csv` → `npc_id` + `node_id` 组合

### 3. 引用完整性检查

验证所有引用的 ID 都存在：

- **NPC 引用**：对话、证据、地点中的 `npc_id` 必须在 `characters.csv` 中定义
- **证据引用**：搜索结果、对话中的证据 ID 必须在 `evidence_items.csv` 中定义
- **地点引用**：搜索点、地点连接中的地点 ID 必须在 `locations.csv` 中定义
- **对话引用**：选项中的 `goto` 目标必须是有效的节点 ID

### 4. 对话图完整性检查

- **起始节点**：每个 NPC 必须有且仅有一个 `is_start=true` 的节点
- **节点可达性**：所有节点都应该能从起始节点到达
- **无死循环**：检测对话图中的无限循环（不包括显式的循环设计）

### 5. 条件语法检查

验证所有条件字段的 JSON 格式正确：

- `requires` 字段
- `unlock_condition` 字段
- `when` 字段
- `trigger` 字段

### 6. 资源路径检查

验证所有资源路径指向的文件存在：

- `portrait` 字段
- `background` 字段
- `icon` 字段

---

## 验证输出

### 成功输出

```
[OK] characters.csv: 9 个角色定义
[OK] evidence_items.csv: 24 个证据/线索
[OK] locations.csv: 10 个地点
[OK] dialogue_nodes.csv: 45 个对话节点
[OK] 所有引用检查通过
✓ 验证通过
```

### 错误输出

```
[FAIL] dialogue_options.csv 指向不存在节点: agui.nonexistent_node
[FAIL] search_results.csv gain_evidence 引用不存在: evidence_not_exist
[FAIL] characters.csv npc_id= 缺 name
✗ 发现 3 个错误
```

### 警告输出

```
[WARN] evidence_items.csv item_id=clue_1 缺 description
[WARN] dialogue_nodes.csv npc_id=extra_npc 未在 characters/runtime npcs 中声明
⚠ 发现 2 个警告
```

---

## 常见错误及修复

### 错误 1：引用不存在的 ID

**错误信息：**
```
[FAIL] dialogue_options.csv goto 不存在: agui.nonexistent_node
```

**原因：** 对话选项中的 `goto` 目标节点不存在

**修复：** 检查 `dialogue_nodes.csv` 中是否有该节点，或修正 `goto` 值

---

### 错误 2：缺少必填字段

**错误信息：**
```
[FAIL] characters.csv npc_id= 缺 name
```

**原因：** 角色定义中 `name` 字段为空

**修复：** 在 `characters.csv` 中为该角色添加名称

---

### 错误 3：ID 重复

**错误信息：**
```
[FAIL] evidence_items.csv 重复 ID: evidence_1
```

**原因：** 同一个证据 ID 出现了多次

**修复：** 删除重复行或使用不同的 ID

---

### 错误 4：条件语法错误

**错误信息：**
```
[FAIL] dialogue_lines.csv agui.intro 条件解析失败: Expecting value: line 1 column 1 (char 0)
```

**原因：** `requires` 字段的 JSON 格式不正确

**修复：** 检查 JSON 语法，确保引号、括号匹配

**正确格式示例：**
```csv
requires
"[{""flag"":""some_flag""}]"
"[{""evidence"":""evidence_1""}]"
"[{""not"":{""flag"":""done""}}]"
```

---

### 错误 5：资源文件不存在

**错误信息：**
```
[FAIL] characters.csv portrait 资源不存在: res://assets/cn/portraits/missing.png
```

**原因：** 头像文件路径指向不存在的文件

**修复：** 
1. 添加对应的图片文件
2. 或修正路径

---

### 警告：缺少描述

**警告信息：**
```
[WARN] evidence_items.csv item_id=clue_1 缺 description
```

**处理：** 建议添加描述，但不影响编译

---

## 验证流程建议

### 开发阶段

1. **编写数据时**：边写边验证，及时发现问题
2. **提交前**：完整验证一次，确保无错误
3. **编译前**：验证通过后再编译

### 验证命令组合

```bash
# 完整验证流程
python tools/data_compiler/validate_case_tables.py your_case_id && \
python tools/data_compiler/compile_case.py your_case_id
```

### 批量验证

```bash
# 验证所有案例
python tools/data_compiler/validate_case_tables.py --all

# 编译所有案例
python tools/data_compiler/compile_case.py --all
```

---

## 高级验证

### 1. 对话图分析

使用回归测试工具分析对话图：

```bash
python tools/regression/analyze_dialogue_paths.py prologue_ferry
```

输出：
- 对话节点统计
- 可达性分析
- 死端检测
- 循环检测

### 2. 证据链验证

检查证据是否可获取：

```bash
python tools/regression/check_evidence_chain.py prologue_ferry
```

验证：
- 关键证据必须有获取途径
- 证据获取条件必须可达成
- 对峙条件必须满足

### 3. 运行时回归测试

```bash
python tools/regression/run_static.py prologue_ferry
```

检查：
- 编译后的 JSON 一致性
- 运行时数据完整性
- 跨文件引用正确性

---

## 自动化集成

### Git Pre-commit Hook

可以配置 Git 在提交前自动验证：

```bash
#!/bin/bash
# .git/hooks/pre-commit

# 获取修改的 CSV 文件
CHANGED_CSVS=$(git diff --cached --name-only --diff-filter=ACM | grep '\.csv$')

if [ -n "$CHANGED_CSVS" ]; then
    echo "验证修改的 CSV 文件..."
    python tools/data_compiler/validate_case_tables.py --all
    if [ $? -ne 0 ]; then
        echo "验证失败，提交被阻止"
        exit 1
    fi
fi
```

### CI/CD 集成

在 GitHub Actions 中添加验证步骤：

```yaml
name: Validate Case Data

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      - name: Validate all cases
        run: python tools/data_compiler/validate_case_tables.py --all
```

---

## 调试技巧

### 1. 详细模式

使用 `--verbose` 参数获取更多信息：

```bash
python tools/data_compiler/validate_case_tables.py prologue_ferry --verbose
```

### 2. 单独验证特定文件

如果只想检查特定类型的错误，可以临时修改 CSV 文件，只保留相关行。

### 3. 查看编译输出

即使验证失败，也可以查看编译输出了解问题：

```bash
# 查看编译到预览目录的结果
python tools/data_compiler/compile_case.py prologue_ferry
ls data/case_tables/prologue_ferry/_compiled/
```

### 4. 对比正常案例

将有问题的案例与正常案例（如 `prologue_ferry`）对比，找出差异。

---

## 最佳实践

1. **定期验证**：不要等到最后才验证，边写边验证
2. **修复错误优先**：错误必须修复，警告建议修复
3. **保持 ID 一致**：NPC ID、证据 ID 等在整个案例中保持一致
4. **添加注释**：在 CSV 中使用 `#` 开头的行作为注释（会被忽略）
5. **备份数据**：在大规模修改前备份 CSV 文件

---

## 相关文档

- [案例数据规范](CASE_DATA_SPEC.md) - 完整的数据格式说明
- [CSV 模板](case_template/) - 可用的 CSV 模板文件
- [编译工具说明](../tools/data_compiler/README.md) - 编译工具详细说明

---

*文档版本：1.0*
*最后更新：2026-05-30*