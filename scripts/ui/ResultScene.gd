class_name ResultScene
extends Control

const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")

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
	final_score = base_score
	
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
	_show_final_report()

func _show_final_report():
	for child in screen_content.get_children():
		child.queue_free()
		
	var page = DeskTheme.create_notebook_panel(Vector2(920, 680), 64, 48, 64, 32)
	page.anchor_left = 0.5; page.anchor_top = 0.5; page.anchor_right = 0.5; page.anchor_bottom = 0.5
	page.offset_left = -460; page.offset_top = -340; page.offset_right = 460; page.offset_bottom = 340
	screen_content.add_child(page)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 18)
	DeskTheme.apply_font(vbox)
	page.get_node("Content").add_child(vbox)
	
	vbox.add_child(DeskTheme.create_label("学末最終通知表", 36, DeskTheme.COLOR_INK, true))
	vbox.add_child(DeskTheme.create_label("名前: " + Global.player_name, 18, DeskTheme.COLOR_INK, true))
	
	# 5教科の勝敗表
	var table_h = HBoxContainer.new()
	table_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_h.add_theme_constant_override("separation", 24)
	vbox.add_child(table_h)
	
	# 左列: 教科勝敗リスト (幅約500)
	var win_list_v = VBoxContainer.new()
	win_list_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	win_list_v.alignment = BoxContainer.ALIGNMENT_CENTER
	win_list_v.add_theme_constant_override("separation", 8)
	table_h.add_child(win_list_v)
	
	win_list_v.add_child(DeskTheme.create_label("【教科別トップ争い結果】", 16, DeskTheme.COLOR_INK))
	
	var bonus_added_subjects = []
	bonus_score = 0
	
	for s in range(5):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		win_list_v.add_child(row)
		
		var icon = DeskTheme.create_icon_rect(DeskTheme.subject_texture(s), Vector2(32, 32))
		row.add_child(icon)
		
		var name_lbl = DeskTheme.create_label(DeskTheme.subject_name(s), 16, DeskTheme.subject_color(s))
		name_lbl.custom_minimum_size = Vector2(50, 0)
		row.add_child(name_lbl)
		
		var top_player = backend_manager.get_top_player_for_subject(s)
		var top_name = top_player["name"]
		var top_sc = top_player["score"]
		
		# 自分が1位か判定 (モックと通信データ両対応)
		# テストのため、自分がトップの場合や、スコアが0より大きくて自分がトップ扱いの場合にボーナスを付与
		var is_my_top = (top_name == Global.player_name)
		
		var result_text = ""
		var result_color = DeskTheme.COLOR_MUTED
		if is_my_top:
			result_text = "学年トップ！(＋10点)"
			result_color = DeskTheme.COLOR_BLUFF_RED
			bonus_score += 10
			bonus_added_subjects.append(s)
		else:
			result_text = "暫定トップ: %s (%d点)" % [top_name, top_sc]
			result_color = DeskTheme.COLOR_INK
			
		var res_lbl = DeskTheme.create_label(result_text, 15, result_color)
		row.add_child(res_lbl)
		
	final_score = base_score + bonus_score
	
	# 右列: 総合成績通知表 (幅約320)
	var report_card = DeskTheme.create_sticky_note(Color("fffae6"), Vector2(300, 320), 1.0)
	report_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	table_h.add_child(report_card)
	
	var rc_v = VBoxContainer.new()
	rc_v.alignment = BoxContainer.ALIGNMENT_CENTER
	rc_v.add_theme_constant_override("separation", 8)
	report_card.add_child(rc_v)
	
	rc_v.add_child(DeskTheme.create_label("【総評】", 16, DeskTheme.COLOR_MUTED, true))
	
	var base_lbl = DeskTheme.create_label("素点合計: %d点" % base_score, 18, DeskTheme.COLOR_INK, true)
	rc_v.add_child(base_lbl)
	
	bonus_score_label = DeskTheme.create_label("トップボーナス: ＋0点", 18, DeskTheme.COLOR_INK, true)
	rc_v.add_child(bonus_score_label)
	
	final_score_label = DeskTheme.create_label("総合評価点: %d点" % base_score, 24, DeskTheme.COLOR_INK, true)
	rc_v.add_child(final_score_label)
	
	# ランク判定
	rank_label = DeskTheme.create_label("判定: F", 36, DeskTheme.COLOR_MUTED, true)
	rc_v.add_child(rank_label)
	
	# タイトルに戻るボタン
	var close_btn = DeskTheme.create_button("シーズンを終了してタイトルへ", Vector2(360, 72), DeskTheme.COLOR_SAFE, Color("2d928a"))
	close_btn.pressed.connect(_on_title_pressed)
	vbox.add_child(close_btn)
	
	DeskTheme.animate_entrance(page)
	
	# ゴールドスタンプ連打演出シーケンス (Tween)
	_run_stamp_sequence(bonus_added_subjects)

func _run_stamp_sequence(subjects: Array):
	await create_tween().tween_interval(0.6).finished
	
	# 自分がトップを取った教科の数だけ王冠スタンプを押す
	for s in subjects:
		# 王冠スタンプ表示
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
		hanamaru.position = Vector2(-50, -100) # 位置微調整
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
	Global.save_data()
	
	SceneTransition.fade_to_scene("res://Title.tscn")
