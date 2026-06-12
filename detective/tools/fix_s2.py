#!/usr/bin/env python3
"""Fix dialogue_lines.csv: remove old cabin sections, insert Agent S2 content."""
import csv

# Read original
rows = []
with open('data/case_tables/prologue_ferry/dialogue_lines.csv', 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    for row in reader:
        rows.append(row)

# Filter: skip old cabin sections
filtered = [header]
skip = False
for row in rows:
    line = ','.join(row)
    if '船舱阶段对话内容' in line:
        skip = True
        continue
    if skip and '阶段化 Hub' in line:
        skip = False
        filtered.append(row)
        continue
    if skip:
        continue
    # Also skip old cabin data rows that might be outside markers
    npc_id = row[0] if row else ''
    if npc_id in ('agui_cabin', 'lao_fan_cabin', 'zhou_de_gui_cabin'):
        continue
    filtered.append(row)

# Agent S2 content
agent = [
    ['# === Agent重写：船舱闲谈（陆昭×3NPC）==='],
    # Zhou Degui
    ['zhou_de_gui_cabin','ask_background','0','','陆昭','','周老板，前舱油味真香——老范炸的河鲜？我这有块炊饼，可惜船晃压扁了。武昌早市的布好卖？','gentle_humor'],
    ['zhou_de_gui_cabin','ask_background','1','zhou_de_gui_cabin','','','油味？老范炸的河鲜，我让他弄的——跑夜船不垫口东西，胃里翻。你那炊饼压扁了也能吃，别嫌。','brusque'],
    ['zhou_de_gui_cabin','ask_background','2','zhou_de_gui_cabin','','','好卖？那可不。荆江来的布，武昌早市一口价，去晚了连剩布都轮不上。','business'],
    ['zhou_de_gui_cabin','ask_background','3','zhou_de_gui_cabin','','','阿贵！那两口红箱子靠墙放！别蹭着漆——五十两的货，磕坏一寸扣你工钱。','brusque'],
    ['zhou_de_gui_cabin','ask_night_ferry','0','','陆昭','','头回走水路。本来官道的，驿丞说前头泥坡塌了才改的船。你这买卖这么急——非得今晚走？','gentle_humor'],
    ['zhou_de_gui_cabin','ask_night_ferry','1','zhou_de_gui_cabin','','','急？这买卖不等人。武昌码头的布，辰时开市午时裁完，你到晚了就只能捡剩的。','business'],
    ['zhou_de_gui_cabin','ask_night_ferry','2','zhou_de_gui_cabin','','','船家老范，老把式了，我常找他跑夜船。他路子熟，这江上哪块有暗礁他闭着眼都知道。','brusque'],
    ['zhou_de_gui_cabin','press_cargo_marks','0','','陆昭','','老范炸的河鲜味真香——压扁的炊饼蘸点油还能吃。这船晃得厉害，周老板不怕水？','gentle_humor'],
    ['zhou_de_gui_cabin','press_cargo_marks','1','zhou_de_gui_cabin','','','怕水？哈！我年轻时跑江船落过一回水，冬天，江水冰得扎骨头，照样游回来了。','brusque'],
    ['zhou_de_gui_cabin','press_cargo_marks','2','zhou_de_gui_cabin','','','这江上讨饭吃的人，不会水早死绝了。你就坐着，到了武昌就好了。','business'],
    ['zhou_de_gui_cabin','ask_business','0','','陆昭','','冬天落水还能游回来——周老板水性真好。五十两的货到了武昌能翻一番？这买卖比读书强。','gentle_humor'],
    ['zhou_de_gui_cabin','ask_business','1','zhou_de_gui_cabin','','','嘿嘿，那可不。五十两的货到了早市翻一番不是问题。这价钱你上哪找——我说了算。','business'],
    ['zhou_de_gui_cabin','ask_business','2','zhou_de_gui_cabin','','','比读书强？那倒未必——不过书生，你读你的书，我赚我的银，各走各的。行了，别聊了，我还有货要看。','brusque'],
    # Agui
    ['agui_cabin','ask_master','0','','陆昭','','这船晃得厉害。我头回坐夜船，腿有点软。你是周老板的伙计？常跟船出门？','gentle_humor'],
    ['agui_cabin','ask_master','1','agui_cabin','','','小的……小的不常坐船。老爷走货才跟着，一年也就两三回。夜船是头一回，风浪大，小的、小的腿都软了。','nervous'],
    ['agui_cabin','ask_master','2','agui_cabin','','','小的跟了老爷十二年。从万历十年起就在周家，倒茶、搬货、守夜，什么活都干过。大人您头回夜船就赶东汊，胆子比小的……比小的大多了。','nervous'],
    ['agui_cabin','ask_voyage','0','','陆昭','','十二年。不容易。今晚走东汊——听说那段水有暗礁？我腿都软了，你呢？','gentle_humor'],
    ['agui_cabin','ask_voyage','1','agui_cabin','','','怕……老范说那段水有暗礁，浪也大。小的不会水，心里慌。可老爷催得紧，不敢不从。','nervous'],
    ['agui_cabin','ask_voyage','2','agui_cabin','','','大人您也腿软？那、那小的就不那么丢人了……小的带了浮囊，怕死，怕死也不行么。','nervous'],
    ['agui_cabin','ask_feelings','0','','陆昭','','带了浮囊就好——怕死不丢人，我也怕。十二年都在周家，没成个家？','gentle_humor'],
    ['agui_cabin','ask_feelings','1','agui_cabin','','','小的……小的没成家。十二年都在周家，没顾上。回乡……回乡也不知道投奔谁。','shaken'],
    ['agui_cabin','ask_feelings','2','agui_cabin','','','老爷说到了东汊就遣散小的。十二年……给了二两银子。管饭、管住，工钱早算在里头了。小的……小的不敢怎样。','defensive'],
    ['agui_cabin','press_bag','0','','陆昭','','二两……你包袱鼓鼓的，带了路上用的？','gentle_humor'],
    ['agui_cabin','press_bag','1','agui_cabin','','','不、不是吃的……是几件旧衣裳。老爷说到了东汊就遣散小的，让小的收拾利索些。','nervous'],
    ['agui_cabin','press_bag','2','agui_cabin','','','小的不会水，才带了个浮囊。大人您别笑话小的，小的就是个怕死的下人……','nervous'],
    # Lao Fan
    ['lao_fan_cabin','ask_route','0','','陆昭','','老范，这风听得我后背发凉。头回走夜船，上船前又听人说东汊有暗礁——你是老把式，心里有数？','gentle_humor'],
    ['lao_fan_cabin','ask_route','1','lao_fan_cabin','','','后背发凉？头回坐夜船都这样——我头一回跑夜路也悬，舵都握出汗来。东汊那几块石头，是有，不多。我跑了二十年，哪块在水下多深、离船帮多远，闭着眼都绕得开。您踏实坐着，过了前面那个弯水面就宽了，风也没这么急了。','smirk'],
    ['lao_fan_cabin','ask_weather','0','','陆昭','','头回也悬——那我踏实点了。二十年什么天气都见过了吧？今晚这风不算最凶的？','gentle_humor'],
    ['lao_fan_cabin','ask_weather','1','lao_fan_cabin','','','二十年——嗐，什么天气没见过。大雪天跑过，江面白得睁不开眼。三伏天暴雨说来就来，浪头比船棚还高。今晚这风不算最凶的，就是吹得紧了些。吃水的饭嘛，哪有不湿鞋的。不过说句实话——跑夜船最怕的不是风，是雾。起了雾，有眼睛也跟瞎子一样。今晚还好，雨大归大，没雾。','smirk'],
    ['lao_fan_cabin','ask_money','0','','陆昭','','没雾就好。跑夜船比白天多挣吧？这大半夜的，周老板加了钱？','gentle_humor'],
    ['lao_fan_cabin','ask_money','1','lao_fan_cabin','','','加钱？嗐——周老爷给的是行价，没多。跑夜船嘛，比白天多挣几个铜板，可也累人。白天跑一趟回来还能眯一会儿，夜里跑完天都快亮了。不过话说回来——这年头有船跑就不错了，码头上闲着等活儿的船家多得是。周老爷不找我，这趟活儿就是别人的。','smirk'],
    ['lao_fan_cabin','press_crowbar','0','','陆昭','','刚才在舱里听见船底有声响——像板子磕碰。老船了？','gentle_humor'],
]

# Find insertion point: before Hub section
insert_idx = None
for i, row in enumerate(filtered):
    line = ','.join(row) if row else ''
    if '阶段化 Hub' in line:
        insert_idx = i
        break

if insert_idx:
    final = filtered[:insert_idx] + agent + filtered[insert_idx:]
else:
    final = filtered + agent

with open('data/case_tables/prologue_ferry/dialogue_lines.csv', 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f, lineterminator='\n')
    writer.writerows(final)

print(f'OK: {len(final)} rows written')
