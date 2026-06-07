# 未生成语音清单

> **自动生成**: `python tools/audit_voices.py`  **最后扫描**: 见 git blame  **用途**: 跟踪每个案件中尚未生成 TTS 的对话/序章/事件节点。新案件 PR 必跑此脚本。

## 总览

| 案件 | 标题 | voice_status | 已有 | 缺失 | 状态 |
|------|------|------|------|------|------|
| `jinling_purge` | 金陵大清洗 | `missing` | 0 | 0 | ✅ 全量 |
| `linchuan_inn` | 临川驿案 | `missing` | 99 | 53 | ⚠ 全部待生成（53 条） |
| `prologue_ferry` | 渡口沉舟 | `missing` | 0 | 191 | ⚠ 全部待生成（191 条） |
| `xunyang_pavilion` | 浔阳楼·夜雨红绸案 | `missing` | 73 | 62 | ⚠ 全部待生成（62 条） |

## 临川驿案 (`linchuan_inn`)

缺失 53 条。

### 序章

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `scene1a` | `assets/cn/voices/_prologue/linchuan_inn/scene1a.wav` | 但他的行程没有结束——巡按的下一站，是临川。  州府公文说临川近年税赋异常，让他顺路核查账目。本是一件例行公事。但特意挑了这个时节派他来——京里可能还有别的意… |
| `scene1b` | `assets/cn/voices/_prologue/linchuan_inn/scene1b.wav` | 万历二十三年，秋。  从浔阳到临川，走水路半日可到。  船行江上，秋雨又起。暮色四合，岸上树木已换了秋色——橙红橘黄，衬着灰蓝的天，像是谁打翻了一盘颜料。  … |
| `scene2a` | `assets/cn/voices/_prologue/linchuan_inn/scene2a.wav` | （抹了把脸上的雨水，四处打量）这驿站比浔阳楼差远了——不过比石矶渡那个破客栈还是强点。  陆大人，您说咱这次来临川是巡按？可我怎么看这地方……太平得很啊？ |
| `scene2b` | `assets/cn/voices/_prologue/linchuan_inn/scene2b.wav` | 先安顿下来。明天开始查账。  （看了眼驿站院中的老槐树，树叶沾着雨水，沉甸甸地低垂。跟他此刻的心情差不多。） |
| `scene2c` | `assets/cn/voices/_prologue/linchuan_inn/scene2c.wav` | 又是那种弯弯绕绕的官场门道。上回浔阳楼那事儿本姑娘到现在还做噩梦呢——不过好歹算帮上忙了吧？  这回查账而已，应该不会出人命了吧…… |
| `scene2d` | `assets/cn/voices/_prologue/linchuan_inn/scene2d.wav` | 先安顿下来。明天开始查账。  （停了一下，没看她）凌姑娘……你跟了两个案子了。这回只是查账，你要是想回镖局—— |
| `scene2e` | `assets/cn/voices/_prologue/linchuan_inn/scene2e.wav` | 走走走，走什么走！本姑娘跟着您跑了两个案子了，这时候走算什么？  再说了，镖局那边的差事早就交待清楚了——首座知道我在帮您，说让我继续跟着。  （小声嘀咕）反… |
| `scene3b` | `assets/cn/voices/_prologue/linchuan_inn/scene3b.wav` | 他穿过回廊，推开后院角门——  井边躺着一个人。  晨雾还未散尽，那人的轮廓模糊不清。但姿势不对。不是蹲着，不是靠着——是瘫倒的。 |
| `scene3c` | `assets/cn/voices/_prologue/linchuan_inn/scene3c.wav` | （脚步一顿。  雾气很重，但那个姿势他太熟悉了——不是活人的姿势。  指尖微微收紧。又来了。） |
| `scene4a` | `assets/cn/voices/_prologue/linchuan_inn/scene4a.wav` | （打着哈欠走出来）陆大人，大清早的您就—— |
| `scene4b` | `assets/cn/voices/_prologue/linchuan_inn/scene4b.wav` | ……！ |
| `scene4c` | `assets/cn/voices/_prologue/linchuan_inn/scene4c.wav` | 凌瑶的哈欠卡在喉咙里。她看清了地上的人，倒退两步，背靠住了廊柱。  嘴唇发黑，指甲青紫。她见过这种死法。 |
| `scene4d` | `assets/cn/voices/_prologue/linchuan_inn/scene4d.wav` | （声音发紧）这个嘴唇的颜色……我以前跑镖见过。是中毒。  陆大人，这人——是被人毒死的？ |
| `scene4e` | `assets/cn/voices/_prologue/linchuan_inn/scene4e.wav` | 还不能确定死因。但唇色青黑、指甲紫暗——中毒的可能性很大。  （翻开死者袖口）  等等——袖子里有东西。 |
| `scene5a` | `assets/cn/voices/_prologue/linchuan_inn/scene5a.wav` | （凑近看了一眼，又退回去）朱砂？那不是画画用的颜料吗……还是入药的那种？  一个当官的在信里写朱砂干什么？而且——信都没写完，人就死了？ |
| `scene5b` | `assets/cn/voices/_prologue/linchuan_inn/scene5b.wav` | 信写到一半人就死了。  （将纸小心折好）谁会自尽前写信？分明是写到一半——被人发现了。或者，写信本身触怒了什么人。  这不是旧疾。这是灭口。 |
| `scene5c` | `assets/cn/voices/_prologue/linchuan_inn/scene5c.wav` | （深吸一口气，攥紧拳头）所以……是被人杀的？  那凶手不会还在这驿站里面吧？！ |
| `scene5d` | `assets/cn/voices/_prologue/linchuan_inn/scene5d.wav` | （站起来，环顾四周。晨雾正散，视线比刚才清楚了一些。）  驿站不大，住的人有限。昨夜能接近死者的人……屈指可数。  先搞清楚这人是谁。青布官袍——临川县衙的小… |
| `scene5e` | `assets/cn/voices/_prologue/linchuan_inn/scene5e.wav` | 这时驿丞赵大有听到了动静，从廊下跑过来。看清地上的人，脸色一变。 |
| `scene5f` | `assets/cn/voices/_prologue/linchuan_inn/scene5f.wav` | 这、这不是沈主簿吗？！沈砚秋——县衙的主簿！昨天傍晚还说今天要来驿站取公文——怎么就…… |
| `scene5g` | `assets/cn/voices/_prologue/linchuan_inn/scene5g.wav` | 县主簿？三十二岁，跟我差不多大……怎么死在这口井边？ |
| `scene6a` | `assets/cn/voices/_prologue/linchuan_inn/scene6a.wav` | 沈主簿素来体弱，想必是旧疾发作，毒火攻心——陆大人远道而来，此事本县自理即可。 |
| `scene6b` | `assets/cn/voices/_prologue/linchuan_inn/scene6b.wav` | 知县大人。  （语气平静，但一字一顿）袖中未写完的信、唇色青黑的毒征、井边而非床上的死亡地点——哪一条像'旧疾'？ |
| `scene6c` | `assets/cn/voices/_prologue/linchuan_inn/scene6c.wav` | （沉默片刻）……陆大人若执意插手，本县自然不便阻拦。只是案宗三日之内须发还州府。  若是查不出结果——「擅自越权」的罪名，本县可担不起。 |
| `scene6d` | `assets/cn/voices/_prologue/linchuan_inn/scene6d.wav` | 三天够了。  （转向凌瑶，语气比对知县柔了一度）凌姑娘，恐怕这趟不只是查账了。又要辛苦你。 |
| `scene6e` | `assets/cn/voices/_prologue/linchuan_inn/scene6e.wav` | （拍胸脯，但声音还有点抖）第三回了！本姑娘查案也算有点经验了——虽然上回在浔阳楼差点被吓死……  不过陆大人您放心，跑腿打探消息我在行！必要时候……必要时候我… |
| `scene6f` | `assets/cn/voices/_prologue/linchuan_inn/scene6f.wav` | 好。有什么看到的、听到的随时告诉我。在人前莫声张。  （望着驿站方向，声音低了下去）  柳知县想断成旧疾。一个在井边倒下、信写到一半的人——他急着把真相写给谁… |

### 日程事件

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `evt_day2_break_in_3` | `assets/cn/voices/_events/linchuan_inn/evt_day2_break_in_3.wav` | ……说明凶手还在临川。而且他要找的东西还没找到。 |
| `evt_day2_break_in_4` | `assets/cn/voices/_events/linchuan_inn/evt_day2_break_in_4.wav` | 那咱们快去看看！ |
| `evt_gu_offers_help_0` | `assets/cn/voices/_events/linchuan_inn/evt_gu_offers_help_0.wav` | 一位白衣公子主动找到你，自称顾清玄，沈砚秋的旧友。 |
| `evt_gu_offers_help_1` | `assets/cn/voices/_events/linchuan_inn/evt_gu_offers_help_1.wav` | 大人。在下听闻砚秋兄遇害，特来相助。我与他相识多年，或许能提供一些线索。 |
| `evt_gu_offers_help_2` | `assets/cn/voices/_events/linchuan_inn/evt_gu_offers_help_2.wav` | （低声）陆大人，这人好突然啊……不过有人帮忙总是好的吧？ |
| `evt_gu_offers_help_3` | `assets/cn/voices/_events/linchuan_inn/evt_gu_offers_help_3.wav` | 顾清玄看起来真诚而悲伤。他说他有一些关于沈砚秋过去的资料——如果你有空，可以去春风楼找他。 |
| `evt_gu_provides_dossier_0` | `assets/cn/voices/_events/linchuan_inn/evt_gu_provides_dossier_0.wav` | 顾清玄在春风楼上邀你吃茶。他从怀中抽出一卷誊本—— |
| `evt_gu_provides_dossier_1` | `assets/cn/voices/_events/linchuan_inn/evt_gu_provides_dossier_1.wav` | 这是邻县按察司里的副本。万历四年的米行案——告发者，俗姓严。流放路上，沈家七口尽殁。只剩一个十一岁的小儿——就是后来的沈砚秋。 |
| `evt_gu_provides_dossier_2` | `assets/cn/voices/_events/linchuan_inn/evt_gu_provides_dossier_2.wav` | 沈兄查的根本不是赈灾粮——那只是顺手。他真正要为之昭雪的，是他亲生父亲。凶手不在县衙——在临川某处寺院的香火里。 |
| `evt_gu_provides_dossier_3` | `assets/cn/voices/_events/linchuan_inn/evt_gu_provides_dossier_3.wav` | ……二十年前的事？等等——他怎么知道得这么清楚？ |
| `evt_gu_provides_dossier_4` | `assets/cn/voices/_events/linchuan_inn/evt_gu_provides_dossier_4.wav` | 顾清玄的消息来源看似合理——按察司幕僚的身份能接触旧档。但凌瑶的话也有道理：他为什么知道得这么清楚？ |
| `evt_ma_reveals_gu_identity_0` | `assets/cn/voices/_events/linchuan_inn/evt_ma_reveals_gu_identity_0.wav` | 马三趁着无人，低声对你说—— |
| `evt_ma_reveals_gu_identity_1` | `assets/cn/voices/_events/linchuan_inn/evt_ma_reveals_gu_identity_1.wav` | 大人，那个白衣公子顾清玄——我上个月在县衙见过他。穿的可不是白衣，是州府按察司的官服。他跟柳知县密谈了半日。 |
| `evt_ma_reveals_gu_identity_2` | `assets/cn/voices/_events/linchuan_inn/evt_ma_reveals_gu_identity_2.wav` | 怎么现在变成『游学路过』了？卑职觉得不对劲，但不敢声张。大人您自己留心。 |
| `evt_ma_reveals_gu_identity_3` | `assets/cn/voices/_events/linchuan_inn/evt_ma_reveals_gu_identity_3.wav` | ！！！他骗我们！他根本不是什么书生！陆大人—— |
| `evt_ma_reveals_gu_identity_4` | `assets/cn/voices/_events/linchuan_inn/evt_ma_reveals_gu_identity_4.wav` | ……先不要打草惊蛇。知道他的真实身份，反而是我们的优势。 |
| `evt_day3_liu_pressure_4` | `assets/cn/voices/_events/linchuan_inn/evt_day3_liu_pressure_4.wav` | （看来夜里时辰，他会等在城南石桥下与你相见。） |
| `evt_day5_su_initiative_3` | `assets/cn/voices/_events/linchuan_inn/evt_day5_su_initiative_3.wav` | 「见朱砂之人」……他知道自己可能出事，提前留了后手？这个人心思可真深。 |
| `evt_daoming_confesses_0` | `assets/cn/voices/_events/linchuan_inn/evt_daoming_confesses_0.wav` | 施主。贫僧确实二十年前出面告发了沈家米行。但——贫僧是被人逼的。 |
| `evt_daoming_confesses_1` | `assets/cn/voices/_events/linchuan_inn/evt_daoming_confesses_1.wav` | 当年有人拿着一份伪造的账簿，逼贫僧以庙的名义出面告发。贫僧……贫僧至今不知那人是谁。只记得他年轻、说话文雅、一身白衣。 |
| `evt_daoming_confesses_2` | `assets/cn/voices/_events/linchuan_inn/evt_daoming_confesses_2.wav` | ……白衣？年轻？二十年前？那时候顾清玄多大？等等不对—— |
| `evt_daoming_confesses_3` | `assets/cn/voices/_events/linchuan_inn/evt_daoming_confesses_3.wav` | 二十年前顾清玄还是个孩子。但如果他家族里有人参与呢？或者……他继承了某个人未竟的事。 |
| `evt_daoming_confesses_4` | `assets/cn/voices/_events/linchuan_inn/evt_daoming_confesses_4.wav` | 贫僧欠了沈家一条命。如果大人能查明真相，贫僧甘愿伏法。 |
| `evt_day6_deadline_3` | `assets/cn/voices/_events/linchuan_inn/evt_day6_deadline_3.wav` | 有。 |
| `evt_day6_deadline_4` | `assets/cn/voices/_events/linchuan_inn/evt_day6_deadline_4.wav` | ……就一个字？行吧，本姑娘信您！大不了……大不了回镖局挨顿骂呗。 |
| `evt_day6_deadline_5` | `assets/cn/voices/_events/linchuan_inn/evt_day6_deadline_5.wav` | 证据若已齐全，便可前往县衙公开指证。 |

## 渡口沉舟 (`prologue_ferry`)

缺失 191 条。

### 对话

#### agui → (无 casting)（1 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `hub` | `assets/cn/voices/agui/hub.wav` | 你……你是昨晚同船的那位？听说里正给了你两天。你要问什么……问吧。 |

#### agui_cabin → (无 casting)（1 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `hub` | `assets/cn/voices/agui_cabin/hub.wav` | 你……你是同船的？我叫阿贵，跟了老爷十二年。这次是去武昌府进棉布。 |

#### fisherman_wang → (无 casting)（6 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `hub` | `assets/cn/voices/fisherman_wang/hub.wav` | 渡口那边传过来了——说有人在查那夜翻船的事。是你吧？来得好。老头子看见了些东西，憋在肚子里不舒坦。 |
| `ask_channel` | `assets/cn/voices/fisherman_wang/ask_channel.wav` | 走的东汊那条。  在这一带跑船的人都知道——东汊有暗礁。涨水没涨水都不能走。  老范在这儿跑了二十年。他不知道？放屁！他比谁都知道！  除非——他就是故意走那… |
| `ask_meeting` | `assets/cn/voices/fisherman_wang/ask_meeting.wav` | 前一晚……对，老头子那天也收了夜网。  路过码头的时候，看到两个人蹲在角落里说话。黑灯瞎火的，鬼鬼祟祟。  一高一矮。高的像是那仆从——腰板直。矮的精瘦精瘦的… |
| `trust` | `assets/cn/voices/fisherman_wang/trust.wav` | 老头子活了一辈子，在这江上。  见过太多死在水里的人。有些是命，有些不是。  那天夜里那人在水里扑腾的声音……老头子一辈子忘不了。  有人跟我说'别多管闲事'… |
| `ask_dawn_sighting` | `assets/cn/voices/fisherman_wang/ask_dawn_sighting.wav` | 天还没亮的时候，老头子在下游浅滩看见一个人拿长竿探水。  那人穿深色衣裳，身量高挑，不像老范，也不像阿贵。  我当时离得远，不敢说死。但天一亮，那人就不见了。… |
| `ask_river_life` | `assets/cn/voices/fisherman_wang/ask_river_life.wav` | 老头子在这江上打了一辈子鱼。  哪条汊水有暗礁，哪片浅滩能藏东西，心里都有数。  所以我才说——老范那样的老船家，绝不可能糊里糊涂把船往东汊暗礁上带。 |

#### lao_fan → (无 casting)（2 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `hub` | `assets/cn/voices/lao_fan/hub.wav` | 哟……你就是那个同船的？听说周氏告了你杀人啊。胆子不小——被告了还到处问话。 |
| `ask_route` | `assets/cn/voices/lao_fan/ask_route.wav` | 周老板说赶早市，码头上又有人把东汊说得近。我想着绕大弯太费时，就拣了那条水路。  嗐，我也知道有礁石。但水涨了以后，以前那礁石应该没过去了嘛。谁知道还露着。 |

#### lao_fan_cabin → (无 casting)（1 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `hub` | `assets/cn/voices/lao_fan_cabin/hub.wav` | 哟……又来一个问话的？我叫老范，跑了二十年船。这次是去武昌府的夜船。 |

#### li_zheng → (无 casting)（6 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `hub` | `assets/cn/voices/li_zheng/hub.wav` | 哦……你来了。我话撂在前头——周氏那边我得给交代。你要问话就问，但最后拿不出真凭实据……我只能按程序报上去。 |
| `ask_fan` | `assets/cn/voices/li_zheng/ask_fan.wav` | 老范嘛……人还行。就是爱赌。以前小赌怡情，这两年越赌越大。  听说欠了赌坊不少钱。前阵子还有人来找他要账，闹得挺凶。  不过嘛——大事化小。他水性好，人也实在… |
| `ask_agui_spending` | `assets/cn/voices/li_zheng/ask_agui_spending.wav` | 异常嘛……嗐，也不能说异常。就是——  他昨天在客栈买了壶好酒，又打了半斤卤肉。出手挺阔的。  按说刚死了主人的仆从……哪有心情喝酒吃肉啊？而且他马上要被遣散… |
| `ask_victim` | `assets/cn/voices/li_zheng/ask_victim.wav` | 知道知道。做布匹生意的，来往走水路常歇在咱这儿。  人嘛……精明是精明的。就是待下人刻薄了些。动不动呵斥，我听过好几回了。  不过嘛——人死了，大事化小，就别… |
| `ask_next_step` | `assets/cn/voices/li_zheng/ask_next_step.wav` | 阿贵招了——但供出的人是沈清月。大人，这事……不好办啊。 沈家在这一带做了几十年药材生意，人脉广。光凭阿贵一张嘴，县衙那边不会批捕的。 您得找到实证。码头时间… |
| `ask_shen_opinion` | `assets/cn/voices/li_zheng/ask_shen_opinion.wav` | 沈清月……说实话，以前觉得她就是个精明的生意人。讨债凶是凶了点，但也没出过格。 不过现在想想——她那天在码头骂周德茂'别想走'，我还以为是气话。 大人，您要是… |

#### shen_qingyue → (无 casting)（3 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `hub` | `assets/cn/voices/shen_qingyue/hub.wav` | 你就是那个……同船活下来的？听说周氏告了你杀人。嘁——冤不冤的我不知道，但你问话倒挺利索。问吧。 |
| `react_agui_caught` | `assets/cn/voices/shen_qingyue/react_agui_caught.wav` | 阿贵招了？……意料之中。他那种人，扛不住的。 |
| `ask_father_after` | `assets/cn/voices/shen_qingyue/ask_father_after.wav` | ……还在躺着。八十两的药，一天不能断。 |

#### zhou_de_gui_cabin → (无 casting)（1 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `hub` | `assets/cn/voices/zhou_de_gui_cabin/hub.wav` | ……你就是那个同船的御史？我叫周德茂，做布匹生意。这次是去武昌府进一批棉布。 |

#### zhou_wife → (无 casting)（5 条）

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `hub` | `assets/cn/voices/zhou_wife/hub.wav` | ……里正说让你查。我拦不住。  问吧。但你最好是来找真凶的——不是来替自己脱罪的。 |
| `intro` | `assets/cn/voices/zhou_wife/intro.wav` | （她冷冷地看着你，好一会儿才开口）……里正说你要自证清白。随你。  老爷做布匹生意。这次是去武昌府进一批棉布，过了年好卖。  他带了五十两货银。还有阿贵跟着。… |
| `ask_suspicion` | `assets/cn/voices/zhou_wife/ask_suspicion.wav` | 阿贵不对劲。案发后他哭得比我都凶——可他跟老爷关系好吗？不好。  上船前还被骂了一通，当晚就哭天抹泪？我不信。  还有——老爷是旱鸭子。连洗澡都怕水深。让他坐… |
| `comfort` | `assets/cn/voices/zhou_wife/comfort.wav` | ……你不像凶手。凶手不会还留在这里问话。  里正让你查——你要是真能查出来……老爷的文书都在房间桌上。你看吧。 |
| `ask_documents` | `assets/cn/voices/zhou_wife/ask_documents.wav` | 都在房间里。大人自己去看吧——遣散字据、货单都在桌上。  （她指了指房间的方向。） |

### 序章

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `opening_monologue_1` | `assets/cn/voices/_prologue/prologue_ferry/opening_monologue_1.wav` | 每逢阴雨，我便想起那条江。 |
| `opening_monologue_2` | `assets/cn/voices/_prologue/prologue_ferry/opening_monologue_2.wav` | 黑水，沉船，以及那些再也没能上岸的脸。 |
| `opening_monologue_3` | `assets/cn/voices/_prologue/prologue_ferry/opening_monologue_3.wav` | 那时候，我以为真相会让人好过一些。 |
| `opening_monologue_4` | `assets/cn/voices/_prologue/prologue_ferry/opening_monologue_4.wav` | 后来才明白——  有些真相，比谎言更冷。 |
| `time_card_opening` | `assets/cn/voices/_prologue/prologue_ferry/time_card_opening.wav` | 万历廿二年 · 腊月 · 亥时 |
| `cabin_prologue_1` | `assets/cn/voices/_prologue/prologue_ferry/cabin_prologue_1.wav` | 我叫陆昭，御史台巡按。奉旨巡查南直隶，途经此地。 ⚠️【待重录】CANON：陆昭是隐秘御史，不应在船上公开身份。此处应改为书生自我介绍。 |
| `cabin_prologue_2` | `assets/cn/voices/_prologue/prologue_ferry/cabin_prologue_2.wav` | 这条渡船，是平水驿驿丞推荐的。说是'夜船半日便到'。 |
| `cabin_prologue_3` | `assets/cn/voices/_prologue/prologue_ferry/cabin_prologue_3.wav` | 船舱里还有三个人：一个布商和他的仆从，还有一个船家。外面下着雨，江面漆黑。 |
| `cabin_free_explore` | `assets/cn/voices/_prologue/prologue_ferry/cabin_free_explore.wav` | 【操作说明】可以在船舱内自由走动，与三位乘客交谈。 |
| `cabin_1` | `assets/cn/voices/_prologue/prologue_ferry/cabin_1.wav` | 黑暗。  身体猛烈一震——像是什么东西从脚底断裂了。  冰冷的水从某处涌上来，没过脚踝。 |
| `cabin_2` | `assets/cn/voices/_prologue/prologue_ferry/cabin_2.wav` | 陆昭从睡梦中惊醒。船舱在晃——不是正常的颠簸，是倾斜。  水已经到了小腿。 |
| `cabin_3` | `assets/cn/voices/_prologue/prologue_ferry/cabin_3.wav` | 船在沉。 |
| `shore_1` | `assets/cn/voices/_prologue/prologue_ferry/shore_1.wav` | ……  「喂！喂！你还活着吗！」  有人在拖拽你的身体。沙砾磨蹭后背。冰冷中有一双温热的手在拍你的脸。 |
| `shore_2` | `assets/cn/voices/_prologue/prologue_ferry/shore_2.wav` | 别死啊你！我好不容易把你拖上来的！咳出来！把水咳出来！ |
| `shore_3` | `assets/cn/voices/_prologue/prologue_ferry/shore_3.wav` | 你剧烈咳嗽，吐出一口江水。  睁开眼——冬雨中一张年轻女子的脸，湿漉漉的碎发贴在额头上，神情焦急。  她穿着一身利落的暗蓝劲装，背上斜挎着信筒。 |
| `shore_4` | `assets/cn/voices/_prologue/prologue_ferry/shore_4.wav` | 活了活了！你可吓死本姑娘了——大半夜的看见江里漂过来个人，还以为是……  能说话吗？你叫什么？怎么掉水里的？ |
| `shore_5a` | `assets/cn/voices/_prologue/prologue_ferry/shore_5a.wav` | 船沉了？！我说呢——刚才江上轰隆一声巨响！我以为是打雷……  你等着，别动。客栈就在那边，本姑娘扶你过去。 |
| `shore_5a_name` | `assets/cn/voices/_prologue/prologue_ferry/shore_5a_name.wav` | 对了——我叫凌瑶。金鳞镖局首席镖师。  别的等进了屋再说——你再淋下去非冻成冰棍不可。走！ ⚠️【待重录】 |
| `shore_5b` | `assets/cn/voices/_prologue/prologue_ferry/shore_5b.wav` | 我叫凌瑶！金鳞镖局首席镖师！押送急件路过石矶渡，等天亮过江的。  别问了别问了，你现在浑身冰的跟死鱼似的——走，客栈就在那边！ ⚠️【待重录】 |
| `inn_arrival` | `assets/cn/voices/_prologue/prologue_ferry/inn_arrival.wav` | 石矶渡。客栈。  凌瑶半扶半拖着你进了门。掌柜给了热水和干衣服。  你坐在火堆旁，寒意还没完全退去。外面的雨越下越大。 |
| `inn_warm_1` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_1.wav` | （端来一碗姜汤）喝。别跟我客气。  你刚才说船沉了——那船上还有别人吗？ |
| `inn_warm_2` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_2.wav` | 有。一个布商，和他的仆从。还有船家。  我搭的他们的渡船。夜里出发，说是半个时辰就到对岸。  ……半个时辰。 |
| `inn_warm_3` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_3.wav` | 半个时辰……那现在都两个时辰了。他们没上岸？  那……那他们是不是—— |
| `inn_warm_3b` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_3b.wav` | 不知道。天亮了才能看清。 |
| `inn_warm_4` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_4.wav` | 你盯着火堆出了会儿神。脑海里还是那条船——黑暗中的水、冰冷的触感…… |
| `inn_warm_4_observed` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_4_observed.wav` | （握紧了拳头）有人想让那条船沉下去。连我在内。 |
| `inn_warm_4_not_observed` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_4_not_observed.wav` | （盯着火堆）如果是人为的——那我也在被害者的名单上。 |
| `inn_warm_5a_certain` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_5a_certain.wav` | 是人为凿开的。我确定。  黑暗中摸到的那个边缘——太整齐了。木头断裂不是那个手感。 |
| `inn_warm_5a` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_5a.wav` | 凿、凿的？！你是说有人故意把船弄沉？！  ……那你岂不是差点被人害了？！ |
| `inn_warm_5b` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_5b.wav` | ……你那个表情可不像记错了的人。  大人——不对，陆昭——你是不是觉得那船有问题？ |
| `inn_warm_6` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_6.wav` | 天亮再说。先休息。  ……多谢。命是你救回来的。这份情，陆昭记着。 |
| `inn_warm_7` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_7.wav` | （摆摆手）行侠仗义嘛！本姑娘虽然是送信的，但见死不救可不是金鳞镖局的作风！  你先歇着。我也累得不行了……明天再说。 |
| `inn_night` | `assets/cn/voices/_prologue/prologue_ferry/inn_night.wav` | 雨声如鼓。你躺在客栈的硬板床上，盯着天花板。  船底那个洞，在脑海里挥之不去。 |
| `inn_night_injury_check` | `assets/cn/voices/_prologue/prologue_ferry/inn_night_injury_check.wav` | 你试着握拳——掌心火辣辣地疼。撬天窗时磨破的皮还在渗血。  但至少手指还能动。命是捡回来了。 |
| `day2_dawn` | `assets/cn/voices/_prologue/prologue_ferry/day2_dawn.wav` | 翌日。黎明。  雨小了些，但天色依旧灰暗。  你起身时，客栈掌柜正在擦桌子。他瞥了你一眼，像是看新闻一样随口说—— |
| `day2_dawn_innkeeper` | `assets/cn/voices/_prologue/prologue_ferry/day2_dawn_innkeeper.wav` | 昨晚翻船——你知道吧？就你那条。后来又冲上来两个人，一个仆从、一个船家。都没死。 |
| `day2_dawn_commotion` | `assets/cn/voices/_prologue/prologue_ferry/day2_dawn_commotion.wav` | 话音未落，渡口方向传来嘈杂的人声。有人在喊。 |
| `day2_body_1` | `assets/cn/voices/_prologue/prologue_ferry/day2_body_1.wav` | （急匆匆跑进来）陆昭！快来！码头那边——有人被冲上来了！ |
| `day2_body_2` | `assets/cn/voices/_prologue/prologue_ferry/day2_body_2.wav` | 码头下游的浅滩。  一具尸体面朝下，半截身子还泡在浑黄的水里。围观的人站了一圈，没人敢上前。 |
| `day2_body_3` | `assets/cn/voices/_prologue/prologue_ferry/day2_body_3.wav` | （捂住嘴）这是……你昨晚说的同船那个人？ |
| `day2_body_4` | `assets/cn/voices/_prologue/prologue_ferry/day2_body_4.wav` | 周德茂。布商。昨夜跟我说过几句话——带着仆从阿贵，要过江进货。  ……他死了。而阿贵和老范都活着。 |
| `day2_body_5` | `assets/cn/voices/_prologue/prologue_ferry/day2_body_5.wav` | 正在此时——一个披头散发的女人从人群中冲出来，扑倒在尸体旁。  哭声尖厉，像是被刀剜了一样。 |
| `day2_zhou_1` | `assets/cn/voices/_prologue/prologue_ferry/day2_zhou_1.wav` | 老爷！老爷——！  （猛地抬头）你——！你是跟他同船的！ |
| `day2_zhou_accuse_1` | `assets/cn/voices/_prologue/prologue_ferry/day2_zhou_accuse_1.wav` | 同船的人——他死了，你活着！  （扑过来抓住你衣领）上船的时候你连船钱都付不起，还是我家老爷替你垫的！五十两货银——钱呢？！你就是图财害命！！ |
| `day2_agui_appears` | `assets/cn/voices/_prologue/prologue_ferry/day2_agui_appears.wav` | 人群外围，一个穿着素色布衣的年轻男子缩着肩膀挤了进来。  是阿贵——周德茂的随行仆从，眼圈通红，嘴唇还在微微颤抖。 |
| `day2_agui_1` | `assets/cn/voices/_prologue/prologue_ferry/day2_agui_1.wav` | 夫人……老爷他……  昨晚三更刚过，我睡不着起来解手，看见这位爷……蹲在船底舱口那边。 |
| `day2_agui_2` | `assets/cn/voices/_prologue/prologue_ferry/day2_agui_2.wav` | （抬头）还有一件事——船沉的时候，我和船家都被困在舱里，门被货物堵死了！我拍了半天门才找到路爬出来！ |
| `day2_accused_silence` | `assets/cn/voices/_prologue/prologue_ferry/day2_accused_silence.wav` | 你想辩解——但几十道目光像钉子一样钉在你身上。周氏的哭声尖厉刺耳。  铁器？凶器？你张了张嘴，一时间竟说不出话来。 |
| `day2_zhou_accuse_3` | `assets/cn/voices/_prologue/prologue_ferry/day2_zhou_accuse_3.wav` | 你还想狡辩？！同船的人只有你活着！只有你从天窗跑了！不是你是谁？！  御史？！谁信！有凭证你拿出来啊！！ |
| `day2_lizheng_appear` | `assets/cn/voices/_prologue/prologue_ferry/day2_lizheng_appear.wav` | 围观人群骚动。一个圆脸中年人从人群中挤出来——是渡口的里正。  他扫了一眼尸体，又打量了你几眼。表情不像同情，更像在盘算。 |
| `day2_lizheng_1` | `assets/cn/voices/_prologue/prologue_ferry/day2_lizheng_1.wav` | 都别吵！——出了人命我这个里正管不了，得等县里来人。  （转向你）你说你是御史？有官印文书吗？ |
| `day2_lizheng_2` | `assets/cn/voices/_prologue/prologue_ferry/day2_lizheng_2.wav` | 官印落在了船舱里。连同行李、文书——全沉在江底了。  （自嘲地扯了扯身上借来的干衣服）你看我现在这样，确实不像个御史。 |
| `day2_lizheng_3` | `assets/cn/voices/_prologue/prologue_ferry/day2_lizheng_3.wav` | （摇头）没有凭证，你说什么都是空口白话。  我且问你一件事——翻船的地方在江心，离这岸至少三四里水路。你一个当官的文人——怎么游过来的？ |
| `day2_lizheng_4` | `assets/cn/voices/_prologue/prologue_ferry/day2_lizheng_4.wav` | 你——！放屁！本姑娘是金鳞镖局的首席镖师！住在码头客栈！听见江上炸响才跑出去的！  他被我拖上来的时候都快断气了！昏迷了大半个时辰才醒！你管这叫'活蹦乱跳'？！ ⚠️【待重录】 |
| `day2_lizheng_5` | `assets/cn/voices/_prologue/prologue_ferry/day2_lizheng_5.wav` | 姑娘，你说得再凶——你认识他吗？昨天之前见过他吗？  （转向你）没有官印、搭船没付钱、铁器在手、知道天窗逃生路线——你脱不了嫌疑。 |
| `day2_framed_resolve` | `assets/cn/voices/_prologue/prologue_ferry/day2_framed_resolve.wav` | 人群缓缓散开。有人回头看你，像看一个已经定了罪的人。  周氏被人扶走了，但她的哭喊声还在码头上空回荡。 |
| `day2_lingyao_resolve` | `assets/cn/voices/_prologue/prologue_ferry/day2_lingyao_resolve.wav` | 陆昭——你信我，我没有跟任何人串通。我就是听到响动跑出来的……  ……这帮人都疯了。你打算怎么办？ |
| `day2_lu_resolve` | `assets/cn/voices/_prologue/prologue_ferry/day2_lu_resolve.wav` | ……他们的指控，表面上全都说得通。这不是巧合——有人在布局，把我框进去。 |
| `day2_lingyao_join_framed` | `assets/cn/voices/_prologue/prologue_ferry/day2_lingyao_join_framed.wav` | 对啊！那个阿贵说自己不会游水——那他怎么从翻了的船里爬出来的？！老范更离谱——跑了二十年的航道，偏偏走上暗礁？！ |
| `day2_start_game` | `assets/cn/voices/_prologue/prologue_ferry/day2_start_game.wav` | 【操作说明】  • 右侧菜单：地图 / 对话 / 移动 / 探索 / 笔记本 / 讨论 • 「讨论」：随时与凌瑶交流，获取下一步方向 • 跨地点移动花费一个时… |
| `day2_crowd_murmur` | `assets/cn/voices/_prologue/prologue_ferry/day2_crowd_murmur.wav` | 围观人群一阵骚动。有人低声议论：  「铁器打人……说得通啊……人被打晕了当然游不了……」 「搭船没付钱还带着铁家伙——不是图财害命是什么？」 |
| `day2_lizheng_3b` | `assets/cn/voices/_prologue/prologue_ferry/day2_lizheng_3b.wav` | 码头王大爷说，翻船前半刻钟，南岸就有人打着灯笼在走。船一沉，那人就朝下游跑。  （指了指凌瑶）你这位姑娘，恰好在那个时辰、那个地方把你捞起来的——这也太巧了吧？ |
| `cabin_flood` | `assets/cn/voices/_prologue/prologue_ferry/cabin_flood.wav` | 舱门推不开——外面有货物压着。水已经没过膝盖，还在涨。  昏暗中能看到：头顶一扇天窗透进雨夜的微光。舱壁上挂着一根铁撬棍。角落有几只木箱正在水中漂浮。 |
| `cabin_discover_hole` | `assets/cn/voices/_prologue/prologue_ferry/cabin_discover_hole.wav` | 水涌得太急了——从脚下某处喷上来的。你咬牙蹲入刺骨的冰水中，双手摸索船底。  找到了。 |
| `cabin_act` | `assets/cn/voices/_prologue/prologue_ferry/cabin_act.wav` | 水到了腰。没时间了。  你扯下舱壁上的铁撬棍，把漂起来的木箱踹到天窗正下方——踩上去。 |
| `cabin_break_out` | `assets/cn/voices/_prologue/prologue_ferry/cabin_break_out.wav` | 咔嚓！  锁扣断裂，天窗向外弹开。冷雨浇在脸上。  你扔掉铁撬，双手撑住窗框，一个翻身钻了出去—— |
| `cabin_deck` | `assets/cn/voices/_prologue/prologue_ferry/cabin_deck.wav` | 船已经大半沉入水中。甲板在脚下剧烈倾斜。  雨幕如帘，江面漆黑一片。远处有模糊的岸线。  船体发出一声像骨头折断的巨响——彻底沉没。 |
| `cabin_swim` | `assets/cn/voices/_prologue/prologue_ferry/cabin_swim.wav` | 你抓住一块断裂的船板，在冰冷的江水中拼命向岸边划去。  四肢已经麻木。冬夜的江水像千万根针同时扎进皮肉里。 |
| `day2_lu_resolve_b` | `assets/cn/voices/_prologue/prologue_ferry/day2_lu_resolve_b.wav` | 谁提前准备了'活下来的方式'——谁才是真正的共犯。 |
| `day2_lu_resolve_c` | `assets/cn/voices/_prologue/prologue_ferry/day2_lu_resolve_c.wav` | 我什么都没准备。我差点死在那条船里。  而那个'不会游水'的仆从——和那个跑了二十年船的老船家——他们是怎么活得那么从容的？ |
| `day2_lizheng_5b` | `assets/cn/voices/_prologue/prologue_ferry/day2_lizheng_5b.wav` | （竖起两根指头）两天。这雨两天内停不了，反正谁也走不了。两天之内——要么你找到真凶，要么等县衙的人来处置你。 |
| `day2_agui_2b` | `assets/cn/voices/_prologue/prologue_ferry/day2_agui_2b.wav` | 他用铁器打了老爷，然后从天窗逃走了！那扇天窗平时用铁锁锁死——他怎么打开的？就是用那把凶器撬的！  他早就想好了——先杀人，再从天窗跑！连逃跑的路线都准备好了！ |
| `day2_lingyao_join_b` | `assets/cn/voices/_prologue/prologue_ferry/day2_lingyao_join_b.wav` | （一拍巴掌）好！两天就两天——走，先去查那条破船！我昨晚在码头还看见几个人鬼鬼祟祟说话呢！ |
| `day2_agui_1b` | `assets/cn/voices/_prologue/prologue_ferry/day2_agui_1b.wav` | 他手里好像攥着个铁家伙——我当时没多想，以为是什么随身的物件……现在想来…… |
| `day2_agui_1c` | `assets/cn/voices/_prologue/prologue_ferry/day2_agui_1c.wav` | 那个铁家伙——一定是凶器！他肯定是在舱里趁老爷不备，用铁器砸了老爷！老爷被打晕了才落水的！我亲眼看到他蹲在舱口拿着那东西！ |
| `inn_warm_4_not_observed_a` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_4_not_observed_a.wav` | 有件事让我在意。水是从脚底下涌上来的——灌得很急，像是从一个豁口里喷出来的。  当时来不及细看。但那个位置、那个速度……不像是撞礁裂开的。 |
| `inn_warm_4_observed_a` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_4_observed_a.wav` | 有件事。船沉的时候，我蹲下去摸过涌水的位置。  是一个方形的洞——边缘很整齐。不是撞出来的。是凿的。 |
| `day2_framed_resolve_b` | `assets/cn/voices/_prologue/prologue_ferry/day2_framed_resolve_b.wav` | 阿贵低着头跟在人群后面走了——走之前，他飞快地瞥了你一眼。那一眼里有东西，不像悲伤。 |
| `inn_night_b` | `assets/cn/voices/_prologue/prologue_ferry/inn_night_b.wav` | 还有一件事——上船前，平水驿的驿丞说：「大人何必走陆路翻山，夜船半日便到。」  ……为什么偏偏建议我搭那条船？ |
| `day2_dawn_innkeeper_b` | `assets/cn/voices/_prologue/prologue_ferry/day2_dawn_innkeeper_b.wav` | 仆从在后头柴房歇着呢，船家住了隔壁。那个布商的婆娘一早也赶来了，在码头哭天喊地…… |
| `day2_body_2b` | `assets/cn/voices/_prologue/prologue_ferry/day2_body_2b.wav` | 你走过去，蹲下翻过尸体——  是昨夜同船的那个布商。面色青紫，已经僵了。 |
| `cabin_discover_hole_b` | `assets/cn/voices/_prologue/prologue_ferry/cabin_discover_hole_b.wav` | 一个方形的洞口。边缘整齐——不是撞击。是凿出来的。  有人故意凿穿了这条船。 |
| `day2_crowd_murmur_b` | `assets/cn/voices/_prologue/prologue_ferry/day2_crowd_murmur_b.wav` | 目光像针一样扎过来。 |
| `day2_body_4b` | `assets/cn/voices/_prologue/prologue_ferry/day2_body_4b.wav` | 三个人落水，只有不会游泳的那个死了。 |
| `inn_warm_5a_certain_b` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_5a_certain_b.wav` | 也就是说——今晚有人想杀我。或者，想杀船上所有人。 |
| `cabin_swim_b` | `assets/cn/voices/_prologue/prologue_ferry/cabin_swim_b.wav` | 意识开始模糊。雨打在眼睛上，什么都看不清了—— |
| `cabin_act_b` | `assets/cn/voices/_prologue/prologue_ferry/cabin_act_b.wav` | 头顶的天窗锁扣锈迹斑斑。你举起铁撬，对准锁扣——全力一撬。 |
| `inn_change_clothes` | `assets/cn/voices/_prologue/prologue_ferry/inn_change_clothes.wav` | 你换上了掌柜找来的旧棉袍——宽大了些，但至少是干的。  没了乌纱帽和官袍，铜镜里只剩一个落魄书生的面孔。 |
| `day2_lu_resolve_narration` | `assets/cn/voices/_prologue/prologue_ferry/day2_lu_resolve_narration.wav` | 陆昭沉默了很长时间。他的手还在微微发抖——不是冷的。是昨晚在黑水里挣扎时积攒的东西，到现在还没完全退下去。 |
| `inn_warm_3b_narration` | `assets/cn/voices/_prologue/prologue_ferry/inn_warm_3b_narration.wav` | 他的手指不自觉地攥紧了袖口。衣服还是湿的，冰凉贴在皮肤上，像那舱里的水。 |

### 日程事件

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `evt_cabin_sleep_0` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_0.wav` | 夜深了。你躺在船板上，听着雨声，渐渐入睡。 |
| `evt_cabin_sleep_1` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_1.wav` | 黑暗中，身体猛烈一震。冰冷的水从脚底涌上来，船舱正在倾斜。 |
| `evt_cabin_sleep_2` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_2.wav` | 船在沉。 |
| `evt_cabin_sleep_3` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_3.wav` | 你咬牙蹲入刺骨的冰水中，双手摸索船底。一个方形洞口，边缘整齐——不是撞击，是凿出来的。 |
| `evt_cabin_sleep_4` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_4.wav` | 你扯下舱壁上的铁撬棍，踩上漂起的木箱，撬开天窗。下一刻，船体发出巨响，彻底沉入黑水。 |
| `evt_cabin_sleep_5` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_5.wav` | 「喂！喂！你还活着吗！」有人把你从江边湿冷的沙砾上拖起来。 |
| `evt_cabin_sleep_6` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_6.wav` | 别死啊你！我好不容易把你拖上来的！咳出来！把水咳出来！ |
| `evt_cabin_sleep_7` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_7.wav` | 我叫凌瑶，金鳞镖局首席镖师。别的等进屋再说——你再淋下去非冻成冰棍不可！ |
| `evt_cabin_sleep_8` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_8.wav` | 清晨，码头下游的浅滩发现了周德茂的尸体。人群围了上来，哭声、雨声和窃窃私语混成一片。 |
| `evt_cabin_sleep_9` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_9.wav` | 就是他！一个来路不明的外乡人，图财害命！ |
| `evt_cabin_sleep_10` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_10.wav` | 昨晚三更刚过，我看见这位爷蹲在船底舱口那边，手里好像攥着个铁家伙…… |
| `evt_cabin_sleep_11` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_11.wav` | 周娘子莫急。人命案最怕情急乱判——但若有证人、有动机、有物证，也不能因他自称御史就轻放。 |
| `evt_cabin_sleep_12` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_12.wav` | 你说你是御史？有官印文书吗？ |
| `evt_cabin_sleep_13` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_13.wav` | 官印落在船舱里。连同行李、文书，全沉在江底了。 |
| `evt_cabin_sleep_14` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_14.wav` | 没有官印，便只能先按眼前证据说话。陆公子，您若清白，就请当堂自证。 |
| `evt_cabin_sleep_15` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_15.wav` | 他被我拖上来的时候都快断气了！昏迷了大半个时辰才醒！ |
| `evt_cabin_sleep_16` | `assets/cn/voices/_events/prologue_ferry/evt_cabin_sleep_16.wav` | 既然你说冤枉——那就当面对质！王大爷，你把那天夜里看到的，再说一遍！ |
| `evt_hull_discovered_0` | `assets/cn/voices/_events/prologue_ferry/evt_hull_discovered_0.wav` | 船底那个洞——边缘整齐，凿痕清晰。这不是暗礁撞出来的。 |
| `evt_hull_discovered_1` | `assets/cn/voices/_events/prologue_ferry/evt_hull_discovered_1.wav` | 等等……这是被人凿开的？！那不是翻船——是有人故意弄沉的！ |
| `evt_hull_discovered_2` | `assets/cn/voices/_events/prologue_ferry/evt_hull_discovered_2.wav` | 那是老范的船！只有他能在自己船上动这种手脚！那个赌鬼——他要弄死人捞钱！ |
| `evt_hull_discovered_3` | `assets/cn/voices/_events/prologue_ferry/evt_hull_discovered_3.wav` | 是人为。但谁动的手，现在还不能下结论。继续查。 |
| `evt_bladder_found_0` | `assets/cn/voices/_events/prologue_ferry/evt_bladder_found_0.wav` | 粗布包袱，和阿贵在客栈用的是同一种。里面是一只充了气的牛皮浮囊。 |
| `evt_bladder_found_1` | `assets/cn/voices/_events/prologue_ferry/evt_bladder_found_1.wav` | 等等……这是阿贵的包袱？浮囊？他一个不会游泳的仆从——为什么会有这种东西？！ |
| `evt_bladder_found_2` | `assets/cn/voices/_events/prologue_ferry/evt_bladder_found_2.wav` | 而且被江水冲到了这里。他提前把包袱扔出船外——除非他知道自己会落水，需要靠它活命。 |
| `evt_bladder_found_3` | `assets/cn/voices/_events/prologue_ferry/evt_bladder_found_3.wav` | 陆大人！如果阿贵也提前知道船要沉——那就不只是老范一个人的事了！他们……他们是一伙的？！ |
| `evt_bladder_found_4` | `assets/cn/voices/_events/prologue_ferry/evt_bladder_found_4.wav` | 看起来……这案子比我们以为的要复杂。 |
| `evt_dismissal_revealed_0` | `assets/cn/voices/_events/prologue_ferry/evt_dismissal_revealed_0.wav` | 「兹遣仆人阿贵，给银二两，各不相欠。」 |
| `evt_dismissal_revealed_1` | `assets/cn/voices/_events/prologue_ferry/evt_dismissal_revealed_1.wav` | 二两银子？！跟了十二年就给二两？这也太…… |
| `evt_dismissal_revealed_2` | `assets/cn/voices/_events/prologue_ferry/evt_dismissal_revealed_2.wav` | 十二年青春换来一纸遣散。换了谁都会恨。 |
| `evt_dismissal_revealed_3` | `assets/cn/voices/_events/prologue_ferry/evt_dismissal_revealed_3.wav` | 所以……阿贵的动机有了。他恨那个主人。 |
| `evt_gambling_debt_0` | `assets/cn/voices/_events/prologue_ferry/evt_gambling_debt_0.wav` | 四十二两赌债。腊月底还不上就断指。 |
| `evt_gambling_debt_1` | `assets/cn/voices/_events/prologue_ferry/evt_gambling_debt_1.wav` | 四十二两！怪不得他铤而走险……这已经不是一般欠钱了，是要命的债！ |
| `evt_gambling_debt_2` | `assets/cn/voices/_events/prologue_ferry/evt_gambling_debt_2.wav` | 阿贵许给他一半货银——二十五两。加上船家的活计还能接着干。对一个走投无路的人来说，这买卖合算。 |
| `evt_gambling_debt_3` | `assets/cn/voices/_events/prologue_ferry/evt_gambling_debt_3.wav` | 一条人命换四十二两银子…… |
| `evt_quiet_moment_0` | `assets/cn/voices/_events/prologue_ferry/evt_quiet_moment_0.wav` | 陆大人。 |
| `evt_quiet_moment_1` | `assets/cn/voices/_events/prologue_ferry/evt_quiet_moment_1.wav` | 凌瑶不知什么时候买了两个馒头，热气腾腾地递过来。 |
| `evt_quiet_moment_2` | `assets/cn/voices/_events/prologue_ferry/evt_quiet_moment_2.wav` | 吃。你从昨晚到现在什么都没吃。 |
| `evt_quiet_moment_3` | `assets/cn/voices/_events/prologue_ferry/evt_quiet_moment_3.wav` | ……不饿。 |
| `evt_quiet_moment_4` | `assets/cn/voices/_events/prologue_ferry/evt_quiet_moment_4.wav` | 骗谁呢？你肚子刚才叫了两次我都听见了。堂堂巡按御史——饿得咕咕叫，像什么样子？ |
| `evt_quiet_moment_5` | `assets/cn/voices/_events/prologue_ferry/evt_quiet_moment_5.wav` | （接过来）……谢了。 |
| `evt_quiet_moment_6` | `assets/cn/voices/_events/prologue_ferry/evt_quiet_moment_6.wav` | （笑了一下）别客气。这顿算你欠我的——等案子结了请我吃顿好的。 |
| `evt_quiet_moment_7` | `assets/cn/voices/_events/prologue_ferry/evt_quiet_moment_7.wav` | 行。 |
| `evt_quiet_moment_8` | `assets/cn/voices/_events/prologue_ferry/evt_quiet_moment_8.wav` | 说好了啊！我记着呢！ |
| `evt_lizheng_pressure_0` | `assets/cn/voices/_events/prologue_ferry/evt_lizheng_pressure_0.wav` | （在门口探头）陆……陆大人？ |
| `evt_lizheng_pressure_1` | `assets/cn/voices/_events/prologue_ferry/evt_lizheng_pressure_1.wav` | 那个……县衙那边来信了。张县令说明日一早派人来接这案子。 |
| `evt_lizheng_pressure_2` | `assets/cn/voices/_events/prologue_ferry/evt_lizheng_pressure_2.wav` | 如果到时候大人还没有结论——那这个嫌疑……（犹豫地看着你） |
| `evt_lizheng_pressure_3` | `assets/cn/voices/_events/prologue_ferry/evt_lizheng_pressure_3.wav` | （低声）嘶——他在施压。再不抓住真凶，明天县衙来人就把你当嫌疑人带走了。 |
| `evt_lizheng_pressure_4` | `assets/cn/voices/_events/prologue_ferry/evt_lizheng_pressure_4.wav` | 我知道了。不会到那一步。 |
| `evt_lizheng_pressure_5` | `assets/cn/voices/_events/prologue_ferry/evt_lizheng_pressure_5.wav` | ……那、那小人先走了。大人加油啊。（溜了） |
| `evt_lizheng_pressure_6` | `assets/cn/voices/_events/prologue_ferry/evt_lizheng_pressure_6.wav` | 陆大人——时间不多了。证据够了就赶紧动手吧。 |
| `evt_confrontation_ready_0` | `assets/cn/voices/_events/prologue_ferry/evt_confrontation_ready_0.wav` | 陆大人！航道、验尸、船底破洞、浮囊、老范获救时间、阿贵遣散字据和赌债——对峙要用的证据链都齐了！ |
| `evt_confrontation_ready_1` | `assets/cn/voices/_events/prologue_ferry/evt_confrontation_ready_1.wav` | 这次不能只盯阿贵。先让老范把船和时间说清楚，再逼阿贵开口。 |
| `evt_confrontation_ready_2` | `assets/cn/voices/_events/prologue_ferry/evt_confrontation_ready_2.wav` | 好。是时候了。 |
| `evt_phase3_transition_0` | `assets/cn/voices/_events/prologue_ferry/evt_phase3_transition_0.wav` | 阿贵被两个帮工押进后院柴房。门闩落下的一刻，客栈大堂像被人抽走了声音。 |
| `evt_phase3_transition_1` | `assets/cn/voices/_events/prologue_ferry/evt_phase3_transition_1.wav` | 陆大人。先前是小人眼拙。从现在起，客栈上下听您调遣。 |
| `evt_phase3_transition_2` | `assets/cn/voices/_events/prologue_ferry/evt_phase3_transition_2.wav` | 你看——位置都变了。阿贵不在屋里了，老范那边也有人盯着，沈清月退回二楼房间。 |
| `evt_phase3_transition_3` | `assets/cn/voices/_events/prologue_ferry/evt_phase3_transition_3.wav` | 她没有跑。 |
| `evt_phase3_transition_4` | `assets/cn/voices/_events/prologue_ferry/evt_phase3_transition_4.wav` | 因为她觉得阿贵的口供不够。那我们就找她不能抵赖的东西。 |
| `evt_phase3_transition_5` | `assets/cn/voices/_events/prologue_ferry/evt_phase3_transition_5.wav` | 雨声压着屋檐。大堂的人不再看你像嫌犯，而是等着你下一个命令。 |
| `evt_bladder_meaning_changed_0` | `assets/cn/voices/_events/prologue_ferry/evt_bladder_meaning_changed_0.wav` | 陆昭重新捏起那只牛皮浮囊。缝线极细，针脚密得不像船工手里的粗活。 |
| `evt_bladder_meaning_changed_1` | `assets/cn/voices/_events/prologue_ferry/evt_bladder_meaning_changed_1.wav` | 等等——浮囊。咱们之前以为那是阿贵自己藏的退路。可他刚才说，连浮囊都是沈清月帮他买的。 |
| `evt_bladder_meaning_changed_2` | `assets/cn/voices/_events/prologue_ferry/evt_bladder_meaning_changed_2.wav` | 那件证物，从一开始就是她的指纹。我们之前看它的角度——错了。 |
| `evt_bladder_meaning_changed_3` | `assets/cn/voices/_events/prologue_ferry/evt_bladder_meaning_changed_3.wav` | 重新看。 |
| `evt_shen_evidence_ready_0` | `assets/cn/voices/_events/prologue_ferry/evt_shen_evidence_ready_0.wav` | 陆大人。五条证据——货银未沉、打捞目击、中间人、时间矛盾，还有毒囊残壳。全指向沈清月。 ⚠️【待重录】香囊→毒囊残壳 |
| `evt_shen_evidence_ready_1` | `assets/cn/voices/_events/prologue_ferry/evt_shen_evidence_ready_1.wav` | 够了吧？这次是真正的对手。你准备好了吗？ |
| `evt_shen_evidence_ready_2` | `assets/cn/voices/_events/prologue_ferry/evt_shen_evidence_ready_2.wav` | ……去吧。 |
| `evt_shen_evidence_ready_3` | `assets/cn/voices/_events/prologue_ferry/evt_shen_evidence_ready_3.wav` | （深吸一口气）好。这次跟阿贵不一样——她不会哭。不会慌。她会用逻辑咬你。 |
| `evt_shen_evidence_ready_4` | `assets/cn/voices/_events/prologue_ferry/evt_shen_evidence_ready_4.wav` | 但我在你旁边。有什么想法我会提醒你的。——走！ |
| `evt_case_partially_resolved_0` | `assets/cn/voices/_events/prologue_ferry/evt_case_partially_resolved_0.wav` | 阿贵和老范被押往县衙。沈清月撑伞离开客栈。雨还在下，像是什么都没发生过。 ⚠️【待重录】删除香囊引用 |
| `evt_case_partially_resolved_1` | `assets/cn/voices/_events/prologue_ferry/evt_case_partially_resolved_1.wav` | 大人……这个案子，算输了吗？ |
| `evt_case_partially_resolved_2` | `assets/cn/voices/_events/prologue_ferry/evt_case_partially_resolved_2.wav` | 推理没有输。证据输了。 |
| `evt_case_partially_resolved_3` | `assets/cn/voices/_events/prologue_ferry/evt_case_partially_resolved_3.wav` | 可我们明明知道是她。 |
| `evt_case_partially_resolved_4` | `assets/cn/voices/_events/prologue_ferry/evt_case_partially_resolved_4.wav` | 知道，不等于能定罪。她靠法律漏洞脱罪——草药遇淡水失活，过期残迹不算证据。 ⚠️【待重录】删除调包香囊，改为法理脱罪 |
| `evt_case_partially_resolved_5` | `assets/cn/voices/_events/prologue_ferry/evt_case_partially_resolved_5.wav` | （低声）那我们从哪里查？|
| `evt_case_partially_resolved_6` | `assets/cn/voices/_events/prologue_ferry/evt_case_partially_resolved_6.wav` | 官印。沉船后它不该只是一件丢失的东西。有人若碰过它，就会留下痕迹。这个案子还没完。 |

## 浔阳楼·夜雨红绸案 (`xunyang_pavilion`)

缺失 62 条。

### 序章

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `scene1a` | `assets/cn/voices/_prologue/xunyang_pavilion/scene1a.wav` | 他改走水路，顺江而下。  冬去春来。江上的雾渐渐散了，岸边的柳枝冒出第一点新绿。连绵的阴雨终于停了——  只有凌瑶还跟在身后。 |
| `scene1b` | `assets/cn/voices/_prologue/xunyang_pavilion/scene1b.wav` | 万历二十三年，三月。  春寒料峭，江南细雨如丝。  江面上薄雾微茫，远处一座飞檐楼阁的轮廓隐约浮现在雾气之中——浔阳楼。 |
| `scene1c` | `assets/cn/voices/_prologue/xunyang_pavilion/scene1c.wav` | 船靠码头。浔阳楼灯火通明，丝竹声隐隐传来。 |
| `scene2a` | `assets/cn/voices/_prologue/xunyang_pavilion/scene2a.wav` | （趴在栏杆上看江，回头）陆大人！这楼也太气派了吧！比咱们石矶渡那个破客栈强了一万倍！ |
| `scene2b` | `assets/cn/voices/_prologue/xunyang_pavilion/scene2b.wav` | ……石矶渡案结了，你的信还没送到？ |
| `scene2c` | `assets/cn/voices/_prologue/xunyang_pavilion/scene2c.wav` | 别提了！那场大雨把官道全泡烂了，前两天的驿马都停了。我寻思反正走不了，不如跟着您再跑一趟——上回查案还挺有意思的！  ……虽然差点被阿贵那家伙骗了。 |
| `scene2d` | `assets/cn/voices/_prologue/xunyang_pavilion/scene2d.wav` | 有意思。  我只是路过借宿一夜，明日继续南下。 |
| `scene2e` | `assets/cn/voices/_prologue/xunyang_pavilion/scene2e.wav` | 好好好，路过路过。那今晚好歹能睡个像样的床了吧？本姑娘上回在渡口客栈那床板上睡了一夜，腰到现在还酸呢！ |
| `scene3b` | `assets/cn/voices/_prologue/xunyang_pavilion/scene3b.wav` | （小声）弹琵琶的那位好漂亮！听说是这儿的头牌，叫什么来着…… |
| `scene3c` | `assets/cn/voices/_prologue/xunyang_pavilion/scene3c.wav` | 秋菱。浔阳楼当家花魁。  ……走吧，上楼。明日一早还要赶路。 |
| `scene3d` | `assets/cn/voices/_prologue/xunyang_pavilion/scene3d.wav` | 切，您就不能坐下来听一曲吗？反正明天才走——  行行行，走就走。大人的话就是圣旨嘛。 |
| `scene4b` | `assets/cn/voices/_prologue/xunyang_pavilion/scene4b.wav` | 然后——  一声闷响。  从楼下传来。沉闷，像是什么重物落地。紧接着是一声短促的惊叫，然后又安静了。 |
| `scene4c` | `assets/cn/voices/_prologue/xunyang_pavilion/scene4c.wav` | （猛然推门进来，衣裳都没披好）陆大人！楼下出事了！ |
| `scene4d` | `assets/cn/voices/_prologue/xunyang_pavilion/scene4d.wav` | （已经拿起外袍）走。 |
| `scene5b` | `assets/cn/voices/_prologue/xunyang_pavilion/scene5b.wav` | （捂住嘴）这是……刚才那个弹琵琶的姑娘？！她怎么从楼上—— |
| `scene5c` | `assets/cn/voices/_prologue/xunyang_pavilion/scene5c.wav` | （蹲下，沉默地检视）…… |
| `scene5d` | `assets/cn/voices/_prologue/xunyang_pavilion/scene5d.wav` | 他看了很久。先看手——指甲缝干净，手心却攥着一段红绸。再看颈——绸带勒痕与坠落伤不一致。  最后他捡起红绸的一端，对着灯笼细看。 |
| `scene5e` | `assets/cn/voices/_prologue/xunyang_pavilion/scene5e.wav` | 断口是横向的。  如果她自己抓着栏杆失足，受力方向应该是纵向——手往下滑，绸带竖着断。但这个断口……是从背后被人往斜下方拽断的。 |
| `scene5f` | `assets/cn/voices/_prologue/xunyang_pavilion/scene5f.wav` | 您是说……不是失足？  是被人……从后面拽下来的？ |
| `scene5g` | `assets/cn/voices/_prologue/xunyang_pavilion/scene5g.wav` | 还不能确定。但这红绸的断口方向——自己抓栏不会留这种痕迹。  （站起来，环顾四周）  后院通向正厅、江畔水阁，还有阁楼的楼梯。案发时楼里至少有五六个人。  有… |
| `scene6b` | `assets/cn/voices/_prologue/xunyang_pavilion/scene6b.wav` | 浔阳楼花魁深夜凭栏，醉后失足——陆大人，你看这还有别的说法吗？  阁楼上酒杯翻了一桌，人又是从三楼落下来的。老夫判了二十年的案，这种事见得多了。 |
| `scene6c` | `assets/cn/voices/_prologue/xunyang_pavilion/scene6c.wav` | 大人可看过红绸断口的方向？ |
| `scene6d` | `assets/cn/voices/_prologue/xunyang_pavilion/scene6d.wav` | 断口？断口能说明什么？喝醉了的人抓什么都可能断。陆大人，你是巡按御史，不是仵作。这案子本府自理即可。 |
| `scene6e` | `assets/cn/voices/_prologue/xunyang_pavilion/scene6e.wav` | 鲁知府拂袖而去，留下'醉酒失足'四字结案稿。  陆昭看着他的背影，又低头看了看青石板上那段红绸。  雨还在下。红绸的一端浸在雨水里，像血一样漫开。 |
| `scene7` | `assets/cn/voices/_prologue/xunyang_pavilion/scene7.wav` | （小声，气鼓鼓）醉酒失足？！那红绸断口明明不对！本姑娘虽然不懂什么横向纵向——但那个知府大人看都没仔细看就拍板了！ |
| `scene7b` | `assets/cn/voices/_prologue/xunyang_pavilion/scene7b.wav` | ……所以，这案子我接了。 |
| `scene7c` | `assets/cn/voices/_prologue/xunyang_pavilion/scene7c.wav` | 又来了！您一句'我接了'，本姑娘就又多了几天苦差事是吧！  （顿了顿，叹气）  不过……上回在石矶渡，要不是本姑娘看见船家半夜鬼鬼祟祟，您也查不下去。这回我又… |
| `scene7d` | `assets/cn/voices/_prologue/xunyang_pavilion/scene7d.wav` | 三天。结案稿发还京之前，我要查出真相。  浔阳楼里的人都还在。先把他们的话听一遍。 |
| `scene7e` | `assets/cn/voices/_prologue/xunyang_pavilion/scene7e.wav` | 明白！本姑娘负责竖耳朵！上回在石矶渡好歹还摸出门道了——坠楼嘛，总比什么凿船沉水的弯弯绕绕好懂吧？  ……对了陆大人，这回能不能别什么都'嗯'一个字就打发我？ |
| `scene7f` | `assets/cn/voices/_prologue/xunyang_pavilion/scene7f.wav` | ……嗯。 |
| `scene7g` | `assets/cn/voices/_prologue/xunyang_pavilion/scene7g.wav` | ！！您故意的吧！！ |

### 日程事件

| node_id | 预期路径 | 文本预览 |
|---------|---------|---------|
| `evt_redemption_revealed_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_redemption_revealed_2.wav` | 问题不在谁愿意赎她——在谁不愿意让她走。 |
| `evt_redemption_revealed_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_redemption_revealed_3.wav` | ……浔阳楼的头牌要走了，那楼里的生意不得砍一大半？青姐她—— |
| `evt_redemption_revealed_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_redemption_revealed_4.wav` | 先不下结论。但这条线很关键。 |
| `evt_encounter_dock_figure_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_figure_4.wav` | （气喘吁吁赶上来）大人——！刚才那人……！您看清了吗！ |
| `evt_encounter_dock_figure_5` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_figure_5.wav` | 只看到身形。兜帽遮了脸。 |
| `evt_encounter_dock_figure_6` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_figure_6.wav` | 那人身高……中等偏矮。步子碎，不像男人。还有——那包袱丢进江里了！肯定是在销毁什么！ |
| `evt_encounter_dock_figure_7` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_dock_figure_7.wav` | 记住了。明天去问问刘船家，他夜里泊在这一带。 |
| `evt_encounter_chamber_intruder_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_intruder_3.wav` | （低声）案发后还有人回来翻东西——这人胆子也太大了吧！ |
| `evt_encounter_chamber_intruder_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_intruder_4.wav` | 说明有东西比命案更让他怕。 |
| `evt_encounter_chamber_intruder_5` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_intruder_5.wav` | 比命案还怕……什么东西会比杀人更怕被发现？ |
| `evt_encounter_chamber_intruder_6` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_chamber_intruder_6.wav` | 动机。 |
| `evt_encounter_convent_visitor_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_visitor_4.wav` | ……又是兜帽！跟水阁那次一样！同一个人？ |
| `evt_encounter_convent_visitor_5` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_visitor_5.wav` | 很可能。这人在打探目击证人的口供——怕无尘师太说出什么。 |
| `evt_encounter_convent_visitor_6` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_visitor_6.wav` | 那就是凶手在灭口前先探底！师太那边会不会有危险？ |
| `evt_encounter_convent_visitor_7` | `assets/cn/voices/_events/xunyang_pavilion/evt_encounter_convent_visitor_7.wav` | ……明天去提醒一声。 |
| `evt_silk_clue_points_south_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_silk_clue_points_south_0.wav` | 哎呀大人，那段红绸我认得！绛红云纹——全城就城南卜掌柜家卖这个花色。浔阳楼前些日子刚采办过一匹呢。 |
| `evt_silk_clue_points_south_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_silk_clue_points_south_1.wav` | 城南布庄？那咱们去问问！如果案发前又有人急着买这种绸子…… |
| `evt_silk_clue_points_south_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_silk_clue_points_south_2.wav` | 走。 |
| `evt_lu_pressures_closing_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_lu_pressures_closing_0.wav` | 马三匆匆赶来，面色不善。 |
| `evt_lu_pressures_closing_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_lu_pressures_closing_1.wav` | 大人，鲁知府催了——他说'醉后失足'那份结案稿明日就要盖印发回京，请大人不要'再多事'。 |
| `evt_lu_pressures_closing_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_lu_pressures_closing_2.wav` | 什么叫多事！人都死了他怕什么——怕查到他头上吗！ |
| `evt_lu_pressures_closing_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_lu_pressures_closing_3.wav` | （沉默片刻）明天之前。必须有结果。 |
| `evt_lu_pressures_closing_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_lu_pressures_closing_4.wav` | ……好。那本姑娘今晚不睡了，帮您再把线索理一遍！ |
| `evt_lu_pressures_closing_5` | `assets/cn/voices/_events/xunyang_pavilion/evt_lu_pressures_closing_5.wav` | 卑职也帮着跑。大人您吩咐。 |
| `evt_final_day_warning_0` | `assets/cn/voices/_events/xunyang_pavilion/evt_final_day_warning_0.wav` | 天色暗了下来。明日便是结案稿发京的最后期限。 |
| `evt_final_day_warning_1` | `assets/cn/voices/_events/xunyang_pavilion/evt_final_day_warning_1.wav` | 陆大人……时间不多了。您有把握吗？ |
| `evt_final_day_warning_2` | `assets/cn/voices/_events/xunyang_pavilion/evt_final_day_warning_2.wav` | 证据链还差最后一环——但方向已经很明确了。 |
| `evt_final_day_warning_3` | `assets/cn/voices/_events/xunyang_pavilion/evt_final_day_warning_3.wav` | 是青姐对不对？泥底绣鞋、涂改的账册、赎身契……全指向她。 |
| `evt_final_day_warning_4` | `assets/cn/voices/_events/xunyang_pavilion/evt_final_day_warning_4.wav` | 证据指向不等于定罪。还需要她自己的口供——或者一个无法辩驳的物证。 |
| `evt_final_day_warning_5` | `assets/cn/voices/_events/xunyang_pavilion/evt_final_day_warning_5.wav` | 那……明天一早，咱们再去搜一遍？或者——直接把她叫到公堂上？ |
| `evt_final_day_warning_6` | `assets/cn/voices/_events/xunyang_pavilion/evt_final_day_warning_6.wav` | 若证据齐全，可前往府衙公开指证。 |

---

## 后续 TTS 生成提示

1. 每条缺失语音的 `actor_id` 决定了用哪个 voice_config —— 见 `data/actors/registry.json`。
2. 缺失列表按 `actor_id` 聚合后跑 `tools/generate_voices.py` 可批量生成。
3. 序章和事件类语音不区分 actor，按 `_prologue/` / `_events/` 旧目录约定生成。
4. 重新跑本脚本即可看到差量更新。
