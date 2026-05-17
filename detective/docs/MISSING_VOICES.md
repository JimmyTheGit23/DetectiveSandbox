# 未生成语音清单

> **自动生成**: `python tools/audit_voices.py`  **最后扫描**: 见 git blame  **用途**: 跟踪每个案件中尚未生成 TTS 的对话/序章/事件节点。新案件 PR 必跑此脚本。

## 总览

| 案件 | 标题 | voice_status | 已有 | 缺失 | 状态 |
|------|------|------|------|------|------|
| `linchuan_inn` | 临川驿案 | `full` | 103 | 0 | ✅ 全量 |
| `xunyang_pavilion` | 浔阳楼·夜雨红绸案 | `missing` | 0 | 83 | ⚠ 全部待生成（83 条） |

## 浔阳楼·夜雨红绸案 (`xunyang_pavilion`)

缺失 83 条。

### 对话

#### bu_zhang → actor_wealthy_merchant（4 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `greet` | `assets/cn/voices/actor_wealthy_merchant/xunyang_pavilion/greet.wav` | （卜掌柜抬眼）大人光临布庄，可是看货？ |
| `about_silk` | `assets/cn/voices/actor_wealthy_merchant/xunyang_pavilion/about_silk.wav` | （顿）这……案发当日午时确有一笔，是位白衣公子急要的，连名都没留全，只签了个「玄」字。  他要的是整匹未断的——我心里就奇怪，浔阳楼那批红绸刚出三日，怎的这位… |
| `show_ledger` | `assets/cn/voices/actor_wealthy_merchant/xunyang_pavilion/show_ledger.wav` | （取出账册）大人您看，这笔记得急，字也歪。买的还是一整匹——三尺八，少见。  他付的是碎银，没要单子。我也是后来听浔阳楼出事，才把这笔记上的。 |
| `match_silk` | `assets/cn/voices/actor_wealthy_merchant/xunyang_pavilion/match_silk.wav` | （对比片刻）大人，这残片的织纹与浔阳楼出的那批是一致的。但那匹绛红云纹绸全城只有我柜上出——三日前刚卖出一匹给浔阳楼，案发当日午时又卖出一匹给那位白衣公子。 |

#### lady_zhou → actor_elder_grandmother（4 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `greet` | `assets/cn/voices/actor_elder_grandmother/xunyang_pavilion/greet.wav` | （周老夫人手拄藤杖，眼神锐利）御史大人来问什么——是为秋菱那孩子吧。 |
| `about_debt` | `assets/cn/voices/actor_elder_grandmother/xunyang_pavilion/about_debt.wav` | （拄杖）她欠我五十两白银。但我那五十两是借给她当赎身银凑数用的——不是为难她。  她明日就要走了。我去布庄看过账册——浔阳楼采办那匹红绸是她自己掏的银钱，不是… |
| `about_redemption` | `assets/cn/voices/actor_elder_grandmother/xunyang_pavilion/about_redemption.wav` | （叹）那三百两是远地一位客人三日前送来的，托青姐转给她。秋菱不肯叫别人知道——她说她只想离开浔阳楼，不想嫁人。  （沉默）她这样的姑娘，旁人想拥有她，胜过想她… |
| `react_to_silk` | `assets/cn/voices/actor_elder_grandmother/xunyang_pavilion/react_to_silk.wav` | （神色一变）案发后还去补一匹？……那便不是失足。是有人怕这条红绸被人查到来路。  大人——若您要查买主，去问卜掌柜，他柜上的账册是有名字的。 |

#### liu_chuan → actor_foreign_traveler（4 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `greet` | `assets/cn/voices/actor_foreign_traveler/xunyang_pavilion/greet.wav` | （刘船家眼神躲闪，正在收缆绳）大人……要渡江么？ |
| `about_night` | `assets/cn/voices/actor_foreign_traveler/xunyang_pavilion/about_night.wav` | （搓手）……三更头我打盹被惊醒，看见一个白影从水阁那头走出来，往江边丢了个包袱。我没敢出声。 |
| `gender` | `assets/cn/voices/actor_foreign_traveler/xunyang_pavilion/gender.wav` | （低声）男的。白衣。瘦。脚步轻——像是会做工夫的，不像寻常书生。  包袱沉得很，丢下水扑通一声，溅起的水花到现在我还记得。 |
| `confront_traces` | `assets/cn/voices/actor_foreign_traveler/xunyang_pavilion/confront_traces.wav` | （叹气）……既然大人都看到了，我便不瞒。那条新打的绳扣是我事后补的——我怕浔阳楼的人来问，把原来的扣子改了。  那白衣公子走后第二日午时还回来过一趟。我躲在船… |

#### ma_san → actor_jianghu_swordsman（3 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_jianghu_swordsman/xunyang_pavilion/intro.wav` | （马三抱拳）陆大人。鲁知府是判了'醉酒失足'，可末将看了现场——红绸断口确实不对劲。大人但有差遣，末将听调。 |
| `request_help` | `assets/cn/voices/actor_jianghu_swordsman/xunyang_pavilion/request_help.wav` | （点头）末将立即布置。浔阳楼前后两门各派两人，三日内出门的全部记下。 |
| `why_lu` | `assets/cn/voices/actor_jianghu_swordsman/xunyang_pavilion/why_lu.wav` | （压低声）末将私下说——本府前年才出了一桩'醉死的伶人'，闹得整府名声不好。鲁大人怕这案子又一闹大，往上拍来一封折子，他这官就难当了。  大人手上若证据充分，… |

#### magistrate_lu → actor_senior_prefect（4 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_senior_prefect/xunyang_pavilion/intro.wav` | （鲁知府捻须）陆大人远来辛苦。这案子本府已经派人查过——醉酒失足，证据明白。大人不必费心。 |
| `argue_railing` | `assets/cn/voices/actor_senior_prefect/xunyang_pavilion/argue_railing.wav` | （皱眉）……指甲痕？本府未曾细看。陆大人若执意要查，本府不阻拦——但三日为限，结案稿已拟好，过期就发回州府。 |
| `argue_silk` | `assets/cn/voices/actor_senior_prefect/xunyang_pavilion/argue_silk.wav` | （脸色微变）……这红绸的断口，确实不像失足。罢罢，本府改'存疑'二字，等大人再查三日。 |
| `argue_witness` | `assets/cn/voices/actor_senior_prefect/xunyang_pavilion/argue_witness.wav` | （沉默良久）阁中第二人——那便不是失足了。本府这就把结案稿撕了。陆大人，这桩案子交予您。 |

#### qing_jie → actor_madam_proprietress（6 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/intro.wav` | （青姐含泪）陆大人。秋菱这孩子，我看着长大的。她不是会跌下去的人——大人您可一定要查个明白。 |
| `last_company` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/last_company.wav` | （垂下眼）那夜雨大，楼里少有客人。她偏房点了灯，似乎是在等人。我去送了一壶酒上去——出来时听见她在说'你回去吧'，再后面我就不该听了。 |
| `voice_who` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/voice_who.wav` | 男声，斯文。是我们这里的常客——白衣公子。 |
| `loan_truth` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/loan_truth.wav` | （叹气）秋菱不是好赌的。她欠周夫人的钱，是为了凑足赎身银——她差三百两不到，便用浔阳楼的份子钱去借，约期就在明日。 |
| `show_redemption` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/show_redemption.wav` | （青姐怔了一下）……这就是了。这是远地一位姓陈的老客人，仰慕秋菱清雅，三百两为聘想接她归乡做夫人。秋菱没说要嫁他——她只是要走。  大人，世上不是所有人都心甘… |
| `show_letter_qj` | `assets/cn/voices/actor_madam_proprietress/xunyang_pavilion/show_letter_qj.wav` | （看到信，眼泪掉下来）……这字是她写的没错。'清郎'是她近半年新交的客——白衣公子。她跟我说过，那位公子人不坏，但太执拗。  秋菱说：'我若不走，他不会让我好… |

#### qing_xuan → actor_opera_performer（12 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/intro.wav` | （白衣公子拱手）陆大人。在下顾清玄，江南游学之客。听说昨夜浔阳楼出了不幸的事，在下可惜得很——秋姑娘那样人物，竟落得这般结局。 |
| `where_you_were` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/where_you_were.wav` | （端着茶杯）在下吃了两壶酒，醉卧偏房。一觉到天亮，连秋姑娘出事都未听闻——惭愧。 |
| `show_wine_amount` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/show_wine_amount.wav` | （顾清玄笑容收了一寸）大人……果然细致。罢罢，我承认那夜只喝了一壶。可'醉'是个心境——我在偏房醒着发愁，跟一壶酒、两壶酒，也没多大分别。 |
| `your_relation` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/your_relation.wav` | （淡淡一笑）相识半年。在下囊中并不宽裕，常来浔阳楼也只是吃些清茶——秋姑娘待人和气，与我也不过点头之交。 |
| `show_letter_q` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/show_letter_q.wav` | （看到那封信，顾清玄沉默了一会儿）……「清郎」，是写给我的。  （声音低下来）她说要走。三百两赎身银，把她从浔阳楼买出来——明日就要走了，去哪里我都不知道。我… |
| `show_hairpin` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/show_hairpin.wav` | （顾清玄盯着那支银钗，半晌没说话）……是我的。  那夜我去找过她，求她不要走。她说她要走了，请我也走。我走出去三步——又回去了。  （自嘲一笑）我没料到她会从… |
| `show_witness` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/show_witness.wav` | （脸色微变）……望见？谁望见的？  罢了，大人既然来问，便是有人见了。是的——那夜阁中我不止一次站在栏边。可我推没推她，那是另一桩事。请大人查清楚再说。 |
| `confront_silk_receipt` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/confront_silk_receipt.wav` | （顾清玄盯着账册上那个歪斜的「玄」字，半晌不语）  ……案发第二日午时，我去布庄取了一匹一样的绛红云纹绸。  （轻声）我以为只要红绸还在她手里，府衙就会信「醉… |
| `confront_at_dock` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/confront_at_dock.wav` | （顾清玄眼神一闪）……大人也去过水阁？  （深吸一口气）那夜我没睡。三更过后我去后江畔——把她平日里的胭脂盒、银钗匣，和一封她没写完的信，一并丢进了江里。  … |
| `confront_at_chamber` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/confront_at_chamber.wav` | （顾清玄嘴角抽了一下）……是的。次日午后，我趁府衙人散，回去过。  她妆台抽屉里有一张小笺——「玄郎，明日我便走了，万勿来送」。她字迹漂亮，写我的名字也漂亮。… |
| `confront_visited_nun` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/confront_visited_nun.wav` | （顾清玄抬眼，眼神冷了一寸）……无尘师太告诉大人的？  （沉默片刻）我去问她那夜是否听见动静。她说她什么都没听见——可她说的时候没看我。  （自嘲）我若没去问… |
| `intro_cornered` | `assets/cn/voices/actor_opera_performer/xunyang_pavilion/intro_cornered.wav` | （顾清玄已不再粉饰，盘腿坐在偏房窗下）陆大人。该问的都问完了。  红绸是我案发后去布庄重买的。她的东西是我夜里丢到江里的。她妆台里的小笺是我次日回去拿走烧了的… |

#### sun_laoliu → actor_innkeeper_wife（4 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `greet` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/greet.wav` | （孙娘擦着茶碗）大人请坐。后院出了事，我这茶也卖不动了。 |
| `about_d1_noon` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/about_d1_noon.wav` | （想了想）午时……白衣那位公子出过楼。一刻钟前还在正厅喝茶，一刻钟后我转头他人就没了。回来的时候手里多了一个布庄的包袱。  我没多想——这边客商常去布庄买点小… |
| `about_d1_dusk` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/about_d1_dusk.wav` | （皱眉）黄昏雨大。我关了茶摊回屋。后门口我看见那位白衣公子披了一件深色斗篷出去——往后江畔的方向。  （叹）我当时只想他是去看江景。出了事后想起来——那个方向… |
| `confirm_silk_trip` | `assets/cn/voices/actor_innkeeper_wife/xunyang_pavilion/confirm_silk_trip.wav` | （看一眼单据）对，就是这家——卜掌柜的字我认得。  这就坐实了——他午时出楼那一刻钟，正是去买了这匹红绸。他不是「醉卧偏房」。 |

#### wuchen → actor_buddhist_nun（6 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `intro` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/intro.wav` | （无尘师太合十）大人安好。寒庵无事，唯每夜诵经守门。 |
| `saw_what` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/saw_what.wav` | （缓缓道）老衲那夜诵经至三更。雨声中，望了对楼三楼阁子一眼——  阁中先有一抹白影徘徊，停在栏边。继而红影后退，白影又逼近。再然后——红影便从栏边坠了下去。 … |
| `saw_face` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/saw_face.wav` | （摇头）夜雨蒙蒙，老衲只见衣色。但那身白衫，本府这几年只一位常着——大人您应已心中有数。 |
| `intro_after_visit` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/intro_after_visit.wav` | （无尘师太眉头微皱）……大人这次来，老衲想说一件事。  昨夜三更，那位白衣公子曾来庵中敲门——问老衲那夜是否听见对楼有动静。老衲只说「未曾」，他便走了。  但… |
| `visit_time` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/visit_time.wav` | （合十）三更刚过。雨已歇。  他一个人来——若只是寻常借宿之客，何必夜半敲庵门问案发夜之事？心虚之人，方才如此。 |
| `why_silent` | `assets/cn/voices/actor_buddhist_nun/xunyang_pavilion/why_silent.wav` | （缓缓道）老衲见过的恶人，多数不在他作恶之时，而在他事后慌乱之时。  若我当场质问他，他可能反咬。老衲只能装作不知，让大人来问。 |

### 序章

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `scene1` | `assets/cn/voices/_prologue/xunyang_pavilion/scene1.wav` | 万历二十四年，三月。江南细雨。  这是个风疏雨骤的夜晚，本府名楼——浔阳楼。 |
| `scene2` | `assets/cn/voices/_prologue/xunyang_pavilion/scene2.wav` | （按辔行至楼下）今日借宿浔阳楼，明日一早就要启程回京。雨下得这么大，倒也省得有人请喝酒了。 |
| `scene3` | `assets/cn/voices/_prologue/xunyang_pavilion/scene3.wav` | 夜里三更。楼下传来一声闷响，紧接着是女人短促的惊叫—— |
| `scene4` | `assets/cn/voices/_prologue/xunyang_pavilion/scene4.wav` | （提灯赶到后院）青石板上躺着一位女子。颈间缠着一段绛红云纹绸——  这便是浔阳楼的当家花魁，秋菱。 |
| `scene5` | `assets/cn/voices/_prologue/xunyang_pavilion/scene5.wav` | （蹲下细看）她的指甲缝里干净，手心却握着一段红绸——这绸的断口是横向的扯痕，分明是从背后被人猛拉。  但鲁知府已经拍板：醉后凭栏，失足跌下。 |
| `scene6` | `assets/cn/voices/_prologue/xunyang_pavilion/scene6.wav` | （皱眉）三日为限。再迟，结案稿就要送回京——这就成了一桩没人在意的'醉死的女伶'。  该问的人，都还在浔阳楼里。从这院里开始查吧。 |

### 日程事件

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `evt_redemption_revealed_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_redemption_revealed_0.wav` | 青姐红着眼睛递过来一封黄黄的封信。 |
| `evt_redemption_revealed_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_redemption_revealed_1.wav` | 「这是远地客人三日前送来的赎身契，三百两整。秋菱若收下了，明日就是良民。她不肯告诉别人——只跟我说要还清债再走。」 |
| `evt_redemption_revealed_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_redemption_revealed_2.wav` | 「她不是想嫁那位客人，她只是想离开这个地方。她欠周夫人的银，也是为了拖时间凑齐赎身钱。」 |
| `evt_redemption_revealed_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_redemption_revealed_3.wav` | 「能让她走得好的人不多，不让她走的人——大人您仔细想想就明白了。」 |
| `evt_silk_message_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_silk_message_0.wav` | 城南布庄一名学徒匆匆送来字条： |
| `evt_silk_message_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_silk_message_1.wav` | 「那匹绛红云纹绸是浔阳楼三日前刚出银采办的。共三尺六寸，一尺六寸做了红披帛，剩下两尺整存着。」 |
| `evt_silk_message_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_silk_message_2.wav` | 「也就是说，案发那条红绸，是从楼里临时拿出来的。死者并不是用'自己的'东西自缢——这红绸是被人特意取来的。」 |
| `evt_encounter_dock_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_0.wav` | 夜色未深，江面起了薄雾。你正踏上那段湿木板，忽见水阁那头一个白衣人影背对着你站着。 |
| `evt_encounter_dock_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_1.wav` | 他手里提着个不大的包袱，正欲俯身把它系在缆绳上。听见脚步，他猛地一僵。 |
| `evt_encounter_dock_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_2.wav` | 你借灯笼微光看清了——是顾清玄。他白衣胸前沾了水痕，袖口还湿着。 |
| `evt_encounter_dock_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_3.wav` | 「……陆大人，怎么这个时辰也来江畔走走？」他笑得极浅，眼里没笑意。「我醉了，出来透透风。这包袱？是楼里小厮托我顺便丢去对岸的旧物罢了。」 |
| `evt_encounter_dock_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_4.wav` | 你没去接他递的话——那包袱沉得不像旧物。但他已松手让它落入江中，绳一抽，便顺水而去。 |
| `evt_encounter_dock_5` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_5.wav` | （你已撞见他在江畔销证，这一夜他必不能再装作'醉卧偏房'。） |
| `evt_encounter_chamber_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_0.wav` | 你推开闺阁门，正撞见一个白衣身影从妆台前直起身——抽屉半开着，里面的物什被翻乱了。 |
| `evt_encounter_chamber_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_1.wav` | 「陆大人。」顾清玄从容地理了理袖口，脸色却有一瞬白。「我来看看……秋菱姐留下的那把篦子。她答应过送我作念想的。」 |
| `evt_encounter_chamber_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_2.wav` | 你看了眼妆台。被翻动的明明不止那把篦子——香盒、笺盒、连枕下的小匣都被掀了一遍。 |
| `evt_encounter_chamber_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_3.wav` | 他笑了笑，从袖中取出一封半皱的信纸折成小笺：「就找到这一张。她写给一位'阿公子'——你看，这字也不是写给我的。」 |
| `evt_encounter_chamber_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_4.wav` | （信纸边缘已有焦痕——他刚才正在烧。） |
| `evt_encounter_chamber_5` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_5.wav` | （你已撞见他在闺阁翻找并销毁书信。这是他在掩盖什么，绝非'念想'二字所能解释。） |
| `evt_encounter_silk_shop_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_silk_shop_0.wav` | 卜掌柜将账册推到你面前，正欲翻页，门口铜铃一响—— |
| `evt_encounter_silk_shop_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_silk_shop_1.wav` | 顾清玄抱着一卷新红绸进来，眼见你与卜掌柜相对而坐，他的脚步顿了一下，随即笑着拱手： |
| `evt_encounter_silk_shop_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_silk_shop_2.wav` | 「陆大人也喜欢这色？这家是城南最老的布庄了。我替楼里采办些新绸——青姐说近日要换些喜色冲冲晦气。」 |
| `evt_encounter_silk_shop_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_silk_shop_3.wav` | 卜掌柜在他背后向你使了个不易察觉的眼神。 |
| `evt_encounter_silk_shop_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_silk_shop_4.wav` | （你看出来了：他怕你看到的不是'采办'，而是账册上他自己三日前那笔——一尺六寸的绛红云纹绸。） |
| `evt_encounter_convent_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_0.wav` | 你立在庵前石阶下，欲叩门，却听见里面传来低低的话音。 |
| `evt_encounter_convent_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_1.wav` | 「……师太昨夜何时熄灯？……可有听见对楼有人说话？」 |
| `evt_encounter_convent_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_2.wav` | 正是顾清玄的声音——温和有礼，问的却分明是案发夜的事。 |
| `evt_encounter_convent_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_3.wav` | 你听见无尘师太淡淡一句：「贫尼念经至子时方歇，旁的，未曾留心。」 |
| `evt_encounter_convent_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_4.wav` | 顾清玄又低声说了几句，便起身。你退到山门后柱影里，看着他披上斗篷，从侧门匆匆离去——并不见他来时焚的香。 |
| `evt_encounter_convent_5` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_5.wav` | （他不是来礼佛——是来探虚实。他要确认师太是否目击案发夜。） |

---

## 后续 TTS 生成提示

1. 每条缺失语音的 `actor_id` 决定了用哪个 voice_config —— 见 `data/actors/registry.json`。
2. 缺失列表按 `actor_id` 聚合后跑 `tools/generate_voices.py` 可批量生成。
3. 序章和事件类语音不区分 actor，按 `_prologue/` / `_events/` 旧目录约定生成。
4. 重新跑本脚本即可看到差量更新。
