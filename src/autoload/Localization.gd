extends Node

# UIテキストのキーマップ
const TEXT_DATA = {
	"MODE_SELECTION_TITLE": "対戦モード",
	"MODE_NATIONAL_TITLE": "📝 模試",
	"MODE_NATIONAL_DESC": "全国のライバルのゴーストと非同期対戦。ダウトはAI判定。(偏差値変動なし)",
	"MODE_FRIEND_TITLE": "🤝 フレンド戦",
	"MODE_FRIEND_DESC": "ルームコードを共有して友達と非同期対戦。ダウトは相手が選ぶ！",
	"MODE_RANDOM_TITLE": "🎲 ランダムマッチ",
	"MODE_RANDOM_DESC": "自動マッチングで見知らぬライバルと同期型対戦。ダウトは対戦相手が選ぶ！偏差値が変動！",
	
	"CANCEL_BUTTON": "戻る ✖",
	"MATCHING_STATUS": "マッチング中...",
}

## 指定されたキーに対応するテキストを取得する。キーが存在しない場合はキー自体を返す。
func get_text(key: String) -> String:
	return TEXT_DATA.get(key, key)
