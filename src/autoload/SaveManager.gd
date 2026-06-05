extends Node

const SAVE_PATH = "user://savegame.json"

signal save_completed(success: bool)
signal load_completed(success: bool, data: Dictionary)

# Save Game state to local storage JSON
func save_game(save_dict: Dictionary) -> void:
	var temp_path = SAVE_PATH + ".tmp"
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("セーブ一時ファイルの作成に失敗しました。Error: %d" % FileAccess.get_open_error())
		save_completed.emit(false)
		return
		
	var json_string = JSON.stringify(save_dict)
	file.store_string(json_string)
	file.close()
	
	# 2世代バックアップのローテーション
	var bak1_path = SAVE_PATH + ".bak1"
	var bak2_path = SAVE_PATH + ".bak2"
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists(bak1_path):
			var err = dir.copy(bak1_path, bak2_path)
			if err != OK:
				push_warning("バックアップ2世代目の更新に失敗しました。Error: %d" % err)
		if dir.file_exists(SAVE_PATH):
			var err = dir.copy(SAVE_PATH, bak1_path)
			if err != OK:
				push_warning("バックアップ1世代目の更新に失敗しました。Error: %d" % err)
				
		# アトミックリネーム
		var err = dir.rename(temp_path, SAVE_PATH)
		if err != OK:
			push_error("セーブファイルの更新（リネーム）に失敗しました。Error: %d" % err)
	else:
		push_error("ユーザーディレクトリのオープンに失敗しました。")
		
	# Silent cloud save if logged in
	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		if global.logged_in_user_id != "" and has_node("/root/BackendManager"):
			var bm = get_node("/root/BackendManager")
			if bm.auth_token != "":
				bm.save_cloud_data(save_dict)
				
	save_completed.emit(true)

# Load Game state from local storage JSON
func load_game(validator: Callable = Callable()) -> Dictionary:
	var loaded_data = {}
	var paths_to_try = [SAVE_PATH, SAVE_PATH + ".bak1", SAVE_PATH + ".bak2"]
	var success = false
	
	for path in paths_to_try:
		if not FileAccess.file_exists(path):
			continue
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var data = json.get_data()
				if data is Dictionary:
					var is_valid = true
					if validator.is_valid():
						is_valid = validator.call(data)
						
					if is_valid:
						loaded_data = data
						if path != SAVE_PATH:
							push_warning("破損検知：バックアップ %s からセーブデータを復旧しました。" % path)
						success = true
						break
					else:
						push_error("%s のデータ構造が無効です。" % path)
			else:
				push_error("%s のJSONパースに失敗しました: %s" % [path, json.get_error_message()])
				
	load_completed.emit(success, loaded_data)
	return loaded_data
