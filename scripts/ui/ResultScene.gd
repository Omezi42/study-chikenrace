class_name ResultScene
extends Control

const GameBalanceScript = preload("res://scripts/core/GameBalance.gd")

const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")

var audio_manager: AudioManager
var backend_manager: BackendManager

var ui_root: Control
var screen_content: Control
var bonus_score_label: Label
var final_score_label: Label
var rank_label: Label

var base_score: int = 0
var bonus_score: int = 0
var final_score: int = 0

# 答え合わせ（Showdown Reveal）用ステート
var current_live_score: int = 0
var is_skipped: bool = false
var board_overlay: Control
var live_score_label: Label
var skip_btn: Button

# 称号算出用統計データ
var player_lie_count: int = 0
var player_exposed_count: int = 0
var player_perfect_crimes: int = 0
var player_doubt_success: int = 0
var player_doubt_failed: int = 0

# 答え合わせ一括計算用データ
var results_per_day: Array = []
var participant_names: Array = []
var final_scores: Dictionary = {}
var initial_scores: Dictionary = {}

func _ready():
	audio_manager = AudioManager.new()
	add_child(audio_manager)
	
	backend_manager = BackendManager.new()
	add_child(backend_manager)
	backend_manager.scores_loaded.connect(_on_scores_loaded)
	
	DeskTheme.decorate_scene(self, 0.24)
	
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)
	
	screen_content = Control.new()
	screen_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(screen_content)
	
	# 得点読み込み
	base_score = Global.total_score
	current_live_score = base_score
	
	backend_manager.load_daily_scores()
	_show_loading()

func _show_loading():
	var page = DeskTheme.create_notebook_panel(Vector2(840, 620), 80, 60, 80, 50)
	page.anchor_left = 0.5; page.anchor_top = 0.5; page.anchor_right = 0.5; page.anchor_bottom = 0.5
	page.offset_left = -420; page.offset_top = -310; page.offset_right = 420; page.offset_bottom = 310
	screen_content.add_child(page)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	DeskTheme.apply_font(vbox)
	page.get_node("Content").add_child(vbox)
	
	vbox.add_child(DeskTheme.create_label("通知表を集計中...", 24, DeskTheme.COLOR_MUTED, true))

func _on_scores_loaded(_scores):
	_start_showdown_reveal()

func _calculate_all_results():
	results_per_day.clear()
	participant_names.clear()
	final_scores.clear()
	initial_scores.clear()
	
	# 参加者リストの取得
	participant_names.append(Global.player_name)
	initial_scores[Global.player_name] = 0
	final_scores[Global.player_name] = 0
	
	var total_days = Global.score_history.size()
	if total_days > 0:
		var first_day = Global.score_history[0]
		for rival in first_day.get("rivals", []):
			var r_name = rival.get("name")
			participant_names.append(r_name)
			initial_scores[r_name] = 0
			final_scores[r_name] = 0
			
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(Global.player_name) + 999
	
	for d in range(1, total_days + 1):
		var entry = Global.score_history[d - 1]
		var day_data = {}
		
		# プレイヤー
		var p_rep = entry.get("reported_score", 0)
		var p_act = entry.get("actual_score", p_rep)
		var p_cheat = entry.get("cheat_sheet_count", 0)
		var p_answer = entry.get("answer_key_count", 0)
		var p_group_chat = entry.get("study_group_chat_count", 0)
		var p_noise_canceling = entry.get("noise_canceling_count", 0)
		var p_votes = []
		for r_name in participant_names:
			if r_name != Global.player_name:
				var vote_key = "day_%d_%s" % [d, r_name]
				if Global.accumulated_votes.get(vote_key, false):
					p_votes.append(r_name)
					
		day_data[Global.player_name] = {
			"reported": p_rep,
			"actual": p_act,
			"is_lying": p_rep > p_act,
			"cheat_sheet_count": p_cheat,
			"answer_key_count": p_answer,
			"study_group_chat_count": p_group_chat,
			"noise_canceling_count": p_noise_canceling,
			"votes": p_votes,
			"exposed": false,
			"score_change": 0,
			"reasons": [],
			"vote_results": []
		}
		initial_scores[Global.player_name] += p_rep
		
		# ライバルたち
		var rivals = entry.get("rivals", [])
		for r in rivals:
			var r_name = r.get("name")
			var r_rep = r.get("score", 0)
			var r_act = r.get("actual_score", r_rep)
			var r_cheat = r.get("cheat_sheet_count", 0)
			var r_answer = r.get("answer_key_count", 0)
			var r_group_chat = r.get("study_group_chat_count", 0)
			var r_noise_canceling = r.get("noise_canceling_count", 0)
			var r_votes = r.get("votes", [])
			
			day_data[r_name] = {
				"reported": r_rep,
				"actual": r_act,
				"is_lying": r_rep > r_act,
				"cheat_sheet_count": r_cheat,
				"answer_key_count": r_answer,
				"study_group_chat_count": r_group_chat,
				"noise_canceling_count": r_noise_canceling,
				"votes": r_votes,
				"exposed": false,
				"score_change": 0,
				"reasons": [],
				"vote_results": []
			}
			initial_scores[r_name] += r_rep
			
		# フォールバック
		for r_name in participant_names:
			if not day_data.has(r_name):
				day_data[r_name] = {
					"reported": 0,
					"actual": 0,
					"is_lying": false,
					"cheat_sheet_count": 0,
					"answer_key_count": 0,
					"votes": [],
					"exposed": false,
					"score_change": 0,
					"reasons": [],
					"vote_results": []
				}
				
		# 露見判定
		for name in participant_names:
			var p_info = day_data[name]
			if p_info["is_lying"]:
				var lie_amount = p_info["reported"] - p_info["actual"]
				var max_cap = GameBalanceScript.max_bluff_cap(p_info["cheat_sheet_count"])
				var exp_rate = GameBalanceScript.calculate_exposure_rate(lie_amount, max_cap, p_info["cheat_sheet_count"], p_info["answer_key_count"])
				var roll = rng.randf()
				if roll < exp_rate:
					p_info["exposed"] = true
					
		# 投票結果判定
		for voter_name in participant_names:
			var voter_info = day_data[voter_name]
			var votes_cast = voter_info["votes"]
			var v_results = []
			
			for target_name in votes_cast:
				if not day_data.has(target_name):
					continue
				var target_info = day_data[target_name]
				
				if target_info["is_lying"] and target_info["exposed"]:
					var lie_amount = target_info["reported"] - target_info["actual"]
					var reward = GameBalanceScript.doubt_success_reward(lie_amount, voter_info.get("study_group_chat_count", 0))
					voter_info["score_change"] += reward
					voter_info["reasons"].append("いいね成功(+%d)➔%s" % [reward, target_name])
					v_results.append({"name": target_name, "success": true, "delta": reward})
				else:
					var penalty = GameBalanceScript.doubt_fail_penalty(d, voter_info.get("noise_canceling_count", 0))
					voter_info["score_change"] -= penalty
					voter_info["reasons"].append("いいね失敗(-%d)➔%s" % [penalty, target_name])
					v_results.append({"name": target_name, "success": false, "delta": -penalty})
			voter_info["vote_results"] = v_results
			
		results_per_day.append(day_data)
		
	for name in participant_names:
		var total = initial_scores[name]
		for d_idx in range(total_days):
			var day_data = results_per_day[d_idx]
			total += day_data[name]["score_change"]
		final_scores[name] = max(0, total)


# ====================================================
# 最終日「答え合わせ・Showdown Reveal」黒板演出
# ====================================================
func _start_showdown_reveal():
	_calculate_all_results()
	
	for child in screen_content.get_children():
		child.queue_free()
		
	# 黒板の外枠パネル（レトロな木製フレーム）
	board_overlay = Panel.new()
	board_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color("133324") # 深みのあるレトロな黒板緑
	frame_style.border_width_left = 18; frame_style.border_width_right = 18
	frame_style.border_width_top = 18; frame_style.border_width_bottom = 18
	frame_style.border_color = Color("5c4033") # 温かみのある濃い木目ブラウン
	frame_style.corner_radius_top_left = 12; frame_style.corner_radius_top_right = 12
	frame_style.corner_radius_bottom_left = 12; frame_style.corner_radius_bottom_right = 12
	frame_style.shadow_color = Color(0, 0, 0, 0.6)
	frame_style.shadow_size = 24
	board_overlay.add_theme_stylebox_override("panel", frame_style)
	screen_content.add_child(board_overlay)
	
	# タップで早送り（スキップ）機能の有効化
	board_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_skipped:
				is_skipped = true
				if audio_manager: audio_manager.play_se("click")
				if skip_btn and is_instance_valid(skip_btn):
					skip_btn.hide()
	)
	
	# 黒板のレトロな粉受け（下部トレイ）
	var tray = Panel.new()
	tray.anchor_left = 0.02; tray.anchor_top = 0.97; tray.anchor_right = 0.98; tray.anchor_bottom = 0.99
	var tray_style = StyleBoxFlat.new()
	tray_style.bg_color = Color("422e23") # 木製トレイ
	tray_style.corner_radius_top_left = 4; tray_style.corner_radius_top_right = 4
	tray.add_theme_stylebox_override("panel", tray_style)
	board_overlay.add_child(tray)
	
	# Sprint 6: トレイ上のチョーク粉装飾
	var chalk_dots_tray = HBoxContainer.new()
	chalk_dots_tray.anchor_left = 0.1; chalk_dots_tray.anchor_top = 0.965; chalk_dots_tray.anchor_right = 0.4; chalk_dots_tray.anchor_bottom = 0.975
	chalk_dots_tray.add_theme_constant_override("separation", 8)
	board_overlay.add_child(chalk_dots_tray)
	for i in range(5):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(randi_range(4, 10), randi_range(2, 5))
		dot.color = [Color("e8e8e8", 0.5), Color("f5e642", 0.4), Color("ff9999", 0.4)][i % 3]
		chalk_dots_tray.add_child(dot)
	
	var title_lbl = DeskTheme.create_label("【 学年最終答え合わせ - Showdown Reveal 】", 28, DeskTheme.COLOR_CHALK_WHITE, true)
	title_lbl.anchor_left = 0.5; title_lbl.anchor_top = 0.04; title_lbl.anchor_right = 0.5
	title_lbl.offset_left = -350; title_lbl.offset_right = 350
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_overlay.add_child(title_lbl)
	
	# Sprint 6: タイトル下のチョーク装飾ライン
	var chalk_line = ColorRect.new()
	chalk_line.color = Color("e8e8e8", 0.3)
	chalk_line.anchor_left = 0.15; chalk_line.anchor_top = 0.085; chalk_line.anchor_right = 0.85; chalk_line.anchor_bottom = 0.085
	chalk_line.offset_top = 0; chalk_line.offset_bottom = 2
	board_overlay.add_child(chalk_line)
	
	# Sprint 6: タイトルのフェードインアニメーション
	title_lbl.modulate.a = 0.0
	var title_tw = title_lbl.create_tween()
	title_tw.tween_property(title_lbl, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC)
	
	live_score_label = DeskTheme.create_label("現在の得点: %d点" % current_live_score, 24, DeskTheme.COLOR_CHALK_YELLOW, true)
	live_score_label.anchor_left = 0.5; live_score_label.anchor_top = 0.10; live_score_label.anchor_right = 0.5
	live_score_label.offset_left = -200; live_score_label.offset_right = 200
	live_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_overlay.add_child(live_score_label)
	
	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0.04; scroll.anchor_top = 0.17; scroll.anchor_right = 0.96; scroll.anchor_bottom = 0.83
	scroll.set_horizontal_scroll_mode(ScrollContainer.SCROLL_MODE_DISABLED)
	scroll.set_vertical_scroll_mode(ScrollContainer.SCROLL_MODE_AUTO)
	board_overlay.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)
	
	# スキップボタン
	skip_btn = DeskTheme.create_button("⏩ 演出を早送り (スキップ)", Vector2(240, 48), DeskTheme.COLOR_ACCENT_GOLD, Color("b38f30"))
	skip_btn.anchor_left = 0.96; skip_btn.anchor_top = 0.91; skip_btn.anchor_right = 0.96; skip_btn.anchor_bottom = 0.91
	skip_btn.offset_left = -240; skip_btn.offset_top = -24; skip_btn.offset_right = 0; skip_btn.offset_bottom = 24
	skip_btn.pressed.connect(func():
		is_skipped = true
		if audio_manager: audio_manager.play_se("click")
		if skip_btn and is_instance_valid(skip_btn):
			skip_btn.hide()
	)
	board_overlay.add_child(skip_btn)
	
	# 5日分の枠組みを事前生成して表示
	var row_nodes = []
	var total_days = Global.score_history.size()
	for d in range(1, total_days + 1):
		var row = _create_reveal_row(d)
		vbox.add_child(row)
		row_nodes.append(row)
		# Sprint 6: 行を最初は透明にしておく
		row.modulate.a = 0.3
		
	# 順次答え合わせアニメーション開始
	if not is_skipped:
		await get_tree().create_timer(0.8).timeout
	
	for d in range(1, total_days + 1):
		var day_data = results_per_day[d - 1]
		var row = row_nodes[d-1]
		
		# スキップされていなければスクロールとハイライトを行う
		if not is_skipped:
			scroll.ensure_control_visible(row)
			
			# Sprint 6: 行のフェードイン＋ハイライト
			var row_fade = row.create_tween()
			row_fade.tween_property(row, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
			
			# 選択中行のやわらかい明滅Tween
			var row_tw = row.create_tween()
			row_tw.tween_property(row, "modulate", Color(1.3, 1.3, 1.3), 0.2)
			row_tw.tween_property(row, "modulate", Color.WHITE, 0.2)
			
			await get_tree().create_timer(0.4).timeout
		else:
			row.modulate.a = 1.0
			
		var rivals_box = row.find_child("RivalsBox", true, false)
		var player_box = row.find_child("PlayerBox", true, false)
		
		# ----------------------------------------------------
		# 1. ライバルの暴露
		# ----------------------------------------------------
		for r_name in participant_names:
			if r_name == Global.player_name:
				continue
				
			var r_data = day_data[r_name]
			var r_reported = r_data["reported"]
			var r_actual = r_data["actual"]
			var is_lying = r_data["is_lying"]
			var exposed = r_data["exposed"]
			
			var r_lbl = DeskTheme.create_label("%s: %d➔%d点" % [r_name.left(4), r_reported, r_actual], 15, DeskTheme.COLOR_CHALK_WHITE)
			rivals_box.add_child(r_lbl)
			
			var stamp_lbl: Control = null
			if is_lying:
				if exposed:
					stamp_lbl = DeskTheme.create_mini_stamp("嘘バレ！", DeskTheme.COLOR_BLUFF_RED, 12)
					if not is_skipped:
						var lie_flash = ColorRect.new()
						lie_flash.color = Color(1.0, 0.3, 0.3, 0.25)
						lie_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
						lie_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
						row.add_child(lie_flash)
						var lf_tw = lie_flash.create_tween()
						lf_tw.tween_property(lie_flash, "color:a", 0.0, 0.5)
						lf_tw.tween_callback(lie_flash.queue_free)
				else:
					stamp_lbl = DeskTheme.create_mini_stamp("すり抜け", Color("ffd43b"), 12)
			else:
				stamp_lbl = DeskTheme.create_mini_stamp("正直者", Color("40c057"), 12)
				
			if stamp_lbl != null:
				rivals_box.add_child(stamp_lbl)
				await _animate_stamp(stamp_lbl)
				
			if not is_skipped:
				await get_tree().create_timer(0.2).timeout
				
		# ----------------------------------------------------
		# 2. プレイヤー自身のダウト結果等の暴露
		# ----------------------------------------------------
		var p_data = day_data[Global.player_name]
		var player_lied = p_data["is_lying"]
		var total_lie = p_data["reported"] - p_data["actual"]
				
		var p_lbl_text = "あなた: 正直報告"
		if player_lied:
			p_lbl_text = "あなた: 嘘盛＋%d点" % total_lie
			player_lie_count += 1
			
		var p_lbl = DeskTheme.create_label(p_lbl_text, 15, DeskTheme.COLOR_CHALK_WHITE)
		player_box.add_child(p_lbl)
		
		var p_stamp: Control = null
		if player_lied:
			if p_data["exposed"]:
				p_stamp = DeskTheme.create_mini_stamp("嘘バレ！", DeskTheme.COLOR_BLUFF_RED, 14)
				player_exposed_count += 1
				if audio_manager: audio_manager.play_se("burst")
				_trigger_mini_shake(16.0)
				
				if not is_skipped:
					var red_flash = ColorRect.new()
					red_flash.color = Color(1.0, 0.0, 0.0, 0.3)
					red_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
					red_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
					board_overlay.add_child(red_flash)
					var rf_tw = red_flash.create_tween()
					rf_tw.tween_property(red_flash, "color:a", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC)
					rf_tw.tween_callback(red_flash.queue_free)
			else:
				p_stamp = DeskTheme.create_mini_stamp("完全犯罪！", Color("e8590c"), 14)
				player_perfect_crimes += 1
				if audio_manager: audio_manager.play_se("combo")
				
				if not is_skipped:
					var gold_flash = ColorRect.new()
					gold_flash.color = Color(1.0, 0.84, 0.0, 0.2)
					gold_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
					gold_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
					board_overlay.add_child(gold_flash)
					var gf_tw = gold_flash.create_tween()
					gf_tw.tween_property(gold_flash, "color:a", 0.0, 0.5)
					gf_tw.tween_callback(gold_flash.queue_free)
		else:
			p_stamp = DeskTheme.create_mini_stamp("平和な一日", Color("8fbf9f"), 14)
			if audio_manager: audio_manager.play_se("place")
				
		if p_stamp != null:
			player_box.add_child(p_stamp)
			await _animate_stamp(p_stamp)
			
		var vote_results = p_data.get("vote_results", [])
		var p_score_diff = p_data["score_change"]
		
		for vote_res in vote_results:
			var doubt_stamp: Control = null
			var v_name = vote_res["name"]
			var delta = vote_res["delta"]
			if vote_res["success"]:
				doubt_stamp = DeskTheme.create_mini_stamp("👍%s見破り(+%d)" % [v_name.left(3), delta], DeskTheme.COLOR_SAFE, 13)
				player_doubt_success += 1
			else:
				doubt_stamp = DeskTheme.create_mini_stamp("👍%s失敗(%d)" % [v_name.left(3), delta], DeskTheme.COLOR_MUTED, 13)
				player_doubt_failed += 1
				
			if doubt_stamp != null:
				player_box.add_child(doubt_stamp)
				await _animate_stamp(doubt_stamp)
		
		if player_lied and not p_data["exposed"]:
			_spawn_confetti(player_box.global_position + Vector2(250, 40))
			_spawn_confetti(player_box.global_position + Vector2(100, 20))
		
		if p_score_diff != 0:
			current_live_score = max(0, current_live_score + p_score_diff)
			_update_live_score_ui(p_score_diff)
			
		if not is_skipped:
			await get_tree().create_timer(0.4).timeout
			
	# スキップ時対応：最終スコアへ即座に補正
	if is_skipped:
		live_score_label.text = "現在の得点: %d点" % current_live_score
		
	# 答え合わせ完了！通知表への遷移ボタンを出現させる
	if skip_btn:
		skip_btn.queue_free()
		
	var next_btn = DeskTheme.create_button("【 通知表を受け取る ➔ 】", Vector2(400, 64), DeskTheme.COLOR_ACCENT_GOLD, Color("b38f30"))
	next_btn.anchor_left = 0.5; next_btn.anchor_top = 0.91; next_btn.anchor_right = 0.5; next_btn.anchor_bottom = 0.91
	next_btn.offset_left = -200; next_btn.offset_top = -32; next_btn.offset_right = 200; next_btn.offset_bottom = 32
	next_btn.pressed.connect(_finish_showdown_reveal)
	next_btn.modulate.a = 0.0
	board_overlay.add_child(next_btn)
	
	# Sprint 6: 「答え合わせ完了」チョーク文字演出
	var completion_lbl = DeskTheme.create_label("── 答え合わせ完了 ──", 22, DeskTheme.COLOR_CHALK_YELLOW, true)
	completion_lbl.anchor_left = 0.5; completion_lbl.anchor_top = 0.86; completion_lbl.anchor_right = 0.5
	completion_lbl.offset_left = -150; completion_lbl.offset_right = 150
	completion_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_lbl.modulate.a = 0.0
	board_overlay.add_child(completion_lbl)
	
	var comp_tw = completion_lbl.create_tween()
	comp_tw.tween_property(completion_lbl, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	if audio_manager: audio_manager.play_se("place")
	
	# Sprint 6: ボタンの出現アニメーション（少し遅延してから表示）
	var btn_appear_tw = next_btn.create_tween()
	btn_appear_tw.tween_interval(0.5)
	btn_appear_tw.tween_property(next_btn, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	
	# ボタンの脈動アニメーション
	next_btn.pivot_offset = Vector2(200, 32)
	var pulse = next_btn.create_tween().set_loops()
	pulse.tween_property(next_btn, "scale", Vector2(1.05, 1.05), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse.tween_property(next_btn, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _animate_stamp(stamp: Control) -> void:
	stamp.pivot_offset = stamp.custom_minimum_size / 2.0
	var rot = randf_range(-15.0, 15.0)
	if is_skipped:
		stamp.scale = Vector2(1.0, 1.0)
		stamp.modulate.a = 1.0
		stamp.rotation_degrees = rot
	else:
		stamp.scale = Vector2(4.0, 4.0)
		stamp.modulate.a = 0.0
		var stw = stamp.create_tween().set_parallel(true)
		stw.tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		stw.tween_property(stamp, "modulate:a", 1.0, 0.08)
		stw.tween_property(stamp, "rotation_degrees", rot, 0.18)
		await stw.finished

func _create_reveal_row(d: int) -> PanelContainer:
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 80)
	
	var row_style = StyleBoxFlat.new()
	row_style.bg_color = Color("1e3d30") # 少し明るめの黒板緑で区切る
	row_style.border_width_left = 2; row_style.border_width_right = 2
	row_style.border_width_top = 2; row_style.border_width_bottom = 2
	row_style.border_color = Color("2e5c46")
	row_style.corner_radius_top_left = 8; row_style.corner_radius_top_right = 8
	row_style.corner_radius_bottom_left = 8; row_style.corner_radius_bottom_right = 8
	row.add_theme_stylebox_override("panel", row_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	row.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	margin.add_child(hbox)
	
	# Day表示
	var day_lbl = DeskTheme.create_label("Day %d" % d, 22, DeskTheme.COLOR_CHALK_WHITE, true)
	day_lbl.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(day_lbl)
	
	# --- ライバルたち ---
	var rivals_box = HBoxContainer.new()
	rivals_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rivals_box.add_theme_constant_override("separation", 16)
	rivals_box.name = "RivalsBox"
	hbox.add_child(rivals_box)
	
	# --- プレイヤー自身 ---
	var player_box = HBoxContainer.new()
	player_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_box.alignment = BoxContainer.ALIGNMENT_END
	player_box.add_theme_constant_override("separation", 16)
	player_box.name = "PlayerBox"
	hbox.add_child(player_box)
	
	return row

func _update_live_score_ui(diff: int):
	live_score_label.text = "現在の得点: %d点" % current_live_score
	
	# 点数の増減によって色を変えてボヨヨンTween
	var pop = live_score_label.create_tween()
	live_score_label.pivot_offset = live_score_label.size / 2.0
	pop.tween_property(live_score_label, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if diff > 0:
		live_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_BONUS)
	elif diff < 0:
		live_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
		
	pop.tween_property(live_score_label, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	pop.tween_callback(func():
		live_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_CHALK_YELLOW)
	)

func _trigger_mini_shake(intensity: float):
	if is_skipped: return
	var shake = create_tween().set_loops(4)
	shake.tween_callback(func(): ui_root.position = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)))
	shake.tween_interval(0.04)
	await shake.finished
	ui_root.position = Vector2.ZERO

func _finish_showdown_reveal():
	if audio_manager: audio_manager.play_se("click")
	
	# スコアカウンタ同期
	base_score = current_live_score
	Global.total_score = base_score
	Global.save_data()
	
	var fade = board_overlay.create_tween()
	fade.tween_property(board_overlay, "modulate:a", 0.0, 0.4)
	await fade.finished
	
	_show_final_report()

# ====================================================
# 成績発表（通知表）カード表示
# ====================================================
func _show_final_report():
	for child in screen_content.get_children():
		child.queue_free()
		
	var page = DeskTheme.create_notebook_panel(Vector2(1040, 780), 64, 48, 64, 32)
	page.anchor_left = 0.5; page.anchor_top = 0.5; page.anchor_right = 0.5; page.anchor_bottom = 0.5
	page.offset_left = -520; page.offset_top = -390; page.offset_right = 520; page.offset_bottom = 390
	screen_content.add_child(page)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 24)
	DeskTheme.apply_font(vbox)
	page.get_node("Content").add_child(vbox)
	
	vbox.add_child(DeskTheme.create_label("学末最終通知表", 42, DeskTheme.COLOR_INK, true))
	vbox.add_child(DeskTheme.create_label("名前: " + Global.player_name, 24, DeskTheme.COLOR_INK, true))
	
	# シーズン成績リスト
	var table_h = HBoxContainer.new()
	table_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_h.add_theme_constant_override("separation", 36)
	table_h.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(table_h)
	
	final_score = final_scores.get(Global.player_name, base_score)
	
	# 総合成績通知表 (幅広めに中央配置)
	var report_card = DeskTheme.create_sticky_note(Color("fffae6"), Vector2(460, 420), 1.0)
	report_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	table_h.add_child(report_card)
	
	# 最終順位ランキングボード
	var leaderboard = DeskTheme.create_sticky_note(Color("e8f4fd"), Vector2(400, 420), -1.0)
	leaderboard.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	table_h.add_child(leaderboard)
	
	var lb_v = VBoxContainer.new()
	lb_v.alignment = BoxContainer.ALIGNMENT_CENTER
	lb_v.add_theme_constant_override("separation", 10)
	leaderboard.add_child(lb_v)
	
	lb_v.add_child(DeskTheme.create_label("【 最終順位 】", 20, DeskTheme.COLOR_MUTED, true))
	
	# スコア順にソート
	var rank_list = []
	for name in final_scores.keys():
		rank_list.append({"name": name, "score": final_scores[name]})
	rank_list.sort_custom(func(a, b): return a["score"] > b["score"])
	
	var r_num = 1
	for r_item in rank_list:
		var r_name = r_item["name"]
		var r_score = r_item["score"]
		
		var entry_h = HBoxContainer.new()
		entry_h.alignment = BoxContainer.ALIGNMENT_CENTER
		entry_h.add_theme_constant_override("separation", 16)
		lb_v.add_child(entry_h)
		
		var c_color = DeskTheme.COLOR_INK
		var r_prefix = "%d." % r_num
		if r_num == 1:
			c_color = DeskTheme.COLOR_ACCENT_GOLD
			r_prefix = "🥇"
		elif r_num == 2:
			c_color = Color("a0aab2")
			r_prefix = "🥈"
		elif r_num == 3:
			c_color = Color("cd7f32")
			r_prefix = "🥉"
		
		var rank_lbl = DeskTheme.create_label(r_prefix, 18, c_color, true)
		rank_lbl.custom_minimum_size = Vector2(30, 0)
		rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entry_h.add_child(rank_lbl)
		
		var display_name = r_name
		if r_name == Global.player_name:
			display_name = "★あなた★"
		
		var name_lbl = DeskTheme.create_label(display_name, 15, c_color, r_name == Global.player_name)
		name_lbl.custom_minimum_size = Vector2(160, 0)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		entry_h.add_child(name_lbl)
		
		var score_lbl = DeskTheme.create_label("%d点" % r_score, 15, c_color, true)
		score_lbl.custom_minimum_size = Vector2(80, 0)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		entry_h.add_child(score_lbl)
		
		r_num += 1
	
	var rc_v = VBoxContainer.new()
	rc_v.alignment = BoxContainer.ALIGNMENT_CENTER
	rc_v.add_theme_constant_override("separation", 12)
	report_card.add_child(rc_v)
	
	rc_v.add_child(DeskTheme.create_label("【成績分析】", 20, DeskTheme.COLOR_MUTED, true))
	
	var base_lbl = DeskTheme.create_label("最終獲得スコア: %d点" % base_score, 24, DeskTheme.COLOR_INK, true)
	rc_v.add_child(base_lbl)
	

	
	# ランク判定
	rank_label = DeskTheme.create_label("判定: F", 38, DeskTheme.COLOR_MUTED, true)
	rc_v.add_child(rank_label)
	
	var earned_coins = int(final_score / 10)
	Global.coins += earned_coins
	Global.save_data()
	
	var coins_lbl = DeskTheme.create_label("獲得コイン: %d枚 (合計: %d枚)" % [earned_coins, Global.coins], 20, Color("e67700"), true)
	rc_v.add_child(coins_lbl)
	
	# 🏆 プレイスタイルに応じた称号判定
	var title_style = "ただの凡人"
	var title_desc = "特に目立った特徴のない平凡な学生生活を送りました。"
	var title_color = DeskTheme.COLOR_INK
	
	if player_lie_count >= 2 and player_exposed_count == 0 and final_score >= 180:
		title_style = "完全犯罪のカリスマ"
		title_desc = "一度も嘘がバレることなく、見事にライバルを騙し抜いた詐欺的ガリ勉。"
		title_color = DeskTheme.COLOR_ACCENT_GOLD
	elif player_lie_count >= 2 and player_exposed_count == player_lie_count:
		title_style = "ガラスのハート"
		title_desc = "ついた嘘がことごとく暴かれ、赤点地獄に陥った不器用なチャレンジャー。"
		title_color = DeskTheme.COLOR_BLUFF_RED
	elif player_lie_count == 0 and final_score >= 150:
		title_style = "清廉潔白なガリ勉"
		title_desc = "一切のハッタリや嘘に頼らず、純粋な自習の力だけで圧倒的スコアを稼いだ聖人。"
		title_color = DeskTheme.COLOR_SAFE
	elif player_doubt_success >= 3:
		title_style = "人間嘘発見器"
		title_desc = "ライバルの微小なスコア変動から嘘の予兆を捉え、見事に暴きまくった名探偵。"
		title_color = Color("2b8a3e")
		
	var title_lbl = DeskTheme.create_label("称号: " + title_style, 18, title_color, true)
	rc_v.add_child(title_lbl)
	var title_desc_lbl = DeskTheme.create_label(title_desc, 12, DeskTheme.COLOR_MUTED)
	title_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rc_v.add_child(title_desc_lbl)
	
	# X (Twitter) でシェアボタン
	var share_btn = DeskTheme.create_button("𝕏 に結果をポストして自慢する", Vector2(300, 42), Color("1ca1f2"), Color("1a8cd8"), true, 13)
	share_btn.pressed.connect(func():
		if audio_manager: audio_manager.play_se("click")
		var share_text = "【テスト勉強チキンレース】総合評価点：%d点！獲得した称号は『%s』！\n%s\n#テスト勉強チキンレース" % [
			final_score,
			title_style,
			title_desc
		]
		var share_url = "https://twitter.com/intent/tweet?text=" + share_text.uri_encode()
		OS.shell_open(share_url)
	)
	rc_v.add_child(share_btn)
	
	# タイトルに戻るボタン
	var close_btn = DeskTheme.create_button("シーズンを終了してタイトルへ", Vector2(400, 72), DeskTheme.COLOR_SAFE, Color("2d928a"))
	close_btn.pressed.connect(_on_title_pressed)
	vbox.add_child(close_btn)
	
	DeskTheme.animate_entrance(page)
	
	# スタンプ連打・ボーナス演出は削除したため即座にランク表示へ
		
	# 最終的なランク評価とS-Fスタンプ
	var rank_char = "F"
	var rank_color = DeskTheme.COLOR_MUTED
	var is_s_rank = false
	if final_score >= 250:
		rank_char = "S"
		rank_color = DeskTheme.COLOR_ACCENT_GOLD
		is_s_rank = true
	elif final_score >= 180:
		rank_char = "A"
		rank_color = DeskTheme.COLOR_BLUFF_RED
	elif final_score >= 120:
		rank_char = "B"
		rank_color = Color("9e7aff")
	elif final_score >= 80:
		rank_char = "C"
		rank_color = Color("4b7de0")
	elif final_score >= 40:
		rank_char = "D"
		rank_color = DeskTheme.COLOR_INK
		
	rank_label.text = "総合判定: 【 %s 級 】" % rank_char
	rank_label.add_theme_color_override("font_color", rank_color)
	
	if Global.current_play_mode == 1:
		if final_score > Global.high_score_cpu:
			Global.high_score_cpu = final_score
			Global.best_rank_cpu = rank_char
			Global.save_data()
	
	# ランク文字がボヨヨンと弾けるTween
	rank_label.pivot_offset = rank_label.size / 2.0
	rank_label.scale = Vector2(0.1, 0.1)
	var rank_tw = rank_label.create_tween()
	rank_tw.tween_property(rank_label, "scale", Vector2(1.3, 1.3), 0.28).set_trans(Tween.TRANS_BACK)
	rank_tw.tween_property(rank_label, "scale", Vector2(1.0, 1.0), 0.15)
	
	if is_s_rank:
		# はなまるスタンプの特大演出
		var hanamaru = TextureRect.new()
		hanamaru.texture = DeskTheme.HANAMARU_TEXTURE
		hanamaru.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hanamaru.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hanamaru.custom_minimum_size = Vector2(400, 400)
		hanamaru.scale = Vector2(5.0, 5.0)
		hanamaru.modulate.a = 0.0
		hanamaru.rotation_degrees = -15
		
		# 画面中央の付箋の上に配置
		var rc_container = rank_label.get_parent()
		rc_container.add_child(hanamaru)
		hanamaru.position = Vector2(-10, -50) # 位置微調整
		hanamaru.pivot_offset = Vector2(200, 200)
		
		var ht = hanamaru.create_tween().set_parallel(true)
		ht.tween_property(hanamaru, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		ht.tween_property(hanamaru, "modulate:a", 0.9, 0.2)
		
		await get_tree().create_timer(0.1).timeout
		if audio_manager: audio_manager.play_se("combo")
		
		var shake = create_tween().set_loops(4)
		shake.tween_callback(func(): ui_root.position = Vector2(randf_range(-10, 10), randf_range(-10, 10)))
		shake.tween_interval(0.04)
		await shake.finished
		ui_root.position = Vector2.ZERO
	else:
		if audio_manager: audio_manager.play_se("combo")

func _on_title_pressed():
	if audio_manager: audio_manager.play_se("click")
	
	# シーズン終了時にゲームデータを初期化
	Global.total_score = 0
	Global.play_count = 0
	Global.score_history.clear()
	Global.accumulated_votes.clear()
	Global.save_data()
	
	SceneTransition.fade_to_scene("res://Title.tscn")

func _spawn_confetti(pos: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 60
	particles.lifetime = 2.0
	particles.explosiveness = 0.85
	particles.direction = Vector2(0, -1)
	particles.spread = 75.0
	particles.gravity = Vector2(0, 300.0)
	particles.initial_velocity_min = 180.0
	particles.initial_velocity_max = 350.0
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 12.0
	
	var grad = Gradient.new()
	grad.set_offsets(PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0]))
	grad.set_colors(PackedColorArray([
		Color("ff8787"), Color("ffc078"), Color("63e6be"),
		Color("74c0fc"), Color("da77f2")
	]))
	particles.color_ramp = grad
	
	particles.angular_velocity_min = -150.0
	particles.angular_velocity_max = 150.0
	particles.linear_damp_min = 1.0
	particles.linear_damp_max = 2.0
	
	add_child(particles)
	
	var timer = get_tree().create_timer(2.2)
	timer.timeout.connect(particles.queue_free)
