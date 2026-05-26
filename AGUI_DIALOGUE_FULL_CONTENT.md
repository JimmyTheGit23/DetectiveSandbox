# agui.json 完整内容 + 关键数据引用

## 1. agui.json 完整结构

### 文件头和起点
```json
{
  "_comment": "阿贵对话树。主犯。初始伪装悲痛，被质问后逐渐露出马脚。",
  "start": "hub",
  "nodes": { ... }
}
```

### 节点总数: 7个
1. **hub** - 初次接触枢纽
2. **intro** - 案发经过初述
3. **ask_relationship** - 询问主仆关系
4. **press_alibi** - 质证逃生故事
5. **show_dismissal** - 出示遣散字据
6. **show_bladder** - 出示浮囊 ⭐ 重要
7. **confession** - 对峙场景启动

---

## 2. 关键台词详解

### 2.1 show_bladder 节点 (第190-230行) - 问题所在

```json
"show_bladder": {
  "lines": [
    {
      "speaker_id": "agui",
      "text": "（猛地站起来）那——那不是小的的！是、是……"
      // ✅ 正确: 惊慌失措的防守反应
    },
    {
      "speaker_id": "agui",
      "text": "……"
      // ⚠️ 沉默
    },
    {
      "speaker_id": "agui",
      "text": "（沉默良久）"
      // ⚠️ 继续沉默
    },
    {
      "speaker_id": "agui",
      "text": "大人。小的想说实话。"
      // ❌ 问题! 这里逻辑不通
      // - 没有任何压力迫使他主动认罪
      // - 浮囊证据还不足以扳倒他
      // - 应该是"被逼"而非"想说"
    },
    {
      "speaker_id": "xia_lingyao",
      "text": "哟——这才对嘛。"
    },
    {
      "speaker_id": "lu_zhao",
      "text": "说。"
    }
  ],
  "set_flags": ["agui_bladder_confronted"]
}
```

**为什么这句台词有问题:**

1. **逻辑断层**: 前面三句都在狡辩和沉默，突然转向"想说实话"显得很生硬
2. **角色塑造冲突**: 主犯应该是被逼供，而非自愿认罪
3. **游戏叙事效果**: 玩家感受不到"抓住真凶"的快感，反而觉得阿贵是主动认错

**建议修改:**
```json
{
  "speaker_id": "agui",
  "text": "（长时间沉默，抬头看向卢大人）……大人，小的无话可说了。"
  // 表现为"被逼得无法再狡辩"而非"主动想说实话"
}
```

或更戏剧化的：
```json
{
  "speaker_id": "agui",
  "text": "（声音颤抖，已无其他说辞）……那个浮囊，只有……"
  // 表现为开始崩溃，被证据压倒
}
```

---

## 3. confrontation 触发条件

### hub 节点中的对峙选项 (第54-77行)

```json
{
  "text": "（对峙）证据够了。说实话吧。",
  "goto": "confession",
  "requires": {
    "all": [
      {
        "evidence": "evidence_hull_hole"
        // 船底凿痕 - 证明人为破坏
      },
      {
        "evidence": "evidence_float_bladder"
        // 浮囊 - 证明阿贵预谋逃生
      },
      {
        "any": [
          {
            "evidence": "evidence_dismissal_note"
            // 遣散字据 - 动机: 被解雇的怨恨
          },
          {
            "evidence": "evidence_gambling_iou"
            // 赌债字据 - 动机: 经济压力
          }
        ]
      }
    ]
  },
  "type": "confrontation",
  "set_flags": ["confrontation_triggered"]
}
```

**三重门槛:**
- ✅ 物证(1): 船底凿痕 (证明预谋)
- ✅ 物证(2): 浮囊 (证明自保)
- ✅ 动机(1-2选1): 遣散字据 OR 赌债字据

---

## 4. case.json 中的对峙流程对应

### 4.1 Testimony 1: 那晚的行踪

```
关键句: "一步都没出去过" (s1_2)
破局证据: evidence_float_bladder (浮囊)
破局对话: "透气？带着这个东西？"

如果玩家按压 s1_2，会触发 press_adds:
├─ 加入新陈述 s1_2b: "……好吧，我承认中间出去过一次"
└─ 后续质证: 为何需要浮囊？
```

### 4.2 Testimony 2: 沉船原因

```
关键句: "船底被暗礁撞了个大洞" (s2_2)
破局证据: evidence_hull_hole (凿痕)
破局对话: "这破洞的木板边缘整齐——是从内侧凿开的"

图表说明:
  暗礁撞击 → 边缘毛躁不规则
  人工凿船 → 边缘整齐，钉眼新旧两圈
```

### 4.3 Testimony 3: 主仆关系

```
关键句: "遣散嘛……是老爷体恤我" (s3_2)
破局证据: evidence_dismissal_note (遣散字据)
破局对话: "「给银二两，各不相欠。」十二年——就值二两银子。"

动机激发:
  十二年侍奉 → 只得二两银子
  心中怨恨 → 与老范合谋 → 贪心杀害主人
```

---

## 5. 主角台词的重复模式分析

### 从 case.json 中提取

```
主角开场风格:
L16:  "你把当时的情况，一句一句说清楚"      [一句一句]
L31:  "那我们就从那晚说起。..."              [标准开场]
L247: "那好。一条一条过。你说的每一句话——我都有东西反驳" [一条一条]

↑ "一句一句" vs "一条一条" 的重复

对浮囊的重复引用:
L61:  "这是牛皮浮囊——水上救命用的"
L75:  "你怎么知道是'大洞'？"
L122: "暗礁撞的？那你看看这个"

↑ 不够自然，显得机械
```

### 建议改进方向

**当前（机械）:**
```
"你说的每一句话——我都有东西反驳"
"那好。一条一条过"
```

**改进后（自然）:**
```
"既然你说得这么有把握，不如逐个过一遍——或许我听着就通了"
"你说得还挺圆满。但这几处，我得请你再解释一下"
```

---

## 6. emotion 字段补全清单

### agui.json 需要补充 emotion 的台词

```json
// hub 节点
{
  "speaker_id": "agui",
  "text": "（阿贵蹲在墙角，眼睛红肿）大人……小的、小的实在是太害怕了……",
  "emotion": "panic"  // ← 需要添加
}

// ask_relationship 全段
{
  "speaker_id": "agui",
  "text": "老爷对小的很好。十二年了，吃住都是老爷供的。\n\n小的这辈子都感激老爷的大恩。",
  "emotion": "loyal"  // ← 需要添加 (虚伪的忠诚)
}

// show_dismissal
{
  "speaker_id": "agui",
  "text": "！……那、那是……\n\n老爷他……他是说过要把小的遣散。但小的没有怨恨！真的没有！\n\n二两银子……十二年……\n\n（声音颤抖）小的没有怨恨。",
  "emotion": "resentful"  // ← 需要添加 (隐藏的怨恨)
}

// show_bladder 中多个阶段
{
  "speaker_id": "agui",
  "text": "（猛地站起来）那——那不是小的的！是、是……",
  "emotion": "alarmed"  // ← 需要添加
},
{
  "speaker_id": "agui",
  "text": "……",
  "emotion": "silent"  // ← 需要添加
},
{
  "speaker_id": "agui",
  "text": "（沉默良久）",
  "emotion": "defeated"  // ← 需要添加
}

// confession 节点的所有台词都需要标注
{
  "speaker_id": "agui",
  "text": "（猛然站起）大人！小的——小的是冤枉的！",
  "emotion": "desperate"  // ← 需要添加
}
```

---

## 7. Emotion 可用值建议表

```json
{
  "neutral": "中立",
  "nervous": "紧张",
  "panic": "惊慌",
  "alarmed": "警惕",
  "defensive": "防守",
  "loyal": "忠诚(虚伪)",
  "resentful": "怨恨",
  "silent": "沉默",
  "defeated": "心灰意冷",
  "desperate": "绝望",
  "resolved": "坦然",
  "thinking": "思考",
  "shaken": "摇动(躯体反应)",
  "collapsed": "崩溃"
}
```

---

## 8. 肖像变体与 emotion 的建议映射

### 修改建议: casting.json 格式扩展

```json
{
  "case_id": "prologue_ferry",
  "casting": {
    "agui": {
      "actor_id": "",
      "role_name": "阿贵",
      "role_title": "死者仆从",
      "role_intro": "跟随周德茂十二年的老仆。案发后惊魂未定，泪流不止。",
      "is_culprit": true,
      
      // 新增: 肖像映射
      "portrait_variants": {
        "default": "res://assets/cn/portraits/prologue_agui.png",
        
        // 前期对话场景
        "neutral": "res://assets/cn/portraits/prologue_agui.png",
        "nervous": "res://assets/cn/portraits/prologue_agui.png",
        "panic": "res://assets/cn/portraits/prologue_agui_shaken.png",
        "alarmed": "res://assets/cn/portraits/prologue_agui_shaken.png",
        "defensive": "res://assets/cn/portraits/prologue_agui.png",
        "loyal": "res://assets/cn/portraits/prologue_agui.png",
        "resentful": "res://assets/cn/portraits/prologue_agui.png",
        "silent": "res://assets/cn/portraits/prologue_agui_collapsed.png",
        "defeated": "res://assets/cn/portraits/prologue_agui_collapsed.png",
        
        // 对峙场景
        "confrontation_neutral": "res://assets/cn/portraits/prologue_agui_confrontation.png",
        "confrontation_desperate": "res://assets/cn/portraits/prologue_agui_confrontation_shaken.png",
        "confrontation_collapsed": "res://assets/cn/portraits/prologue_agui_confrontation_collapsed.png",
        "confrontation_resolved": "res://assets/cn/portraits/prologue_agui_confrontation.png"
      }
    }
  }
}
```

---

## 9. 快速修复清单

| 优先级 | 文件 | 行号 | 修改内容 |
|--------|------|------|----------|
| 🔴 高 | agui.json | L206 | 改"想说实话" → "无话可说了" |
| 🟠 中 | agui.json | 全文 | 为主要台词补充 emotion 字段 |
| 🟠 中 | case.json | L16-247 | 润色主角台词，避免"一句一句"重复 |
| 🟡 低 | casting.json | 全文 | 添加 portrait_variants 映射表 |
| 🟡 低 | case.json | L61,75,122 | 多角度引用证据，避免机械感 |

