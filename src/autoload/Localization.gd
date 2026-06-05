# -*- coding: utf-8 -*-
extends Node

# UTF-8 でエンコードされた日本語定数の一元管理クラス

const JP_YOU = "あなた"
const JP_RIVAL = "ライバル"
const JP_MEMBER = "メンバー"
const JP_PLAYER = "プレイヤー"
const JP_COMMUNICATION_ERROR = "通信エラー"

# CPU名
const CPU_SATO = "佐藤くん"
const CPU_SUZUKI = "鈴木さん"
const CPU_TAKAHASHI = "高橋くん"
const CPU_TANAKA = "田中くん"
const CPU_TAKEDA = "武田くん"
const CPU_WATANABE = "渡辺さん"

# UIテキスト
const MSG_SAVING = "セーブ中..."
const MSG_LOADING = "ロード中..."
const MSG_SIGNUPPING = "新規登録中..."
const MSG_LOGINNING = "ログイン中..."
const MSG_VERIFYING = "セッション復旧中..."
const MSG_ROOM_CREATING = "ルーム作成中..."
const MSG_ROOM_JOINING = "ルーム参加中..."
const MSG_CONNECTION_LOST = "接続が切断されました。\n自動再接続中..."
const MSG_RECONNECT_SUCCESS = "接続復旧しました。\n同期を再開しています..."
const MSG_TIMELINE_POST = "タイムラインに投稿"
const MSG_STUDY_REPORT = "今日の勉強報告"
const MSG_REPORT_SLIDER_WARN = "[注意] 申告が実点を超えています！ダウトされる危険性があります。"

# UIテキストのキーマップ
const TEXT_DATA = {
	"MODE_SELECTION_TITLE": "対戦モード",
	"MODE_NATIONAL_TITLE": "模試",
	"MODE_NATIONAL_DESC": "全国のライバルのゴーストと非同期対戦。ダウトはAI判定。(偏差値変動なし)",
	"MODE_FRIEND_TITLE": "フレンド戦",
	"MODE_FRIEND_DESC": "ルームコードを共有して友達と非同期対戦。ダウトは相手が選ぶ！",
	"MODE_RANDOM_TITLE": "ランダムマッチ",
	"MODE_RANDOM_DESC": "自動マッチングで見知らぬライバルと同期型対戦。ダウトは対戦相手が選ぶ！偏差値が変動！",
	
	"CANCEL_BUTTON": "戻る",
	"MATCHING_STATUS": "マッチング中...",
}

## 指定されたキーに対応するテキストを取得する。キーが存在しない場合はキー自体を返す。
func get_text(key: String) -> String:
	return TEXT_DATA.get(key, key)
