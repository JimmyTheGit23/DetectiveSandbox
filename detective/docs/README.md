# 案例开发文档

欢迎参与侦探沙盒游戏的案例开发！本文档将帮助你了解如何创建新的游戏案例。

## 快速开始

### 1. 了解规范

阅读 [案例数据规范](CASE_DATA_SPEC.md) 了解完整的数据格式要求。

### 2. 使用模板

复制 `case_template/` 目录作为起点：

```bash
cp -r docs/case_template data/case_tables/your_case_id
```

### 3. 编辑数据

按照规范编辑 CSV 文件：
- `case_info.csv` - 案例基本信息
- `characters.csv` - 角色定义
- `evidence_items.csv` - 证据和线索
- `locations.csv` - 地点定义
- `dialogue_*.csv` - 对话系统
- ...

### 4. 验证数据

运行验证工具检查数据完整性：

```bash
python tools/data_compiler/validate_case_tables.py your_case_id
```

### 5. 编译生成

编译 CSV 为游戏可用的 JSON：

```bash
python tools/data_compiler/compile_case.py your_case_id --write-runtime
```

### 6. 测试案例

启动游戏，选择你的案例进行测试。

---

## 文档目录

### 核心文档

- **[案例数据规范](CASE_DATA_SPEC.md)** - 完整的数据格式说明
  - 目录结构
  - 所有 CSV 字段定义
  - 条件语法
  - 最佳实践

- **[验证指南](VALIDATION_GUIDE.md)** - 数据验证工具使用说明
  - 验证命令
  - 常见错误及修复
  - 自动化集成

### 模板文件

- **[CSV 模板](case_template/)** - 可用的 CSV 模板
  - `case_info.csv` - 案例信息模板
  - `characters.csv` - 角色模板
  - `evidence_items.csv` - 证据模板
  - `locations.csv` - 地点模板
  - `dialogue_*.csv` - 对话模板
  - ...

### 参考案例

- **序章「渡口沉舟」** - `data/case_tables/prologue_ferry/`
  - 完整的教学案例
  - 包含所有系统示例
  - 推荐新手参考

- **第一章「浔阳水阁」** - `data/case_tables/xunyang_pavilion/`
  - 更复杂的案例
  - 包含多嫌疑人设计
  - 进阶参考

---

## 工具说明

### 编译工具

**位置：** `tools/data_compiler/compile_case.py`

**功能：** 将 CSV 表格编译为游戏运行时 JSON

**用法：**
```bash
# 编译单个案例（预览模式）
python tools/data_compiler/compile_case.py case_id

# 编译并写入运行时目录
python tools/data_compiler/compile_case.py case_id --write-runtime

# 编译所有案例
python tools/data_compiler/compile_case.py --all
```

### 验证工具

**位置：** `tools/data_compiler/validate_case_tables.py`

**功能：** 验证 CSV 数据的完整性和正确性

**用法：**
```bash
# 验证单个案例
python tools/data_compiler/validate_case_tables.py case_id

# 验证所有案例
python tools/data_compiler/validate_case_tables.py --all
```

### 导出工具

**位置：** `tools/data_compiler/export_case_tables.py`

**功能：** 从运行时 JSON 导出为 CSV（逆向工程）

**用法：**
```bash
python tools/data_compiler/export_case_tables.py case_id
```

---

## 案例开发流程

### 阶段 1：规划

1. **确定主题**：案件背景、时代、地点
2. **设计角色**：受害者、嫌疑人、证人、凶手
3. **构建剧情**：案件经过、动机、手法
4. **规划证据**：关键证据、辅助证据、红鲱鱼

### 阶段 2：数据编写

1. **创建目录**
   ```bash
   cp -r docs/case_template data/case_tables/your_case_id
   ```

2. **填写基础信息**
   - `case_info.csv` - 案例元数据
   - `case_meta.csv` - 凶手、动机、结局

3. **定义角色**
   - `characters.csv` - 所有 NPC

4. **设计地点**
   - `locations.csv` - 地点层级
   - `search_points.csv` - 搜索点

5. **创建证据**
   - `evidence_items.csv` - 证据和线索

6. **编写对话**
   - `dialogue_nodes.csv` - 对话节点
   - `dialogue_lines.csv` - 对话台词
   - `dialogue_options.csv` - 对话选项

7. **配置事件**
   - `day_events.csv` - 日间事件
   - `progression_*.csv` - 进度解锁

### 阶段 3：验证与调试

1. **运行验证**
   ```bash
   python tools/data_compiler/validate_case_tables.py your_case_id
   ```

2. **修复错误**
   - 根据验证报告修复问题
   - 确保所有引用有效

3. **编译测试**
   ```bash
   python tools/data_compiler/compile_case.py your_case_id
   ```

4. **游戏内测试**
   - 启动游戏
   - 完整游玩一遍
   - 检查所有分支

### 阶段 4：优化

1. **对话润色**
   - 调整台词风格
   - 优化选项设计
   - 添加高亮关键词

2. **节奏调整**
   - 平衡时间消耗
   - 调整事件触发
   - 优化证据获取顺序

3. **配音准备**
   - 标记情绪
   - 添加语气提示
   - 准备配音配置

---

## 常见问题

### Q: 如何添加新的 NPC？

1. 在 `characters.csv` 添加一行
2. 在 `dialogue_nodes.csv` 添加对话节点
3. 在 `dialogue_lines.csv` 添加台词
4. 在 `dialogue_options.csv` 添加选项
5. 在 `locations.csv` 中指定出现地点

### Q: 如何实现多结局？

在 `case_meta.csv` 的 `endings` 中定义所有结局，通过证据组合和标志位触发不同结局。

**示例：**
```csv
key,value
endings,"{""perfect"": {""title"": ""完美结局"", ""narration"": ""...""}, ""bad"": {""title"": ""失败结局"", ""narration"": ""...""}}"
```

### Q: 如何添加条件对话？

在 `dialogue_lines.csv` 或 `dialogue_options.csv` 中使用 `requires` 字段：

```csv
requires
"[{""flag"":""some_flag""}]"
"[{""evidence"":""evidence_1""}]"
"[{""not"":{""flag"":""done""}}]"
```

### Q: 如何实现分支剧情？

1. 使用 `set_flags` 设置标志位
2. 使用 `requires` 条件显示不同内容
3. 使用 `when` 条件创建搜索结果变体

### Q: 如何添加新的搜索点？

1. 在 `search_points.csv` 添加搜索点定义
2. 在 `search_results.csv` 添加搜索结果
3. 如有子选项，在 `search_sub_choices.csv` 添加

### Q: 如何配置对峙系统？

1. 在 `confrontations.csv` 定义对峙配置
2. 在 `confrontation_lines.csv` 添加对峙台词
3. 在 `testimony_*.csv` 配置证词系统
4. 在对话中使用 `__confront__` 触发对峙

### Q: 如何添加日间事件？

在 `day_events.csv` 定义事件：

```csv
event_id,title,hint,trigger,effects,auto_play
evt_example,事件标题,事件提示,"{""all"": [{""flag"":""some_flag""}]}","{""set_flag"":[""done""]}",false
```

### Q: 如何配置 NPC 状态变化？

使用 `npc_state_initial.csv` 定义初始状态，`npc_state_transitions.csv` 定义状态转换规则。

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

## 贡献指南

### 提交规范

1. **验证通过**：提交前确保验证通过
   ```bash
   python tools/data_compiler/validate_case_tables.py your_case_id
   ```

2. **编译测试**：确保编译成功
   ```bash
   python tools/data_compiler/compile_case.py your_case_id
   ```

3. **游戏测试**：完整游玩一遍，确保无问题

4. **提交内容**：
   - CSV 源文件（必须）
   - 编译后的 JSON（可选，建议不提交）
   - 素材文件（如有）

### 代码审查

提交 Pull Request 时，会自动运行验证：

1. 数据格式验证
2. 引用完整性检查
3. 编译测试

### 问题反馈

如遇到问题，请提供：

1. 案例 ID
2. 错误信息
3. 相关 CSV 文件内容
4. 复现步骤

---

## 相关资源

- [案例数据规范](CASE_DATA_SPEC.md)
- [验证指南](VALIDATION_GUIDE.md)
- [CSV 模板](case_template/)
- [序章参考](../data/case_tables/prologue_ferry/)
- [第一章参考](../data/case_tables/xunyang_pavilion/)

---

## 联系方式

如有疑问，请联系开发团队。

---

*文档版本：1.0*
*最后更新：2026-05-30*