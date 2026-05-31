# 项目验证系统

本验证系统包含多个专业Agent，用于检查项目的数据一致性、剧情逻辑、美术资源和场景调度。

## Agent列表

### 1. 数据一致性检查Agent (`data-consistency-checker`)
- 检查CSV文件之间的引用关系
- 验证ID命名规范
- 检查必填字段
- 验证枚举值
- 检查资源引用完整性

### 2. 剧情逻辑验证Agent (`narrative-logic-validator`)
- 验证对话流程可达性
- 检查flag逻辑一致性
- 验证事件触发条件
- 检查证据链完整性
- 验证进度系统规则

### 3. 导演Agent (`director-agent`)
- 检查场景人物调度合理性
- 验证时间线一致性
- 检查物件位置和状态
- 验证角色认知合理性
- 检查对话一致性

## 使用方法

### 运行所有检查

```bash
cd /Users/zhoujiong/Documents/UGit/DetectiveSandbox/detective
python3 data/validation/agents/validation_runner.py
```

### 运行单个Agent

```bash
# 数据一致性检查
python3 data/validation/agents/data_consistency_checker.py

# 剧情逻辑验证
python3 data/validation/agents/narrative_logic_validator.py

# 导演检查
python3 data/validation/agents/director_agent.py
```

### 指定案件检查

```bash
python3 data/validation/agents/validation_runner.py --case prologue_ferry
```

### 指定Agent检查

```bash
python3 data/validation/agents/validation_runner.py --agent data
python3 data/validation/agents/validation_runner.py --agent logic
python3 data/validation/agents/validation_runner.py --agent director
```

### 输出报告

```bash
python3 data/validation/agents/validation_runner.py --output report.md
```

## 配置文件

### `validation_config.yaml`
全局验证配置，包括：
- Agent启用/禁用设置
- 案件配置
- 输出格式设置
- 严重性级别定义

### `data_consistency_rules.yaml`
数据一致性检查规则，包括：
- ID命名规范
- 必填字段定义
- 枚举值定义
- 引用完整性规则

### `narrative_logic_rules.yaml`
剧情逻辑验证规则，包括：
- Flag逻辑规则
- 对话流程规则
- 事件触发规则
- 证据链规则
- 进度系统规则

### `director_rules.yaml`
导演检查规则，包括：
- 场景规则（人物、时间、天气）
- 角色身份定义
- 物件规则
- 角色认知规则
- 对话规则

## 规则配置示例

### 添加新场景规则

在 `director_rules.yaml` 中添加：

```yaml
scene_rules:
  new_scene:
    allowed_characters: [char1, char2]
    forbidden_characters: [char3]
    required_characters: [char1]
    time_phase: day
    weather: clear
    location: new_location
    description: "新场景描述"
```

### 添加新角色认知规则

在 `director_rules.yaml` 中添加：

```yaml
character_knowledge:
  new_character:
    new_phase:
      knows:
        - "知道的信息1"
        - "知道的信息2"
      doesnt_know:
        - "不知道的信息1"
        - "不知道的信息2"
      emotion: calm
```

## 报告说明

验证报告包含以下部分：

1. **检查总结**：错误和警告数量统计
2. **场景统计**：场景数量、人物数量、对话行数
3. **错误详情**：所有严重错误的详细信息
4. **警告详情**：所有警告的详细信息
5. **建议**：根据检查结果提供的修复建议

## 严重性级别

- **error**：严重错误，必须修复
- **warning**：警告，建议修复
- **info**：信息，供参考
- **hint**：提示，可选优化

## 扩展Agent

如需添加新的检查Agent：

1. 在 `agents/` 目录下创建新的Python文件
2. 实现检查逻辑，继承基础检查模式
3. 在 `validation_runner.py` 中添加调用
4. 在 `validation_config.yaml` 中添加配置

## 注意事项

1. 所有规则文件使用YAML格式，注意缩进
2. 检查结果会自动保存到 `validation_report.md`
3. 可以通过配置文件禁用不需要的Agent
4. 建议在提交代码前运行验证系统
