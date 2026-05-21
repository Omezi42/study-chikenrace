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
	NORMAL,        # 0: 通常カード
	ERASER,        # 1: 消しゴム（場のカード1枚を無効化）
	ENERGY_DRINK,  # 2: エナジードリンク（バーストシールド付与）
	WORD_BOOK,     # 3: 単語帳（山札上3枚見て戻す等）
	RED_SHEET,     # 4: 赤シート（次カード得点2倍）
	THICK_BOOK,    # 5: 分厚い参考書（強制2枚ドロー）
	STICKY_NOTE,   # 6: 付箋（ストップ時にボーナス+30）
	CHEAT_SHEET    # 7: ズルいカンペ（嘘上限さらに+50追加）
}
