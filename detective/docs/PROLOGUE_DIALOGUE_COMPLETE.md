# 序章「渡口沉舟」完整对话文档

> 版本：2026-06-02 | 数据来源：prologue_ferry/*.csv 全量整合
> 用途：游戏对话系统接入参考
> 格式：speaker {emotion} → 台词
> 标记：[narration] 旁白 | [inner_thought] 内心独白

---

# Phase 0 · 船舱夜话

## 陆昭船舱（搜索）

| 搜索点 | 描述 | 获得 |
|---|---|---|
| cabin_seal_box | 木匣压在床边，铜锁还扣着。里面是官印、敕牒和巡按令牌。你伸手按了按锁舌——完好。至少此刻，你的身份还稳稳放在这里。… | clue_cabin_seal_box |
| cabin_route_note | 桌上压着一页行程简记：平水驿、石矶渡、夜船、东汊、武昌。东汊二字被一点水痕洇开。你想起驿丞说过“这条水路快”——但他没提… | clue_cabin_route_note |
| cabin_storm_window | 窗外一道闪电照亮江面。船身随浪轻轻一偏，油灯火苗被风压得发蓝。这样的天气还要夜渡，急的不是路，是人。… | clue_cabin_storm_window |
| cabin_wet_cloak | 墙边斗篷下已经积了一小摊水。你上船时明明拧过水，如今却像又淋过一场雨。门缝里灌来冷风，带着淡淡的江腥味。… | clue_cabin_wet_cloak |

## 阿贵船舱

### 对话：ask_master

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | agui_cabin | 小的叫阿贵，跟了老爷十二年。老爷是做布匹生意的，这次是去武昌府进一批棉布。 | nervous |
| 2 | agui_cabin | 老爷对小的有知遇之恩。十六岁进的门，什么都不会——是老爷手把手教的。 | nervous |
| 3 | lu_zhao | 十二年了……不短。 | serious |

### 对话：ask_voyage

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | agui_cabin | 这次夜船是老爷安排的。说是急着赶路，要赶武昌的早市。 | nervous |
| 2 | agui_cabin | 小的不敢多嘴。老爷说什么就是什么。 | nervous |
| 3 | lu_zhao | 夜船危险，他不敢多嘴？ | serious |

### 对话：ask_feelings

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | agui_cabin | 老爷……老爷对小的严厉，但也是为小的好。 | nervous |
| 2 | agui_cabin | 十二年了……小的半条命都是老爷给的。 | crying |
| 3 | narrator | （他低下头，手指无意识地搓着衣角） | — |
| 4 | lu_zhao | 严厉……但也是为你好。 | serious |

### 对话：observe_cabin

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | narrator | 船舱不大，但收拾得还算干净。 | — |
| 2 | narrator | 舱壁上挂着一根铁撬棍，旁边是蓑衣和斗笠。 | — |
| 3 | narrator | 角落有几只木箱，用麻绳捆着。 | — |
| 4 | narrator | （铁撬棍的位置有点奇怪——挂在舱壁正中间，像是特意放在那里的。） | — |
| 5 | lu_zhao | 这铁撬棍放得倒显眼…… | serious |

## 老范船舱

### 对话：ask_route

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan_cabin | 走东汊那条。快是快，就是……有暗礁。 | evasive |
| 2 | lao_fan_cabin | 涨水的时候应该能过去。谁知道还露着。 | evasive |
| 3 | lu_zhao | 暗礁？你跑了二十年船，不知道有暗礁？ | cold |
| 4 | lao_fan_cabin | 知道……但客人催得急啊！ | evasive |

### 对话：ask_weather

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan_cabin | 这天气……说实话，不太好。但客人催得急。 | evasive |
| 2 | lao_fan_cabin | 老头子跑了二十年船，什么天气没经历过？ | evasive |
| 3 | narrator | （他转了转手里的旱烟杆，没点着） | — |

### 对话：ask_cabin

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan_cabin | 铁撬棍？那是……那是修船用的。有时候船板松了，得敲敲打打。 | evasive |
| 2 | lao_fan_cabin | 放在舱壁上，方便拿。 | evasive |
| 3 | lu_zhao | 修船用的……放了多久了？ | cold |
| 4 | lao_fan_cabin | ……记不清了。 | evasive |

### 对话：ask_money

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan_cabin | 嗐……跑船挣的是辛苦钱。 | evasive |
| 2 | lao_fan_cabin | 这两年行情不好，客人少，价钱也压得低。 | evasive |
| 3 | narrator | （他转了转手里的旱烟杆，没点着） | — |
| 4 | lu_zhao | 辛苦钱……但至少是安稳钱。 | serious |
| 5 | lao_fan_cabin | 安稳？嘿嘿……安稳。 | evasive |

### 对话：observe_cabin

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | narrator | 船舱不大，但收拾得还算干净。 | — |
| 2 | narrator | 舱壁上挂着一根铁撬棍，旁边是蓑衣和斗笠。 | — |
| 3 | narrator | 角落有几只木箱，用麻绳捆着。 | — |
| 4 | narrator | （铁撬棍的位置有点奇怪——挂在舱壁正中间，像是特意放在那里的。） | — |
| 5 | lu_zhao | 这铁撬棍放得倒显眼…… | serious |

## 周德贵船舱

### 对话：ask_business

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | zhou_de_gui_cabin | 不算大。就是混口饭吃。 | serious |
| 2 | zhou_de_gui_cabin | 这次是去武昌府进一批棉布，过了年好卖。 | serious |
| 3 | lu_zhao | 周老板谦虚了。 | serious |

### 对话：ask_night_ferry

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | zhou_de_gui_cabin | 急着赶路。武昌的早市不能错过。 | serious |
| 2 | zhou_de_gui_cabin | 夜船快。半天就到。 | serious |
| 3 | lu_zhao | 夜船危险。 | serious |
| 4 | zhou_de_gui_cabin | 我知道。但时间不等人。而且……有人告诉我这条路快。 | serious |
| 5 | narrator | （他顿了顿，像是在斟酌用词） | — |
| 6 | zhou_de_gui_cabin | 是个做药材的朋友。说这条船靠谱，船家跑了二十年。 | serious |
| 7 | lu_zhao | 做药材的朋友？ | serious |
| 8 | zhou_de_gui_cabin | 嗯。姓沈。以前在武昌做过药材生意。 | serious |

### 对话：ask_servant

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | zhou_de_gui_cabin | 阿贵跟了我十二年。 | serious |
| 2 | zhou_de_gui_cabin | 十六岁进的门。什么都不会——是我手把手教的。 | serious |
| 3 | zhou_de_gui_cabin | 十二年了……不短了。 | serious |
| 4 | lu_zhao | 十二年……确实不短。 | serious |

### 对话：observe_cabin

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | narrator | 船舱不大，但收拾得还算干净。 | — |
| 2 | narrator | 舱壁上挂着一根铁撬棍，旁边是蓑衣和斗笠。 | — |
| 3 | narrator | 角落有几只木箱，用麻绳捆着。 | — |
| 4 | narrator | （铁撬棍的位置有点奇怪——挂在舱壁正中间，像是特意放在那里的。） | — |
| 5 | lu_zhao | 这铁撬棍放得倒显眼…… | serious |

# 沉船事件（Phase 0→1）

[narration] 夜深了。你躺在船板上，听着雨声，渐渐入睡。

[narration] 黑暗中，身体猛烈一震。冰冷的水从脚底涌上来，船舱正在倾斜。

陆昭 {cold} → 船在沉。

[narration] 你咬牙蹲入刺骨的冰水中，双手摸索船底。一个方形洞口，边缘整齐——不是撞击，是凿出来的。

[narration] 你扯下舱壁上的铁撬棍，踩上漂起的木箱，撬开天窗。下一刻，船体发出巨响，彻底沉入黑水。

[narration] 「喂！喂！你还活着吗！」有人把你从江边湿冷的沙砾上拖起来。

凌瑶 {anxious} → 别死啊你！我好不容易把你拖上来的！咳出来！把水咳出来！

凌瑶 {determined} → 我叫凌瑶，金鳞镖局首席镖师。别的等进屋再说——你再淋下去非冻成冰棍不可！

[narration] 清晨，码头下游的浅滩发现了周德茂的尸体。人群围了上来，哭声、雨声和窃窃私语混成一片。

周氏 {grief} → 就是他！一个来路不明的外乡人，图财害命！

阿贵 {nervous} → 昨晚三更刚过，我看见这位爷蹲在船底舱口那边，手里好像攥着个铁家伙……

沈清月 {cooperative} → 周娘子莫急。人命案最怕情急乱判——但若有证人、有动机、有物证，也不能因他自称御史就轻放。

钱里正 {nervous} → 你说你是御史？有官印文书吗？

陆昭 {serious} → 官印落在船舱里。连同行李、文书，全沉在江底了。

沈清月 {sharp} → 没有官印，便只能先按眼前证据说话。陆公子，您若清白，就请当堂自证。

凌瑶 {determined} → 他被我拖上来的时候都快断气了！昏迷了大半个时辰才醒！

钱里正 {nervous} → 既然你说冤枉——那就当面对质！王大爷，你把那天夜里看到的，再说一遍！


# 王大爷对峙 (confrontation_wang)

### intro_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 钱里正 | （拍桌子）肃静！既然陆大人说冤枉——那就当面对质！ | nervous |
| 1 | 周氏 | 就是他！我家老爷死得冤，若不是他，还能是谁？！ | screaming |
| 2 | 沈清月 | 里正大人。周娘子悲痛失态，但证人既在，不妨让证词说话。若陆公子真无辜，也该经得住问。 | cooperative |
| 3 | 钱里正 | 王大爷，你只说你亲眼所见、亲耳所闻，不必替谁下结论。 | nervous |
| 4 | 王大爷 | （慢吞吞站起来，避开周氏的目光）行。老头子……只说看到的。 | evasive |
| 5 | 王大爷 | 那天夜里我在岸边收网。船翻之前，我看见陆公子和周老板在船头争执，影子清清楚楚。 | evasive |
| 6 | 王大爷 | 我还听见有人喊'银子'、'别走'。随后船身一晃，周老板就没了声。 | evasive |
| 7 | 王大爷 | 周老板带着五十两货银，陆公子又是唯一活下来的外乡人。老头子不敢乱说，可这事……太巧。 | evasive |
| 8 | 沈清月 | 陆公子，唯一生还者最有机会毁船灭口。你若只说自己冤枉，恐怕不能服众。 | sharp |
| 9 | 陆昭 | 那就从这份证词开始。一句一句拆。 | cold |
| 10 | 凌瑶 | （低声）他说得太满了。雾、风、动机——全有破绽。 | determined |

# Phase 2 · 深入追查探索对话

## NPC: 钱里正 (li_zheng)

### 对话：intro

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | li_zheng | 我跟你说实话——周氏闹成那样，我不给你时间查不好收场。但反过来讲…… | nervous |
| 2 | li_zheng | 这种事我见多了。冬天涨水，夜里走船——十年八年总得翻一回。老范跑了二十年没出过事，这次栽了，也不是不可能。 | — |
| 3 | lu_zhao | 意外……你倒是想大事化小。 | cold |
| 4 | li_zheng | 我给你两天，是给周氏一个交代。但你要是查来查去没真凭实据……我上报县衙只能写'翻船落水，意外溺亡'。懂我意思？ | sighing |
| 5 | xia_lingyao | 这老滑头——他巴不得你查不出来。'意外'归他自己结案，'命案'得惊动县衙。他在赌你拿不出证据。 | anxious |
| 6 | lu_zhao | 他的态度很明确——不帮忙，但也不拦着。除非我拿出东西来，否则他会把这事盖过去。 | serious |

### 对话：ask_reef

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | li_zheng | 那可不是！我从小在这儿长大，那片礁石连小孩儿都知道要绕着走。 | — |
| 2 | li_zheng | 涨水了也不保险——石头尖的很，水面下照样能把船底划烂。 | — |
| 3 | xia_lingyao | 那老范二十年老船家，他不知道？ | anxious |
| 4 | lu_zhao | 不可能不知道。 | cold |

### 对话：ask_recent_strangers

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | li_zheng | 异常嘛……嗯，这个不知道算不算—— | nervous |
| 2 | li_zheng | 半个月前吧。有个外地来的人在渡口打听事儿。穿得挺体面——长衫马褂，像个读书人。 | gossip |
| 3 | lu_zhao | 打听什么？ | surprised |
| 4 | li_zheng | 打听水路。问哪条航道夜里走、什么船什么时辰开。还问了——常走这条路的商客有哪些。 | — |
| 5 | lu_zhao | 他自称什么人？ | cold |
| 6 | li_zheng | 说是南京来的。做茶叶生意。名号嘛……我不太记得了。姓——好像姓顾？还是姓谷？反正文绉绉的。 | evasive |
| 7 | xia_lingyao | 南京来的人，半个月前就在打听水路和常客？这时间点也太巧了…… | anxious |
| 8 | lu_zhao | 他后来呢？还在渡口吗？ | cold |
| 9 | li_zheng | 待了两三天就走了。我也没多想——过路的商人来打听行情嘛，正常。 | evasive |
| 10 | lu_zhao | ……南京来的读书人。打听航道、时间、常客。半个月后——'南京来信'引诱周德茂走夜船。这两件事之间…… | serious |
| 11 | xia_lingyao | 大人……这事跟周氏说的那封信——会不会有关系？先记下来。 | determined |

### 对话：ask_fan

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | li_zheng | 老范嘛……人还行。就是爱赌。以前小赌怡情，这两年越赌越大。 | nervous |
| 2 | li_zheng | 听说欠了赌坊不少钱。前阵子还有人来找他要账，闹得挺凶。 | nervous |
| 3 | lu_zhao | 欠了赌坊不少钱……前阵子有人来要账？ | cold |
| 4 | lu_zhao | 欠了赌坊的钱……如果有人拿这个做文章呢？ | cold |
| 5 | li_zheng | 不过嘛——大事化小。他水性好，人也实在。年轻时候还救过落水的孩子，全渡口都知道。 | nervous |
| 6 | xia_lingyao | 欠了赌坊的钱……如果有人拿这个做文章呢？ | anxious |

### 对话：ask_agui_spending

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | li_zheng | 异常嘛……嗐，也不能说异常。就是—— | nervous |
| 2 | li_zheng | 他昨天在客栈买了壶好酒，又打了半斤卤肉。出手挺阔的。 | nervous |
| 3 | lu_zhao | 刚死了主人就买酒吃肉……出手阔绰。 | cold |
| 4 | li_zheng | 按说刚死了主人的仆从……哪有心情喝酒吃肉啊？而且他马上要被遣散了，身上能有几个钱？ | nervous |
| 5 | xia_lingyao | 刚死了主人就大吃大喝……要么是演戏，要么是心里有底。 | determined |

### 对话：ask_victim

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | li_zheng | 知道知道。做布匹生意的，来往走水路常歇在咱这儿。 | nervous |
| 2 | li_zheng | 人嘛……精明是精明的。就是待下人刻薄了些。动不动呵斥，我听过好几回了。 | nervous |
| 3 | lu_zhao | 待下人刻薄……阿贵跟了他十二年。 | serious |
| 4 | li_zheng | 不过嘛——人死了，大事化小，就别说那么多坏话了。 | nervous |
| 5 | lu_zhao | 待下人刻薄……阿贵跟了他十二年，受的恐怕不止这些。 | serious |

## NPC: 周氏 (zhou_wife)

### 对话：ask_agui

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | zhou_wife | 阿贵跟了老爷十二年了。以前什么都好——忠心、勤快。 | — |
| 2 | zhou_wife | 可这两年……老爷嫌他笨手笨脚，动不动就骂。上船前一天还当着外人面骂了他一顿。 | — |
| 3 | zhou_wife | 而且……老爷上船前跟我说过，到了武昌就把阿贵打发走。 | suspicious |
| 4 | lu_zhao | 上船前还被骂了一顿……当晚就哭天抹泪？ | cold |
| 5 | lu_zhao | 打发走？给多少遣散银？ | cold |
| 6 | lu_zhao | 打发走？给多少遣散银？ | serious |
| 7 | zhou_wife | 老爷写了字据……二两。 | silent |
| 8 | xia_lingyao | 二两？十二年就换二两？这也太寒碜了。 | shocked |
| 9 | lu_zhao | 寒心不等于杀人。但确实是动机。 | serious |

### 对话：ask_swimming

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | zhou_wife | 不会！完全不会！他连河边都不敢走太近。 | trembling |
| 2 | zhou_wife | 以前在家洗澡，水深过膝盖他就不下去。别人笑他，他也不改。 | — |
| 3 | lu_zhao | 连洗澡都怕水深……这样的人会主动坐夜船？ | cold |
| 4 | zhou_wife | 这也是他平时从不坐夜船的原因——白天能看到岸。 | — |
| 5 | xia_lingyao | 怕水的人深夜上船，不是被催的，就是被骗的。 | worried |
| 6 | lu_zhao | 这点可以和阿贵的说法互证。 | serious |

### 对话：ask_why_night_ferry

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 你丈夫平时不坐夜船。这次为什么突然改了主意？ | serious |
| 2 | zhou_wife | 说起来……他收到了一封信。出发前两天。 | suspicious |
| 3 | lu_zhao | 什么信？ | cold |
| 4 | zhou_wife | 南京那边来的。说是有个大买家急着要货。'到了南京棉布能翻一倍'——老爷看了就坐不住了。 | suspicious |
| 5 | lu_zhao | 那封信现在在哪？ | serious |
| 6 | zhou_wife | 老爷带在身上了。应该……随船沉了。 | — |
| 7 | zhou_wife | 说起来——那封信的写法有点奇怪。 | suspicious |
| 8 | lu_zhao | 哪里奇怪？ | serious |
| 9 | zhou_wife | 字写得很工整——老爷平时来往的商人没几个字好看的。而且……没有署名。只说'故友知会'。老爷的故友里没有字写得那么好的。 | suspicious |
| 10 | xia_lingyao | 匿名信把他引到夜船上……嘶——如果那封信本身就是诱饵呢？ | anxious |
| 11 | lu_zhao | ……工整的字迹。匿名。精准地知道他做布匹生意、精准地用'翻倍利润'引诱他赶路。这不像是巧合——像是有人特意把他引到这条船上。 | serious |

### 对话：react_murder_confirmed

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 周氏。我不想对你隐瞒——你丈夫的船底有一个人为凿出的洞。 | serious |
| 2 | lu_zhao | 这不是意外。是谋杀。 | cold |
| 3 | zhou_wife | 全身僵住。手里的帕子掉在地上，她没去捡。 | grief |
| 4 | lu_zhao | 是谋杀。我不会骗你。 | serious |
| 5 | zhou_wife | ……我就知道。我就知道不是意外。老爷他————他是被人害的。 | screaming |
| 6 | zhou_wife | 恩公。求您一定要抓住凶手。不管是谁——不管是谁！ | grief |
| 7 | xia_lingyao | ……她哭了。这种哭法不是假的。陆大人，她是真的不知道。 | worried |
| 8 | lu_zhao | 我一定查清楚。——不管你信不信我是谁，凶手我会找到。 | serious |

### 对话：react_agui_confessed

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 周氏。阿贵已经认了。是他凿的船。 | cold |
| 2 | zhou_wife | 阿贵……他怎么……他跟了老爷十二年…… | shocked |
| 3 | zhou_wife | 十二年啊。吃一口锅里的饭、睡一个屋檐下——他怎么下得去手？ | shocked |
| 4 | lu_zhao | 你丈夫用二两银子遣散了他。十二年。 | serious |
| 5 | zhou_wife | ……二两。是少了。但、但也不至于杀人啊…… | screaming |
| 6 | lu_zhao | 他背后还有人。有人教他怎么做的——利用了他的怨恨。 | cold |
| 7 | zhou_wife | 还有人？！谁？！ | grief |
| 8 | lu_zhao | 还在查。时间不多了——但会有结果。 | serious |
| 9 | xia_lingyao | 她的表情……又是恨又是不敢信。十二年的旧仆——她可能把阿贵当半个家人的。 | worried |

### 对话：intro

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | zhou_wife | 里正说让你查。我拦不住。 | trembling |
| 2 | zhou_wife | 问吧。但你最好是来找真凶的——不是来替自己脱罪的。 | trembling |
| 3 | lu_zhao | 我会查清楚。不管你信不信我是谁。 | serious |

### 对话：ask_suspicion

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | zhou_wife | 阿贵不对劲。案发后他哭得比我都凶——可他跟老爷关系好吗？不好。 | suspicious |
| 2 | zhou_wife | 上船前还被骂了一通，当晚就哭天抹泪？我不信。 | suspicious |
| 3 | lu_zhao | 被骂了一通，当晚就哭天抹泪……确实反常。 | cold |
| 4 | zhou_wife | 还有——老爷是旱鸭子。连洗澡都怕水深。让他坐夜船，一定是阿贵催的。 | suspicious |
| 5 | xia_lingyao | 她说的有道理。一个被骂了一顿的仆从，当晚哭得比主人的妻子还凶——确实反常。 | determined |

### 对话：comfort

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 节哀。我一定查清楚。 | serious |
| 2 | zhou_wife | ……你不像凶手。凶手不会还留在这里问话。 | grief |
| 3 | zhou_wife | 里正让你查——你要是真能查出来……老爷的文书都在房间桌上。你看吧。 | grief |

### 对话：ask_documents

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | zhou_wife | 都在房间里。先生自己去看吧——遣散字据、货单都在桌上。 | suspicious |
| 2 | lu_zhao | 都在房间里……多谢。 | serious |
| 3 | lu_zhao | 多谢。 | serious |

## NPC: 阿贵 (agui)

### 对话：intro

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | agui | 那天晚上……老爷急着过江，老范说夜里也能走。小的只是跟着上了船，哪敢多嘴。 | grief |
| 2 | agui | 到了江心，突然船就晃得厉害——然后水就涌进来了！什么都看不见！小的拼命去拉老爷的手，没拉住…… | grief |
| 3 | xia_lingyao | 他没有急着咬谁，只把自己说成了一个慌乱救主的人。 | worried |
| 4 | agui | 小的不知道是谁害了老爷……小的只知道，自己没把老爷救回来。 | grief |
| 5 | xia_lingyao | 他没有急着咬谁，只把自己说成了一个慌乱救主的人。听起来可怜，但也太干净了。 | worried |
| 6 | lu_zhao | 先听着。看他后面怎么说。 | serious |

### 对话：ask_relationship

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | agui | 老爷对小的有知遇之恩。十六岁进的门，什么都不会——是老爷手把手教的。 | grief |
| 2 | agui | 十二年了……小的半条命都是老爷给的。现在老爷没了……小的不知道该怎么办。 | grief |

### 对话：press_alibi

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | agui | 小的不会水……当时什么都看不见，只觉得冷。手里好像抓到了一块板子——死死抱住不敢放。 | grief |
| 2 | agui | 后来就什么都不知道了。醒过来已经在岸上。命大吧……可老爷就没这么幸运了…… | grief |
| 3 | xia_lingyao | 冬天的江水，不会游泳的人抱块板子就能活？说得倒轻巧。 | worried |
| 4 | lu_zhao | 先记下。他的说法站不稳。 | serious |

### 对话：show_dismissal

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | agui | 公、公子——遣散？那是……那是老爷另有安排。老爷说让小的回乡置点田产，过自在日子。 | nervous |
| 2 | agui | 老爷是为小的好。十二年了……也该放小的走了。 | shaken |
| 3 | lu_zhao | 另有安排？什么样的安排？ | cold |
| 4 | agui | 小的没有怨恨。真的。 | defensive |
| 5 | lu_zhao | 十二年了，就换来一句放你走？ | cold |
| 6 | xia_lingyao | 嘴上说没有，拳头都攥白了。记下来——演技不错，但细节骗不了人。 | determined |

### 对话：show_bladder

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | agui | 包袱？当、当然都是小的的……衣服被褥什么的…… | nervous |
| 2 | agui | 公……您、您为什么突然问这个…… | panic |
| 3 | xia_lingyao | 心虚了。他包袱里肯定有鬼，回头正式审的时候再拿出来——打他个措手不及。 | determined |

### 对话：confession

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 阿贵。我不想再绕弯子了。 | cold |
| 2 | lu_zhao | 浮囊、船底的洞、你那身衣服——所有证据都指向你。 | cold |
| 3 | agui | 公子！小的——小的是冤枉的！ | panic |
| 4 | lu_zhao | 那好。一条一条过。你说的每一句话——我都有东西反驳。 | serious |

### 对话：ask_twelve_years

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | agui | 十二年？……公子怎么突然问这个？ | — |
| 2 | lu_zhao | 随便聊聊。十二年不短了。 | serious |
| 3 | agui | ……不短。 | nervous |
| 4 | agui | 小的十六岁进周家。什么都不会。老爷说'跟着学三年就放你出师'。 | crying |
| 5 | lu_zhao | 三年五年八年……出师的事再没提过。 | serious |
| 6 | agui | 三年……五年……八年。出师的事再没提过。 | — |
| 7 | agui | 中间想走过。跟老爷说想回乡。他说'走可以，把这些年吃穿的钱还了再走'。小的哪还得起？只好继续待着。 | nervous |
| 8 | xia_lingyao | ……这不是卖身契？ | shocked |
| 9 | agui | 大约……算是吧。但小的没地方去。爹娘早没了。只有这一个主人。 | grief |
| 10 | agui | 前几年还好。老爷生意好的时候心情也好，偶尔给几十文赏钱。后来生意差了——骂的就多了。打也打过。 | nervous |
| 11 | xia_lingyao | 骂的就多了。打也打过……十二年。 | worried |
| 12 | agui | 小的有个相好的——隔壁村的姑娘。存了两年钱想下聘。结果钱被老爷'借走'——说是补生意上的窟窿。 | grief |
| 13 | agui | 那姑娘等了一年……后来嫁别人了。 | grief |
| 14 | lu_zhao | …… | serious |
| 15 | xia_lingyao | …… | worried |
| 16 | agui | 公子，小的不是好人。但小的……这十二年过的也不是人过的日子。 | grief |

## NPC: 老范 (lao_fan)

### 对话：intro

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan | 唉，天灾呗。那夜雨大浪急，我跑了二十年船没见过那阵仗。 | smirk |
| 2 | lao_fan | 到了礁石那段，一个浪头打过来——'咔嚓'一声船底就裂了。 | smirk |
| 3 | lu_zhao | 天灾……你说得倒轻巧。 | cold |
| 4 | lu_zhao | 你说你水性好……好到能在冰水里泡半个时辰？ | cold |
| 5 | lao_fan | 我水性好，自己扒着船板上了岸。那主仆两个……唉，没能救上来。 | smirk |
| 6 | xia_lingyao | 他说得倒顺。翻船死了人，他一点都不慌。 | worried |
| 7 | lu_zhao | 水性好的人能自救，不奇怪。奇怪的是他说得太稳。 | serious |

### 对话：press_route

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan | 你这话说的……涨水嘛，水面高了礁石就该没了。我判断失误，这、这能怪我？ | defensive |
| 2 | xia_lingyao | 怪不怪你，船底那个洞会告诉我们。 | determined |
| 3 | lu_zhao | 先看证据。 | serious |

### 对话：ask_rescue

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan | 我水性好嘛。泡了……泡了有半个时辰。后来有船经过，把我捞上来的。 | smirk |
| 2 | xia_lingyao | 半个时辰？冬天的江水里泡半个时辰还能活？ | shocked |
| 3 | lao_fan | 我身体硬朗嘛。年轻时候在江里泡一两个时辰都试过。 | defensive |
| 4 | lu_zhao | 半个时辰……你确定不是一刻钟？ | cold |
| 5 | lu_zhao | 半个时辰。跟王老汉说的'不到一刻钟'——对不上。先记下。 | serious |

### 对话：show_hull

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan | 修……修过？哪条船不修呢，跑久了总要补补的嘛。 | nervous |
| 2 | lao_fan | 不过翻船之前没动过！那是礁石撞的！ | defensive |
| 3 | xia_lingyao | 他急了。一问船底就急——心里有鬼。 | determined |
| 4 | lu_zhao | 你说翻船之前没动过……那你船上那套工具是干什么用的？ | cold |
| 5 | lu_zhao | 好。先记下。 | serious |

### 对话：show_iou

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan | 手头紧？谁、谁跟你说的？我日子过得好好的！ | defensive |
| 2 | lao_fan | 跑船嘛，有时多赚有时少赚……不至于！ | nervous |
| 3 | xia_lingyao | 瞧他那样，跟踩了尾巴似的。赌债的事八成是真的。 | determined |
| 4 | lu_zhao | 不急。之后再说。 | serious |

### 对话：ask_gambling_story

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan | ……你问这个干嘛。跟案子有关系？ | — |
| 2 | lu_zhao | 随便聊聊。二十年的老船家，怎么沾上的赌？ | serious |
| 3 | lao_fan | ……嗐。说来话长。 | dismissive |
| 4 | lao_fan | 五年前。我家小子——刚十二岁。一场急病。大夫说得用好药，开的方子贵得吓人。 | nervous |
| 5 | lao_fan | 我攒了一辈子的钱不够。找人借——没人借。最后有人说'赌坊有快钱'…… | nervous |
| 6 | lu_zhao | 赌坊有快钱……是谁跟你说的？ | cold |
| 7 | xia_lingyao | ……孩子后来怎样了？ | worried |
| 8 | xia_lingyao | 没了。药没凑齐…… | worried |
| 9 | lao_fan | 没了。药没凑齐。 | cornered |
| 10 | lao_fan | 赌坊的钱没赚到——倒欠了一屁股。之后就……越赌越深。想翻本。翻不了。 | nervous |
| 11 | lu_zhao | 越赌越深。想翻本。翻不了。 | serious |
| 12 | lao_fan | 公子。我不是好人。但我也不是天生的赌鬼。 | cornered |
| 13 | lu_zhao | ……为了孩子的药钱进了赌坊。和沈清月为父亲筹药钱——何其相似。 | serious |

### 对话：press_shen_connection

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 老范。阿贵已经招了。你也可以说实话了。 | cold |
| 2 | lu_zhao | 那个找你'商量发财路子'的人——是个做药材生意的姑娘。对不对？ | cold |
| 3 | lao_fan | 烟杆从嘴边落了下来。整个人僵住。 | cornered |
| 4 | lao_fan | ……公子都知道了？ | cornered |
| 5 | lu_zhao | 说。她怎么找的你。 | cold |
| 6 | lu_zhao | 她怎么找的你。 | cold |
| 7 | lao_fan | ……是她先来的。说知道我欠赌坊的钱。说……有门生意，做完了赌债一笔勾销。 | cornered |
| 8 | lao_fan | 我问什么生意。她说——把船弄沉就行。其他的不用管。 | cornered |
| 9 | lao_fan | 我……我当时被逼急了。年底不还钱赌坊说要断指…… | cornered |
| 10 | xia_lingyao | 他招了。老范也是被她拉下水的——跟阿贵一样。 | shocked |
| 11 | lu_zhao | 那个姑娘——长什么样？ | cold |
| 12 | lao_fan | 高个子。穿劲装。说话利索——像是做过生意的人。 | cornered |
| 13 | lu_zhao | ……沈清月。 | serious |

### 对话：ask_route

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lao_fan | 那客人催得急啊！说要赶武昌的早市。走大路绕远，走那条—— | evasive |
| 2 | lao_fan | 嗐，我也知道有礁石。但水涨了以后，以前那礁石应该没过去了嘛。谁知道还露着。 | defensive |
| 3 | lu_zhao | 二十年的老船家，会不知道涨水后礁石还在？ | cold |
| 4 | xia_lingyao | 他在赌——赌你不会细查。 | determined |

## NPC: 王大爷 (fisherman_wang)

### 对话：intro

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | fisherman_wang | 那天夜里，老头子在江上收夜网。 | — |
| 2 | fisherman_wang | 先是听到一声巨响——木头裂开的声音。然后是人喊。 | — |
| 3 | xia_lingyao | 木头裂开的声音……那不是普通的风浪。 | anxious |
| 4 | fisherman_wang | 老头子划过去的时候，船已经翻了。看到一个人趴在水里。另一个——自己扒着船板游上了岸。利索得很。 | evasive |
| 5 | xia_lingyao | 自己游上岸？那就是老范了。他说自己泡了半个时辰才被人救上来—— | shocked |
| 6 | xia_lingyao | 自己游上岸？利索得很？那跟落水求救的样子可对不上啊—— | anxious |
| 7 | fisherman_wang | 放屁。不到一刻钟他就上岸了。老头子看得清清楚楚。 | evasive |

### 对话：ask_channel

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | fisherman_wang | 走的东汊那条。 | evasive |
| 2 | fisherman_wang | 在这一带跑船的人都知道——东汊有暗礁。涨水没涨水都不能走。 | evasive |
| 3 | lu_zhao | 东汊那片有暗礁的水道。本地人都知道危险。 | cold |
| 4 | fisherman_wang | 老范在这儿跑了二十年。他不知道？他比谁都知道！ | angry |
| 5 | xia_lingyao | 故意走危险航道……除非他有把握自己能活下来。 | anxious |
| 6 | fisherman_wang | 除非——他就是故意走那条路。 | evasive |
| 7 | lu_zhao | 故意走危险航道……除非他有把握自己能活下来。 | serious |
| 8 | xia_lingyao | 二十年老船家走暗礁航道——这不是失误，是故意的。 | anxious |

### 对话：ask_meeting

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | fisherman_wang | 前一晚……对，老头子那天也收了夜网。 | evasive |
| 2 | fisherman_wang | 路过码头的时候，看到两个人蹲在角落里说话。黑灯瞎火的，鬼鬼祟祟。 | evasive |
| 3 | lu_zhao | 鬼鬼祟祟……他们说了什么？ | cold |
| 4 | fisherman_wang | 一高一矮。高的像是那仆从——腰板直。矮的精瘦精瘦的——像船家。 | evasive |
| 5 | lu_zhao | 一高一矮……你确定高的像阿贵？ | cold |
| 6 | fisherman_wang | 老头子当时没在意。第二天出了事才想起来。 | evasive |
| 7 | xia_lingyao | 案发前一晚两人鬼祟说话……这时间点也太巧了。 | anxious |

### 对话：trust

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | fisherman_wang | 老头子活了一辈子，在这江上。 | evasive |
| 2 | fisherman_wang | 见过太多死在水里的人。有些是命，有些不是。 | evasive |
| 3 | lu_zhao | 有些是命，有些不是……你看到了什么？ | serious |
| 4 | fisherman_wang | 那天夜里那人在水里扑腾的声音……老头子一辈子忘不了。 | evasive |
| 5 | lu_zhao | 有人让你别多管闲事？谁？ | cold |
| 6 | fisherman_wang | 有人跟我说别多管闲事。放屁。杀了人就该偿命。老头子不怕得罪人。 | angry |
| 7 | lu_zhao | ……谢谢你。 | serious |

### 对话：ask_dawn_sighting

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | fisherman_wang | 天还没亮的时候，老头子在下游浅滩看见一个人拿长竿探水。 | evasive |
| 2 | fisherman_wang | 那人穿深色衣裳，身量高挑，不像老范，也不像阿贵。 | evasive |
| 3 | lu_zhao | 深色衣裳，身量高挑……你看清是男是女了吗？ | cold |
| 4 | fisherman_wang | 我当时离得远，不敢说死。但天一亮，那人就不见了。 | evasive |
| 5 | xia_lingyao | 深色衣裳、身量高挑……如果不是老范和阿贵，那还有谁？ | anxious |

### 对话：ask_river_life

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | fisherman_wang | 老头子在这江上打了一辈子鱼。 | evasive |
| 2 | fisherman_wang | 哪条汊水有暗礁，哪片浅滩能藏东西，心里都有数。 | evasive |
| 3 | lu_zhao | 哪片浅滩能藏东西……你对这片江了如指掌。 | serious |
| 4 | fisherman_wang | 所以我才说——老范那样的老船家，绝不可能糊里糊涂把船往东汊暗礁上带。 | angry |
| 5 | lu_zhao | 本地人的判断——比任何证据都准。 | serious |

## NPC: 沈清月 (shen_qingyue)

### 对话：intro

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | shen_qingyue | 关系？欠债的和讨债的——就这么简单。 | bold |
| 2 | shen_qingyue | 他欠我沈家三十八两药材款。白纸黑字的借据。三个月了——催了七八回，一两没还。 | bold |
| 3 | shen_qingyue | 现在他死了。三十八两——打水漂了。'大人'——哦对了，您的官印好像丢了？那就叫你'公子'吧。公子，您说我是不是天底下最倒霉的债主？ | bold |
| 4 | lu_zhao | 三十八两。三个月。催了七八回。 | cold |
| 5 | xia_lingyao | 嘶——她说得倒坦然。欠她钱的人死了，她反而亏了……确实没有杀人理由？ | worried |
| 6 | xia_lingyao | 她说得倒坦然。欠她钱的人死了，她反而亏了。 | worried |
| 7 | lu_zhao | ……先记下。'没有理由'——这话说得太顺了。 | serious |
| 8 | lu_zhao | 借据留着……杀了他这张纸就是废纸。 | serious |
| 9 | shen_qingyue | 大人不信？这是借据。您看看日期——三个月前。看看签字——周德茂亲笔。 | cooperative |
| 10 | shen_qingyue | 我要是想杀他，何必留着借据？杀了他这张纸就是废纸。 | cooperative |

### 对话：ask_quarrel

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | shen_qingyue | 对。我骂了他。当着码头二十多号人的面。 | bold |
| 2 | shen_qingyue | '不还钱就别想走'——我原话。大人觉得有问题？ | bold |
| 3 | lu_zhao | 这话听上去像威胁。 | cold |
| 4 | shen_qingyue | '别想走'是说我会堵路讨债——不是说我会杀他。 | sharp |
| 5 | lu_zhao | 做生意的人不会杀欠债的——逻辑通。但前提是真的只想讨债。 | cold |
| 6 | shen_qingyue | 大人，我做生意的人。杀了欠债的——谁还我钱？我虎，但没虎到那份上。 | bold |
| 7 | xia_lingyao | 嘶……说的也是。她要钱不要命——这逻辑通啊。但总觉得她太自在了。像是——早就想好怎么答了。 | anxious |
| 8 | shen_qingyue | 而且——我跟他吵完了，他答应到武昌就还。我就在渡口等着呢。等他回来。 | cooperative |
| 9 | lu_zhao | 等他回来……她一直在渡口等着。 | serious |
| 10 | shen_qingyue | 谁知道等来的是一具尸体。行吧。就我这运气。 | bold |

### 对话：ask_alibi

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | shen_qingyue | 那天晚上？在码头看着他上船。确认他没跑——然后回客栈睡觉了。 | cooperative |
| 2 | lu_zhao | 几时回的？有人看到你吗？ | cold |
| 3 | shen_qingyue | 亥时前？客栈掌柜应该看到了——我跟他要了壶热水。 | cooperative |
| 4 | xia_lingyao | 亥时前……那时候船刚走没多久。如果是真的——她确实没时间做什么手脚。 | worried |
| 5 | xia_lingyao | 不过'看着他上船'——她对他的行踪掌握得也太清楚了吧？ | anxious |
| 6 | lu_zhao | '亥时前回客栈'。记下了。待会跟其他人的证词比对。 | serious |

### 对话：ask_fan_connection

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | shen_qingyue | 老范？那个船家？ | cooperative |
| 2 | shen_qingyue | 见过几面吧。码头这么大的地方——低头不见抬头见。但不熟。 | deflecting |
| 3 | lu_zhao | 只是'见过面'？ | cold |
| 4 | shen_qingyue | 大人这话什么意思？我一个做药材的姑娘，跟一个跑船的老头能有什么关系？ | sharp |
| 5 | xia_lingyao | 她眯眼了——刚才问别的问题时她可不这样。碰到老范的事就变了。 | determined |
| 6 | shen_qingyue | 他欠赌债的事我倒是听说了。码头人嘴杂嘛——谁不知道？但那跟我有什么关系？ | deflecting |
| 7 | lu_zhao | 她主动提到了赌债——但我没问这个。 | serious |

### 对话：ask_father

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | shen_qingyue | 一瞬间——她的表情僵住了。手指微微蜷缩。 | cracking |
| 2 | shen_qingyue | ……你查到我爹了？ | cold_smile |
| 3 | lu_zhao | 八十两的药。你家里只有四十二两。差额——你打算怎么补？ | cold |
| 4 | shen_qingyue | ……跑别的帐呗。沈家在浔阳还有其他欠账的。 | cold_smile |
| 5 | shen_qingyue | 大人想说什么？周德茂欠我三十八两——加上别的帐，凑够了不就行了？ | sharp |
| 6 | xia_lingyao | 嘶——她紧张了。一提到她爹，整个人都不一样了。 | determined |
| 7 | xia_lingyao | 等等——四十二两差额。周德茂带了五十两货银上船。如果那五十两没真的沉江…… | shocked |
| 8 | lu_zhao | 三十八两旧债 + 五十两货银 = 八十八两。刚好够药钱。 | serious |
| 9 | shen_qingyue | 大人。你想多了。那五十两沉在江底呢——跟我有什么关系？ | deflecting |

### 对话：press_dock_timing

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 你说亥时前就回了客栈。但有人看到——船开走之后一刻钟，你还在码头。 | cold |
| 2 | shen_qingyue | ……一刻钟？谁说的？夜里那么黑——看错了吧。 | deflecting |
| 3 | lu_zhao | 看错了？那个人描述得很清楚——穿男装的高挑女子。这里只有你一个符合。 | cold |
| 4 | shen_qingyue | ……好吧。也许我多站了一会儿。看看江面。吹吹风。犯法吗？ | sharp |
| 5 | xia_lingyao | '多站了一会儿'？刚才她可是说'看他上船就走了'。时间对不上了。 | determined |
| 6 | lu_zhao | 你之前说的是'上船就回'。现在又说'多站了一会儿'。哪个是真的？ | cold |
| 7 | shen_qingyue | ……好。是我多站了一会儿。看着船走远了才回来的。——满意了？ | cracking |
| 8 | xia_lingyao | 她在修正说法——一小步一小步地退。就跟阿贵被逼的时候一样。 | anxious |

### 对话：press_salvage

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 沈姑娘。案发当夜天亮前——下游浅滩有人打捞东西。 | cold |
| 2 | shen_qingyue | ……所以？跟我有什么关系？ | sharp |
| 3 | lu_zhao | 打捞的人——身量高挑，穿深色衣裳。像个女子。 | cold |
| 4 | shen_qingyue | 大人。穿深色衣裳身量高的人多了去了。 | deflecting |
| 5 | lu_zhao | 你说你亥时前就回客栈了。天亮前在下游——这怎么解释？ | cold |
| 6 | shen_qingyue | 那不是我。我那时候在睡觉。 | cold_smile |
| 7 | xia_lingyao | 她说'不是我'——可你注意到没有，她的手？刚才一直松着的手指，现在死死扣着。 | determined |
| 8 | xia_lingyao | 而且——下游浅滩。沉船的位置正好在上游。东西顺水漂下来——刚好到那。她怎么知道去那里捞？除非她算过。 | shocked |
| 9 | lu_zhao | 记下了。打捞目击 + 时间矛盾 + 五十两货银。线快连上了。 | serious |

### 对话：press_connection

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 沈姑娘。老范说了——最初找他商量这事的，是一个'药材行的姑娘'。 | cold |
| 2 | shen_qingyue | 一瞬间面部完全静止——像被冰冻了。然后她笑了。 | cold_fury |
| 3 | shen_qingyue | 他这样说了？……有意思。一个赌鬼的话，大人也信？ | cold_fury |
| 4 | lu_zhao | 不只老范。阿贵也说——'有人教我'。那个人教了他怎么凿船。一个仆从自己想不出这种计划。 | cold |
| 5 | lu_zhao | 不只老范。阿贵也说——有人教他。 | cold |
| 6 | shen_qingyue | …… | cracking |
| 7 | shen_qingyue | 沉默了整整五息。然后她慢慢地——把一直抱着的双臂放了下来。 | cracking |
| 8 | shen_qingyue | 大人。你是来定我罪的——还是来问话的？ | cold_fury |
| 9 | xia_lingyao | 她变了。刚才那个'飒爽女商人'不见了——这个才是真的她。冷得……像另一个人。 | anxious |
| 10 | lu_zhao | 阿贵的供述 + 老范的供述 + 打捞目击 + 时间矛盾。——够了。 | serious |

### 对话：confession_trigger

| # | speaker | text | emotion |
|---|---|---|---|
| 1 | lu_zhao | 沈清月。 | cold |
| 2 | lu_zhao | 阿贵说有人教他凿船。老范说是'药材行的姑娘'找的他。你案发当夜没有回客栈。下游有人在打捞货银。 | cold |
| 3 | lu_zhao | 阿贵说有人教他凿船。老范说是药材行的姑娘找的他。 | cold |
| 4 | lu_zhao | 三条线——全部指向你。 | cold |
| 5 | shen_qingyue | 久久凝视着你。然后她——笑了。不是之前的飒，是一种极冷的、赞赏的笑。 | cold_fury |
| 6 | shen_qingyue | ……你比我想象的快。 | cold_fury |
| 7 | shen_qingyue | 好。那就坐下来谈。——不过大人，'指向'不等于'证明'。你想定我的罪——就拿真东西来。 | cold_fury |
| 8 | xia_lingyao | 嘶——她认了？不……她没认。她是在说'你证据不够'。这比阿贵难对付多了…… | anxious |
| 9 | xia_lingyao | 陆大人——她不会像阿贵那样哭着认罪的。这次你得一步一步把她的逻辑拆碎。准备好了吗？ | determined |

# 阿贵对峙 (confrontation)

### intro_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 |  | 客栈大堂。外面的雨还没有要停的意思。

钱里正把相关的人都叫了来——不情不愿的，但拗不过你拿出的证据。 | narration |
| 1 |  | 大堂里围坐了一圈人。阿贵缩在角落低着头。老范坐在门口，旱烟杆攥得发白。周氏红着眼，坐在灵位旁边。

王大爷靠在柱子边，一副事不关己的样子。 | narration |
| 10 | 周氏 | （红着眼，手里攥着帕子。帕子已经被攥得皱巴巴的——像她这些天的脸。） | grief |
| 11 | 王大爷 | （靠在柱子上，双手抱胸。眼睛半睁半闭——像是在打盹，又像是在等什么。） | evasive |
| 12 | 凌瑶 | （低声）都到齐了。陆大人——开始吧。 | determined |
| 13 |  | （你扫视了一圈。六个人，六种心思。有人在装可怜，有人在装傻，有人在等真相。

而你——要把这层窗户纸捅破。） | inner_thought |
| 14 | 陆昭 | （深吸一口气）好。——那就从头说起。 | cold |
| 2 | 钱里正 | （清了清嗓子）好了——都安静！

今天叫大家来，是因为陆……陆大人说，那条船不是意外翻的。 | nervous |
| 3 |  | 人群一阵骚动。阿贵低下头去，肩膀缩得更紧了。 | narration |
| 4 | 钱里正 | （看向你）大人……你说有证据。那——就当着大家的面说清楚吧。 | stern |
| 4a | 阿贵 | （猛地站起来，指着陆昭）大人！不要听他的！是他杀了老爷！那天夜里我亲眼看见他蹲在船舱里——手里攥着个铁家伙！他才是凶手！ | angry |
| 4b | 陆昭 | ……你的指控，一会儿我会逐一回应。现在——先请证人说话。 | cold |
| 4c | 沈清月 | 里正大人，我受周娘子所托在此旁听。陆公子若要把船家和仆从都拖成共犯，证据链必须比他的推测更硬。 | cooperative |
| 4d | 沈清月 | 浮囊也好、航道也好，都可能只是船上常备用具与行船失误。若只凭“可能”，那人人都能成凶手。 | sharp |
| 5 | 陆昭 | 好。那就让证词和证据说话。——王大爷。 | cold |
| 6 | 凌瑶 | （低声）先让王大爷把那天夜里看到的东西说出来。有了他的证言打底，后面才好发难。 | anxious |
| 7 |  | 外面的雨越下越大。雨水顺着屋檐滴落，在地上汇成小溪。

大堂里弥漫着潮湿的霉味和香烛的烟气。 | narration |
| 8 | 阿贵 | （缩在角落，双手绞在一起，指节发白。嘴里喃喃着什么——听不清。） | nervous |
| 9 | 老范 | （坐在门口，旱烟杆在手里转了一圈又一圈。烟锅早灭了，他没注意。） | evasive |

### victory_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 阿贵 | ………… | broken |
| 1 | 阿贵 | （瘫坐在地，双手抱头） | broken |
| 10 | 凌瑶 | 不是你？那是谁教你的？！ | shocked |
| 11 | 阿贵 | （抬头，眼中有恐惧）有人来找我……那个人说——'你被克扣了十二年。你不恨他吗？' | shaken |
| 12 | 阿贵 | 那个人什么都知道。知道遣散字据的事。知道我被赶走的事。连我心里想什么——她都知道。 | shaken |
| 13 | 陆昭 | ……她？ | cold |
| 14 | 凌瑶 | ！等等——'她'？是个女人？！ | shocked |
| 15 | 阿贵 | （猛然闭嘴，像是意识到说错了话）……不、不是…… | panic |
| 16 | 陆昭 | 阿贵。你已经认罪了。现在说出她是谁——不会让你的处境更差。但隐瞒——会。 | cold |
| 17 | 阿贵 | （身体在发抖）是……是那个……药材行的姑娘。沈……沈姑娘。 | broken |
| 18 | 凌瑶 | 药材行——！那个追债的沈清月？！ | shocked |
| 19 | 阿贵 | 她找的我。也是她去找的老范。连浮囊都是她帮我买的——她说'你不会水，这个保命用'。 | broken |
| 2 | 凌瑶 | ……他不说话了。 | worried |
| 20 |  | （浮囊上那种过细的密封缝——不像船工手艺。那条线索，一直在手里。） | inner_thought |
| 21 | 凌瑶 | 等等……那只浮囊。咱们之前以为是阿贵自己的退路。可如果是她买的——意思完全变了。 | shocked |
| 22 | 阿贵 | 怎么凿船。凿哪里。什么时候动手——全是她教的。她连货银会漂到哪里都算好了…… | broken |
| 23 | 阿贵 | 小的只是……只是恨。恨了十二年。她给了我一个机会——我……我没忍住。 | broken |
| 24 | 凌瑶 | （低声）……所以她才是真正的主谋。利用阿贵的恨、利用老范的债——一个人导演了整出戏。 | worried |
| 25 | 陆昭 | 阿贵。你做了你该做的。 | cold |
| 26 | 凌瑶 | （转身朝门外喊）钱里正！钱里正你进来——！他招了！ | determined |
| 27 |  | 钱里正带着两个渡口帮工跑进来。看了看瘫在地上的阿贵，又看了看你——脸上的表情很复杂。 | narration |
| 28 | 钱里正 | 他……认了？ | shocked |
| 29 | 陆昭 | 认了。船底是他凿的。但他背后还有人——这案子没完。把他看住，别让他跑了。 | cold |
| 3 | 陆昭 | 阿贵。不成立的钝器指控、提前准备好的浮囊、船底的钉痕、十二年二两银子的遣散字据——四段证词，四重铁证。你还有什么话说？ | cold |
| 30 |  | 钱里正没有马上回答。他低下头，搓了搓手，又抬起头看了看阿贵——又看了看周氏灵位的方向。

沉默了很久。 | narration |
| 31 | 钱里正 | （声音很轻）……两天前，是我把你当犯人的。 | nervous |
| 32 |  | 他又沉默了一会儿。然后——像是要把什么很重的东西从嗓子里咽下去——他抬起头，看着你的眼睛。 | narration |
| 33 | 钱里正 | 陆……大人。是我眼拙了。 | nervous |
| 34 | 钱里正 | 先前周氏那一闹、阿贵那一通指证——铁器打人也好、天窗逃生也好——当时我觉得铁证如山。可你查过尸体——死人身上没伤，那套说法就不成立。是我没细想。 | nervous |
| 35 | 钱里正 | 阿贵先关柴房。您要查谁——我全力配合。两天的事……不提了不提了。 | nervous |
| 36 |  | 门口两个帮工互相看了一眼。其中一个小声说了句'……还真是御史啊'。另一个已经在弯腰行礼了。 | narration |
| 37 | 凌瑶 | （小声，语气带着几分得意）嘿——看到没？刚才还叫你'那个查案的'。现在改口了。 | cheerful |
| 38 |  | （……'两天期限'没了。嫌犯的帽子也摘了。从现在起——我不是嫌疑人。我是办案的人。） | inner_thought |
| 39 | 凌瑶 | 陆大人……沈清月现在还在客栈里。她不知道阿贵已经招了。 | determined |
| 4 | 阿贵 | …… | broken |
| 40 | 陆昭 | （……不。她可能已经知道了。像她这种人——什么都算好了。） | serious |
| 41 | 凌瑶 | 那怎么办？直接去抓她？ | anxious |
| 42 | 陆昭 | 不。光凭阿贵一个人的口供不够。她会说阿贵在诬陷她。 | cold |
| 43 | 陆昭 | 我们需要更多证据——能把她钉死的证据。然后——当面拆穿她。 | cold |
| 44 | 凌瑶 | 等等——还有一件事。阿贵凿船、老范选航道，这些解释了船为什么沉。但—— | determined |
| 45 | 凌瑶 | 死者指甲缝里那些蓝色草药碎屑呢？脖颈侧面的压痕呢？一个旱鸭子落水——指甲里不该有药。 | determined |
| 46 | 陆昭 | 有人在船沉之前就对周德茂动了手。让他失去反抗能力——然后随沉船坠江。 | serious |
| 47 | 凌瑶 | 阿贵不懂药。老范更不可能……那只有—— | anxious |
| 48 | 陆昭 | 药材商之女。 | cold |
| 49 | 凌瑶 | 好。那我们现在去——查她！赌坊那条线、码头的时间、蓝色草药的来源、还有那五十两货银到底去了哪—— | determined |
| 5 | 阿贵 | 我认了。船底是我凿的。浮囊是我带的。 | broken |
| 50 |  | 阿贵被带走了。他的供述揭开了案件下面的第二层——凿船沉舟只是表象，蓝色草药才是真正的杀人手段。

真正的对手——还在客栈里等着你。 | narration |
| 51 | 钱里正 | （站直身子，清了清嗓子）石矶渡渡口命案——经陆大人查明： | stern |
| 52 | 钱里正 | 船底系人为凿沉，仆从阿贵亲手实施。证据确凿。 | stern |
| 53 | 钱里正 | 阿贵—— | stern |
| 54 | 钱里正 | 有罪。 | stern |
| 6 | 凌瑶 | ！ | shocked |
| 6a | 阿贵 | （突然抬头，眼中闪过一丝混乱）可……可遣散的事…… | panic |
| 6b | 阿贵 | 不是老爷要遣散我的……是有人跟老爷说了什么。老爷本来没想赶我走——是有人在他耳边吹了风。 | shaken |
| 6c | 凌瑶 | 什么？！你是说——你的遣散也是被人操纵的？ | shocked |
| 6d |  | （阿贵的恨——十二年的怨——不是自然积累的。有人在背后推了一把，让周德茂做出了那个决定。让阿贵的仇恨彻底爆发。） | inner_thought |
| 6e | 陆昭 | ……谁？谁跟周德茂说的？ | serious |
| 6f | 阿贵 | 我……我不知道。我只知道老爷突然就变了脸。之前还说'再干一年看看'——然后某天回来就说'滚'。 | broken |
| 6g | 凌瑶 | （低声）如果遣散本身就是被设计的……那阿贵的恨、他的动机——全是被人制造出来的。他不只是帮凶——他也是棋子。 | worried |
| 7 | 陆昭 | 是你策划的整件事？ | cold |
| 8 | 阿贵 | ……不是。 | broken |
| 9 | 阿贵 | 不是我想的。我——我不会想这种事。 | broken |

### defeat_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 阿贵 | 大人，您说了这么多……都只是猜测吧。 | defensive |
| 1 | 阿贵 | 没有实证，您不能定小的罪。 | nervous |
| 2 | 陆昭 | …… | serious |
| 3 | 凌瑶 | （低声）嘶……让他溜了。不过别急——证据又不会长腿跑掉。咱们回去好好想想，下回叫他哑口无言。 | worried |
| 4 | 阿贵 | 小的冤枉。老爷的事，跟小的真的没关系。 | defensive |
| 5 | 凌瑶 | 走吧。回去把证物翻出来一样一样对。这案子没那么难——是咱出牌的顺序不对。 | worried |

# 阿贵对峙 · 四轮证词 (testimony_lines)

## testimony_0

### preamble

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 陆昭 | ……坐下。一个字一个字说。 | cold |
| 1 | 沈清月 | 阿贵是案发唯一在场的目击者。他的指控成不成立，得听完再说。陆公子，我知道你着急，但请允许他把话说完。 | cooperative |
| 2 | 阿贵 | 我说！那晚三更刚过—— | angry |
| 3 | 凌瑶 | （低声）她又在框规矩了，想给阿贵争一口气。哪句跟咱们手里的证据对不上，就拿出来打他脸。 | determined |

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 |  | 阿贵咬着牙坐了回去。额头上的汗珠滚落。指控的招数已经用尽了——被当众打脸。 | narration |
| 1 | 陆昭 | 死者身上没有钝器伤。你的指控不成立。 | cold |
| 2 | 沈清月 | 陆公子，钝器伤不存在只能说明死法不是打死——不能说明阿贵的其他描述都是假的。他仍然是唯一在场的目击者。 | sharp |
| 3 | 陆昭 | 不是打死的——但也不是简单的溺亡。 | cold |
| 4 | 凌瑶 | （低声）对。验尸时我注意到两处蹊跷：死者指甲缝里有蓝色碎屑，脖颈侧面还有极淡的压痕。单纯落水不会留下这些。 | determined |
| 5 | 沈清月 | （微不可察地顿了一下）……碎屑也可能是死者自己接触过什么草药。压痕更可能是落水挣扎时被绳缆磨出来的。大人不要先入为主。 | deflecting |
| 6 | 阿贵 | …… | shaken |
| 7 |  | （他不再喊了。刚才的气势——像泄了气的皮球。） | inner_thought |
| 8 |  | （从'他杀了老爷'到'就算没打也是他害的'——他已经开始给自己找退路了。而蓝色碎屑和脖颈压痕……这条线另有出处。） | inner_thought |
| 9 | 凌瑶 | （低声）她在帮阿贵保底——"就算指控不成立，他的目击者身份还在"。而且她刚才那句'草药'——说得太快了，像是准备好的。 | determined |
| 10 | 凌瑶 | 接下来别让他抢节奏了。该我们问——他答。一句一句来。 | determined |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 阿贵 | 大人——他就是凶手！铁器打人、天窗逃跑——都是他干的！ | angry |
| 1 | 沈清月 | 陆公子，若你要驳阿贵的证词，请对准他说的那一句来——别拿别的证物乱砸。 | sharp |
| 2 |  | （他喊得很大声，但手指在发抖。像是一个赌徒——把全部身家押在一把牌上。） | inner_thought |
| 3 | 凌瑶 | （低声）出错了。他咬死'铁器打人'——得用验尸结果打他的脸。 | worried |
| 4 | 凌瑶 | 死者身上没有钝器伤的证据！想想你验尸时看到了什么。 | worried |

## testimony_1

### preamble

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 陆昭 | 阿贵。从上船开始——一句一句说。 | cold |
| 1 | 沈清月 | 带浮囊上船不犯法，带伞出门也不犯法。陆公子，若只凭一个"提前准备"就定预谋，怕是天下人都进大牢了。 | cooperative |
| 2 | 阿贵 | （吞了口口水）是……是，大人。 | nervous |

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 |  | 阿贵像被抽掉了骨头——整个人瘫坐在地上，大口喘着粗气。额头上的汗比刚才更密了。 | narration |
| 1 | 凌瑶 | （小声）瞧他那样——像被踩了尾巴的耗子。喘成这样还嘴硬？ | anxious |
| 2 |  | （第一道防线破了。他现在知道我不是来走过场的——接下来他会更拼命地编。但越拼命，破绽越大。） | inner_thought |
| 3 | 你 | 阿贵。浮囊的事你怎么解释？ | cold |
| 4 | 阿贵 | 大人……大人您听我说……（抬起手，手指在抖） | panic |
| 5 | 阿贵 | 那个浮囊……小的确实是提前准备的。但不是为了害人——是为了保命啊！ | defensive |
| 6 | 你 | 保命？ | cold |
| 7 | 阿贵 | 老范跟小的说过，这段水路有暗礁，夜里走尤其凶险。小的不会水，怕出事……所以才藏了个浮囊。 | nervous |
| 8 | 阿贵 | 小的怕死！就这么简单！这又不犯法！（声音突然大了——随即又缩了回去）不犯法的…… | defensive |
| 9 |  | （'不犯法'——他在用法律术语替自己辩护。一个仆从。有意思。） | inner_thought |
| 10 | 凌瑶 | （低声）他把浮囊说成'怕死才带的'——那暗礁的事就成了他的保护伞。得把那个'暗礁'的谎也给拆了。 | worried |
| 11 | 凌瑶 | 对付他得一层一层剥。别急——本姑娘相信你。 | determined |
| 12 | 凌瑶 | （突然肚子咕噜叫了一声）……啊。 | embarrassed |
| 13 | 凌瑶 | ……别看我！早上那半个馒头被野狗叼走了我说过了！ | embarrassed |
| 14 |  | （……审讯到一半，她肚子饿了。） | inner_thought |
| 15 | 你 | 好。那我们就来谈谈你说的这个'暗礁'。船底那个洞——你再好好想想，到底是怎么来的。 | cold |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 阿贵 | 大人……这、这跟那晚有什么关系？您别冤枉好人啊……（抬头看你，眼神里闪过一丝得意——随即消失） | defensive |
| 1 | 沈清月 | 陆公子，你出示的证物跟"提前准备"搭不上。请对准他说的那一句。 | sharp |
| 2 |  | （那一闪而过的眼神——不是无辜者的委屈。是赌徒押对了的庆幸。） | inner_thought |
| 3 | 凌瑶 | （低声拽了拽你袖子）嘶……出错了。想想——他上船前就做了准备，咱手里哪样东西能揭穿他？ | worried |
| 4 | 凌瑶 | 别慌，本姑娘相信你。再来。 | determined |

## testimony_2

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 阿贵 | （双手抱头，蹲在地上发抖） | shaken |
| 1 | 沈清月 | 陆公子，凿痕只能证明船是人为沉的。"谁凿的"仍需进一步确认——船舱里还有死者和主角，不是只有阿贵一人。 | sharp |
| 2 | 凌瑶 | 两次了——两次被当场戳穿。而且他刚才差点说出个'教他的人'…… | determined |
| 3 | 凌瑶 | （低声）嘶——审了这么久我嘴都干了。大人你渴不渴？ | anxious |
| 4 | 你 | （看了她一眼） | cold |
| 5 | 凌瑶 | 好好好不渴不渴！继续继续！我没说话！ | embarrassed |
| 6 | 你 | 凿痕在船舱内侧。那晚只有你在船舱里。阿贵——你还有什么话说？ | cold |
| 7 | 阿贵 | …… | shaken |
| 8 | 阿贵 | 就算……就算小的动了手脚——那也是被逼的！ | panic |
| 9 | 阿贵 | 老范欠了赌坊四十二两银子！腊月底还不上就断指！是他来求小的帮忙的！小的只是……只是没拒绝！ | defensive |
| 10 | 阿贵 | 小的跟老爷十二年，吃穿不愁——小的为什么要主动害老爷？小的没有理由！ | nervous |
| 11 | 沈清月 | 阿贵说是被迫帮忙——这恰好和老范的说法对上了。陆公子，他的供词对他不利，他没必要同时为老范开脱。 | cooperative |
| 12 | 凌瑶 | （低声）她又在替阿贵圆话——"被逼的"如果成立，阿贵最多是从犯。她在保他的棋子。咱们手里那个东西能证明他自己就有杀人的理由。 | worried |
| 13 | 你 | 没有理由？只是被动帮忙？好——那我们来说说你跟周老爷的关系。一个字一个字说清楚。 | cold |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 阿贵 | 暗礁撞的！石头不长眼！大人您讲道理啊！ | defensive |
| 1 | 沈清月 | 里正大人也说了，江底暗礁尖利得很。陆公子，若证物不能排除天灾，就不能把它说成人祸。 | sharp |
| 2 | 凌瑶 | （低声）他在死撑'暗礁'的谎。咱们手里有能证明船底是人凿的东西——用它堵他的嘴。 | worried |

## testimony_3

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 阿贵 | （双手抱头，蹲在地上）小的……小的只是个下人…… | — |
| 1 | 凌瑶 | （低声）他又在装可怜了。可这次——遣散字据在他脸上。 | — |
| 2 | 钱里正 | （低声）这……遣散字据……阿贵，你之前可没提过这个。 | — |
| 3 | 周氏 | （突然开口）阿贵。老爷遣散你——是为什么？ | — |
| 4 | 阿贵 | （身体一僵）夫、夫人…… | — |
| 5 | 凌瑶 | （低声）周氏开口了。这下他更难编了。 | — |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 阿贵 | 大人……小的只是个下人，哪有本事害人性命……您搞错了！ | defensive |
| 1 | 沈清月 | 十二年主仆情分——陆公子若不能拿出他反目的证据，怎么叫人相信他会杀主人？ | sharp |
| 2 | 凌瑶 | （低声）他装孝子呢。好主仆？那咱们手里那张字据怎么说？拿出来打他脸。 | worried |

# 老范证词 (testimony_lao_fan_*)

## testimony_lao_fan_route

### preamble

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 钱里正 | 老范，你别缩着。船是你的，你得说清楚。 | nervous |
| 1 | 老范 | （咳了一声）我说。说错了，大人只管问。 | evasive |
| 2 | 沈清月 | 老范跑了二十年船，越是老船家越明白江上无常。陆公子若要把风浪说成谋杀，请先拿出硬证。 | cooperative |

### readthrough_end_hint

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）她把老范先摆成“老船家也会遇天灾”。可船底到底是什么样，咱们亲眼看过。 | determined |

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 陆昭 | 船不是被浪打翻的。是有人事先在船底动了手脚。 | cold |
| 1 | 沈清月 | 船底有洞也可能是旧船修补不当。陆公子，别把每个钉眼都看成杀意。 | sharp |
| 2 | 老范 | （脸色发白）大人……船、船底那事，我真的不知道…… | shaken |
| 3 | 陆昭 | 你知不知道，下一轮会说清楚。先说你落水之后的时间。 | cold |
| 4 | 凌瑶 | （低声）她替他挡了一下，但老范自己先慌了。王大爷那句话，正好能堵他。 | determined |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 老范 | 大人，江上翻船不稀奇。您这证物……跟暗礁浪头对不上啊。 | evasive |
| 1 | 沈清月 | 证物要对证词。拿不相干的东西压证人，只会让他的说法更稳。 | sharp |
| 2 | 凌瑶 | （低声）别跟他争水性。先证明船不是浪撞的——船底破洞，或者那些钉痕。 | worried |

## testimony_lao_fan_rescue

### preamble

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 陆昭 | 继续。船翻之后，你如何上岸？ | cold |
| 1 | 沈清月 | 翻船落水，惊惶之下记错时间并不奇怪。陆公子，这一轮若只问记忆偏差，恐怕定不了罪。 | cooperative |
| 2 | 老范 | 我……我命大。扒着块船板，漂了许久。 | evasive |

### readthrough_end_hint

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）她提前把“时间矛盾”说成“记忆偏差”。别让她把半个时辰糊成一句记不清。 | determined |

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 陆昭 | 半个时辰是假的。不到一刻钟上岸，说明你早有准备。 | cold |
| 1 | 沈清月 | 水性好的人上岸快些并不离奇。速度不是罪证。 | sharp |
| 2 | 老范 | 大人……我水性好，上岸快些也不能说我杀人啊。 | shaken |
| 3 | 陆昭 | 单独看确实不能。所以还要问最后一件事——你为什么愿意冒这个险。 | cold |
| 4 | 老范 | ……我跟周老爷无冤无仇。 | evasive |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 老范 | 大人，落水之后的事乱得很。您拿这个压我，我也说不出别的。 | evasive |
| 1 | 沈清月 | 冬江逃生，差一刻半刻并不少见。要推翻这句，得拿出能卡死时间的证据。 | sharp |
| 2 | 凌瑶 | （低声）他说'半个时辰后被救'。我们手里有王大爷记下的时间矛盾。 | worried |

## testimony_lao_fan_motive

### preamble

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 陆昭 | 老范。你说无冤无仇。那就说清楚——你为什么没有动机。 | cold |
| 1 | 沈清月 | 穷不是罪。码头上像老范这样欠钱的人多了去了，谁都可能有嫌疑。陆公子若要定他的罪，至少要拿出他"非做不可"的证据。 | cooperative |
| 2 | 老范 | 我一个跑船的，跟周老爷不过一趟生意。哪来的仇？ | evasive |

### readthrough_end_hint

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）她把老范的赌债说成"码头上欠钱的人多了"——等于提前把动机淡化。可码头竹棚里那张字据不是这么说的。 | determined |

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 老范 | （瘫坐回椅子）我……我只是缺钱。可主意不是我出的。 | shaken |
| 1 | 陆昭 | 那是谁出的？ | cold |
| 2 | 老范 | 是阿贵！是那仆从先说周老爷带着五十两货银！我只是、只是被他拖下水！ | panic |
| 3 | 沈清月 | （微不可察地皱了下眉）……老范。你别激动。有话慢慢说。 | cooperative |
| 4 | 阿贵 | （猛然站起）你胡说！明明是你—— | angry |
| 5 |  | 堂上一阵骚动。周氏的手攥紧了帕子。钱里正张了张嘴，没说出话。 | narration |
| 6 | 阿贵 | 大人！不用再查了！是他杀了老爷！我用性命担保——是他用铁器打的！ | angry |
| 7 | 凌瑶 | （低声）沈清月刚才让老范"别激动"——她不是在安慰他，她是在控场。怕他乱说。 | determined |
| 8 | 凌瑶 | 两个人开始互咬了。现在轮到阿贵——主动开口的人，破绽最多。 | determined |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 老范 | 大人，我是穷，可穷不等于杀人。您得拿出我非做不可的理由。 | evasive |
| 1 | 沈清月 | 赌债是旧债，谁知道他是上个月的还是去年的？陆公子，时间对不上就不是动机。 | sharp |
| 2 | 凌瑶 | （低声）动机。老范的动机就在那张借据上——四十二两，腊月底，断指。 | worried |

# 王大爷证词 (testimony_wang)

### preamble

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 钱里正 | 王大爷——你那天夜里在江上。看到了什么，就跟大人说说。 | nervous |
| 1 | 王大爷 | （慢吞吞站起来，清了清嗓子）行。那就说说。 | evasive |
| 2 | 沈清月 | 陆公子，王大爷只是说他听见和看见的事。若一上来就说成合谋，倒像是在替真正的问题开脱。 | cooperative |

### readthrough_end_hint

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）证言说完了。她先替王大爷把话框住了——别被她带着走，哪句能和我们手里的证据对上，你来判断。 | determined |

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 陆昭 | 王大爷的证言已经说明——航道是故意选的，有人提前约定了时间和路线。 | cold |
| 1 | 沈清月 | 从几句话推成合谋，未免太快。合计路线不等于凿船杀人，更不等于老范有罪。 | sharp |
| 2 | 陆昭 | 所以现在问老范。那条船是你的，航道也是你选的。你来解释。 | cold |
| 3 | 老范 | （旱烟杆在手里转了半圈）大人……我跑船二十年，最怕的就是这种事。可江上的事，谁说得准？ | evasive |
| 4 | 凌瑶 | （低声）她把“约定路线”降成了“几句话”。这就是偷换概念。别让老范躲在水雾里。 | determined |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 王大爷 | 大人……这个跟我说的事搭不上边吧。 | evasive |
| 1 | 沈清月 | 陆公子，若证物不能直接推翻这一句，继续硬压只会显得你急于定案。 | sharp |
| 2 | 凌瑶 | （低声）方向不太对。再想想——他那句'也正常'，什么东西能证明不正常？ | worried |

# 沈清月终局对峙 (confrontation_final)

### intro_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 |  | 客栈大堂临时设下的公堂。阿贵和老范被押在一侧，周氏伏案发抖，钱里正坐在上首。

沈清月原本站在周氏身后。此刻，她被请到了堂中。 | narration |
| 1 | 钱里正 | 沈姑娘……陆大人说，此案还没完。你得把话说清楚。 | nervous |
| 2 | 沈清月 | （平静走到堂中）我一直在这里。陆公子要问，我自然奉陪。 | cooperative |
| 3 | 凌瑶 | （低声）她从讼师的位置走到被问的位置了……可她还是一点都不慌。 | anxious |
| 4 | 陆昭 | 沈清月。阿贵已经招了。 | cold |
| 5 | 沈清月 | （微微挑眉）哦？一个杀人犯为了减罪攀咬别人，他说什么都能算数？ | sharp |
| 6 | 陆昭 | 所以我不只带了阿贵的供词。我带了证据。 | cold |
| 7 | 沈清月 | （沉默三息，然后笑了）好。那就来吧。——不过大人，“指向”和“证明”之间，隔着一条人命。 | cold_smile |
| 8 | 沈清月 | 你要定我的罪，就拿能让我闭嘴的东西出来。 | cold_fury |
| 9 | 凌瑶 | （低声）陆大人……她不是阿贵。她不会哭着认罪的。得一步步把她的逻辑全部拆碎。 | determined |
| 10 | 凌瑶 | 她会用反向逻辑——杀他对她没好处、口供不能定罪、物证可能被嫁祸。你得一层一层堵死。 | determined |
| 11 | 陆昭 | 开始。 | cold |

### victory_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 |  | 客栈大堂临时设下的公堂里，雨声压在屋檐上。所有人的目光都落在那只草药香囊上。 | narration |
| 1 | 陆昭 | 蓝色草药、脖颈压痕、阿贵口供、老范赌债、货银去向——证据链已经闭合。 | cold |
| 2 | 凌瑶 | 她输了。陆大人，她真的输了。 | determined |
| 3 | 沈清月 | （看着香囊，忽然笑了）是吗？陆公子，你确定你手里的，是“那一只”香囊？ | cold_smile |
| 4 | 陆昭 | ……什么意思？ | serious |
| 5 | 沈清月 | 凌姑娘懂药，也懂针线。劳烦你看看：这只香囊的绣线配色、药材配比，和你方才说的“专属香囊”是否一致。 | sharp |
| 6 | 凌瑶 | （接过香囊，脸色一点点变了）……不对。蓝草药味很淡，里面少了一味定香的辅料。绣线也不对，外圈该是银灰线，这只是灰白棉线。 | shocked |
| 7 | 沈清月 | 所以，这不是我的香囊。或者说——它已经不是原来那只了。 | deflecting |
| 8 | 钱里正 | 这、这是什么意思？ | shocked |
| 9 | 沈清月 | 意思是：陆公子拿来定我罪的核心物证，是赝品。孤证不立，赝物更不能立。 | cold_fury |
| 10 | 陆昭 | 你提前调包了。 | cold |
| 11 | 沈清月 | 大人说话要讲证据。你能证明是我调包，而不是有人嫁祸，甚至不是你自己急于定罪而拿错了东西吗？ | sharp |
| 12 | 凌瑶 | 你——！ | angry |
| 13 | 沈清月 | 阿贵是杀人犯，老范是赌鬼，王大爷刚被拆成伪证者。现在，唯一能直接指向我的香囊也是赝品。陆公子，你还剩什么？ | cold_smile |
| 14 | 陆昭 | 还剩真相。 | serious |
| 15 | 沈清月 | 真相不能替你签押，证据才能。 | cold_fury |
| 16 | 钱里正 | 陆大人……若物证存疑，县衙那边恐怕不会准押沈姑娘。 | nervous |
| 17 | 沈清月 | （转身向门外走去）你推理得很好。可惜，公堂上赢的不是推理，是证据。 | cold_smile |
| 18 | 沈清月 | 陆昭，下次再拿证据来找我时，记得先确认它还在不在你手里。 | sharp |
| 19 |  | 她撑伞走入雨幕。没有奔逃，没有回头，像只是赴完一场早已写好结局的约。 | narration |
| 20 | 凌瑶 | 陆大人……我从一开始就觉得她不对劲。下次，不会再让她得逞。 | worried |
| 21 | 陆昭 | 嗯。我们输的不是案情，是证据规则。那就从证据重新查。 | serious |
| 22 |  | 你第一次如此清楚地意识到：知道真相，与赢下案件，并不是同一件事。 | inner_thought |

### defeat_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 沈清月 | 大人。你手里所有的证据加在一起——也只够定阿贵的罪。跟我有什么关系？ | cold_fury |
| 1 | 沈清月 | 一个赌鬼的口供、一个杀人犯的攀咬、一个老渔翁在黑夜里看到的'模糊身影'——大人拿这些去县衙告我试试？ | cold_smile |
| 2 | 沈清月 | 至于蓝色草药？指甲缝的碎屑连死者自己什么时候沾上的都说不清。脖颈压痕？冬夜江水里什么撞不出来？大人，这叫证据还是叫联想？ | sharp |
| 3 | 沈清月 | 回去再读读大明律吧。'指向'和'证明'之间——隔着一条人命。 | sharp |
| 4 | 凌瑶 | （低声，咬牙）她……她在嘲笑我们……！但她说得也没错——草药线还没闭合，直接证据确实不够。下次一定把那只香囊的真品找回来！ | worried |

# 沈清月对峙 · 三轮证词

## shen_testimony_1

### preamble

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）第一轮。她会用"没有动机"挡你。 | determined |
| 1 | 沈清月 | （抱臂，微笑）陆公子，请便。不过先说好——我跟周德茂只有债务纠纷。杀债务人对债主没有好处。 | bold |

### readthrough_end_hint

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）她整套逻辑建立在"钱沉了所以我亏了"上面。拿出能推翻这个前提的证据。 | determined |

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 |  | 沈清月的表情变了——只有一瞬间。嘴角的弧度消失了。她重新抱起双臂，但这次——手指攥得更紧了。 | narration |
| 1 | 凌瑶 | （低声）看到了吗？她在调整姿势——重新找站稳的方式。第一层壳被敲碎了。 | determined |
| 2 | 凌瑶 | （深吸一口气，小声）我手心全是汗……比刚才审阿贵紧张十倍。 | anxious |
| 3 | 你 | （低声）你还站得住吗？ | serious |
| 4 | 凌瑶 | 站得住！本姑娘又不是纸糊的。就是……你能不能别那么酷？偶尔说句'进展不错'会死吗？ | determined |
| 5 | 你 | ……进展不错。 | serious |
| 6 | 凌瑶 | （愣了一下，然后笑了）哎。好。继续。 | cheerful |
| 7 | 沈清月 | ……好。就算有人打捞了那笔钱。你能证明——是我捞的？ | cold_fury |
| 8 | 你 | 你说你亥时前就回了客栈。但有人看到你一直待到船走远了才走。而天亮前你又出现在下游。 | cold |
| 9 | 沈清月 | 那是——（停了一下）别人。不是我。 | cracking |
| 10 | 你 | 你之前说'看他上船就走了'。后来改成'多站了一会儿'。现在又说不是你——你到底在哪里？ | cold |
| 11 | 沈清月 | （沉默了五息。然后她深吸一口气。） | cracking |
| 12 | 沈清月 | 好。换个说法。就算那天晚上我在码头待得久了——盯着自己的债务人上船有什么问题？不犯法。 | cold_fury |
| 13 | 凌瑶 | （低声）她在一步步退。从'不在场'退到'在场但合法'——跟阿贵一个套路。但她比阿贵冷静得多…… | anxious |
| 14 | 你 | 好。那我们来说说——你跟老范和阿贵之间的关系。你说'不认识'。可他们不是这么说的。 | cold |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 沈清月 | 大人。我说了——杀他对我只有坏处没有好处。你拿不出反驳这一点的东西。 | sharp |
| 1 | 凌瑶 | （低声）她的逻辑防线还没被破——得先证明'五十两没有沉江'。那个打捞证据——用它！ | worried |

## shen_testimony_2

### preamble

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）第二轮。她会说"我跟他们不认识"。但阿贵的供词和赌坊账本都指向她。 | determined |
| 1 | 沈清月 | 陆公子，你要证明我跟两个共犯有联系？好——但请注意，"码头碰过面"跟"合谋杀人"之间有十万八千里。 | cold_fury |

### readthrough_end_hint

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）她在用"熟人不等于同伙"挡。得找到她介入得太深、太精确的证据。 | determined |

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 |  | 沈清月的呼吸节奏变了。不再是之前均匀的、控制着的呼吸。胸口有了微微的起伏。 | narration |
| 1 | 凌瑶 | （低声）两层防线都破了——打捞、中间人。她现在只剩最后一道了：'你没有直接证据证明我策划了谋杀'。 | determined |
| 2 | 沈清月 | （声音变了——不再有演出的飒。是真正的她。极冷。极静。） | cold_fury |
| 3 | 沈清月 | 就算……就算我认识老范。就算那天夜里我没回客栈。 | cold_fury |
| 4 | 沈清月 | 那也只能证明——我在场。我认识当事人。 | cold_fury |
| 5 | 沈清月 | 你能证明是我策划了这一切吗？你能证明是我教阿贵凿船的吗？你有——直接证据吗？ | cold_fury |
| 6 | 你 | …… | cold |
| 7 | 凌瑶 | （低声）嘶……她反击了。她在把'认识'和'策划'之间的距离拉大——'就算我在场，也不能证明我指使了他们'…… | anxious |
| 8 | 你 | 好。那我换一个问法。——你案发前一天骂周德茂'别想走'。你说那只是讨债。 | cold |
| 9 | 你 | 但如果——你说那句话的时候，已经知道他走不了呢？ | cold |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 沈清月 | 一个赌鬼和一个杀人犯的话——大人就凭这个定我的罪？传出去不怕人笑话吗？ | cold_fury |
| 1 | 凌瑶 | （低声）她硬撑'别人的话不可信'——可老范亲口说了那个中间人。拿那条证据堵她！ | worried |

## shen_testimony_3

### preamble

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）最后一轮。她会说"你没有直接物证"。香囊是唯一能把草药线连到她身上的东西。 | determined |
| 1 | 沈清月 | （双臂抱得更紧，声音很平）你证明了我在场、认识共犯、有钱可图。但这些——在公堂上只叫"嫌疑"。你有直接物证吗？ | cold_fury |

### readthrough_end_hint

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 凌瑶 | （低声）她在赌你手里没有能直接指向她的物证。香囊——只有这个能砸碎她最后的壳。 | determined |

### transition_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 沈清月 | （抱臂，下巴微抬）大人。您的证据——都是间接的。 | cold_fury |
| 1 | 凌瑶 | （低声）她在说'你没有直接证据'。这是她最后的防线。 | determined |
| 2 | 你 | 间接证据也是证据。一条链环扣一环——足以定罪。 | cold |
| 3 | 沈清月 | （冷笑）链环？大人，您这链环——哪一环不是别人嘴里说出来的？ | cold_smile |
| 4 | 沈清月 | 阿贵的口供——杀人犯减罪攀咬。老范的证词——赌鬼为自保翻供。王大爷——你自己方才还拆成了伪证。 | cold_fury |
| 5 | 沈清月 | 陆公子，你全部的指控，建立在三个不可信的人嘴上。这叫证据链？这叫传话链。 | sharp |
| 6 | 你 | 那就不用他们的话。我用物证。 | cold |
| 7 | 沈清月 | （眉头微微一动）……哪个物证？ | deflecting |
| 8 | 凌瑶 | （低声）她刚才停了一下——她在算我们手里还剩什么。陆大人，最后一张牌。 | determined |
| 9 | 你 | 你问我还有什么。那就看——你那句'你没有任何直接物证'能不能扛住接下来的东西。 | cold |
| 10 | 沈清月 | （极轻地笑了）……好。那就请大人——出牌。 | cold_smile |

### fail_dialogue

| # | speaker | text | emotion |
|---|---|---|---|
| 0 | 沈清月 | 大人。巧合。全部都是巧合。——你带着这些'巧合'去县衙告我试试看？ | cold_fury |
| 1 | 凌瑶 | （低声）嘶……她的谎说了三遍了，咱们得把她时间线上的矛盾砸在她脸上——！ | worried |

# 搭档互动 (companion_banter)

### after_talk_agui

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "agui"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "那个阿贵……哭得也太假了吧？我见过镖局里装哭骗赏钱的，都比他演得好。"}, {"speaker": "陆昭", "text": "演技不好，不代表杀过人。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "那也不代表他没杀！反正他肯定在藏什么。"}], [{"speaker": "凌瑶", "text": "他说抱着船板飘上来的——冬天的江水啊！一个不会水的人能抱得住？"}, {"speaker": "陆昭", "text": "嗯，这条疑点先记下。", "emotion": "serious"}]]

```


### after_talk_lao_fan

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "lao_fan"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "跑了二十年船、水性一流的人——翻船了还能淹死别人自己没事？骗鬼呢。"}, {"speaker": "陆昭", "text": "水性好不代表不会翻船。但他说自己泡了半个时辰……", "emotion": "serious"}, {"speaker": "凌瑶", "text": "对！王大爷说不到一刻钟他就上岸了！这人在撒谎！"}], [{"speaker": "凌瑶", "text": "老范那态度……太淡定了。翻了船死了人，他连急都不急？"}, {"speaker": "陆昭", "text": "要么是真淡定，要么是心里有底。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "我赌是后者。"}]]

```


### after_talk_zhou_wife

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "zhou_wife"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "她丈夫刚死……看她那样子，不像是装出来的。"}, {"speaker": "陆昭", "text": "嗯。但悲伤不代表没有隐情。先记下她说的。", "emotion": "serious"}]]

```


### after_talk_zhou_wife_duck

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "zhou_wife", "requires": {"clue": "clue_victim_cant_swim"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "周氏说的那条——'旱鸭子半夜坐船'——确实蹊跷。怕水的人天黑上船，不是被人催的就是被人骗的。"}, {"speaker": "陆昭", "text": "而且她丈夫上船前刚骂了阿贵。当晚就出事……", "emotion": "serious"}, {"speaker": "凌瑶", "text": "这也太巧了吧！"}]]

```


### after_talk_zhou_wife_money

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "zhou_wife", "requires": {"evidence": "evidence_dismissal_note"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "二两银子遣散费……十二年。换谁都得寒心。"}, {"speaker": "陆昭", "text": "寒心不等于杀人。但确实给了他动机。", "emotion": "serious"}]]

```


### after_talk_li_zheng

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "li_zheng"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "钱里正这人……净替人开脱。'意外''天灾'说得可真轻松。"}, {"speaker": "陆昭", "text": "地方小吏，怕事。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "怕事就别当官啊！哼。"}], [{"speaker": "凌瑶", "text": "他说阿贵昨天买了好酒好肉——刚死了主人就大吃大喝？"}, {"speaker": "陆昭", "text": "这不正常。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "太不正常了！而且他马上要被遣散，哪来的钱？"}]]

```


### after_talk_fisherman_wang

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "fisherman_wang"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "王大爷说的跟老范完全对不上！一个说不到一刻钟就上岸了，一个说泡了半个时辰——"}, {"speaker": "陆昭", "text": "谁在撒谎，一目了然。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "老范那个老滑头！他根本不是被困在水里，他是自己游上岸的！"}], [{"speaker": "凌瑶", "text": "案发前一晚，一高一矮两个人在码头角落嘀咕……高的像仆从，矮的像船家。"}, {"speaker": "陆昭", "text": "阿贵和老范。他们在预谋。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "这下对上了！"}]]

```


### lie_exposed_generic

**触发条件**: `{"trigger": "lie_exposed"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "露馅了吧！我就说他在撒谎！"}, {"speaker": "陆昭", "text": "别急着高兴。撒谎不一定等于杀人。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "可是——为什么要撒这个谎？撒谎的人心里肯定有鬼！"}]]

```


### gain_evidence_generic

**触发条件**: `{"trigger": "gain_evidence"}`

**对话内容**:

```

["又找到一样东西！本姑娘帮您收着！", "这是证据吧？感觉很关键。", [{"speaker": "凌瑶", "text": "陆大人，又一样。证据越来越多了。"}, {"speaker": "陆昭", "text": "多不代表够。缺一环都不行。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "……您这人，就不会说句'进展不错'？"}]]

```


### gain_clue_generic

**触发条件**: `{"trigger": "gain_clue"}`

**对话内容**:

```

["有意思……这条线牵着谁？", "又多了一条线索。陆大人您脑子里是不是已经有数了？", [{"speaker": "凌瑶", "text": "嗯……这条线索很重要吧？"}, {"speaker": "陆昭", "text": "先记下来。", "emotion": "serious"}]]

```


### arrive_ferry_inn

**触发条件**: `{"trigger": "arrive_location:ferry_inn", "requires": {"not_flag": "visited_ferry_inn_banter"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "这雨下得没完没了的……我那封信都快发霉了。"}, {"speaker": "陆昭", "text": "……你要是早些寄出去，我替你想想办法。这一趟是我连累了你。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "哎，说什么连累——您倒是先把案子查清楚，我这封信等得起。"}]]

```


### arrive_zhou_room

**触发条件**: `{"trigger": "arrive_location:zhou_room", "requires": {"location": "zhou_room"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "（压低声音）她眼睛都哭肿了……但你看那个眼神——不像是纯粹的悲伤。更像是在盯着什么。"}, {"speaker": "陆昭", "text": "别乱下结论。先听她说。", "emotion": "serious"}]]

```


### arrive_agui_room

**触发条件**: `{"trigger": "arrive_location:agui_room", "requires": {"location": "agui_room"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "（小声）他看着比码头上更紧张了……手一直在抖。"}, {"speaker": "凌瑶", "text": "你注意他的眼睛——说话时老往门口那边瞟。是在怕谁进来？"}]]

```


### arrive_ferry_dock

**触发条件**: `{"trigger": "arrive_location:ferry_dock"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "码头这味儿……鱼腥味加泥巴味。真香。"}, {"speaker": "陆昭", "text": "……走吧。", "emotion": "cold"}]]

```


### arrive_wreck_site

**触发条件**: `{"trigger": "arrive_location:wreck_site"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "这船烂成这样……那人在里头得多绝望啊。冬天的江水，冰到骨头里。"}, {"speaker": "凌瑶", "text": "……算了不想了。查案查案。"}]]

```


### arrive_river_bend

**触发条件**: `{"trigger": "arrive_location:river_bend"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "这渔村好小啊。感觉全村加一块儿不到十户人。"}, {"speaker": "凌瑶", "text": "不过空气比码头好闻多了。"}]]

```


### phase_unlocked_2

**触发条件**: `{"trigger": "phase_unlocked:phase_2"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "陆大人，听说下游渔村有个老渔民，那晚也在江上——说不定他看见了什么！去那边看看？"}]]

```


### after_talk_shen_phase1

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "shen_qingyue", "requires": {"not_flag": "agui_confessed_mastermind"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "这个沈清月……嘴挺利的。看着像个做生意的女强人——但嘴太快了。"}, {"speaker": "陆昭", "text": "嘴快不代表说的都是实话。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "嗯……不过暂时没看出什么破绽。她确实亏了——债收不回来了。"}], [{"speaker": "凌瑶", "text": "她说'杀他对我有什么好处'——这话乍一听……还真没毛病。"}, {"speaker": "凌瑶", "text": "但如果好处不只是那三十八两呢？嗯……先查别的。"}]]

```


### after_talk_shen_phase3

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "shen_qingyue", "requires": {"flag": "agui_confessed_mastermind"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "嘶——跟她说话真累。每句话都滴水不漏。比阿贵难对付十倍。"}, {"speaker": "陆昭", "text": "她比阿贵聪明得多。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "所以才更可恨。聪明到把别人当棋子——然后自己站在干岸上。"}], [{"speaker": "凌瑶", "text": "她那个眼神……真冷。刚才有一瞬间——我觉得她在打量你，像在估量'这个人能不能拦住我'。"}, {"speaker": "陆昭", "text": "能。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "（噗）好。本姑娘信你。"}]]

```


### pre_confrontation_agui

**触发条件**: `{"trigger": "confrontation_start:agui"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "（深吸一口气）好……要上了。陆大人，我的手心在出汗。"}, {"speaker": "陆昭", "text": "别紧张。证据够了。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "我不紧张！就是……有点激动。头一次看审案呢。加油！"}]]

```


### lingyao_moral_crisis_shen

**触发条件**: `{"trigger": "phase_unlocked:phase_3", "requires": {"evidence": "evidence_father_ledger"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "陆大人。我有个事……想跟你说。"}, {"speaker": "陆昭", "text": "说。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "我爹……前年也病过一回。大夫说要三十两的药。我们家哪拿得出来。"}, {"speaker": "凌瑶", "text": "那时候我跑了三趟远镖——命都差点搭上——才凑够的。"}, {"speaker": "凌瑶", "text": "……沈清月她爹要八十两。她一个姑娘家。"}, {"speaker": "陆昭", "text": "……", "emotion": "serious"}, {"speaker": "凌瑶", "text": "我不是替她说话！杀人就是杀人。但是——（攥紧拳头）——如果当时我凑不够那三十两……"}, {"speaker": "凌瑶", "text": "我不知道我会不会做出跟她一样的事。"}, {"speaker": "陆昭", "text": "你不会。", "emotion": "serious"

```


### pre_confrontation_shen

**触发条件**: `{"trigger": "confrontation_start:shen_qingyue"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "（压低声音）陆大人。她不是阿贵——她不会崩溃哭着认罪。"}, {"speaker": "凌瑶", "text": "她会反咬。会用逻辑把你绕进去。你得比她更冷静。"}, {"speaker": "陆昭", "text": "嗯。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "……我在你旁边。有什么想法我会提醒你。别一个人扛。"}, {"speaker": "陆昭", "text": "嗯。——你也别一个人扛。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "（愣了一下。然后用力点了点头。）"}]]

```


### confrontation_break_success

**触发条件**: `{"trigger": "confrontation_break"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "漂亮！打得他说不出话来！"}], [{"speaker": "凌瑶", "text": "这下没话说了吧！证据面前——你还怎么编？！"}], [{"speaker": "凌瑶", "text": "嘶——你看他那表情。裂了。继续！"}]]

```


### confrontation_wrong_evidence

**触发条件**: `{"trigger": "confrontation_fail_evidence"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "嗯……这个好像不太对。别急——换个角度想想。"}], [{"speaker": "凌瑶", "text": "（小声）方向不对……那条证据不是用在这儿的。再看看他说的哪句有问题？"}], [{"speaker": "凌瑶", "text": "没事没事……出一次错不算什么。深呼吸——本姑娘信你。"}]]

```


### arrive_shen_room

**触发条件**: `{"trigger": "arrive_location:shen_room"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "（低声）这姑娘……气场好强。坐在那儿跟没看见我们似的。"}, {"speaker": "凌瑶", "text": "不过你看她手——指甲修得很干净，但虎口那里有茧。练过功夫？"}]]

```


### arrive_gambling_alley

**触发条件**: `{"trigger": "arrive_location:gambling_alley"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "好暗……这种地方白天都这么阴森？"}, {"speaker": "凌瑶", "text": "（吸吸鼻子）嚯——烟味汗味骰子声。我爹以前就爱去这种地方。"}, {"speaker": "陆昭", "text": "你爹也赌？", "emotion": "serious"}, {"speaker": "凌瑶", "text": "（理直气壮）以前赌！后来被我娘拿笤帚追了三条街——从此戒了。"}, {"speaker": "凌瑶", "text": "老范就是在这里欠了四十二两。嗯——进去问问，看有没有人认识那个'药材行的姑娘'。"}]]

```


### gain_evidence_hull_hole

**触发条件**: `{"trigger": "gain_evidence", "evidence": "evidence_hull_hole"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "凿子凿的！边缘这么齐——不可能是意外！陆大人，这是谋杀！"}, {"speaker": "陆昭", "text": "嗯。谁凿的——才是问题。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "老范最有条件。他自己的船、自己修——想做手脚太容易了。"}, {"speaker": "陆昭", "text": "可能。但也可能有人'教'他这么做。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "……你的意思是——还有幕后？"}]]

```


### gain_evidence_float_bladder

**触发条件**: `{"trigger": "gain_evidence", "evidence": "evidence_float_bladder"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "浮囊！在阿贵包袱里！他——"}, {"speaker": "凌瑶", "text": "一个说自己不会水、什么准备都没有的人——包袱里藏着救命的东西！"}, {"speaker": "陆昭", "text": "说明他事先知道船会沉。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "不只是知道——他准备好了自己不死。那他主人呢？他主人不会水——他知道的。"}, {"speaker": "凌瑶", "text": "……这就是谋杀。蓄意的。"}]]

```


### gain_evidence_salvage_mark

**触发条件**: `{"trigger": "gain_evidence", "evidence": "evidence_salvage_mark"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "天亮前有人在下游打捞……穿深色衣裳，身量高挑，像女子？"}, {"speaker": "凌瑶", "text": "等等——谁会知道沉船之后东西会漂到哪里？只有事先算过的人！"}, {"speaker": "陆昭", "text": "而且那个时间——如果阿贵和老范都还在岸上'待着'——谁去的下游？", "emotion": "serious"}, {"speaker": "凌瑶", "text": "第三个人……一个算好了一切、在下游等着收货的人。她。"}]]

```


### gain_evidence_blue_herb

**触发条件**: `{"trigger": "gain_evidence", "evidence": "evidence_blue_herb_residue"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "蓝色……碎屑？指甲缝里的？（凑近闻了闻）嘶——这味道辛冷刺鼻，不像寻常香料。"}, {"speaker": "陆昭", "text": "能让人昏沉失力的草药。他落水之前可能已经被迷晕了。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "被迷晕了再掉进水里——旱鸭子根本没机会挣扎。这不是单纯溺亡——是被人安排好的死局。"}, {"speaker": "凌瑶", "text": "这种罕见药……寻常人弄不到。药材商才有门路。"}]]

```


### gain_evidence_neck_marks

**触发条件**: `{"trigger": "gain_evidence", "evidence": "evidence_neck_marks"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "脖颈这里……（用手比划）有极淡的压痕。不像绳勒，更像是被人用手短暂按住过。"}, {"speaker": "陆昭", "text": "昏迷前被压制。有人在他身后动了手——确保他完全失去反抗能力。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "凿船的是阿贵，掌舵的是老范……那谁在船上对死者下药、按住他？"}, {"speaker": "凌瑶", "text": "（皱眉）除非——不是在船上。是上船之前就被人动过手脚。"}]]

```


### gain_evidence_herb_sachet

**触发条件**: `{"trigger": "gain_evidence", "evidence": "evidence_herb_sachet"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "这香囊……（翻来覆去看）绣工精细得很，不是渔民船夫的东西。而且——（深吸一口）这味道！"}, {"speaker": "凌瑶", "text": "跟死者指甲缝的蓝色碎屑一模一样的辛冷气！"}, {"speaker": "陆昭", "text": "带着这种药的人，把香囊遗落在了案发现场附近。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "富户女子的随身物、罕见蓝色草药——大人，这条线能把草药和那个人绑在一起。"}, {"speaker": "凌瑶", "text": "（低声）……我越来越觉得，沈清月有问题。"}]]

```


### gain_evidence_father_ledger

**触发条件**: `{"trigger": "gain_evidence", "evidence": "evidence_father_ledger"}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "八十两药钱……她家只有四十二两。差三十八两。"}, {"speaker": "凌瑶", "text": "三十八两——这不就是周德茂欠她的数吗？！"}, {"speaker": "陆昭", "text": "继续算。如果不只是旧债——还有周德茂身上那五十两货银呢？", "emotion": "serious"}, {"speaker": "凌瑶", "text": "三十八加五十……八十八两。超过了她需要的八十两！"}, {"speaker": "凌瑶", "text": "陆大人——这是动机！她不是为了讨债——她是为了把人和钱一锅端！"}]]

```


### idle_hint_phase1

**触发条件**: `{"trigger": "idle", "min_periods": 8, "requires": {"not_flag": "agui_confessed_mastermind"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "陆大人……你是不是在想什么？"}, {"speaker": "陆昭", "text": "在理线索。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "要不要我帮你捋一捋？目前知道的——船是人为凿沉的。阿贵和老范都有嫌疑。"}, {"speaker": "凌瑶", "text": "要对质阿贵——得先找齐证据。船底的洞、他包袱里的东西、还有他被遣散的事……"}, {"speaker": "凌瑶", "text": "哪个还没查到？去翻翻看？"}]]

```


### idle_hint_phase3

**触发条件**: `{"trigger": "idle", "min_periods": 6, "requires": {"flag": "agui_confessed_mastermind", "not_flag": "shen_confrontation_triggered"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "陆大人。沈清月还在楼上呢——你打算什么时候去找她摊牌？"}, {"speaker": "陆昭", "text": "证据不够。光凭阿贵的话不够定她。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "那还差什么？——码头那晚她到底做了什么？那五十两银子去哪了？老范是谁找来的？"}, {"speaker": "凌瑶", "text": "赌坊那条线能不能查到什么……要不去试试？"}]]

```


### lingyao_shen_connection

**触发条件**: `{"trigger": "dialogue_end", "npc_id": "shen_qingyue", "requires": {"flag": "shen_connection_pressed"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "等等。等等等等。"}, {"speaker": "凌瑶", "text": "陆大人——我刚想起来一件事。我那个急件——送到石矶渡的那封——"}, {"speaker": "凌瑶", "text": "收件人……姓沈。"}, {"speaker": "陆昭", "text": "……", "emotion": "serious"}, {"speaker": "凌瑶", "text": "沈什么我不记得了。但姓沈——石矶渡——做药材生意——这也太巧了吧？！"}, {"speaker": "陆昭", "text": "先把这件事记下来。案子结了之后再查。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "……好。但我心里毛毛的。我那个急件——不会跟这案子有关系吧？"}]]

```


### moral_reflection_agui

**触发条件**: `{"trigger": "phase_unlocked:phase_3", "requires": {"flag": "agui_confessed_mastermind"}}`

**对话内容**:

```

[[{"speaker": "凌瑶", "text": "大人……你说，阿贵算是坏人吗？"}, {"speaker": "陆昭", "text": "他杀了人。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "我知道。可是——十二年被人当牛马使，最后被二两银子打发。换我我也……"}, {"speaker": "凌瑶", "text": "……算了。我不会杀人。但我理解他为什么恨。"}, {"speaker": "陆昭", "text": "理解恨是一回事。原谅杀人是另一回事。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "嗯。……所以才需要大人这样的人吧。在'理解'和'不能原谅'之间——做出判断。"}]]

```


# 搜索发现对话 (search_results)

| 场景 | 搜索点 | 描述 | 获得证据/线索 |
|---|---|---|---|
| zhou_room | zhou_desk | 桌上散着几张文书和信纸。一方砚台搁在角上，墨迹有的干了有的还新鲜。几封信似乎是周氏在写但没寄出的。 | — |
| zhou_room | zhou_luggage | 周氏的行李包袱。里面是几件换洗衣裳和一些碎银。没什么异常——但包袱底层有一张货单，列着五十两的布匹预… | clue_cargo_money_record |
| agui_room | agui_clothes | 绳上晾着阿贵的衣物——一件厚棉外袍还在往下滴水，旁边是一件薄里衣和一条腰带。 | — |
| agui_room | agui_bundle | 床下有个旧包袱，系了死结，像是故意不让人轻易打开的。 | — |
| ferry_inn | inn_lobby | 客栈大堂。几个滞留旅客缩在角落烤火。掌柜的在擦桌子。看起来没什么特别——只是掌柜的随口说了句「那仆从… | clue_agui_spending |
| ferry_dock | dock_body_examine | 你蹲下翻看尸体。面色青紫，口鼻有白色泡沫——这是溺亡的特征。

头部、躯干——没有一处钝器击打的伤痕… | evidence_no_blunt_trauma |
| ferry_dock | dock_wreck_hull | 被拖上岸的破船。船底朝天。你凑近看——确实能看到一处破洞的边缘，但大部分被淤泥糊住了。需要去下游打捞… | — |
| ferry_dock | dock_fan_boat | 老范自己的那条小船停在码头边。船身干净、保养得不错。船舱里有渔网、绳索，还有一个空酒坛。

码头上一… | clue_fan_night_work |
| ferry_dock | dock_fan_belongings | 码头角落的竹棚下，堆着老范的杂物。翻了翻——一堆渔具底下压着一张皱巴巴的纸：「借银四十二两整……限腊… | evidence_gambling_iou |
| ferry_dock | dock_fan_belongings | 你再次翻检老范的杂物——这次更仔细了。渔具最底层，压在一块油布下面：一张被揉皱又展平的纸条。半截泡糊… | evidence_anonymous_note |
| wreck_site | wreck_hull_bottom | 你蹲下仔细查看船底。一块木板明显与周围不同——边缘有整齐的凿痕，不像是撞击造成的。更像是从内侧被人打… | evidence_hull_hole |
| wreck_site | wreck_cargo_area | 货舱区域空空如也。按周氏所说，丈夫带了五十两货银上船。但这里除了几块泡烂的布匹，什么值钱东西都没有。… | evidence_cargo_silver |
| wreck_site | wreck_debris | 散落的残骸中有断裂的船桨、泡水的草席，还有几截断钉。断钉上的痕迹新旧不一——有人在出事前不久动过这条… | evidence_nail_marks |
| wreck_site | wreck_shore_bag | 在沉船下游的芦苇丛中，你发现一只被江水冲到岸上的包袱——和阿贵在客栈用的是同一种粗布。打开一看，底层… | evidence_float_bladder |
| river_bend | village_wang_home | 王大爷的小屋里挂满了渔网。老人坐在门口补网，看到你来并不意外：「我就知道会有人来问。那天夜里的事……… | evidence_wet_letter |
| shen_room | shen_bedside | 床边缝隙里卡着几根干草和一缕辛冷药香。再往里拨，摸出一只绣工极细的香囊。香囊内残留蓝色草药碎末，气味… | evidence_herb_sachet |
| ferry_dock | dock_reed_seal | 雨后的芦苇伏在江边。你在泥水里捡到一小片油布锦袋残角，边缘有朱砂印泥的痕迹——像是官印匣上的封布。官… | evidence_seal_cloth_wrap |
| shen_room | shen_desk | 桌案上摊着一本账册，封面写着'沈氏药账'。翻开一看——密密麻麻记着药名、数量、银两。最后一笔是三十八… | evidence_father_ledger |
| gambling_alley | gambling_den | 赌坊柜台上积着厚厚的油污。掌柜的不在，只有一个打瞌睡的伙计。你翻了翻柜台上的账本——大多是欠条和借贷… | clue_fan_double_debt |
| gambling_alley | gambling_alley_wall | 后巷墙角堆着烂菜叶和破筐。你拨开杂物——墙根的砖缝里塞着一张被揉成团的纸条。展开一看：'事成之后，码… | clue_gambling_alley_note |
