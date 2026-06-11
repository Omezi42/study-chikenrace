class_name AIProfile
extends RefCounted

const TYPE_CAUTIOUS = "cautious"
const TYPE_AGGRESSIVE = "aggressive"
const TYPE_BLUFFER = "bluffer"
const TYPE_HIGHROLLER = "highroller"

const CPU_OPPONENTS = {
	"cpu_sato": {
		"name": "佐藤くん",
		"type": TYPE_CAUTIOUS,
		"avatar": "res://assets/split/subject_math.png",
		"bio": "数学が得意な真面目男子。嘘を嫌い、石橋を叩いて渡るプレイスタイル。",
		"bluff_tendency": "誠実",
		"deck": {
			1: "item_eraser", 2: "item_ruler", 3: "item_wordbook", 4: "item_cushion",
			5: "item_memo_cards", 6: "item_memo_app", 7: "item_earplugs", 8: "item_sticky_note",
			9: "item_blue_pen", 10: "item_highlighter"
		}
	},
	"cpu_suzuki": {
		"name": "鈴木さん",
		"type": TYPE_BLUFFER,
		"avatar": "res://assets/split/subject_english.png",
		"bio": "いつもスマホをいじっているギャル。涼しい顔で大嘘をかましてくる。",
		"bluff_tendency": "変幻自在",
		"deck": {
			1: "item_cheat_sheet", 2: "item_copy_answer", 3: "item_sticky_note", 4: "item_eraser",
			5: "item_ruler", 6: "item_timer", 7: "item_study_chat", 8: "item_memo_app",
			9: "item_highlighter", 10: "item_wordbook"
		}
	},
	"cpu_takahashi": {
		"name": "高橋くん",
		"type": TYPE_HIGHROLLER,
		"avatar": "res://assets/split/subject_science.png",
		"bio": "エナドリ中毒の熱血野球部員。バースト上等で限界突破を狙う。",
		"bluff_tendency": "中〜高",
		"deck": {
			1: "item_energy_drink", 2: "item_red_sheet", 3: "item_thick_book", 4: "item_night_note",
			5: "item_mech_pencil", 6: "item_highlighter", 7: "item_eraser", 8: "item_ruler",
			9: "item_sticky_note", 10: "item_cram_school_print"
		}
	},
	"cpu_tanaka": {
		"name": "田中くん",
		"type": TYPE_AGGRESSIVE,
		"avatar": "res://assets/split/subject_science.png",
		"bio": "野球部所属の熱血漢。直感で引き続ける傾向があるが、ブラフは下手。",
		"bluff_tendency": "低〜中",
		"deck": {
			1: "item_energy_drink", 2: "item_mech_pencil", 3: "item_highlighter", 4: "item_eraser",
			5: "item_thick_book", 6: "item_night_note", 7: "item_cushion", 8: "item_ruler",
			9: "item_blue_pen", 10: "item_sticky_note"
		}
	},
	"cpu_watanabe": {
		"name": "渡辺さん",
		"type": TYPE_CAUTIOUS,
		"avatar": "res://assets/split/subject_japanese.png",
		"bio": "図書委員の真面目な女子。リスクを徹底的に避け、ほぼ正直に申告する。",
		"bluff_tendency": "極めて誠実",
		"deck": {
			1: "item_eraser", 2: "item_ruler", 3: "item_wordbook", 4: "item_cushion",
			5: "item_memo_cards", 6: "item_memo_app", 7: "item_earplugs", 8: "item_amulet",
			9: "item_timer", 10: "item_cram_school_print"
		}
	},
	"cpu_ito": {
		"name": "伊藤くん",
		"type": TYPE_BLUFFER,
		"avatar": "res://assets/split/subject_english.png",
		"bio": "お調子者のゲーマー男子。手札がボロボロでも、平気で大嘘を申告する。",
		"bluff_tendency": "大嘘つき",
		"deck": {
			1: "item_cheat_sheet", 2: "item_copy_answer", 3: "item_study_chat", 4: "item_eraser",
			5: "item_ruler", 6: "item_timer", 7: "item_memo_app", 8: "item_wordbook",
			9: "item_highlighter", 10: "item_blue_pen"
		}
	}
}

static func generate_dynamic_cpu_deck(cpu_type: String) -> Dictionary:
	var deck = {}
	var preferences = []
	match cpu_type:
		TYPE_CAUTIOUS:
			preferences = [
				"item_eraser", "item_ruler", "item_wordbook", "item_cushion",
				"item_memo_cards", "item_memo_app", "item_earplugs", "item_sticky_note",
				"item_blue_pen", "item_highlighter", "item_timer", "item_amulet"
			]
		TYPE_BLUFFER:
			preferences = [
				"item_cheat_sheet", "item_copy_answer", "item_study_chat", "item_eraser",
				"item_ruler", "item_timer", "item_memo_app", "item_wordbook",
				"item_highlighter", "item_blue_pen"
			]
		TYPE_HIGHROLLER:
			preferences = [
				"item_energy_drink", "item_red_sheet", "item_thick_book", "item_night_note",
				"item_mech_pencil", "item_highlighter", "item_eraser", "item_ruler",
				"item_sticky_note", "item_cram_school_print"
			]
		TYPE_AGGRESSIVE:
			preferences = [
				"item_energy_drink", "item_mech_pencil", "item_highlighter", "item_blue_pen",
				"item_thick_book", "item_night_note", "item_cram_school_print", "item_ruler",
				"item_sticky_note", "item_expected_questions"
			]
		_:
			preferences = [
				"item_sticky_note", "item_eraser", "item_ruler", "item_wordbook",
				"item_mech_pencil", "item_memo_cards", "item_highlighter", "item_blue_pen",
				"item_cushion", "item_memo_app"
			]

	for slot in range(1, 11):
		if slot - 1 < preferences.size():
			deck[slot] = preferences[slot - 1]
		else:
			deck[slot] = "item_sticky_note"
	return deck

static func _get_cpu_info(actual_id: String) -> Dictionary:
	if CPU_OPPONENTS.has(actual_id):
		var base = CPU_OPPONENTS[actual_id]
		var dynamic_deck = generate_dynamic_cpu_deck(base["type"])
		return {
			"name": base["name"],
			"type": base["type"],
			"avatar": base["avatar"],
			"bio": base["bio"],
			"bluff_tendency": base["bluff_tendency"],
			"deck": dynamic_deck
		}
	var types = [TYPE_CAUTIOUS, TYPE_AGGRESSIVE, TYPE_BLUFFER, TYPE_HIGHROLLER]
	var h = abs(actual_id.hash())
	var type_idx = h % types.size()
	var selected_type = types[type_idx]
	var dynamic_deck = generate_dynamic_cpu_deck(selected_type)
	var fallback_keys = CPU_OPPONENTS.keys()
	var deck_idx = h % fallback_keys.size()
	var base = CPU_OPPONENTS[fallback_keys[deck_idx]]
	return {
		"name": actual_id,
		"type": selected_type,
		"avatar": base.get("avatar", ""),
		"bio": "",
		"bluff_tendency": "不明",
		"deck": dynamic_deck
	}

static func get_cpu_info(actual_id: String) -> Dictionary:
	return _get_cpu_info(actual_id)

static func get_cpu_name(actual_id: String) -> String:
	return _get_cpu_info(actual_id).get("name", actual_id)
