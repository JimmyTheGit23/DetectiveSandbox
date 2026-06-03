# 序章对峙剧情具体改进方案

## 概述

针对序章「渡口沉舟」的对峙剧情，提供具体的 CSV 修改方案，提升剧情丰富度。

---

## 1. 修改文件清单

| 文件 | 修改类型 | 优先级 |
|------|---------|--------|
| `confrontation_lines.csv` | 增加开场剧情 | 高 |
| `testimony_lines.csv` | 补充缺失过渡 | 高 |
| `testimony_lines.csv` | 增加围观群众反应 | 中 |
| `testimony_press_lines.csv` | 增加角色标志性台词 | 中 |

---

## 2. 具体修改内容

### 2.1 增加开场剧情（confrontation_lines.csv）

**当前：** 7句开场对话
**目标：** 15句开场对话

**在 `confrontation_lines.csv` 中添加：**

```csv
confrontation,intro_dialogue,7,,,"外面的雨越下越大。雨水顺着屋檐滴落，在地上汇成小溪。
大堂里弥漫着潮湿的霉味和香烛的烟气。",narration
confrontation,intro_dialogue,8,阿贵,,（缩在角落，双手绞在一起，指节发白。嘴里喃喃着什么——听不清。）,nervous
confrontation,intro_dialogue,9,老范,,（坐在门口，旱烟杆在手里转了一圈又一圈。烟锅早灭了，他没注意。）,evasive
confrontation,intro_dialogue,10,周氏,,（红着眼，手里攥着帕子。帕子已经被攥得皱巴巴的——像她这些天的脸。）,grief
confrontation,intro_dialogue,11,王大爷,,（靠在柱子上，双手抱胸。眼睛半睁半闭——像是在打盹，又像是在等什么。）,evasive
confrontation,intro_dialogue,12,凌瑶,,（低声）都到齐了。陆大人——开始吧。,determined
confrontation,intro_dialogue,13,,,（你扫视了一圈。六个人，六种心思。有人在装可怜，有人在装傻，有人在等真相。
而你——要把这层窗户纸捅破。）,inner_thought
confrontation,intro_dialogue,14,陆昭,,（深吸一口气）好。——那就从头说起。,cold
```

### 2.2 补充 testimony_3 过渡对话（testimony_lines.csv）

**当前：** 无过渡
**目标：** 6句过渡对话

**在 `testimony_lines.csv` 中添加：**

```csv
testimony_3,transition_dialogue,0,阿贵,,（双手抱头，蹲在地上）小的……小的只是个下人……
testimony_3,transition_dialogue,1,凌瑶,,（低声）他又在装可怜了。可这次——遣散字据在他脸上。
testimony_3,transition_dialogue,2,钱里正,,（低声）这……遣散字据……阿贵，你之前可没提过这个。
testimony_3,transition_dialogue,3,周氏,,（突然开口）阿贵。老爷遣散你——是为什么？
testimony_3,transition_dialogue,4,阿贵,,（身体一僵）夫、夫人……
testimony_3,transition_dialogue,5,凌瑶,,（低声）周氏开口了。这下他更难编了。
```

### 2.3 补充 shen_testimony_2 过渡对话（testimony_lines.csv）

**当前：** 无过渡
**目标：** 5句过渡对话

**在 `testimony_lines.csv` 中添加：**

```csv
shen_testimony_2,transition_dialogue,0,沈清月,,（冷笑）大人，您拿一个赌鬼的话来定我的罪？
shen_testimony_2,transition_dialogue,1,凌瑶,,（低声）她开始攻击证据来源了。这是她的防御策略。
shen_testimony_2,transition_dialogue,2,你,,证据不分贵贱。只看真假。
shen_testimony_2,transition_dialogue,3,沈清月,,（挑眉）哦？那大人倒是说说——老范的话，有几分真？
shen_testimony_2,transition_dialogue,4,凌瑶,,（低声）她在把水搅浑。得用时间线上的矛盾堵她。
```

### 2.4 补充 shen_testimony_3 过渡对话（testimony_lines.csv）

**当前：** 无过渡
**目标：** 5句过渡对话

**在 `testimony_lines.csv` 中添加：**

```csv
shen_testimony_3,transition_dialogue,0,沈清月,,（抱臂，下巴微抬）大人。您的证据——都是间接的。
shen_testimony_3,transition_dialogue,1,凌瑶,,（低声）她在说'你没有直接证据'。这是她最后的防线。
shen_testimony_3,transition_dialogue,2,你,,间接证据也是证据。一条链环扣一环——足以定罪。
shen_testimony_3,transition_dialogue,3,沈清月,,（冷笑）链环？大人，您这链环——哪一环不是别人嘴里说出来的？
shen_testimony_3,transition_dialogue,4,凌瑶,,（低声）她在质疑证据的可信度。得用最硬的那块——时间线矛盾。
```

### 2.5 增加围观群众反应（testimony_lines.csv）

**在关键证词后增加围观群众反应：**

**testimony_2 之后增加：**

```csv
testimony_2,transition_dialogue,12,钱里正,,（低声）这……阿贵，你之前说的'暗礁'……
testimony_2,transition_dialogue,13,周氏,,（突然抬头）阿贵。你说实话。
testimony_2,transition_dialogue,14,阿贵,,（身体发抖）夫人……小的……
testimony_2,transition_dialogue,15,凌瑶,,（低声）周氏的压迫感比我们还强。
```

**testimony_lao_fan_motive 之后增加：**

```csv
testimony_lao_fan_motive,transition_dialogue,7,周氏,,（突然站起来）老范！你说——是不是你害了老爷！
testimony_lao_fan_motive,transition_dialogue,8,老范,,（吓得往后一缩）夫、夫人……老汉冤枉……
testimony_lao_fan_motive,transition_dialogue,9,钱里正,,（赶紧拦住）周氏！周氏你先坐下！让大人问！
testimony_lao_fan_motive,transition_dialogue,10,凌瑶,,（低声）周氏快忍不住了。这对我们有利——她的质问比我们更狠。
```

### 2.6 增加角色标志性台词（testimony_press_lines.csv）

**阿贵的标志性台词：**

```csv
s1_2,press,0,阿贵,,小的冤枉啊！大人您明鉴！（双手合十，连连作揖）,defensive
s1_2,press,1,凌瑶,,（低声）他又在求神拜佛了。每次心虚就这样。
```

**老范的标志性台词：**

```csv
fan_route_2,press,0,老范,,老汉跑船二十年……这种事……老汉不敢认……,evasive
fan_route_2,press,1,凌瑶,,（低声）'跑船二十年'——他每次说这话，就是在给自己找台阶下。
```

**沈清月的标志性台词：**

```csv
sf1_3,press,0,沈清月,,（轻笑）大人。'指向'和'证明'之间——隔着一条人命。,sharp
sf1_3,press,1,凌瑶,,（低声）她又在说这话了。每次她这么说，就是在提醒我们——证据不够硬。
```

---

## 3. 修改步骤

### 步骤 1：备份原文件

```bash
cp data/case_tables/prologue_ferry/confrontation_lines.csv data/case_tables/prologue_ferry/confrontation_lines.csv.bak
cp data/case_tables/prologue_ferry/testimony_lines.csv data/case_tables/prologue_ferry/testimony_lines.csv.bak
cp data/case_tables/prologue_ferry/testimony_press_lines.csv data/case_tables/prologue_ferry/testimony_press_lines.csv.bak
```

### 步骤 2：编辑 confrontation_lines.csv

在 `confrontation_lines.csv` 的 `intro_dialogue` 部分，在第 14 行之后添加新的对话行。

### 步骤 3：编辑 testimony_lines.csv

在 `testimony_lines.csv` 中：
1. 在 `testimony_3` 的 `transition_dialogue` 部分添加 6 句过渡对话
2. 在 `shen_testimony_2` 的 `transition_dialogue` 部分添加 5 句过渡对话
3. 在 `shen_testimony_3` 的 `transition_dialogue` 部分添加 5 句过渡对话
4. 在 `testimony_2` 的 `transition_dialogue` 部分添加 4 句围观群众反应
5. 在 `testimony_lao_fan_motive` 的 `transition_dialogue` 部分添加 4 句围观群众反应

### 步骤 4：编辑 testimony_press_lines.csv

在 `testimony_press_lines.csv` 中添加角色标志性台词。

### 步骤 5：验证并编译

```bash
python3 tools/data_compiler/validate_case_tables.py --case prologue_ferry
python3 tools/data_compiler/compile_case.py --case prologue_ferry --write-runtime
```

---

## 4. 预期效果

### 4.1 开场剧情改进

**之前：** 7句对话，快速进入对峙
**之后：** 15句对话，充分渲染氛围

**效果：**
- 玩家有时间感受场景氛围
- 了解每个角色的状态
- 增强仪式感和紧张感

### 4.2 证词间过渡改进

**之前：** 部分证词无过渡，剧情跳跃
**之后：** 所有证词都有3-6句过渡

**效果：**
- 剧情更连贯
- 角色性格更突出
- 围观群众反应增强沉浸感

### 4.3 角色标志性改进

**之前：** 角色有基本性格
**之后：** 角色有标志性动作/台词

**效果：**
- 角色辨识度更高
- 对话更生动
- 增强记忆点

---

## 5. 完整修改示例

### 5.1 confrontation_lines.csv 修改示例

**原文件片段：**
```csv
confrontation,intro_dialogue,5,陆昭,,好。先请一位证人说话。——王大爷。,cold
confrontation,intro_dialogue,6,凌瑶,,（低声）先让王大爷把那天夜里看到的东西说出来。有了他的证言打底，后面才好发难。,anxious
```

**修改后：**
```csv
confrontation,intro_dialogue,5,陆昭,,好。先请一位证人说话。——王大爷。,cold
confrontation,intro_dialogue,6,凌瑶,,（低声）先让王大爷把那天夜里看到的东西说出来。有了他的证言打底，后面才好发难。,anxious
confrontation,intro_dialogue,7,,,"外面的雨越下越大。雨水顺着屋檐滴落，在地上汇成小溪。
大堂里弥漫着潮湿的霉味和香烛的烟气。",narration
confrontation,intro_dialogue,8,阿贵,,（缩在角落，双手绞在一起，指节发白。嘴里喃喃着什么——听不清。）,nervous
confrontation,intro_dialogue,9,老范,,（坐在门口，旱烟杆在手里转了一圈又一圈。烟锅早灭了，他没注意。）,evasive
confrontation,intro_dialogue,10,周氏,,（红着眼，手里攥着帕子。帕子已经被攥得皱巴巴的——像她这些天的脸。）,grief
confrontation,intro_dialogue,11,王大爷,,（靠在柱子上，双手抱胸。眼睛半睁半闭——像是在打盹，又像是在等什么。）,evasive
confrontation,intro_dialogue,12,凌瑶,,（低声）都到齐了。陆大人——开始吧。,determined
confrontation,intro_dialogue,13,,,（你扫视了一圈。六个人，六种心思。有人在装可怜，有人在装傻，有人在等真相。
而你——要把这层窗户纸捅破。）,inner_thought
confrontation,intro_dialogue,14,陆昭,,（深吸一口气）好。——那就从头说起。,cold
```

### 5.2 testimony_lines.csv 修改示例

**原文件片段：**
```csv
testimony_3,fail_dialogue,0,阿贵,,大人……小的只是个下人，哪有本事害人性命……您搞错了！,defensive
testimony_3,fail_dialogue,1,凌瑶,,（低声）他装孝子呢。好主仆？那咱们手里那张字据怎么说？拿出来打他脸。,worried
```

**修改后：**
```csv
testimony_3,fail_dialogue,0,阿贵,,大人……小的只是个下人，哪有本事害人性命……您搞错了！,defensive
testimony_3,fail_dialogue,1,凌瑶,,（低声）他装孝子呢。好主仆？那咱们手里那张字据怎么说？拿出来打他脸。,worried
testimony_3,transition_dialogue,0,阿贵,,（双手抱头，蹲在地上）小的……小的只是个下人……
testimony_3,transition_dialogue,1,凌瑶,,（低声）他又在装可怜了。可这次——遣散字据在他脸上。
testimony_3,transition_dialogue,2,钱里正,,（低声）这……遣散字据……阿贵，你之前可没提过这个。
testimony_3,transition_dialogue,3,周氏,,（突然开口）阿贵。老爷遣散你——是为什么？
testimony_3,transition_dialogue,4,阿贵,,（身体一僵）夫、夫人……
testimony_3,transition_dialogue,5,凌瑶,,（低声）周氏开口了。这下他更难编了。
```

---

## 6. 注意事项

### 6.1 CSV 格式

- 确保每行的列数一致
- 多行文本用引号包围
- 保持 `testimony_id,section,order,speaker,speaker_id,text,emotion` 的列顺序

### 6.2 顺序问题

- `order` 字段决定显示顺序
- 新增的过渡对话应放在 `fail_dialogue` 之后
- 确保顺序号连续

### 6.3 验证

修改后必须运行验证：
```bash
python3 tools/data_compiler/validate_case_tables.py --case prologue_ferry
```

---

## 7. 总结

### 修改统计

| 文件 | 新增行数 | 优先级 |
|------|---------|--------|
| `confrontation_lines.csv` | +8行 | 高 |
| `testimony_lines.csv` | +24行 | 高 |
| `testimony_press_lines.csv` | +6行 | 中 |
| **总计** | **+38行** | - |

### 预期提升

| 维度 | 之前 | 之后 | 提升 |
|------|------|------|------|
| 开场剧情 | ⭐⭐⭐ | ⭐⭐⭐⭐ | +1 |
| 证词间过渡 | ⭐⭐ | ⭐⭐⭐⭐ | +2 |
| 围观群众 | ⭐⭐ | ⭐⭐⭐ | +1 |
| 角色标志性 | ⭐⭐⭐ | ⭐⭐⭐⭐ | +1 |
| **总体** | ⭐⭐⭐ | ⭐⭐⭐⭐ | **+1** |

### 实施时间

- 高优先级修改：1-2小时
- 中优先级修改：30分钟
- 验证测试：15分钟

**总计：约2-3小时**

---

*文档版本：1.0*
*最后更新：2026-05-30*