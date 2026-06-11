# 当前证物获得途径（prologue_ferry）

来源：`data/case_tables/prologue_ferry` 当前 CSV 表。`type=evidence` 为证据，`type=clue` 为线索。

## 证据（24）

| 名称 | ID | 阶段 | 获得途径 |
| --- | --- | --- | --- |
| 船底人工破洞 | `evidence_hull_hole` | phase_1 | 搜索：沉船打捞处 / 船底破洞<br>事件：沉船惊变（evt_cabin_sinking，第 5 段） |
| 牛皮浮囊 | `evidence_float_bladder` | phase_1 | 搜索：沉船打捞处 / 岸边芦苇丛 |
| 赌债字据 | `evidence_gambling_iou` | phase_3 | 搜索：石矶渡·码头 / 码头竹棚杂物 |
| 遣散字据 | `evidence_dismissal_note` | phase_1 | 搜索：周氏房间 / 桌上纸笔砚台 -> 翻看正式文书 |
| 失踪的货银 | `evidence_cargo_silver` | phase_2 | 搜索：沉船打捞处 / 货舱残骸 |
| 沈父药账 | `evidence_father_ledger` | phase_3 | 搜索：客栈二楼·沈清月房间 / 床边草屑 |
| 船底钉痕 | `evidence_nail_marks` | phase_1 | 搜索：沉船打捞处 / 水边断钉木屑 |
| 尸检报告：无钝器伤 | `evidence_no_blunt_trauma` | phase_1 | 搜索：石矶渡·码头 / 岸边的尸体 |
| 泡烂的密信 | `evidence_wet_letter` | - | 搜索：江湾渔村 / 王大爷家 |
| 匿名字条残片 | `evidence_anonymous_note` | - | 搜索：石矶渡·码头 / 码头竹棚杂物（conditional_1）（有条件） |
| 救起时间笔录 | `evidence_cabin_escape_time` | - | 事件：沉船惊变（evt_cabin_sinking，第 55a 段） |
| 凌瑶身份证明 | `evidence_lingyao_identity` | - | 事件：沉船惊变（evt_cabin_sinking，第 19 段） |
| 铁撬棍位置 | `evidence_iron_crowbar_location` | - | 事件：沉船惊变（evt_cabin_sinking，第 8 段） |
| 翻船处岸距与雾况 | `evidence_weather_fog` | - | 事件：沉船惊变（evt_cabin_sinking，第 66b 段） |
| 夜雨风浪与听距 | `evidence_storm_noise` | - | 事件：沉船惊变（evt_cabin_sinking，第 66b 段） |
| 蓝色草药碎屑 | `evidence_blue_herb_residue` | phase_1 | 搜索：石矶渡·码头 / 岸边的尸体 -> 检查指甲缝隙 |
| 脖颈淡压痕 | `evidence_neck_marks` | phase_1 | 搜索：石矶渡·码头 / 岸边的尸体 -> 检查脖颈皮肤 |
| 毒囊残壳 | `evidence_drug_capsule_shell` | phase_2 | 搜索：沉船打捞处 / 水边断钉木屑 -> 检查进水口边缘（有条件） |
| 毒囊定位吻合 | `evidence_capsule_position_match` | phase_3 | 对峙奖励：confrontation_final / — 证词其三：你没有证据 — |
| 遗失官印 | `evidence_seal_lost` | phase_1 | 事件：沉船惊变（evt_cabin_sinking，第 10 段） |
| 官印封角残片 | `evidence_seal_cloth_wrap` | phase_4 | 搜索：石矶渡·码头 / 芦苇里的锦袋残角 |
| 舌根草药残留 | `evidence_tongue_herb_residue` | phase_2 | 搜索：石矶渡·码头 / 岸边的尸体 -> 检查口舌残留 |
| 油脂锁毒推定 | `evidence_oil_lock_residue` | phase_3 | 搜索：石矶渡·码头 / 岸边的尸体 -> 检查口腔油脂层（有条件）<br>搜索：周氏房间 / 墙角包袱行李 -> 检查油纸食盒（有条件） |
| 漕账残页 | `evidence_account_fragment` | phase_4 | 搜索：石矶渡·码头 / 芦苇里的锦袋残角 -> 翻看夹在船板间的湿纸（有条件） |

## 线索（30）

| 名称 | ID | 阶段 | 获得途径 |
| --- | --- | --- | --- |
| 下游打捞痕迹 | `evidence_salvage_mark` | phase_2 | 对话：王大爷 -> 「天亮之前，你还看到别的什么了吗？」 |
| 赌坊中间人 | `evidence_shen_connection` | phase_3 | 对话：老范 -> 「阿贵已经招了。那个'药材行的姑娘'——是她先找你的吧？」 |
| 码头时间矛盾 | `evidence_dock_timing` | phase_3 | 事件效果：客栈变局（evt_phase3_transition） |
| 周氏的怀疑 | `clue_wife_suspicion` | - | 对话：周氏 -> 「你为什么觉得不是意外？」 |
| 错误的航道 | `evidence_wrong_channel` | phase_1 | 对话：王大爷 -> 「他们走的哪条航道？」 |
| 阿贵内衣干燥 | `clue_agui_dry_inner` | - | 搜索：阿贵住处 / 晾着的湿衣物 -> 摸摸里衣的干湿程度 |
| 老范时间矛盾 | `clue_fan_alibi_hole` | - | 对话：王大爷 -> 「你看到了什么？」 |
| 深夜密谈 | `clue_secret_meeting` | - | 对话：王大爷 -> 「案发前一晚你看到什么了？」 |
| 阿贵的新钱 | `clue_agui_spending` | - | 搜索：石矶渡·客栈 / 客栈大堂<br>搜索：阿贵住处 / 晾着的湿衣物 -> 翻翻腰带和口袋<br>对话：钱里正 -> 「阿贵这两天有什么异常吗？」<br>对峙奖励：confrontation / — 证词其二：那晚的经过 — |
| 老范的水性 | `clue_fan_boat_skill` | - | 对话：钱里正 -> 「老范这个人怎么样？」 |
| 老范独自修船 | `clue_fan_night_work` | - | 搜索：石矶渡·码头 / 老范的小船 |
| 死者不识水性 | `clue_victim_cant_swim` | - | 对话：周氏 -> 「你丈夫会游泳吗？」 |
| 暗礁是常识 | `clue_reef_common_knowledge` | - | 对话：王大爷 -> 「你敢断定老范不是失手？」<br>对话：钱里正 -> 「那片礁石，本地人都知道？」 |
| 阿贵可疑的包袱 | `clue_agui_suspicious_bag` | - | 搜索：阿贵住处 / 床下包袱 -> 强行解开死结<br>对话：阿贵 -> 「你包袱底下怎么是湿的？」 |
| 沉船记忆：方形的洞 | `clue_cabin_hole_memory` | - | **未找到直接发放入口** |
| 改道的建议 | `clue_route_change` | - | 对话：周氏 -> 「你丈夫为什么突然决定走夜船？」 |
| 码头的三个人影 | `clue_lingyao_dock_witness` | - | **未找到直接发放入口** |
| 五十两货银记录 | `clue_cargo_money_record` | - | 搜索：周氏房间 / 墙角包袱行李 |
| 周氏未完成的家信 | `clue_zhou_unfinished_letter` | - | 搜索：周氏房间 / 桌上纸笔砚台 -> 检查未寄出的信件 |
| 第三种笔迹 | `clue_third_handwriting` | - | 搜索：周氏房间 / 桌上纸笔砚台 -> 对比桌上各张纸的笔迹<br>对话：钱里正 -> 「渡口最近有什么异常吗？」<br>对峙奖励：confrontation / — 证词其四：不是我干的 — |
| 外袍上的红泥 | `clue_agui_red_mud` | - | 搜索：阿贵住处 / 晾着的湿衣物 -> 仔细检查湿外袍 |
| 水手绳结 | `clue_agui_sailor_knot` | - | 搜索：阿贵住处 / 床下包袱 -> 检查包袱布料和绳结 |
| 沈清月的药钱动机 | `clue_shen_motive_calculation` | - | 对话：沈清月 -> 「你父亲的病，很严重？」 |
| 陆昭无杀人动机 | `evidence_no_motive` | - | **未找到直接发放入口** |
| 旅途札记 | `clue_travel_notes` | - | 序章：cabin_prologue_1 |
| 随身官印木匣 | `clue_cabin_seal_box` | - | 搜索：自己的舱室 / 官印木匣 |
| 夜船路线疑点 | `clue_cabin_route_note` | - | 搜索：自己的舱室 / 桌上行程简记 |
| 窗外风雨 | `clue_cabin_storm_window` | - | 搜索：自己的舱室 / 雨夜小窗 |
| 异常湿斗篷 | `clue_cabin_wet_cloak` | - | 搜索：自己的舱室 / 墙边湿斗篷 |
| 阿贵口供笔录 | `clue_agui_confession` | phase_3 | 事件效果：客栈变局（evt_phase3_transition） |

## 当前无直接发放入口

- 沉船记忆：方形的洞 (`clue_cabin_hole_memory`, clue)
- 码头的三个人影 (`clue_lingyao_dock_witness`, clue)
- 陆昭无杀人动机 (`evidence_no_motive`, clue)

## GM 跳转进场行为

- 修正前：GM 套预设会强制切地点并触发 `location_changed`，因此可能播放首次地名卡和 `arrive_location:*` 到达闲聊。
- 修正后：`_gm_force_location()` 默认静默进场，会抑制首次地名卡和到达闲聊；GM 直接跳对话/旁白不走场景进入逻辑。
