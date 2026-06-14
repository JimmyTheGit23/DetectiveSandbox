# 序章·临川驿案 — 全剧本

> **说明**：
> - 每行格式: `[ID] 角色 [情绪]: 台词`
> - ID 格式: `文件名:行号`，用于重新导入时定位
> - 修改台词后，运行 `python3 tools/import_prologue_md.py` 写回源文件
> - 请勿改动 ID 或行首的 `[` `]` 标记


# 案件信息

- **id**: prologue_ferry
- **title**: 渡口沉舟
- **subtitle**: 万历廿二年 · 腊月 · 荆江
- **order**: 0
- **difficulty**: simple
- **estimated_days**: 2
- **max_days**: 10
- **main_scene**: cabin_lu_room
- **preview_image**: res://assets/cn/scenes/prologue_ferry_dock.png
- **synopsis**: 荆江石矶渡，商人溺亡。是暗礁翻船的意外，还是另有蹊跷？
- **intro**: 教学序章：石矶渡冬雨命案。
- **era**: ming_wanli
- **locale**: cn
- **companion**: xia_lingyao
- **is_tutorial**: true
- **voice_status**: missing
- **scenes**: {"prologue": "prologue.json", "epilogue_meta": "epilogue_meta.json"}
- **files**: {"case": "case.json", "casting": "casting.json", "npcs": "npcs.json", "npc_states": "npc_states.json", "evidence": "evidence.json", "locations": "locations.json", "search_results": "search_results.json", "progression": "progression.json", "day_events": "day_events.json", "bgm_config": "bgm_config.json"}
- **directories**: {"dialogues": "dialogues/", "companion": "companion/"}
- **rewards**: {"xp": 50, "unlock_cases": ["xunyang_pavilion"]}

# 角色表

- **阿贵** (死者仆从): 跟随周德茂十二年的老仆，受怨恨与银钱诱导卷入沉船局。
- **王大爷** (江边渔翁): 下游渔村的老渔翁，受人用银钱诱导在堂上补说不实目击；不实指认被拆穿后，说话再不敢咬死，只能提供一些边角线索。
- **老范** (石矶渡船家): 在这段江面跑了二十年船的老船家，熟悉沉船骗保的河道门道。
- **钱里正** (石矶渡里正): 地方小吏，圆滑世故，熟知河上骗保陋习却畏惧担责。
- **陆昭** (巡按御史): 玩家本人。奉旨南下暗查漕运账弊，途经石矶渡时被卷入命案。
- **沈清月** (药材商之女兼讼师): 浔阳沈氏药材行独女，兼通讼理与草药毒理。以讼师身份介入此案，最终从辩方走到被告席。
- **周德茂** (死者 · 布商): 荆江布商，携五十两货银乘夜船过江；其货物中疑似藏有与漕运账目有关的残页。
- **周氏** (死者妻子): 周德茂之妻，悲痛之下被人暗中引导，将矛头指向同船幸存的陆昭。
- **阿贵** (死者仆从（船舱阶段）): 跟随周德茂十二年的老仆。船舱中的紧张仆从。
- **老范** (船家（船舱阶段）): 在这段江面跑了二十年船的老船家。船舱中的老船家。
- **周德茂** (布商（船舱阶段）): 荆江布商，携五十两货银乘夜船过江。船舱中的精明商人。

# 第一幕 · 船舱


## 开场独白


> ⏱ 半个时辰前 · 荆江石矶渡

`[prologue_l:2]` **陆昭** `[observing]`: 驿丞说这船宽敞。若这也算宽敞，他大概没坐过窄船。 *(内心)*
`[prologue_l:3]` **陆昭** `[focused]`: 斗篷挂好。官印木匣放回床脚。封蜡没裂，绳结还是我打的那个活扣。 *(内心)*
`[prologue_l:4]` **陆昭** `[relieved]`: 都还在。手别抖。只是过江，不是上刑场。 *(内心)*
`[prologue_l:5]` **陆昭** `[warm]`: 临走前老师把旧砚推给我，说压行李用。六斤重的砚台压什么行李。他只是没好意思说，怕我回不去。 *(内心)*
`[prologue_l:6]` **陆昭** `[serious]`: 三年账，十四万两。纸上只是墨点，真落到人身上，就是一城人的米盐。沿江有人敢吞，就有人敢让查账的人闭嘴。 *(内心)*
`[prologue_l:7]` **陆昭** `[anxious]`: 上一位御史也是走水路失踪。离这条江不远。卷宗上只写下落不明，四个字干净得像洗过。 *(内心)*
`[prologue_l:8]` **陆昭** `[determined]`: 老师送我出京时只说写信回来。不是查清楚，也不是小心。写信回来。那我至少得活到能写信。 *(内心)*
`[prologue_l:9]` **陆昭** `[tired]`: 先到了再说。 *(内心)*
`[prologue_l:10]` **陆昭** `[observing]`: 前舱还在吃饭？这么晚了…… *(内心)*
`[prologue_l:11]` **陆昭** `[determined]`: 同船的有布商、仆从、船家。先出去看看这三个人。 *(内心)*
`[prologue_l:12]` **陆昭** `[determined]`: 舱室不大。桌上有行程简记，床脚搁着木匣。前舱和船尾有人说话。趁现在聊聊。 *(内心)*
`[prologue_l:13]` **陆昭** `[warm]`: 枕头硬邦邦的，里头塞的好像是荞麦壳。……京城租的那间房也是荞麦枕，睡了三年都没压扁。走的时候忘了带，也没什么可惜的。就是今晚换了个硬法。 *(内心)*
`[prologue_l:14]` **陆昭** `[serious]`: 回到舱室。没点灯。三个人。在心里排一遍。 *(内心)*
`[prologue_l:15]` **陆昭** `[serious]`: 周德茂。铜锁木箱抱得那么紧，比我还紧张。说是布匹，布匹用得着铜锁？水性好、胃口好、赶夜船……倒像是个赶着去办正事的，不像他自己说的那么闲。 *(内心)*
`[prologue_l:16]` **陆昭** `[suspicious]`: 阿贵。那一口咽的口水比什么都响。十二年跟一个人，张嘴只有"还行"。要么是嘴笨说不出好话，要么是真的只剩"还行"了。包袱里那个弧形的东西……他不想让我知道。一个仆从，有什么需要瞒外人的？ *(内心)*
`[prologue_l:17]` **陆昭** `[suspicious]`: 老范。等等。南汊堵了，谁说的？我上船前码头上没听任何人讲。还有"客官也急着到"，我什么时候说过急？我只说了去武昌。还有别开窗……晚上行船开窗透气不是常事吗，为什么专门叮嘱？这人话不多，但每句话里好像都夹着一根我看不见的线。也许我多心了。但如果不是多心呢。 *(内心)*
`[prologue_l:18]` **陆昭** `[serious]`: 三个人。铜锁、咽口水、说不通的叮嘱。 *(内心)*
`[prologue_l:19]` **陆昭** `[anxious]`: ……也许我想多了。但如果没想多呢？ *(内心)*
`[prologue_l:20]` **陆昭** `[tired]`: 先睡。明天还长。 *(内心)*
`[prologue_l:21]` **陆昭** `[nervous]`: ……别开窗。为什么是"别开窗"。 *(内心)*
`[prologue_l:22]` **陆昭** `[shocked]`: “轰——！”一声刺耳的巨响从船底炸开，整个舱室剧烈倾斜。 *(内心)*
`[prologue_l:23]` **陆昭** `[panic]`: 冰冷的江水瞬间冲毁舱门，油灯熄灭，无边的黑暗和失重感将我吞没…… *(内心)*
`[prologue_l:24]` **陆昭** `[vulnerable]`: 好冷。翻滚的浊流疯狂拉扯着四肢。官印、木匣……抓不住，全抓不住了。我在往下沉。 *(内心)*
`[prologue_l:25]` **陆昭** `[vulnerable]`: 肺部像要炸开般剧痛。真的要无声无息地死在冰冷的江底了吗…… *(内心)*
`[prologue_l:26]` **陆昭** `[shocked]`: 模糊中，冰冷的水流似乎被强硬地撕开。一只极温热、极有力的手，死死扣住了我的手腕！ *(内心)*
`[prologue_l:27]` **陆昭** `[relieved]`: 被猛地拽出水面的瞬间，冰凉的夜风灌入胸腔，耳畔只留下一个清亮而坚决的声音—— *(内心)*
`[prologue_l:28]` **凌瑶** `[determined]`: “喂！撑着点！抓紧我，不许松手！”

## NPC对话 (JSON)


### NPC: agui

`[dialogue:agui.json:intro]` **** `[grief]`: 陆公子，您别站太近。小的昨晚一闭眼就是水声。
`[dialogue:agui.json:intro]` **** `[serious]`: 我问昨夜，不问你怕不怕。你第一次醒来时，人在舱里哪里？
`[dialogue:agui.json:intro]` **** `[nervous]`: 靠门边。油灯快灭了，小的想去添油，底舱那边忽然咚了一声。
`[dialogue:agui.json:intro]` **** `[worried]`: 刚才堂上，他只说自己醒了一次。现在多了添油。
`[dialogue:agui.json:intro]` **** `[serious]`: 添油之前，你看见周德茂了吗？
`[dialogue:agui.json:intro]` **** `[panic]`: 没有。小的只听见声，后头船就斜了。人一乱，谁还分得清。
`[dialogue:agui.json:ask_relationship]` **** `[grief]`: 老爷帮过小的。十六岁进的门，什么都不会，开门、跑腿、守夜，都是老爷叫人教的。
`[dialogue:agui.json:ask_relationship]` **** `[grief]`: 十二年了……小的半条命都是老爷给的。现在老爷没了……小的不知道该怎么办。
`[dialogue:agui.json:press_alibi]` **** `[serious]`: 你不会水。落水后靠什么撑到岸边？
`[dialogue:agui.json:press_alibi]` **** `[nervous]`: 像是抓到一块板子。黑里摸到什么就抱什么，小的哪敢挑。
`[dialogue:agui.json:press_alibi]` **** `[serious]`: 那块板子现在在哪？
`[dialogue:agui.json:press_alibi]` **** `[panic]`: 水冲走了吧。小的醒来时，两只手都空着。
`[dialogue:agui.json:press_alibi]` **** `[worried]`: 他说得像做梦。可人真靠一块板子活下来，手上总该留下点擦伤。
`[dialogue:agui.json:show_dismissal]` **** `[serious]`: 这是周德茂出发前三日写的。给银二两，各不相欠。
`[dialogue:agui.json:show_dismissal]` **** `[nervous]`: 老爷说，让小的回乡。小的伺候久了，也该回去了。
`[dialogue:agui.json:show_dismissal]` **** `[serious]`: 十二年，只写二两。你读到这句时，没说话？
`[dialogue:agui.json:show_dismissal]` **** `[defensive]`: 说什么呢。小的这张嘴，哪有资格跟老爷算账。
`[dialogue:agui.json:show_dismissal]` **** `[worried]`: 他没抬头。可指甲一直抠着袖口。
`[dialogue:agui.json:show_dismissal]` **** `[serious]`: 不敢算，不等于没算过。
`[dialogue:agui.json:show_bladder]` **** `[serious]`: 包袱底下的牛皮浮囊，已经充好了气。不是落水后临时吹的。
`[dialogue:agui.json:show_bladder]` **** `[defensive]`: 怕水的人带个保命东西，也犯法？
`[dialogue:agui.json:show_bladder]` **** `[determined]`: 怕水会带浮囊。可会把它先充满，还压在衣裳最底下吗？
`[dialogue:agui.json:confession]` **** `[serious]`: 阿贵，先别哭。船底的洞、你包袱里的浮囊、周德茂身上的痕迹，都在拆你的话。
`[dialogue:agui.json:confession]` **** `[panic]`: 陆公子，小的真没那个胆子。
`[dialogue:agui.json:confession]` **** `[serious]`: 胆子未必是你的。可那只浮囊，是你自己藏进包袱的。
`[dialogue:agui.json:confession]` **** `[determined]`: 他说怕，可他每次怕的都是自己会死，不是周德茂已经死了。
`[dialogue:agui.json:confession]` **** `[determined]`: 那就进堂。你慢慢说，我一件件拿给你看。
`[dialogue:agui.json:ask_twelve_years]` **** `[nervous]`: 十二年？……陆公子怎么突然问这个？
`[dialogue:agui.json:ask_twelve_years]` **** `[serious]`: 随便聊聊。十二年……不短了。
`[dialogue:agui.json:ask_twelve_years]` **** `[nervous]`: ……不短。
`[dialogue:agui.json:ask_twelve_years]` **** `[crying]`: 小的十六岁进周家。什么都不会。老爷说'跟着学三年就放你出师'。
`[dialogue:agui.json:ask_twelve_years]` **** `[serious]`: 三年五年八年……出师的事再没提过。
`[dialogue:agui.json:ask_twelve_years]` **** `[nervous]`: ……不敢提。老爷说学徒的够用了。小的哪敢再开口。
`[dialogue:agui.json:ask_twelve_years]` **** `[nervous]`: 中间想走过。跟老爷说想回乡。他说'走可以，把这些年吃穿的钱还了再走'。小的哪还得起？只好继续待着。
`[dialogue:agui.json:ask_twelve_years]` **** `[shocked]`: ……这不是卖身契？
`[dialogue:agui.json:ask_twelve_years]` **** `[grief]`: 大约……算是吧。但小的没地方去。爹娘早没了。只有这一个主人。
`[dialogue:agui.json:ask_twelve_years]` **** `[nervous]`: 前几年还好。老爷生意好的时候心情也好，偶尔给几十文赏钱。后来生意差了。骂的就多了。打也打过。
`[dialogue:agui.json:ask_twelve_years]` **** `[worried]`: ……他打你哪了？
`[dialogue:agui.json:ask_twelve_years]` **** `[grief]`: 小的有个相好的。隔壁村的姑娘。存了两年钱想下聘。结果钱被老爷'借走'。说是补生意上的窟窿。
`[dialogue:agui.json:ask_twelve_years]` **** `[grief]`: 那姑娘等了一年……后来嫁别人了。
`[dialogue:agui.json:ask_twelve_years]` **** `[serious]`: ……
`[dialogue:agui.json:ask_twelve_years]` **** `[worried]`: ……
`[dialogue:agui.json:ask_twelve_years]` **** `[grief]`: 陆公子，小的不是好人。但小的……这十二年过的也不是人过的日子。
`[dialogue:agui.json:ask_twelve_years]` **** `[gentle]`: 陆昭，他说到那姑娘时，先去摸袖口。不是咬牙，是怕别人看见。
`[dialogue:agui.json:ask_twelve_years]` **** `[serious]`: 嗯。恨是真的，怕也是真的。先别替他下结论。

### NPC: agui_cabin


### NPC: fisherman_wang

`[dialogue:fisherman_wang.json:intro]` **** `[evasive]`: 你又来问我昨夜那眼神？先说好，我老王这回不把话说死。
`[dialogue:fisherman_wang.json:intro]` **** `[serious]`: 我不要你说死。你只说看见了什么，没看见什么。
`[dialogue:fisherman_wang.json:intro]` **** `[evasive]`: 船头有人影。两个人，一高一矮。脸看不清，衣裳也被雾糊住。
`[dialogue:fisherman_wang.json:intro]` **** `[determined]`: 这句比堂上松了。他先前把像说成了就是。
`[dialogue:fisherman_wang.json:intro]` **** `[guilty]`: 人命案里，话说满了会害人。我昨夜已经害过一回嘴了。
`[dialogue:fisherman_wang.json:ask_channel]` **** `[evasive]`: 东汊。那条水面看着平，底下石头像牙。
`[dialogue:fisherman_wang.json:ask_channel]` **** `[evasive]`: 本地撑船的，闭着眼也会绕开。涨水也不保险，石尖藏在水皮下头。
`[dialogue:fisherman_wang.json:ask_channel]` **** `[serious]`: 老范跑了二十年，不会不知道。
`[dialogue:fisherman_wang.json:ask_channel]` **** `[angry]`: 他要说不知道，我把这张老脸按进江里给他洗眼睛。
`[dialogue:fisherman_wang.json:ask_channel]` **** `[determined]`: 这不是失误。至少不是普通失误。
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[evasive]`: 前一晚……对，我那天也收了夜网。
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[evasive]`: 路过码头的时候，看到两个人蹲在角落里说话。黑灯瞎火的，偷偷摸摸的。
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[cold]`: 他们说了什么？
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[evasive]`: 一高一矮。高的像是那仆从。腰板直。矮的精瘦精瘦的。像船家。
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[serious]`: 你确定高的是阿贵？
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[anxious]`: 那晚他们说了什么？声音大不大？
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[evasive]`: （看了凌瑶一眼，话停了）……我没听见说话。只是看见。
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[worried]`: （低声，对陆昭）对不住，问急了。
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[evasive]`: 我当时没在意。第二天出了事才想起来。
`[dialogue:fisherman_wang.json:ask_meeting]` **** `[anxious]`: 案发前一晚两人鬼祟说话……这时间点也太巧了。
`[dialogue:fisherman_wang.json:trust]` **** `[evasive]`: 我活了一辈子，在这江上。这江面夜里是什么声气，我闭着眼都听得出来。
`[dialogue:fisherman_wang.json:trust]` **** `[evasive]`: 见过太多死在水里的人。有些是真出事，有些一看就不对。
`[dialogue:fisherman_wang.json:trust]` **** `[serious]`: 有些是命，有些不是……你看到了什么？
`[dialogue:fisherman_wang.json:trust]` **** `[evasive]`: 那天夜里……那人扑腾的声音不对。我听了四十年水声，人真溺水的时候，手乱拍，声儿很急，听得出来。
`[dialogue:fisherman_wang.json:trust]` **** `[serious]`: 谁？谁让你别管的？
`[dialogue:fisherman_wang.json:trust]` **** `[angry]`: 有人跟我说'别多管闲事'。还往我船上扔了两条鱼，说是'谢礼'。放屁。我这一辈子没收过这种黑心鱼。杀了人就该偿命。
`[dialogue:fisherman_wang.json:trust]` **** `[serious]`: 谢了。
`[dialogue:fisherman_wang.json:ask_dawn_sighting]` **** `[evasive]`: 天还没亮的时候。鸡叫头遍那会儿。我在下游浅滩收夜网，看见芦苇倒了一片。
`[dialogue:fisherman_wang.json:ask_dawn_sighting]` **** `[evasive]`: 水边有长竿探过的划痕，还有重东西拖上岸的泥印。新得很，不像白天留下的。
`[dialogue:fisherman_wang.json:ask_dawn_sighting]` **** `[cold]`: 看清是谁留下的吗？
`[dialogue:fisherman_wang.json:ask_dawn_sighting]` **** `[evasive]`: 看不清，也不敢再乱说。你们要查，就查浅滩泥印和芦苇折口。
`[dialogue:fisherman_wang.json:ask_dawn_sighting]` **** `[anxious]`: 嘴会改，泥不会。陆公子，去浅滩看脚印和折口。
`[dialogue:fisherman_wang.json:ask_dawn_sighting]` **** `[serious]`: 嗯。下游浅滩要查现场，不靠目击。
`[dialogue:fisherman_wang.json:ask_river_life]` **** `[evasive]`: 我在这江上打了一辈子鱼。
`[dialogue:fisherman_wang.json:ask_river_life]` **** `[evasive]`: 哪条汊水有暗礁，哪片浅滩能藏东西，心里都有数。
`[dialogue:fisherman_wang.json:ask_river_life]` **** `[serious]`: 你对这片江很熟。
`[dialogue:fisherman_wang.json:ask_river_life]` **** `[angry]`: 所以我才说。老范那样的老船家，绝不可能糊里糊涂把船往东汊暗礁上带。
`[dialogue:fisherman_wang.json:ask_river_life]` **** `[serious]`: 谢了！我记下了。

### NPC: lao_fan

`[dialogue:lao_fan.json:intro]` **** `[evasive]`: 船是我撑的，人也死在我船上。陆公子要问，我认。
`[dialogue:lao_fan.json:intro]` **** `[serious]`: 那就从船底那一下说起。
`[dialogue:lao_fan.json:intro]` **** `[evasive]`: 进东汊后浪横，船身先蹭了一下，后头就裂了。老船嘛，吃不住撞。
`[dialogue:lao_fan.json:intro]` **** `[worried]`: 他说蹭了一下。可昨晚水灌得太快，不像慢慢裂开的。
`[dialogue:lao_fan.json:intro]` **** `[serious]`: 我会去看那道裂口。石头撞出来的，和人凿出来的，不会一样。
`[dialogue:lao_fan.json:ask_route]` **** `[evasive]`: 周老板催得急，说天亮前要赶到武昌。我就拣近的水道走。
`[dialogue:lao_fan.json:ask_route]` **** `[serious]`: 近路就是东汊？
`[dialogue:lao_fan.json:ask_route]` **** `[defensive]`: 涨水后看着能过。老船家也有看走眼的时候嘛。
`[dialogue:lao_fan.json:ask_route]` **** `[determined]`: 他把知道有礁，改成了看走眼。
`[dialogue:lao_fan.json:ask_route]` **** `[serious]`: 看走眼，和明知还走，是两回事。
`[dialogue:lao_fan.json:press_route]` **** `[defensive]`: 涨水时水面高，礁石该没下去。我是看水吃饭的人，也有看走眼的时候。这能全怪我？
`[dialogue:lao_fan.json:press_route]` **** `[determined]`: 他说看走眼，可一提东汊，眼睛就往门外瞟。
`[dialogue:lao_fan.json:press_route]` **** `[serious]`: 嗯。先问他为什么非走那条水。
`[dialogue:lao_fan.json:ask_rescue]` **** `[smirk]`: 我水性好嘛。泡了……泡了有半个时辰。江饭吃久了，水里也能咬牙熬一阵。后来有船经过，把我捞上来的。
`[dialogue:lao_fan.json:ask_rescue]` **** `[shocked]`: 半个时辰？腊月的江水冷得像刀子。人在里头泡上半个时辰，怕是早就冻硬了。陆公子，咱们得查查码头的册子。
`[dialogue:lao_fan.json:ask_rescue]` **** `[defensive]`: 我身体硬朗。年轻时候在江里扎猛子，冷水也扛过。
`[dialogue:lao_fan.json:ask_rescue]` **** `[serious]`: 好。那我们就按码头登记核时辰。
`[dialogue:lao_fan.json:ask_rescue]` **** `[worried]`: 半个时辰和一刻钟，差得足够让一个人从落水，变成先上岸等着。
`[dialogue:lao_fan.json:show_hull]` **** `[nervous]`: 修……修过？哪条船不修呢。船跑久了要捻缝补板，这都是常事。
`[dialogue:lao_fan.json:show_hull]` **** `[defensive]`: 翻船之前动它干嘛？吃水的饭，自己砸自己饭碗？那不是礁石还能是什么。
`[dialogue:lao_fan.json:show_hull]` **** `[determined]`: 他先说没动过，又马上拿'常修船'挡。两句话贴不上。
`[dialogue:lao_fan.json:show_hull]` **** `[serious]`: 船上有捻凿和桐油。翻船前后，谁碰过船底？
`[dialogue:lao_fan.json:show_hull]` **** `[defensive]`: 陆公子，船家船上有修船物件不稀奇。你要说我动过船底，总得拿准是哪一道痕。
`[dialogue:lao_fan.json:show_hull]` **** `[determined]`: 好。那就看洞边的凿痕和钉眼，不看口气。
`[dialogue:lao_fan.json:show_iou]` **** `[defensive]`: 手头紧？嗐！这话说的……跑船的人哪天不紧巴？日子嘛，凑合过呗。
`[dialogue:lao_fan.json:show_iou]` **** `[nervous]`: 跑船嘛，有时多赚有时少赚……年关难过，水浅船沉，谁家不紧巴？
`[dialogue:lao_fan.json:show_iou]` **** `[determined]`: 四十二两……腊月底还不上就断指。这不是年关难过，是要命。
`[dialogue:lao_fan.json:show_iou]` **** `[serious]`: 四十二两。有人拿这笔债找过你吗？
`[dialogue:lao_fan.json:show_iou]` **** `[defensive]`: 没人兜底。我自己欠的债，自己认。陆公子别把什么事都往别人身上扯。
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[defensive]`: ……你问这个干嘛。跟案子有关系？
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[serious]`: 二十年的老船家，怎么沾上的赌？
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[dismissive]`: ……嗐。说来话长。
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[nervous]`: 那死鬼崽子要是还在……嗐，说这干啥。
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[nervous]`: 那年冬月，孩子发热烧得直说胡话，药铺要二两银子才肯抓药。我跑了一整天，一分没借到。
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[nervous]`: 回船时候码头边有人递话——"范老哥，急用银子？我认识个门路。"
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[cornered]`: 嗐！我那会儿想都没想就跟去了，想着赢了药钱就收手。谁知道那是个无底洞……
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[serious]`: 从借钱救急，到欠四十二两，中间是谁牵的线？
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[cornered]`: 二两变五两，五两变十两……等我还不上，还是那帮人，又凑上来说可以借。
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[worried]`: ……孩子后来怎样了？
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[cornered]`: 到头来四十二两。那死鬼崽子……也没等到那副药。
`[dialogue:lao_fan.json:ask_gambling_story]` **** `[cornered]`: 吃水的饭哪有不湿鞋的……嗐。
`[dialogue:lao_fan.json:press_shen_connection]` **** `[serious]`: 阿贵已经招了。老范，你这边也该把中间人说清楚。
`[dialogue:lao_fan.json:press_shen_connection]` **** `[serious]`: 找你的人，是个做药材生意的姑娘。对吗？
`[dialogue:lao_fan.json:press_shen_connection]` ****: 烟杆从嘴边落了下来。整个人僵住。
`[dialogue:lao_fan.json:press_shen_connection]` **** `[cornered]`: ……陆公子都知道了？
`[dialogue:lao_fan.json:press_shen_connection]` **** `[serious]`: 她怎么找上你的？条件是什么？
`[dialogue:lao_fan.json:press_shen_connection]` **** `[cornered]`: ……是她先来的。她把我那张欠条放在桌上，说有门生意，做完了赌债一笔勾销。
`[dialogue:lao_fan.json:press_shen_connection]` **** `[cornered]`: 我问什么生意。她说'把船弄沉就行。其他的不用管。你水性好，淹不死你。'……她连我水性好都查过了。
`[dialogue:lao_fan.json:press_shen_connection]` **** `[cornered]`: 我……我当时被逼急了。年底不还钱赌坊说要断指……
`[dialogue:lao_fan.json:press_shen_connection]` **** `[anxious]`: 她不是临时路过。她连老范哪条水熟，都先问清了。
`[dialogue:lao_fan.json:press_shen_connection]` **** `[serious]`: 你能认出她吗？
`[dialogue:lao_fan.json:press_shen_connection]` **** `[cornered]`: 高个子。穿劲装。说话利索。像是做过生意的人。
`[dialogue:lao_fan.json:press_shen_connection]` **** `[serious]`: ……沈清月。

### NPC: lao_fan_cabin


### NPC: li_zheng

`[dialogue:li_zheng.json:intro]` **** `[nervous]`: 陆公子，我这边也是夹在门缝里。周氏要凶手，县里要交代，渡口的人又怕牵连。
`[dialogue:li_zheng.json:intro]` **** `[serious]`: 你先别替任何人收口。把渡口知道的事说出来。
`[dialogue:li_zheng.json:intro]` **** `[sighing]`: 能说的我说。只是有些话，平日里能当闲谈，进了案卷就要压死人。
`[dialogue:li_zheng.json:intro]` **** `[worried]`: 他怕写错，也怕不写。先问能落到地方的。
`[dialogue:li_zheng.json:ask_reef]` **** `[gossip]`: 这话不好说……不过嘛，小人从小在这儿长大，那片礁石连小孩儿都知道要绕着走。小人也是听老一辈说的。
`[dialogue:li_zheng.json:ask_reef]` **** `[gossip]`: 涨水了也不保险。石头尖的很，水面下照样能把船底划烂。
`[dialogue:li_zheng.json:ask_reef]` **** `[anxious]`: 老范跑这条江二十年，真会不知道？
`[dialogue:li_zheng.json:ask_reef]` **** `[cold]`: 他知道。只是昨夜还是把船带过去了。
`[dialogue:li_zheng.json:ask_fan]` **** `[nervous]`: 老范嘛……人还行。就是爱赌。以前小赌怡情，这两年越赌越大。
`[dialogue:li_zheng.json:ask_fan]` **** `[nervous]`: 听说欠了赌坊不少钱。前阵子还有人来找他要账，闹得挺凶。
`[dialogue:li_zheng.json:ask_fan]` **** `[cold]`: 欠了多少？
`[dialogue:li_zheng.json:ask_fan]` **** `[serious]`: 如果有人拿欠条逼他呢？
`[dialogue:li_zheng.json:ask_fan]` **** `[nervous]`: 不过嘛。案卷不能只写坏处。他水性好，人也实在。年轻时候还救过落水的孩子，全渡口都知道。
`[dialogue:li_zheng.json:ask_fan]` **** `[anxious]`: 债能把人逼低头。有人若拿着欠条找他，他未必撑得住。
`[dialogue:li_zheng.json:ask_agui_spending]` **** `[nervous]`: 异常嘛……嗐，也不能说异常。就是。
`[dialogue:li_zheng.json:ask_agui_spending]` **** `[nervous]`: 他昨天在客栈买了壶好酒，又打了半斤卤肉。出手挺阔的。
`[dialogue:li_zheng.json:ask_agui_spending]` **** `[serious]`: 刚死了主人就买酒吃肉？
`[dialogue:li_zheng.json:ask_agui_spending]` **** `[nervous]`: 按说刚死了主人的仆从……哪有心情喝酒吃肉啊？而且他马上要被遣散了，身上能有几个钱？
`[dialogue:li_zheng.json:ask_agui_spending]` **** `[determined]`: 主人刚死还能吃肉喝酒，除非他知道自己今晚不会挨饿。
`[dialogue:li_zheng.json:ask_victim]` **** `[nervous]`: 知道知道。做布匹生意的，来往走水路常歇在咱这儿。
`[dialogue:li_zheng.json:ask_victim]` **** `[nervous]`: 人嘛……精明是精明的。就是待下人刻薄了些。动不动呵斥，小人听过好几回了。
`[dialogue:li_zheng.json:ask_victim]` **** `[serious]`: 十二年的刻薄……
`[dialogue:li_zheng.json:ask_victim]` **** `[nervous]`: 不过嘛。人死了，案卷上不好写太多坏话。大事化小，嘴也化小些。
`[dialogue:li_zheng.json:ask_victim]` **** `[serious]`: 十二年……受的恐怕不止这些。
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[nervous]`: 异常嘛……嗯，这个不知道算不算。
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[gossip]`: 半个月前吧。有个外地来的人在渡口打听事儿。穿得挺体面。长衫马褂，像个读书人。
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[surprised]`: 打听什么？
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[gossip]`: 打听水路。问哪条航道夜里走、什么船什么时辰开。还问了。常走这条路的商客有哪些。
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[cold]`: 他是什么人？
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[evasive]`: 说是南京来的。做茶叶生意。名号嘛……小人不太记得了。姓。好像姓顾？还是姓谷？反正文绉绉的。
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[anxious]`: 半个月前打听水路和常客，正卡在周德茂收到信前头。
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[cold]`: 后来呢？
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[evasive]`: 待了两三天就走了。小人也没多想。过路的商人来打听行情嘛，正常。
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[serious]`: 先是有人打听航道，半个月后周德茂收到南京来的信。
`[dialogue:li_zheng.json:ask_recent_strangers]` **** `[determined]`: 不像过路闲问。他是在挑哪条船、哪一夜最好下手。

### NPC: shen_qingyue

`[dialogue:shen_qingyue.json:intro]` **** `[cooperative]`: 周德茂欠我三十八两。前天我在码头堵过他，这事不用绕。
`[dialogue:shen_qingyue.json:intro]` **** `[serious]`: 你堵他，是为讨债。
`[dialogue:shen_qingyue.json:intro]` **** `[sharp]`: 是。药材行要周转，我爹的药也等钱。账期到了，我当然要追。
`[dialogue:shen_qingyue.json:intro]` **** `[serious]`: 可他死了，你一文也收不回来。
`[dialogue:shen_qingyue.json:intro]` **** `[cooperative]`: 所以我才还站在这儿。凶手若不是你，就别让那人顺手替周德茂赖账。
`[dialogue:shen_qingyue.json:intro]` **** `[worried]`: 她把话落在钱上，不落在恨上。
`[dialogue:shen_qingyue.json:ask_quarrel]` **** `[sharp]`: 我原话是，今天不给个准日子，就别想安生上船。码头边卖茶的都听见了。
`[dialogue:shen_qingyue.json:ask_quarrel]` **** `[serious]`: 听起来像威胁。
`[dialogue:shen_qingyue.json:ask_quarrel]` **** `[sharp]`: 讨债的话本来就不中听。我要是真想害他，会挑二十多双眼睛前先吵一场？
`[dialogue:shen_qingyue.json:ask_quarrel]` **** `[worried]`: 她一句都没停。像早就知道我们会问到这儿。
`[dialogue:shen_qingyue.json:ask_quarrel]` **** `[serious]`: 吵完之后呢？
`[dialogue:shen_qingyue.json:ask_quarrel]` **** `[cooperative]`: 他说明早到武昌先兑银，三日内给我。说完就让阿贵搬箱子上船。
`[dialogue:shen_qingyue.json:ask_quarrel]` **** `[serious]`: 你连阿贵搬箱子都看见了。
`[dialogue:shen_qingyue.json:ask_quarrel]` **** `[sharp]`: 债主盯欠债人的箱子，不奇怪吧。
`[dialogue:shen_qingyue.json:ask_alibi]` **** `[cooperative]`: 船离岸后，我就回客栈了。那晚冷，我还让伙计送过热水。
`[dialogue:shen_qingyue.json:ask_alibi]` **** `[serious]`: 伙计能作证？
`[dialogue:shen_qingyue.json:ask_alibi]` **** `[sharp]`: 他若没睡死，该能记得。不能记得，也不能反过来说我没回。
`[dialogue:shen_qingyue.json:ask_alibi]` **** `[worried]`: 她没有给准时辰，只把话压到伙计记不记得上。
`[dialogue:shen_qingyue.json:ask_alibi]` **** `[serious]`: 你说船离岸后就走，这句我记下了。
`[dialogue:shen_qingyue.json:ask_fan_connection]` **** `[cooperative]`: 老范替我送过两回药箱。码头船家嘛，认得脸很平常。
`[dialogue:shen_qingyue.json:ask_fan_connection]` **** `[serious]`: 我问的是你们有没有私下说过话。
`[dialogue:shen_qingyue.json:ask_fan_connection]` **** `[deflecting]`: 码头上说话不叫私下。问船价，问雨势，问哪条路快，这些谁都会问。
`[dialogue:shen_qingyue.json:ask_fan_connection]` **** `[determined]`: 她答得太快了。像把这句在嘴里含了很久。
`[dialogue:shen_qingyue.json:ask_fan_connection]` **** `[serious]`: 老范欠赌债的事，你从哪听来的？
`[dialogue:shen_qingyue.json:ask_fan_connection]` **** `[sharp]`: 赌坊讨债能闹半条街，想不听见都难。
`[dialogue:shen_qingyue.json:ask_father]` ****: 她看见药账的一瞬间，指尖压住了袖口。只一下，很快又松开。
`[dialogue:shen_qingyue.json:ask_father]` **** `[serious]`: 八十两药钱。账上只剩四十二两。
`[dialogue:shen_qingyue.json:ask_father]` **** `[cold_smile]`: 家里病人等药，铺子还要开门。我缺钱，不等于我会杀人。
`[dialogue:shen_qingyue.json:ask_father]` **** `[serious]`: 周德茂欠你三十八两，正好补这个缺口。
`[dialogue:shen_qingyue.json:ask_father]` **** `[sharp]`: 所以我更该让他活着还。死人不会拿银票出门。
`[dialogue:shen_qingyue.json:ask_father]` **** `[determined]`: 她这句接得快。可提到账上只剩四十二两时，她先按了袖口。
`[dialogue:shen_qingyue.json:press_dock_timing]` **** `[serious]`: 你说船离岸后就回客栈。可有人看见船开出去一刻钟，你还在码头。
`[dialogue:shen_qingyue.json:press_dock_timing]` **** `[deflecting]`: 夜里雾重。高个子的女人，也不只我一个。
`[dialogue:shen_qingyue.json:press_dock_timing]` **** `[serious]`: 那人穿男装，站在你先前堵周德茂的位置。
`[dialogue:shen_qingyue.json:press_dock_timing]` **** `[sharp]`: 债没讨到，我站一会儿吹风，不行吗？
`[dialogue:shen_qingyue.json:press_dock_timing]` **** `[determined]`: 她把回客栈，改成了站一会儿。
`[dialogue:shen_qingyue.json:press_dock_timing]` **** `[serious]`: 一会儿之后呢？往客栈，还是往下游？
`[dialogue:shen_qingyue.json:press_dock_timing]` **** `[cracking]`: ……往客栈。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[cold]`: 沈姑娘。天亮之前，下游浅滩留下了打捞痕迹。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[sharp]`: ……所以？跟我有什么关系？
`[dialogue:shen_qingyue.json:press_salvage]` **** `[cold]`: 浅滩芦苇新折，水边有长竿划痕，还有重物拖上岸又搬走的压痕。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[deflecting]`: 陆公子，那片芦苇丛谁都能踩。江边不是沈家的后院。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[serious]`: 你说你在睡觉。但那处痕迹只可能是天亮前留下的；而你那晚的去向，正缺这一段。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[cold]`: 等等。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[cold]`: 我没说芦苇丛。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[cold_smile]`: ……那一带都是芦苇。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[determined]`: 她停了。只有一下。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[cold]`: 石矶渡下游的浅滩，多数是泥滩。你去过那里，才知道长着芦苇。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[determined]`: 她嘴上说不是自己……可你看她的手，刚才还松着，现在死死扣着扶手。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[shocked]`: 镖局走水路看漂痕。东西会往哪儿靠，不是站在码头吹一夜风就能知道的。
`[dialogue:shen_qingyue.json:press_salvage]` **** `[serious]`: 我现在只问这一处：你怎么知道那片是芦苇，不是泥滩？
`[dialogue:shen_qingyue.json:press_connection]` **** `[cold]`: 老范说了，找他的人是做药材的姑娘。
`[dialogue:shen_qingyue.json:press_connection]` ****: 她脸上的笑一下收住了。过了一瞬，才又重新笑起来。
`[dialogue:shen_qingyue.json:press_connection]` **** `[cold_fury]`: 他这样说了？……有意思。赌鬼输急了，连自家祖宗都能押上桌。陆公子也信？
`[dialogue:shen_qingyue.json:press_connection]` **** `[cold]`: 不只老范。阿贵也说，有人教他买浮囊、凿哪块板。
`[dialogue:shen_qingyue.json:press_connection]` **** `[serious]`: 你放下了手。
`[dialogue:shen_qingyue.json:press_connection]` **** `[cracking]`: ……
`[dialogue:shen_qingyue.json:press_connection]` ****: 沉默了整整五息。然后她慢慢地。把一直抱着的双臂放了下来。
`[dialogue:shen_qingyue.json:press_connection]` **** `[cold_fury]`: 陆公子。你是来问话的，还是已经把判词写在袖子里了？
`[dialogue:shen_qingyue.json:press_connection]` **** `[anxious]`: 她……怎么突然不笑了？
`[dialogue:shen_qingyue.json:press_connection]` **** `[serious]`: 老范说见过做药材的姑娘。阿贵说有人教他留活路。你刚才听见这两句，把手放下来了。
`[dialogue:shen_qingyue.json:confession_trigger]` **** `[serious]`: 沈姑娘，堂上说吧。
`[dialogue:shen_qingyue.json:confession_trigger]` **** `[serious]`: 老范的债，阿贵的浮囊，码头那一刻钟，下游浅滩的脚印，我都会一件件摆出来。
`[dialogue:shen_qingyue.json:confession_trigger]` ****: 她看了看门外。雨水顺着檐角滴下，半晌才落一滴。
`[dialogue:shen_qingyue.json:confession_trigger]` **** `[cold_fury]`: 该问的人，你几乎都问到了。
`[dialogue:shen_qingyue.json:confession_trigger]` **** `[cold_fury]`: 不过陆公子，县衙落笔，不靠你觉得我像。
`[dialogue:shen_qingyue.json:confession_trigger]` **** `[anxious]`: 她没认。她在等你拿那件能写进案卷的东西。
`[dialogue:shen_qingyue.json:confession_trigger]` **** `[determined]`: 那就让她等着听完。

### NPC: zhou_de_gui_cabin


### NPC: zhou_wife

`[dialogue:zhou_wife.json:intro]` **** `[trembling]`: 你问吧。可别拿自证清白四个字来堵我。我丈夫躺在外头，不是给谁洗名声用的。
`[dialogue:zhou_wife.json:intro]` **** `[serious]`: 我问的是他为什么上那条船。
`[dialogue:zhou_wife.json:intro]` **** `[suspicious]`: 他去武昌进布，带了五十两货银。平日他舍不得赶夜船，这回却像被火追着。
`[dialogue:zhou_wife.json:ask_agui]` **** `[trembling]`: 阿贵跟了老爷十二年。以前贴春联，左联贴歪了，他能撕下来重贴三遍。
`[dialogue:zhou_wife.json:ask_agui]` **** `[trembling]`: 这两年不一样了。老爷嫌他慢，茶碗摔在他脚边，他也只蹲下去捡。
`[dialogue:zhou_wife.json:ask_agui]` **** `[suspicious]`: 上船前，老爷还说到了武昌就打发他走。
`[dialogue:zhou_wife.json:ask_agui]` **** `[serious]`: 打发走，给多少？
`[dialogue:zhou_wife.json:ask_agui]` **** `[silent]`: 字据在桌上。二两。
`[dialogue:zhou_wife.json:ask_agui]` **** `[worried]`: 她说二两时自己都停了一下。
`[dialogue:zhou_wife.json:ask_agui]` **** `[serious]`: 十二年，临走只给二两。他心里不会没东西。
`[dialogue:zhou_wife.json:ask_suspicion]` **** `[suspicious]`: 阿贵不对劲。案发后他哭得比我都凶。可他跟老爷关系好吗？不好。
`[dialogue:zhou_wife.json:ask_suspicion]` **** `[suspicious]`: 上船前还被骂了一通，当晚就哭天抹泪？我不信。
`[dialogue:zhou_wife.json:ask_suspicion]` **** `[cold]`: 确实反常。
`[dialogue:zhou_wife.json:ask_suspicion]` **** `[suspicious]`: 还有。老爷会水，年轻时跟船跑货，落水也能自己爬上来。普通翻船不该这么快没命。
`[dialogue:zhou_wife.json:ask_suspicion]` **** `[determined]`: 你说得对。一个挨了骂的仆从，哭得比主人的妻子还凶。这哭声太满了。
`[dialogue:zhou_wife.json:ask_swimming]` **** `[trembling]`: 会。他年轻时常跟船跑货，落水也能自己扒上岸。
`[dialogue:zhou_wife.json:ask_swimming]` **** `[trembling]`: 这几年身子重了些，可水性没丢。他还总说，跑买卖的人不能怕水。
`[dialogue:zhou_wife.json:ask_swimming]` **** `[determined]`: 那他昨晚不该这么快沉下去。
`[dialogue:zhou_wife.json:ask_swimming]` **** `[suspicious]`: 对。所以我才不信是意外。老爷会水，老范更会水，偏偏只有老爷死了。
`[dialogue:zhou_wife.json:ask_swimming]` **** `[worried]`: 会水的人没扒上来，这水里还有别的事。
`[dialogue:zhou_wife.json:ask_swimming]` **** `[serious]`: 记下。他会水，却没能上岸。
`[dialogue:zhou_wife.json:comfort]` **** `[serious]`: ……我会查到底。
`[dialogue:zhou_wife.json:comfort]` **** `[relieved]`: ……你不像凶手。凶手不会还留在这里问话。
`[dialogue:zhou_wife.json:comfort]` **** `[relieved]`: 里正让你查。你要是真能查出来……老爷的文书都在房间桌上。你看吧。
`[dialogue:zhou_wife.json:ask_documents]` **** `[suspicious]`: 都在房间里。陆公子自己去看吧。遣散字据、货单都在桌上。
`[dialogue:zhou_wife.json:ask_documents]` **** `[serious]`: 多谢。
`[dialogue:zhou_wife.json:ask_documents]` **** `[serious]`: 多谢。
`[dialogue:zhou_wife.json:ask_why_night_ferry]` **** `[serious]`: 你丈夫平日不赶夜船。这回为什么急？
`[dialogue:zhou_wife.json:ask_why_night_ferry]` **** `[suspicious]`: 出发前两天，他收到一封南京来的信。
`[dialogue:zhou_wife.json:ask_why_night_ferry]` **** `[suspicious]`: 信上说武昌有一批棉布，转到南京能翻价。还催他夜里走，误了时辰就换别人。
`[dialogue:zhou_wife.json:ask_why_night_ferry]` **** `[serious]`: 署名是谁？
`[dialogue:zhou_wife.json:ask_why_night_ferry]` **** `[suspicious]`: 没有。只写故友知会。字倒工整，工整得不像跑买卖的人写的。
`[dialogue:zhou_wife.json:ask_why_night_ferry]` **** `[determined]`: 知道他缺这笔生意，又知道夜船时辰。这信不是随手寄的。
`[dialogue:zhou_wife.json:ask_why_night_ferry]` **** `[serious]`: 那封信随他上船了？
`[dialogue:zhou_wife.json:ask_why_night_ferry]` **** `[silent]`: 是。他贴身收着。现在也许在江里，也许不在了。
`[dialogue:zhou_wife.json:react_murder_confirmed]` **** `[serious]`: 周氏。你丈夫的船底，有一个被凿出来的洞。
`[dialogue:zhou_wife.json:react_murder_confirmed]` **** `[serious]`: 不是意外。是有人故意的。
`[dialogue:zhou_wife.json:react_murder_confirmed]` ****: 周氏全身僵住。手里的帕子掉在地上，她没去捡。
`[dialogue:zhou_wife.json:react_murder_confirmed]` **** `[serious]`: 我不会骗你。
`[dialogue:zhou_wife.json:react_murder_confirmed]` **** `[screaming]`: ……我就知道不是意外。老爷他。
`[dialogue:zhou_wife.json:react_murder_confirmed]` **** `[grief]`: ……求您。一定要查清楚。
`[dialogue:zhou_wife.json:react_murder_confirmed]` **** `[worried]`: ……她哭了。这种哭法不是假的。陆公子，她是真的不知道。
`[dialogue:zhou_wife.json:react_murder_confirmed]` **** `[worried]`: ……
`[dialogue:zhou_wife.json:react_agui_confessed]` **** `[cold]`: 周氏。阿贵认了。船底是他凿的。
`[dialogue:zhou_wife.json:react_agui_confessed]` **** `[shocked]`: 阿贵。他跟了老爷十二年。
`[dialogue:zhou_wife.json:react_agui_confessed]` **** `[shocked]`: 十二年啊。吃一口锅里的饭、睡一个屋檐下。他怎么下得去手？
`[dialogue:zhou_wife.json:react_agui_confessed]` **** `[serious]`: 二两银子。十二年。
`[dialogue:zhou_wife.json:react_agui_confessed]` **** `[screaming]`: 二两……是少了点。可也不至于。
`[dialogue:zhou_wife.json:react_agui_confessed]` **** `[serious]`: 他背后还有人。是别人教他做的。
`[dialogue:zhou_wife.json:react_agui_confessed]` **** `[interrogating]`: 还有人？！谁？！
`[dialogue:zhou_wife.json:react_agui_confessed]` **** `[determined]`: 还在查！会有结果的！
`[dialogue:zhou_wife.json:react_agui_confessed]` **** `[worried]`: 她不光是恨……还有伤心。贴对联的人，亲手凿了她丈夫的船。

## 调查对话 (CSV)

`[dl:intro:1]` **agui** `[grief]`: 陆公子，您别站太近。小的昨晚一闭眼就是水声。
`[dl:intro:2]` **lu_zhao** `[serious]`: 我问昨夜，不问你怕不怕。你第一次醒来时，人在舱里哪里？
`[dl:intro:3]` **agui** `[nervous]`: 靠门边。油灯快灭了，小的想去添油，底舱那边忽然咚了一声。
`[dl:intro:4]` **xia_lingyao** `[worried]`: 刚才堂上，他只说自己醒了一次。现在多了添油。
`[dl:intro:5]` **lu_zhao** `[serious]`: 添油之前，你看见周德茂了吗？
`[dl:intro:6]` **agui** `[panic]`: 没有。小的只听见声，后头船就斜了。人一乱，谁还分得清。
`[dl:ask_relationship:1]` **agui** `[grief]`: 老爷帮过小的。十六岁进的门，什么都不会，开门、跑腿、守夜，都是老爷叫人教的。
`[dl:ask_relationship:2]` **agui** `[grief]`: 十二年了……小的半条命都是老爷给的。现在老爷没了……小的不知道该怎么办。
`[dl:press_alibi:1]` **lu_zhao** `[serious]`: 你不会水。落水后靠什么撑到岸边？
`[dl:press_alibi:2]` **agui** `[nervous]`: 像是抓到一块板子。黑里摸到什么就抱什么，小的哪敢挑。
`[dl:press_alibi:3]` **lu_zhao** `[serious]`: 那块板子现在在哪？
`[dl:press_alibi:4]` **agui** `[panic]`: 水冲走了吧。小的醒来时，两只手都空着。
`[dl:press_alibi:5]` **xia_lingyao** `[worried]`: 他说得像做梦。可人真靠一块板子活下来，手上总该留下点擦伤。
`[dl:show_dismissal:1]` **lu_zhao** `[serious]`: 这是周德茂出发前三日写的。给银二两，各不相欠。
`[dl:show_dismissal:2]` **agui** `[nervous]`: 老爷说，让小的回乡。小的伺候久了，也该回去了。
`[dl:show_dismissal:3]` **lu_zhao** `[serious]`: 十二年，只写二两。你读到这句时，没说话？
`[dl:show_dismissal:4]` **agui** `[defensive]`: 说什么呢。小的这张嘴，哪有资格跟老爷算账。
`[dl:show_dismissal:5]` **xia_lingyao** `[worried]`: 他没抬头。可指甲一直抠着袖口。
`[dl:show_dismissal:6]` **lu_zhao** `[serious]`: 不敢算，不等于没算过。
`[dl:show_bladder:1]` **lu_zhao** `[serious]`: 包袱底下的牛皮浮囊，已经充好了气。不是落水后临时吹的。
`[dl:show_bladder:2]` **agui** `[defensive]`: 怕水的人带个保命东西，也犯法？
`[dl:show_bladder:3]` **xia_lingyao** `[determined]`: 怕水会带浮囊。可会把它先充满，还压在衣裳最底下吗？
`[dl:confession:1]` **lu_zhao** `[serious]`: 阿贵，先别哭。船底的洞、你包袱里的浮囊、周德茂身上的痕迹，都在拆你的话。
`[dl:confession:2]` **agui** `[panic]`: 陆公子，小的真没那个胆子。
`[dl:confession:3]` **lu_zhao** `[serious]`: 胆子未必是你的。可那只浮囊，是你自己藏进包袱的。
`[dl:confession:4]` **xia_lingyao** `[determined]`: 他说怕，可他每次怕的都是自己会死，不是周德茂已经死了。
`[dl:confession:5]` **lu_zhao** `[determined]`: 那就进堂。你慢慢说，我一件件拿给你看。
`[dl:ask_twelve_years:1]` **agui** `[nervous]`: 十二年？……陆公子怎么突然问这个？
`[dl:ask_twelve_years:2]` **lu_zhao** `[serious]`: 随便聊聊。十二年……不短了。
`[dl:ask_twelve_years:3]` **agui** `[nervous]`: ……不短。
`[dl:ask_twelve_years:4]` **agui** `[crying]`: 小的十六岁进周家。什么都不会。老爷说'跟着学三年就放你出师'。
`[dl:ask_twelve_years:5]` **lu_zhao** `[serious]`: 三年五年八年……出师的事再没提过。
`[dl:ask_twelve_years:6]` **agui** `[nervous]`: ……不敢提。老爷说学徒的够用了。小的哪敢再开口。
`[dl:ask_twelve_years:7]` **agui** `[nervous]`: 中间想走过。跟老爷说想回乡。他说'走可以，把这些年吃穿的钱还了再走'。小的哪还得起？只好继续待着。
`[dl:ask_twelve_years:8]` **xia_lingyao** `[shocked]`: ……这不是卖身契？
`[dl:ask_twelve_years:9]` **agui** `[grief]`: 大约……算是吧。但小的没地方去。爹娘早没了。只有这一个主人。
`[dl:ask_twelve_years:10]` **agui** `[nervous]`: 前几年还好。老爷生意好的时候心情也好，偶尔给几十文赏钱。后来生意差了。骂的就多了。打也打过。
`[dl:ask_twelve_years:11]` **xia_lingyao** `[worried]`: ……他打你哪了？
`[dl:ask_twelve_years:12]` **agui** `[grief]`: 小的有个相好的。隔壁村的姑娘。存了两年钱想下聘。结果钱被老爷'借走'。说是补生意上的窟窿。
`[dl:ask_twelve_years:13]` **agui** `[grief]`: 那姑娘等了一年……后来嫁别人了。
`[dl:ask_twelve_years:14]` **lu_zhao** `[serious]`: ……
`[dl:ask_twelve_years:15]` **xia_lingyao** `[worried]`: ……
`[dl:ask_twelve_years:16]` **agui** `[grief]`: 陆公子，小的不是好人。但小的……这十二年过的也不是人过的日子。
`[dl:ask_twelve_years:17]` **xia_lingyao** `[gentle]`: 陆昭，他说到那姑娘时，先去摸袖口。不是咬牙，是怕别人看见。
`[dl:ask_twelve_years:18]` **lu_zhao** `[serious]`: 嗯。恨是真的，怕也是真的。先别替他下结论。
`[dl:intro:1]` **fisherman_wang** `[evasive]`: 你又来问我昨夜那眼神？先说好，我老王这回不把话说死。
`[dl:intro:2]` **lu_zhao** `[serious]`: 我不要你说死。你只说看见了什么，没看见什么。
`[dl:intro:3]` **fisherman_wang** `[evasive]`: 船头有人影。两个人，一高一矮。脸看不清，衣裳也被雾糊住。
`[dl:intro:4]` **xia_lingyao** `[determined]`: 这句比堂上松了。他先前把像说成了就是。
`[dl:intro:5]` **fisherman_wang** `[guilty]`: 人命案里，话说满了会害人。我昨夜已经害过一回嘴了。
`[dl:intro:1]` **lao_fan** `[evasive]`: 船是我撑的，人也死在我船上。陆公子要问，我认。
`[dl:intro:2]` **lu_zhao** `[serious]`: 那就从船底那一下说起。
`[dl:intro:3]` **lao_fan** `[evasive]`: 进东汊后浪横，船身先蹭了一下，后头就裂了。老船嘛，吃不住撞。
`[dl:intro:4]` **xia_lingyao** `[worried]`: 他说蹭了一下。可昨晚水灌得太快，不像慢慢裂开的。
`[dl:intro:5]` **lu_zhao** `[serious]`: 我会去看那道裂口。石头撞出来的，和人凿出来的，不会一样。
`[dl:press_route:1]` **lao_fan** `[defensive]`: 涨水时水面高，礁石该没下去。我是看水吃饭的人，也有看走眼的时候。这能全怪我？
`[dl:press_route:2]` **xia_lingyao** `[determined]`: 他说看走眼，可一提东汊，眼睛就往门外瞟。
`[dl:press_route:3]` **lu_zhao** `[serious]`: 嗯。先问他为什么非走那条水。
`[dl:ask_rescue:1]` **lao_fan** `[smirk]`: 我水性好嘛。泡了……泡了有半个时辰。江饭吃久了，水里也能咬牙熬一阵。后来有船经过，把我捞上来的。
`[dl:ask_rescue:2]` **xia_lingyao** `[shocked]`: 半个时辰？腊月的江水冷得像刀子。人在里头泡上半个时辰，怕是早就冻硬了。陆公子，咱们得查查码头的册子。
`[dl:ask_rescue:3]` **lao_fan** `[defensive]`: 我身体硬朗。年轻时候在江里扎猛子，冷水也扛过。
`[dl:ask_rescue:4]` **lu_zhao** `[serious]`: 好。那我们就按码头登记核时辰。
`[dl:ask_rescue:5]` **lu_zhao** `[worried]`: 半个时辰和一刻钟，差得足够让一个人从落水，变成先上岸等着。
`[dl:show_hull:1]` **lao_fan** `[nervous]`: 修……修过？哪条船不修呢。船跑久了要捻缝补板，这都是常事。
`[dl:show_hull:2]` **lao_fan** `[defensive]`: 翻船之前动它干嘛？吃水的饭，自己砸自己饭碗？那不是礁石还能是什么。
`[dl:show_hull:3]` **xia_lingyao** `[determined]`: 他先说没动过，又马上拿'常修船'挡。两句话贴不上。
`[dl:show_hull:4]` **lu_zhao** `[serious]`: 船上有捻凿和桐油。翻船前后，谁碰过船底？
`[dl:show_hull:5]` **lao_fan** `[defensive]`: 陆公子，船家船上有修船物件不稀奇。你要说我动过船底，总得拿准是哪一道痕。
`[dl:show_hull:6]` **lu_zhao** `[determined]`: 好。那就看洞边的凿痕和钉眼，不看口气。
`[dl:show_iou:1]` **lao_fan** `[defensive]`: 手头紧？嗐！这话说的……跑船的人哪天不紧巴？日子嘛，凑合过呗。
`[dl:show_iou:2]` **lao_fan** `[nervous]`: 跑船嘛，有时多赚有时少赚……年关难过，水浅船沉，谁家不紧巴？
`[dl:show_iou:3]` **xia_lingyao** `[determined]`: 四十二两……腊月底还不上就断指。这不是年关难过，是要命。
`[dl:show_iou:4]` **lu_zhao** `[serious]`: 四十二两。有人拿这笔债找过你吗？
`[dl:show_iou:5]` **lao_fan** `[defensive]`: 没人兜底。我自己欠的债，自己认。陆公子别把什么事都往别人身上扯。
`[dl:ask_gambling_story:1]` **lao_fan** `[defensive]`: ……你问这个干嘛。跟案子有关系？
`[dl:ask_gambling_story:2]` **lu_zhao** `[serious]`: 二十年的老船家，怎么沾上的赌？
`[dl:ask_gambling_story:3]` **lao_fan** `[dismissive]`: ……嗐。说来话长。
`[dl:ask_gambling_story:4]` **lao_fan** `[nervous]`: 那死鬼崽子要是还在……嗐，说这干啥。
`[dl:ask_gambling_story:5]` **lao_fan** `[nervous]`: 那年冬月，孩子发热烧得直说胡话，药铺要二两银子才肯抓药。我跑了一整天，一分没借到。
`[dl:ask_gambling_story:6]` **lao_fan** `[nervous]`: 回船时候码头边有人递话——"范老哥，急用银子？我认识个门路。"
`[dl:ask_gambling_story:7]` **lao_fan** `[cornered]`: 嗐！我那会儿想都没想就跟去了，想着赢了药钱就收手。谁知道那是个无底洞……
`[dl:ask_gambling_story:8]` **lu_zhao** `[serious]`: 从借钱救急，到欠四十二两，中间是谁牵的线？
`[dl:ask_gambling_story:9]` **lao_fan** `[cornered]`: 二两变五两，五两变十两……等我还不上，还是那帮人，又凑上来说可以借。
`[dl:ask_gambling_story:10]` **xia_lingyao** `[worried]`: ……孩子后来怎样了？
`[dl:ask_gambling_story:11]` **lao_fan** `[cornered]`: 到头来四十二两。那死鬼崽子……也没等到那副药。
`[dl:ask_gambling_story:12]` **lao_fan** `[cornered]`: 吃水的饭哪有不湿鞋的……嗐。
`[dl:press_shen_connection:1]` **lu_zhao** `[serious]`: 阿贵已经招了。老范，你这边也该把中间人说清楚。
`[dl:press_shen_connection:2]` **lu_zhao** `[serious]`: 找你的人，是个做药材生意的姑娘。对吗？
`[dl:press_shen_connection:3]` **narrator**: 烟杆从嘴边落了下来。整个人僵住。
`[dl:press_shen_connection:4]` **lao_fan** `[cornered]`: ……陆公子都知道了？
`[dl:press_shen_connection:5]` **lu_zhao** `[serious]`: 她怎么找上你的？条件是什么？
`[dl:press_shen_connection:7]` **lao_fan** `[cornered]`: ……是她先来的。她把我那张欠条放在桌上，说有门生意，做完了赌债一笔勾销。
`[dl:press_shen_connection:8]` **lao_fan** `[cornered]`: 我问什么生意。她说'把船弄沉就行。其他的不用管。你水性好，淹不死你。'……她连我水性好都查过了。
`[dl:press_shen_connection:9]` **lao_fan** `[cornered]`: 我……我当时被逼急了。年底不还钱赌坊说要断指……
`[dl:press_shen_connection:10]` **xia_lingyao** `[anxious]`: 她不是临时路过。她连老范哪条水熟，都先问清了。
`[dl:press_shen_connection:11]` **lu_zhao** `[serious]`: 你能认出她吗？
`[dl:press_shen_connection:12]` **lao_fan** `[cornered]`: 高个子。穿劲装。说话利索。像是做过生意的人。
`[dl:press_shen_connection:13]` **lu_zhao** `[serious]`: ……沈清月。
`[dl:intro:1]` **li_zheng** `[nervous]`: 陆公子，我这边也是夹在门缝里。周氏要凶手，县里要交代，渡口的人又怕牵连。
`[dl:intro:2]` **lu_zhao** `[serious]`: 你先别替任何人收口。把渡口知道的事说出来。
`[dl:intro:3]` **li_zheng** `[sighing]`: 能说的我说。只是有些话，平日里能当闲谈，进了案卷就要压死人。
`[dl:intro:4]` **xia_lingyao** `[worried]`: 他怕写错，也怕不写。先问能落到地方的。
`[dl:ask_reef:1]` **li_zheng** `[gossip]`: 这话不好说……不过嘛，小人从小在这儿长大，那片礁石连小孩儿都知道要绕着走。小人也是听老一辈说的。
`[dl:ask_reef:2]` **li_zheng** `[gossip]`: 涨水了也不保险。石头尖的很，水面下照样能把船底划烂。
`[dl:ask_reef:3]` **xia_lingyao** `[anxious]`: 老范跑这条江二十年，真会不知道？
`[dl:ask_reef:4]` **lu_zhao** `[cold]`: 他知道。只是昨夜还是把船带过去了。
`[dl:ask_recent_strangers:1]` **li_zheng** `[nervous]`: 异常嘛……嗯，这个不知道算不算。
`[dl:ask_recent_strangers:2]` **li_zheng** `[gossip]`: 半个月前吧。有个外地来的人在渡口打听事儿。穿得挺体面。长衫马褂，像个读书人。
`[dl:ask_recent_strangers:3]` **lu_zhao** `[surprised]`: 打听什么？
`[dl:ask_recent_strangers:4]` **li_zheng** `[gossip]`: 打听水路。问哪条航道夜里走、什么船什么时辰开。还问了。常走这条路的商客有哪些。
`[dl:ask_recent_strangers:5]` **lu_zhao** `[cold]`: 他是什么人？
`[dl:ask_recent_strangers:6]` **li_zheng** `[evasive]`: 说是南京来的。做茶叶生意。名号嘛……小人不太记得了。姓。好像姓顾？还是姓谷？反正文绉绉的。
`[dl:ask_recent_strangers:7]` **xia_lingyao** `[anxious]`: 半个月前打听水路和常客，正卡在周德茂收到信前头。
`[dl:ask_recent_strangers:8]` **lu_zhao** `[cold]`: 后来呢？
`[dl:ask_recent_strangers:9]` **li_zheng** `[evasive]`: 待了两三天就走了。小人也没多想。过路的商人来打听行情嘛，正常。
`[dl:ask_recent_strangers:10]` **lu_zhao** `[serious]`: 先是有人打听航道，半个月后周德茂收到南京来的信。
`[dl:ask_recent_strangers:11]` **xia_lingyao** `[determined]`: 不像过路闲问。他是在挑哪条船、哪一夜最好下手。
`[dl:intro:1]` **shen_qingyue** `[cooperative]`: 周德茂欠我三十八两。前天我在码头堵过他，这事不用绕。
`[dl:intro:2]` **lu_zhao** `[serious]`: 你堵他，是为讨债。
`[dl:intro:3]` **shen_qingyue** `[sharp]`: 是。药材行要周转，我爹的药也等钱。账期到了，我当然要追。
`[dl:intro:4]` **lu_zhao** `[serious]`: 可他死了，你一文也收不回来。
`[dl:intro:5]` **shen_qingyue** `[cooperative]`: 所以我才还站在这儿。凶手若不是你，就别让那人顺手替周德茂赖账。
`[dl:intro:6]` **xia_lingyao** `[worried]`: 她把话落在钱上，不落在恨上。
`[dl:ask_quarrel:1]` **shen_qingyue** `[sharp]`: 我原话是，今天不给个准日子，就别想安生上船。码头边卖茶的都听见了。
`[dl:ask_quarrel:2]` **lu_zhao** `[serious]`: 听起来像威胁。
`[dl:ask_quarrel:3]` **shen_qingyue** `[sharp]`: 讨债的话本来就不中听。我要是真想害他，会挑二十多双眼睛前先吵一场？
`[dl:ask_quarrel:4]` **xia_lingyao** `[worried]`: 她一句都没停。像早就知道我们会问到这儿。
`[dl:ask_quarrel:5]` **lu_zhao** `[serious]`: 吵完之后呢？
`[dl:ask_quarrel:6]` **shen_qingyue** `[cooperative]`: 他说明早到武昌先兑银，三日内给我。说完就让阿贵搬箱子上船。
`[dl:ask_quarrel:7]` **lu_zhao** `[serious]`: 你连阿贵搬箱子都看见了。
`[dl:ask_quarrel:8]` **shen_qingyue** `[sharp]`: 债主盯欠债人的箱子，不奇怪吧。
`[dl:ask_alibi:1]` **shen_qingyue** `[cooperative]`: 船离岸后，我就回客栈了。那晚冷，我还让伙计送过热水。
`[dl:ask_alibi:2]` **lu_zhao** `[serious]`: 伙计能作证？
`[dl:ask_alibi:3]` **shen_qingyue** `[sharp]`: 他若没睡死，该能记得。不能记得，也不能反过来说我没回。
`[dl:ask_alibi:4]` **xia_lingyao** `[worried]`: 她没有给准时辰，只把话压到伙计记不记得上。
`[dl:ask_alibi:5]` **lu_zhao** `[serious]`: 你说船离岸后就走，这句我记下了。
`[dl:ask_fan_connection:1]` **shen_qingyue** `[cooperative]`: 老范替我送过两回药箱。码头船家嘛，认得脸很平常。
`[dl:ask_fan_connection:2]` **lu_zhao** `[serious]`: 我问的是你们有没有私下说过话。
`[dl:ask_fan_connection:3]` **shen_qingyue** `[deflecting]`: 码头上说话不叫私下。问船价，问雨势，问哪条路快，这些谁都会问。
`[dl:ask_fan_connection:4]` **xia_lingyao** `[determined]`: 她答得太快了。像把这句在嘴里含了很久。
`[dl:ask_fan_connection:5]` **lu_zhao** `[serious]`: 老范欠赌债的事，你从哪听来的？
`[dl:ask_fan_connection:6]` **shen_qingyue** `[sharp]`: 赌坊讨债能闹半条街，想不听见都难。
`[dl:ask_father:1]` **narrator**: 她看见药账的一瞬间，指尖压住了袖口。只一下，很快又松开。
`[dl:ask_father:2]` **lu_zhao** `[serious]`: 八十两药钱。账上只剩四十二两。
`[dl:ask_father:3]` **shen_qingyue** `[cold_smile]`: 家里病人等药，铺子还要开门。我缺钱，不等于我会杀人。
`[dl:ask_father:4]` **lu_zhao** `[serious]`: 周德茂欠你三十八两，正好补这个缺口。
`[dl:ask_father:5]` **shen_qingyue** `[sharp]`: 所以我更该让他活着还。死人不会拿银票出门。
`[dl:ask_father:6]` **xia_lingyao** `[determined]`: 她这句接得快。可提到账上只剩四十二两时，她先按了袖口。
`[dl:press_dock_timing:1]` **lu_zhao** `[serious]`: 你说船离岸后就回客栈。可有人看见船开出去一刻钟，你还在码头。
`[dl:press_dock_timing:2]` **shen_qingyue** `[deflecting]`: 夜里雾重。高个子的女人，也不只我一个。
`[dl:press_dock_timing:3]` **lu_zhao** `[serious]`: 那人穿男装，站在你先前堵周德茂的位置。
`[dl:press_dock_timing:4]` **shen_qingyue** `[sharp]`: 债没讨到，我站一会儿吹风，不行吗？
`[dl:press_dock_timing:5]` **xia_lingyao** `[determined]`: 她把回客栈，改成了站一会儿。
`[dl:press_dock_timing:6]` **lu_zhao** `[serious]`: 一会儿之后呢？往客栈，还是往下游？
`[dl:press_dock_timing:7]` **shen_qingyue** `[cracking]`: ……往客栈。
`[dl:press_salvage:1]` **lu_zhao** `[cold]`: 沈姑娘。天亮之前，下游浅滩留下了打捞痕迹。
`[dl:press_salvage:2]` **shen_qingyue** `[sharp]`: ……所以？跟我有什么关系？
`[dl:press_salvage:3]` **lu_zhao** `[cold]`: 浅滩芦苇新折，水边有长竿划痕，还有重物拖上岸又搬走的压痕。
`[dl:press_salvage:4]` **shen_qingyue** `[deflecting]`: 陆公子，那片芦苇丛谁都能踩。江边不是沈家的后院。
`[dl:press_salvage:5]` **lu_zhao** `[serious]`: 你说你在睡觉。但那处痕迹只可能是天亮前留下的；而你那晚的去向，正缺这一段。
`[dl:press_salvage:5.1]` **lu_zhao** `[cold]`: 等等。
`[dl:press_salvage:5.2]` **lu_zhao** `[cold]`: 我没说芦苇丛。
`[dl:press_salvage:6]` **shen_qingyue** `[cold_smile]`: ……那一带都是芦苇。
`[dl:press_salvage:6.1]` **xia_lingyao** `[determined]`: 她停了。只有一下。
`[dl:press_salvage:6.2]` **lu_zhao** `[cold]`: 石矶渡下游的浅滩，多数是泥滩。你去过那里，才知道长着芦苇。
`[dl:press_salvage:7]` **xia_lingyao** `[determined]`: 她嘴上说不是自己……可你看她的手，刚才还松着，现在死死扣着扶手。
`[dl:press_salvage:8]` **xia_lingyao** `[shocked]`: 镖局走水路看漂痕。东西会往哪儿靠，不是站在码头吹一夜风就能知道的。
`[dl:press_salvage:9]` **lu_zhao** `[serious]`: 我现在只问这一处：你怎么知道那片是芦苇，不是泥滩？
`[dl:press_connection:1]` **lu_zhao** `[cold]`: 老范说了，找他的人是做药材的姑娘。
`[dl:press_connection:2]` **narrator**: 她脸上的笑一下收住了。过了一瞬，才又重新笑起来。
`[dl:press_connection:3]` **shen_qingyue** `[cold_fury]`: 他这样说了？……有意思。赌鬼输急了，连自家祖宗都能押上桌。陆公子也信？
`[dl:press_connection:4]` **lu_zhao** `[cold]`: 不只老范。阿贵也说，有人教他买浮囊、凿哪块板。
`[dl:press_connection:5]` **lu_zhao** `[serious]`: 你放下了手。
`[dl:press_connection:6]` **shen_qingyue** `[cracking]`: ……
`[dl:press_connection:7]` **narrator**: 沉默了整整五息。然后她慢慢地。把一直抱着的双臂放了下来。
`[dl:press_connection:8]` **shen_qingyue** `[cold_fury]`: 陆公子。你是来问话的，还是已经把判词写在袖子里了？
`[dl:press_connection:9]` **xia_lingyao** `[anxious]`: 她……怎么突然不笑了？
`[dl:press_connection:10]` **lu_zhao** `[serious]`: 老范说见过做药材的姑娘。阿贵说有人教他留活路。你刚才听见这两句，把手放下来了。
`[dl:confession_trigger:1]` **lu_zhao** `[serious]`: 沈姑娘，堂上说吧。
`[dl:confession_trigger:2]` **lu_zhao** `[serious]`: 老范的债，阿贵的浮囊，码头那一刻钟，下游浅滩的脚印，我都会一件件摆出来。
`[dl:confession_trigger:3]` **narrator**: 她看了看门外。雨水顺着檐角滴下，半晌才落一滴。
`[dl:confession_trigger:4]` **shen_qingyue** `[cold_fury]`: 该问的人，你几乎都问到了。
`[dl:confession_trigger:5]` **shen_qingyue** `[cold_fury]`: 不过陆公子，县衙落笔，不靠你觉得我像。
`[dl:confession_trigger:6]` **xia_lingyao** `[anxious]`: 她没认。她在等你拿那件能写进案卷的东西。
`[dl:confession_trigger:7]` **lu_zhao** `[determined]`: 那就让她等着听完。
`[dl:ask_agui:1]` **zhou_wife** `[trembling]`: 阿贵跟了老爷十二年。以前贴春联，左联贴歪了，他能撕下来重贴三遍。
`[dl:ask_agui:2]` **zhou_wife** `[trembling]`: 这两年不一样了。老爷嫌他慢，茶碗摔在他脚边，他也只蹲下去捡。
`[dl:ask_agui:3]` **zhou_wife** `[suspicious]`: 上船前，老爷还说到了武昌就打发他走。
`[dl:ask_agui:4]` **lu_zhao** `[serious]`: 打发走，给多少？
`[dl:ask_agui:5]` **zhou_wife** `[silent]`: 字据在桌上。二两。
`[dl:ask_agui:6]` **xia_lingyao** `[worried]`: 她说二两时自己都停了一下。
`[dl:ask_agui:7]` **lu_zhao** `[serious]`: 十二年，临走只给二两。他心里不会没东西。
`[dl:ask_swimming:1]` **zhou_wife** `[trembling]`: 会。他年轻时常跟船跑货，落水也能自己扒上岸。
`[dl:ask_swimming:2]` **zhou_wife** `[trembling]`: 这几年身子重了些，可水性没丢。他还总说，跑买卖的人不能怕水。
`[dl:ask_swimming:3]` **lu_zhao** `[determined]`: 那他昨晚不该这么快沉下去。
`[dl:ask_swimming:4]` **zhou_wife** `[suspicious]`: 对。所以我才不信是意外。老爷会水，老范更会水，偏偏只有老爷死了。
`[dl:ask_swimming:5]` **xia_lingyao** `[worried]`: 会水的人没扒上来，这水里还有别的事。
`[dl:ask_swimming:6]` **lu_zhao** `[serious]`: 记下。他会水，却没能上岸。
`[dl:ask_why_night_ferry:1]` **lu_zhao** `[serious]`: 你丈夫平日不赶夜船。这回为什么急？
`[dl:ask_why_night_ferry:2]` **zhou_wife** `[suspicious]`: 出发前两天，他收到一封南京来的信。
`[dl:ask_why_night_ferry:3]` **zhou_wife** `[suspicious]`: 信上说武昌有一批棉布，转到南京能翻价。还催他夜里走，误了时辰就换别人。
`[dl:ask_why_night_ferry:4]` **lu_zhao** `[serious]`: 署名是谁？
`[dl:ask_why_night_ferry:5]` **zhou_wife** `[suspicious]`: 没有。只写故友知会。字倒工整，工整得不像跑买卖的人写的。
`[dl:ask_why_night_ferry:6]` **xia_lingyao** `[determined]`: 知道他缺这笔生意，又知道夜船时辰。这信不是随手寄的。
`[dl:ask_why_night_ferry:7]` **lu_zhao** `[serious]`: 那封信随他上船了？
`[dl:ask_why_night_ferry:8]` **zhou_wife** `[silent]`: 是。他贴身收着。现在也许在江里，也许不在了。
`[dl:react_murder_confirmed:1]` **lu_zhao** `[serious]`: 周氏。你丈夫的船底，有一个被凿出来的洞。
`[dl:react_murder_confirmed:2]` **lu_zhao** `[serious]`: 不是意外。是有人故意的。
`[dl:react_murder_confirmed:3]` **narrator**: 周氏全身僵住。手里的帕子掉在地上，她没去捡。
`[dl:react_murder_confirmed:4]` **lu_zhao** `[serious]`: 我不会骗你。
`[dl:react_murder_confirmed:5]` **zhou_wife** `[screaming]`: ……我就知道不是意外。老爷他。
`[dl:react_murder_confirmed:6]` **zhou_wife** `[grief]`: ……求您。一定要查清楚。
`[dl:react_murder_confirmed:7]` **xia_lingyao** `[worried]`: ……她哭了。这种哭法不是假的。陆公子，她是真的不知道。
`[dl:react_murder_confirmed:8]` **lu_zhao** `[worried]`: ……
`[dl:react_agui_confessed:1]` **lu_zhao** `[cold]`: 周氏。阿贵认了。船底是他凿的。
`[dl:react_agui_confessed:2]` **zhou_wife** `[shocked]`: 阿贵。他跟了老爷十二年。
`[dl:react_agui_confessed:3]` **zhou_wife** `[shocked]`: 十二年啊。吃一口锅里的饭、睡一个屋檐下。他怎么下得去手？
`[dl:react_agui_confessed:4]` **lu_zhao** `[serious]`: 二两银子。十二年。
`[dl:react_agui_confessed:5]` **zhou_wife** `[screaming]`: 二两……是少了点。可也不至于。
`[dl:react_agui_confessed:6]` **lu_zhao** `[serious]`: 他背后还有人。是别人教他做的。
`[dl:react_agui_confessed:7]` **zhou_wife** `[interrogating]`: 还有人？！谁？！
`[dl:react_agui_confessed:8]` **lu_zhao** `[determined]`: 还在查！会有结果的！
`[dl:react_agui_confessed:9]` **xia_lingyao** `[worried]`: 她不光是恨……还有伤心。贴对联的人，亲手凿了她丈夫的船。
`[dl:ask_channel:1]` **fisherman_wang** `[evasive]`: 东汊。那条水面看着平，底下石头像牙。
`[dl:ask_channel:2]` **fisherman_wang** `[evasive]`: 本地撑船的，闭着眼也会绕开。涨水也不保险，石尖藏在水皮下头。
`[dl:ask_channel:3]` **lu_zhao** `[serious]`: 老范跑了二十年，不会不知道。
`[dl:ask_channel:4]` **fisherman_wang** `[angry]`: 他要说不知道，我把这张老脸按进江里给他洗眼睛。
`[dl:ask_channel:5]` **xia_lingyao** `[determined]`: 这不是失误。至少不是普通失误。
`[dl:ask_meeting:1]` **fisherman_wang** `[evasive]`: 前一晚……对，我那天也收了夜网。
`[dl:ask_meeting:2]` **fisherman_wang** `[evasive]`: 路过码头的时候，看到两个人蹲在角落里说话。黑灯瞎火的，偷偷摸摸的。
`[dl:ask_meeting:3]` **lu_zhao** `[cold]`: 他们说了什么？
`[dl:ask_meeting:4]` **fisherman_wang** `[evasive]`: 一高一矮。高的像是那仆从。腰板直。矮的精瘦精瘦的。像船家。
`[dl:ask_meeting:5]` **lu_zhao** `[serious]`: 你确定高的是阿贵？
`[dl:ask_meeting:5.1]` **xia_lingyao** `[anxious]`: 那晚他们说了什么？声音大不大？
`[dl:ask_meeting:5.2]` **fisherman_wang** `[evasive]`: （看了凌瑶一眼，话停了）……我没听见说话。只是看见。
`[dl:ask_meeting:5.3]` **xia_lingyao** `[worried]`: （低声，对陆昭）对不住，问急了。
`[dl:ask_meeting:6]` **fisherman_wang** `[evasive]`: 我当时没在意。第二天出了事才想起来。
`[dl:ask_meeting:7]` **xia_lingyao** `[anxious]`: 案发前一晚两人鬼祟说话……这时间点也太巧了。
`[dl:trust:1]` **fisherman_wang** `[evasive]`: 我活了一辈子，在这江上。这江面夜里是什么声气，我闭着眼都听得出来。
`[dl:trust:2]` **fisherman_wang** `[evasive]`: 见过太多死在水里的人。有些是真出事，有些一看就不对。
`[dl:trust:3]` **lu_zhao** `[serious]`: 有些是命，有些不是……你看到了什么？
`[dl:trust:4]` **fisherman_wang** `[evasive]`: 那天夜里……那人扑腾的声音不对。我听了四十年水声，人真溺水的时候，手乱拍，声儿很急，听得出来。
`[dl:trust:5]` **lu_zhao** `[serious]`: 谁？谁让你别管的？
`[dl:trust:6]` **fisherman_wang** `[angry]`: 有人跟我说'别多管闲事'。还往我船上扔了两条鱼，说是'谢礼'。放屁。我这一辈子没收过这种黑心鱼。杀了人就该偿命。
`[dl:trust:7]` **lu_zhao** `[serious]`: 谢了。
`[dl:ask_dawn_sighting:1]` **fisherman_wang** `[evasive]`: 天还没亮的时候。鸡叫头遍那会儿。我在下游浅滩收夜网，看见芦苇倒了一片。
`[dl:ask_dawn_sighting:2]` **fisherman_wang** `[evasive]`: 水边有长竿探过的划痕，还有重东西拖上岸的泥印。新得很，不像白天留下的。
`[dl:ask_dawn_sighting:3]` **lu_zhao** `[cold]`: 看清是谁留下的吗？
`[dl:ask_dawn_sighting:4]` **fisherman_wang** `[evasive]`: 看不清，也不敢再乱说。你们要查，就查浅滩泥印和芦苇折口。
`[dl:ask_dawn_sighting:5]` **xia_lingyao** `[anxious]`: 嘴会改，泥不会。陆公子，去浅滩看脚印和折口。
`[dl:ask_dawn_sighting:6]` **lu_zhao** `[serious]`: 嗯。下游浅滩要查现场，不靠目击。
`[dl:ask_river_life:1]` **fisherman_wang** `[evasive]`: 我在这江上打了一辈子鱼。
`[dl:ask_river_life:2]` **fisherman_wang** `[evasive]`: 哪条汊水有暗礁，哪片浅滩能藏东西，心里都有数。
`[dl:ask_river_life:3]` **lu_zhao** `[serious]`: 你对这片江很熟。
`[dl:ask_river_life:4]` **fisherman_wang** `[angry]`: 所以我才说。老范那样的老船家，绝不可能糊里糊涂把船往东汊暗礁上带。
`[dl:ask_river_life:5]` **lu_zhao** `[serious]`: 谢了！我记下了。
`[dl:ask_route:1]` **lao_fan** `[evasive]`: 周老板催得急，说天亮前要赶到武昌。我就拣近的水道走。
`[dl:ask_route:2]` **lu_zhao** `[serious]`: 近路就是东汊？
`[dl:ask_route:3]` **lao_fan** `[defensive]`: 涨水后看着能过。老船家也有看走眼的时候嘛。
`[dl:ask_route:4]` **xia_lingyao** `[determined]`: 他把知道有礁，改成了看走眼。
`[dl:ask_route:5]` **lu_zhao** `[serious]`: 看走眼，和明知还走，是两回事。
`[dl:ask_fan:1]` **li_zheng** `[nervous]`: 老范嘛……人还行。就是爱赌。以前小赌怡情，这两年越赌越大。
`[dl:ask_fan:2]` **li_zheng** `[nervous]`: 听说欠了赌坊不少钱。前阵子还有人来找他要账，闹得挺凶。
`[dl:ask_fan:3]` **lu_zhao** `[cold]`: 欠了多少？
`[dl:ask_fan:4]` **lu_zhao** `[serious]`: 如果有人拿欠条逼他呢？
`[dl:ask_fan:5]` **li_zheng** `[nervous]`: 不过嘛。案卷不能只写坏处。他水性好，人也实在。年轻时候还救过落水的孩子，全渡口都知道。
`[dl:ask_fan:6]` **xia_lingyao** `[anxious]`: 债能把人逼低头。有人若拿着欠条找他，他未必撑得住。
`[dl:ask_agui_spending:1]` **li_zheng** `[nervous]`: 异常嘛……嗐，也不能说异常。就是。
`[dl:ask_agui_spending:2]` **li_zheng** `[nervous]`: 他昨天在客栈买了壶好酒，又打了半斤卤肉。出手挺阔的。
`[dl:ask_agui_spending:3]` **lu_zhao** `[serious]`: 刚死了主人就买酒吃肉？
`[dl:ask_agui_spending:4]` **li_zheng** `[nervous]`: 按说刚死了主人的仆从……哪有心情喝酒吃肉啊？而且他马上要被遣散了，身上能有几个钱？
`[dl:ask_agui_spending:5]` **xia_lingyao** `[determined]`: 主人刚死还能吃肉喝酒，除非他知道自己今晚不会挨饿。
`[dl:ask_victim:1]` **li_zheng** `[nervous]`: 知道知道。做布匹生意的，来往走水路常歇在咱这儿。
`[dl:ask_victim:2]` **li_zheng** `[nervous]`: 人嘛……精明是精明的。就是待下人刻薄了些。动不动呵斥，小人听过好几回了。
`[dl:ask_victim:3]` **lu_zhao** `[serious]`: 十二年的刻薄……
`[dl:ask_victim:4]` **li_zheng** `[nervous]`: 不过嘛。人死了，案卷上不好写太多坏话。大事化小，嘴也化小些。
`[dl:ask_victim:5]` **lu_zhao** `[serious]`: 十二年……受的恐怕不止这些。
`[dl:intro:1]` **zhou_wife** `[trembling]`: 你问吧。可别拿自证清白四个字来堵我。我丈夫躺在外头，不是给谁洗名声用的。
`[dl:intro:2]` **lu_zhao** `[serious]`: 我问的是他为什么上那条船。
`[dl:intro:3]` **zhou_wife** `[suspicious]`: 他去武昌进布，带了五十两货银。平日他舍不得赶夜船，这回却像被火追着。
`[dl:ask_suspicion:1]` **zhou_wife** `[suspicious]`: 阿贵不对劲。案发后他哭得比我都凶。可他跟老爷关系好吗？不好。
`[dl:ask_suspicion:2]` **zhou_wife** `[suspicious]`: 上船前还被骂了一通，当晚就哭天抹泪？我不信。
`[dl:ask_suspicion:3]` **lu_zhao** `[cold]`: 确实反常。
`[dl:ask_suspicion:4]` **zhou_wife** `[suspicious]`: 还有。老爷会水，年轻时跟船跑货，落水也能自己爬上来。普通翻船不该这么快没命。
`[dl:ask_suspicion:5]` **xia_lingyao** `[determined]`: 你说得对。一个挨了骂的仆从，哭得比主人的妻子还凶。这哭声太满了。
`[dl:comfort:1]` **lu_zhao** `[serious]`: ……我会查到底。
`[dl:comfort:2]` **zhou_wife** `[relieved]`: ……你不像凶手。凶手不会还留在这里问话。
`[dl:comfort:3]` **zhou_wife** `[relieved]`: 里正让你查。你要是真能查出来……老爷的文书都在房间桌上。你看吧。
`[dl:ask_documents:1]` **zhou_wife** `[suspicious]`: 都在房间里。陆公子自己去看吧。遣散字据、货单都在桌上。
`[dl:ask_documents:2]` **lu_zhao** `[serious]`: 多谢。
`[dl:ask_documents:3]` **lu_zhao** `[serious]`: 多谢。

# 第三幕 · 日程事件


## 事件: 整理疑点

- **触发**: {'all': [{'location': 'cabin_lu_room'}, {'flag': 'cabin_seal_box_checked'}, {'flag': 'cabin_route_note_checked'}, {'any': [{'flag': 'cabin_agui_talked'}, {'flag': 'cabin_lao_fan_talked'}, {'flag': 'cabin_zhou_talked'}]}, {'not': {'flag': 'cabin_review_done'}}, {'not': {'flag': 'cabin_phase_done'}}]}
- **提示**: （你回到了自己的舱室。雨声不停，风越来越大。该把船舱里的异常先记下来。）

## 事件: 沉船惊变

- **触发**: {'all': [{'flag': 'cabin_review_done'}, {'not': {'flag': 'evt_cabin_sinking_done'}}, {'not': {'flag': 'accused_of_murder'}}]}
- **提示**: 夜深了。雨声越来越重。

## 事件: 客栈深处

- **触发**: {'all': [{'flag': 'evt_cabin_sinking_done'}, {'location': 'ferry_inn'}, {'not': {'flag': 'evt_inn_recovery_done'}}, {'not': {'flag': 'accused_of_murder'}}]}
- **提示**: 

## 事件: 自证清白

- **触发**: {'all': [{'flag': 'confrontation_wang_completed'}, {'not': {'flag': 'self_cleared'}}]}
- **提示**: 王大爷的证词被推翻

## 事件: 人为破坏

- **触发**: {'all': [{'flag': 'self_cleared'}, {'any': [{'location': 'ferry_dock'}, {'location': 'wreck_site'}]}, {'evidence': 'evidence_hull_hole'}, {'not': {'flag': 'evt_hull_discovered_done'}}]}
- **提示**: （你发现了船底的人工破洞）

## 事件: 预谋逃生

- **触发**: {'all': [{'evidence': 'evidence_float_bladder'}, {'not': {'flag': 'evt_bladder_found_done'}}]}
- **提示**: （你在沉船下游的芦苇丛中发现了阿贵的包袱和浮囊）

## 事件: 二两遣散银

- **触发**: {'all': [{'evidence': 'evidence_dismissal_note'}, {'not': {'flag': 'evt_dismissal_revealed_done'}}]}
- **提示**: （你发现了遣散字据）

## 事件: 赌鬼的绝路

- **触发**: {'all': [{'flag': 'agui_confessed_mastermind'}, {'evidence': 'evidence_gambling_iou'}, {'not': {'flag': 'evt_gambling_debt_done'}}]}
- **提示**: （你发现了老范的赌债借据）

## 事件: 馒头

- **触发**: {'all': [{'evidence_count_gte': 2}, {'location': 'ferry_inn'}, {'not': {'flag': 'evt_quiet_moment_done'}}, {'not': {'flag': 'agui_confessed_mastermind'}}]}
- **提示**: 

## 事件: 催促

- **触发**: {'all': [{'day_gte': 2}, {'not': {'flag': 'evt_lizheng_pressure_done'}}, {'not': {'flag': 'agui_confessed_mastermind'}}]}
- **提示**: 

## 事件: 证据齐了——可以对峙了

- **触发**: {'all': [{'evidence': 'evidence_hull_hole'}, {'evidence': 'evidence_float_bladder'}, {'evidence': 'evidence_no_blunt_trauma'}, {'clue': 'clue_fan_alibi_hole'}, {'evidence': 'evidence_dismissal_note'}, {'not': {'flag': 'confrontation_auto_triggered'}}]}
- **提示**: ✦ 关键证据已齐，点击发起对峙

## 事件: 客栈变局

- **触发**: {'all': [{'flag': 'agui_confessed_mastermind'}, {'not': {'flag': 'evt_phase3_transition_done'}}]}
- **提示**: 

## 事件: 重新审视的物证

- **触发**: {'all': [{'flag': 'evt_phase3_transition_done'}, {'location': 'ferry_inn'}, {'evidence': 'evidence_float_bladder'}, {'not': {'flag': 'bladder_meaning_revised'}}]}
- **提示**: 

## 事件: 该收网了

- **触发**: {'all': [{'flag': 'agui_confessed_mastermind'}, {'evidence': 'evidence_cargo_silver'}, {'clue': 'evidence_salvage_mark'}, {'clue': 'evidence_shen_connection'}, {'clue': 'evidence_dock_timing'}, {'evidence': 'evidence_drug_capsule_shell'}, {'evidence': 'evidence_tongue_herb_residue'}, {'evidence': 'evidence_oil_lock_residue'}, {'not': {'flag': 'evt_shen_evidence_ready_done'}}]}
- **提示**: 

## 事件: 船身异动

- **触发**: {'all': [{'location': 'cabin_lu_room'}, {'any': [{'all': [{'flag': 'cabin_route_note_checked'}, {'flag': 'cabin_storm_window_checked'}]}, {'all': [{'flag': 'cabin_route_note_checked'}, {'flag': 'cabin_wet_cloak_checked'}]}, {'all': [{'flag': 'cabin_storm_window_checked'}, {'flag': 'cabin_wet_cloak_checked'}]}]}, {'not': {'flag': 'evt_cabin_unease_done'}}, {'not': {'flag': 'cabin_explore_done'}}]}
- **提示**: 船舱里有些不对劲。

## 事件: 终局前夜

- **触发**: {'all': [{'flag': 'evt_shen_evidence_ready_done'}, {'not': {'flag': 'evt_night_before_shen_done'}}, {'not': {'flag': 'shen_confrontation_triggered'}}]}
- **提示**: 夜深了。证据齐了，但明天要面对的是沈清月。
`[del:1]` **陆昭** `[inner_thought]`: 回舱。把刚才听到的几句话先按住。
`[del:2]` **陆昭** `[inner_thought]`: 周德茂的铜锁箱。阿贵的包袱。老范那句别开窗。三样东西都不该同时让我不安。
`[del:3]` **陆昭** `[anxious]`: 先睡不成了。再听一会儿水声。
  *背景: res://assets/cn/scenes/prologue_ship_cabin_lu_room.png*
`[del:0]` **叙述**: 夜深。船舱只剩半盏油灯。雨敲在船篷上，像有人隔着木板细细敲门。
`[del:1]` **陆昭** `[inner_thought]`: 水声不对。
  *背景: res://assets/cn/scenes/prologue_ship_cabin_night.png*
`[del:2]` **叙述**: 船底忽然传来一声闷响。下一瞬，地板从脚下歪过去。
`[del:3]` **陆昭** `[panic]`: 官印匣！
`[del:4]` **叙述**: 冷水从底舱缝里冲上来。灯灭了，四周只剩木头断裂和人喊人的声音。
`[del:5]` **陆昭** `[vulnerable]`: 抓不到。箱子也好，舱门也好，全在往下沉。
`[del:6]` **叙述**: 水压像一只手按住胸口。你摸到天窗边的铁器，狠狠撬了一下。
  *背景: res://assets/cn/scenes/prologue_shore_rescue.png*
`[del:7]` **叙述**: 木栓断开。江水裹着你撞出船舱，夜色和浪一起压下来。
  *背景: res://assets/cn/scenes/prologue_cg_lingyao_meets_luzhao.png*
`[del:8]` **凌瑶** `[determined]`: 抓住我！别松手！
`[del:9]` **叙述**: 有人从水里扣住你的手腕。那只手很稳，把你从冰冷里硬拽出来。
  *背景: res://assets/cn/scenes/prologue_ferry_inn_aftermath.png*
`[del:10]` **叙述**: 石矶渡客栈。火盆噼啪作响。你醒来时，喉咙里全是江水的腥味。
`[del:11]` **凌瑶** `[concerned]`: 别急着起。你刚才连咳都咳不出来。
`[del:12]` **陆昭** `[panic]`: 我的官印匣呢？
`[del:13]` **凌瑶** `[serious]`: 我捞的是人，不是木匣。你先活着。
`[del:14]` **陆昭** `[serious]`: 陆昭。昨夜同船的，还有布商周德茂，仆从阿贵，船家老范。
`[del:15]` **凌瑶** `[determined]`: 凌瑶。金鳞镖局。路过这里押一封急件，顺手捞了个人。
  *背景: res://assets/cn/scenes/prologue_ferry_dock.png*
`[del:16]` **叙述**: 天刚亮，下游浅滩又抬回来一具尸首。湿衣贴在身上，脸已经青了。
`[del:17]` **陆昭** `[serious]`: 周德茂。
`[del:18]` **凌瑶** `[worried]`: 阿贵和老范都活着，死的是会水的布商。
  *背景: res://assets/cn/scenes/prologue_cg_zhou_kneel.png*
`[del:19]` **周氏** `[grief]`: 昨夜他还在说武昌的货，今天就躺在这儿。谁害的他？
`[del:20]` **阿贵** `[nervous]`: 夫人，小的看见陆公子在底舱口。手里像拿着铁的东西。
`[del:21]` **陆昭** `[serious]`: 那是我撬天窗逃命用的。
`[del:22]` **老范** `[shaken]`: 我没看清谁害谁。可船翻前，舱里确实响过铁碰木头的声。
`[del:23]` **周氏** `[accusing]`: 一个说没看清，一个说只为逃命。可我家老爷死了，你活着。
`[del:24]` **叙述**: 人群后方，沈清月没有往前挤。她只抬了抬眼，声音却压住了哭声。
`[del:25]` **沈清月** `[sharp]`: 先别吵。阿贵说看见，就让他说清楚看见哪只手，哪件铁器。
`[del:26]` **沈清月** `[sharp]`: 陆公子说船底进水，也该说清楚你怎么知道是船底。
`[del:27]` **凌瑶** `[angry]`: 他刚从江里捞回来，话都没喘匀。你倒问得稳。
`[del:28]` **钱里正** `[stern]`: 够了。人命在这儿，谁都别先把话钉死。
`[del:29]` **钱里正** `[stern]`: 陆公子，您眼下也脱不了嫌疑。先到客栈堂上，把能看见能听见的，一句句说清。
`[del:30]` **陆昭** `[determined]`: 我没害周德茂。船也不是自己翻的。
`[del:31]` **凌瑶** `[determined]`: 那就查。先把他们说满的地方拆开。
`[del:32]` **叙述**: 王大爷被人从门边请出来。他搓着冻红的手，眼神一直往地上躲。
`[del:1]` **钱里正** `[stern]`: 王大爷的话不能再当铁证。陆公子，这一层我记下。
`[del:2]` **凌瑶** `[determined]`: 洗掉一盆脏水，不等于船就干净了。
`[del:3]` **陆昭** `[serious]`: 去看船。阿贵和老范的话，都得落到木板上。
`[del:1]` **陆昭** `[serious]`: 洞口边缘太齐。木刺朝外，不像撞进去，像从里头开出来。
`[del:2]` **凌瑶** `[determined]`: 暗礁不会挑一块板子下手。
`[del:3]` **陆昭** `[serious]`: 这不是翻船，是有人让船在该沉的时候沉。
`[del:1]` **凌瑶** `[shocked]`: 包袱底下这东西还鼓着。牛皮缝线里全是江泥。
`[del:2]` **陆昭** `[serious]`: 阿贵说自己抱木板活下来。可浮囊已经替他说了另一句。
`[del:3]` **凌瑶** `[determined]`: 一个不会水的人，先把活路藏在衣服底下。
`[del:1]` **陆昭** `[serious]`: 给银二两，各不相欠。周德茂写得很省墨。
`[del:2]` **凌瑶** `[worried]`: 十二年被写成二两，谁看了都冷。
`[del:3]` **陆昭** `[serious]`: 冷不等于杀人。但冷到这份上，别人递话时，他会听。
`[del:1]` **陆昭** `[serious]`: 四十二两，腊月底不还，断指抵债。
`[del:2]` **凌瑶** `[determined]`: 这不是手头紧，是催债的人已经按到门上了。
`[del:3]` **陆昭** `[serious]`: 老范要么自己认，要么说出谁拿欠条找过他。
`[del:1]` **陆昭** `[serious]`: 阿贵的浮囊不只是逃生物。它说明有人提前告诉他，船会进水。
`[del:2]` **凌瑶** `[worried]`: 他怕水，所以听得进去。也因为恨，所以敢听下去。
`[del:0]` **叙述**: 客栈后廊。雨小了，檐下还在滴水。
`[del:1]` **凌瑶** `[gentle]`: 老板蒸了馒头。拿着，别又说不饿。
`[del:2]` **陆昭** `[tired]`: 我确实不饿。
`[del:3]` **凌瑶** `[gentle]`: 那就当手炉。你手冷得不像活人。
`[del:4]` **陆昭** `[gentle]`: 多谢。
`[del:5]` **凌瑶** `[playful]`: 谢先欠着。案子完了，请我吃顿热的。
`[del:1]` **钱里正** `[stern]`: 陆公子，县里的人下午前就到。到时候若还没新证，您这嫌疑我压不住。
`[del:2]` **陆昭** `[serious]`: 我知道。
`[del:3]` **凌瑶** `[determined]`: 那就快。先找木板，再找人话里的缝。
`[del:1]` **陆昭** `[inner_thought]`: 这船晃得太急。风雨是一回事，底下像还有别的声音。
`[del:2]` **陆昭** `[inner_thought]`: 老范说别开窗。可他为什么先想到窗？
`[del:0]` **叙述**: 客栈房间。火盆还亮着，窗纸被雨吹得发白。
`[del:1]` **凌瑶** `[gentle]`: 你醒了就别乱动。掌柜说你刚才冻得牙都合不上。
`[del:2]` **陆昭** `[vulnerable]`: 我欠你一条命。
`[del:3]` **凌瑶** `[serious]`: 记账可以，先活过今晚。你到底惹上什么事，等能坐稳了再说。
`[del:1]` **钱里正** `[stern]`: 阿贵画押了。可口供只能开门，不能单独押沈清月。
`[del:2]` **钱里正** `[stern]`: 要动她，得找她自己留下的东西。时辰、银子、药，哪样都得对得上她的脚步。
`[del:3]` **凌瑶** `[worried]`: 她不会像阿贵那样哭。她会把每样东西拆开说。
`[del:4]` **陆昭** `[serious]`: 那就让每一样都回到昨夜那条船上。
`[del:1]` **凌瑶** `[determined]`: 阿贵这边能进堂了。你手里这几件，够把他的话一层层拆开。
`[del:2]` **陆昭** `[serious]`: 先拆阿贵，再拆他身后的人。
`[del:1]` **凌瑶** `[determined]`: 银子，浅滩，码头时辰，药囊残壳，都齐了。
`[del:2]` **陆昭** `[serious]`: 齐不等于稳。她会说每一件都没碰到她手上。
`[del:3]` **凌瑶** `[determined]`: 那就先问她的手。再问她走过哪儿。
`[del:0]` **叙述**: 终局前夜。客栈二楼安静下来，只剩雨后水滴从檐角落下。
`[del:1]` **陆昭** `[inner_thought]`: 官印还在江底。明天堂上，我还是那个刚洗清嫌疑的人。
`[del:2]` **陆昭** `[vulnerable]`: 怕的不是沈清月会赢。怕的是我把事实说对了，却没有一件能让县衙落笔。
`[del:3]` **叙述**: 门轻轻推开。凌瑶端着一盏热茶站在外面。
`[del:4]` **凌瑶** `[worried]`: 在这儿坐多久了？
`[del:5]` **陆昭** `[tired]`: 不知道。
`[del:6]` **凌瑶** `[determined]`: 那就别一个人坐。明天我站你旁边，听她怎么拆，我们再一件件装回去。
`[del:7]` **陆昭** `[vulnerable]`: 如果最后还是让她走呢？
`[del:8]` **凌瑶** `[determined]`: 那也要让所有人听见，她是从哪道缝里走的。
`[del:9]` **陆昭** `[determined]`: 好。明天进堂。

# 第四幕 · 证词对峙


## 证人陈述

`[ts:testimony_wang_self:wang_s1]` **王大爷** `[evasive]`: 那晚我在岸边收网。船头那边晃着两个人影。
`[ts:testimony_wang_self:wang_s1a]` **王大爷** `[evasive]`: 一高一矮。隔着点儿。高的在外侧，矮的挨着舱口。
`[ts:testimony_wang_self:wang_s1b]` **王大爷** `[evasive]`: 江上有雾，我脸看不真，只看见那两个人一直在动。
`[ts:testimony_wang_self:wang_s1c]` **王大爷** `[guilty]`: 当时我心里就不安。大半夜的，在船头那样晃，总不像好事。
`[ts:testimony_wang_self:wang_s2]` **王大爷** `[evasive]`: 船离岸虽有一段，我那会儿就觉得高个儿像陆公子。
`[ts:testimony_wang_self_hearing:wang_h0]` **王大爷** `[evasive]`: 先是一阵喊。隔着风雨，我只听得出那边乱起来了。
`[ts:testimony_wang_self_hearing:wang_h1]` **王大爷** `[evasive]`: 雨打船棚，浪拍木板，人声和水声搅在一块。
`[ts:testimony_wang_self_hearing:wang_h2]` **王大爷** `[evasive]`: 像是一个拦着，一个硬要往前去，我那时就听出个大概。
`[ts:testimony_wang_self_hearing:wang_h3]` **王大爷** `[guilty]`: 等船身一歪，我才把前头那些动静想连起来。
`[ts:testimony_wang_self_hearing:wang_s3]` **王大爷** `[guilty]`: 我记得有人嚷过银子，也像有人喊别走。可我不敢把字咬得太死。
`[ts:testimony_wang_self_escape:wang_s4]` **王大爷** `[evasive]`: 船翻后没多久，南岸那边就有人上去了。我远远瞧着像陆公子。
`[ts:testimony_wang_self_escape:wang_s4a]` **王大爷** `[evasive]`: 那人上岸倒快，手一撑石头，人就上去了。
`[ts:testimony_wang_self_escape:wang_s4b]` **王大爷** `[evasive]`: 我在江上活得久，落水的人什么样，我心里大概有个数。
`[ts:testimony_wang_self_escape:wang_s5]` **王大爷** `[guilty]`: 后来里正问我，我一慌，就顺着把这话说下去了。
`[ts:testimony_wang_self_escape:wang_s5b]` **王大爷** `[guilty]`: 真要说亲眼看见陆公子害人，我没有。我是越想越怕，话也越说越满。
`[ts:testimony_wang_shen_counter:wang_shen_0]` **沈清月** `[sharp]`: 王大爷后头的话是说满了，可陆公子的说法，也不是天生就站得住。
`[ts:testimony_wang_shen_counter:wang_shen_0a]` **沈清月** `[sharp]`: 你说自己昏迷许久，这话是谁替你按的印。
`[ts:testimony_wang_shen_counter:wang_shen_0b]` **沈清月** `[sharp]`: 不是周家人，也不是渡口旧识，偏偏是昨夜才到此地的凌姑娘。
`[ts:testimony_wang_shen_counter:wang_shen_0c]` **沈清月** `[sharp]`: 她这份来历若说不清，你那段上岸时辰，也就跟着发虚。
`[ts:testimony_wang_shen_counter:wang_shen_1]` **沈清月** `[sharp]`: 所以我只问一句：凌姑娘凭什么能替你作这个证。
`[ts:testimony_lao_fan_route:fan_route_1]` **老范** `[evasive]`: 那晚雨大雾也大嘛。船先走得还顺，一进东汊水就发横了。
`[ts:testimony_lao_fan_route:fan_route_2]` **老范** `[evasive]`: 船底那个洞，多半是碰着暗礁嘛。老船旧了，撞一下就要命。
`[ts:testimony_lao_fan_route:fan_route_3]` **老范** `[evasive]`: 嗐，我也是跑船吃饭的人。船翻了，我自己都差点交代在江里。
`[ts:testimony_lao_fan_route:fan_route_4]` **老范** `[evasive]`: 翻船前一日我补过两块旧板嘛。旧船补补钉钉，很平常。
`[ts:testimony_lao_fan_route:fan_route_5]` **老范** `[evasive]`: 夜里催得急，雨又压着江面。那种时候，谁敢把话说死嘛。
`[ts:testimony_lao_fan_rescue:fan_rescue_1]` **老范** `[evasive]`: 船一斜我就栽下去了嘛。冰水一灌，人先乱了。
`[ts:testimony_lao_fan_rescue:fan_rescue_2]` **老范** `[evasive]`: 我在水里扑腾了好一阵，才让下游的人拖上岸。谁拖的我真记不清。
`[ts:testimony_lao_fan_rescue:fan_rescue_3]` **老范** `[evasive]`: 周老爷会水，阿贵又慌。我连自己都顾不上，哪还顾得上他们嘛。
`[ts:testimony_lao_fan_rescue:fan_rescue_4]` **老范** `[evasive]`: 水里黑成一团，嗐，耳边全是浪。我哪看得见谁在哪里。
`[ts:testimony_lao_fan_rescue:fan_rescue_5]` **老范** `[evasive]`: 上岸后我就缩在火边烤着。手脚发僵，话都说不顺了嘛。
`[ts:testimony_lao_fan_motive:fan_motive_1]` **老范** `[evasive]`: 我跟周老爷就是一趟船钱的来往嘛。送过江，收钱，仅此而已。
`[ts:testimony_lao_fan_motive:fan_motive_2]` **老范** `[evasive]`: 嗐，我虽穷，还没穷到为了几两银子杀人嘛。
`[ts:testimony_lao_fan_motive:fan_motive_3]` **老范** `[evasive]`: 人死了，货没了，船也没了。我能落着什么好处嘛。
`[ts:testimony_lao_fan_motive:fan_motive_4]` **老范** `[evasive]`: 药材行的人找过我没有？码头上那么多人搭话，我哪记得清嘛。
`[ts:testimony_lao_fan_motive:fan_motive_5]` **老范** `[evasive]`: 二十年的船都搭进去了。陆公子，你说我图什么嘛。
`[ts:testimony_0:s0_1]` **阿贵** `[nervous]`: 三更后小的起来解手，瞧见陆公子蹲在底舱口，身边还搁着个铁家伙。
`[ts:testimony_0:s0_2]` **阿贵** `[defensive]`: 就是他害了老爷。小的听见一声闷响，老爷随后就没动静了。
`[ts:testimony_0:s0_3]` **阿贵** `[defensive]`: 他后来是从天窗那边跑的。小的慌得厉害，可方向不会看错。
`[ts:testimony_0:s0_4]` **阿贵** `[defensive]`: 小的看见他伏在老爷旁边，一只手压着人。那样子绝不是救人。
`[ts:testimony_0:s0_5]` **阿贵** `[nervous]`: 老爷落水后，小的也伸手去拉了，可船一晃，小的自己先摔进了水里。
`[ts:testimony_1:s1_1]` **阿贵** `[nervous]`: 那晚老爷赶路，小的跟着伺候。上船后，小的就在舱里守着。
`[ts:testimony_1:s1_2]` **阿贵** `[defensive]`: 船翻得太快了，小的一点准备都没有。人掉下去时，脑子都木了。
`[ts:testimony_1:s1_3]` **阿贵** `[nervous]`: 小的不会水。落下去以后，只记得一阵冰冷，后头的事都糊了。
`[ts:testimony_1:s1_4]` **阿贵** `[nervous]`: 小的摸到客栈时浑身都湿了，冻得牙直响。
`[ts:testimony_1:s1_5]` **阿贵** `[nervous]`: 上船后老爷就靠着歇了。起先江面还算平稳，小的真没想到会出事。
`[ts:testimony_2:s2_1]` **阿贵** `[nervous]`: 老范先前提过一句，说东汊这段水不好走。小的怕水，才把浮囊带上。
`[ts:testimony_2:s2_2]` **阿贵** `[defensive]`: 船底那洞就是暗礁撞的。小的后来听人说，那片礁石最会咬船。
`[ts:testimony_2:s2_3]` **阿贵** `[panic]`: 也有人路上劝过小的，说夜里水险，不会水就该多防着些。可他不知道老爷要打发小的回乡，只是顺口提醒。
`[ts:testimony_2:s2_4]` **阿贵** `[defensive]`: 那洞若是从里头开，船里的人先倒霉。小的哪敢拿自己命去赌。
`[ts:testimony_2:s2_5]` **阿贵** `[evasive]`: 东汊走哪条线、停哪个弯，都是老范说了算。小的只是跟着走，哪懂那些。
`[ts:testimony_3:s3_1]` **阿贵** `[nervous]`: 老爷管小的吃住，小的跟了十二年，哪会平白害他。
`[ts:testimony_3:s3_2]` **阿贵** `[defensive]`: 老爷遣小的回乡，还给了路费。主仆一场，小的只有认命。
`[ts:testimony_3:s3_3]` **阿贵** `[defensive]`: 要说谁最懂那条水路，当然是老范。走哪边，停哪边，都是他拿主意。
`[ts:testimony_3:s3_4]` **阿贵** `[defensive]`: 小的就是个使唤人。叫做什么做什么，哪里敢起杀心。
`[ts:testimony_3:s3_5]` **阿贵** `[defensive]`: 十二年啊。端茶守夜，搬货跑腿，小的怎么会害老爷。
`[ts:shen_testimony_1:sf1_1]` **沈清月** `[cooperative]`: 周德茂欠我三十八两。前天我还堵着他要还期，他死了，这笔钱反而更难收。
`[ts:shen_testimony_1:sf1_2]` **沈清月** `[sharp]`: 我在渡口当众骂过他。真要害人，我会先把自己摆到众人眼前吗。
`[ts:shen_testimony_1:sf1_3]` **沈清月** `[sharp]`: 船上若真有五十两货银，那也是跟船一并没了。我亏的是两笔，不是一笔。
`[ts:shen_testimony_1:sf1_4]` **沈清月** `[sharp]`: 阿贵的话也能信？一个要给自己找活路的人，拖谁下水都不奇怪。
`[ts:shen_testimony_1:sf1_5]` **沈清月** `[cooperative]`: 我爹等钱买药。我巴不得周德茂活着还账，哪会盼他死。
`[ts:shen_testimony_2:sf2_1]` **沈清月** `[cooperative]`: 老范？码头船家罢了。认得脸不稀奇，难道认得脸就算一伙？
`[ts:shen_testimony_2:sf2_2]` **沈清月** `[sharp]`: 他欠赌坊四十二两，这事码头上都有人说。我听过一句，也算罪名？
`[ts:shen_testimony_2:sf2_3]` **沈清月** `[sharp]`: 阿贵？我只在码头见他跟着周德茂。船开后我便回客栈，哪来的工夫同他说话。
`[ts:shen_testimony_2:sf2_4]` **沈清月** `[sharp]`: 我亥时前就回客栈了。陆公子若疑我时辰，就拿能落到点上的东西来说。
`[ts:shen_testimony_2:sf2_5]` **沈清月** `[cold_fury]`: 说我教他们怎么做？先拿出我跟他们开口的那一刻。没有那一刻，就只是他们两张嘴。
`[ts:shen_testimony_3:sf3_1]` **沈清月** `[sharp]`: 我在码头多站一会儿又怎样。讨债的人盯着欠债人上船，很怪吗。
`[ts:shen_testimony_3:sf3_2]` **沈清月** `[sharp]`: 你拿几个人的话来凑我。一个赌鬼，一个仆从，一个老渔翁，这就要定我？
`[ts:shen_testimony_3:sf3_3]` **沈清月** `[cold_fury]`: 你说我在码头多站了一会儿，可以。可从码头走到船底那一步，你还没说清。
`[ts:shen_testimony_3:sf3_4]` **沈清月** `[cold_fury]`: 你找到了药囊壳。可它什么时候放上去，谁放上去，你还没抓住。码头能靠近船的人，不止我一个。
`[ts:shen_testimony_3:sf3_5]` **沈清月** `[cold_fury]`: 堂上看的是能不能写。最后那笔没落下，别急着让我点头。
`[ts:shen_testimony_4:sf4_1]` **沈清月** `[cold_fury]`: 周德茂落水前是不是先失了力，没人亲眼看见。冬水冷得狠，抽筋闭气都能让人沉。
`[ts:shen_testimony_4:sf4_2]` **沈清月** `[cold_fury]`: 糯米胶封鱼篓，补伞骨，糊船缝都用得着。码头上谁手里没有一点。
`[ts:shen_testimony_4:sf4_3]` **沈清月** `[cold_fury]`: 此草遇淡水几刻就散。验到最后，剩下的也只是草屑，撑不起毒杀二字。
`[ts:shen_testimony_4:sf4_4]` **沈清月** `[cold_fury]`: 油痕更说不准。鱼虾有油，船漆有油，饭菜也有油。你总不能见了油就往我身上按。
`[ts:shen_testimony_4:sf4_4b]` **沈清月** `[cold_fury]`: 除非你能说清，进水时那口水里混了药，油又正好把残味留住。说不清，它们就只是一堆湿东西。

## 证词流程台词

`[tl:testimony_wang_self:preamble:0]` **钱里正** `[stern]`: 王大爷，站近些。昨晚看见什么，再说一遍。
`[tl:testimony_wang_self:preamble:1]` **王大爷** `[evasive]`: ……好。我只说我瞧见的，不往里添话。
`[tl:testimony_wang_self:preamble:2]` **凌瑶** `[determined]`: 他一张嘴就说"不添话"。可我怎么听着，越说越像已经在添了……
`[tl:testimony_wang_self:readthrough_end_hint:0]` **凌瑶** `[determined]`: 我听得好累。他绕来绕去的，就是不往正路上走。陆昭，你呢？ *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_wang_self:readthrough_end_hint:1]` **陆昭** `[serious]`: 站了快一个时辰了。你腿还行？ *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_wang_self:transition_dialogue:0]` **王大爷** `[guilty]`: ……我认岔了。脸是真没看清。
`[tl:testimony_wang_self:transition_dialogue:1]` **周氏** `[grief]`: 那你刚才咬得那么死——！
`[tl:testimony_wang_self:transition_dialogue:2]` **沈清月** `[sharp]`: 夜里看不清，不等于一字都不能听。周娘子，让老人家把听见的也说完。
`[tl:testimony_wang_self:transition_dialogue:3]` **陆昭** `[determined]`: 行。眼睛先放一边。听听耳朵那段。
`[tl:testimony_wang_self:transition_dialogue:4]` **凌瑶** `[determined]`: 她好快。王大爷刚松口，她就替他开口了。
`[tl:testimony_wang_self:transition_dialogue:5]` **陆昭** `[serious]`: 你听得倒快。
`[tl:testimony_wang_self:transition_dialogue:6]` **凌瑶** `[determined]`: 真是的。话都让她一个人说了……
`[tl:testimony_wang_self:fail_dialogue:0]` **王大爷** `[evasive]`: 我没瞎编。你不信，也得说清我哪一句看错了。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_wang_self:fail_dialogue:1]` **凌瑶** `[worried]`: 没对……我手心又出汗了。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_wang_self_hearing:preamble:0]` **钱里正** `[stern]`: 王大爷，只说喊声。别把前头后头都揉进去。
`[tl:testimony_wang_self_hearing:preamble:1]` **王大爷** `[evasive]`: ……行。那就说喊声。
`[tl:testimony_wang_self_hearing:preamble:2]` **沈清月** `[sharp]`: 字句未必清楚，整段也未必作废。陆公子，别听见一处含糊，就把老人家后头的话全划掉。
`[tl:testimony_wang_self_hearing:preamble:3]` **凌瑶** `[determined]`: 她把话留得真滑。我一时还真不好接。
`[tl:testimony_wang_self_hearing:readthrough_end_hint:0]` **凌瑶** `[determined]`: 我听得都头晕了……这堂上好闷。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_wang_self_hearing:readthrough_end_hint:1]` **陆昭** `[serious]`: 等会儿出去透口气。快完了。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_wang_self_hearing:transition_dialogue:0]` **王大爷** `[guilty]`: ……是。我没听清那两个字，是自己往那个意思上记的。
`[tl:testimony_wang_self_hearing:transition_dialogue:1]` **钱里正** `[stern]`: 眼也花，耳也混……那你后头说陆公子很快上岸，总该有个准吧？
`[tl:testimony_wang_self_hearing:transition_dialogue:2]` **沈清月** `[sharp]`: 听错两个字，不等于看错一个活人上岸。里正大人，错的是哪句，就划哪句。
`[tl:testimony_wang_self_hearing:transition_dialogue:3]` **陆昭** `[determined]`: 正好。最后这句也说说。
`[tl:testimony_wang_self_hearing:transition_dialogue:4]` **凌瑶** `[worried]`: 陆昭，她盯上我了。你先别被我这边拉走。
`[tl:testimony_wang_self_hearing:fail_dialogue:0]` **王大爷** `[evasive]`: 我只是把听见的那个意思说出来。难不成听见人吵架也算错？ *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_wang_self_hearing:fail_dialogue:1]` **沈清月** `[sharp]`: 争执的大意还在。陆公子若只抓两个字，王大爷后头的话可还站着。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_wang_self_hearing:fail_dialogue:2]` **凌瑶** `[worried]`: 又说"大意"……她一直把门留着。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_wang_self_escape:preamble:0]` **钱里正** `[stern]`: 王大爷，最后一件。那个人上岸，到底是不是陆公子？你再说一遍。
`[tl:testimony_wang_self_escape:preamble:1]` **王大爷** `[evasive]`: ……我只记得，那人上岸很快。
`[tl:testimony_wang_self_escape:preamble:2]` **沈清月** `[cold_fury]`: 王大爷，想清楚再开口。老眼昏花是记错；收了钱又当堂改口，就不是糊涂两字能遮过去了。
`[tl:testimony_wang_self_escape:preamble:3]` **凌瑶** `[determined]`: 她吓王大爷，可她看的是你。陆昭。
`[tl:testimony_wang_self_escape:readthrough_end_hint:0]` **凌瑶** `[determined]`: 王大爷脸都白了。我看着他有点不忍心……可该问的还得问。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_wang_self_escape:readthrough_end_hint:1]` **陆昭** `[serious]`: 他这把年纪，站这么久也不容易。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_wang_self_escape:transition_dialogue:0]` **钱里正** `[stern]`: ……够了。王大爷这份指认，不能作准。
`[tl:testimony_wang_self_escape:transition_dialogue:1]` **陆昭** `[serious]`: 王大爷。你刚才说——"像是"。不是"就是"。你这一个像字，是要我命的。
`[tl:testimony_wang_self_escape:transition_dialogue:2]` **沈清月** `[cold_fury]`: 慢着。王大爷收钱，只能划掉他后头添的那几笔，划不掉陆公子自己的空白。
`[tl:testimony_wang_self_escape:transition_dialogue:3]` **沈清月** `[cold_fury]`: 你说自己上岸时快没气了。除了凌姑娘，谁替这笔救起时辰盖印？
`[tl:testimony_wang_self_escape:transition_dialogue:4]` **凌瑶** `[worried]`: 陆昭。我来。
`[tl:testimony_wang_self_escape:transition_dialogue:5]` **陆昭** `[serious]`: 行。要问就当堂问。我不躲。
`[tl:testimony_wang_self_escape:fail_dialogue:0]` **王大爷** `[evasive]`: 我记不清刻数……可那人上岸是真快。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_wang_self_escape:fail_dialogue:1]` **沈清月** `[sharp]`: 老人家已经把话让到这份上了。陆公子若还想说他作伪，就得拿出更硬的时辰。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_wang_self_escape:fail_dialogue:2]` **凌瑶** `[worried]`: 时辰……他就一个"快"字。我站得腿都酸了，他还在快…… *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_wang_shen_counter:preamble:0]` **沈清月** `[cold_fury]`: 里正大人，陆公子要验王大爷的眼睛，可以。可他自己的说法，也该当堂过一遍。
`[tl:testimony_wang_shen_counter:preamble:1]` **沈清月** `[cold_fury]`: 他说自己昏迷许久，全靠凌瑶撑着。一个昨夜才冒出来的姑娘，来路未验，凭什么比王大爷几十年的江上眼睛更压秤？
`[tl:testimony_wang_shen_counter:preamble:2]` **凌瑶** `[anxious]`: 好家伙……她把我也拎出来了。陆昭，别慌，镖局的牌子在这呢。
`[tl:testimony_wang_shen_counter:preamble:3]` **陆昭** `[serious]`: 别绕。你怀疑她什么，说。
`[tl:testimony_wang_shen_counter:readthrough_end_hint:0]` **凌瑶** `[determined]`: 呼……刚才那下我背上全是汗。幸好里正接得快。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_wang_shen_counter:readthrough_end_hint:1]` **陆昭** `[serious]`: 你刚才那下比我还快。镖局出来的就是不一样。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_wang_shen_counter:transition_dialogue:0]` **钱里正** `[stern]`: 金鳞镖局的铜牌在此，客栈掌柜也认得这位凌姑娘。她不是雨夜里凭空钻出来替谁圆话的。
`[tl:testimony_wang_shen_counter:transition_dialogue:1]` **沈清月** `[cracking]`: ……好。这一味验过了，我收回。
`[tl:testimony_wang_shen_counter:transition_dialogue:2]` **凌瑶** `[determined]`: 她居然不说了。（小声）我气都还没喘匀……
`[tl:testimony_wang_shen_counter:transition_dialogue:3]` **陆昭** `[serious]`: 她按不下去。你救我的事，不能被她一句话抹掉。
`[tl:testimony_wang_shen_counter:transition_dialogue:4]` **凌瑶** `[cheerful]`: 嗯。凳子还在。
`[tl:testimony_wang_shen_counter:fail_dialogue:0]` **沈清月** `[cold_fury]`: 陆公子，若连凌姑娘为什么可信都说不清，那王大爷这份证词顶多有瑕，不是整张作废。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_wang_shen_counter:fail_dialogue:1]` **凌瑶** `[worried]`: 她把我和王大爷搁一块了……我跟他又不一样。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_lao_fan_route:preamble:0]` **钱里正** `[nervous]`: 老范，别贴门边了。船是你的，你得说。
`[tl:testimony_lao_fan_route:preamble:1]` **老范** `[evasive]`: ……我说。陆公子问，我不躲。
`[tl:testimony_lao_fan_route:preamble:2]` **沈清月** `[cooperative]`: 江上风浪一句话就能变。陆公子若说不是风浪，先让船板替你开口。
`[tl:testimony_lao_fan_route:readthrough_end_hint:0]` **凌瑶** `[determined]`: 老范这个人，身上有股烟味，从堂下就闻到了。说暗礁的时候眼睛也不瞧人。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_lao_fan_route:readthrough_end_hint:1]` **凌瑶** `[determined]`: 陆昭，我师父教过我一个看人的法子。看跑船的，不看手，看鞋。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_lao_fan_route:readthrough_end_hint:2]` **陆昭** `[serious]`: 怎么说。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_lao_fan_route:readthrough_end_hint:3]` **凌瑶** `[determined]`: 水上站久了，鞋底磨的印子和岸上不一样。老范这双鞋，怕是岸上的时候比水上的多。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_lao_fan_route:transition_dialogue:0]` **陆昭** `[serious]`: 不是浪。船底被人动过。
`[tl:testimony_lao_fan_route:transition_dialogue:1]` **沈清月** `[sharp]`: 旧船补板不稀奇。陆公子，别见一个钉眼，就说它昨夜才咬过人。
`[tl:testimony_lao_fan_route:transition_dialogue:2]` **老范** `[shaken]`: 陆公子……船、船底那事，我真没……
`[tl:testimony_lao_fan_route:transition_dialogue:3]` **陆昭** `[serious]`: 知不知道，后头再说。先说你落水以后怎么上岸。
`[tl:testimony_lao_fan_route:transition_dialogue:4]` **凌瑶** `[determined]`: 她又来了……让老范自己说不行么。
`[tl:testimony_lao_fan_route:transition_dialogue:5]` **陆昭** `[serious]`: 你倒是不怕她把水都泼过来。
`[tl:testimony_lao_fan_route:transition_dialogue:6]` **凌瑶** `[cheerful]`: 怕啊。可看着她我更来气。老范自己都被她说蔫了。
`[tl:testimony_lao_fan_route:fail_dialogue:0]` **老范** `[evasive]`: 陆公子，江上翻船不稀奇。您这东西……压不到暗礁这句话上啊。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_lao_fan_route:fail_dialogue:1]` **沈清月** `[sharp]`: 证物要对准证词。拿错了，只会让老范这句话站得更稳。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_lao_fan_route:fail_dialogue:2]` **凌瑶** `[worried]`: 对不上……陆昭，你是不是拿错东西了？ *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_lao_fan_rescue:preamble:0]` **陆昭** `[serious]`: 继续。船翻之后，你怎么活下来的？
`[tl:testimony_lao_fan_rescue:preamble:1]` **沈清月** `[cooperative]`: 翻船落水，人在冷水里连呼吸都乱，时辰乱半刻不稀奇。陆公子，只拿这点问不实。
`[tl:testimony_lao_fan_rescue:preamble:2]` **老范** `[evasive]`: 我……命大。扒着块船板，漂了好久。
`[tl:testimony_lao_fan_rescue:readthrough_end_hint:0]` **凌瑶** `[determined]`: 老范一张嘴她就知道他要说什么似的……这俩人怎么像对过词。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_lao_fan_rescue:transition_dialogue:0]` **陆昭** `[serious]`: 半个时辰。太快了。你游的方向，是最近的浅滩。
`[tl:testimony_lao_fan_rescue:transition_dialogue:1]` **沈清月** `[sharp]`: 跑船二十年，水性好，上岸快，不奇怪。快不是罪，熟水路也不是罪。
`[tl:testimony_lao_fan_rescue:transition_dialogue:2]` **老范** `[shaken]`: 陆公子……我跑船的，水性好些，也不能说我杀人啊。
`[tl:testimony_lao_fan_rescue:transition_dialogue:3]` **陆昭** `[serious]`: 你说命大。船是你凿的。上岸的也是你。中间呢。
`[tl:testimony_lao_fan_rescue:transition_dialogue:4]` **陆昭** `[serious]`: 老范，先别坐。船底和上岸时辰都说不圆。还有一件，你的赌债怎么说？
`[tl:testimony_lao_fan_rescue:transition_dialogue:4a]` **凌瑶** `[determined]`: 他说得也太顺了……掉水里的人，不该记这么清楚。
`[tl:testimony_lao_fan_rescue:transition_dialogue:4b]` **陆昭** `[serious]`: 嗯。命大解释不了每一步都刚好。
`[tl:testimony_lao_fan_rescue:transition_dialogue:5]` **老范** `[panic]`: 我跟周老爷无冤无仇！就一趟船钱，陆公子别把人往死里推。
`[tl:testimony_lao_fan_rescue:fail_dialogue:0]` **老范** `[evasive]`: 陆公子，落水以后乱成一锅粥。您拿这个压我，我也只能这么说。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_lao_fan_rescue:fail_dialogue:1]` **沈清月** `[sharp]`: 冬江逃生，差一刻半刻不稀奇。要翻这句，时辰得咬得住，不能只咬住"快"字。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_lao_fan_rescue:fail_dialogue:2]` **凌瑶** `[worried]`: 快、快、快……他除了快还会说别的吗。船板的事就没人提。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_lao_fan_motive:preamble:0]` **陆昭** `[serious]`: 老范，你说无冤无仇。那四十二两赌债，是怎么压到你身上的？
`[tl:testimony_lao_fan_motive:preamble:1]` **沈清月** `[cooperative]`: 欠债不是杀人。码头上被银子逼得喘不过气的人多了，不能个个都往案子里按。
`[tl:testimony_lao_fan_motive:preamble:2]` **老范** `[evasive]`: 我一个跑船的，跟周老爷就一趟生意。哪来的仇？
`[tl:testimony_lao_fan_motive:readthrough_end_hint:0]` **凌瑶** `[determined]`: 四十二两断指……她说得轻飘飘的。我听着都替老范疼。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_lao_fan_motive:readthrough_end_hint:1]` **陆昭** `[serious]`: 你见过断指的人吗。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:testimony_lao_fan_motive:transition_dialogue:0]` **老范** `[shaken]`: 我……我欠了赌债。可我没想杀人。
`[tl:testimony_lao_fan_motive:transition_dialogue:1]` **陆昭** `[determined]`: 你说没想杀人。可东汊是你选的，船底是你动的，上岸也比谁都快。哪一步是临时乱撞出来的？
`[tl:testimony_lao_fan_motive:transition_dialogue:2]` **老范** `[panic]`: 他们只说……船沉了，货银漂到下游，周老爷会被人救起来。我只要让船偏进东汊，事后分一笔银子还债。
`[tl:testimony_lao_fan_motive:transition_dialogue:3]` **陆昭** `[shocked]`: 他们？还有谁？
`[tl:testimony_lao_fan_motive:transition_dialogue:4]` **老范** `[panic]`: 阿贵来找过我。还有一个……药材行的姑娘。她知道我欠四十二两，知道腊月底要断指。她说"你只要照做，债就没了"。
`[tl:testimony_lao_fan_motive:transition_dialogue:5]` **沈清月** `[deflecting]`: 老范。赌债逼急了，别把谁都往水里拖。话出口前，先想想哪句能进案卷。
`[tl:testimony_lao_fan_motive:transition_dialogue:6]` **阿贵** `[angry]`: 你胡说！明明是你先收了她的钱，明明是你说东汊好下手！
`[tl:testimony_lao_fan_motive:transition_dialogue:7]` **叙述** `[narration]`: 堂上一阵骚动。老范和阿贵同时闭嘴。两个人的说法对不上，反而露出了第三个人。
`[tl:testimony_lao_fan_motive:transition_dialogue:8]` **陆昭** `[determined]`: 船不是意外。赌债也不是。阿贵，你和老范说的不一样。
`[tl:testimony_lao_fan_motive:transition_dialogue:9]` **凌瑶** `[determined]`: 药材行的姑娘……他刚要说名字，又咽回去了。
`[tl:testimony_lao_fan_motive:fail_dialogue:0]` **老范** `[evasive]`: 陆公子，我是穷，可穷不等于杀人。您总得说出我为什么非做不可。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_lao_fan_motive:fail_dialogue:1]` **沈清月** `[sharp]`: 赌债也分新旧轻重。去年欠下的，和昨夜催到门口的，不是一回事。陆公子，先问清时候。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_lao_fan_motive:fail_dialogue:2]` **凌瑶** `[worried]`: 腊月底断指……陆昭，这事你那边有没有查过？ *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_0:preamble:0]` **陆昭** `[serious]`: 阿贵，先坐下。别急着喊。你说你看见了，那就一件一件说，我会听完。
`[tl:testimony_0:preamble:1]` **沈清月** `[cooperative]`: 阿贵是当夜在场的人，也是周家用了十二年的仆从。话真不真，得让他说完整。陆公子，急着打断，反倒难看。
`[tl:testimony_0:preamble:2]` **阿贵** `[angry]`: 我说！那晚三更刚过——
`[tl:testimony_0:preamble:3]` **凌瑶** `[determined]`: 他一喊，我耳朵都嗡了……
`[tl:testimony_0:transition_dialogue:0]` **叙述** `[narration]`: 阿贵咬着牙坐了回去。额头上的汗珠滚落。刚才那套指控，已经说不下去了。
`[tl:testimony_0:transition_dialogue:1]` **陆昭** `[serious]`: 你说他用铁器打的。他身上的伤呢。没有。
`[tl:testimony_0:transition_dialogue:2]` **沈清月** `[sharp]`: 没有钝器伤，顶多说明不是打死。陆公子，别顺手把阿贵整个人也抹掉。他仍是在场的人，仍有该听的部分。
`[tl:testimony_0:transition_dialogue:3]` **陆昭** `[serious]`: 不是打死。可也不是普通落水——凌瑶验过了，指甲有碎屑，脖子有压痕。
`[tl:testimony_0:transition_dialogue:4]` **凌瑶** `[determined]`: 对。我验尸时就觉得不对。指甲缝有蓝色碎屑，脖子边有压痕。单纯落水，不该这样。
`[tl:testimony_0:transition_dialogue:5]` **沈清月** `[deflecting]`: ……碎屑可能是死者自己碰过什么草药。压痕也可能是呛水挣扎时磕碰舱壁。两处痕迹，都还没到下毒那一步。
`[tl:testimony_0:transition_dialogue:6]` **阿贵** `[shaken]`: ……
`[tl:testimony_0:transition_dialogue:7]` **叙述** `[inner_thought]`: （他不再喊了。刚才的气势已经没了。）
`[tl:testimony_0:transition_dialogue:8]` **叙述** `[inner_thought]`: （从'他杀了老爷'到'就算没打也是他害的'——他已经开始给自己找退路了。而蓝色碎屑和脖颈压痕……这条线另有出处。）
`[tl:testimony_0:transition_dialogue:9]` **凌瑶** `[determined]`: 草药……她接得好顺。我还没反应过来。
`[tl:testimony_0:transition_dialogue:10]` **凌瑶** `[determined]`: 陆昭，你发现没？她每次都能帮人找到理由。可这理由……不对味。
`[tl:testimony_0:transition_dialogue:11]` **陆昭** `[serious]`: 这你都听出来了？
`[tl:testimony_0:transition_dialogue:12]` **凌瑶** `[determined]`: 听得出来。死人开不了口，我就替他多听一耳朵。
`[tl:testimony_0:fail_dialogue:0]` **阿贵** `[angry]`: 陆公子——他就是凶手！铁器打人、天窗逃跑——都是他干的！ *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_0:fail_dialogue:1]` **沈清月** `[sharp]`: 陆公子，要驳阿贵，就对准他说的那一句。拿错东西，只会让他咬得更死。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_0:fail_dialogue:2]` **叙述** `[inner_thought]`: （他喊得很大声，但手指在发抖。他把这套说法当成最后的遮挡。） *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_0:fail_dialogue:3]` **凌瑶** `[worried]`: 他手在抖，陆昭。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_0:fail_dialogue:4]` **凌瑶** `[worried]`: 你一问别的他就不怕了。刚才那下，他怕的是你手上那件东西。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_1:preamble:0]` **陆昭** `[serious]`: 阿贵，从上船开始。慢点说，别漏。
`[tl:testimony_1:preamble:1]` **沈清月** `[cooperative]`: 怕水的人带浮囊，不犯法。下人命贱，怕死更寻常。陆公子，别把"怕死"两个字硬拧成"预谋"。
`[tl:testimony_1:preamble:2]` **阿贵** `[nervous]`: 是……是，陆公子。
`[tl:testimony_1:transition_dialogue:0]` **叙述** `[narration]`: 阿贵瘫坐在地上，大口喘着气。额头上的汗比刚才更密了。
`[tl:testimony_1:transition_dialogue:1]` **凌瑶** `[determined]`: 刚才还嚷……这会儿塌成这样。看着都有点替他不好意思。
`[tl:testimony_1:transition_dialogue:2]` **叙述** `[inner_thought]`: （第一道防线破了。他知道我不是来走过场的。接下来他会更用力地编，也会更容易喘不上气。）
`[tl:testimony_1:transition_dialogue:3]` **陆昭** `[serious]`: 我没问你是不是怕水。这只浮囊——上船前就充好了。
`[tl:testimony_1:transition_dialogue:4]` **阿贵** `[panic]`: 陆公子……陆公子，您听我说……
`[tl:testimony_1:transition_dialogue:5]` **阿贵** `[defensive]`: 那个浮囊……小的确实是提前准备的。但不是为了害人——是为了保命啊！
`[tl:testimony_1:transition_dialogue:6]` **陆昭** `[serious]`: 保命——这两个字我听见了。可你得把它说圆。
`[tl:testimony_1:transition_dialogue:7]` **阿贵** `[nervous]`: 老范跟小的说过，这段水路有暗礁，夜里走尤其凶险。小的不会水，怕出事……所以才藏了个浮囊。
`[tl:testimony_1:transition_dialogue:8]` **阿贵** `[defensive]`: 小的怕死！就这么简单！这又不犯法！……不犯法的……
`[tl:testimony_1:transition_dialogue:9]` **叙述** `[inner_thought]`: （他反复说"不犯法"。这不是解释，是早就准备好的挡法。）
`[tl:testimony_1:transition_dialogue:10]` **凌瑶** `[worried]`: 我怕死……他念了好几遍了。真的怕的人，不是这个声。
`[tl:testimony_1:transition_dialogue:11]` **凌瑶** `[determined]`: 我不信。真怕成那样，不会说得这么齐整。
`[tl:testimony_1:transition_dialogue:11a]` **陆昭** `[serious]`: 连这个你都听得出来？
`[tl:testimony_1:transition_dialogue:11b]` **凌瑶** `[cheerful]`: 听得出来。人怕的时候，喘气和背词不是一个声。
`[tl:testimony_1:transition_dialogue:12]` **叙述** `[inner_thought]`: （浮囊不是推理。它就摆在堂上：充好气，泡过江水，绳结上还挂着河草。阿贵必须解释这个东西为什么会在那里。）
`[tl:testimony_1:transition_dialogue:13]` **钱里正** `[nervous]`: 等等——陆公子，有件事我一直没提。
`[tl:testimony_1:transition_dialogue:14]` **钱里正** `[shocked]`: 案发后第二天，阿贵在客栈买了一壶好酒、打了半斤卤肉。一个被遣散的仆从——哪来这么多闲钱？
`[tl:testimony_1:transition_dialogue:15]` **阿贵** `[panic]`: 那、那是……小的之前攒的……
`[tl:testimony_1:transition_dialogue:16]` **凌瑶** `[determined]`: 攒的？十二年工钱都被扣成那样，他哪来的闲钱买酒买肉？
`[tl:testimony_1:transition_dialogue:17]` **陆昭** `[serious]`: 暗礁？那个洞不是外面撞的。是从里面开的。
`[tl:testimony_1:fail_dialogue:0]` **阿贵** `[defensive]`: 陆公子……这、这跟那晚有什么关系？您别冤枉好人啊…… *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_1:fail_dialogue:1]` **沈清月** `[sharp]`: 陆公子，这东西搭不到"提前准备"上。药引搭错方，越问越偏。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_1:fail_dialogue:2]` **叙述** `[inner_thought]`: （那一闪而过的眼神，不像无辜者的委屈，倒像是庆幸你问偏了。） *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_1:fail_dialogue:3]` **凌瑶** `[worried]`: 他刚才那个眼神……不是委屈。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_1:fail_dialogue:4]` **凌瑶** `[determined]`: 不是这个。陆昭，你手上还有别的吗？ *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_2:transition_dialogue:0]` **阿贵** `[shaken]`: （双手抱头，蹲在地上发抖）
`[tl:testimony_2:transition_dialogue:1]` **沈清月** `[sharp]`: 陆公子，凿痕只能说船被人动过。谁动、谁教、谁得利，还没落到阿贵一个人头上。船舱里可不止他一个活人。
`[tl:testimony_2:transition_dialogue:2]` **凌瑶** `[determined]`: 被逼的……他刚才差一点就说名字了。那个逼他的人。
`[tl:testimony_2:transition_dialogue:3]` **陆昭** `[serious]`: 凿痕在内侧，那晚你就在舱里。先别推，说你自己的。
`[tl:testimony_2:transition_dialogue:4]` **阿贵** `[shaken]`: ……
`[tl:testimony_2:transition_dialogue:5]` **阿贵** `[panic]`: 就算……就算小的动了手脚——那也是被逼的！
`[tl:testimony_2:transition_dialogue:6]` **阿贵** `[defensive]`: 是老范！是他先说东汊好下手，小的只是照他说的做！小的只是……只是没拒绝！
`[tl:testimony_2:transition_dialogue:7]` **陆昭** `[serious]`: 被逼的？浮囊是你自己备的。船板是你自己动的。周德茂最信的人是你。
`[tl:testimony_2:transition_dialogue:8]` **阿贵** `[nervous]`: 小的跟老爷十二年，吃穿不愁——小的为什么要主动害老爷？小的没有理由！
`[tl:testimony_2:transition_dialogue:9]` **沈清月** `[cooperative]`: 他说被逼，也未必全假。下人犯了事，总会先找一个更有力气的人压在前头，为的是自己少担一点。
`[tl:testimony_2:transition_dialogue:10]` **凌瑶** `[worried]`: 她张嘴了……这下阿贵又不用说了。
`[tl:testimony_2:transition_dialogue:11]` **陆昭** `[serious]`: 没有理由？十二年工钱被扣光。遣散字据在你身上。
`[tl:testimony_2:fail_dialogue:0]` **阿贵** `[defensive]`: 暗礁撞的！石头不长眼！陆公子，您讲道理啊！ *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_2:fail_dialogue:1]` **沈清月** `[sharp]`: 江底暗礁尖，里正大人也知道。陆公子，天灾这味还没排掉，就别急着下"人祸"的药名。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_2:fail_dialogue:2]` **凌瑶** `[worried]`: 他接得也太快了……这句像练过。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_3:fail_dialogue:0]` **阿贵** `[defensive]`: 陆公子……小的只是个下人，哪有本事害人性命……您搞错了！ *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_3:fail_dialogue:1]` **沈清月** `[sharp]`: 十二年主仆，饭碗和命都系在周家门槛上。陆公子若拿不出他翻脸的那一下，谁信他会杀主人？ *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_3:fail_dialogue:2]` **凌瑶** `[worried]`: 十二年……我听着心里堵。可难受归难受，不对就是不对。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:testimony_3:transition_dialogue:0]` **阿贵** `[shaken]`: 小的……小的只是个下人……
`[tl:testimony_3:transition_dialogue:1]` **凌瑶** `[determined]`: 他又缩回去了……"只是下人"，这是他最后的壳。
`[tl:testimony_3:transition_dialogue:2]` **钱里正** `[stern]`: 这……遣散字据……阿贵，你之前可没提过这个。
`[tl:testimony_3:transition_dialogue:3]` **周氏** `[grief]`: 阿贵。老爷遣散你——是为什么？
`[tl:testimony_3:transition_dialogue:4]` **阿贵** `[shaken]`: 夫、夫人……
`[tl:testimony_3:transition_dialogue:5]` **凌瑶** `[determined]`: 周氏一开口，阿贵整个人就矮了半截。
`[tl:testimony_3:transition_dialogue:6]` **周氏** `[shocked]`: 等等……老爷的字我认得。遣散字据是老爷写的——但旁边那张纸条不是。
`[tl:testimony_3:transition_dialogue:7]` **周氏** `[grief]`: 那张纸条的字……工工整整的，像读过书的人写的。老爷写字歪歪扭扭——那不是他的。
`[tl:testimony_3:transition_dialogue:8]` **凌瑶** `[shocked]`: 等等……纸条上还有别人的字！
`[tl:testimony_3:transition_dialogue:9]` **陆昭** `[serious]`: ……把那张纸条拿来。
`[tl:testimony_3:transition_dialogue:9a]` **凌瑶** `[determined]`: 这下总算有东西落到地上了。
`[tl:testimony_3:transition_dialogue:9b]` **陆昭** `[serious]`: 半口就够。后面还有人等着他说出来。
`[tl:testimony_3:transition_dialogue:10]` **沈清月** `[deflecting]`: ……纸条而已。字这种东西，谁都能写。堂上认笔迹，也得先认人。
`[tl:testimony_3:transition_dialogue:11]` **凌瑶** `[determined]`: 她不说话了……那张纸管用。
`[tl:shen_testimony_1:preamble:0]` **凌瑶** `[determined]`: 我后槽牙发酸。她把账算得太好看了……
`[tl:shen_testimony_1:preamble:0a]` **陆昭** `[serious]`: 牙疼也先站稳。
`[tl:shen_testimony_1:preamble:0b]` **凌瑶** `[cheerful]`: 太好了，好得我胃不舒服……
`[tl:shen_testimony_1:preamble:1]` **沈清月** `[bold]`: 问吧。不过先把账算清：周德茂欠我钱。债主杀债人，亏的是我。
`[tl:shen_testimony_1:readthrough_end_hint:0]` **凌瑶** `[determined]`: 我有点怕她，陆昭。每句话都太好听了…… *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:shen_testimony_1:readthrough_end_hint:1]` **陆昭** `[serious]`: 怕就站我后面。她再厉害也是一个人。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:shen_testimony_1:transition_dialogue:0]` **叙述** `[narration]`: 沈清月的表情变了——只有一瞬间。嘴角的弧度消失了。她重新抱起双臂，但这次——手指攥得更紧了。
`[tl:shen_testimony_1:transition_dialogue:1]` **凌瑶** `[determined]`: 她手指攥紧了。别看她脸没变，手不会骗人。
`[tl:shen_testimony_1:transition_dialogue:2]` **凌瑶** `[anxious]`: 我手心出汗了……她比阿贵难对付多了。
`[tl:shen_testimony_1:transition_dialogue:3]` **陆昭** `[serious]`: 还撑得住吗？
`[tl:shen_testimony_1:transition_dialogue:4]` **凌瑶** `[determined]`: 站得住。
`[tl:shen_testimony_1:transition_dialogue:5]` **陆昭** `[serious]`: ……刚才那一下，问得好。
`[tl:shen_testimony_1:transition_dialogue:6]` **凌瑶** `[cheerful]`: 哎。好。继续。
`[tl:shen_testimony_1:transition_dialogue:7]` **沈清月** `[cold_fury]`: ……好。就算那笔银子没沉。你凭什么说是我捞的？
`[tl:shen_testimony_1:transition_dialogue:8]` **陆昭** `[determined]`: 亥时就回客栈了？船走的时候你还在码头。凌瑶看见了。
`[tl:shen_testimony_1:transition_dialogue:9]` **沈清月** `[cracking]`: 那是——……别人留下的。不是我。
`[tl:shen_testimony_1:transition_dialogue:10]` **陆昭** `[determined]`: 看他上船就走了——后来又说"多站了一会儿"。现在连浅滩的痕迹也不认。沈清月，那晚你到底在哪儿？
`[tl:shen_testimony_1:transition_dialogue:11]` **沈清月** `[cracking]`: ……
`[tl:shen_testimony_1:transition_dialogue:12]` **沈清月** `[cold_fury]`: 好。换个说法。就算那晚我在码头多站了一会儿，盯着欠债人上船，有什么问题？不犯法。
`[tl:shen_testimony_1:transition_dialogue:13]` **凌瑶** `[anxious]`: 不犯法……她把这三个字说得跟吃饭似的。
`[tl:shen_testimony_1:transition_dialogue:14]` **陆昭** `[determined]`: 你说不认识。老范说你找过他。阿贵说是你教的。
`[tl:shen_testimony_1:fail_dialogue:0]` **沈清月** `[sharp]`: 陆公子，我说过，杀他对我只坏不好。你要翻这账，先把银子翻出来。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:shen_testimony_1:fail_dialogue:1]` **凌瑶** `[worried]`: 她死咬着银子不放。陆昭，别跟她在这耗。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:shen_testimony_2:preamble:0]` **凌瑶** `[determined]`: 她更轻了……可越轻我越怕。陆昭你紧张不？
`[tl:shen_testimony_2:preamble:0a]` **凌瑶** `[determined]`: 我想起一件事。去年押过一个药材商的镖，账本也是这么漂亮。
`[tl:shen_testimony_2:preamble:0b]` **陆昭** `[serious]`: 后来呢。
`[tl:shen_testimony_2:preamble:0c]` **凌瑶** `[determined]`: 全是假的。越好看的账本越不能信。他封箱用的胶，泡了水才看得出来底下有缝。
`[tl:shen_testimony_2:preamble:1]` **沈清月** `[cold_fury]`: 陆公子，你想把我和那两个男人绑在一处？可以。可碰过面，离合谋杀人还差一条江。
`[tl:shen_testimony_2:readthrough_end_hint:0]` **凌瑶** `[determined]`: 她穿得也太素净了。不像做药材生意的…… *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:shen_testimony_2:readthrough_end_hint:1]` **陆昭** `[serious]`: 嗯。她从上到下都不像。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:shen_testimony_2:transition_dialogue:0]` **叙述** `[narration]`: 沈清月的呼吸节奏变了。不再是之前均匀的、控制着的呼吸。胸口有了微微的起伏。
`[tl:shen_testimony_2:transition_dialogue:1]` **钱里正** `[stern]`: 陆公子——阿贵的供词。他画了押的。
`[tl:shen_testimony_2:transition_dialogue:2]` **钱里正** `[stern]`: 上面写着：'船底是小的凿的。浮囊是小的带的。凿船的位置、浮囊的来历——全是沈姑娘教的。'
`[tl:shen_testimony_2:transition_dialogue:2a]` **钱里正** `[stern]`: 不过丑话说在前头。口供能开线索，不能单独押人。若没有旁的东西相印，县衙不会只凭阿贵一张嘴拿人。
`[tl:shen_testimony_2:transition_dialogue:3]` **沈清月** `[cold_fury]`: ……一个杀人犯为了减罪攀咬别人。这种口供——陆公子不会当真吧？
`[tl:shen_testimony_2:transition_dialogue:4]` **陆昭** `[serious]`: 我倒想一句口供就够用。可惜不够。所以我没单拿它。
`[tl:shen_testimony_2:transition_dialogue:5]` **陆昭** `[determined]`: 老范说你找过他。阿贵说是你教的。够不够。
`[tl:shen_testimony_2:transition_dialogue:6]` **沈清月** `[cold_fury]`: ……说下去。
`[tl:shen_testimony_2:transition_dialogue:7]` **沈清月** `[cold_fury]`: 就算我认识老范。就算那天夜里我没有立刻回客栈。那也只是我在场，我认识人。
`[tl:shen_testimony_2:transition_dialogue:8]` **沈清月** `[cold_fury]`: 策划？教阿贵凿船？陆公子，别让两个字替你跑完这一段路。
`[tl:shen_testimony_2:transition_dialogue:9]` **凌瑶** `[anxious]`: 她好冷……
`[tl:shen_testimony_2:transition_dialogue:9a]` **陆昭** `[serious]`: 她退得太熟了，像早就练过。
`[tl:shen_testimony_2:transition_dialogue:9b]` **凌瑶** `[determined]`: 她越不急我越急。陆昭你手上还有东西吗？
`[tl:shen_testimony_2:transition_dialogue:10]` **陆昭** `[determined]`: 那我问得更窄一点。凿船位置如果不是阿贵自己定的，谁能提前把毒囊放到同一个点？
`[tl:shen_testimony_2:transition_dialogue:11]` **沈清月** `[cracking]`: ……
`[tl:shen_testimony_2:transition_dialogue:12]` **陆昭** `[determined]`: 下一轮，看船上留下的东西。她要东西，我们就给她东西。
`[tl:shen_testimony_2:fail_dialogue:0]` **沈清月** `[cold_fury]`: 一个赌鬼，一个杀人犯，就把陆公子哄成这样？传出去，不怕人笑话吗？ *(fail_dialogue)* *(fail_dialogue)*
`[tl:shen_testimony_2:fail_dialogue:1]` **凌瑶** `[worried]`: 她不疼……换一句吧陆昭。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:shen_testimony_3:preamble:0]` **凌瑶** `[determined]`: 她开始凶了。凶的时候比冷静的时候好对付。
`[tl:shen_testimony_3:preamble:1]` **沈清月** `[cold_fury]`: 你说我在场，认识人，也有钱可图。可这些到了堂上，只叫嫌疑。陆公子，嫌疑押不住人。
`[tl:shen_testimony_3:readthrough_end_hint:0]` **凌瑶** `[determined]`: 她不躲了……我反而更紧张。陆昭你手上还有什么？ *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:shen_testimony_3:fail_dialogue:0]` **沈清月** `[cold_fury]`: 陆公子，你把每个巧合都往我身上拧，是怕案子空着，还是怕自己先前看错了人？这样的案卷，县衙不会落印。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:shen_testimony_3:fail_dialogue:1]` **凌瑶** `[worried]`: 她说"巧合"的时候断了一下。她自己也不信。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:shen_testimony_3:transition_dialogue:0]` **沈清月** `[cold_fury]`: 陆公子，您这些证据，绕得太远。
`[tl:shen_testimony_3:transition_dialogue:1]` **凌瑶** `[determined]`: 太远了……她说这三个字的时候慢了。她也不像嘴上那么稳。
`[tl:shen_testimony_3:transition_dialogue:1a]` **陆昭** `[serious]`: ……等等。
`[tl:shen_testimony_3:transition_dialogue:1b]` **叙述** `[inner_thought]`: 毒囊残壳的固定位置。船底破洞的位置。两个点——完全重合。
`[tl:shen_testimony_3:transition_dialogue:1b2]` **叙述** `[inner_thought]`: （想起老师一句话。证据不是单件用的，是连起来用的。这两个点——毒囊和破洞——放在一起，才是一件事。）
`[tl:shen_testimony_3:transition_dialogue:1c]` **陆昭** `[shocked]`: ……等等。我好像漏看了一点。
`[tl:shen_testimony_3:transition_dialogue:1d]` **凌瑶** `[anxious]`: 怎么了？
`[tl:shen_testimony_3:transition_dialogue:1e]` **陆昭** `[determined]`: 这片胶卡在进水口破洞边上。附着痕在内侧，像是船板还没破时就贴好了。
`[tl:shen_testimony_3:transition_dialogue:1f]` **陆昭** `[determined]`: 放毒囊的人，早知道阿贵会凿哪一块板。而阿贵画押说，那个位置是沈清月指定的。
`[tl:shen_testimony_3:transition_dialogue:1g]` **沈清月** `[cracking]`: ……巧合。船底那么大，卡在那儿，不等于我放在那儿。
`[tl:shen_testimony_3:transition_dialogue:1h]` **凌瑶** `[determined]`: 她说"巧合"时停了一下……
`[tl:shen_testimony_3:transition_dialogue:1i]` **陆昭** `[serious]`: 刚才那一下，总算逼出她一丝慌了。
`[tl:shen_testimony_3:transition_dialogue:1j]` **凌瑶** `[cheerful]`: 就说嘛，她也不是铁打的。
`[tl:shen_testimony_3:transition_dialogue:2]` **陆昭** `[serious]`: 单拎哪一条都还差点意思，可一并摆上来，就不是巧合了。
`[tl:shen_testimony_3:transition_dialogue:2a]` **钱里正** `[nervous]`: 陆公子，小人听得懂。可堂上要分清：能串出案情，不等于能押住一个会辩的人。
`[tl:shen_testimony_3:transition_dialogue:3]` **沈清月** `[cold_smile]`: 押我？陆公子，你手里这些，哪一样不是别人嘴里说出来的？
`[tl:shen_testimony_3:transition_dialogue:4]` **沈清月** `[cold_fury]`: 阿贵想减罪，老范想自保，王大爷夜里连人都看不清。
`[tl:shen_testimony_3:transition_dialogue:5]` **沈清月** `[sharp]`: 三张嘴互相推，推到我身上，就叫证据了？陆公子，你这是查案，还是替他们找个更体面的出口？
`[tl:shen_testimony_3:transition_dialogue:6]` **陆昭** `[determined]`: 你说证人的话不可靠。好。那不看人——看东西。看船上留下来的。
`[tl:shen_testimony_3:transition_dialogue:7]` **沈清月** `[deflecting]`: ……哪一件？
`[tl:shen_testimony_3:transition_dialogue:8]` **凌瑶** `[determined]`: 哪一件……她也不确定你手上有什么。
`[tl:shen_testimony_3:transition_dialogue:9]` **陆昭** `[determined]`: 要看实物是吧。来。看完这个再说。
`[tl:shen_testimony_3:transition_dialogue:10]` **沈清月** `[cold_smile]`: ……好啊。拿来。
`[tl:shen_testimony_4:preamble:0]` **凌瑶** `[determined]`: 最后一轮。她这会儿是真急了，只是还端着。
`[tl:shen_testimony_4:preamble:0a1]` **凌瑶** `[determined]`: 陆昭。胶。还记得我说的那个药材商吗。
`[tl:shen_testimony_4:preamble:0a2]` **陆昭** `[serious]`: 封条泡水才看得出来。
`[tl:shen_testimony_4:preamble:0a3]` **凌瑶** `[determined]`: 对。你手上那片胶，泡过江水了。现在看，正好。
`[tl:shen_testimony_4:preamble:0a]` **陆昭** `[serious]`: 胶、药、油，三样都摆在这儿。她想一件件拆开，我就一件件听她怎么拆。
`[tl:shen_testimony_4:preamble:0b]` **凌瑶** `[determined]`: 好。她把三样东西拆开……好像它们没关系似的。
`[tl:shen_testimony_4:preamble:1]` **沈清月** `[cold_fury]`: 糯米胶？码头上封鱼篓、补船缝都用。陆公子，你拿一片烂胶来吓我？
`[tl:shen_testimony_4:readthrough_end_hint:0]` **凌瑶** `[determined]`: 她一件件往外推的时候，我心里就在想：这三样东西怎么就不能是一件事呢。陆昭？ *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:shen_testimony_4:readthrough_end_hint:1]` **陆昭** `[serious]`: 你说得对。快完了。 *(readthrough_end_hint)* *(readthrough_end_hint)*
`[tl:shen_testimony_4:transition_dialogue:0]` **沈清月** `[cracking]`: ……油脂锁毒，毒囊定位。陆公子，你真把船底翻了个底朝天。
`[tl:shen_testimony_4:transition_dialogue:1]` **凌瑶** `[determined]`: 她不推了。可也没认。这个人……真的是。
`[tl:shen_testimony_4:transition_dialogue:1a]` **钱里正** `[stern]`: 这两件东西若能互相印上，至少能让人看清一点：这不是临时起意，也不是江底暗礁。有人预先知道破洞会开在哪里。
`[tl:shen_testimony_4:transition_dialogue:2]` **陆昭** `[determined]`: 能不能落到你身上，要看位置。毒囊贴着破洞，破洞又是阿贵照你给的地方凿的。沈清月，这不是路过就能撞上的巧。
`[tl:shen_testimony_4:transition_dialogue:2a]` **叙述** `[inner_thought]`: （老师。你教我的，"让证据自己说话"。胶在破洞边上。破洞是她指定的位置。毒囊贴着胶。三样东西，不在别处，在同一个地方。）
`[tl:shen_testimony_4:fail_dialogue:0]` **沈清月** `[sharp]`: 糯米胶随处有，草渣过了时效，油也不是人名。陆公子，别把三样说不清的东西硬拧成一桩案。 *(fail_dialogue)* *(fail_dialogue)*
`[tl:shen_testimony_4:fail_dialogue:1]` **凌瑶** `[worried]`: 她就是要把事情拆散……陆昭，别让她拆。 *(fail_dialogue)* *(fail_dialogue)*

# 第五幕 · 最终对峙

`[cl:confrontation_wang:intro_dialogue:0]` **钱里正** `[stern]`: 都缓缓。人命案不是谁嗓门大谁就赢。
`[cl:confrontation_wang:intro_dialogue:1]` **周氏** `[grief]`: 我只要知道我家老爷怎么死的。
`[cl:confrontation_wang:intro_dialogue:2]` **沈清月** `[cooperative]`: 那就请证人把看见的和后头想的分开说。
`[cl:confrontation_wang:intro_dialogue:3]` **钱里正** `[stern]`: 王大爷，依我看，你照实说就是。
`[cl:confrontation_wang:intro_dialogue:4]` **王大爷** `[evasive]`: 行。我照实说。
`[cl:confrontation_wang:intro_dialogue:5]` **陆昭** `[determined]`: 王大爷，我只求一句真话。哪句是你亲眼见的，哪句是后头想的，请分开。
`[cl:confrontation_wang:intro_dialogue:6]` **沈清月** `[sharp]`: 陆公子若真冤，也不怕一条条问清。
`[cl:confrontation_wang:intro_dialogue:7]` **凌瑶** `[determined]`: 问吧。我在旁边听着。
`[cl:confrontation_wang:intro_dialogue:8]` **陆昭** `[serious]`: 好。那就从第一句开始。
`[cl:confrontation_wang:defeat_dialogue:0]` **钱里正** `[stern]`: 依我看，这回还压不住王大爷这份话。
`[cl:confrontation_wang:defeat_dialogue:1]` **沈清月** `[sharp]`: 陆公子，若要洗清自己，下回带点能落地的东西来。
`[cl:confrontation_wang:defeat_dialogue:2]` **凌瑶** `[determined]`: 别灰心。他话里有空处，只是刚才还没掏净。
`[cl:confrontation_wang:defeat_dialogue:3]` **陆昭** `[serious]`: 好。我再来。
`[cl:confrontation:intro_dialogue:0]` **叙述** `[narration]`: 客栈大堂里人都到了。
`[cl:confrontation:intro_dialogue:1]` **钱里正** `[stern]`: 依我看，今日就把那条船怎么翻的，说个明白。
`[cl:confrontation:intro_dialogue:2]` **阿贵** `[angry]`: 里正大人，就是他害了老爷。
`[cl:confrontation:intro_dialogue:3]` **陆昭** `[serious]`: 你指我可以，但一句一句都得经得起问。
`[cl:confrontation:intro_dialogue:4]` **沈清月** `[cooperative]`: 我也在这儿听着。谁把话说满，就得拿木板和尸身对得上。
`[cl:confrontation:intro_dialogue:5]` **陆昭** `[serious]`: 老范，先从你开船说起。
`[cl:confrontation:intro_dialogue:6]` **凌瑶** `[determined]`: 别急，一句句问。我看着。
`[cl:confrontation:intro_dialogue:7]` **钱里正** `[stern]`: 好。都慢些说。
`[cl:confrontation:victory_dialogue:0]` **阿贵** `[nervous]`: 那晚三更过了些时候，小的听见舱外有水声……可小的不会水，没敢出去看。
`[cl:confrontation:victory_dialogue:1]` **阿贵** `[nervous]`: 后来船就翻了。小的只记得死死抱着块船板，江水灌进嘴里……旁的什么都记不得了。
`[cl:confrontation:victory_dialogue:2]` **阿贵** `[nervous]`: 老爷怎么死的，小的真不知道。小的自己也是捡了一条命。
`[cl:confrontation:victory_dialogue:3]` **阿贵** `[grief]`: （低着头，声音平得像背过无数遍）小的只是个下人……命贱，老天没收罢了。
`[cl:confrontation:victory_dialogue:4]` **凌瑶** `[worried]`: 他说得太整齐了。一个差点淹死的人，话不该这么齐整。
`[cl:confrontation:victory_dialogue:5]` **陆昭** `[serious]`: 阿贵，你说你不会水——那这个呢？（将浮囊放在桌上）
`[cl:confrontation:victory_dialogue:6]` **阿贵** `[panic]`: （吞了口口水）那、那不是小的的……小的没见过这东西。
`[cl:confrontation:victory_dialogue:7]` **凌瑶** `[determined]`: 没见过？粗布包袱和你客栈里用的是同一种。绳结上还挂着河草——江水泡过的。
`[cl:confrontation:victory_dialogue:8]` **阿贵** `[panic]`: 那是……那是别人放在小的包袱里的！小的不知道是谁！
`[cl:confrontation:victory_dialogue:9]` **阿贵** `[defensive]`: （声音发颤）小的说了——那不是小的买的！兴许是老范……对，老范放的！他跑船的，这种东西他多的是！
`[cl:confrontation:victory_dialogue:10]` **陆昭** `[serious]`: 码头的杂货铺有记录。腊月十八，有人买了两只牛皮浮囊。掌柜记了名字——阿贵。
`[cl:confrontation:victory_dialogue:11]` **阿贵** `[nervous]`: （手指开始抠袖口，眼睛盯着地面）……记、记错了。码头那么多人，掌柜哪能个个都记清……
`[cl:confrontation:victory_dialogue:12]` **陆昭** `[serious]`: 掌柜记得很清楚。因为你说你不会水，还特意问了怎么绑在身上才不掉。
`[cl:confrontation:victory_dialogue:13]` **阿贵** `[shaken]`: （突然抬起头，眼泪涌出来）小的……小的……那是……（语无伦次地）是有人教小的买的！她说带着浮囊就不会死，她说只是让船进水——不会出人命的！
`[cl:confrontation:victory_dialogue:14]` **凌瑶** `[determined]`: 她说？谁说的？
`[cl:confrontation:victory_dialogue:15]` **阿贵** `[broken]`: （双手捂住脸，声音闷在掌心里）小的不想杀老爷的……小的真没想杀他……
`[cl:confrontation:victory_dialogue:16]` **阿贵** `[broken]`: （手慢慢滑下来，声音反而平了）我跟了他十二年。十二年。吃的是剩饭，睡的是柴房。骂是轻的，打也打过……
`[cl:confrontation:victory_dialogue:17]` **阿贵** `[broken]`: 最后他给我二两银子。二两。说各不相欠。我算过——我至少该有三十两。可他只给我二两。
`[cl:confrontation:victory_dialogue:18]` **阿贵** `[broken]`: 我不是要杀他。我只是想让他也尝尝……什么叫被人踩到底。什么叫没处说。（眼泪无声地淌下来）……可我没想让他死。
`[cl:confrontation:victory_dialogue:19]` **周氏** `[shocked]`: （浑身发抖）阿贵……年节你还帮我贴过对联。你、你怎么下得去手……
`[cl:confrontation:victory_dialogue:20]` **钱里正** `[stern]`: （神色沉了下去）十二年主仆……依我看，这不是临时起的意。背后有人推。
`[cl:confrontation:victory_dialogue:21]` **凌瑶** `[determined]`: （沉默了片刻）……我懂你的委屈。可委屈不是杀人的理由。你说有人教你——那个人，必须说出来。
`[cl:confrontation:victory_dialogue:22]` **阿贵** `[broken]`: 我认……船底是我凿的。浮囊也是我带的。
`[cl:confrontation:victory_dialogue:23]` **凌瑶** `[determined]`: 这才像句真话。
`[cl:confrontation:victory_dialogue:24]` **陆昭** `[serious]`: 这些不是你自己想出来的。是谁教你的？
`[cl:confrontation:victory_dialogue:25]` **阿贵** `[broken]`: 不是我自己想的。有人来找过我。她知道我被赶走，也知道我恨老爷。
`[cl:confrontation:victory_dialogue:26]` **凌瑶** `[shocked]`: 她？
`[cl:confrontation:victory_dialogue:27]` **陆昭** `[serious]`: 是谁？说清楚。
`[cl:confrontation:victory_dialogue:28]` **阿贵** `[broken]`: 是……沈姑娘。
`[cl:confrontation:victory_dialogue:29]` **钱里正** `[shocked]`: 沈姑娘？
`[cl:confrontation:victory_dialogue:30]` **陆昭** `[serious]`: 她还做了什么？
`[cl:confrontation:victory_dialogue:31]` **阿贵** `[broken]`: 她找过老范，也替我备了浮囊。凿哪块板，什么时候动手，都是她说的。
`[cl:confrontation:victory_dialogue:32]` **凌瑶** `[determined]`: 她知道你恨，也知道老范欠债。她挑的都是你们最疼的地方。
`[cl:confrontation:victory_dialogue:33]` **陆昭** `[serious]`: 这句话还按不住她。
`[cl:confrontation:victory_dialogue:34]` **凌瑶** `[determined]`: 我知道。还得往下查。
`[cl:confrontation:victory_dialogue:35]` **钱里正** `[stern]`: 依我看，阿贵先看住。陆公子若还要查，我叫人带路。
`[cl:confrontation:victory_dialogue:36]` **陆昭** `[determined]`: 还没完。周德茂为何那么快没力气，还没说透。
`[cl:confrontation:victory_dialogue:37]` **凌瑶** `[determined]`: 那就去查船底和下游。
`[cl:confrontation:victory_dialogue:38]` **陆昭** `[serious]`: 沈清月一定会说，你是为了活命胡乱攀咬。我得再找一样她驳不掉的。
`[cl:confrontation:defeat_dialogue:0]` **阿贵** `[defensive]`: 陆公子，您说来说明去，也只是猜。
`[cl:confrontation:defeat_dialogue:1]` **钱里正** `[nervous]`: 依我看，这回还差点实在东西。
`[cl:confrontation:defeat_dialogue:2]` **凌瑶** `[worried]`: 让他滑过去了。证物还差一口气。
`[cl:confrontation:defeat_dialogue:3]` **陆昭** `[serious]`: 好。我再找。
`[cl:confrontation_final:intro_dialogue:0]` **叙述** `[narration]`: 客栈大堂又清出一块地方。阿贵和老范被押在旁边。
`[cl:confrontation_final:intro_dialogue:1]` **钱里正** `[nervous]`: 沈姑娘。陆公子说这案子还没完。依我看，你也当面回几句。
`[cl:confrontation_final:intro_dialogue:2]` **沈清月** `[cooperative]`: 我没躲。要问就当众问。
`[cl:confrontation_final:intro_dialogue:3]` **陆昭** `[serious]`: 阿贵已经认了凿船。但我知道你会说口供不够，所以我还带了别的。
`[cl:confrontation_final:intro_dialogue:4]` **沈清月** `[sharp]`: 一个求活命的人，最会顺着审问人的眼神说话。阿贵的话，我只当线头，不当结论。
`[cl:confrontation_final:intro_dialogue:5]` **凌瑶** `[determined]`: 你只管问。我替你看着她。
`[cl:confrontation_final:intro_dialogue:6]` **钱里正** `[stern]`: 对。口供能听，物件也要看。
`[cl:confrontation_final:intro_dialogue:7]` **陆昭** `[determined]`: 那就从银子和船底开始。
`[cl:confrontation_final:victory_dialogue:0]` **陆昭** `[serious]`: 周德茂不是寻常落水。他舌根里有蓝草屑，落水前被人下过药。
`[cl:confrontation_final:victory_dialogue:1]` **沈清月** `[cold_fury]`: 蓝萍草入水就散。验尸时只剩一点屑，写不得毒杀。
`[cl:confrontation_final:victory_dialogue:2]` **钱里正** `[nervous]`: 这话……我听着有理。
`[cl:confrontation_final:victory_dialogue:3]` **陆昭** `[serious]`: 所以我不只看草屑。进水口破洞边，还卡着一片没化尽的糯米胶壳。
`[cl:confrontation_final:victory_dialogue:4]` **陆昭** `[determined]`: 船板没凿穿前，药囊就贴在那里。洞一开，第一口水先进舱。
`[cl:confrontation_final:victory_dialogue:5]` **沈清月** `[cold_fury]`: 码头上谁都能碰船。一片胶壳，还写不出人名。
`[cl:confrontation_final:victory_dialogue:6]` **钱里正** `[nervous]`: 这倒也……不能不问。
`[cl:confrontation_final:victory_dialogue:7]` **陆昭** `[determined]`: 还有油。周德茂上船前吃过重油酒菜，那点油把舌根的药残裹住了。
`[cl:confrontation_final:victory_dialogue:8]` **沈清月** `[cracking]`: ……原来你一直看的是这点。
`[cl:confrontation_final:victory_dialogue:9]` **沈清月** `[cold_fury]`: 可这也只能说明药进过水。胶壳是谁缝的，草是谁放的，你没有人证。大明律不会替你补这一笔。
`[cl:confrontation_final:victory_dialogue:10]` **凌瑶** `[determined]`: 她刚才看了一眼袖口。
`[cl:confrontation_final:victory_dialogue:11]` **陆昭** `[serious]`: 她没算到周德茂上船前那桌菜。
`[cl:confrontation_final:victory_dialogue:12]` **钱里正** `[stern]`: 依我看，案情我明白了。可眼下这些东西，还真未必能当堂把沈姑娘押住。
`[cl:confrontation_final:victory_dialogue:13]` **沈清月** `[cold_fury]`: 陆公子，你把事说圆了。可说圆，不等于能写我名字。
`[cl:confrontation_final:victory_dialogue:14]` **钱里正** `[stern]`: 阿贵，老范，先送县里。沈姑娘……先留在客栈，不可远走。
`[cl:confrontation_final:victory_dialogue:15]` **凌瑶** `[worried]`: 就这么让她从门口出去？
`[cl:confrontation_final:victory_dialogue:16]` **陆昭** `[determined]`: 不。她留下的东西还在。
`[cl:confrontation_final:defeat_dialogue:0]` **沈清月** `[cold_fury]`: 陆公子，你摆了一桌子东西，还是只够把阿贵和老范往前推。
`[cl:confrontation_final:defeat_dialogue:1]` **沈清月** `[sharp]`: 胶壳谁都能碰，草屑也可能是落水时呛的，油痕更写不出人名。三样东西，还写不出我。
`[cl:confrontation_final:defeat_dialogue:2]` **凌瑶** `[worried]`: 她这回站住了。我们还差能把她带到船边的那一下。
`[cl:confrontation_final:defeat_dialogue:3]` **陆昭** `[serious]`: 我知道。差的那一下，我会补回来。
`[cl:confrontation_final:defeat_dialogue:4]` **钱里正** `[nervous]`: 依我看，今儿先到这儿。

# 第六幕 · 尾声

`[ep:0]` **叙述**: 黑暗中，一个声音响起。
`[ep:1]` **钱里正**: ……第一步棋，落下了。
`[ep:2]` **叙述**: 不要急。让他先走完这段路。
`[ep:3]` **叙述**: 浔阳楼的事……很快就会发生。
`[ep:4]` **凌瑶**: 【第一案 · 浔阳楼】
`[ep:5]` **陆昭**: ……现在还不能说。
`[ep:6]` **陆昭**: 他将那片湿纸收进袖中。两人走出石矶渡时，雨彻底停了。江面上浮着一层薄雾，远处的渡船声听不真切。
`[ep:7]` **凌瑶**: （愣了一下，然后笑了）行吧。那你换不换？
`[ep:8]` **陆昭**: （嘴角微动）换。前面路还长。
`[ep:0]` **凌瑶**: 黑暗中，一个声音响起。
`[ep:1]` **陆昭**: ……第一步棋，落下了。
`[ep:2]` **叙述**: 不要急。让他先走完这段路。
`[ep:3]` **叙述**: 浔阳楼的事……很快就会发生。
`[ep:4]` **凌瑶**: 【第一案 · 浔阳楼】
`[ep:5]` **陆昭**: ……现在还不能说。
`[ep:6]` **叙述**: 他将那片湿纸收进袖中。两人走出石矶渡时，雨彻底停了。江面上浮着一层薄雾，远处的渡船声听不真切。
`[ep:0]` **叙述**: 黑暗中，一个声音响起。
`[ep:1]` **???**: ……第一步棋，落下了。
`[ep:2]` **???**: 不要急。让他先走完这段路。
`[ep:3]` **???**: 浔阳楼的事……很快就会发生。
`[ep:4]` **叙述**: 【第一案 · 浔阳楼】

# 附录 · 搭档互动


## 闲聊

`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "刚才站太久了，腿麻了。"}, {"speaker": "陆昭", "text": "坐一会儿。"}, {"speaker": "凌瑶", "text": "你那块饼还留着吗？"}, {"speaker": "陆昭", "text": "……给你。"}, {"speaker": "凌瑶", "text": "刚才那个阿贵。他答话我听着不太对。不是假，是太顺了，像背过的。"}, {"speaker": "陆昭", "text": "问他落水时辰的时候停了半拍。"}, {"speaker": "凌瑶", "text": "饼有点干。"}, {"speaker": "陆昭", "text": "忍一下。"}, {"speaker": "凌瑶", "text": "他也不容易。主家刚死，自己差点淹死。"}, {"speaker": "陆昭", "text": "不容易不等于每句都经得起问。"}, {"speaker": "凌瑶", "text": "嗯。吃完去码头。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "外面有人在喊卖鱼？"}, {"speaker": "陆昭", "text": "没听见。"}, {"speaker": "凌瑶", "text": "我饿了就耳朵尖。对了。你闻到老范身上的烟味了吗？"}, {"speaker": "陆昭", "text": "烟味？"}, {"speaker": "凌瑶", "text": "不是江上的。是赌坊的。躲雨进一次，那种味沾衣服三天散不掉。"}, {"speaker": "凌瑶", "text": "问他几点回的码头，他顿了一下。"}, {"speaker": "陆昭", "text": "那一下没准备。"}, {"speaker": "凌瑶", "text": "走，去码头。顺路看看有没有卖包子的。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "火盆快灭了。"}, {"speaker": "陆昭", "text": "我去添柴。"}, {"speaker": "凌瑶", "text": "等一下，先坐着。你那披风还没干。"}, {"speaker": "凌瑶", "text": "刚才周娘子……我不知道该怎么跟她说话。"}, {"speaker": "陆昭", "text": "你都没开口。"}, {"speaker": "凌瑶", "text": "她哭的时候我不敢。眼泪没停，但手在翻账本，翻得很快。"}, {"speaker": "凌瑶", "text": "送镖时遇过这样的人家。灵堂里哭得最凶的，算账最清楚。那时候我也不敢开口。"}, {"speaker": "陆昭", "text": "你怕说错话伤她。"}, {"speaker": "凌瑶", "text": "也怕她看出来我在可怜她。"}, {"speaker": "陆昭", "text": "她说的细节你记了几条？"}, {"speaker": "凌瑶", "text": "三条。水性、时辰、老范跟阿贵的关系。"}, {"speaker": "陆昭", "text": "一条条来。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "周夫人说他从小在水边长大。"}, {"speaker": "陆昭", "text": "嗯。会水的人，不该那么快沉。"}, {"speaker": "凌瑶", "text": "嗯。"}, {"speaker": "凌瑶", "text": "走，去码头。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "十二年，给二两。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "也难怪他说老爷'还行'，不说'好'。"}, {"speaker": "凌瑶", "text": "去问他那两两银子花在哪儿了。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "你刚才差点被他那声'大人'噎住。"}, {"speaker": "陆昭", "text": "他叫得比我亲先生还响。", "emotion": "gentle_humor"}, {"speaker": "凌瑶", "text": "外面雨好像小了。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "对了。他刚才说'阿贵买过酒肉'那句，是夹在一大段废话里的。前面什么'天气不好''路不好走'，突然来一句。"}, {"speaker": "凌瑶", "text": "他每次说完'要我说嘛''不过嘛'，后面那句都不像废话。"}, {"speaker": "陆昭", "text": "老范常去赌坊也是。"}, {"speaker": "凌瑶", "text": "嗯。这两句我觉得是真的。"}, {"speaker": "陆昭", "text": "记下来。走，先去码头。"}], [{"speaker": "凌瑶", "text": "他说阿贵买过酒肉。主家刚死，仆从却有闲钱吃喝，这不顺。"}, {"speaker": "陆昭", "text": "钱从哪来，什么时候花的，都要问。", "emotion": "serious"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "天快黑了。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "你刚才一直在看他补网。全程没停。"}, {"speaker": "陆昭", "text": "跟你学的。"}, {"speaker": "凌瑶", "text": "急件还在我怀里。没湿。"}, {"speaker": "陆昭", "text": "案子结了帮你送。"}, {"speaker": "凌瑶", "text": "他今天跟上次不一样。刚才你说雾太大，他没驳，只说'那天夜里'就停了。"}, {"speaker": "陆昭", "text": "自己也知道看错了。"}, {"speaker": "凌瑶", "text": "去码头之前先整点火。真冷了。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "他刚才那句话底气不对。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "继续盯那个地方。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "这东西收好，别叫雨水湿了。"}, {"speaker": "陆昭", "text": "嗯。"}], [{"speaker": "凌瑶", "text": "好东西。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "记住这个。"}, {"speaker": "陆昭", "text": "嗯。"}], [{"speaker": "凌瑶", "text": "先收着。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "这火盆烧得旺，可门缝里还是往里灌冷风。"}, {"speaker": "陆昭", "text": "你急件还在吗？"}, {"speaker": "凌瑶", "text": "在的，没湿。怀里揣着，比暖炉强。"}, {"speaker": "陆昭", "text": "耽误你了。"}, {"speaker": "凌瑶", "text": "等会儿再算。先把今晚的事搞清楚。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "她翻账本的手，一下都没抖。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "收神，进去。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "他那双手紧紧塞在袖管里。"}, {"speaker": "陆昭", "text": "冷？"}, {"speaker": "凌瑶", "text": "不像是冷。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "这就是你上来的地方。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "那时候还没亮。我听见水响，就来了。"}, {"speaker": "陆昭", "text": "……谢谢你。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "等一下，前头泥很软。你刚从水里捞回来，别又踩下去。"}, {"speaker": "陆昭", "text": "我看起来这么不稳？", "emotion": "gentle_humor"}, {"speaker": "凌瑶", "text": "现在？像一张刚晾起来的纸。走这边，石头硬。"}, {"speaker": "陆昭", "text": "听你的。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "（停住）这船……拆成这样了。"}, {"speaker": "陆昭", "text": "……你昨晚是从哪边下水的？"}, {"speaker": "凌瑶", "text": "那边。你在船底。我在岸这头。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "这地方太安静了。风一停，水声反而清楚。"}, {"speaker": "凌瑶", "text": "你看芦苇断口，都是新的。有人来过，还不止站了一下。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "光凭嘴说来说去的，说不出来什么。去看那条船。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "阿贵认了。但她不认他。"}, {"speaker": "陆昭", "text": "嗯。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "……她那眼神。"}, {"speaker": "陆昭", "text": "怎么了？"}, {"speaker": "凌瑶", "text": "太稳了。说话不快不慢，脸上什么都没有。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "我走镖这几年，见过很多人被追债、被威胁，会慌、会哭，就是没见过像她这样的。"}, {"speaker": "陆昭", "text": "因为她知道自己在做什么。"}, {"speaker": "凌瑶", "text": "……嗯。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "（低头摸了摸怀里的急件，手停了一下）"}, {"speaker": "陆昭", "text": "怎么了？"}, {"speaker": "凌瑶", "text": "没事。走了。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "手松开。指甲快掐进肉里了。"}, {"speaker": "陆昭", "text": "……（低头看手）", "emotion": "tired"}, {"speaker": "凌瑶", "text": "她停了三次。你发现了吗？"}, {"speaker": "陆昭", "text": "第二次是刚才问老范名字的时候。"}, {"speaker": "凌瑶", "text": "嗯。还有两次是你没追的地方。"}, {"speaker": "陆昭", "text": "手心出汗了。", "emotion": "tired"}, {"speaker": "凌瑶", "text": "我知道。我一直在旁边。"}], [{"speaker": "凌瑶", "text": "那眼神……最后走的时候。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "她觉得咱们证据不够。", "emotion": "serious"}, {"speaker": "陆昭", "text": "所以她走得住。", "emotion": "tired"}, {"speaker": "凌瑶", "text": "那就把够不够的东西，给她找出来。走。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "要开始了？我手心有点汗。"}, {"speaker": "陆昭", "text": "你也紧张？"}, {"speaker": "凌瑶", "text": "第一次看人靠几句话和几件东西翻案。你问，我看他手。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "她父亲病着。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "我……理解这种急。"}, {"speaker": "陆昭", "text": "但不等于她做的事是对的。"}, {"speaker": "凌瑶", "text": "我知道。只是……"}, {"speaker": "凌瑶", "text": "走，进去。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "她不是阿贵。不会哭着认。"}, {"speaker": "陆昭", "text": "我知道。我现在已经急了，只是不能让她看出来。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "那我盯她，也盯你。你要被她带偏，我就拽袖子。尽量轻点。"}, {"speaker": "陆昭", "text": "你也别一个人扛。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "好。那就一起扛。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "她停了一下。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "继续。"}], [{"speaker": "凌瑶", "text": "她刚才那句话没接上来。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "这件压不到她刚才那句话。"}, {"speaker": "陆昭", "text": "嗯。换一句问。"}], [{"speaker": "凌瑶", "text": "她没躲这个。先别追。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "她茶还温着。像知道我们会来。"}, {"speaker": "陆昭", "text": "手呢？"}, {"speaker": "凌瑶", "text": "虎口有茧，不像只拨算盘的人。先别说破。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "这巷子里的叶子烟味……我爹当年也爱这个，被我娘拿火钳追了三条街才戒掉。"}, {"speaker": "陆昭", "text": "……你爹赌过？"}, {"speaker": "凌瑶", "text": "小时候。后来还清了。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "走，进去。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "等等。（蹲下去）你看这边缘。"}, {"speaker": "陆昭", "text": "凿的。"}, {"speaker": "凌瑶", "text": "……是凿的。"}, {"speaker": "陆昭", "text": "那老范那套话。"}, {"speaker": "凌瑶", "text": "从头都是假的。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "这是……浮囊？"}, {"speaker": "陆昭", "text": "他的包袱里的。"}, {"speaker": "凌瑶", "text": "他说不会水，什么都没备。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "……周老板呢。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "（蹲下去）新的。这断口还湿着。"}, {"speaker": "陆昭", "text": "有人今早在这儿打捞过。"}, {"speaker": "凌瑶", "text": "他算准东西会漂到这儿。不是随手，是等在这里。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "冷的很。他在这儿站了多久。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "别碰。（凑近）这味……不对。"}, {"speaker": "陆昭", "text": "什么味？"}, {"speaker": "凌瑶", "text": "辣的，又冰。不是江边的草。"}, {"speaker": "陆昭", "text": "……我认得。麻痹药，碰水就化。"}, {"speaker": "凌瑶", "text": "（抬头看他）"}, {"speaker": "陆昭", "text": "嗯。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "陆昭，这儿。"}, {"speaker": "陆昭", "text": "很浅。"}, {"speaker": "凌瑶", "text": "挣扎过。但没什么力气了。"}, {"speaker": "陆昭", "text": "……嗯。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "等等。（蹲下）这壳"}, {"speaker": "陆昭", "text": "药囊。进水口上的。"}, {"speaker": "凌瑶", "text": "这针脚……不是船工做的。太细了。"}, {"speaker": "陆昭", "text": "有人提前放在那里，等水冲开。"}, {"speaker": "凌瑶", "text": "对着凿洞的位置。"}]]
`[cb:?]` **?**: [[{"speaker": "陆昭", "text": "（翻开）八十两。"}, {"speaker": "凌瑶", "text": "……她只有四十二两。"}, {"speaker": "陆昭", "text": "差三十八两。"}, {"speaker": "凌瑶", "text": "三十八两。正是周德茂欠她的数。"}, {"speaker": "陆昭", "text": "嗯。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "阿贵那包袱的事……我还没想通。"}, {"speaker": "陆昭", "text": "哪儿？"}, {"speaker": "凌瑶", "text": "浮囊是他自己装的，还是有人塞的。这两种，后面的事不一样。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "她现在稳得很，我觉得不对劲。"}, {"speaker": "陆昭", "text": "哪儿？"}, {"speaker": "凌瑶", "text": "太稳了。不是不怕。是算过了，觉得咱们不够。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "等一下。那封急件……收件人也姓沈。"}, {"speaker": "陆昭", "text": "石矶渡姓沈的不多。"}, {"speaker": "凌瑶", "text": "我还不能说就是她。可红漆急件、药行、暴雨都撞在这一天，我心里不踏实。"}, {"speaker": "陆昭", "text": "案子完了，查镖单。"}, {"speaker": "凌瑶", "text": "嗯。先把眼前这场问完。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "emotion": "shocked", "text": "堂外比堂里还冷。"}, {"speaker": "陆昭", "emotion": "tired", "text": "嗯。"}, {"speaker": "凌瑶", "emotion": "worried", "text": "你手还在抖。"}, {"speaker": "陆昭", "emotion": "tired", "text": "冷的。"}, {"speaker": "凌瑶", "emotion": "anxious", "text": "阿贵被带走时，指甲缝里都是木屑和泥血，还攥着那张二两的字据。"}, {"speaker": "陆昭", "text": "……"}, {"speaker": "凌瑶", "emotion": "anxious", "text": "十二年，最后只剩一张纸。可他还是凿了船。"}, {"speaker": "陆昭", "emotion": "serious", "text": "嗯。委屈不能抵命。"}, {"speaker": "凌瑶", "emotion": "worried", "text": "走吧。外头风大。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "你刚才又摸腰侧了。找什么？", "emotion": "cheerful"}, {"speaker": "陆昭", "text": "官印。沉江里了。", "emotion": "tired"}, {"speaker": "凌瑶", "text": "官印？你是官家的人？", "emotion": "curious"}, {"speaker": "陆昭", "text": "……现在说不清了。", "emotion": "vulnerable"}, {"speaker": "陆昭", "text": "没官印。没人会信。", "emotion": "vulnerable"}, {"speaker": "凌瑶", "text": "不过……你一个人在那条船上，是要去哪儿的？", "emotion": "curious"}, {"speaker": "凌瑶", "text": "你说不清没关系。我也没有一定要搞明白的意思。", "emotion": "cheerful"}, {"speaker": "凌瑶", "text": "不过你被捞上来的时候，第一句话不是救我。是船上还有人。", "emotion": "curious"}, {"speaker": "陆昭", "text": "……你听见了？", "emotion": "vulnerable"}, {"speaker": "凌瑶", "text": "嗯。我看见了，就不能当没看见。就这样。", "emotion": "determined"}, {"speaker": "陆昭", "text": "……就因为这个？", "emotion": "vulnerable"}, {"speaker": "凌瑶", "text": "知道你会先想别人，就够了。剩下的慢慢补。", "emotion": "cheerful"}, {"speaker": "陆昭", "text": "……我连自己是谁都证明不了。", "emotion": "vulnerable"}, {"speaker": "陆昭", "text": "你现在走，也不算食言。", "emotion": "vulnerable"}], [{"speaker": "凌瑶", "text": "刚才在王大爷那儿，看你还挺稳的。", "emotion": "playful"}, {"speaker": "陆昭", "text": "他句句都在躲。我没想过有人能把谎说得这么顺。", "emotion": "serious"}, {"speaker": "凌瑶", "text": "行走江湖，满嘴跑舌头的人多的是。不过你刚才咬死不放的时候，倒真有几分查案的架势。", "emotion": "cheerful"}, {"speaker": "陆昭", "text": "我只是想问出真相……即便我现在连官印都丢了，证明不了自己是谁。", "emotion": "tired"}, {"speaker": "凌瑶", "text": "丢了官印，你就不是陆昭了？你若不查，死掉的人、沉下去的船就真的成无头公案了。", "emotion": "determined"}, {"speaker": "陆昭", "text": "可别人都觉得我是凶手。你不去送你那封急件，为什么偏留下来蹚这趟浑水？", "emotion": "vulnerable"}, {"speaker": "凌瑶", "text": "我看人，不看什么官印。捞你上来的时候，你连气都快喘不上来，嘴里还在喊船上还有人。", "emotion": "gentle"}, {"speaker": "陆昭", "text": "……我当时只是本能觉得还有人在下面。", "emotion": "vulnerable"}, {"speaker": "凌瑶", "text": "对啊，一个连自己命都快没了还惦记别人的人，怎么可能是凿船害命的凶手。", "emotion": "determined"}, {"speaker": "陆昭", "text": "就因为这一句……你信我？", "emotion": "gentle"}, {"speaker": "凌瑶", "text": "够了。其他的，咱们一件件查，我把你的清白找回来。", "emotion": "cheerful"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "腿麻了。"}, {"speaker": "陆昭", "text": "……"}, {"speaker": "凌瑶", "text": "靠墙站太久了。你也麻了吧？"}, {"speaker": "陆昭", "text": "还好。"}, {"speaker": "凌瑶", "text": "给你。水。"}, {"speaker": "陆昭", "text": "谢谢。"}, {"speaker": "凌瑶", "text": "雨还在下。你看那个檐角，水连成线了。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "你刚才差点把老头子的渔网问断了。他补网的手停了三次。"}, {"speaker": "陆昭", "text": "第三次是他自己知道说不通了。"}, {"speaker": "凌瑶", "text": "我怀里那封急件。刚才靠墙压了一下，希望没皱。"}, {"speaker": "陆昭", "text": "什么急件？"}, {"speaker": "凌瑶", "text": "金鳞镖局的，送到石矶渡。本来昨天就该到的。"}, {"speaker": "陆昭", "text": "耽误了。"}, {"speaker": "凌瑶", "text": "人比信要紧。走，下一个。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "外面安静了。"}, {"speaker": "陆昭", "text": "他走了。"}, {"speaker": "凌瑶", "text": "火盆快灭了。我去拨一下。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "这个客栈的茶是真难喝。凉了更难喝。"}, {"speaker": "陆昭", "text": "你没喝多少。"}, {"speaker": "凌瑶", "text": "喝了三口。第三口是苦的。"}, {"speaker": "陆昭", "text": "……那是茶叶末子。"}, {"speaker": "凌瑶", "text": "你饿不饿？我怀里还有半块饼。压碎了，但还能吃。"}, {"speaker": "陆昭", "text": "不饿。"}, {"speaker": "凌瑶", "text": "那我留着。等你想吃的时候叫我。"}, {"speaker": "陆昭", "text": "……他刚才说到赌债的时候，手在抖。"}, {"speaker": "凌瑶", "text": "不是怕。是说到那笔数目，他自己也难受。"}, {"speaker": "陆昭", "text": "下一场是什么？"}, {"speaker": "凌瑶", "text": "阿贵。那个手缩在袖子里的。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "姜汤。"}, {"speaker": "陆昭", "text": "……谢谢。"}, {"speaker": "凌瑶", "text": "烫不烫？"}, {"speaker": "陆昭", "text": "烫。"}, {"speaker": "凌瑶", "text": "好。烫说明还活着。"}, {"speaker": "凌瑶", "text": "外面雨停了。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "你怕什么？"}, {"speaker": "陆昭", "text": "不是怕输。是怕证据全对了。她还是走得掉。"}, {"speaker": "凌瑶", "text": "……嗯。"}, {"speaker": "凌瑶", "text": "我知道这种感觉。押镖的时候也有。该赢的仗打完了，走出门，镖还是丢了。"}, {"speaker": "陆昭", "text": "你怎么处理那种感觉的？"}, {"speaker": "凌瑶", "text": "接下来那趟镖打起精神继续押。"}, {"speaker": "凌瑶", "text": "你嘴角动了一下。"}, {"speaker": "陆昭", "text": "没有。"}, {"speaker": "凌瑶", "text": "有。"}, {"speaker": "陆昭", "text": "……明天我不会让她走的。"}, {"speaker": "凌瑶", "text": "行。我信你。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "这江风……"}, {"speaker": "陆昭", "text": "怎么了？"}, {"speaker": "凌瑶", "text": "没什么。想起我爹了。"}, {"speaker": "陆昭", "text": "他也跑这条江的？"}, {"speaker": "凌瑶", "text": "嗯。撑货船的。后来有一年，出去就没回来。我那时候七岁。"}, {"speaker": "陆昭", "text": "……"}, {"speaker": "凌瑶", "text": "昨晚看见你在水里扑腾，就没想别的，先捞再说。"}, {"speaker": "陆昭", "text": "谢谢你。"}, {"speaker": "凌瑶", "text": "谢什么，应该的。"}]]
`[cb:?]` **?**: [[{"speaker": "凌瑶", "text": "四十二两。我爹当年欠过七八两，除夕躲在船篷里不敢回家。"}, {"speaker": "陆昭", "text": "……"}, {"speaker": "凌瑶", "text": "后来把钱还清了，扛麻袋扛了半年。踏进家门那天，他说最难的不是被债主追。是站在门口，瞧见里头的灯，硬是迈不进去。"}, {"speaker": "陆昭", "text": "老范那条路……"}, {"speaker": "凌瑶", "text": "嗯。他自己堵死的。"}]]

## 讨论

`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "沈姑娘还在楼上吗？"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "阿贵认了。那货银不知道在哪儿，下游那片。我总觉得有东西。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "浅滩那边，昨晚天亮前有人去过。我睡前出去喝水，看见有火光，当时没在意。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "老范的赌债。他怎么欠进去的，我们都不知道。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "周老板喝了一肚子油腻还赶夜船。你问没问他船上吃了什么？"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "那个浮囊不是怕万一用的。它是给知道船会进水的人准备的。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "阿贵说了，但他一个人不够。"}, {"speaker": "陆昭", "text": "对。一个人说的话，谁都能说他是在攀咬。"}, {"speaker": "凌瑶", "text": "嗯。我去看看浅滩那边。你去哪？"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "阿贵说你用铁器砸人。周老板身上有没有伤，我们去看了吗？"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "老范说在水里泡了半个时辰。大冷天泡那么久，上岸的时候总得有人瞧见他。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "凿了船的人肯定给自己留了活路。浮囊是一个，还有没有别的。芦苇丛那边没看过。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "阿贵跟了十二年，突然下手。这事不说清楚说不通。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "差不多了。去把人叫到一块儿吧。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "那条船底……你还想再看一眼吗？"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "好，我陪你去。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "沈姑娘……我看不透她。她一直是那个眼神，从头到尾没变过。"}, {"speaker": "陆昭", "text": "她父亲病了，欠的债也是真的。"}, {"speaker": "凌瑶", "text": "我知道。所以才看不透她。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "沈姑娘一个人坐在楼上，像在等什么。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "阿贵身上那个浮囊。是别人给的。一个十六岁的仆从，哪儿来的钱。"}, {"speaker": "陆昭", "text": "有人替他想好了后路。"}, {"speaker": "凌瑶", "text": "嗯，所以那个人也知道船要沉。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "阿贵和老范。感觉是被同一件事堵进来的。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "阿贵之前一直盯着那个包袱，话却说得很顺溜。"}, {"speaker": "陆昭", "text": "顺溜到不像临时想出来的。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "老范……他走东汊，说南汊堵了。可昨天停在渡口的船里，有两条是从南汊来的。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "同船三个人，死的是最会水的。活下来的说自己不会水。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "这说不通。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "老范和阿贵，哪个先知道船会沉？"}, {"speaker": "陆昭", "text": "……或者两个都知道。"}, {"speaker": "凌瑶", "text": "可两个人凑在一起策划这种事，需要有个人牵线。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "老范太稳了。船刚沉，死了人，他说话不乱。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "阿贵怕得真实。可那些话像提前想好的。怕的是露馅，不是说错了。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "现在说不好。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "那就一个个问。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "银子、码头时辰、船底药囊，都有了。"}, {"speaker": "陆昭", "text": "还要让它们对上同一个时辰。"}, {"speaker": "凌瑶", "text": "走吧。她会拆，我们就让她拆不开。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "还差一点。"}, {"speaker": "陆昭", "text": "差哪儿？"}, {"speaker": "凌瑶", "text": "现在东西在手里，可还落不到她身上。"}, {"speaker": "陆昭", "text": "再去看一遍。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "光阿贵说可不成。她不认这个人。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "老范和阿贵这边，我觉得够了。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "还缺东西。"}, {"speaker": "陆昭", "text": "什么？"}, {"speaker": "凌瑶", "text": "能把她带到船边的东西。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "被人指着鼻子骂凶手，你一直都这么稳的？"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "我是金鳞镖局的，押一封急件路过。雨大封了航，就在客栈等船。"}, {"speaker": "凌瑶", "text": "那急件委托人的底单，等案子完了我得回分舵查查。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "押急件路过，遇上暴雨，船没等到，倒先把你从江里捞上来了。"}, {"speaker": "陆昭", "text": "……缘分。"}, {"speaker": "凌瑶", "text": "折腾的缘分。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "她父亲病了，欠了三个月的药债。我听说是这样的。"}, {"speaker": "陆昭", "text": "嗯。"}, {"speaker": "凌瑶", "text": "我理解急到那个地步的感觉。但害人是害人，说不过去就是说不过去。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "阿贵都招了，她还坐在那儿。"}, {"speaker": "陆昭", "text": "她知道一个人的话不够。"}, {"speaker": "凌瑶", "text": "嗯。所以她现在很安稳。"}]
`[cd:?]` **?**: [{"speaker": "凌瑶", "text": "她说话不紧不慢，我听着就发毛。"}, {"speaker": "陆昭", "text": "为什么？"}, {"speaker": "凌瑶", "text": "因为我不知道哪句是真的。"}]

---

*本文档由 tools/export_prologue_md.py 自动生成。*
*修改后运行 tools/import_prologue_md.py 写回源文件。*
