class_name CardData
extends RefCounted

# Roles (系統)
const ROLE_DEFENSE = "defense"  # 守り
const ROLE_PUSH = "push"        # 押し
const ROLE_BLUFF = "bluff"      # ブラフ
const ROLE_PREP = "prep"        # 仕込み

const ITEMS = {
	# --- 初期解放アイテム (10種類) ---
	"item_sticky_note": {
		"id": "item_sticky_note",
		"name": "付箋",
		"description": "次に引く1枚の勉強時間（カードの点数）を＋3点する。",
		"role": ROLE_PREP,
		"is_initial": true,
		"is_gacha": false
	},
	"item_eraser": {
		"id": "item_eraser",
		"name": "消しゴム",
		"description": "次の一枚のみ寝落ち（バースト）を無効化し、重複したカードを山札に戻してドローを継続する。",
		"role": ROLE_DEFENSE,
		"is_initial": true,
		"is_gacha": false
	},
	"item_ruler": {
		"id": "item_ruler",
		"name": "定規",
		"description": "山札の次の一枚をのぞき見する。",
		"role": ROLE_PREP,
		"is_initial": true,
		"is_gacha": false
	},
	"item_wordbook": {
		"id": "item_wordbook",
		"name": "単語帳",
		"description": "山札の次の三枚をのぞき見する。",
		"role": ROLE_PREP,
		"is_initial": true,
		"is_gacha": false
	},
	"item_mech_pencil": {
		"id": "item_mech_pencil",
		"name": "シャーペン",
		"description": "この時限で次に引く2枚のカードの点数を＋3点する。",
		"role": ROLE_PUSH,
		"is_initial": true,
		"is_gacha": false
	},
	"item_memo_cards": {
		"id": "item_memo_cards",
		"name": "暗記カード",
		"description": "手札のカード1枚を山札のトップのカードと入れ替える。",
		"role": ROLE_PREP,
		"is_initial": true,
		"is_gacha": false
	},
	"item_highlighter": {
		"id": "item_highlighter",
		"name": "蛍光ペン",
		"description": "この時限で引いたすべての勉強時間（カードの点数）を＋1点する。",
		"role": ROLE_PUSH,
		"is_initial": true,
		"is_gacha": false
	},
	"item_blue_pen": {
		"id": "item_blue_pen",
		"name": "青ペン",
		"description": "この時限で引いたすべての勉強時間（カードの点数）を＋2点する。",
		"role": ROLE_PREP,
		"is_initial": true,
		"is_gacha": false
	},
	"item_cushion": {
		"id": "item_cushion",
		"name": "座布団",
		"description": "ダウトに失敗した時のペナルティ失点を半分に軽減する。",
		"role": ROLE_DEFENSE,
		"is_initial": true,
		"is_gacha": false
	},
	"item_memo_app": {
		"id": "item_memo_app",
		"name": "メモアプリ",
		"description": "カードを2枚引いて、手札から1枚を捨てる。",
		"role": ROLE_PREP,
		"is_initial": true,
		"is_gacha": false
	},

	# --- ガチャ解放アイテム (14種類) ---
	"item_cheat_sheet": {
		"id": "item_cheat_sheet",
		"name": "ズルいカンペ",
		"description": "その日のブラフ上限（盛れる点数）を＋16点拡張する。",
		"role": ROLE_BLUFF,
		"is_initial": false,
		"is_gacha": true
	},
	"item_compass": {
		"id": "item_compass",
		"name": "コンパス",
		"description": "山札の中にある、現在の手札と同じ数字 of カードの位置をすべて可視化する。",
		"role": ROLE_PREP,
		"is_initial": false,
		"is_gacha": true
	},
	"item_energy_drink": {
		"id": "item_energy_drink",
		"name": "エナジードリンク",
		"description": "この時限の獲得点数を2倍にするが、ドロー時に25%の確率で強制寝落ち（バースト）する副作用を持つ。",
		"role": ROLE_PUSH,
		"is_initial": false,
		"is_gacha": true
	},
	"item_red_sheet": {
		"id": "item_red_sheet",
		"name": "赤シート",
		"description": "次の一枚に限り、バーストするカードであってもそのまま手札に加える（バースト無効）。",
		"role": ROLE_PUSH,
		"is_initial": false,
		"is_gacha": true
	},
	"item_thick_book": {
		"id": "item_thick_book",
		"name": "分厚い参考書",
		"description": "山札に高得点（+15点）カードを3枚追加する（この時限のみ）。",
		"role": ROLE_PUSH,
		"is_initial": false,
		"is_gacha": true
	},
	"item_amulet": {
		"id": "item_amulet",
		"name": "お守り",
		"description": "寝落ち（バースト）した際、その時限で稼いでいた点数の50%を維持する。",
		"role": ROLE_DEFENSE,
		"is_initial": false,
		"is_gacha": true
	},
	"item_night_note": {
		"id": "item_night_note",
		"name": "追込みノート",
		"description": "本日4回目の時限（延長時間）を追加でプレイできる。ただし、山札に重複カードが1枚増える。",
		"role": ROLE_PUSH,
		"is_initial": false,
		"is_gacha": true
	},
	"item_copy_answer": {
		"id": "item_copy_answer",
		"name": "解答写し",
		"description": "ブラフ上限を＋25点拡張するが、嘘（ブラフ）が見破られた際の失点ペナルティが2倍になる。",
		"role": ROLE_BLUFF,
		"is_initial": false,
		"is_gacha": true
	},
	"item_timer": {
		"id": "item_timer",
		"name": "タイマー",
		"description": "現在のドローにおけるバースト（被り）の正確な確率（%）を表示する。",
		"role": ROLE_PREP,
		"is_initial": false,
		"is_gacha": true
	},
	"item_study_chat": {
		"id": "item_study_chat",
		"name": "勉強会チャット",
		"description": "他人の嘘を見破る（ダウト成功）時の獲得点数を＋6点強化する。",
		"role": ROLE_PREP,
		"is_initial": false,
		"is_gacha": true
	},
	"item_expected_questions": {
		"id": "item_expected_questions",
		"name": "予想問題集",
		"description": "次に引く3枚の勉強時間（カードの点数）を＋3点する。",
		"role": ROLE_PREP,
		"is_initial": false,
		"is_gacha": true
	},
	"item_cafe_latte": {
		"id": "item_cafe_latte",
		"name": "カフェラテ",
		"description": "ターンを終了せずに、山札から安全に1枚追加ドローする。",
		"role": ROLE_PREP,
		"is_initial": false,
		"is_gacha": true
	},
	"item_earplugs": {
		"id": "item_earplugs",
		"name": "耳栓",
		"description": "ダウト失敗時のペナルティ失点を10点軽減する。",
		"role": ROLE_DEFENSE,
		"is_initial": false,
		"is_gacha": true
	},
	"item_cram_school_print": {
		"id": "item_cram_school_print",
		"name": "塾プリント",
		"description": "この時限の獲得合計得点を＋10点する。",
		"role": ROLE_PREP,
		"is_initial": false,
		"is_gacha": true
	},

	# --- システム専用トークン (ガチャに入らない) ---
	"item_forget_notebook": {
		"id": "item_forget_notebook",
		"name": "忘却のノート",
		"description": "手札の最小値カードを1枚、捨て札に送る（この時限のみバースト対象から除外）。",
		"role": ROLE_DEFENSE,
		"is_initial": false,
		"is_gacha": false
	}
}

static func get_role_name(role: String) -> String:
	match role:
		ROLE_DEFENSE: return "守り"
		ROLE_PUSH: return "押し"
		ROLE_BLUFF: return "ブラフ"
		ROLE_PREP: return "仕込み"
	return "その他"

static func get_role_color(role: String) -> Color:
	match role:
		ROLE_DEFENSE: return DeskTheme.COLOR_ROLE_DEFENSE
		ROLE_PUSH: return DeskTheme.COLOR_ROLE_PUSH
		ROLE_BLUFF: return DeskTheme.COLOR_ROLE_BLUFF
		ROLE_PREP: return DeskTheme.COLOR_ROLE_PREP
	return DeskTheme.COLOR_INK

static func get_item_image_path(item_id: String) -> String:
	if item_id == "":
		return ""
	var filename = item_id
	if item_id == "item_mech_pencil":
		filename = "item_mech_pen"
	elif item_id == "item_wordbook":
		filename = "item_memo_cards"
		
	var path_item = "res://assets/item/" + filename + ".png"
	if ResourceLoader.exists(path_item):
		return path_item
		
	var path_root = "res://assets/" + filename + ".png"
	if ResourceLoader.exists(path_root):
		return path_root
		
	return ""

static func get_item_short_effect(item_id: String) -> String:
	match item_id:
		"item_sticky_note": return "次引く1枚の得点+3点"
		"item_eraser": return "眠気被りを1回無効化"
		"item_ruler": return "山札の次の1枚を覗き見"
		"item_wordbook": return "山札の次の3枚を覗き見"
		"item_mech_pencil": return "次の2ドロー得点+3点"
		"item_memo_cards": return "手札と山札トップ交換"
		"item_highlighter": return "この時限ドローの得点+1点"
		"item_blue_pen": return "この時限ドローの得点+2点"
		"item_cushion": return "ダウト失敗ペナルティ半減"
		"item_memo_app": return "2枚引いて1枚捨てる"
		"item_cheat_sheet": return "本日のブラフ上限+16点"
		"item_compass": return "山札の被り札枚数表示"
		"item_energy_drink": return "得点2倍(25%眠気バースト)"
		"item_red_sheet": return "次の被り札をバースト無効"
		"item_thick_book": return "山札に+15点札を3枚追加"
		"item_amulet": return "バースト時得点の50%維持"
		"item_night_note": return "本日4時限目をプレイ可能"
		"item_copy_answer": return "ブラフ+25点(嘘バレペナ2倍)"
		"item_timer": return "安全確率を正確に表示"
		"item_study_chat": return "ダウト成功時の得点+6点"
		"item_expected_questions": return "次引く3枚の得点+3点"
		"item_cafe_latte": return "安全に1枚追加ドロー"
		"item_earplugs": return "ダウト失敗ペナルティ-10"
		"item_cram_school_print": return "この時限の最終得点+10点"
		"item_forget_notebook": return "手札最小値カードを捨てる"
	return ""

static func get_reaction_text(prob: float) -> String:
	if prob <= 0.15:
		return "落ち着いている"
	elif prob <= 0.40:
		return "少し緊張している..."
	elif prob <= 0.70:
		return "冷や汗をかいている..."
	else:
		return "手が震えている！"

