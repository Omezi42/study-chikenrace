extends SceneTree

const LOG_PATH := "res://debug-e62179.log"


func _init() -> void:
	var results: Array = []
	_test_script("ZukanScene", "res://scripts/ui/ZukanScene.gd", results)
	_test_scene("ZukanScene.tscn", "res://ZukanScene.tscn", results)
	_test_script("DeskTheme", "res://scripts/ui/DeskTheme.gd", results)
	_test_desk_texture(results)
	_test_vote_flow(results)
	_flush_log(results)
	var ok := _all_passed(results)
	quit(1 if not ok else 0)


func _test_script(label: String, path: String, results: Array) -> void:
	var scr = load(path) if ResourceLoader.exists(path) else null
	results.append(_entry(label, scr != null, {"path": path}))


func _test_scene(label: String, path: String, results: Array) -> void:
	var packed = load(path) if ResourceLoader.exists(path) else null
	var ok := false
	if packed is PackedScene:
		var inst = packed.instantiate()
		ok = inst != null
		if inst:
			inst.free()
	results.append(_entry(label, ok, {"path": path}))


func _test_desk_texture(results: Array) -> void:
	var dt = load("res://scripts/ui/DeskTheme.gd")
	var desk = dt.DESK_TEXTURE if dt else null
	results.append(_entry("desk_texture", desk != null, {"has_texture": desk != null}))


func _test_vote_flow(results: Array) -> void:
	var g = get_root().get_node_or_null("/root/Global")
	if g == null:
		results.append(_entry("vote_flow", false, {"reason": "Global autoload missing"}))
		return
	var bm_script = load("res://scripts/core/BackendManager.gd")
	var bm = bm_script.new()
	g.play_count = 0
	bm.clear_daily_votes()
	bm.vote_rival("慎重な優等生", -1)
	var k1 := "day_1_慎重な優等生"
	var day1_ok: bool = bm.has_voted_rival("慎重な優等生") and bool(g.accumulated_votes.get(k1, false))
	bm.clear_daily_votes()
	g.play_count = 1
	bm.vote_rival("慎重な優等生", -1)
	var day2_ok: bool = bm.has_voted_rival("慎重な優等生")
	results.append(_entry("vote_day1_key", day1_ok, {"key": k1}))
	results.append(_entry("vote_day2_fresh", day2_ok, {"play_count": 1}))


func _entry(test_id: String, passed: bool, data: Dictionary) -> Dictionary:
	return {
		"sessionId": "e62179",
		"hypothesisId": test_id,
		"location": "tools/smoke_test.gd",
		"message": "pass" if passed else "fail",
		"data": data,
		"passed": passed,
		"timestamp": Time.get_unix_time_from_system() * 1000
	}


func _all_passed(results: Array) -> bool:
	for r in results:
		if not r.get("passed", false):
			return false
	return true


func _flush_log(results: Array) -> void:
	var lines: PackedStringArray = []
	for r in results:
		lines.append(JSON.stringify(r))
	var text := "\n".join(lines) + "\n"
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.store_string(text)
	var abs := ProjectSettings.globalize_path(LOG_PATH)
	var f2 := FileAccess.open(abs, FileAccess.WRITE)
	if f2:
		f2.store_string(text)
