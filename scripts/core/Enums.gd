class_name Enums

enum Subject {
	JAPANESE,
	MATH,
	ENGLISH,
	SCIENCE,
	SOCIAL_STUDIES,
	NONE
}

enum ItemType {
	STICKY_NOTE = 1,   # 1: 付箋（ストップ時にボーナス+30）
	ERASER = 2,        # 2: 消しゴム（場のカード1枚を無効化）
	RULER = 3,         # 3: 定規（ストップ時にボーナス+10）
	WORD_BOOK = 4,     # 4: 単語帳（山札上3枚見て戻す等）
	CHEAT_SHEET = 5,   # 5: ズルいカンペ（嘘上限さらに+50追加）
	COMPASS = 6,       # 6: コンパス（引いた瞬間にスコア+15）
	ENERGY_DRINK = 7,  # 7: エナジードリンク（バーストシールド付与）
	RED_SHEET = 8,     # 8: 赤シート（次カード得点2倍）
	MECHANICAL_PENCIL = 9, # 9: シャーペン（引いた瞬間にスコア+5）
	THICK_BOOK = 10,   # 10: 分厚い参考書（強制2枚ドロー）
	DELETE_CARD = 99   # 忘却のノート（アイテム削除用特殊アイテム）
}

const ITEM_SUBJECT_MAP = {
	ItemType.STICKY_NOTE: Subject.JAPANESE,
	ItemType.ERASER: Subject.NONE,
	ItemType.RULER: Subject.MATH,
	ItemType.WORD_BOOK: Subject.ENGLISH,
	ItemType.CHEAT_SHEET: Subject.SOCIAL_STUDIES,
	ItemType.COMPASS: Subject.MATH,
	ItemType.ENERGY_DRINK: Subject.NONE,
	ItemType.RED_SHEET: Subject.ENGLISH,
	ItemType.MECHANICAL_PENCIL: Subject.JAPANESE,
	ItemType.THICK_BOOK: Subject.SCIENCE,
	ItemType.DELETE_CARD: Subject.NONE
}
