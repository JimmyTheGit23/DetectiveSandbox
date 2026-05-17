# 未生成语音清单

> **自动生成**: `python tools/audit_voices.py`  **最后扫描**: 见 git blame  **用途**: 跟踪每个案件中尚未生成 TTS 的对话/序章/事件节点。新案件 PR 必跑此脚本。

## 总览

| 案件 | 标题 | voice_status | 已有 | 缺失 | 状态 |
|------|------|------|------|------|------|
| `linchuan_inn` | 临川驿案 | `full` | 103 | 0 | ✅ 全量 |
| `xunyang_pavilion` | 浔阳楼·夜雨红绸案 | `missing` | 2 | 69 | ⚠ 全部待生成（69 条） |

## 浔阳楼·夜雨红绸案 (`xunyang_pavilion`)

缺失 69 条。

### 对话

#### bu_zhang → actor_wealthy_merchant（2 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `show_ledger` | `assets/cn/voices/actor_wealthy_merchant/xunyang_pavilion/show_ledger.wav` | （取出账册）大人请看，此处便是那一笔。字迹潦草，银两付得干脆。  小人做了二十年绸缎生意——案发后急着补一匹同款，总觉得不大寻常。 |
| `match_silk` | `assets/cn/voices/actor_wealthy_merchant/xunyang_pavilion/match_silk.wav` | （对着灯细看）大人，这残片的经纬与小号那批绛红云纹绸相合。此色此纹，本城只小号有存货。  三日前浔阳楼取过一匹，案发后又有人另买一匹——两笔买家是否同一人，小… |

#### lady_zhou → actor_elder_grandmother（5 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `greet` | `assets/cn/voices/actor_elder_grandmother/xunyang_pavilion/greet.wav` | （周老夫人手拄藤杖）御史大人。是为秋菱那孩子来的吧。 |
| `about_debt` | `assets/cn/voices/actor_elder_grandmother/xunyang_pavilion/about_debt.wav` | 五十两。是她来借的，凑赎身银。我没催——我是盼着她走得成。一个清清白白的姑娘，不该一辈子待在这种地方。 |
| `alibi` | `assets/cn/voices/actor_elder_grandmother/xunyang_pavilion/alibi.wav` | 老身那夜住在城南别院。年纪大了，入夜便不出门。  但老身前一日傍晚去过浔阳楼——是去跟青姐说，秋菱的赎身银快凑齐了，让她把手续办利索。青姐当时脸色不太好看。 |
| `qingjie_reaction` | `assets/cn/voices/actor_elder_grandmother/xunyang_pavilion/qingjie_reaction.wav` | （拄杖）秋菱是浔阳楼的摇钱树。她走了，楼里的生意少说折三成。青姐打理这楼十年，岂会心甘？  但老身只是说个猜测——大人自行判断。 |
| `show_redemption` | `assets/cn/voices/actor_elder_grandmother/xunyang_pavilion/show_redemption.wav` | 三百两——陈老客人的聘。加上老身借她的五十两凑齐赎身银。明日就要走了。  谁不让她走——大人问问楼里的人便知。 |

#### liu_chuan → actor_foreign_traveler（4 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `greet` | `assets/cn/voices/actor_foreign_traveler/xunyang_pavilion/greet.wav` | （刘船家眼神躲闪，正在收缆绳）大人……要渡江么？ |
| `about_night` | `assets/cn/voices/actor_foreign_traveler/xunyang_pavilion/about_night.wav` | 三更头我打盹被惊醒，看见一个人影从水阁那头走出来，往江边丢了个包袱。  我没敢出声。那人走得急——像是怕被人看见。 |
| `figure_detail` | `assets/cn/voices/actor_foreign_traveler/xunyang_pavilion/figure_detail.wav` | ……戴了兜帽。身形不高——不像是个大男人。但也可能是缩着肩膀走的。夜里看不真切。 |
| `about_prints` | `assets/cn/voices/actor_foreign_traveler/xunyang_pavilion/about_prints.wav` | 那条缆绳上的扣子不是我打的——那是个生手扣，渔家不会那样打。说明来的人不常下水。 |

#### ma_san → actor_jianghu_swordsman（4 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_jianghu_swordsman/xunyang_pavilion/intro.wav` | （马三抱拳）陆大人。鲁知府判的是'醉酒失足'，但末将看了现场——红绸断口和栏杆挣痕都不对劲。大人但有差遣，末将听调。 |
| `request_help` | `assets/cn/voices/actor_jianghu_swordsman/xunyang_pavilion/request_help.wav` | 末将立即布置。前后两门各派两人，三日内进出的全部记下。 |
| `why_lu` | `assets/cn/voices/actor_jianghu_swordsman/xunyang_pavilion/why_lu.wav` | 本府前年出过一桩'醉死的伶人'，闹得名声不好。鲁大人怕这案子再闹大。  大人手上若证据充分，鲁大人也不敢压。 |
| `opinion` | `assets/cn/voices/actor_jianghu_swordsman/xunyang_pavilion/opinion.wav` | 末将觉得——楼里不止一个人有心事。但心事归心事，推人归推人。大人还是看证据说话稳当。 |

#### magistrate_lu → actor_senior_prefect（4 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_senior_prefect/xunyang_pavilion/intro.wav` | （鲁知府捻须）陆大人远来辛苦。这案子本府已经查过——醉酒失足，证据明白。大人不必费心。 |
| `argue_railing` | `assets/cn/voices/actor_senior_prefect/xunyang_pavilion/argue_railing.wav` | （眉头微皱）……指甲痕？本府再看看。但这也可能是她抓栏时留下的——不算定论。 |
| `argue_silk` | `assets/cn/voices/actor_senior_prefect/xunyang_pavilion/argue_silk.wav` | （脸色微变）……这红绸的断口确实不像失足。罢罢，本府改'存疑'二字，等大人再查三日。 |
| `argue_witness` | `assets/cn/voices/actor_senior_prefect/xunyang_pavilion/argue_witness.wav` | （沉默良久）阁中有第二人——那便不是失足了。本府这就把结案稿撕了。陆大人，这桩案子交予您。 |

#### qing_jie → actor_madam_proprietress（10 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/intro.wav` | （青姐含泪）大人。秋菱是我一手带大的，她若真是失足，我认了。可若不是——大人可一定要查个明白。 |
| `last_company` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/last_company.wav` | 那夜雨大，楼里少有客人。她偏房点了灯。我去送了一壶酒上去——出来时听见她在跟人说话。 |
| `voice_who` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/voice_who.wav` | （迟疑）……声音压得低，我没听清。我只知道她在说'你别拦我'。 |
| `loan_truth` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/loan_truth.wav` | 她欠周夫人五十两，是为了凑赎身银。差三百两不到，借期急得很。 |
| `show_redemption` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/show_redemption.wav` | （青姐怔了一下，随即恢复）……这便是了。外地一位客人三百两为聘。秋菱说她要走——我劝过她，浔阳楼离了她，日子难过。  但她主意已定。 |
| `who_loses` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/who_loses.wav` | （眼神闪过一丝什么）……这楼是我打理的。秋菱走了，下一个头牌不知几年才能养出来。但大人，我不至于为这个—— |
| `confront_shoes` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/confront_shoes.wav` | （脸色微变）……那双鞋，是白日里我去后院看过现场——大人忘了？我早上在那儿上过香。 |
| `confront_ledger` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/confront_ledger.wav` | （沉默良久）……那是我改的没错。赎身的事还没定，我先把账挂'待议'，等她想清楚再说。这有什么问题？ |
| `ledger_pressed` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/ledger_pressed.wav` | （青姐抬起头，眼眶红了）……大人。我养了她十年。她说走就走，连一句商量都没有。  我改了账册不假。但我没有——我没有推她。 |
| `alibi` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/alibi.wav` | 案发那夜我在房中。三更听见响动才下楼的——大人可以问孙娘，她看见我下来。 |

#### qing_xuan → actor_opera_performer（9 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/intro.wav` | （白衣公子拱手）在下顾清玄，江南游学之客。秋姑娘那样人物，竟落得这般结局——在下惋惜得很。 |
| `alibi` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/alibi.wav` | 在下吃了酒，醉卧偏房。一觉到天亮——连出事都未听闻。 |
| `press_wine` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/press_wine.wav` | （笑容收了一寸）……罢罢，在下那夜没醉。但在下确实在偏房——心里不痛快，喝不下去。 |
| `relation` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/relation.wav` | （淡淡一笑）相识半年，不过点头之交。 |
| `show_hairpin` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/show_hairpin.wav` | （盯着银钗，半晌）……是在下的。那夜在下去找过她。求她不要走。她说请在下也走。  在下走出去三步——又回去了。但回去的时候，阁子里已经只剩她一个人。 |
| `she_was_fine` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/she_was_fine.wav` | 她靠在栏边，回头对在下笑了笑。那时候她好好的。  在下离开后不到一刻钟就听见了响动——赶到后院时……已经来不及了。 |
| `show_letter` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/show_letter.wav` | （看到信，沉默了）……'清郎'是在下。她要走，在下没拦住。这信，是她写给在下的告别。  在下案后回去拿走了一封同样的信并烧了——不是销毁证据，是不想让旁人说她… |
| `post_actions` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/post_actions.wav` | （苦笑）在下去布庄买了一匹同样的红绸——以为把整匹放回去就能让府衙信'失足'。又去水阁丢了她的一些私物——怕被人翻出来说闲话。  在下知道这些事让在下看起来像… |
| `show_silk` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/show_silk.wav` | 是在下买的。账上那个字是在下写的。  大人若因此治在下的罪——在下认。但推不推她，是另一桩事。请大人明察。 |

#### sun_laoliu → actor_innkeeper_wife（6 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `greet` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/greet.wav` | （孙娘擦着茶碗）大人请坐。出了这事，茶也卖不动了。 |
| `night_movement` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/night_movement.wav` | 三更前我被响动惊醒。后门口我探头看了一眼——有个人从后院方向走回来，走得急。 |
| `who_from_yard` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/who_from_yard.wav` | （压低声音）雨大，灯暗。我只看到那人穿的是楼里的衣裳——不是客人的。但是谁，我不敢说。 |
| `d1_noon` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/d1_noon.wav` | 午时……我记得有两三个人出过楼。一位素衣客人出去一刻钟回来时手里多了个包袱。还有青姐出去又回来——说是去市集买香。 |
| `d1_dusk` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/d1_dusk.wav` | 黄昏雨大。有人披着斗篷从后门出去——往江畔方向。我没看清是谁。 |
| `qingjie_timing` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/qingjie_timing.wav` | （想了想）青姐说她三更听到响动才下楼。但我看到她时，她是从后院那个方向过来的，不是从楼梯口下来。  也许我记错了——夜里黑，也说不准。 |

#### wuchen → actor_buddhist_nun（6 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/intro.wav` | （无尘师太合十）大人安好。 |
| `saw_what` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/saw_what.wav` | 老衲那夜诵经至三更。雨声中望了对楼一眼——阁中有两个人影。一个后退，另一个逼近。前者从栏边坠下。  雨夜朦胧，老衲分辨不出衣色，也分辨不出男女。 |
| `figure_detail` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/figure_detail.wav` | （沉思）不高……比死者略矮些许。身形偏瘦。老衲只看了一眼，不敢妄断。 |
| `intro_after_visit` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/intro_after_visit.wav` | （无尘师太眉头微皱）大人，昨夜有人来庵中敲门——戴了兜帽，问老衲那夜是否听见对楼动静。老衲答「未曾」，那人便走了。  但那人走路的步子——老衲觉得不像是陌生人。 |
| `visit_time` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/visit_time.wav` | 三更刚过。雨已歇。 |
| `step_familiar` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/step_familiar.wav` | （缓缓道）那步子轻快利落，像是常在楼里走动的人。不像是外来的客商或书生。  但老衲不敢指认——兜帽遮了脸，老衲只听了脚步声。 |

### 序章

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `scene1` | `assets/cn/voices/_prologue/xunyang_pavilion/scene1.wav` | 万历二十四年，三月。江南细雨。  这是个风疏雨骤的夜晚，本府名楼——浔阳楼。 |
| `scene2` | `assets/cn/voices/_prologue/xunyang_pavilion/scene2.wav` | 巡按御史陆昭借宿楼中，明日一早便要启程回京。 |
| `scene3` | `assets/cn/voices/_prologue/xunyang_pavilion/scene3.wav` | 夜里三更。楼下传来一声闷响，紧接着是短促的惊叫—— |
| `scene4` | `assets/cn/voices/_prologue/xunyang_pavilion/scene4.wav` | 后院青石板上躺着一位女子。颈间缠着一段绛红云纹绸。  这便是浔阳楼的当家花魁，秋菱。 |
| `scene5` | `assets/cn/voices/_prologue/xunyang_pavilion/scene5.wav` | 她的指甲缝里干净，手心却握着一段红绸。红绸的断口是横向的——这与失足坠落的受力方向不一致。  鲁知府已经拍板：醉后凭栏，失足跌下。 |
| `scene6` | `assets/cn/voices/_prologue/xunyang_pavilion/scene6.wav` | 三日为限。结案稿送回京之前，也许还有值得追问的事。  浔阳楼里的人，都还在。 |

### 日程事件

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `evt_redemption_revealed_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_redemption_revealed_0.wav` | 一封赎身契。三百两白银，赎秋菱归故里。 |
| `evt_redemption_revealed_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_redemption_revealed_1.wav` | 若此契生效，浔阳楼将失去头牌——这对楼里的人意味着什么？ |
| `evt_encounter_dock_figure_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_figure_0.wav` | 夜色未深，江面起了薄雾。你踏上那段湿木板，忽见水阁那头有一个人影背对着你站着。 |
| `evt_encounter_dock_figure_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_figure_1.wav` | 那人手里提着个不大的包袱，正欲俯身把它系在缆绳上。听见脚步，那人猛地一僵——随即转过身来。 |
| `evt_encounter_dock_figure_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_figure_2.wav` | 灯笼微光下，你只看清一个被兜帽遮住半面的轮廓。那人低声说了句什么，便松手让包袱落入江中，绳一抽，顺水而去。 |
| `evt_encounter_dock_figure_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_figure_3.wav` | 你来不及看清那人的脸。但你记住了——那人的身形、那人走路的姿态。 |
| `evt_encounter_chamber_intruder_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_intruder_0.wav` | 你推开闺阁门，正撞见一个人影从妆台前直起身——抽屉半开着，里面的物什被翻乱了。 |
| `evt_encounter_chamber_intruder_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_intruder_1.wav` | 那人转过身，表情一闪而过——是意外，还是心虚？ |
| `evt_encounter_chamber_intruder_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_intruder_2.wav` | 那人说自己是来'整理秋菱遗物'的。但你注意到桌上的内账册翻开在赎身那一页。 |
| `evt_encounter_convent_visitor_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_visitor_0.wav` | 你立在庵前石阶下，听见里面传来低低的话音。 |
| `evt_encounter_convent_visitor_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_visitor_1.wav` | 「……师太昨夜何时熄灯？可有听见对楼有人说话？」 |
| `evt_encounter_convent_visitor_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_visitor_2.wav` | 声音压得很低，你分辨不出是谁。但问的分明是案发夜的事。 |
| `evt_encounter_convent_visitor_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_visitor_3.wav` | 你退到山门后柱影里，看着那人戴着兜帽从侧门匆匆离去。 |

---

## 后续 TTS 生成提示

1. 每条缺失语音的 `actor_id` 决定了用哪个 voice_config —— 见 `data/actors/registry.json`。
2. 缺失列表按 `actor_id` 聚合后跑 `tools/generate_voices.py` 可批量生成。
3. 序章和事件类语音不区分 actor，按 `_prologue/` / `_events/` 旧目录约定生成。
4. 重新跑本脚本即可看到差量更新。
