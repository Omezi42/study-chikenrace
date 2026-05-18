# scripts/ui/phases/BagBuilderPhase.gd
class_name BagBuilderPhase
extends RefCounted

signal phase_completed()

var ctx: GameContext

# ドラッグ&ドロップ用の一時状態
var drag_data: Dictionary = {
	"active": false,
	"value": 0,
	"source": "", # "palette" or "slot"
	"subject": -1,
	"slot": -1,
	"node": null
}

func _init(context: GameContext):
	self.ctx = context

func start():
	_show_bag_builder()

func _show_bag_builder():
	ctx.screen_content.get_tree().call_group("ui_elements", "queue_free") # 古いUIのクリア
	
	ctx.bag_assignments.clear()
	for s in range(5):
		ctx.bag_assignments[s] = [null, null]
	
	# メインの横分割コンテナ (左: チキスタスマホ / 右: リングノート)
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 40)
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.offset_left = 40; main_hbox.offset_top = 40; main_hbox.offset_right = -40; main_hbox.offset_bottom = -40
	ctx.screen_content.add_child(main_hbox)
	
	# ==========================================
	# 左側: 教室の机に置かれた「スマートフォン (チキスタアプリ)」
	# ==========================================
	var phone_container = Control.new()
	phone_container.custom_minimum_size = Vector2(400, 0)
	phone_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(phone_container)
	
	var app_container = SmartphoneBuilder.create_mockup(ctx, false)
	
	# 1. アプリヘッダー
	var app_header = PanelContainer.new()
	app_header.custom_minimum_size = Vector2(0, 52)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color("ffffff")
	header_style.border_width_bottom = 2
	header_style.border_color = Color("e1e4e6")
	app_header.add_theme_stylebox_override("panel", header_style)
	app_container.add_child(app_header)
	
	var app_header_h = HBoxContainer.new()
	app_header_h.add_theme_constant_override("separation", 8)
	app_header_h.alignment = BoxContainer.ALIGNMENT_CENTER
	app_header.add_child(app_header_h)
	
	var app_icon = ColorRect.new()
	app_icon.custom_minimum_size = Vector2(28, 28)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = DeskTheme.COLOR_SAFE
	icon_style.corner_radius_top_left = 8; icon_style.corner_radius_top_right = 8
	icon_style.corner_radius_bottom_left = 8; icon_style.corner_radius_bottom_right = 8
	app_icon.add_theme_stylebox_override("panel", icon_style)
	app_header_h.add_child(app_icon)
	
	var app_icon_lbl = DeskTheme.create_label("S", 14, Color.WHITE)
	app_icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app_icon.add_child(app_icon_lbl)
	
	var app_title = DeskTheme.create_label("チキスタ !", 18, DeskTheme.COLOR_SAFE, true)
	app_header_h.add_child(app_title)
	
	# 2. アプリ内メインスクロールエリア
	var app_scroll = ScrollContainer.new()
	app_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app_container.add_child(app_scroll)
	
	# 初期のタイムライン表示
	var feed_v = VBoxContainer.new()
	feed_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_v.add_theme_constant_override("separation", 10)
	app_scroll.add_child(feed_v)
	ctx.chikista_active_tab = 0
	SmartphoneBuilder._build_timeline_feed(ctx, feed_v)
	
	# 3. ボトムナビゲーションバー
	var app_footer = PanelContainer.new()
	app_footer.custom_minimum_size = Vector2(0, 60)
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = Color("f8f9fa")
	footer_style.border_width_top = 2
	footer_style.border_color = Color("e1e4e6")
	app_footer.add_theme_stylebox_override("panel", footer_style)
	app_container.add_child(app_footer)
	
	var app_footer_h = HBoxContainer.new()
	app_footer_h.alignment = BoxContainer.ALIGNMENT_CENTER
	app_footer_h.add_theme_constant_override("separation", 16)
	app_footer.add_child(app_footer_h)
	
	var tabs_info = [
		{"text": "タイムライン", "idx": 0},
		{"text": "学習分析", "idx": 1},
		{"text": "目標", "idx": 2}
	]
	
	for tab in tabs_info:
		var tab_btn = Button.new()
		tab_btn.text = tab["text"]
		tab_btn.custom_minimum_size = Vector2(110, 48)
		tab_btn.add_theme_font_override("font", DeskTheme.DEFAULT_FONT)
		tab_btn.add_theme_font_size_override("font_size", 13)
		tab_btn.add_theme_color_override("font_color", DeskTheme.COLOR_MUTED)
		
		var b_normal = StyleBoxFlat.new()
		b_normal.bg_color = Color(0,0,0,0)
		b_normal.corner_radius_top_left = 8; b_normal.corner_radius_top_right = 8
		b_normal.corner_radius_bottom_left = 8; b_normal.corner_radius_bottom_right = 8
		tab_btn.add_theme_stylebox_override("normal", b_normal)
		
		var b_hover = StyleBoxFlat.new()
		b_hover.bg_color = Color(0.9, 0.9, 0.92, 0.5)
		b_hover.corner_radius_top_left = 8; b_hover.corner_radius_top_right = 8
		b_hover.corner_radius_bottom_left = 8; b_hover.corner_radius_bottom_right = 8
		tab_btn.add_theme_stylebox_override("hover", b_hover)
		
		var b_pressed = StyleBoxFlat.new()
		b_pressed.bg_color = Color(0.85, 0.85, 0.88)
		b_pressed.corner_radius_top_left = 8; b_pressed.corner_radius_top_right = 8
		b_pressed.corner_radius_bottom_left = 8; b_pressed.corner_radius_bottom_right = 8
		tab_btn.add_theme_stylebox_override("pressed", b_pressed)
		
		tab_btn.pressed.connect(SmartphoneBuilder.on_chikista_tab_pressed.bind(ctx, tab["idx"], app_scroll))
		app_footer_h.add_child(tab_btn)
		
	# ==========================================
	# 右側: カバン構築用 見開きリングノートUI
	# ==========================================
	var note_panel = NotebookBuilder.create()
	ctx.active_notebook = note_panel
	main_hbox.add_child(note_panel)
	
	var left_margin = note_panel.find_child("LeftContent", true, false) as MarginContainer
	var right_margin = note_panel.find_child("RightContent", true, false) as MarginContainer
	
	# ---------------- Left Page Content ----------------
	var left_content = VBoxContainer.new()
	left_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_content.add_theme_constant_override("separation", 24)
	left_margin.add_child(left_content)
	
	# カレンダーと手書きヘッダー
	var cal_h = HBoxContainer.new()
	cal_h.add_theme_constant_override("separation", 12)
	left_content.add_child(cal_h)
	
	var day_num = 1
	if is_instance_valid(ctx.game_session):
		day_num = ctx.game_session.current_day
	var cal_lbl = DeskTheme.create_label("📅 %d日目 / 7日中" % day_num, 20, DeskTheme.COLOR_INK, true)
	cal_h.add_child(cal_lbl)
	
	# 計画計画のタイトル
	var title_lbl = DeskTheme.create_label("✏️ 今日のカバンの中身（学習計画）", 26, DeskTheme.COLOR_INK, true)
	left_content.add_child(title_lbl)
	
	# 指示書き
	var desc_lbl = DeskTheme.create_label("下の手書きの「重り」を、教科のスロットへドラッグ＆ドロップして学習計画を立てましょう。\n計画ができたら右下の【通学開始！】ボタンを押して、今日の勉強チキンレースに挑みます！", 14, DeskTheme.COLOR_MUTED)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_content.add_child(desc_lbl)
	
	# 重りパレット
	var pal_lbl = DeskTheme.create_label("▼ 勉強の「重り」パレット (ドラッグしてカバンに入れてね)", 13, DeskTheme.COLOR_MUTED)
	left_content.add_child(pal_lbl)
	
	var weights_grid = GridContainer.new()
	weights_grid.columns = 4
	weights_grid.add_theme_constant_override("h_separation", 24)
	weights_grid.add_theme_constant_override("v_separation", 16)
	left_content.add_child(weights_grid)
	
	var weights = [10, 20, 30, 40, 50, 60, 70, 80]
	for w in weights:
		var w_panel = PanelContainer.new()
		w_panel.custom_minimum_size = Vector2(110, 76)
		
		var w_style = StyleBoxFlat.new()
		w_style.bg_color = Color("faf8f5")
		w_style.border_width_left = 2; w_style.border_width_top = 2
		w_style.border_width_right = 2; w_style.border_width_bottom = 4
		w_style.border_color = Color("c2b29d")
		w_style.corner_radius_top_left = 12; w_style.corner_radius_top_right = 12
		w_style.corner_radius_bottom_left = 12; w_style.corner_radius_bottom_right = 12
		w_style.content_margin_left = 8; w_style.content_margin_right = 8
		w_style.content_margin_top = 6; w_style.content_margin_bottom = 6
		
		# ドロップシャドウ
		w_style.shadow_color = Color(0,0,0, 0.08)
		w_style.shadow_size = 5
		w_style.shadow_offset = Vector2(2, 4)
		w_panel.add_theme_stylebox_override("panel", w_style)
		weights_grid.add_child(w_panel)
		
		# 手書きふせんデザイン (付箋感)
		var w_v = VBoxContainer.new()
		w_v.alignment = BoxContainer.ALIGNMENT_CENTER
		w_panel.add_child(w_v)
		
		var w_lbl = DeskTheme.create_label(str(w) + "g", 24, DeskTheme.COLOR_INK, true)
		w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		w_v.add_child(w_lbl)
		
		var label_text = "極軽"
		if w >= 80: label_text = "極重"
		elif w >= 60: label_text = "激重"
		elif w >= 40: label_text = "普通"
		elif w >= 20: label_text = "軽め"
		var sub_lbl = DeskTheme.create_label(label_text, 11, DeskTheme.COLOR_MUTED)
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		w_v.add_child(sub_lbl)
		
		w_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		w_panel.gui_input.connect(_on_weight_gui_input.bind(w))
		ctx.bag_ui_elements["palette_" + str(w)] = w_panel
		
	# ---------------- Right Page Content ----------------
	var right_content = VBoxContainer.new()
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_content.add_theme_constant_override("separation", 20)
	right_margin.add_child(right_content)
	
	# カバンヘッダー
	var right_header_h = HBoxContainer.new()
	right_header_h.alignment = BoxContainer.ALIGNMENT_BEGIN
	right_content.add_child(right_header_h)
	
	right_header_h.add_child(DeskTheme.create_label("🎒 カバンの中身スロット (最大2個/教科)", 20, DeskTheme.COLOR_INK, true))
	
	# カバンスロットリスト
	var slots_v = VBoxContainer.new()
	slots_v.add_theme_constant_override("separation", 14)
	right_content.add_child(slots_v)
	
	for s in range(5):
		var s_row = PanelContainer.new()
		var s_style = StyleBoxFlat.new()
		s_style.bg_color = Color("ffffff")
		s_style.corner_radius_top_left = 12; s_style.corner_radius_top_right = 12
		s_style.corner_radius_bottom_left = 12; s_style.corner_radius_bottom_right = 12
		s_style.content_margin_left = 16; s_style.content_margin_right = 16
		s_style.content_margin_top = 10; s_style.content_margin_bottom = 10
		
		# 微細なシャドウで浮かせる
		s_style.shadow_color = Color(0,0,0, 0.04)
		s_style.shadow_size = 4
		s_style.shadow_offset = Vector2(1, 2)
		s_row.add_theme_stylebox_override("panel", s_style)
		slots_v.add_child(s_row)
		
		var s_hbox = HBoxContainer.new()
		s_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		s_hbox.add_theme_constant_override("separation", 16)
		s_row.add_child(s_hbox)
		
		# 教科表示
		var sub_info_h = HBoxContainer.new()
		sub_info_h.custom_minimum_size = Vector2(150, 0)
		sub_info_h.add_theme_constant_override("separation", 10)
		s_hbox.add_child(sub_info_h)
		
		var sub_tex = DeskTheme.subject_texture(s)
		sub_info_h.add_child(DeskTheme.create_icon_rect(sub_tex, Vector2(38, 38)))
		
		var sub_lbl_v = VBoxContainer.new()
		sub_lbl_v.alignment = BoxContainer.ALIGNMENT_CENTER
		sub_info_h.add_child(sub_lbl_v)
		
		sub_lbl_v.add_child(DeskTheme.create_label(DeskTheme.subject_name(s), 18, DeskTheme.COLOR_INK, true))
		var sub_col_lbl = DeskTheme.create_label("目標: 20点", 11, DeskTheme.COLOR_MUTED)
		sub_lbl_v.add_child(sub_col_lbl)
		
		# スロット1 & スロット2 (3D巨大スロット)
		for slot in range(2):
			var slot_panel = PanelContainer.new()
			slot_panel.custom_minimum_size = Vector2(110, 56)
			
			var slot_style = StyleBoxFlat.new()
			slot_style.bg_color = Color("f5f4f0")
			slot_style.border_width_left = 3; slot_style.border_width_top = 3
			slot_style.border_width_right = 3; slot_style.border_width_bottom = 3
			slot_style.border_color = Color("d3cbbf")
			slot_style.corner_radius_top_left = 10; slot_style.corner_radius_top_right = 10
			slot_style.corner_radius_bottom_left = 10; slot_style.corner_radius_bottom_right = 10
			
			slot_panel.add_theme_stylebox_override("panel", slot_style)
			s_hbox.add_child(slot_panel)
			
			var slot_lbl = DeskTheme.create_label("計画なし", 12, Color("bdae9c"))
			slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot_panel.add_child(slot_lbl)
			
			slot_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			slot_panel.gui_input.connect(_on_slot_gui_input.bind(s, slot))
			ctx.bag_ui_elements["slot_%d_%d" % [s, slot]] = slot_panel
			
	# 下部フッター
	var footer_hbox = HBoxContainer.new()
	footer_hbox.alignment = BoxContainer.ALIGNMENT_END
	right_content.add_child(footer_hbox)
	
	var start_btn = DeskTheme.create_button("通学開始！ 🎒", Vector2(240, 56), DeskTheme.COLOR_SAFE, Color("1b8a4f"), true, 20)
	start_btn.pressed.connect(_on_start_race_pressed)
	footer_hbox.add_child(start_btn)
	
	_update_bag_ui()
	
	# 【翌日朝の会】いいね被弾判定演出の自動開始 (0.5秒後)
	var timer = ctx.screen_content.get_tree().create_timer(0.5)
	timer.timeout.connect(func():
		var likes_phase = DailyLikesPhase.new(ctx)
		likes_phase.phase_completed.connect(func():
			_update_bag_ui() # 完了後にHUDの点数などを再同期
		)
		likes_phase.start()
	)

func _on_weight_gui_input(event: InputEvent, weight: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(weight, "palette")

func _on_slot_gui_input(event: InputEvent, subject: int, slot: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# すでにスロットに何かあればそれをドラッグ開始
				var cur_val = ctx.bag_assignments[subject][slot]
				if cur_val != null:
					_start_drag(cur_val, "slot", subject, slot)

func _start_drag(value: int, source: String, subject: int = -1, slot: int = -1):
	if drag_data["active"]: return
	
	drag_data["active"] = true
	drag_data["value"] = value
	drag_data["source"] = source
	drag_data["subject"] = subject
	drag_data["slot"] = slot
	
	# ドラッグ中の浮遊ビジュアルノード作成
	var drag_node = PanelContainer.new()
	drag_node.custom_minimum_size = Vector2(100, 60)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("faf8f5", 0.9)
	style.border_width_left = 2; style.border_width_top = 2
	style.border_width_right = 2; style.border_width_bottom = 4
	style.border_color = Color("c2b29d")
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	drag_node.add_theme_stylebox_override("panel", style)
	
	var lbl = DeskTheme.create_label(str(value) + "g", 20, DeskTheme.COLOR_INK, true)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_node.add_child(lbl)
	
	ctx.ui_root.add_child(drag_node)
	drag_node.z_index = 200
	drag_data["node"] = drag_node
	
	# 元のスロットやパレットから一時的に見た目を薄くするなどの処理
	if source == "slot":
		ctx.bag_assignments[subject][slot] = null
		_update_bag_ui()
		
	if ctx.audio_manager:
		ctx.audio_manager.play_se("draw")
		
	# ドラッグ追従処理
	_update_drag_position()
	
	# ドラッグループ用ポーリング開始
	var timer = Timer.new()
	timer.name = "DragTimer"
	timer.wait_time = 0.016
	timer.autostart = true
	timer.timeout.connect(_on_drag_poll)
	ctx.ui_root.add_child(timer)

func _update_drag_position():
	if drag_data["node"]:
		var mouse_pos = ctx.ui_root.get_local_mouse_position()
		drag_data["node"].position = mouse_pos - Vector2(50, 30) # ピボット調整

func _on_drag_poll():
	if not drag_data["active"]:
		var timer = ctx.ui_root.find_child("DragTimer")
		if timer: timer.queue_free()
		return
		
	_update_drag_position()
	_update_drag_hover()
	
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_drag()

func _update_drag_hover():
	# ホバー時のスロットの強調表示などのおもちゃ感フィードバック
	var mouse_pos = ctx.ui_root.get_local_mouse_position()
	for s in range(5):
		for slot in range(2):
			var key = "slot_%d_%d" % [s, slot]
			var panel = ctx.bag_ui_elements.get(key)
			if panel and is_instance_valid(panel):
				var rect = panel.get_global_rect()
				var local_mouse = panel.get_global_mouse_position()
				if rect.has_point(local_mouse):
					var style = panel.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
					style.border_color = DeskTheme.COLOR_SAFE
					style.bg_color = Color("eef9f3")
					panel.add_theme_stylebox_override("panel", style)
				else:
					var style = panel.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
					style.border_color = Color("d3cbbf")
					style.bg_color = Color("f5f4f0")
					panel.add_theme_stylebox_override("panel", style)

func _end_drag():
	drag_data["active"] = false
	if drag_data["node"]:
		drag_data["node"].queue_free()
		drag_data["node"] = null
		
	# ドロップ位置判定
	var dropped_on_slot = false
	var target_subject = -1
	var target_slot = -1
	
	for s in range(5):
		for slot in range(2):
			var key = "slot_%d_%d" % [s, slot]
			var panel = ctx.bag_ui_elements.get(key)
			if panel and is_instance_valid(panel):
				var rect = panel.get_global_rect()
				var local_mouse = panel.get_global_mouse_position()
				if rect.has_point(local_mouse):
					dropped_on_slot = true
					target_subject = s
					target_slot = slot
					break
		if dropped_on_slot: break
		
	if dropped_on_slot:
		# 対象スロットの置き換え
		var prev_val = ctx.bag_assignments[target_subject][target_slot]
		# すでに他のスロットに同じ重りがあれば重複配置を避けるため消去
		_remove_weight_from_assignments(drag_data["value"])
		
		ctx.bag_assignments[target_subject][target_slot] = drag_data["value"]
		
		if ctx.audio_manager:
			ctx.audio_manager.play_se("place")
	else:
		# スロット外に落とした場合、元のソースがスロットなら何もしない（すでに消えているのでパレットに戻る）
		if ctx.audio_manager:
			ctx.audio_manager.play_se("place")
			
	_update_bag_ui()

func _remove_weight_from_assignments(value: int):
	for s in range(5):
		for slot in range(2):
			if ctx.bag_assignments[s][slot] == value:
				ctx.bag_assignments[s][slot] = null

func _update_bag_ui():
	# 全スロットを現在の割り当てに同期
	for s in range(5):
		for slot in range(2):
			var key = "slot_%d_%d" % [s, slot]
			var panel = ctx.bag_ui_elements.get(key)
			if panel and is_instance_valid(panel):
				var val = ctx.bag_assignments[s][slot]
				var lbl = panel.get_child(0) as Label
				
				# 既存のスタイル複製
				var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
				
				if val != null:
					lbl.text = str(val) + "g"
					lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
					
					style.bg_color = Color("faf8f5") # 割り当てあり
					style.border_color = Color("c2b29d")
					
					# ゴムスタンプ風の「ペチッ」としたTweenアニメーション
					if not panel.has_meta("has_element") or panel.get_meta("has_element") != val:
						panel.set_meta("has_element", val)
						panel.pivot_offset = panel.size / 2.0
						panel.scale = Vector2(1.15, 1.15)
						var tw = panel.create_tween()
						tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				else:
					lbl.text = "計画なし"
					lbl.add_theme_color_override("font_color", Color("bdae9c"))
					
					style.bg_color = Color("f5f4f0") # 空白
					style.border_color = Color("d3cbbf")
					panel.set_meta("has_element", null)
					
				panel.add_theme_stylebox_override("panel", style)

func _on_start_race_pressed():
	# 各スロットが設定されているか確認（最低1つは必要）
	var count = 0
	for s in range(5):
		for slot in range(2):
			if ctx.bag_assignments[s][slot] != null:
				count += 1
				
	if count == 0:
		ToastOverlay.show_toast(ctx.ui_root, "最低1つの教科に「重り」を設定してください！", DeskTheme.COLOR_BLUFF_RED)
		if ctx.audio_manager:
			ctx.audio_manager.play_se("place") # エラーSE代わり
		return
		
	if ctx.audio_manager:
		ctx.audio_manager.play_se("click")
		
	# フェーズ終了シグナル発火
	phase_completed.emit()
