# 对话路径测试报告

**案件**: prologue_ferry
**时间**: 2026-05-30 00:06:20
**测试类型**: 对话路径完整性验证

---

## 测试摘要

| 指标 | 值 |
|------|-----|
| 总节点数 | 51 |
| NPC 数量 | 6 |
| 选项数量 | 138 |
| 测试路径数 | 0 |
| 错误数量 | 0 |
| 测试状态 | ❌ 失败 |

---

## 静态分析结果

### 错误统计

| 检查项 | 错误数 |
|--------|--------|
| goto 目标缺失 | 0 |
| 不可达节点 | 1 |
| 死胡同节点 | 0 |
| 缺失内容 | 1 |
| 死循环路径 | 0 |

### 详细错误

#### unreachable_nodes

- **unreachable_node**: 节点 agui.confession 从起始节点不可达

#### missing_content

- **missing_content**: 节点 lao_fan.ask_rescue 没有对话内容

---

## 运行时测试结果

### agui

| 节点 | 状态 |
|------|------|
| agui.hub | ✅ PASS |
| agui.intro | ✅ PASS |

### fisherman_wang

| 节点 | 状态 |
|------|------|
| fisherman_wang.hub | ✅ PASS |
| fisherman_wang.intro | ✅ PASS |

### lao_fan

| 节点 | 状态 |
|------|------|
| lao_fan.hub | ✅ PASS |
| lao_fan.intro | ✅ PASS |

### li_zheng

| 节点 | 状态 |
|------|------|
| li_zheng.hub | ✅ PASS |
| li_zheng.intro | ✅ PASS |

### shen_qingyue

| 节点 | 状态 |
|------|------|
| shen_qingyue.hub | ✅ PASS |
| shen_qingyue.intro | ✅ PASS |

### zhou_wife

| 节点 | 状态 |
|------|------|
| zhou_wife.hub | ✅ PASS |
| zhou_wife.intro | ✅ PASS |

---

## 测试配置

- **静态分析器**: `tools/regression/analyze_dialogue_paths.py`
- **运行时测试器**: `tools/regression/dialogue_path_tester.gd`
- **编排脚本**: `tools/regression/run_dialogue_tests.py`

---

## 附录

### 测试的 NPC 列表

- agui
- fisherman_wang
- lao_fan
- li_zheng
- shen_qingyue
- zhou_wife

### 测试时间

- **开始时间**: 2026-05-30 00:06:20
- **生成时间**: 2026-05-30 00:06:20

---

*报告由对话路径测试工具自动生成*
