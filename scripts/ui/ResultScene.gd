class_name ResultScene
extends Control

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

# ====================================================
# 最終日「答え合わせ・Showdown Reveal」黒板演出
# ====================================================
func _start_showdown_reveal():
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
	
	var title_lbl = DeskTheme.create_label("【 学年最終答え合わせ - Showdown Reveal 】", 28, DeskTheme.COLOR_CHALK_WHITE, true)
	title_lbl.anchor_left = 0.5; title_lbl.anchor_top = 0.04; title_lbl.anchor_right = 0.5
	title_lbl.offset_left = -350; title_lbl.offset_right = 350
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_overlay.add_child(title_lbl)
	
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
		skip_btn.hide()
	)
	board_overlay.add_child(skip_btn)
	
	# 7日分の枠組みを事前生成して表示
	var row_nodes = []
	var total_days = Global.score_history.size()
	for d in range(1, total_days + 1):
		var row = _create_reveal_row(d)
		vbox.add_child(row)
		row_nodes.append(row)
		
	# 順次答え合わせアニメーション開始
	if not is_skipped:
		await get_tree().create_timer(0.8).timeout
	
	for d in range(1, total_days + 1):
		var entry = Global.score_history[d-1]
		var row = row_nodes[d-1]
		
		# スキップされていなければスクロールとハイライトを行う
		if not is_skipped:
			scroll.ensure_control_visible(row)
			
			# 選択中行のやわらかい明滅Tween
			var row_tw = row.create_tween()
			row_tw.tween_property(row, "modulate", Color(1.2, 1.2, 1.2), 0.2)
			row_tw.tween_property(row, "modulate", Color.WHITE, 0.2)
			
			await get_tree().create_timer(0.4).timeout
			
		var rivals_box = row.find_child("RivalsBox", true, false)
		var player_box = row.find_child("PlayerBox", true, false)
		
		# ----------------------------------------------------
		# 1. ライバルの暴露 (GDD準拠: 決定論的単日データ再現)
		# ----------------------------------------------------
		var rival_names = ["慎重な優等生", "ギャンブラー", "ブラフの達人"]
		for r_name in rival_names:
			var r_reported = 0
			var r_actual = 0
			var is_lying = false
			var total_lie = 0
			
			# CPU行動パターンの決定論的再現 (BackendManagerのget_timeline_feedsに完全に準拠)
			if r_name == "慎重な優等生":
				r_reported = 50
				r_actual = 50
				is_lying = false
				total_lie = 0
			elif r_name == "ギャンブラー":
				if d == 3:
					r_reported = 48 # 実際30 + 数学盛り18
					r_actual = 30
					is_lying = true
					total_lie = 18
				elif d == 6:
					r_reported = 50 # 実際30 + 英語盛り20
					r_actual = 30
					is_lying = true
					total_lie = 20
				else:
					r_reported = 60
					r_actual = 60
					is_lying = false
					total_lie = 0
			elif r_name == "ブラフの達人":
				r_reported = 50 # 国語20, 理科20, 社会10
				r_actual = 40   # 国語15, 理科20, 社会5
				is_lying = true
				total_lie = 10
				
			# プレイヤーがタイムラインでこのライバルに「いいね(ダウト)」を送っていたか
			var voted = false
			var vote_key = "day_%d_%s" % [d, r_name]
			if Global.accumulated_votes.get(vote_key, false):
				voted = true
			
			# ライバルUIの構築
			var r_lbl = DeskTheme.create_label("%s: %d➔%d点" % [r_name.left(4), r_reported, r_actual], 15, DeskTheme.COLOR_CHALK_WHITE)
			rivals_box.add_child(r_lbl)
			
			var stamp_lbl: Control = null
			var score_diff = 0
			
			if voted:
				# プレイヤーがダウト(いいね)投票した場合
				if is_lying:
					# ダウト成功！ プレイヤー＋5点
					stamp_lbl = DeskTheme.create_mini_stamp("ダウト成功！", Color("ff6b6b"), 13)
					score_diff = 5
					player_doubt_success += 1
					if audio_manager: audio_manager.play_se("burst")
				else:
					# ダウト失敗(冤罪)！ プレイヤー－3点
					stamp_lbl = DeskTheme.create_mini_stamp("冤罪ペナ！", Color("868e96"), 13)
					score_diff = -3
					player_doubt_failed += 1
					if audio_manager: audio_manager.play_se("click")
			else:
				# プレイヤーがスルーした場合
				if is_lying:
					# 嘘つきをスルー ➔ プレイヤー加点なし。
					# CPU2人がダウトするかを確率シミュレートして完全犯罪の成否を判定
					var cpu_vote_count = 0
					var rng = RandomNumberGenerator.new()
					rng.seed = hash(r_name) + d + 888
					var detect_prob = clamp(total_lie * 0.15, 0.1, 0.8)
					for other_cpu in range(2):
						if rng.randf() < detect_prob:
							cpu_vote_count += 1
							
					if cpu_vote_count >= 2:
						# 見破られ (プレイヤーはダウトしていないが、他CPUに暴かれた)
						stamp_lbl = DeskTheme.create_mini_stamp("嘘バレ", Color("ff8787"), 12)
					else:
						# 完全犯罪成立 (ダウトが少なかった)
						stamp_lbl = DeskTheme.create_mini_stamp("完全犯罪！", Color("fab005"), 12)
				else:
					# 正直者をスルー ➔ お互い平和。加点なし
					stamp_lbl = DeskTheme.create_mini_stamp("信頼スルー", Color("40c057"), 12)
					
			if stamp_lbl != null:
				rivals_box.add_child(stamp_lbl)
				await _animate_stamp(stamp_lbl)
				
			if score_diff != 0:
				current_live_score = max(0, current_live_score + score_diff)
				_update_live_score_ui(score_diff)
				_trigger_mini_shake(abs(score_diff) * 1.5)
				
			if not is_skipped:
				await get_tree().create_timer(0.2).timeout
				
		# ----------------------------------------------------
		# 2. プレイヤー自身の暴露 (完全犯罪＆見破られ＆正直応援)
		# ----------------------------------------------------
		var player_lied = false
		var total_lie = 0
		for s in entry["subjects"]:
			var rep = entry["subjects"][s]
			var act = entry["actual_subjects"].get(s, rep)
			if rep > act:
				player_lied = true
				total_lie += (rep - act)
				
		var p_lbl_text = "あなた: 正直報告"
		if player_lied:
			p_lbl_text = "あなた: 嘘盛＋%d点" % total_lie
			player_lie_count += 1
			
		var p_lbl = DeskTheme.create_label(p_lbl_text, 15, DeskTheme.COLOR_CHALK_WHITE)
		player_box.add_child(p_lbl)
		
		var p_stamp: Control = null
		var p_score_diff = 0
		var is_perfect_crime = false
		
		if player_lied:
			# プレイヤーが嘘をついていた日：ライバル3名がプレイヤーにダウト(いいね)を刺したかを確率計算
			var p_seed = hash(Global.player_name) + d
			var p_rng = RandomNumberGenerator.new()
			p_rng.seed = p_seed
			
			var received_likes = 0
			# 慎重な優等生 (見破り率高め)
			if p_rng.randf() < clamp(total_lie * 0.18, 0.1, 0.85):
				received_likes += 1
			# ブラフの達人 (通常)
			if p_rng.randf() < clamp(total_lie * 0.15, 0.1, 0.80):
				received_likes += 1
			# ギャンブラー (見破り率低め)
			if p_rng.randf() < clamp(total_lie * 0.10, 0.05, 0.70):
				received_likes += 1
				
			if received_likes >= 2:
				# 2票以上で嘘見破られ確定！盛ったスコア没収 ＆ ペナルティ＝盛ったスコアの2倍
				p_stamp = DeskTheme.create_mini_stamp("見破られた！", DeskTheme.COLOR_BLUFF_RED, 14)
				p_score_diff = -(total_lie * 2)
				player_exposed_count += 1
				if audio_manager: audio_manager.play_se("burst")
				_trigger_mini_shake(12.0)
			else:
				# 1票以下で完全犯罪成立！嘘が通る
				p_stamp = DeskTheme.create_mini_stamp("完全犯罪！", Color("e8590c"), 14)
				p_score_diff = 0
				is_perfect_crime = true
				player_perfect_crimes += 1
				if audio_manager: audio_manager.play_se("combo")
		else:
			# 正直に報告していた日：ライバルからの誤ダウト(冤罪被弾)判定
			var p_seed = hash(Global.player_name) + d + 999
			var p_rng = RandomNumberGenerator.new()
			p_rng.seed = p_seed
			
			var received_likes = 0
			for i in range(3):
				if p_rng.randf() < 0.15: # 各ライバル15%の確率で誤ダウト
					received_likes += 1
					
			if received_likes > 0:
				# 誤ダウトされた ➔ 冤罪ボーナス: 1票につき＋3点
				p_stamp = DeskTheme.create_mini_stamp("正直証明＋%d" % (received_likes * 3), DeskTheme.COLOR_SAFE, 14)
				p_score_diff = received_likes * 3
				if audio_manager: audio_manager.play_se("combo")
			else:
				p_stamp = DeskTheme.create_mini_stamp("正直合格", Color("8fbf9f"), 14)
				p_score_diff = 0
				if audio_manager: audio_manager.play_se("place")
				
		player_box.add_child(p_stamp)
		await _animate_stamp(p_stamp)
		
		if is_perfect_crime:
			_spawn_confetti(player_box.global_position + Vector2(250, 40))
		
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
	board_overlay.add_child(next_btn)
	
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
	
	# 5教科の勝敗表
	var table_h = HBoxContainer.new()
	table_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_h.add_theme_constant_override("separation", 36)
	vbox.add_child(table_h)
	
	# 左列: 教科勝敗リスト (幅約500)
	var win_list_v = VBoxContainer.new()
	win_list_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	win_list_v.alignment = BoxContainer.ALIGNMENT_CENTER
	win_list_v.add_theme_constant_override("separation", 12)
	table_h.add_child(win_list_v)
	
	win_list_v.add_child(DeskTheme.create_label("【教科別トップ争い結果】", 22, DeskTheme.COLOR_INK, true))
	
	var bonus_added_subjects = []
	bonus_score = 0
	
	# デイリー教科1位ボーナスの教科別集計
	var daily_bonus_per_subject = {}
	for s in range(5):
		daily_bonus_per_subject[s] = 0
	for key in Global.daily_subject_top_bonus:
		var parts = str(key).split("_")
		if parts.size() >= 2:
			var subj = int(parts[1])
			if subj >= 0 and subj < 5:
				daily_bonus_per_subject[subj] += Global.daily_subject_top_bonus[key]
	
	for s in range(5):
		var row = VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		win_list_v.add_child(row)
		
		var row_h = HBoxContainer.new()
		row_h.add_theme_constant_override("separation", 12)
		row.add_child(row_h)
		
		var icon = DeskTheme.create_icon_rect(DeskTheme.subject_texture(s), Vector2(34, 34))
		row_h.add_child(icon)
		
		var name_lbl = DeskTheme.create_label(DeskTheme.subject_name(s), 18, DeskTheme.subject_color(s), true)
		name_lbl.custom_minimum_size = Vector2(60, 0)
		row_h.add_child(name_lbl)
		
		var top_player = backend_manager.get_top_player_for_subject(s)
		var top_name = top_player["name"]
		var top_sc = top_player["score"]
		
		var is_my_top = (top_name == Global.player_name)
		
		# シーズン教科トップボーナス (+20点)
		var result_text = ""
		var result_color = DeskTheme.COLOR_MUTED
		if is_my_top:
			result_text = "学年トップ! +20点"
			result_color = DeskTheme.COLOR_BLUFF_RED
			bonus_score += 20
			bonus_added_subjects.append(s)
		else:
			result_text = "1位: %s (%d点)" % [top_name, top_sc]
			result_color = DeskTheme.COLOR_INK
			
		var res_lbl = DeskTheme.create_label(result_text, 18, result_color, true)
		row_h.add_child(res_lbl)
		
		# デイリーボーナス行
		var d_bonus = daily_bonus_per_subject[s]
		if d_bonus > 0:
			var daily_count = d_bonus / 5
			var d_lbl = DeskTheme.create_label("  デイリー1位 x%d日 = +%d点" % [daily_count, d_bonus], 16, DeskTheme.COLOR_ACCENT_GOLD, true)
			row.add_child(d_lbl)
			bonus_score += d_bonus
	
	final_score = base_score + bonus_score
	
	# 右列: 総合成績通知表 (幅約380)
	var report_card = DeskTheme.create_sticky_note(Color("fffae6"), Vector2(380, 420), 1.0)
	report_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	table_h.add_child(report_card)
	
	var rc_v = VBoxContainer.new()
	rc_v.alignment = BoxContainer.ALIGNMENT_CENTER
	rc_v.add_theme_constant_override("separation", 12)
	report_card.add_child(rc_v)
	
	rc_v.add_child(DeskTheme.create_label("【成績分析】", 20, DeskTheme.COLOR_MUTED, true))
	
	var base_lbl = DeskTheme.create_label("素点合計: %d点" % base_score, 20, DeskTheme.COLOR_INK, true)
	rc_v.add_child(base_lbl)
	
	bonus_score_label = DeskTheme.create_label("トップボーナス: ＋0点", 20, DeskTheme.COLOR_INK, true)
	rc_v.add_child(bonus_score_label)
	
	final_score_label = DeskTheme.create_label("総合評価点: %d点" % base_score, 24, DeskTheme.COLOR_INK, true)
	rc_v.add_child(final_score_label)
	
	# ランク判定
	rank_label = DeskTheme.create_label("判定: F", 38, DeskTheme.COLOR_MUTED, true)
	rc_v.add_child(rank_label)
	
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
	
	# ゴールドスタンプ連打演出シーケンス (Tween)
	_run_stamp_sequence(bonus_added_subjects)

func _run_stamp_sequence(subjects: Array):
	await create_tween().tween_interval(0.6).finished
	
	# 自分がトップを取った教科の数だけ王冠スタンプを押す
	for s in subjects:
		var stamp = TextureRect.new()
		stamp.texture = DeskTheme.CROWN_TEXTURE
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stamp.custom_minimum_size = Vector2(50, 50)
		stamp.rotation_degrees = randf_range(-20, 20)
		stamp.scale = Vector2(4.0, 4.0)
		stamp.modulate.a = 0.0
		stamp.pivot_offset = Vector2(25, 25)
		
		# 対応する教科の行の末尾にスタンプを落とす
		var list_container = screen_content.get_child(0).get_node("Content/VBoxContainer/HBoxContainer/VBoxContainer")
		var target_row = list_container.get_child(s + 1) # ヘッダー分+1
		target_row.add_child(stamp)
		
		var tw = stamp.create_tween()
		tw.set_parallel(true)
		tw.tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BOUNCE)
		tw.tween_property(stamp, "modulate:a", 1.0, 0.15)
		
		if audio_manager: audio_manager.play_se("combo")
		
		# 画面シェイク
		var shake = create_tween().set_loops(3)
		shake.tween_callback(func(): ui_root.position = Vector2(randf_range(-4, 4), randf_range(-4, 4)))
		shake.tween_interval(0.04)
		await shake.finished
		ui_root.position = Vector2.ZERO
		
		await tw.finished
		await create_tween().tween_interval(0.4).finished
		
	# ボーナススコア表示をインクリメントしていくジューシーなTween
	if bonus_score > 0:
		var score_tw = create_tween()
		score_tw.tween_method(func(val):
			bonus_score_label.text = "トップボーナス: ＋%d点" % val
			bonus_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_ACCENT_GOLD)
			final_score_label.text = "総合評価点: %d点" % (base_score + val)
			if audio_manager: audio_manager.play_se("place")
		, 0, bonus_score, 0.6)
		
		await score_tw.finished
		
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
	for s in Global.daily_noises:
		Global.daily_noises[s] = 0
	Global.score_history.clear()
	Global.accumulated_votes.clear()
	Global.daily_subject_top_bonus.clear()
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

