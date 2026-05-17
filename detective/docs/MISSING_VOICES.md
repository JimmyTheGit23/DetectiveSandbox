# 未生成语音清单

> **自动生成**: `python tools/audit_voices.py`  **最后扫描**: 见 git blame  **用途**: 跟踪每个案件中尚未生成 TTS 的对话/序章/事件节点。新案件 PR 必跑此脚本。

## 总览

| 案件 | 标题 | voice_status | 已有 | 缺失 | 状态 |
|------|------|------|------|------|------|
| `linchuan_inn` | 临川驿案 | `full` | 103 | 0 | ✅ 全量 |
| `xunyang_pavilion` | 浔阳楼·夜雨红绸案 | `full` | 73 | 0 | ✅ 全量 |

---

## 后续 TTS 生成提示

1. 每条缺失语音的 `actor_id` 决定了用哪个 voice_config —— 见 `data/actors/registry.json`。
2. 缺失列表按 `actor_id` 聚合后跑 `tools/generate_voices.py` 可批量生成。
3. 序章和事件类语音不区分 actor，按 `_prologue/` / `_events/` 旧目录约定生成。
4. 重新跑本脚本即可看到差量更新。
