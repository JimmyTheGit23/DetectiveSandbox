# 《渡口沉舟》整合文本参考

> **状态**：参考文档  
> **详细角色设定**：[character_profiles.md](narrative/character_profiles.md)  
> **最终剧本基准**：[PROLOGUE_FERRY_FINAL_STORY_CANON.md](canon/PROLOGUE_FERRY_FINAL_STORY_CANON.md)  
> **对话CSV**：`data/case_tables/prologue_ferry/dialogue_lines.csv`  
> **质证CSV**：`data/case_tables/prologue_ferry/testimony_lines.csv`

---

## 一、NPC称呼规则（陆昭）

| 场景 | NPC | 称呼 | 理由 |
|------|-----|------|------|
| 船舱阶段 | 阿贵/老范/周德茂 | 公子 | 陆昭自称外乡书生 |
| 沉船后调查 | 阿贵 | 公子 | 不知陆昭身份 |
| 沉船后调查 | 老范 | 公子 | 不知陆昭身份 |
| 沉船后调查 | 周氏 | 恩公/先生 | 船家妇人，不知身份 |
| 沉船后调查 | 钱里正 | 大人 | 知道陆昭是御史台派来的人 |
| 沉船后调查 | 凌瑶 | 陆大人 | 知道陆昭身份 |
| 沉船后调查 | 沈清月 | 大人→公子→大人 | **故意**：她知道陆昭身份，用"大人"试探/讽刺 |
| 质证环节 | 王大爷/阿贵/老范 | 大人 | 钱里正主持正式场合，已建立权威 |

### 沈清月称呼特殊设计
- 第123行：`'大人'——哦对了，您的官印好像丢了？那就叫你'公子'吧。`
- 之后故意交替使用"大人"和"公子"，体现她**知道真相但装不知道**的双面性格

---

## 二、故事时间线摘要

```
楔子 → 万历河弊，沈家/陆昭/周德茂各有隐患
第一章 → 夜舟四客（陆昭/周德茂/老范/阿贵），劣谋初生
第二章 → 沈清月登船布毒，凿船触发毒囊，周德茂溺亡
第三章 → 污名加身，栽赃闭环形成
第四章 → 四轮对峙（王大爷→老范→阿贵→沈清月），法理绝杀
第五章 → 沈清月脱罪离去，陆昭败局留火
```

---

## 三、角色情绪标签速查

| 角色 | 默认 | 紧张 | 崩溃/真相 | 特殊 |
|------|------|------|-----------|------|
| 陆昭 | cold/serious | quiet_fury | tired | dry_humor（极罕见）|
| 凌瑶 | cheerful | anxious/worried | shocked | smug（验证猜测）|
| 阿贵 | grief（假哭）| nervous/panic | broken | cold_flash（闪现真面目）|
| 老范 | smirk | nervous | cornered/pleading | dismissive（不当回事）|
| 周氏 | grief | suspicious | screaming | bitter（提丈夫刻薄）|
| 钱里正 | fawning | nervous | evasive | gossip（八卦时信息最多）|
| 王大爷 | stoic | angry | contempt | gentle（罕见同情）|
| 沈清月 | bold（表演）| deflecting | cold_fury（真面目）| broken（提父亲时）|

---

## 四、对话文本索引

### dialogue_lines.csv 节点列表
| NPC | 节点 | 说明 |
|-----|------|------|
| agui_cabin | ask_master, ask_voyage, ask_feelings, observe_cabin | 船舱阶段 |
| lao_fan_cabin | ask_route, ask_weather, ask_cabin, ask_money, observe_cabin | 船舱阶段 |
| zhou_de_gui_cabin | ask_business, ask_night_ferry, ask_servant, observe_cabin | 船舱阶段 |
| agui | intro, ask_relationship, press_alibi, show_dismissal, show_bladder, confession, ask_twelve_years | 岸上调查 |
| lao_fan | intro, press_route, ask_rescue, show_hull, show_iou, ask_gambling_story, ask_shen_connection, ask_route | 岸上调查 |
| zhou_wife | intro, ask_agui, ask_swimming, ask_why_night_ferry, react_murder_confirmed, react_agui_confessed, ask_suspicion, comfort, ask_documents | 岸上调查 |
| li_zheng | intro, ask_reef, ask_recent_strangers, ask_fan, ask_agui_spending, ask_victim | 岸上调查 |
| fisherman_wang | intro, ask_channel, ask_meeting, trust, ask_dawn_sighting, ask_river_life | 岸上调查 |
| shen_qingyue | intro, ask_quarrel, ask_alibi, ask_fan_connection, ask_father, press_dock_timing, press_salvage, press_connection, confession_trigger | 岸上调查 |

### testimony_lines.csv 质证列表
| 质证ID | 对象 | 说明 |
|--------|------|------|
| testimony_wang | 王大爷 | 第一轮：破老翁伪证 |
| testimony_lao_fan_route | 老范 | 第二轮A：破触礁谎言 |
| testimony_lao_fan_rescue | 老范 | 第二轮B：破时间矛盾 |
| testimony_lao_fan_motive | 老范 | 第二轮C：破动机 |
| testimony_0 ~ testimony_3 | 阿贵 | 第三轮：破逃生伪供 |
| shen_testimony_1 ~ shen_testimony_3 | 沈清月 | 第四轮：终局对弈 |
