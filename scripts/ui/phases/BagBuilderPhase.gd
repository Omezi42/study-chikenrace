# scripts/ui/phases/BagBuilderPhase.gd
class_name BagBuilderPhase
extends RefCounted
const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")
const DailyLikesPhaseScript = preload("res://scripts/ui/phases/DailyLikesPhase.gd")

signal phase_completed()

var ctx: RefCounted

# 付箋カラー定義 (旧版の10色Post-itパレット)
const POSTIT_COLORS = [
	Color("ffd43b"), Color("ff6b6b"), Color("339af0"), Color("51cf66"), Color("cc5de8"),
	Color("ff922b"), Color("f06595"), Color("20c997"), Color("5c7cfa"), Color("845ef7")
]

# タップ選択用の状態
var selected_bag_subject: int = 8
var selected_bag_slot: int = -1
var active_likes_phase: RefCounted = null

# ドラッグ&ドロップ用の一時状態
var drag_data: Dictionary = {"active": false, "value": 0, "source": "", "subject": -1, "slot": -1, "node": null}
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_threshold: float = 10.0
var has_dragged: bool = false
var hovered_slot_subject: int = -1
var hovered_slot_idx: int = -1
var drag_helper: Node

# グローバル入力を監視するための一時ノード
class DragHelper extends Node:
	var phase: RefCounted
	func _input(event: InputEvent):
		if phase:
			phase._handle_global_input(event)

func _init(context: RefCounted):
	self.ctx = context

func start():
	_show_bag_builder()

func _show_bag_builder():
	for child in ctx.screen_content.get_children():
		child.queue_free()
	
	# 初回起動時のみ初期化を行い、2日目以降は配置を維持して引き継ぐ
	if ctx.bag_assignments.is_empty():
		for s in range(5):
			ctx.bag_assignments[s] = [null, null]
	
	# ドラッグ＆ドロップ監視ヘルパーの起動
	if is_instance_valid(drag_helper):
		drag_helper.queue_free()
	drag_helper = DragHelper.new()
	drag_helper.phase = self
	ctx.ui_root.add_child(drag_helper)
	
	# === カバン構築用 見開きリングノートUIを先に追加（手前に入力レイヤーを置くための順序調整） ===
	var note_panel = NotebookBuilderScript.create()
	ctx.active_notebook = note_panel
	note_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note_panel.offset_left = 420.0 # 少し右寄りに配置してスマホと被らないようにする
	note_panel.offset_top = 80.0
	note_panel.offset_right = -120.0
	note_panel.offset_bottom = -80.0
	ctx.screen_content.add_child(note_panel)
	
	SmartphoneBuilderScript.build_standard_smartphone(ctx)
	
	var left_margin = note_panel.find_child("LeftContent", true, false) as MarginContainer
	var right_margin = note_panel.find_child("RightContent", true, false) as MarginContainer
	
	# ---- Left Page: カレンダー + 教科スロット一覧 ----
	var left_content = VBoxContainer.new()
	left_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_content.add_theme_constant_override("separation", 24)
	left_margin.add_child(left_content)
	
	var cal_h = HBoxContainer.new()
	cal_h.add_theme_constant_override("separation", 16)
	left_content.add_child(cal_h)
	
	var cal_note = TextureRect.new()
	cal_note.texture = DeskTheme.CALENDAR_TEXTURE
	cal_note.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cal_note.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cal_note.custom_minimum_size = Vector2(90, 90)
	cal_note.rotation_degrees = -4.0
	cal_h.add_child(cal_note)
	
	var cal_v = VBoxContainer.new()
	cal_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cal_v.alignment = BoxContainer.ALIGNMENT_CENTER
	cal_v.position.y += 8
	cal_note.add_child(cal_v)
	cal_v.add_child(DeskTheme.create_label("Day", 15, DeskTheme.COLOR_MUTED, true))
	cal_v.add_child(DeskTheme.create_label(str(Global.play_count + 1), 38, Color("d94040"), true))
	
	var title_lbl = DeskTheme.create_label("[ 今週の学習計画ノート ]", 34, DeskTheme.COLOR_INK, true)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cal_h.add_child(title_lbl)
	
	# カバンスロットリスト（5教科×2スロット）
	var pockets_v = VBoxContainer.new()
	pockets_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pockets_v.add_theme_constant_override("separation", 26)
	left_content.add_child(pockets_v)
	
	ctx.bag_ui_elements["slots"] = {}
	for s in range(5):
		var pocket_h = HBoxContainer.new()
		pocket_h.add_theme_constant_override("separation", 16)
		pockets_v.add_child(pocket_h)
		
		var p_header = DeskTheme.create_stat_chip(DeskTheme.subject_name(s), DeskTheme.subject_color(s), 18)
		p_header.custom_minimum_size = Vector2(92, 44)
		pocket_h.add_child(p_header)
		
		var icon = DeskTheme.create_icon_rect(DeskTheme.subject_texture(s), Vector2(44, 44))
		pocket_h.add_child(icon)
		
		var slot_btns = []
		for i in range(2):
			var slot_btn = Button.new()
			slot_btn.custom_minimum_size = Vector2(150, 88)
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color("ffffff", 0.8)
			btn_style.border_width_left = 2; btn_style.border_width_right = 2
			btn_style.border_width_top = 2; btn_style.border_width_bottom = 4
			btn_style.border_color = DeskTheme.COLOR_MUTED
			btn_style.corner_radius_top_left = 8; btn_style.corner_radius_top_right = 8
			btn_style.corner_radius_bottom_left = 8; btn_style.corner_radius_bottom_right = 8
			slot_btn.add_theme_stylebox_override("normal", btn_style)
			slot_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			slot_btn.add_theme_font_size_override("font_size", 32)
			slot_btn.add_theme_font_override("font", DeskTheme.DEFAULT_FONT)
			slot_btn.pressed.connect(_on_bag_slot_pressed.bind(s, i))
			slot_btn.gui_input.connect(_on_slot_gui_input.bind(s, i))
			pocket_h.add_child(slot_btn)
			slot_btns.append(slot_btn)
			# ホバー時のボヨヨン拡大
			slot_btn.pivot_offset = Vector2(75, 44)
			slot_btn.mouse_entered.connect(func():
				slot_btn.pivot_offset = slot_btn.size / 2.0
				var tw = slot_btn.create_tween()
				tw.tween_property(slot_btn, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			)
			slot_btn.mouse_exited.connect(func():
				var tw = slot_btn.create_tween()
				tw.tween_property(slot_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			)
		ctx.bag_ui_elements["slots"][s] = slot_btns
	
	# ---- Right Page: 数字付箋パレット ----
	var right_content = VBoxContainer.new()
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_content.add_theme_constant_override("separation", 20)
	right_margin.add_child(right_content)
	
	var rp_header = VBoxContainer.new()
	rp_header.add_theme_constant_override("separation", 6)
	right_content.add_child(rp_header)
	rp_header.add_child(DeskTheme.create_label("[ 数字付箋パレット ]", 32, DeskTheme.COLOR_INK, true))
	
	var placement_h = HBoxContainer.new()
	placement_h.alignment = BoxContainer.ALIGNMENT_CENTER
	placement_h.add_theme_constant_override("separation", 8)
	rp_header.add_child(placement_h)
	
	placement_h.add_child(DeskTheme.create_label("付箋を選んでスロットに貼ろう！", 15, DeskTheme.COLOR_MUTED, true))
	
	var placed_counter = DeskTheme.create_label("配置: 0/10", 15, DeskTheme.COLOR_SAFE, true)
	placement_h.add_child(placed_counter)
	ctx.bag_ui_elements["placed_counter"] = placed_counter
	
	var grid_center = CenterContainer.new()
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_content.add_child(grid_center)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	grid_center.add_child(grid)
	
	ctx.bag_ui_elements["weights"] = {}
	for w in range(1, 11):
		var btn = Button.new()
		btn.text = str(w)
		btn.custom_minimum_size = Vector2(110, 110)
		btn.add_theme_font_override("font", DeskTheme.DEFAULT_FONT)
		btn.add_theme_font_size_override("font_size", 42)
		btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		btn.add_theme_color_override("font_hover_color", DeskTheme.COLOR_INK)
		btn.add_theme_color_override("font_pressed_color", DeskTheme.COLOR_INK)
		btn.add_theme_color_override("font_disabled_color", Color("868e96"))
		var sticky_style = StyleBoxFlat.new()
		var postit_col = POSTIT_COLORS[w - 1]
		sticky_style.bg_color = postit_col
		sticky_style.corner_radius_top_left = 2; sticky_style.corner_radius_top_right = 2
		sticky_style.corner_radius_bottom_left = 6; sticky_style.corner_radius_bottom_right = 6
		sticky_style.shadow_color = Color(0, 0, 0, 0.16)
		sticky_style.shadow_size = 6
		sticky_style.shadow_offset = Vector2(2, 4)
		btn.add_theme_stylebox_override("normal", sticky_style)
		var sticky_hov = sticky_style.duplicate()
		sticky_hov.bg_color = postit_col.lightened(0.06)
		sticky_hov.shadow_size = 10
		btn.add_theme_stylebox_override("hover", sticky_hov)
		var sticky_prs = sticky_style.duplicate()
		sticky_prs.bg_color = postit_col.darkened(0.06)
		sticky_prs.shadow_size = 3
		btn.add_theme_stylebox_override("pressed", sticky_prs)
		btn.pressed.connect(_on_bag_weight_pressed.bind(w))
		btn.gui_input.connect(_on_weight_gui_input.bind(w))
		grid.add_child(btn)
		btn.pivot_offset = Vector2(55, 55)
		btn.rotation_degrees = randf_range(-6.0, 6.0)
		ctx.bag_ui_elements["weights"][w] = btn
		# 付箋のプルプルおもちゃホバー
		btn.mouse_entered.connect(func():
			if btn.disabled: return
			btn.pivot_offset = btn.size / 2.0
			var random_rot = randf_range(-0.06, 0.06)
			var tw = btn.create_tween().set_parallel(true)
			tw.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.08).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(btn, "rotation", random_rot, 0.1).set_trans(Tween.TRANS_BACK)
		)
		btn.mouse_exited.connect(func():
			var tw = btn.create_tween().set_parallel(true)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(btn, "rotation", deg_to_rad(btn.rotation_degrees), 0.1).set_trans(Tween.TRANS_CUBIC)
		)
	
	# 右ページ下部の開始ボタン（ハンコ風スタンプ）
	var footer_center = CenterContainer.new()
	right_content.add_child(footer_center)
	var start_btn = DeskTheme.create_button("チキンレース開始！", Vector2(280, 64), DeskTheme.COLOR_SAFE, Color("2d928a"))
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.pressed.connect(_on_start_race_pressed)
	footer_center.add_child(start_btn)
	
	ctx.bag_ui_elements["start_btn"] = start_btn
	ctx.bag_ui_elements["was_all_placed"] = false
	ctx.bag_ui_elements["bonus_given"] = false
	
	DeskTheme.animate_entrance(note_panel)
	selected_bag_subject = 8
	selected_bag_slot = -1
	_update_bag_ui()
	
	var timer = ctx.screen_content.get_tree().create_timer(0.5)
	timer.timeout.connect(func():
		var likes_phase = DailyLikesPhaseScript.new(ctx)
		active_likes_phase = likes_phase
		likes_phase.phase_completed.connect(func():
			_update_bag_ui()
			active_likes_phase = null
		)
		likes_phase.start()
	)

func _on_bag_slot_pressed(subject: int, slot: int):
	if ctx.audio_manager: ctx.audio_manager.play_se("click")
	selected_bag_subject = subject
	selected_bag_slot = slot
	_update_bag_ui()

func _on_bag_weight_pressed(weight: int):
	_remove_weight_from_assignments(weight)
	var target_subject = selected_bag_subject
	var target_slot = selected_bag_slot
	if target_subject != 8 and target_slot != -1:
		ctx.bag_assignments[target_subject][target_slot] = weight
		var slot_btn = ctx.bag_ui_elements["slots"][target_subject][target_slot] as Control
		slot_btn.pivot_offset = slot_btn.size / 2.0
		var tw = slot_btn.create_tween()
		tw.tween_property(slot_btn, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(slot_btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK)
		selected_bag_subject = 8
		selected_bag_slot = -1
	else:
		var assigned = false
		for s in range(5):
			for i in range(2):
				if ctx.bag_assignments[s][i] == null:
					ctx.bag_assignments[s][i] = weight
					assigned = true
					var slot_btn = ctx.bag_ui_elements["slots"][s][i] as Control
					slot_btn.pivot_offset = slot_btn.size / 2.0
					var tw = slot_btn.create_tween()
					tw.tween_property(slot_btn, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_CUBIC)
					tw.tween_property(slot_btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BOUNCE)
					break
			if assigned: break
	if ctx.audio_manager: ctx.audio_manager.play_se("place")
	_update_bag_ui()

func _on_weight_gui_input(event: InputEvent, weight: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start_pos = event.global_position
			drag_data = {"active": false, "value": weight, "source": "tray", "subject": -1, "slot": -1, "node": null}
			has_dragged = false

func _on_slot_gui_input(event: InputEvent, subject: int, slot: int):
	var current_weight = ctx.bag_assignments[subject][slot]
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start_pos = event.global_position
			if current_weight != null:
				drag_data = {"active": false, "value": current_weight, "source": "slot", "subject": subject, "slot": slot, "node": null}
			else:
				drag_data = {"active": false, "value": 0, "source": "", "subject": -1, "slot": -1, "node": null}
			has_dragged = false

func _handle_global_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			if drag_data["active"]:
				_end_drag()
			elif drag_data.get("value", 0) > 0:
				# 通常のタップ処理
				if drag_data["source"] == "tray":
					_on_bag_weight_pressed(drag_data["value"])
				elif drag_data["source"] == "slot":
					_on_bag_slot_pressed(drag_data["subject"], drag_data["slot"])
			drag_data = {"active": false, "value": 0, "source": "", "subject": -1, "slot": -1, "node": null}
	elif event is InputEventMouseMotion and drag_data.get("value", 0) > 0 and not drag_data["active"]:
		if event.global_position.distance_to(drag_start_pos) > drag_threshold:
			_start_drag(drag_data["value"], drag_data["source"], drag_data["subject"], drag_data["slot"])

func _start_drag(value: int, source: String, subject: int = -1, slot: int = -1):
	drag_data["active"] = true
	has_dragged = true
	if ctx.audio_manager: ctx.audio_manager.play_se("click")
	var postit_col = POSTIT_COLORS[value - 1]
	
	var drag_preview = PanelContainer.new()
	drag_preview.custom_minimum_size = Vector2(110, 110)
	drag_preview.size = Vector2(110, 110)
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(postit_col.r, postit_col.g, postit_col.b, 0.82)
	style.corner_radius_top_left = 2; style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 12
	style.shadow_offset = Vector2(4, 8)
	drag_preview.add_theme_stylebox_override("panel", style)
	var lbl = DeskTheme.create_label(str(value), 42, DeskTheme.COLOR_INK, true)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_preview.add_child(lbl)
	ctx.screen_content.add_child(drag_preview)
	drag_preview.z_index = 200
	drag_preview.global_position = ctx.ui_root.get_global_mouse_position() - Vector2(55, 55)
	drag_data["node"] = drag_preview
	
	if source == "slot" and subject != -1 and slot != -1:
		ctx.bag_ui_elements["slots"][subject][slot].modulate = Color(1, 1, 1, 0.3)
	elif source == "tray":
		ctx.bag_ui_elements["weights"][value].modulate = Color(1, 1, 1, 0.3)
	
	# ドラッグポーリング用Timer
	var timer = Timer.new()
	timer.name = "DragTimer"
	timer.wait_time = 0.016
	timer.autostart = true
	timer.timeout.connect(_on_drag_poll)
	ctx.ui_root.add_child(timer)

func _on_drag_poll():
	if not drag_data["active"]:
		var timer = ctx.ui_root.find_child("DragTimer")
		if timer: timer.queue_free()
		return
	if drag_data["node"]:
		drag_data["node"].global_position = ctx.ui_root.get_global_mouse_position() - Vector2(55, 55)
	_update_drag_hover()

func _update_drag_hover():
	var mouse_pos = ctx.ui_root.get_global_mouse_position()
	var found_subject = -1
	var found_slot = -1
	for s in range(5):
		for i in range(2):
			var slot_btn = ctx.bag_ui_elements["slots"][s][i] as Button
			if slot_btn.get_global_rect().has_point(mouse_pos):
				found_subject = s
				found_slot = i
				break
		if found_subject != -1: break
	if found_subject != hovered_slot_subject or found_slot != hovered_slot_idx:
		if hovered_slot_subject != -1 and hovered_slot_idx != -1:
			var old_btn = ctx.bag_ui_elements["slots"][hovered_slot_subject][hovered_slot_idx] as Button
			var style = old_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			style.border_color = DeskTheme.COLOR_MUTED
			style.border_width_bottom = 4
			old_btn.add_theme_stylebox_override("normal", style)
		hovered_slot_subject = found_subject
		hovered_slot_idx = found_slot
		if hovered_slot_subject != -1 and hovered_slot_idx != -1:
			var new_btn = ctx.bag_ui_elements["slots"][hovered_slot_subject][hovered_slot_idx] as Button
			var style = new_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			style.border_color = DeskTheme.COLOR_ACCENT_GOLD
			style.border_width_bottom = 6
			new_btn.add_theme_stylebox_override("normal", style)
			if ctx.audio_manager: ctx.audio_manager.play_se("place")

func _end_drag():
	drag_data["active"] = false
	if is_instance_valid(drag_data.get("node")):
		drag_data["node"].queue_free()
	drag_data["node"] = null
	# ドラッグ元のモジュレーションを元に戻す
	if drag_data.get("source") == "slot":
		var s = drag_data["subject"]
		var idx = drag_data["slot"]
		ctx.bag_ui_elements["slots"][s][idx].modulate = Color.WHITE
	elif drag_data.get("source") == "tray":
		var val = drag_data["value"]
		ctx.bag_ui_elements["weights"][val].modulate = Color.WHITE
	_update_drag_hover()
	var value = drag_data.get("value", 0)
	var source = drag_data.get("source", "")
	if hovered_slot_subject != -1 and hovered_slot_idx != -1:
		var dest_subject = hovered_slot_subject
		var dest_slot = hovered_slot_idx
		var dest_current_val = ctx.bag_assignments[dest_subject][dest_slot]
		if source == "tray":
			_remove_weight_from_assignments(value)
			ctx.bag_assignments[dest_subject][dest_slot] = value
			var btn = ctx.bag_ui_elements["slots"][dest_subject][dest_slot] as Control
			btn.pivot_offset = btn.size / 2.0
			var tw = btn.create_tween()
			tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
		elif source == "slot":
			var src_subject = drag_data["subject"]
			var src_slot = drag_data["slot"]
			if not (src_subject == dest_subject and src_slot == dest_slot):
				ctx.bag_assignments[src_subject][src_slot] = dest_current_val
				ctx.bag_assignments[dest_subject][dest_slot] = value
				for btn in [ctx.bag_ui_elements["slots"][src_subject][src_slot], ctx.bag_ui_elements["slots"][dest_subject][dest_slot]]:
					btn.pivot_offset = btn.size / 2.0
					var tw = btn.create_tween()
					tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_CUBIC)
					tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
		if ctx.audio_manager: ctx.audio_manager.play_se("place")
	else:
		if source == "slot":
			var src_subject = drag_data["subject"]
			var src_slot = drag_data["slot"]
			ctx.bag_assignments[src_subject][src_slot] = null
			if ctx.audio_manager: ctx.audio_manager.play_se("click")
	if hovered_slot_subject != -1 and hovered_slot_idx != -1:
		var btn = ctx.bag_ui_elements["slots"][hovered_slot_subject][hovered_slot_idx] as Button
		var style = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.border_color = DeskTheme.COLOR_MUTED
		style.border_width_bottom = 4
		btn.add_theme_stylebox_override("normal", style)
	hovered_slot_subject = -1
	hovered_slot_idx = -1
	drag_data = {"active": false, "value": 0, "source": "", "subject": -1, "slot": -1, "node": null}
	_update_bag_ui()

func _remove_weight_from_assignments(weight: int):
	for s in range(5):
		for i in range(2):
			if ctx.bag_assignments[s][i] == weight:
				ctx.bag_assignments[s][i] = null

func _update_bag_ui():
	var placed = 0
	var assigned_weights = []
	
	# 教科スロット付箋の更新
	for s in range(5):
		for i in range(2):
			var btn = ctx.bag_ui_elements["slots"][s][i]
			var val = ctx.bag_assignments[s][i]
			var is_selected = (s == selected_bag_subject and i == selected_bag_slot)
			var style: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate()
			
			if val != null:
				placed += 1
				btn.text = str(val)
				assigned_weights.append(val)
				# 配置済み：ふせんの色に変化（Post-itスタイル + 3Dシャドウ）
				var postit_col = POSTIT_COLORS[val - 1]
				style.bg_color = postit_col
				style.border_color = postit_col.darkened(0.15)
				style.border_width_left = 1; style.border_width_right = 1
				style.border_width_top = 1; style.border_width_bottom = 3
				style.corner_radius_top_left = 2; style.corner_radius_top_right = 2
				style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
				style.shadow_color = Color(0, 0, 0, 0.16)
				style.shadow_size = 5
				style.shadow_offset = Vector2(2, 4)
				btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			else:
				# 空きスロット
				style.shadow_size = 0
				style.shadow_offset = Vector2.ZERO
				style.border_width_left = 2; style.border_width_right = 2
				style.border_width_top = 2; style.border_width_bottom = 4
				style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
				style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
				if is_selected:
					style.border_color = DeskTheme.COLOR_BLUFF_RED
					style.bg_color = Color("fff0f0", 0.6)
				else:
					style.border_color = DeskTheme.COLOR_MUTED
					style.bg_color = Color("ffffff", 0.2)
				btn.text = "空き"
				btn.add_theme_color_override("font_color", DeskTheme.COLOR_MUTED)
			btn.add_theme_stylebox_override("normal", style)
	
	# 数字付箋パレットのグレーアウト処理
	for w in range(1, 11):
		var btn = ctx.bag_ui_elements["weights"][w]
		if assigned_weights.has(w):
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4, 0.7)
		else:
			btn.disabled = false
			btn.modulate = Color.WHITE
	
	# チキンレース開始ボタンのハンコ演出（すべて配置された時）
	var is_all_placed = (placed >= 10)
	if not ctx.bag_ui_elements.has("was_all_placed"):
		ctx.bag_ui_elements["was_all_placed"] = false
	if is_all_placed and not ctx.bag_ui_elements["was_all_placed"]:
		var target_btn = ctx.bag_ui_elements["start_btn"]
		target_btn.pivot_offset = target_btn.size / 2.0
		var tw = target_btn.create_tween()
		tw.tween_property(target_btn, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(target_btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if ctx.audio_manager: ctx.audio_manager.play_se("combo")
	ctx.bag_ui_elements["was_all_placed"] = is_all_placed
	
	# 配置済みカウンターの更新
	if ctx.bag_ui_elements.has("placed_counter"):
		var counter_lbl = ctx.bag_ui_elements["placed_counter"] as Label
		counter_lbl.text = "配置: %d/10" % placed
		if placed >= 10:
			counter_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_ACCENT_GOLD)
		else:
			counter_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_SAFE)
	
	# 選択中スロットのパルスアニメーション
	for s in range(5):
		for i in range(2):
			var btn = ctx.bag_ui_elements["slots"][s][i]
			var is_sel = (s == selected_bag_subject and i == selected_bag_slot)
			if is_sel and ctx.bag_assignments[s][i] == null:
				# 選択中の空スロットにパルス
				btn.pivot_offset = btn.size / 2.0
				var pulse = btn.create_tween().set_loops()
				pulse.set_meta("is_pulse", true)
				pulse.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				pulse.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			else:
				btn.scale = Vector2.ONE

func _on_start_race_pressed():
	if ctx.audio_manager: ctx.audio_manager.play_se("click")
	var weights = {}
	var placed_count = 0
	for s in range(5):
		weights[s] = []
		for v in ctx.bag_assignments[s]:
			if v != null:
				weights[s].append(v)
				placed_count += 1
	if placed_count < 10:
		ToastOverlayScript.show_toast(ctx.ui_root, "すべてのポケットに付箋を入れてね！", DeskTheme.COLOR_BLUFF_RED)
		return
	if is_instance_valid(drag_helper):
		drag_helper.queue_free()
	phase_completed.emit()
