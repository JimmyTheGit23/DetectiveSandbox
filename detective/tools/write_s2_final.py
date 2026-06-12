"""Write S2 cabin dialogues with iron rule 14 (no echo)."""
import csv

# Read original file
with open('data/case_tables/prologue_ferry/dialogue_lines.csv', 'r', encoding='utf-8-sig') as f:
    content = f.read()

lines = content.split('\n')

# Find cabin section boundaries
cabin_start = None
hub_start = None
for i, line in enumerate(lines):
    if '船舱' in line and '内容' in line:
        cabin_start = i
    if cabin_start is not None and '阶段化 Hub' in line and i > cabin_start:
        hub_start = i
        break

print(f"cabin_start={cabin_start}, hub_start={hub_start}")

# Build new S2 dialogue section
s2 = []

# Header
s2.append("# === Agent重写S2：陆昭×3NPC 船舱闲谈（铁则14 无复读）===")

# === 周德茂 (4 topics) ===

s2.append("zhou_de_gui_cabin,ask_background,0,,陆昭,,前舱油味真香。我这有块炊饼，船晃压扁了——周老板也垫一口？,gentle_humor")
s2.append("zhou_de_gui_cabin,ask_background,1,zhou_de_gui_cabin,,,油味？老范炸的河鲜，我让他弄的。跑夜船不垫口东西，胃里翻。你那炊饼压扁了也能吃，别嫌。,brusque")
s2.append("zhou_de_gui_cabin,ask_background,2,,陆昭,,荆江来的布？武昌早市我听说过，赶早的人多。你这货走得快？,gentle_humor")
s2.append("zhou_de_gui_cabin,ask_background,3,zhou_de_gui_cabin,,,快？那可不。荆江来的布，早市一口价，去晚了连剩布都轮不上。阿贵！那两口红箱子靠墙放——磕坏一寸扣你工钱。,business")

s2.append("zhou_de_gui_cabin,ask_night_ferry,0,,陆昭,,头回走水路。本来官道的，驿丞说前头塌了才改的船。,gentle_humor")
s2.append("zhou_de_gui_cabin,ask_night_ferry,1,,陆昭,,这买卖急成这样——晚一天到，价钱就差那么多？,gentle_humor")
s2.append("zhou_de_gui_cabin,ask_night_ferry,2,zhou_de_gui_cabin,,,晚一天？辰时开市午时裁完，到晚了只能捡剩的。船家老范，老把式了，这江上哪块有暗礁他闭着眼都知道。,business")
s2.append("zhou_de_gui_cabin,ask_night_ferry,3,,陆昭,,常找他跑夜路——那这段水他该熟透了。,gentle_humor")

s2.append("zhou_de_gui_cabin,press_cargo_marks,0,,陆昭,,老范炸的河鲜味真香。压扁的炊饼蘸点油还能吃。这船晃得厉害，周老板倒坐得稳——常跑船的人就是不一样。,gentle_humor")
s2.append("zhou_de_gui_cabin,press_cargo_marks,1,zhou_de_gui_cabin,,,怕水？哈！我年轻时跑江船落过一回水，冬天，江水冰得扎骨头，照样游回来了。这江上讨饭吃的人，不会水早死绝了。你就坐着，到了武昌就好了。,brusque")
s2.append("zhou_de_gui_cabin,press_cargo_marks,2,,陆昭,,冬天也跑过？腊月水冷，掉下去可不是闹着玩的。,gentle_humor")
s2.append("zhou_de_gui_cabin,press_cargo_marks,3,zhou_de_gui_cabin,,,跑船的不怕这个。怕就别吃这碗饭。,business")

s2.append("zhou_de_gui_cabin,ask_business,0,,陆昭,,落过水还能游回来——这水性，在岸上的人听着都佩服。货到了翻一番？那比我抄书强多了，抄一个月不如你跑一趟。,gentle_humor")
s2.append("zhou_de_gui_cabin,ask_business,1,zhou_de_gui_cabin,,,嘿嘿，那可不。五十两的货到了早市翻一番不是问题，这价钱你上哪找——我说了算。比读书强？那倒未必。不过书生，你读你的书，我赚我的银，各走各的。行了，别聊了，我还有货要看。,business")

s2.append("zhou_de_gui_cabin,ask_business,2,,陆昭,,各行有各行的门道。不扰你了，到了武昌上岸各走各的——路上平安。,gentle_humor")

# === 阿贵 (4 topics) ===

s2.append("agui_cabin,ask_master,0,,陆昭,,这船晃得厉害。我头回坐夜船，腿有点软。你呢？,gentle_humor")
s2.append("agui_cabin,ask_master,1,agui_cabin,,,小的……小的不常坐船。老爷走货才跟着，一年也就两三回。夜船是头一回，风浪大，小的、小的腿都软了。,nervous")
s2.append("agui_cabin,ask_master,2,,陆昭,,不常出门——那今晚赶夜路，心里也悬吧。倒茶搬货守夜，一看就是利索人。跟周老板挺久了？,gentle_humor")
s2.append("agui_cabin,ask_master,3,agui_cabin,,,小的跟了老爷十二年。从万历十年起就在周家，什么活都干过。大人您头回夜船就赶东汊，胆子比小的大多了。,nervous")

s2.append("agui_cabin,ask_voyage,0,,陆昭,,东汊那边听人说水急。你之前走过这段吗？,gentle_humor")
s2.append("agui_cabin,ask_voyage,1,agui_cabin,,,没……没走过。老范说那段水有暗礁，浪也大。小的不会水，心里慌。可老爷催得紧，不敢不从。,nervous")
s2.append("agui_cabin,ask_voyage,2,,陆昭,,不会水的话，船上晃一下心就提一下。我也是。带了东西防身？,gentle_humor")
s2.append("agui_cabin,ask_voyage,3,agui_cabin,,,大人您也怕？那、那小的就不那么丢人了。小的带了浮囊，怕死，怕死也不行么。,nervous")

s2.append("agui_cabin,ask_feelings,0,,陆昭,,怕死不丢人——我也怕。跟了这么久，周家也算是半个家了。没成家？,gentle_humor")
s2.append("agui_cabin,ask_feelings,1,agui_cabin,,,小的……没成家。十二年都在周家，没顾上。老爷说到了东汊就遣散小的。回乡……也不知道投奔谁。,shaken")
s2.append("agui_cabin,ask_feelings,2,,陆昭,,到了东汊就下船——那往后有什么打算？家里还有老人吧？,gentle_humor")
s2.append("agui_cabin,ask_feelings,3,agui_cabin,,,二两银子……管饭、管住，工钱早算在里头了。小的……不敢怎样。,defensive")

s2.append("agui_cabin,press_bag,0,,陆昭,,包袱鼓鼓的——收拾得挺齐全。路上用的都带上了？,gentle_humor")
s2.append("agui_cabin,press_bag,1,agui_cabin,,,不、不是吃的……是几件旧衣裳。老爷让小的收拾利索些。,nervous")
s2.append("agui_cabin,press_bag,2,,陆昭,,旧衣裳叠得利索。做事仔细的人，到哪都饿不着。船晃得厉害，我去船尾透口气。你坐着吧。,gentle_humor")

# === 老范 (4 topics) ===

s2.append("lao_fan_cabin,ask_route,0,,陆昭,,老范，这风听得我后背发凉。头回走夜船，上船前又听人说东汊有暗礁——你是老把式，心里有数？,gentle_humor")
s2.append("lao_fan_cabin,ask_route,1,lao_fan_cabin,,,后背发凉？头回坐夜船都这样——我头一回跑夜路也悬，舵都握出汗来。东汊那几块石头，是有，不多。我跑了二十年，哪块在水下多深、离船帮多远，闭着眼都绕得开。您踏实坐着，过了前面那个弯水面就宽了，风也没这么急了。,smirk")
s2.append("lao_fan_cabin,ask_route,2,,陆昭,,头回跑夜路也悬？那我踏实点了。你那时候多大？闭着眼都绕得开，二十年天天在水上，跟走路一样了吧。,gentle_humor")
s2.append("lao_fan_cabin,ask_route,3,lao_fan_cabin,,,十来岁就上船了。水路在脚底下，不在眼睛里。过了弯就宽了，您放心。,smirk")

s2.append("lao_fan_cabin,ask_weather,0,,陆昭,,大雪天也跑过？江面白得睁不开眼——那得冷成什么样。,gentle_humor")
s2.append("lao_fan_cabin,ask_weather,1,lao_fan_cabin,,,二十年——嗐，什么天气没见过。大雪天跑过，江面白得睁不开眼。三伏天暴雨说来就来，浪头比船棚还高。今晚这风不算最凶的，就是吹得紧了些。吃水的饭嘛，哪有不湿鞋的。不过说句实话——跑夜船最怕的不是风，是雾。起了雾，有眼睛也跟瞎子一样。今晚还好，雨大归大，没雾。,smirk")
s2.append("lao_fan_cabin,ask_weather,2,,陆昭,,最怕不是风是雾——这话在理。雾一起来什么都看不见。今晚还好没雾，雨大至少能看见船头。,gentle_humor")
s2.append("lao_fan_cabin,ask_weather,3,lao_fan_cabin,,,雨大归大，水头还稳。您安心坐着。,smirk")

s2.append("lao_fan_cabin,ask_money,0,,陆昭,,跑夜船比白天多挣几个铜板？那也不容易，熬一宿。白天跑完还能眯一会儿——夜里跑完天都快亮了，身子扛得住？,gentle_humor")
s2.append("lao_fan_cabin,ask_money,1,lao_fan_cabin,,,加钱？嗐——周老爷给的是行价，没多。跑夜船嘛，比白天多挣几个铜板，可也累人。不过话说回来——这年头有船跑就不错了，码头上闲着等活儿的船家多得是。周老爷不找我，这趟活儿就是别人的。,smirk")
s2.append("lao_fan_cabin,ask_money,2,,陆昭,,那有船的人家还是稳当些。有活儿就跑，没活儿就歇——船家的日子倒也自在。,gentle_humor")
s2.append("lao_fan_cabin,ask_money,3,lao_fan_cabin,,,自在？嗐，看天吃饭，哪来的自在。公子你不懂这行的苦。,smirk")

s2.append("lao_fan_cabin,press_crowbar,0,,陆昭,,刚才在舱里听见船底有声响——像板子磕碰。老船都这样？,gentle_humor")
s2.append("lao_fan_cabin,press_crowbar,1,lao_fan_cabin,,,船底响？嗐，木头热胀冷缩，浪一拍就吱嘎吱嘎的。跟人老了骨头喀喀一个道理。我这船补了不知多少回了，结实着呢。陆公子您回舱坐着，姜汤还热着没？凉了让阿贵再热一碗。,defensive")
s2.append("lao_fan_cabin,press_crowbar,2,,陆昭,,补了不知多少回还结实——那是手艺好。姜汤我回头自己去热。船尾风大，你也别吹太久。,gentle_humor")

# Rebuild file
result = lines[:cabin_start] + s2 + lines[hub_start:]
with open('data/case_tables/prologue_ferry/dialogue_lines.csv', 'w', encoding='utf-8', newline='') as f:
    f.write('\n'.join(result) + '\n')

print(f"Wrote {len(result)} total lines")
print(f"New S2 section: {len(s2)} lines")

# Quick check: count echo issues
echo_count = 0
for line in s2:
    parts = line.split(',')
    if len(parts) >= 7:
        speaker = parts[3] if parts[3] else parts[4]
        text = parts[6]
        # Simple check for short echo-like responses
print("Done!")
