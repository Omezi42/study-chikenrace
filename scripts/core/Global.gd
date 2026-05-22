extends Node

var player_name: String = ""
var total_score: int = 0
var play_count: int = 0
var has_seen_tutorial: bool = false
var current_play_mode: int = 2 # 0: ROOM, 1: CPU, 2: GLOBAL

# CPUモード用のステートとローカルハイスコア
var cpu_data: Array = []
var high_score_cpu: int = 0
var best_rank_cpu: String = "未プレイ"

# メタゲーム（いいね・嘘判定）用ステート
var last_reported_score: int = 0
var last_actual_score: int = 0
# メタ進行・ロードアウト用ステート
var coins: int = 0
var unlocked_items: Array = [
	Enums.ItemType.STICKY_NOTE, Enums.ItemType.ERASER, Enums.ItemType.RULER,
	Enums.ItemType.WORD_BOOK, Enums.ItemType.CHEAT_SHEET, Enums.ItemType.COMPASS,
	Enums.ItemType.ENERGY_DRINK, Enums.ItemType.RED_SHEET, Enums.ItemType.MECHANICAL_PENCIL,
	Enums.ItemType.THICK_BOOK
]
var item_levels: Dictionary = {}
var current_loadout: Dictionary = {
	1: Enums.ItemType.STICKY_NOTE,
	2: Enums.ItemType.ERASER,
	3: Enums.ItemType.RULER,
	4: Enums.ItemType.WORD_BOOK,
	5: Enums.ItemType.CHEAT_SHEET,
	6: Enums.ItemType.COMPASS,
	7: Enums.ItemType.ENERGY_DRINK,
	8: Enums.ItemType.RED_SHEET,
	9: Enums.ItemType.MECHANICAL_PENCIL,
	10: Enums.ItemType.THICK_BOOK
}

# アイテム使用回数（図鑑用）
var item_usage_counts: Dictionary = {}

# スコア履歴（日別推移・プレイヤー別集計用）
# [{"day": 1, "total": 42, "actual_score": 42, "reported_score": 42, "rivals": [{"name": "...", "score": 30}]}]
var score_history: Array = []

# タイムラインでのライバルへのいいね（投票）履歴の永続化
# キー: "day_【Day数】_【ライバル名】" -> true
var accumulated_votes: Dictionary = {}

const SAVE_PATH = "user://savegame.json"
const SAVE_BACKUP_PATH = "user://savegame_backup.json"

func _ready():
	load_data()

func save_data():
	var data = {
		"player_name": player_name,
		"total_score": total_score,
		"play_count": play_count,
		"has_seen_tutorial": has_seen_tutorial,
		"high_score_cpu": high_score_cpu,
		"best_rank_cpu": best_rank_cpu,
		"last_reported_score": last_reported_score,
		"last_actual_score": last_actual_score,
		"coins": coins,
		"unlocked_items": unlocked_items,
		"item_levels": item_levels,
		"current_loadout": current_loadout,
		"item_usage_counts": item_usage_counts,
		"score_history": score_history,
		"accumulated_votes": accumulated_votes,
		"save_version": 2  # Sprint 9: セーブデータバージョン管理
	}
	
	# Sprint 9: 安全な書き込み（一時ファイル→リネーム方式）
	var json_text = JSON.stringify(data)
	var temp_path = SAVE_PATH + ".tmp"
	
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		
		# 既存セーブをバックアップに退避してからリネーム
		if FileAccess.file_exists(SAVE_PATH):
			# バックアップ用コピー
			var backup_file = FileAccess.open(SAVE_BACKUP_PATH, FileAccess.WRITE)
			if backup_file:
				var orig = FileAccess.open(SAVE_PATH, FileAccess.READ)
				if orig:
					backup_file.store_string(orig.get_as_text())
					orig.close()
				backup_file.close()
		
		# 一時ファイルをメインに上書き
		var final_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if final_file:
			final_file.store_string(json_text)
			final_file.close()
	else:
		push_warning("Global.save_data: Failed to open temp save file")

func load_data():
	var loaded = _try_load_from(SAVE_PATH)
	if loaded == null:
		# Sprint 9: メインセーブが破損した場合、バックアップから復元を試みる
		push_warning("Global.load_data: Main save failed, attempting backup recovery...")
		loaded = _try_load_from(SAVE_BACKUP_PATH)
	if loaded == null:
		push_warning("Global.load_data: No valid save data found, using defaults")
		return
	_apply_loaded_data(loaded)

func _try_load_from(path: String):
	if not FileAccess.file_exists(path): return null
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return null
	var text = file.get_as_text()
	file.close()
	if text.is_empty(): return null
	var json = JSON.new()
	if json.parse(text) != OK:
		push_warning("Global._try_load_from: JSON parse error in %s" % path)
		return null
	var data = json.get_data()
	if not data is Dictionary:
		push_warning("Global._try_load_from: Data is not a Dictionary in %s" % path)
		return null
	return data

func _apply_loaded_data(data: Dictionary):
	# Sprint 9: 型安全なデータ読み込み（不正な型はデフォルト値にフォールバック）
	player_name = str(data.get("player_name", ""))
	total_score = _safe_int(data.get("total_score", 0))
	play_count = _safe_int(data.get("play_count", 0))
	has_seen_tutorial = bool(data.get("has_seen_tutorial", false))
	high_score_cpu = _safe_int(data.get("high_score_cpu", 0))
	best_rank_cpu = str(data.get("best_rank_cpu", "未プレイ"))
	last_reported_score = _safe_int(data.get("last_reported_score", 0))
	last_actual_score = _safe_int(data.get("last_actual_score", 0))
	coins = max(0, _safe_int(data.get("coins", 0)))  # コインは負にならない
	
	if data.has("unlocked_items") and data["unlocked_items"] is Array:
		unlocked_items = data["unlocked_items"]
	if data.has("item_levels") and data["item_levels"] is Dictionary:
		var loaded_levels = data["item_levels"]
		item_levels.clear()
		for k in loaded_levels.keys():
			item_levels[int(k)] = loaded_levels[k]
	if data.has("current_loadout") and data["current_loadout"] is Dictionary:
		var loaded_loadout = data["current_loadout"]
		current_loadout.clear()
		# JSONのキーは文字列になるのでintに変換
		for k in loaded_loadout.keys():
			current_loadout[int(k)] = loaded_loadout[k]
	if data.has("item_usage_counts") and data["item_usage_counts"] is Dictionary:
		var loaded_usage = data["item_usage_counts"]
		item_usage_counts.clear()
		for k in loaded_usage.keys():
			item_usage_counts[int(k)] = loaded_usage[k]
			
	score_history = data.get("score_history", []) if data.get("score_history") is Array else []
	accumulated_votes = data.get("accumulated_votes", {}) if data.get("accumulated_votes") is Dictionary else {}

func _safe_int(val) -> int:
	if val is float: return int(val)
	if val is int: return val
	if val is String and val.is_valid_int(): return val.to_int()
	return 0

func increment_item_usage(item_type: int) -> void:
	if not item_usage_counts.has(item_type):
		item_usage_counts[item_type] = 0
	item_usage_counts[item_type] += 1
	save_data()

func get_item_level(item_type: int) -> int:
	return item_levels.get(item_type, 1)

func get_item_usage(item_type: int) -> int:
	return item_usage_counts.get(item_type, 0)

func unlock_achievement(_id: String, _title: String):
	print("Achievement Unlocked: ", _title)
