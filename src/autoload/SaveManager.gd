extends Node

const SAVE_PATH = "user://savegame.json"

signal save_completed(success: bool)
signal load_completed(success: bool, data: Dictionary)

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
	
	var bak1_path = SAVE_PATH + ".bak1"
	var bak2_path = SAVE_PATH + ".bak2"
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists(bak1_path):
			dir.copy(bak1_path, bak2_path)
		if dir.file_exists(SAVE_PATH):
			dir.copy(SAVE_PATH, bak1_path)
				
		if dir.file_exists(SAVE_PATH):
			dir.remove(SAVE_PATH)
		dir.rename(temp_path, SAVE_PATH)
	else:
		push_error("ユーザーディレクトリのオープンに失敗しました。")
		
	save_completed.emit(true)

func load_game() -> Dictionary:
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
					loaded_data = data
					success = true
					break
				
	load_completed.emit(success, loaded_data)
	return loaded_data
