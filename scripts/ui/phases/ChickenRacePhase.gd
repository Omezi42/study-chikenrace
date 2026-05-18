# scripts/ui/phases/ChickenRacePhase.gd
class_name ChickenRacePhase
extends RefCounted

signal phase_completed(scores_data: Dictionary)

var ctx: GameContext

# チキンレース中の状態
var current_subject_idx: int = 0
var active_subjects: Array = []
var drawn_card_nodes: Array = []

# HUD要素の参照保持
var hud_elements: Dictionary = {}
var sleepiness_bar: TextureProgressBar
var sleepiness_pulse: TextureRect
var vignette_overlay: ColorRect

var is_animating: bool = false

func _init(context: GameContext):
	self.ctx = context

func start():
	# 割り当てのある教科（カバンに重りが入っている教科）を抽出
	active_subjects.clear()
	for s in range(5):
		var has_weight = false
		for w in ctx.bag_assignments[s]:
			if w != null:
				has_weight = true
				break
		if has_weight:
			active_subjects.append(s)
			
	if active_subjects.size() == 0:
		# 例外的なガード処理：カバン計画が空なら即フェーズ完了
		phase_completed.emit({})
		return
		
	current_subject_idx = 0
	_start_next_subject_race()

func _start_next_subject_race():
	if current_subject_idx >= active_subjects.size():
		# すべての教科のチキンレースが完了
		phase_completed.emit({})
		return
		
	var s = active_subjects[current_subject_idx]
	_show_race_screen(s)

func _show_race_screen(subject: int):
	ctx.screen_content.get_tree().call_group("ui_elements", "queue_free") # 古いUIクリア
	drawn_card_nodes.clear()
	is_animating = false
	
	# チキンレースセッションの開始
	var weights = []
	for w in ctx.bag_assignments[subject]:
		if w != null: weights.append(w)
		
	# バックエンドのセッション初期化
	ctx.game_session.start_chicken_race(subject, weights)
	
	# 見開きノート外枠
	var note_panel = NotebookBuilder.create()
	ctx.active_notebook = note_panel
	ctx.screen_content.add_child(note_panel)
	
	var left_margin = note_panel.find_child("LeftContent", true, false) as MarginContainer
	var right_margin = note_panel.find_child("RightContent", true, false) as MarginContainer
	
	# ---------------- Left Page: チキンレースHUD ----------------
	var left_v = VBoxContainer.new()
	left_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_v.add_theme_constant_override("separation", 20)
	left_margin.add_child(left_v)
	
	# 睡魔の脈動ビネットを背景（親）にアタッチ
	_create_sleepy_vignette(ctx.screen_content)
	
	# ヘッダー
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 12)
	left_v.add_child(header_hbox)
	
	var sub_tex = DeskTheme.subject_texture(subject)
	header_hbox.add_child(DeskTheme.create_icon_rect(sub_tex, Vector2(48, 48)))
	
	var title_lbl = DeskTheme.create_label("✏️ %s の勉強チキンレース" % DeskTheme.subject_name(subject), 24, DeskTheme.COLOR_INK, true)
	header_hbox.add_child(title_lbl)
	
	# パラメータHUDカード
	var hud_card = PanelContainer.new()
	var hud_style = StyleBoxFlat.new()
	hud_style.bg_color = Color("ffffff")
	hud_style.corner_radius_top_left = 12; hud_style.corner_radius_top_right = 12
	hud_style.corner_radius_bottom_left = 12; hud_style.corner_radius_bottom_right = 12
	hud_style.content_margin_left = 16; hud_style.content_margin_right = 16
	hud_style.content_margin_top = 16; hud_style.content_margin_bottom = 16
	hud_style.shadow_color = Color(0,0,0, 0.05)
	hud_style.shadow_size = 6
	hud_style.shadow_offset = Vector2(2, 3)
	hud_card.add_theme_stylebox_override("panel", hud_style)
	left_v.add_child(hud_card)
	
	var hud_grid = GridContainer.new()
	hud_grid.columns = 2
	hud_grid.add_theme_constant_override("h_separation", 24)
	hud_grid.add_theme_constant_override("v_separation", 14)
	hud_card.add_child(hud_grid)
	
	hud_grid.add_child(DeskTheme.create_label("現在の総勉強量:", 14, DeskTheme.COLOR_MUTED))
	var score_val = DeskTheme.create_label("0g / 目標 20g", 18, DeskTheme.COLOR_INK, true)
	hud_grid.add_child(score_val)
	hud_elements["score"] = score_val
	
	hud_grid.add_child(DeskTheme.create_label("カバンの最大容量:", 14, DeskTheme.COLOR_MUTED))
	var cap_val = DeskTheme.create_label("--- g", 16, DeskTheme.COLOR_INK, true)
	hud_grid.add_child(cap_val)
	hud_elements["capacity"] = cap_val
	
	hud_grid.add_child(DeskTheme.create_label("今日引いた山札:", 14, DeskTheme.COLOR_MUTED))
	var cards_val = DeskTheme.create_label("--- 枚", 16, DeskTheme.COLOR_INK, true)
	hud_grid.add_child(cards_val)
	hud_elements["deck_count"] = cards_val
	
	# お手元お助け文房具
	left_v.add_child(DeskTheme.create_label("🛠️ 所持しているお助け文房具", 13, DeskTheme.COLOR_MUTED))
	
	var items_hbox = HBoxContainer.new()
	items_hbox.add_theme_constant_override("separation", 16)
	left_v.add_child(items_hbox)
	
	# 消しゴム
	var item_era = PanelContainer.new()
	item_era.custom_minimum_size = Vector2(120, 52)
	var era_style = StyleBoxFlat.new()
	era_style.bg_color = Color("ffffff")
	era_style.corner_radius_top_left = 8; era_style.corner_radius_top_right = 8
	era_style.corner_radius_bottom_left = 8; era_style.corner_radius_bottom_right = 8
	era_style.content_margin_left = 10; era_style.content_margin_right = 10
	era_style.border_width_left = 1; era_style.border_width_top = 1; era_style.border_width_right = 1; era_style.border_width_bottom = 1
	era_style.border_color = Color("e0e0e0")
	item_era.add_theme_stylebox_override("panel", era_style)
	items_hbox.add_child(item_era)
	
	var era_lbl = DeskTheme.create_label("🧹 消しゴム: ---", 12, DeskTheme.COLOR_INK)
	item_era.add_child(era_lbl)
	hud_elements["eraser"] = era_lbl
	
	# 定規
	var item_rul = PanelContainer.new()
	item_rul.custom_minimum_size = Vector2(120, 52)
	var rul_style = era_style.duplicate() as StyleBoxFlat
	item_rul.add_theme_stylebox_override("panel", rul_style)
	items_hbox.add_child(item_rul)
	
	var rul_lbl = DeskTheme.create_label("📐 定規: ---", 12, DeskTheme.COLOR_INK)
	item_rul.add_child(rul_lbl)
	hud_elements["ruler"] = rul_lbl
	
	# 3D風睡眠メーター（睡魔メーター）
	left_v.add_child(DeskTheme.create_label("💤 今日の睡魔ゲージ (満タンで寝落ちバースト！)", 13, DeskTheme.COLOR_MUTED))
	
	# メーター外枠
	var meter_container = PanelContainer.new()
	meter_container.custom_minimum_size = Vector2(0, 48)
	var met_style = StyleBoxFlat.new()
	met_style.bg_color = Color("23272a") # ダークなスリット
	met_style.border_width_left = 3; met_style.border_width_top = 3
	met_style.border_width_right = 3; met_style.border_width_bottom = 3
	met_style.border_color = Color("4b5358")
	met_style.corner_radius_top_left = 10; met_style.corner_radius_top_right = 10
	met_style.corner_radius_bottom_left = 10; met_style.corner_radius_bottom_right = 10
	meter_container.add_theme_stylebox_override("panel", met_style)
	left_v.add_child(meter_container)
	
	# 進捗 ProgressBar
	sleepiness_bar = TextureProgressBar.new()
	sleepiness_bar.value = 0
	sleepiness_bar.max_value = 100
	sleepiness_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sleepiness_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var bar_fill = GradientTexture2D.new()
	bar_fill.width = 300
	bar_fill.height = 36
	var g = Gradient.new()
	g.set_color(0, Color("4a90e2")) # はじめは青いリラックスした眠気
	g.set_color(1, Color("e34a4a")) # バースト間近は赤い警告
	bar_fill.gradient = g
	sleepiness_bar.texture_progress = bar_fill
	
	# 滑らかな角丸マスク用 StyleBoxFlat を進捗に乗せる（Godotのお作法）
	sleepiness_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	meter_container.add_child(sleepiness_bar)
	
	# ---------------- Right Page: 山札＆勉強机の上 ----------------
	var right_v = VBoxContainer.new()
	right_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_v.add_theme_constant_override("separation", 24)
	right_margin.add_child(right_v)
	
	# 机の上に並べた勉強ノート風の枠
	var desk_area = PanelContainer.new()
	desk_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var da_style = StyleBoxFlat.new()
	da_style.bg_color = Color("faf8f5", 0.75) # 半透明で罫線を透かす
	da_style.border_width_left = 2; da_style.border_width_top = 2
	da_style.border_width_right = 2; da_style.border_width_bottom = 2
	da_style.border_color = Color("c2b29d", 0.5)
	da_style.corner_radius_top_left = 12; da_style.corner_radius_top_right = 12
	da_style.corner_radius_bottom_left = 12; da_style.corner_radius_bottom_right = 12
	desk_area.add_theme_stylebox_override("panel", da_style)
	right_v.add_child(desk_area)
	
	var desk_c = Control.new()
	desk_area.add_child(desk_c)
	
	# 引いたカードの配置用コンテナ
	var card_container = Control.new()
	card_container.name = "CardContainer"
	card_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desk_c.add_child(card_container)
	
	# 操作ボタン群
	var button_box = HBoxContainer.new()
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 32)
	right_v.add_child(button_box)
	
	# ドロー（勉強する）
	var draw_btn = DeskTheme.create_button("さらに勉強する ✍️", Vector2(200, 56), DeskTheme.COLOR_SAFE, Color("1b8a4f"), true, 18)
	draw_btn.pressed.connect(_on_draw_pressed)
	button_box.add_child(draw_btn)
	hud_elements["draw_btn"] = draw_btn
	
	# パス（寝る/切り上げる）
	var stop_btn = DeskTheme.create_button("今日の勉強を切り上げる 😴", Vector2(240, 56), Color("b85a1b"), Color("8a3f1b"), true, 16)
	stop_btn.pressed.connect(_on_stop_pressed)
	button_box.add_child(stop_btn)
	hud_elements["stop_btn"] = stop_btn
	
	DeskTheme.animate_entrance(note_panel)
	_update_race_hud()

func _create_sleepy_vignette(parent: Control):
	vignette_overlay = ColorRect.new()
	vignette_overlay.name = "SleepyVignette"
	vignette_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_overlay.color = Color(0,0,0,0)
	
	var mat = ShaderMaterial.new()
	var code = """
	shader_type canvas_item;
	uniform float intensity : hint_range(0.0, 5.0) = 1.0;
	uniform float pulse_speed : hint_range(0.0, 10.0) = 1.5;
	uniform vec4 vignette_color : source_color = vec4(0.03, 0.01, 0.05, 0.9);
	
	void fragment() {
		vec2 uv = UV - vec2(0.5);
		float d = length(uv);
		float pulse = 1.0 + sin(TIME * pulse_speed) * 0.15;
		float alpha = smoothstep(0.4, 0.95 - (intensity * 0.06 * pulse), d);
		COLOR = vec4(vignette_color.rgb, alpha * vignette_color.a);
	}
	"""
	var sh = Shader.new()
	sh.code = code
	mat.shader = sh
	mat.set_shader_parameter("intensity", 0.0)
	vignette_overlay.material = mat
	parent.add_child(vignette_overlay)
	vignette_overlay.z_index = 50

func _update_race_hud():
	var race = ctx.game_session.current_race
	if not race: return
	
	var count = race["score"]
	var target = race["target"]
	var cap = race["capacity"]
	
	var score_lbl = hud_elements["score"] as Label
	score_lbl.text = "%d g / 目標 %d g" % [count, target]
	if count >= target:
		score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_SAFE)
	else:
		score_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		
	var cap_lbl = hud_elements["capacity"] as Label
	cap_lbl.text = "%d g" % cap
	
	var deck_lbl = hud_elements["deck_count"] as Label
	deck_lbl.text = "%d 枚" % race["deck_size"]
	
	# お助け文房具
	var era_lbl = hud_elements["eraser"] as Label
	era_lbl.text = "🧹 消しゴム: " + ("あり" if race["has_eraser"] else "使用済み")
	era_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK if race["has_eraser"] else DeskTheme.COLOR_MUTED)
	
	var rul_lbl = hud_elements["ruler"] as Label
	rul_lbl.text = "📐 定規: " + ("あり" if race["has_ruler"] else "使用済み")
	rul_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK if race["has_ruler"] else DeskTheme.COLOR_MUTED)
	
	# 睡魔メーター (パーセント)
	var pct = 0.0
	if cap > 0:
		pct = float(count) / float(cap) * 100.0
	sleepiness_bar.value = min(pct, 100.0)
	
	# 睡魔の脈動ビネット強度の更新
	if is_instance_valid(vignette_overlay) and vignette_overlay.material:
		var intensity = float(count) / float(cap) * 5.0 if cap > 0 else 0.0
		var mat = vignette_overlay.material as ShaderMaterial
		
		# 睡魔の脈動がじんわり強まる極上のTween遷移
		var tw = vignette_overlay.create_tween()
		tw.tween_property(mat, "shader_material:intensity" if mat.get("shader_material:intensity") != null else "shader_parameter/intensity", intensity, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_action_buttons_enabled(enabled: bool):
	var draw_btn = hud_elements.get("draw_btn") as Button
	var stop_btn = hud_elements.get("stop_btn") as Button
	if is_instance_valid(draw_btn): draw_btn.disabled = not enabled
	if is_instance_valid(stop_btn): stop_btn.disabled = not enabled

func _on_draw_pressed():
	if is_animating: return
	is_animating = true
	_set_action_buttons_enabled(false)
	
	var race = ctx.game_session.current_race
	if not race: 
		is_animating = false
		_set_action_buttons_enabled(true)
		return
		
	var prev_score = race["score"]
	var res = ctx.game_session.draw_study_card()
	
	var card = res["card"]
	var cap = race["capacity"]
	var current_score = race["score"]
	
	# カードビジュアルノード生成
	var card_container = ctx.active_notebook.find_child("CardContainer", true, false)
	if not card_container:
		is_animating = false
		_set_action_buttons_enabled(true)
		return
		
	var card_node = PanelContainer.new()
	var card_sz = Vector2(130, 190)
	card_node.custom_minimum_size = card_sz
	card_node.size = card_sz
	
	# 高級なカード枠スタイル (手書き単語カード風)
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("ffffff")
	card_style.border_width_left = 3; card_style.border_width_top = 3
	card_style.border_width_right = 3; card_style.border_width_bottom = 3
	card_style.border_color = DeskTheme.COLOR_INK
	card_style.corner_radius_top_left = 12; card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12; card_style.corner_radius_bottom_right = 12
	card_style.content_margin_left = 8; card_style.content_margin_right = 8
	card_style.content_margin_top = 8; card_style.content_margin_bottom = 8
	
	# ドロップシャドウ
	card_style.shadow_color = Color(0,0,0, 0.18)
	card_style.shadow_size = 12
	card_style.shadow_offset = Vector2(4, 8)
	card_node.add_theme_stylebox_override("panel", card_style)
	
	card_container.add_child(card_node)
	drawn_card_nodes.append(card_node)
	
	var cv = VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_theme_constant_override("separation", 10)
	card_node.add_child(cv)
	
	# タイトル (教科名アイコンなど)
	var sub_name = DeskTheme.create_label(DeskTheme.subject_name(card.subject_type), 11, DeskTheme.COLOR_MUTED, true)
	sub_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(sub_name)
	
	# 特大g表示
	var g_lbl = DeskTheme.create_label(str(card.weight) + "g", 32, DeskTheme.COLOR_INK, true)
	g_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(g_lbl)
	
	# カード裏面テクスチャ（スライド演出のフリップ用）
	var back_tex = Panel.new()
	back_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color("c2b29d") # 単語カードの厚紙裏地
	bs.border_width_left = 6; bs.border_width_top = 6; bs.border_width_right = 6; bs.border_width_bottom = 6
	bs.border_color = Color("8e7a63")
	bs.corner_radius_top_left = 12; bs.corner_radius_top_right = 12
	bs.corner_radius_bottom_left = 12; bs.corner_radius_bottom_right = 12
	back_tex.add_theme_stylebox_override("panel", bs)
	card_node.add_child(back_tex)
	
	# 裏側の単語カードリング穴デザイン
	var hole = ColorRect.new()
	hole.custom_minimum_size = Vector2(16, 16)
	hole.color = Color("ffffff") # 穴
	hole.anchor_left = 0.5; hole.anchor_right = 0.5
	hole.offset_left = -8; hole.offset_top = 10; hole.offset_right = 8; hole.offset_bottom = 26
	var hole_style = StyleBoxFlat.new()
	hole_style.bg_color = Color("faf8f5")
	hole_style.border_width_left = 2; hole_style.border_width_top = 2
	hole_style.border_width_right = 2; hole_style.border_width_bottom = 2
	hole_style.border_color = Color("8e7a63")
	hole_style.corner_radius_top_left = 8; hole_style.corner_radius_top_right = 8
	hole_style.corner_radius_bottom_left = 8; hole_style.corner_radius_bottom_right = 8
	hole.add_theme_stylebox_override("panel", hole_style)
	back_tex.add_child(hole)
	
	# 最終整列位置（山札からの飛び出し目標）
	var cols = 5
	var card_idx = drawn_card_nodes.size() - 1
	var col = card_idx % cols
	var row = card_idx / cols
	var gap = Vector2(24, 32)
	
	var target_pos = Vector2(
		40 + col * (card_sz.x + gap.x),
		40 + row * (card_sz.y + gap.y)
	)
	
	# 山札（ドローボタン）のグローバル座標から出現
	var start_pos = Vector2(400, 400)
	var button_box = hud_elements.get("draw_btn")
	if is_instance_valid(button_box):
		start_pos = button_box.global_position + button_box.size / 2.0 - card_sz / 2.0
		
	card_node.position = start_pos - card_container.global_position
	card_node.rotation_degrees = -45.0
	card_node.scale = Vector2(0.2, 0.2)
	card_node.modulate.a = 0.0
	card_node.pivot_offset = card_sz / 2.0
	
	if ctx.audio_manager: ctx.audio_manager.play_se("draw")
	
	var tw = card_node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(card_node, "position", target_pos, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_node, "rotation_degrees", randf_range(-10.0, 10.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_node, "modulate:a", 1.0, 0.15)
	tw.tween_property(card_node, "scale", Vector2(0.0, 1.3), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func(): back_tex.hide())
	tw.tween_property(card_node, "scale", Vector2(1.0, 1.0), 0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if ctx.audio_manager: ctx.audio_manager.play_se("place")
	await tw.finished
	
	_update_race_hud()
	
	# RULER 定規お助け効果発動
	if card.item_type == 3: # RULER
		_trigger_ruler_effect(card_node)
		return
		
	# バースト検知時の演出
	if res["burst"]:
		await _trigger_burst_sequence()
		return
		
	is_animating = false
	_set_action_buttons_enabled(true)

func _trigger_ruler_effect(card_node: Control):
	var race = ctx.game_session.current_race
	if not race: return
	
	if ctx.audio_manager: ctx.audio_manager.play_se("draw") # お助け出現SE
	
	var diag = PanelContainer.new()
	diag.custom_minimum_size = Vector2(450, 240)
	var diag_style = StyleBoxFlat.new()
	diag_style.bg_color = Color("ffffff")
	diag_style.border_width_left = 4; diag_style.border_width_top = 4
	diag_style.border_width_right = 4; diag_style.border_width_bottom = 4
	diag_style.border_color = DeskTheme.COLOR_SAFE
	diag_style.corner_radius_top_left = 16; diag_style.corner_radius_top_right = 16
	diag_style.corner_radius_bottom_left = 16; diag_style.corner_radius_bottom_right = 16
	diag_style.content_margin_left = 24; diag_style.content_margin_right = 24
	diag_style.content_margin_top = 20; diag_style.content_margin_bottom = 20
	
	# ドロップシャドウ
	diag_style.shadow_color = Color(0,0,0, 0.3)
	diag_style.shadow_size = 24
	diag_style.shadow_offset = Vector2(8, 12)
	diag.add_theme_stylebox_override("panel", diag_style)
	
	# 画面中央表示
	var view_size = ctx.ui_root.get_viewport_rect().size
	diag.position = Vector2(view_size.x / 2.0 - 225, view_size.y / 2.0 - 120)
	ctx.ui_root.add_child(diag)
	diag.z_index = 150
	
	var dv = VBoxContainer.new()
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.add_theme_constant_override("separation", 16)
	diag.add_child(dv)
	
	dv.add_child(DeskTheme.create_label("📐 定規お助け効果発動！", 22, DeskTheme.COLOR_SAFE, true))
	dv.add_child(DeskTheme.create_label("カバンの最大容量（許容量）が、今日だけ特別に +20g 拡張されました！寝落ちバーストを防ぎやすくなります。", 14, DeskTheme.COLOR_INK))
	
	var ok_btn = DeskTheme.create_button("効果を確認する", Vector2(160, 48), DeskTheme.COLOR_SAFE, Color("1b8a4f"))
	dv.add_child(ok_btn)
	
	# 軽快な出現バウンスTween
	diag.pivot_offset = Vector2(225, 120)
	diag.scale = Vector2(0.8, 0.8)
	var tw = diag.create_tween()
	tw.tween_property(diag, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	ok_btn.pressed.connect(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		
		# ダイアログ閉じるTween
		var tw_close = diag.create_tween()
		tw_close.tween_property(diag, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw_close.tween_callback(func():
			diag.queue_free()
			# バックエンド拡張＆同期
			ctx.game_session.apply_ruler_effect()
			_update_race_hud()
			
			is_animating = false
			_set_action_buttons_enabled(true)
		)
	)

func _trigger_eraser_evasion_sequence(new_card_node: Control, weight: int):
	# 消しゴム回避アニメーション
	is_animating = true
	_set_action_buttons_enabled(false)
	
	var diag = PanelContainer.new()
	diag.custom_minimum_size = Vector2(450, 240)
	var diag_style = StyleBoxFlat.new()
	diag_style.bg_color = Color("ffffff")
	diag_style.border_width_left = 4; diag_style.border_width_top = 4
	diag_style.border_width_right = 4; diag_style.border_width_bottom = 4
	diag_style.border_color = Color("b85a1b")
	diag_style.corner_radius_top_left = 16; diag_style.corner_radius_top_right = 16
	diag_style.corner_radius_bottom_left = 16; diag_style.corner_radius_bottom_right = 16
	diag_style.content_margin_left = 24; diag_style.content_margin_right = 24
	diag_style.content_margin_top = 20; diag_style.content_margin_bottom = 20
	diag.add_theme_stylebox_override("panel", diag_style)
	
	var view_size = ctx.ui_root.get_viewport_rect().size
	diag.position = Vector2(view_size.x / 2.0 - 225, view_size.y / 2.0 - 120)
	ctx.ui_root.add_child(diag)
	diag.z_index = 150
	
	var dv = VBoxContainer.new()
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.add_theme_constant_override("separation", 16)
	diag.add_child(dv)
	
	dv.add_child(DeskTheme.create_label("🧹 消しゴム回避発動！", 22, Color("b85a1b"), true))
	dv.add_child(DeskTheme.create_label("総勉強量が許容量を超えました！しかし、所持している消しゴムで今回引いた重りを無効化し、今日の寝落ちを回避します！", 14, DeskTheme.COLOR_INK))
	
	var use_btn = DeskTheme.create_button("消しゴムを使用する", Vector2(200, 48), Color("b85a1b"), Color("8a3f1b"))
	dv.add_child(use_btn)
	
	diag.pivot_offset = Vector2(225, 120)
	diag.scale = Vector2(0.8, 0.8)
	var tw = diag.create_tween()
	tw.tween_property(diag, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	use_btn.pressed.connect(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("place")
		
		# ノートの上で該当のカードが弾け飛んで消え去るようなTween演出
		if is_instance_valid(new_card_node):
			var card_tw = new_card_node.create_tween().set_parallel(true)
			card_tw.tween_property(new_card_node, "position:y", new_card_node.position.y - 120, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			card_tw.tween_property(new_card_node, "scale", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			card_tw.tween_property(new_card_node, "rotation_degrees", 180.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			card_tw.chain().tween_callback(func():
				drawn_card_nodes.erase(new_card_node)
				new_card_node.queue_free()
			)
			
		var tw_close = diag.create_tween()
		tw_close.tween_property(diag, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw_close.tween_callback(func():
			diag.queue_free()
			# 回避適用
			ctx.game_session.apply_eraser_evasion()
			_update_race_hud()
			
			is_animating = false
			_set_action_buttons_enabled(true)
		)
	)

func _trigger_burst_sequence():
	# 寝落ちバースト演出
	is_animating = true
	_set_action_buttons_enabled(false)
	
	# 所持消しゴムチェック
	var race = ctx.game_session.current_race
	if race and race["has_eraser"]:
		var last_node = drawn_card_nodes.back() if drawn_card_nodes.size() > 0 else null
		var last_val = race["score"] - ctx.game_session.current_race["score"] # 増加分
		await _trigger_eraser_evasion_sequence(last_node, last_val)
		return
		
	# 暗転フェード＆極上の睡魔脈動Tween（Godot 4 の堅牢なタイマー連動）
	if ctx.audio_manager: ctx.audio_manager.play_se("place") # ドスンと寝落ちるSE
	
	var fade_black = ColorRect.new()
	fade_black.color = Color(0,0,0,0)
	fade_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctx.ui_root.add_child(fade_black)
	fade_black.z_index = 100
	
	var fade_tw = fade_black.create_tween()
	fade_tw.tween_property(fade_black, "color", Color(0,0,0, 0.8), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# おもちゃ感が弾け飛ぶ：引いたカードたちが画面上で跳ねるコメディ風Tween
	var has_cards = false
	var hop_tw = ctx.ui_root.create_tween().set_parallel(true)
	for i in range(drawn_card_nodes.size()):
		var node = drawn_card_nodes[i]
		if is_instance_valid(node):
			has_cards = true
			node.pivot_offset = node.size / 2.0
			hop_tw.tween_property(node, "scale", Vector2.ZERO, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			hop_tw.tween_property(node, "position:y", node.position.y + 150, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			hop_tw.tween_property(node, "rotation_degrees", randf_range(-45.0, 45.0), 0.45)
			
	# Godot 4 エンジンの finished 発火ハングバグを完全に回避するため、空Tween同期を時間ベースに一本化！
	await ctx.ui_root.get_tree().create_timer(0.45).timeout
	
	# バーストリザルトダイアログの表示
	var diag = PanelContainer.new()
	diag.custom_minimum_size = Vector2(480, 260)
	var diag_style = StyleBoxFlat.new()
	diag_style.bg_color = Color("1a0d24") # 深い紫色の夜更け・寝落ちイメージ
	diag_style.border_width_left = 4; diag_style.border_width_top = 4
	diag_style.border_width_right = 4; diag_style.border_width_bottom = 4
	diag_style.border_color = Color("6c3a93")
	diag_style.corner_radius_top_left = 18; diag_style.corner_radius_top_right = 18
	diag_style.corner_radius_bottom_left = 18; diag_style.corner_radius_bottom_right = 18
	diag_style.content_margin_left = 28; diag_style.content_margin_right = 28
	diag_style.content_margin_top = 22; diag_style.content_margin_bottom = 22
	diag_style.shadow_color = Color(0,0,0, 0.5)
	diag_style.shadow_size = 32
	diag_style.shadow_offset = Vector2(10, 15)
	diag.add_theme_stylebox_override("panel", diag_style)
	
	var view_size = ctx.ui_root.get_viewport_rect().size
	diag.position = Vector2(view_size.x / 2.0 - 240, view_size.y / 2.0 - 130)
	ctx.ui_root.add_child(diag)
	diag.z_index = 101
	
	var dv = VBoxContainer.new()
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.add_theme_constant_override("separation", 18)
	diag.add_child(dv)
	
	dv.add_child(DeskTheme.create_label("😴 机の上で寝落ちした...", 24, Color("dca5ff"), true))
	
	# 面白いコメディ風寝落ちテキスト
	var txt = "今日のノルマを超えて無理に勉強しようとしたため、睡魔に負けて机の上でぐっすり寝てしまいました！\n今日の「%s」の勉強量は【 0g （バースト判定）】となります..." % DeskTheme.subject_name(race["subject_type"])
	var desc = DeskTheme.create_label(txt, 13, Color("ffffff"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(desc)
	
	var cont_btn = DeskTheme.create_button("翌朝をむかえる ☀️", Vector2(220, 52), Color("6c3a93"), Color("4e2470"))
	dv.add_child(cont_btn)
	
	diag.pivot_offset = Vector2(240, 130)
	diag.scale = Vector2(0.8, 0.8)
	var tw_diag = diag.create_tween()
	tw_diag.tween_property(diag, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	cont_btn.pressed.connect(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		
		# バックエンドのバースト処理（スコア0で終了）
		ctx.game_session.burst_chicken_race()
		
		diag.queue_free()
		fade_black.queue_free()
		
		# 次の教科へ進む
		current_subject_idx += 1
		_start_next_subject_race()
	)

func _on_stop_pressed():
	if is_animating: return
	is_animating = true
	_set_action_buttons_enabled(false)
	
	if ctx.audio_manager: ctx.audio_manager.play_se("click")
	
	# 切り上げ処理を実行
	var race = ctx.game_session.current_race
	if race:
		ctx.game_session.stop_chicken_race()
		
	# ページめくりアニメーション演出
	_animate_page_turn(func():
		current_subject_idx += 1
		_start_next_subject_race()
	)

func _animate_page_turn(callback: Callable):
	if not is_instance_valid(ctx.active_notebook):
		callback.call()
		return
		
	if ctx.audio_manager: ctx.audio_manager.play_se("place") # パサッという音
	
	# 右ページの紙を左へめくる3D風フリップアニメーション
	var paper_cover = PanelContainer.new()
	paper_cover.custom_minimum_size = Vector2(620, 840)
	paper_cover.size = Vector2(620, 840)
	paper_cover.pivot_offset = Vector2(0, 420) # リングノートの中央綴じ目をピボット
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("faf8f5") # 白い用紙
	style.border_width_left = 1; style.border_width_top = 2
	style.border_width_right = 2; style.border_width_bottom = 3
	style.border_color = Color("c2b29d")
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 24
	paper_cover.add_theme_stylebox_override("panel", style)
	
	ctx.active_notebook.add_child(paper_cover)
	paper_cover.position = Vector2(620, 20) # 右ページの位置
	
	var tw = paper_cover.create_tween()
	tw.set_parallel(true)
	# 180度フリップして左ページに被さる
	tw.tween_property(paper_cover, "scale:x", -1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(paper_cover, "position:x", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	tw.chain().tween_callback(callback)
	tw.tween_callback(paper_cover.queue_free)
