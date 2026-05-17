"""补齐 4 个 NPC 对话树，让 schedule 矛盾能被反复验证。"""
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
dlg_dir = root / "data/cases/xunyang_pavilion/dialogues"

# === 卜掌柜 ===
bu_zhang = {
    "_comment": "城南布庄掌柜。D1 午时凶手 qing_xuan 来买新红绸，他亲眼所见。",
    "start": "greet",
    "nodes": {
        "greet": {
            "text": "（卜掌柜抬眼）大人光临布庄，可是看货？",
            "options": [
                {"text": "案发那天可有人买过绛红云纹绸？", "goto": "about_silk", "hide_after_visit": True},
                {"text": "（出示红绸残片）能否对一下织法？", "goto": "match_silk", "requires": {"evidence": "evidence_torn_silk"}, "cost_time": 1, "hide_after_visit": True},
                {"text": "（先告辞）", "goto": "__exit__"}
            ]
        },
        "about_silk": {
            "text": "（顿）这……案发当日午时确有一笔，是位白衣公子急要的，连名都没留全，只签了个「玄」字。\n\n他要的是整匹未断的——我心里就奇怪，浔阳楼那批红绸刚出三日，怎的这位公子又赶着补一匹。",
            "set_flags": ["bu_zhang_revealed_white_buyer"],
            "options": [
                {"text": "请出示账册", "goto": "show_ledger", "hide_after_visit": True},
                {"text": "（先记下）", "goto": "greet"}
            ]
        },
        "show_ledger": {
            "text": "（取出账册）大人您看，这笔记得急，字也歪。买的还是一整匹——三尺八，少见。\n\n他付的是碎银，没要单子。我也是后来听浔阳楼出事，才把这笔记上的。",
            "set_flags": ["silk_buyer_is_white_robed"],
            "reward": {"evidence": "evidence_silk_purchase_receipt"},
            "options": [{"text": "（记下离开）", "goto": "__exit__"}]
        },
        "match_silk": {
            "text": "（对比片刻）大人，这残片的织纹与浔阳楼出的那批是一致的。但那匹绛红云纹绸全城只有我柜上出——三日前刚卖出一匹给浔阳楼，案发当日午时又卖出一匹给那位白衣公子。",
            "set_flags": ["silk_source_confirmed"],
            "options": [{"text": "（先告辞）", "goto": "greet"}]
        }
    }
}

# === 刘船家 ===
liu_chuan = {
    "_comment": "江畔船家。D1 昏时凶手 qing_xuan 在水阁销证，他打盹被惊醒目击。",
    "start": "greet",
    "nodes": {
        "greet": {
            "text": "（刘船家眼神躲闪，正在收缆绳）大人……要渡江么？",
            "options": [
                {"text": "案发那夜你在水阁吗？", "goto": "about_night", "hide_after_visit": True},
                {"text": "（出示江畔乱痕）水阁这边昨夜被人来过。", "goto": "confront_traces", "requires": {"evidence": "evidence_dock_disturbed"}, "cost_time": 1, "hide_after_visit": True},
                {"text": "（先告辞）", "goto": "__exit__"}
            ]
        },
        "about_night": {
            "text": "（搓手）……三更头我打盹被惊醒，看见一个白影从水阁那头走出来，往江边丢了个包袱。我没敢出声。",
            "set_flags": ["liu_chuan_witnessed_disposal"],
            "options": [
                {"text": "是男是女？", "goto": "gender", "hide_after_visit": True},
                {"text": "（先告辞）", "goto": "greet"}
            ]
        },
        "gender": {
            "text": "（低声）男的。白衣。瘦。脚步轻——像是会做工夫的，不像寻常书生。\n\n包袱沉得很，丢下水扑通一声，溅起的水花到现在我还记得。",
            "set_flags": ["liu_chuan_described_culprit"],
            "options": [{"text": "（先记下）", "goto": "greet"}]
        },
        "confront_traces": {
            "text": "（叹气）……既然大人都看到了，我便不瞒。那条新打的绳扣是我事后补的——我怕浔阳楼的人来问，把原来的扣子改了。\n\n那白衣公子走后第二日午时还回来过一趟。我躲在船舱里没敢露面，只听见他在水阁来回踱了一会儿，像是在确认包袱有没有浮起来。",
            "set_flags": ["liu_chuan_revealed_revisit"],
            "options": [{"text": "（先记下）", "goto": "greet"}]
        }
    }
}

# === 周老夫人 ===
lady_zhou = {
    "_comment": "望族遗孀。秋菱欠她银两；她对赎身银动向有所了解；她在 D1 P3 去布庄查账。",
    "start": "greet",
    "nodes": {
        "greet": {
            "text": "（周老夫人手拄藤杖，眼神锐利）御史大人来问什么——是为秋菱那孩子吧。",
            "options": [
                {"text": "听说秋菱欠您银两？", "goto": "about_debt", "hide_after_visit": True},
                {"text": "您可知她赎身银的来路？", "goto": "about_redemption", "hide_after_visit": True},
                {"text": "（出示红绸购单）有人案发后又去买了一匹同样的红绸。", "goto": "react_to_silk", "requires": {"evidence": "evidence_silk_purchase_receipt"}, "cost_time": 1, "hide_after_visit": True},
                {"text": "（先告辞）", "goto": "__exit__"}
            ]
        },
        "about_debt": {
            "text": "（拄杖）她欠我五十两白银。但我那五十两是借给她当赎身银凑数用的——不是为难她。\n\n她明日就要走了。我去布庄看过账册——浔阳楼采办那匹红绸是她自己掏的银钱，不是楼里的。她是一心想走，不是醉了发疯。",
            "set_flags": ["lady_zhou_revealed_debt_purpose"],
            "options": [{"text": "（先记下）", "goto": "greet"}]
        },
        "about_redemption": {
            "text": "（叹）那三百两是远地一位客人三日前送来的，托青姐转给她。秋菱不肯叫别人知道——她说她只想离开浔阳楼，不想嫁人。\n\n（沉默）她这样的姑娘，旁人想拥有她，胜过想她安生。",
            "set_flags": ["lady_zhou_revealed_redemption"],
            "options": [{"text": "（先记下）", "goto": "greet"}]
        },
        "react_to_silk": {
            "text": "（神色一变）案发后还去补一匹？……那便不是失足。是有人怕这条红绸被人查到来路。\n\n大人——若您要查买主，去问卜掌柜，他柜上的账册是有名字的。",
            "set_flags": ["lady_zhou_pointed_to_shopkeeper"],
            "options": [{"text": "（先记下）", "goto": "greet"}]
        }
    }
}

# === 孙娘 ===
sun_laoliu = {
    "_comment": "茶坊娘子。整日守在浔阳楼前院，能证明谁何时进出。是 qing_xuan 不在场的关键证人。",
    "start": "greet",
    "nodes": {
        "greet": {
            "text": "（孙娘擦着茶碗）大人请坐。后院出了事，我这茶也卖不动了。",
            "options": [
                {"text": "案发当日午时你看到谁出过楼？", "goto": "about_d1_noon", "hide_after_visit": True},
                {"text": "案发当日黄昏呢？", "goto": "about_d1_dusk", "hide_after_visit": True},
                {"text": "（出示红绸购单）案发当日午时有人去买过红绸。", "goto": "confirm_silk_trip", "requires": {"evidence": "evidence_silk_purchase_receipt"}, "cost_time": 1, "hide_after_visit": True},
                {"text": "（先告辞）", "goto": "__exit__"}
            ]
        },
        "about_d1_noon": {
            "text": "（想了想）午时……白衣那位公子出过楼。一刻钟前还在正厅喝茶，一刻钟后我转头他人就没了。回来的时候手里多了一个布庄的包袱。\n\n我没多想——这边客商常去布庄买点小料子，他买什么是他的事。",
            "set_flags": ["sun_laoliu_confirmed_d1_noon_qing_xuan_left"],
            "options": [{"text": "（先记下）", "goto": "greet"}]
        },
        "about_d1_dusk": {
            "text": "（皱眉）黄昏雨大。我关了茶摊回屋。后门口我看见那位白衣公子披了一件深色斗篷出去——往后江畔的方向。\n\n（叹）我当时只想他是去看江景。出了事后想起来——那个方向是江畔水阁。",
            "set_flags": ["sun_laoliu_saw_white_to_dock"],
            "options": [{"text": "（先记下）", "goto": "greet"}]
        },
        "confirm_silk_trip": {
            "text": "（看一眼单据）对，就是这家——卜掌柜的字我认得。\n\n这就坐实了——他午时出楼那一刻钟，正是去买了这匹红绸。他不是「醉卧偏房」。",
            "set_flags": ["qing_xuan_alibi_broken_by_witness"],
            "options": [{"text": "（先记下）", "goto": "greet"}]
        }
    }
}

(dlg_dir / "bu_zhang.json").write_text(json.dumps(bu_zhang, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(dlg_dir / "liu_chuan.json").write_text(json.dumps(liu_chuan, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(dlg_dir / "lady_zhou.json").write_text(json.dumps(lady_zhou, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(dlg_dir / "sun_laoliu.json").write_text(json.dumps(sun_laoliu, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("写出 4 个对话树：bu_zhang / liu_chuan / lady_zhou / sun_laoliu")
