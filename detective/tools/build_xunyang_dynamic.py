"""一次性落地：注册 2 个新场景、扩 locations 到 8、加 2 个 NPC、写 schedules + culprit_actions。"""
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent

# === P1.A 注册新场景到 scenes/registry.json ===
reg_path = root / 'data/scenes/registry.json'
reg = json.loads(reg_path.read_text(encoding='utf-8'))
reg['scenes']['scene_xunyang_dock'] = {
    'name': '浔阳楼·江畔水阁',
    'background': 'res://assets/cn/scenes/xunyang_riverside_dock.png',
    'tags': ['outdoor', 'water', 'secret', 'dusk', 'transit'],
    'mood': 'tense',
    'description': '浔阳楼后江畔的小码头与水阁，泊船、灯笼、雾江。可作为销证地、夜间目击点。'
}
reg['scenes']['scene_xunyang_silk_shop'] = {
    'name': '城南布庄',
    'background': 'res://assets/cn/scenes/xunyang_silk_shop.png',
    'tags': ['indoor', 'trade', 'evidence', 'daytime'],
    'mood': 'neutral',
    'description': '城南布庄内堂：成卷绸缎、铜秤算盘、绣样、内帐帘。'
}
reg_path.write_text(json.dumps(reg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('scenes registry +2 → total', len(reg['scenes']))

# === 扩展 locations.json ===
loc_path = root / 'data/cases/xunyang_pavilion/locations.json'
loc = json.loads(loc_path.read_text(encoding='utf-8'))
loc['riverside_dock'] = {
    'name': '江畔水阁',
    'description': '浔阳楼后的江畔水阁。泊船摇晃，雾深。案发夜可能有人在此销毁证物。',
    'scene_type': 'scene_xunyang_dock',
    'npcs': ['liu_chuan'],
    'search_points': [
        {'id': 'mooring_post', 'name': '石桩缆绳', 'time_cost': 1},
        {'id': 'wet_planks', 'name': '湿木板', 'time_cost': 1},
        {'id': 'ferry_boat', 'name': '渡船舱底', 'time_cost': 2}
    ]
}
loc['silk_shop'] = {
    'name': '城南布庄',
    'description': '城南老字号布庄。绛红云纹绸的卖出之处，柜上账册有名。',
    'scene_type': 'scene_xunyang_silk_shop',
    'npcs': ['bu_zhang'],
    'search_points': [
        {'id': 'silk_shelf', 'name': '红绸架', 'time_cost': 1},
        {'id': 'sales_ledger', 'name': '账册', 'time_cost': 2},
        {'id': 'back_curtain', 'name': '内帐帘后', 'time_cost': 1}
    ]
}
loc_path.write_text(json.dumps(loc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('xunyang locations:', [k for k in loc.keys() if not k.startswith('_')])

# === 新增 2 NPC ===
casting_path = root / 'data/cases/xunyang_pavilion/casting.json'
casting_doc = json.loads(casting_path.read_text(encoding='utf-8'))
c = casting_doc['casting']
c['bu_zhang'] = {
    'actor_id': 'actor_wealthy_merchant',
    'role_name': '卜掌柜',
    'role_title': '城南布庄东家',
    'role_intro': '四十来岁的布庄东家。绛红云纹绸自他柜上而出，账册记的客户名让人意外。'
}
c['liu_chuan'] = {
    'actor_id': 'actor_foreign_traveler',
    'role_name': '刘船家',
    'role_title': '江上船家',
    'role_intro': '三十来岁的渡船船家。案发夜恰好在江畔过夜，似乎看到了什么但欲言又止。'
}
casting_path.write_text(json.dumps(casting_doc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

npc_path = root / 'data/cases/xunyang_pavilion/npcs.json'
npcs = json.loads(npc_path.read_text(encoding='utf-8'))
npcs['bu_zhang'] = {
    'name': '卜掌柜',
    'title': '城南布庄东家',
    'dialogue': 'bu_zhang',
    'portrait': 'res://assets/cn/portraits/actor_wealthy_merchant.png'
}
npcs['liu_chuan'] = {
    'name': '刘船家',
    'title': '江上船家',
    'dialogue': 'liu_chuan',
    'portrait': 'res://assets/cn/portraits/actor_foreign_traveler.png'
}
npc_path.write_text(json.dumps(npcs, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('casting + npcs +2 → 9 NPC + 玩家')

# === schedules.json ===
schedules = {
    '_comment': 'NPC 时段日程表。每条 NPC 有 default 和 overrides。运行时 GameManager.get_npc_at(npc_id, day, period) 返回该时段实际所在地。public=false 是隐秘行动。',
    'qing_jie': {
        '_role': '死者义姐 当家娘子',
        'default': {'location': 'pavilion_main', 'activity': 'mourning', 'public': True},
        'overrides': {
            'D1_P0': {'location': 'pavilion_courtyard', 'activity': 'incense_offering', 'public': True},
            'D2_P4': {'location': 'yamen', 'activity': 'plead_case', 'public': True}
        }
    },
    'sun_laoliu': {
        '_role': '茶坊娘子',
        'default': {'location': 'pavilion_courtyard', 'activity': 'tea_stall', 'public': True},
        'overrides': {
            'D2_P0': {'location': 'marketplace', 'activity': 'fetch_tea_leaves', 'public': True}
        }
    },
    'lady_zhou': {
        '_role': '望族老遗孀',
        'default': {'location': 'marketplace', 'activity': 'shopping', 'public': True},
        'overrides': {
            'D1_P3': {'location': 'silk_shop', 'activity': 'check_ledger', 'public': True},
            'D2_P5': {'location': 'pavilion_main', 'activity': 'demand_debt', 'public': True}
        }
    },
    'wuchen': {
        '_role': '庵主师太',
        'default': {'location': 'convent', 'activity': 'sutra', 'public': True}
    },
    'ma_san': {
        '_role': '本府捕头',
        'default': {'location': 'yamen', 'activity': 'on_duty', 'public': True},
        'overrides': {
            'D1_P5': {'location': 'pavilion_courtyard', 'activity': 'recheck_scene', 'public': True},
            'D3_P0': {'location': 'riverside_dock', 'activity': 'patrol_dock', 'public': True}
        }
    },
    'magistrate_lu': {
        '_role': '本府知府',
        'default': {'location': 'yamen', 'activity': 'review_case', 'public': True}
    },
    'bu_zhang': {
        '_role': '布庄掌柜',
        'default': {'location': 'silk_shop', 'activity': 'mind_shop', 'public': True},
        'overrides': {
            'D1_P6': {'location': 'pavilion_main', 'activity': 'collect_debt', 'public': True},
            'D2_P2': {'location': 'marketplace', 'activity': 'wholesale_run', 'public': True}
        }
    },
    'liu_chuan': {
        '_role': '江上船家',
        'default': {'location': 'riverside_dock', 'activity': 'idle_boat', 'public': True},
        'overrides': {
            'D1_P7': {'location': 'marketplace', 'activity': 'drink_alone', 'public': True},
            'D2_P4': {'location': 'convent', 'activity': 'consult_nun', 'public': True}
        }
    },
    'qing_xuan': {
        '_role': '真凶 白衣公子（戏子伪装）',
        'default': {'location': 'pavilion_main', 'activity': 'calm_pose', 'public': True},
        'overrides': {
            'D1_P2': {'location': 'silk_shop', 'activity': 'buy_silk_replica', 'public': True},
            'D1_P6': {'location': 'riverside_dock', 'activity': 'dispose_evidence', 'public': False},
            'D2_P3': {'location': 'qiu_chamber', 'activity': 'search_letter', 'public': False},
            'D2_P6': {'location': 'convent', 'activity': 'test_nun', 'public': False},
            'D3_P1': {'location': 'pavilion_main', 'activity': 'pretend_calm', 'public': True}
        }
    }
}
(root / 'data/cases/xunyang_pavilion/schedules.json').write_text(
    json.dumps(schedules, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('schedules.json written')

# === culprit_actions.json ===
culprit = {
    '_comment': '凶手 qing_xuan 的罪后清理动作。每项 jitter=N 表示运行时执行时间 = day_period + rand(-N..+N) 时段。痕迹证据在 discoverable_after 之后可被搜索发现。',
    'actions': [
        {
            'id': 'ca_silk_buy_new',
            'culprit': 'qing_xuan',
            'day_period': 'D1_P2',
            'jitter': 1,
            'intent': '买新绛红云纹绸顶替案发那条，破坏证物链',
            'leaves_trace': {
                'evidence_id': 'evidence_silk_purchase_receipt',
                'location': 'silk_shop',
                'discoverable_after': 'D1_P3'
            },
            'if_witnessed': 'qing_xuan_alibi_market_broken'
        },
        {
            'id': 'ca_dispose_at_dock',
            'culprit': 'qing_xuan',
            'day_period': 'D1_P6',
            'jitter': 1,
            'intent': '把死者贴身私物丢入江中销证',
            'leaves_trace': {
                'evidence_id': 'evidence_dock_disturbed',
                'location': 'riverside_dock',
                'discoverable_after': 'D1_P7'
            },
            'if_witnessed': 'qing_xuan_seen_at_dock'
        },
        {
            'id': 'ca_revisit_chamber',
            'culprit': 'qing_xuan',
            'day_period': 'D2_P3',
            'jitter': 1,
            'intent': '回闺阁找写有他名字的小笺',
            'leaves_trace': {
                'evidence_id': 'evidence_chamber_redisturbed',
                'location': 'qiu_chamber',
                'discoverable_after': 'D2_P4'
            },
            'if_witnessed': 'qing_xuan_caught_at_chamber'
        },
        {
            'id': 'ca_test_nun',
            'culprit': 'qing_xuan',
            'day_period': 'D2_P6',
            'jitter': 1,
            'intent': '去对面慈航庵打探无尘是否目击案发夜',
            'leaves_trace': {
                'evidence_id': 'evidence_nun_visited_by_white',
                'location': 'convent',
                'discoverable_after': 'D2_P7'
            },
            'if_witnessed': 'qing_xuan_seen_at_convent'
        }
    ]
}
(root / 'data/cases/xunyang_pavilion/culprit_actions.json').write_text(
    json.dumps(culprit, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('culprit_actions.json written:', len(culprit['actions']), 'actions')

# === 给新证据加到 evidence.json（占位即可） ===
ev_path = root / 'data/cases/xunyang_pavilion/evidence.json'
ev = json.loads(ev_path.read_text(encoding='utf-8'))
new_evs = {
    'evidence_silk_purchase_receipt': {
        'name': '新购红绸单据',
        'description': '布庄账册上一条临时手写的销售记录。买方笔迹与顾清玄案上字迹一致——他在案发前买过一匹同样的红绸。',
        'category': '物证'
    },
    'evidence_dock_disturbed': {
        'name': '江畔水阁的乱痕',
        'description': '湿木板上一道新鲜的鞋印拖痕，缆绳被打了一个奇怪的扣。有人凌晨独自来此并把东西丢进了江里。',
        'category': '物证'
    },
    'evidence_chamber_redisturbed': {
        'name': '闺阁被翻动的痕迹',
        'description': '案发后封锁的闺阁，妆台抽屉被重新拉开过，几张纸笺凌乱。有人在你之前回来找过东西。',
        'category': '物证'
    },
    'evidence_nun_visited_by_white': {
        'name': '无尘师太的异常',
        'description': '无尘师太提到——夜里有个白衣公子曾敲门，问案发那夜她是否听到过什么动静。',
        'category': '证词'
    }
}
for k, v in new_evs.items():
    ev[k] = v
ev_path.write_text(json.dumps(ev, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('evidence +4 →', len([k for k in ev.keys() if not k.startswith('_')]))

# === search_results.json：让搜索点能"挖到"新证据（需在 discoverable_after 后）===
sr_path = root / 'data/cases/xunyang_pavilion/search_results.json'
sr = json.loads(sr_path.read_text(encoding='utf-8'))
sr.update({
    'silk_shop.sales_ledger': {
        'default': {
            'narration': '账册上一笔三日前的临时手写记录：「绛红云纹绸一匹，急用，三两八。」字迹歪斜，买方栏写着一个孤字——「玄」。',
            'reward': {'evidence': 'evidence_silk_purchase_receipt'},
            'time_cost': 2
        }
    },
    'riverside_dock.wet_planks': {
        'default': {
            'narration': '湿木板上一道新鲜的鞋印拖痕，方向朝着江面。缆绳上多了一个生手打的扣。',
            'reward': {'evidence': 'evidence_dock_disturbed'},
            'time_cost': 1
        }
    },
    'qiu_chamber.letter_box': {
        'default': {
            'narration': '案发后本已封锁的桌案抽屉被人拉开过——你昨日见到的那张未送出的小笺，今天不见了。',
            'reward': {'evidence': 'evidence_chamber_redisturbed'},
            'time_cost': 2
        }
    }
})
sr_path.write_text(json.dumps(sr, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('search_results updated')

# === 占位对话树：bu_zhang.json / liu_chuan.json ===
dlg_dir = root / 'data/cases/xunyang_pavilion/dialogues'
(dlg_dir / 'bu_zhang.json').write_text(json.dumps({
    'start': 'greet',
    'nodes': {
        'greet': {
            'text': '（卜掌柜抬眼）大人光临布庄，可是看货？',
            'options': [
                {'text': '问：近来可有人买过绛红云纹绸？', 'next': 'about_silk'},
                {'text': '（先告辞）', 'effect': '__exit__'}
            ]
        },
        'about_silk': {
            'text': '（顿）这……三日前确有一笔，是位白衣公子急要的，连名都没留全，只签了个「玄」字。',
            'options': [
                {'text': '请出示账册', 'next': 'show_ledger', 'requires': {'evidence_obtained': 'evidence_silk_purchase_receipt'}},
                {'text': '（先记下）', 'effect': '__exit__'}
            ]
        },
        'show_ledger': {
            'text': '（取出账册）大人您看，这笔记得急，字也歪。买的还是一整匹——三尺八，少见。',
            'set_flags': ['silk_buyer_is_white_robed'],
            'options': [{'text': '（先告辞）', 'effect': '__exit__'}]
        }
    }
}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

(dlg_dir / 'liu_chuan.json').write_text(json.dumps({
    'start': 'greet',
    'nodes': {
        'greet': {
            'text': '（刘船家眼神躲闪）大人……要渡江么？',
            'options': [
                {'text': '问：案发那夜你在水阁吗？', 'next': 'about_night'},
                {'text': '（先告辞）', 'effect': '__exit__'}
            ]
        },
        'about_night': {
            'text': '（搓手）……三更头我打盹被惊醒，看见一个白影从水阁那头走出来，往江边丢了个包袱。我没敢出声。',
            'set_flags': ['liu_chuan_witnessed_disposal'],
            'options': [
                {'text': '是男是女？', 'next': 'gender'},
                {'text': '（先告辞）', 'effect': '__exit__'}
            ]
        },
        'gender': {
            'text': '（低声）男的。白衣。瘦。脚步轻——像是会做工夫的。',
            'options': [{'text': '（先告辞）', 'effect': '__exit__'}]
        }
    }
}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('占位对话树 bu_zhang.json / liu_chuan.json 已生成')

# === manifest 升级 ===
man_path = root / 'data/cases/xunyang_pavilion/manifest.json'
man = json.loads(man_path.read_text(encoding='utf-8'))
man['estimated_days'] = 3
man['art_todo']['_comment'] = '动态扩展完成：8 地点 / 9 嫌疑人 / schedule + culprit_actions / 新增 2 场景图。剩余 P1 旧背景仍可后续替换。'
man['art_todo']['new_actors'] = []
man_path.write_text(json.dumps(man, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('manifest updated')
