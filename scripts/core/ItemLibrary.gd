class_name ItemLibrary
extends RefCounted

const TACTIC_SAFE := "safe"
const TACTIC_PUSH := "push"
const TACTIC_BLUFF := "bluff"
const TACTIC_SETUP := "setup"

const ITEM_DEFS := {
	Enums.ItemType.STICKY_NOTE: {
		"name": "付箋",
		"short": "付",
		"desc": "ストップ時に安定ボーナス。小さく確実に逃げ切りやすくなる。",
		"color": Color("ffd43b"),
		"subject": Enums.Subject.JAPANESE,
		"tactics": [TACTIC_SAFE]
	},
	Enums.ItemType.ERASER: {
		"name": "消しゴム",
		"short": "消",
		"desc": "直前のアクティブなカードを1枚だけ無効化する。",
		"color": Color("adb5bd"),
		"subject": Enums.Subject.NONE,
		"tactics": [TACTIC_SAFE, TACTIC_SETUP]
	},
	Enums.ItemType.RULER: {
		"name": "定規",
		"short": "定",
		"desc": "ストップ時にボーナス。止め判断を後押しする。",
		"color": Color("4dabf7"),
		"subject": Enums.Subject.MATH,
		"tactics": [TACTIC_SAFE]
	},
	Enums.ItemType.WORD_BOOK: {
		"name": "単語帳",
		"short": "単",
		"desc": "山札上3枚を確認し、危険札を下へ逃がす。",
		"color": Color("3bc9db"),
		"subject": Enums.Subject.ENGLISH,
		"tactics": [TACTIC_SAFE, TACTIC_SETUP]
	},
	Enums.ItemType.CHEAT_SHEET: {
		"name": "ズルいカンペ",
		"short": "ズ",
		"desc": "虚偽申告の上限を広げ、少しだけ露見しにくくする。",
		"color": Color("94d82d"),
		"subject": Enums.Subject.SOCIAL_STUDIES,
		"tactics": [TACTIC_BLUFF]
	},
	Enums.ItemType.COMPASS: {
		"name": "コンパス",
		"short": "コ",
		"desc": "引いた瞬間に追加点。中盤の押し込み向け。",
		"color": Color("748ffc"),
		"subject": Enums.Subject.MATH,
		"tactics": [TACTIC_PUSH]
	},
	Enums.ItemType.ENERGY_DRINK: {
		"name": "エナジードリンク",
		"short": "エ",
		"desc": "次のバーストを1回だけ無効化する。",
		"color": Color("fcc419"),
		"subject": Enums.Subject.NONE,
		"tactics": [TACTIC_SAFE, TACTIC_PUSH]
	},
	Enums.ItemType.RED_SHEET: {
		"name": "赤シート",
		"short": "赤",
		"desc": "次に引く有効カードの得点倍率を上げる。",
		"color": Color("ff6b6b"),
		"subject": Enums.Subject.ENGLISH,
		"tactics": [TACTIC_PUSH, TACTIC_SETUP]
	},
	Enums.ItemType.MECHANICAL_PENCIL: {
		"name": "シャーペン",
		"short": "シ",
		"desc": "引いた瞬間に小さな追加点。序盤の底上げ用。",
		"color": Color("868e96"),
		"subject": Enums.Subject.JAPANESE,
		"tactics": [TACTIC_PUSH]
	},
	Enums.ItemType.THICK_BOOK: {
		"name": "分厚い参考書",
		"short": "参",
		"desc": "山札上2枚を見て1枚を引き、もう1枚を山下へ送る。",
		"color": Color("845ef7"),
		"subject": Enums.Subject.SCIENCE,
		"tactics": [TACTIC_PUSH, TACTIC_SETUP]
	},
	Enums.ItemType.FLASH_CARD: {
		"name": "暗記カード",
		"short": "暗",
		"desc": "同教科の連続ボーナスを少し強くする。",
		"color": Color("ff922b"),
		"subject": Enums.Subject.ENGLISH,
		"tactics": [TACTIC_SETUP]
	},
	Enums.ItemType.LUCKY_CHARM: {
		"name": "お守り",
		"short": "守",
		"desc": "その時限だけ最初のバースト率警告を和らげる守り札。",
		"color": Color("74c0fc"),
		"subject": Enums.Subject.NONE,
		"tactics": [TACTIC_SAFE]
	},
	Enums.ItemType.ALL_NIGHTER: {
		"name": "徹夜ノート",
		"short": "徹",
		"desc": "引いた瞬間の加点は大きいが、その時限の露見リスクが上がる。",
		"color": Color("b197fc"),
		"subject": Enums.Subject.SCIENCE,
		"tactics": [TACTIC_PUSH, TACTIC_BLUFF]
	},
	Enums.ItemType.ANSWER_KEY: {
		"name": "解答写し",
		"short": "写",
		"desc": "その時限の虚偽申告にボーナス補正を付けるが、見破られやすい。",
		"color": Color("69db7c"),
		"subject": Enums.Subject.SOCIAL_STUDIES,
		"tactics": [TACTIC_BLUFF]
	},
	Enums.ItemType.HIGHLIGHTER: {
		"name": "蛍光ペン",
		"short": "蛍",
		"desc": "場にある最小数字カードを追加点付きで強調する。",
		"color": Color("f06595"),
		"subject": Enums.Subject.JAPANESE,
		"tactics": [TACTIC_SETUP]
	},
	Enums.ItemType.TIMER: {
		"name": "タイマー",
		"short": "時",
		"desc": "ストップ時の残り危険度に応じて少額ボーナス。",
		"color": Color("4dabf7"),
		"subject": Enums.Subject.MATH,
		"tactics": [TACTIC_SAFE]
	},
	Enums.ItemType.STUDY_GROUP_CHAT: {
		"name": "勉強会チャット",
		"short": "談",
		"desc": "ダウト成功時のボーナスが少し伸びる。",
		"color": Color("20c997"),
		"subject": Enums.Subject.SOCIAL_STUDIES,
		"tactics": [TACTIC_BLUFF, TACTIC_SETUP]
	},
	Enums.ItemType.PRACTICE_TEST: {
		"name": "予想問題集",
		"short": "予",
		"desc": "山札上4枚から1枚だけ先に予約し、次ドロー候補を整える。",
		"color": Color("9775fa"),
		"subject": Enums.Subject.SCIENCE,
		"tactics": [TACTIC_SETUP]
	},
	Enums.ItemType.CAFE_LATTE: {
		"name": "カフェラテ",
		"short": "ラ",
		"desc": "次の2回だけ小さな追加点を得る。",
		"color": Color("c68642"),
		"subject": Enums.Subject.NONE,
		"tactics": [TACTIC_PUSH]
	},
	Enums.ItemType.NOISE_CANCELING: {
		"name": "耳栓",
		"short": "耳",
		"desc": "ダウト失敗時のペナルティを少し軽減する。",
		"color": Color("495057"),
		"subject": Enums.Subject.NONE,
		"tactics": [TACTIC_SAFE, TACTIC_BLUFF]
	},
	Enums.ItemType.SEAT_CUSHION: {
		"name": "座布団",
		"short": "座",
		"desc": "その時限の最初のストップ系ボーナスを強くする。",
		"color": Color("ffa8a8"),
		"subject": Enums.Subject.NONE,
		"tactics": [TACTIC_SAFE]
	},
	Enums.ItemType.BLUE_PEN: {
		"name": "青ペン",
		"short": "青",
		"desc": "直後に引く同教科カードのコンボ価値を高める。",
		"color": Color("228be6"),
		"subject": Enums.Subject.JAPANESE,
		"tactics": [TACTIC_SETUP, TACTIC_PUSH]
	},
	Enums.ItemType.CRAM_SCHOOL: {
		"name": "塾プリント",
		"short": "塾",
		"desc": "5教科達成時のボーナスを少しだけ伸ばす。",
		"color": Color("7950f2"),
		"subject": Enums.Subject.SCIENCE,
		"tactics": [TACTIC_SETUP]
	},
	Enums.ItemType.MEMO_APP: {
		"name": "メモアプリ",
		"short": "メ",
		"desc": "その日だけ相手の虚偽上振れを見抜きやすくする。",
		"color": Color("51cf66"),
		"subject": Enums.Subject.SOCIAL_STUDIES,
		"tactics": [TACTIC_BLUFF, TACTIC_SETUP]
	},
	Enums.ItemType.DELETE_CARD: {
		"name": "忘却のノート",
		"short": "忘",
		"desc": "山札か捨て札から指定カード1枚を完全に削除する。",
		"color": Color("495057"),
		"subject": Enums.Subject.NONE,
		"tactics": [TACTIC_SETUP]
	}
}

const STARTER_POOL := [
	Enums.ItemType.STICKY_NOTE,
	Enums.ItemType.ERASER,
	Enums.ItemType.RULER,
	Enums.ItemType.WORD_BOOK,
	Enums.ItemType.CHEAT_SHEET,
	Enums.ItemType.COMPASS,
	Enums.ItemType.ENERGY_DRINK,
	Enums.ItemType.RED_SHEET,
	Enums.ItemType.MECHANICAL_PENCIL,
	Enums.ItemType.THICK_BOOK,
	Enums.ItemType.FLASH_CARD,
	Enums.ItemType.TIMER,
	Enums.ItemType.CAFE_LATTE,
	Enums.ItemType.NOISE_CANCELING
]

const ADVANCED_POOL := [
	Enums.ItemType.LUCKY_CHARM,
	Enums.ItemType.ALL_NIGHTER,
	Enums.ItemType.ANSWER_KEY,
	Enums.ItemType.HIGHLIGHTER,
	Enums.ItemType.STUDY_GROUP_CHAT,
	Enums.ItemType.PRACTICE_TEST,
	Enums.ItemType.SEAT_CUSHION,
	Enums.ItemType.BLUE_PEN,
	Enums.ItemType.CRAM_SCHOOL,
	Enums.ItemType.MEMO_APP
]

static func definition(item_type: int) -> Dictionary:
	return ITEM_DEFS.get(item_type, {
		"name": "Unknown",
		"short": "?",
		"desc": "",
		"color": Color("495057"),
		"subject": Enums.Subject.NONE,
		"tactics": []
	})


static func name(item_type: int) -> String:
	return str(definition(item_type).get("name", "Unknown"))


static func short_name(item_type: int) -> String:
	return str(definition(item_type).get("short", "?"))


static func description(item_type: int) -> String:
	return str(definition(item_type).get("desc", ""))


static func color(item_type: int) -> Color:
	return definition(item_type).get("color", Color("495057"))


static func subject(item_type: int) -> int:
	return int(definition(item_type).get("subject", Enums.Subject.NONE))


static func tactics(item_type: int) -> Array:
	return definition(item_type).get("tactics", [])


static func all_item_types() -> Array:
	return ITEM_DEFS.keys()


static func default_unlocks() -> Array:
	return STARTER_POOL.duplicate()

