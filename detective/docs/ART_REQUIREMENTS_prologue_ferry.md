# 序章「渡口沉舟」— 美术资产需求清单

> 生成顺序：先角色立绘 → 再以立绘为 reference 做场景过场图 (img2img)

---

## 一、角色立绘（5 人）

| # | npc_id | 角色名 | 描述 | 风格要求 |
|---|--------|--------|------|----------|
| 1 | `agui` | 阿贵 | 三十出头男性仆从。方脸，面相老实敦厚，但眼神里有一丝闪烁。穿灰蓝色粗布棉袍，腰系布带。 | 明代服饰，水墨画风 |
| 2 | `lao_fan` | 老范 | 四十多岁船家。黝黑精瘦，颧骨突出，手上满是老茧。穿短褐，头扎粗布巾。 | 明代服饰，水墨画风 |
| 3 | `zhou_wife` | 周氏 | 三十五岁左右中年妇人。素服（丈夫刚亡），眼圈红肿但神态坚定。梳简单发髻。 | 明代服饰，水墨画风 |
| 4 | `li_zheng` | 钱里正 | 五十多岁地方小吏。微胖，圆脸，笑眯眯的但有精明相。穿深色长衫，戴小帽。 | 明代服饰，水墨画风 |
| 5 | `fisherman_wang` | 王老汉 | 六十多岁渔翁。消瘦佝偻，一张被江风吹皱的脸。穿蓑衣或短褐，手里拿着渔网。 | 明代服饰，水墨画风 |

---

## 二、场景背景（5 张）

| # | location_id | 场景名 | 描述 | 时间/天气 |
|---|-------------|--------|------|-----------|
| 1 | `ferry_inn` | 石矶渡·客栈 | 长江边的简陋客栈。土墙、木梁、灰瓦。门前泥泞，屋檐滴水。远处可见江面和几条船。 | 阴天/小雨，黄昏 |
| 2 | `ferry_dock` | 石矶渡·码头 | 雨中的小渡口码头。几条乌篷船歪斜停泊，岸边有竹竿、缆绳。一条翻覆的破船被拖上岸。江水浑浊。 | 白天，大雨 |
| 3 | `wreck_site` | 沉船打捞处 | 下游礁石群。两块大石之间卡着半截船身，船底朝天。周围散落木片碎板。江水拍打石头。 | 白天，阴天 |
| 4 | `river_bend` | 江湾渔村 | 长江下游小江湾。几间茅屋散落，竹竿上晾着渔网。水面薄雾，远处青山隐约。宁静清冷。 | 清晨，薄雾 |
| 5 | (prologue用) | 雨夜码头·开场 | 黎明时分的石矶渡码头。暴雨倾盆，天色昏暗。岸边一具尸体面朝下趴在水里，周围站着一圈人。 | 黎明，暴雨 |

---

## 三、过场图 / CG（4 张，img2img 从角色立绘出发）

| # | 场景 | 描述 | 需要的角色 reference |
|---|------|------|---------------------|
| 1 | 开场：发现尸体 | 暴雨黎明。码头岸边，一具面朝下的尸体泡在浑水中。围观人群远远站着。气氛阴森肃杀。 | (无特写角色) |
| 2 | 周氏跪地拦陆昭 | 雨中泥地。一个素服妇人（周氏）跪着死死抓住一个青年男子（陆昭）的衣角。背景是码头和围观人群。 | 周氏 + 陆昭 |
| 3 | 凌瑶冲来 | 一个穿深蓝灰短衫的年轻女子（凌瑶）挤过人群，浑身湿透，辫子甩在脑后，表情焦急又兴奋。 | 凌瑶（主角立绘 reference） |
| 4 | 结案后：密信 | 雨停后。凌瑶从船板缝隙中捞出一封泡烂的信，陆昭站在旁边看。远处江面薄雾，氛围从紧张转为神秘。 | 凌瑶 + 陆昭 |

---

## 四、证据图标（7 张，小图标）

| # | evidence_id | 名称 | 描述 |
|---|-------------|------|------|
| 1 | `evidence_hull_hole` | 船底人工破洞 | 一块木板上有整齐的凿痕，边缘有钉眼 |
| 2 | `evidence_float_bladder` | 牛皮浮囊 | 鼓鼓囊囊的水牛皮气囊，有系绳 |
| 3 | `evidence_gambling_iou` | 赌债字据 | 皱巴巴的借据，上面有毛笔字 |
| 4 | `evidence_dismissal_note` | 遣散字据 | 一张较新的纸张，上有规整笔迹 |
| 5 | `evidence_cargo_silver` | 失踪的货银 | 空荡荡的钱袋/箱子，暗示银两已失 |
| 6 | `evidence_nail_marks` | 船底钉痕 | 木板特写，上面有新旧两排钉眼 |
| 7 | `evidence_wet_letter` | 泡烂的密信 | 泡水发透的信纸，字迹模糊，仅几个字可辨 |

---

## 五、风格规范

- **整体风格**：中国水墨画风 + 略带写实质感
- **色调**：冷灰蓝为主（冬雨/江水），点缀暖黄（灯火/烛光）
- **参考**：与现有浔阳楼案保持一致性（同一画风 pipeline）
- **角色一致性**：所有含角色的场景图必须以角色立绘为 reference image 做 img2img
- **陆昭/凌瑶**：使用现有主角立绘（`companion_lingyao.png` / `actor_protagonist.png`）作为 base

---

## 六、文件命名规范

```
assets/cn/portraits/prologue_agui.png
assets/cn/portraits/prologue_lao_fan.png
assets/cn/portraits/prologue_zhou_wife.png
assets/cn/portraits/prologue_li_zheng.png
assets/cn/portraits/prologue_fisherman_wang.png

assets/cn/scenes/prologue_ferry_inn.png
assets/cn/scenes/prologue_ferry_dock.png
assets/cn/scenes/prologue_wreck_site.png
assets/cn/scenes/prologue_river_bend.png
assets/cn/scenes/prologue_cold_open.png

assets/cn/scenes/prologue_cg_body.png
assets/cn/scenes/prologue_cg_zhou_kneel.png
assets/cn/scenes/prologue_cg_lingyao_rush.png
assets/cn/scenes/prologue_cg_letter.png

assets/cn/evidence/prologue_hull_hole.png
assets/cn/evidence/prologue_float_bladder.png
assets/cn/evidence/prologue_gambling_iou.png
assets/cn/evidence/prologue_dismissal_note.png
assets/cn/evidence/prologue_cargo_silver.png
assets/cn/evidence/prologue_nail_marks.png
assets/cn/evidence/prologue_wet_letter.png
```
