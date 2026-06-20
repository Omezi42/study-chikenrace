class_name RulebookModal
extends CanvasLayer

static func create_and_show(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = RulebookModal.new()
	parent_node.add_child(canvas)

var current_page: int = 0
var max_pages: int = 6

var content_container: PanelContainer
var prev_btn: Button
var next_btn: Button
var page_lbl: Label
var modal: PanelContainer

func _ready() -> void:
	layer = 102
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)
	
	modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(1050, 750)
	modal.pivot_offset = Vector2(525, 375)
	modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(modal)
	
	var viewport_size = get_viewport().get_visible_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Header
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "テスト勉強チキンレースの遊び方"
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = " × 閉じる "
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.custom_minimum_size = Vector2(120, 40)
	DeskTheme.apply_white_button_style(close_btn)
	header_hbox.add_child(close_btn)
	close_btn.pressed.connect(_close_modal)
	
	# Content Area
	content_container = PanelContainer.new()
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color("faf6f0")
	content_style.border_color = DeskTheme.COLOR_INK
	content_style.border_width_left = 2
	content_style.border_width_right = 2
	content_style.border_width_top = 2
	content_style.border_width_bottom = 2
	content_style.corner_radius_top_left = 12
	content_style.corner_radius_top_right = 12
	content_style.corner_radius_bottom_left = 12
	content_style.corner_radius_bottom_right = 12
	content_style.content_margin_left = 24
	content_style.content_margin_right = 24
	content_style.content_margin_top = 24
	content_style.content_margin_bottom = 24
	content_container.add_theme_stylebox_override("panel", content_style)
	vbox.add_child(content_container)
	
	# Footer Navigation
	var footer_hbox = HBoxContainer.new()
	footer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(footer_hbox)
	
	prev_btn = Button.new()
	prev_btn.text = " ＜ 前へ "
	prev_btn.custom_minimum_size = Vector2(140, 50)
	prev_btn.add_theme_font_override("font", DeskTheme.get_font())
	prev_btn.add_theme_font_size_override("font_size", 20)
	DeskTheme.apply_white_button_style(prev_btn)
	prev_btn.pressed.connect(func():
		DeskTheme.animate_click(prev_btn, Vector2.ONE, 0.08)
		if current_page > 0:
			_show_page(current_page - 1)
	)
	footer_hbox.add_child(prev_btn)
	
	page_lbl = Label.new()
	page_lbl.add_theme_font_override("font", DeskTheme.get_font())
	page_lbl.add_theme_font_size_override("font_size", 22)
	page_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	page_lbl.custom_minimum_size = Vector2(100, 0)
	page_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_hbox.add_child(page_lbl)
	
	next_btn = Button.new()
	next_btn.text = " 次へ ＞ "
	next_btn.custom_minimum_size = Vector2(140, 50)
	next_btn.add_theme_font_override("font", DeskTheme.get_font())
	next_btn.add_theme_font_size_override("font_size", 20)
	DeskTheme.apply_white_button_style(next_btn)
	next_btn.pressed.connect(func():
		DeskTheme.animate_click(next_btn, Vector2.ONE, 0.08)
		if current_page < max_pages - 1:
			_show_page(current_page + 1)
	)
	footer_hbox.add_child(next_btn)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(40, 0)
	footer_hbox.add_child(spacer)
	
	var play_tutorial_btn = Button.new()
	play_tutorial_btn.text = " ★ チュートリアルをプレイ！ ★ "
	play_tutorial_btn.custom_minimum_size = Vector2(300, 50)
	play_tutorial_btn.add_theme_font_override("font", DeskTheme.get_font())
	play_tutorial_btn.add_theme_font_size_override("font_size", 18)
	_apply_tutorial_button_style(play_tutorial_btn)
	play_tutorial_btn.pressed.connect(_start_tutorial)
	footer_hbox.add_child(play_tutorial_btn)
	
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
	
	_show_page(0)

func _close_modal() -> void:
	var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
	out_tween.tween_callback(func(): queue_free())

func _start_tutorial() -> void:
	Global.is_tutorial_mode = true
	Global.game_mode = Constants.MODE_CPU
	Global.opponent_profiles = {
		"cpu_sato": {"name": "佐藤くん", "deviation": 51.5},
		"cpu_suzuki": {"name": "鈴木さん", "deviation": 48.0},
		"cpu_takahashi": {"name": "高橋くん", "deviation": 54.2}
	}
	if Global.player_name == "":
		Global.player_name = "プレイヤー"
	
	var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
	out_tween.tween_callback(func():
		queue_free()
		var tree = get_tree()
		if tree:
			Global.change_scene_with_fade(tree, "res://Main.tscn")
	)

func _apply_tutorial_button_style(btn: Button) -> void:
	var tut_normal = StyleBoxFlat.new()
	tut_normal.bg_color = Color("fff59d")
	tut_normal.border_color = DeskTheme.COLOR_INK
	tut_normal.border_width_left = 3
	tut_normal.border_width_right = 3
	tut_normal.border_width_top = 3
	tut_normal.border_width_bottom = 6
	tut_normal.corner_radius_top_left = 8
	tut_normal.corner_radius_top_right = 8
	tut_normal.corner_radius_bottom_left = 8
	tut_normal.corner_radius_bottom_right = 8
	
	var tut_hover = tut_normal.duplicate()
	tut_hover.bg_color = Color("fff176")
	var tut_pressed = tut_normal.duplicate()
	tut_pressed.border_width_bottom = 3
	
	btn.add_theme_stylebox_override("normal", tut_normal)
	btn.add_theme_stylebox_override("hover", tut_hover)
	btn.add_theme_stylebox_override("pressed", tut_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	btn.add_theme_color_override("font_hover_color", DeskTheme.COLOR_INK)
	btn.add_theme_color_override("font_pressed_color", DeskTheme.COLOR_INK)
	
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.mouse_entered.connect(func(): DeskTheme.animate_hover(btn, true, Vector2.ONE, 0.1))
	btn.mouse_exited.connect(func(): DeskTheme.animate_hover(btn, false, Vector2.ONE, 0.1))

func _show_page(idx: int) -> void:
	current_page = idx
	page_lbl.text = "%d / %d" % [current_page + 1, max_pages]
	prev_btn.disabled = (current_page == 0)
	next_btn.disabled = (current_page == max_pages - 1)
	
	for child in content_container.get_children():
		child.queue_free()
		
	var page_content = _build_page(idx)
	content_container.add_child(page_content)

func _build_page(idx: int) -> Control:
	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Top Visual Area
	var visual_area = Control.new()
	visual_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(visual_area)
	
	# Text Area (Bottom)
	var text_panel = PanelContainer.new()
	text_panel.custom_minimum_size = Vector2(0, 140)
	var tp_style = StyleBoxFlat.new()
	tp_style.bg_color = Color.WHITE
	tp_style.border_color = Color(0, 0, 0, 0.1)
	tp_style.border_width_left = 2
	tp_style.border_width_right = 2
	tp_style.border_width_top = 2
	tp_style.border_width_bottom = 2
	tp_style.corner_radius_top_left = 8
	tp_style.corner_radius_top_right = 8
	tp_style.corner_radius_bottom_left = 8
	tp_style.corner_radius_bottom_right = 8
	tp_style.content_margin_left = 20
	tp_style.content_margin_right = 20
	tp_style.content_margin_top = 20
	tp_style.content_margin_bottom = 20
	text_panel.add_theme_stylebox_override("panel", tp_style)
	vbox.add_child(text_panel)
	
	# For vertical centering, we wrap the RichTextLabel in a VBoxContainer with ALIGNMENT_CENTER
	var text_vcenter = VBoxContainer.new()
	text_vcenter.alignment = BoxContainer.ALIGNMENT_CENTER
	text_vcenter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_panel.add_child(text_vcenter)
	
	var rtb = RichTextLabel.new()
	rtb.bbcode_enabled = true
	rtb.fit_content = true
	rtb.add_theme_font_override("normal_font", DeskTheme.get_font())
	rtb.add_theme_font_override("bold_font", DeskTheme.get_font())
	rtb.add_theme_font_size_override("normal_font_size", 22)
	rtb.add_theme_font_size_override("bold_font_size", 24)
	rtb.add_theme_color_override("default_color", DeskTheme.COLOR_INK)
	rtb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vcenter.add_child(rtb)
	
	match idx:
		0: _setup_page_1(visual_area, rtb)
		1: _setup_page_2(visual_area, rtb)
		2: _setup_page_3(visual_area, rtb)
		3: _setup_page_4(visual_area, rtb)
		4: _setup_page_5(visual_area, rtb)
		5: _setup_page_6(visual_area, rtb)
		
	return vbox

func _create_title_label(text: String, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", DeskTheme.get_font())
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

func _create_arrow_label() -> Label:
	var lbl = Label.new()
	lbl.text = "➡"
	lbl.add_theme_font_override("font", DeskTheme.get_font())
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

func _setup_page_1(visual_area: Control, rtb: RichTextLabel) -> void:
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	visual_area.add_child(hbox)
	
	# Left: Draw 3 cards
	var left_v = VBoxContainer.new()
	left_v.alignment = BoxContainer.ALIGNMENT_CENTER
	left_v.add_theme_constant_override("separation", 20)
	left_v.add_child(_create_title_label("チキンレースで勉強", Color("#ff9900")))
	
	var cards_ctrl = Control.new()
	cards_ctrl.custom_minimum_size = Vector2(280, 240)
	var c1 = CardVisual.create({"value": 7, "item_id": "item_mech_pencil", "name": "シャーペン"})
	c1.scale = Vector2(0.8, 0.8)
	c1.position = Vector2(0, 20)
	c1.rotation_degrees = -10
	c1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards_ctrl.add_child(c1)
	
	var c2 = CardVisual.create({"value": 10, "item_id": "item_ruler", "name": "定規"})
	c2.scale = Vector2(0.8, 0.8)
	c2.position = Vector2(60, 0)
	c2.rotation_degrees = 0
	c2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards_ctrl.add_child(c2)
	
	var c3 = CardVisual.create({"value": 8, "item_id": "item_blue_pen", "name": "青ペン"})
	c3.scale = Vector2(0.8, 0.8)
	c3.position = Vector2(120, 20)
	c3.rotation_degrees = 10
	c3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards_ctrl.add_child(c3)
	
	left_v.add_child(cards_ctrl)
	hbox.add_child(left_v)
	
	hbox.add_child(_create_arrow_label())
	
	# Center: Share (Slider mock)
	var center_v = VBoxContainer.new()
	center_v.alignment = BoxContainer.ALIGNMENT_CENTER
	center_v.add_theme_constant_override("separation", 20)
	center_v.add_child(_create_title_label("結果をシェア", Color("#33cc33")))
	
	var share_pnl = PanelContainer.new()
	share_pnl.custom_minimum_size = Vector2(240, 160)
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color.WHITE
	s_style.border_width_left = 4
	s_style.border_color = Color("#33cc33")
	s_style.shadow_size = 4
	s_style.shadow_color = Color(0,0,0,0.1)
	share_pnl.add_theme_stylebox_override("panel", s_style)
	
	var svbox = VBoxContainer.new()
	svbox.alignment = BoxContainer.ALIGNMENT_CENTER
	svbox.add_theme_constant_override("separation", 10)
	
	var slbl = Label.new()
	slbl.text = "実際の成果: 20点"
	slbl.add_theme_font_override("font", DeskTheme.get_font())
	slbl.add_theme_font_size_override("font_size", 18)
	slbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	slbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(slbl)
	
	var arr = Label.new()
	arr.text = "↓盛って報告↓"
	arr.add_theme_font_override("font", DeskTheme.get_font())
	arr.add_theme_font_size_override("font_size", 14)
	arr.add_theme_color_override("font_color", Color("#888"))
	arr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(arr)
	
	var dec_lbl = Label.new()
	dec_lbl.text = "申告: 44 点！"
	dec_lbl.add_theme_font_override("font", DeskTheme.get_font())
	dec_lbl.add_theme_font_size_override("font_size", 26)
	dec_lbl.add_theme_color_override("font_color", Color("#e53935"))
	dec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(dec_lbl)
	
	share_pnl.add_child(svbox)
	center_v.add_child(share_pnl)
	hbox.add_child(center_v)
	
	hbox.add_child(_create_arrow_label())
	
	# Right: Doubt
	var right_v = VBoxContainer.new()
	right_v.alignment = BoxContainer.ALIGNMENT_CENTER
	right_v.add_theme_constant_override("separation", 20)
	right_v.add_child(_create_title_label("ダウト", Color("#ff3333")))
	
	var doubt_btn = Button.new()
	doubt_btn.text = "ダウト！"
	doubt_btn.custom_minimum_size = Vector2(160, 80)
	doubt_btn.add_theme_font_override("font", DeskTheme.get_font())
	doubt_btn.add_theme_font_size_override("font_size", 30)
	var d_bstyle = StyleBoxFlat.new()
	d_bstyle.bg_color = Color("#e53935")
	d_bstyle.border_width_bottom = 6
	d_bstyle.border_color = Color("#b71c1c")
	d_bstyle.corner_radius_top_left = 16
	d_bstyle.corner_radius_top_right = 16
	d_bstyle.corner_radius_bottom_left = 16
	d_bstyle.corner_radius_bottom_right = 16
	doubt_btn.add_theme_stylebox_override("normal", d_bstyle)
	doubt_btn.add_theme_color_override("font_color", Color.WHITE)
	right_v.add_child(doubt_btn)
	hbox.add_child(right_v)
	
	rtb.text = "[center]ゲームの基本の流れは[color=#ff9900][b]3つのステップ[/b][/color]です。\n1. カードを引いて点数を集め、 2. 結果を盛って報告し、 3. 相手の嘘を見破る！[/center]"

func _setup_page_2(visual_area: Control, rtb: RichTextLabel) -> void:
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 80)
	visual_area.add_child(hbox)
	
	# Left: Bar Graph
	var graph_v = VBoxContainer.new()
	graph_v.alignment = BoxContainer.ALIGNMENT_CENTER
	graph_v.add_theme_constant_override("separation", 10)
	var g_lbl = Label.new()
	g_lbl.text = "数字が大きいほど出やすい＝重なりやすい！"
	g_lbl.add_theme_font_override("font", DeskTheme.get_font())
	g_lbl.add_theme_font_size_override("font_size", 20)
	g_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	graph_v.add_child(g_lbl)
	
	var graph_bg = ColorRect.new()
	graph_bg.color = Color(0,0,0,0.05)
	graph_bg.custom_minimum_size = Vector2(340, 200)
	
	var bar_data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var max_val = 10.0
	for i in range(bar_data.size()):
		var val = bar_data[i]
		var h = (val / max_val) * 160.0
		var bar = ColorRect.new()
		bar.color = Color("#ff9900")
		bar.size = Vector2(24, h)
		bar.position = Vector2(10 + i * 32, 180 - h)
		graph_bg.add_child(bar)
		var num_lbl = Label.new()
		num_lbl.text = str(val)
		num_lbl.add_theme_font_override("font", DeskTheme.get_font())
		num_lbl.add_theme_font_size_override("font_size", 14)
		num_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		num_lbl.position = Vector2(10 + i * 32, 185)
		graph_bg.add_child(num_lbl)
	
	graph_v.add_child(graph_bg)
	hbox.add_child(graph_v)
	
	# Right: Burst overlay
	var burst_v = VBoxContainer.new()
	burst_v.alignment = BoxContainer.ALIGNMENT_CENTER
	var burst_ctrl = Control.new()
	burst_ctrl.custom_minimum_size = Vector2(200, 240)
	
	var c7_1 = CardVisual.create({"value": 7, "item_id": "", "name": "通常"})
	c7_1.position = Vector2(0, 0)
	c7_1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst_ctrl.add_child(c7_1)
	
	var c7_2 = CardVisual.create({"value": 7, "item_id": "", "name": "通常"})
	c7_2.position = Vector2(40, 40) # ズラして配置
	c7_2.modulate = Color(1.0, 0.3, 0.3) # 強い赤
	c7_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst_ctrl.add_child(c7_2)
	burst_v.add_child(burst_ctrl)
	
	var burst_lbl = Label.new()
	burst_lbl.text = "バースト！"
	burst_lbl.add_theme_font_override("font", DeskTheme.get_font())
	burst_lbl.add_theme_font_size_override("font_size", 36)
	burst_lbl.add_theme_color_override("font_color", Color.WHITE)
	burst_lbl.add_theme_color_override("font_outline_color", Color.RED)
	burst_lbl.add_theme_constant_override("outline_size", 8)
	burst_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burst_v.add_child(burst_lbl)
	
	hbox.add_child(burst_v)
	
	rtb.text = "[center]カードを引くと、[color=#ff9900][b]カードの数字がそのまま点数（勉強時間）として加算[/b][/color]されます。\nただし、[color=#ff3333][b]同じ数字のカードを2枚引く[/b][/color]と寝落ち（バースト）してその回の点数は0点に！\n『休憩』して点数を確定させましょう。[/center]"

func _setup_page_3(visual_area: Control, rtb: RichTextLabel) -> void:
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 60)
	visual_area.add_child(hbox)
	
	var item1_v = VBoxContainer.new()
	item1_v.alignment = BoxContainer.ALIGNMENT_CENTER
	item1_v.add_theme_constant_override("separation", 20)
	
	var t1 = TextureRect.new()
	t1.texture = load(CardData.get_item_image_path("item_eraser"))
	t1.custom_minimum_size = Vector2(120, 120)
	t1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item1_v.add_child(t1)
	
	var l_eraser = Label.new()
	l_eraser.text = "【消しゴム】\n重複したカードを山札に戻して\nドローをやり直す！"
	l_eraser.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_eraser.add_theme_font_override("font", DeskTheme.get_font())
	l_eraser.add_theme_font_size_override("font_size", 20)
	l_eraser.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	item1_v.add_child(l_eraser)
	hbox.add_child(item1_v)
	
	var item2_v = VBoxContainer.new()
	item2_v.alignment = BoxContainer.ALIGNMENT_CENTER
	item2_v.add_theme_constant_override("separation", 20)
	
	var t2 = TextureRect.new()
	t2.texture = load(CardData.get_item_image_path("item_blue_pen"))
	t2.custom_minimum_size = Vector2(120, 120)
	t2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item2_v.add_child(t2)
	
	var l_pen = Label.new()
	l_pen.text = "【青ペン】\n最終得点に\n倍率をかける！"
	l_pen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_pen.add_theme_font_override("font", DeskTheme.get_font())
	l_pen.add_theme_font_size_override("font_size", 20)
	l_pen.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	item2_v.add_child(l_pen)
	hbox.add_child(item2_v)
	
	rtb.text = "[center]数字ポケットに[b]アイテムを割り当てる[/b]\n強力な効果で[color=#ff9900][b]勉強を有利に！[/b][/color][/center]"

func _setup_page_4(visual_area: Control, rtb: RichTextLabel) -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	visual_area.add_child(vbox)
	
	# Chikista mock
	var pnl = PanelContainer.new()
	pnl.custom_minimum_size = Vector2(400, 160)
	pnl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color("#e0e0e0")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	pnl.add_theme_stylebox_override("panel", style)
	
	var in_vbox = VBoxContainer.new()
	in_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pnl.add_child(in_vbox)
	
	var rtb_post = RichTextLabel.new()
	rtb_post.bbcode_enabled = true
	rtb_post.text = "[center][b]プレイヤー[/b]の投稿\n\n実際の成果: 20点\n↓\n報告する点数: [color=#ff3333][b]44点（+24盛り）[/b][/color][/center]"
	rtb_post.add_theme_font_override("normal_font", DeskTheme.get_font())
	rtb_post.add_theme_font_override("bold_font", DeskTheme.get_font())
	rtb_post.add_theme_font_size_override("normal_font_size", 20)
	rtb_post.add_theme_font_size_override("bold_font_size", 22)
	rtb_post.add_theme_color_override("default_color", DeskTheme.COLOR_INK)
	rtb_post.custom_minimum_size = Vector2(380, 140)
	in_vbox.add_child(rtb_post)
	
	vbox.add_child(pnl)
	
	# Waves using SVGs
	var wave_hbox = HBoxContainer.new()
	wave_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	wave_hbox.add_theme_constant_override("separation", 20)
	
	var load_icon = func(path: String, color: Color) -> TextureRect:
		var tex = TextureRect.new()
		if ResourceLoader.exists(path):
			tex.texture = load(path)
		tex.custom_minimum_size = Vector2(48, 48)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.modulate = color
		return tex
		
	wave_hbox.add_child(load_icon.call("res://assets/icons/user.svg", Color("#2196f3")))
	
	var wave_lbl = Label.new()
	wave_lbl.text = "〰〰〰"
	wave_lbl.add_theme_font_override("font", DeskTheme.get_font())
	wave_lbl.add_theme_font_size_override("font_size", 40)
	wave_lbl.add_theme_color_override("font_color", Color("#2196f3"))
	wave_hbox.add_child(wave_lbl)
	
	wave_hbox.add_child(load_icon.call("res://assets/icons/smartphone.svg", Color("#2196f3")))
	
	var wave_lbl2 = wave_lbl.duplicate()
	wave_hbox.add_child(wave_lbl2)
	
	wave_hbox.add_child(load_icon.call("res://assets/icons/user.svg", Color("#2196f3")))
	vbox.add_child(wave_hbox)
	
	rtb.text = "[center]勉強の成果をライバルたちに[b]共有[/b]\n得点を[color=#ff3333][b]盛って報告して[/b][/color]プレッシャーをかけろ！[/center]"

func _setup_page_5(visual_area: Control, rtb: RichTextLabel) -> void:
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	visual_area.add_child(hbox)
	
	# Left: Doubt Modal replication (exactly like actual game modal)
	var doubt_pnl = PanelContainer.new()
	doubt_pnl.custom_minimum_size = Vector2(500, 320)
	
	var base_style = DeskTheme.create_craft_panel()
	base_style.border_color = DeskTheme.COLOR_GREEN
	base_style.border_width_left = 4
	base_style.border_width_right = 4
	base_style.border_width_top = 4
	base_style.border_width_bottom = 4
	doubt_pnl.add_theme_stylebox_override("panel", base_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	doubt_pnl.add_child(margin)
	
	var d_vbox = VBoxContainer.new()
	d_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(d_vbox)
	
	var d_title = Label.new()
	d_title.text = "ダウト成功！"
	d_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_title.add_theme_font_override("font", DeskTheme.get_font())
	d_title.add_theme_font_size_override("font_size", 28)
	d_title.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	d_vbox.add_child(d_title)
	
	var desc_lbl = Label.new()
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	desc_lbl.text = "佐藤くん は勉強報告で嘘をついていた！\n【申告】 44 点  ➡  【実際】 20 点"
	d_vbox.add_child(desc_lbl)
	
	var cards_hbox = HBoxContainer.new()
	cards_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_hbox.add_theme_constant_override("separation", 20)
	d_vbox.add_child(cards_hbox)
	
	var my_card = PanelContainer.new()
	my_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var my_style = StyleBoxFlat.new()
	my_style.bg_color = Color("e8f5e9")
	my_style.border_color = Color("81c784")
	my_style.border_width_left = 2
	my_style.border_width_right = 2
	my_style.border_width_top = 2
	my_style.border_width_bottom = 2
	my_style.corner_radius_top_left = 8
	my_style.corner_radius_top_right = 8
	my_style.corner_radius_bottom_left = 8
	my_style.corner_radius_bottom_right = 8
	my_card.add_theme_stylebox_override("panel", my_style)
	cards_hbox.add_child(my_card)
	
	var my_margin = MarginContainer.new()
	my_margin.add_theme_constant_override("margin_left", 10)
	my_margin.add_theme_constant_override("margin_right", 10)
	my_margin.add_theme_constant_override("margin_top", 10)
	my_margin.add_theme_constant_override("margin_bottom", 10)
	my_card.add_child(my_margin)
	
	var my_vbox = VBoxContainer.new()
	my_vbox.add_theme_constant_override("separation", 5)
	my_margin.add_child(my_vbox)
	
	var my_title = Label.new()
	my_title.text = "あなたへの影響"
	my_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_title.add_theme_font_override("font", DeskTheme.get_font())
	my_title.add_theme_font_size_override("font_size", 14)
	my_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	my_vbox.add_child(my_title)
	
	var my_diff_lbl = Label.new()
	my_diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_diff_lbl.add_theme_font_override("font", DeskTheme.get_font())
	my_diff_lbl.add_theme_font_size_override("font_size", 28)
	my_diff_lbl.text = "+24 点"
	my_diff_lbl.add_theme_color_override("font_color", Color("2e7d32"))
	my_vbox.add_child(my_diff_lbl)
	
	var my_detail = Label.new()
	my_detail.text = "ダウト成功ボーナスを獲得！"
	my_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	my_detail.add_theme_font_override("font", DeskTheme.get_font())
	my_detail.add_theme_font_size_override("font_size", 12)
	my_detail.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	my_vbox.add_child(my_detail)
	
	var opp_card = PanelContainer.new()
	opp_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opp_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var opp_style = StyleBoxFlat.new()
	opp_style.bg_color = Color("ffebee")
	opp_style.border_color = Color("e57373")
	opp_style.border_width_left = 2
	opp_style.border_width_right = 2
	opp_style.border_width_top = 2
	opp_style.border_width_bottom = 2
	opp_style.corner_radius_top_left = 8
	opp_style.corner_radius_top_right = 8
	opp_style.corner_radius_bottom_left = 8
	opp_style.corner_radius_bottom_right = 8
	opp_card.add_theme_stylebox_override("panel", opp_style)
	cards_hbox.add_child(opp_card)
	
	var opp_margin = MarginContainer.new()
	opp_margin.add_theme_constant_override("margin_left", 10)
	opp_margin.add_theme_constant_override("margin_right", 10)
	opp_margin.add_theme_constant_override("margin_top", 10)
	opp_margin.add_theme_constant_override("margin_bottom", 10)
	opp_card.add_child(opp_margin)
	
	var opp_vbox = VBoxContainer.new()
	opp_vbox.add_theme_constant_override("separation", 5)
	opp_margin.add_child(opp_vbox)
	
	var opp_title = Label.new()
	opp_title.text = "佐藤くん"
	opp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_title.add_theme_font_override("font", DeskTheme.get_font())
	opp_title.add_theme_font_size_override("font_size", 14)
	opp_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	opp_vbox.add_child(opp_title)
	
	var opp_diff_lbl = Label.new()
	opp_diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_diff_lbl.add_theme_font_override("font", DeskTheme.get_font())
	opp_diff_lbl.add_theme_font_size_override("font_size", 28)
	opp_diff_lbl.text = "実点に低下"
	opp_diff_lbl.add_theme_color_override("font_color", Color("c62828"))
	opp_vbox.add_child(opp_diff_lbl)
	
	var opp_detail = Label.new()
	opp_detail.text = "嘘がバレてスコアが下がった"
	opp_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opp_detail.add_theme_font_override("font", DeskTheme.get_font())
	opp_detail.add_theme_font_size_override("font_size", 12)
	opp_detail.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	opp_vbox.add_child(opp_detail)
	
	hbox.add_child(doubt_pnl)
	
	# Right: Blackboard
	var bb_pnl = PanelContainer.new()
	bb_pnl.custom_minimum_size = Vector2(360, 260)
	var bb_style = StyleBoxFlat.new()
	bb_style.bg_color = Color("#1b5e20") # Dark green
	bb_style.border_width_left = 8
	bb_style.border_width_right = 8
	bb_style.border_width_top = 8
	bb_style.border_width_bottom = 8
	bb_style.border_color = Color("#5d4037") # Wood
	bb_pnl.add_theme_stylebox_override("panel", bb_style)
	
	var bb_vbox = VBoxContainer.new()
	bb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bb_pnl.add_child(bb_vbox)
	
	var crown_tex = TextureRect.new()
	if ResourceLoader.exists("res://assets/icons/crown.svg"):
		crown_tex.texture = load("res://assets/icons/crown.svg")
	crown_tex.custom_minimum_size = Vector2(40, 40)
	crown_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown_tex.modulate = Color("#ffd54f")
	crown_tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bb_vbox.add_child(crown_tex)
	
	var bb_text = RichTextLabel.new()
	bb_text.bbcode_enabled = true
	bb_text.text = "[center][color=#ffd54f][b]1位: プレイヤー (120点)[/b][/color]\n\n2位: 高橋くん (95点)\n3位: 佐藤くん (80点)\n4位: 鈴木さん (45点)[/center]"
	bb_text.add_theme_font_override("normal_font", DeskTheme.get_font())
	bb_text.add_theme_font_override("bold_font", DeskTheme.get_font())
	bb_text.add_theme_font_size_override("normal_font_size", 20)
	bb_text.add_theme_font_size_override("bold_font_size", 24)
	bb_text.add_theme_color_override("default_color", Color.WHITE)
	bb_text.fit_content = true
	bb_text.custom_minimum_size = Vector2(300, 0)
	bb_text.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bb_vbox.add_child(bb_text)
	
	hbox.add_child(bb_pnl)
	
	rtb.text = "[center]嘘の報告には[color=#ff3333][b]ダウトを宣告！[/b][/color]\n勉強で稼いだ点数 ＋ ダウトの結果（最終得点）が一番高かった人の[color=#ff9900][b]勝ち！[/b][/color][/center]"

func _setup_page_6(visual_area: Control, rtb: RichTextLabel) -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual_area.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "詳細な計算式とルール"
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var space = Control.new()
	space.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(space)
	
	var text_rtb = RichTextLabel.new()
	text_rtb.bbcode_enabled = true
	text_rtb.fit_content = true
	text_rtb.add_theme_font_override("normal_font", DeskTheme.get_font())
	text_rtb.add_theme_font_override("bold_font", DeskTheme.get_font())
	text_rtb.add_theme_font_size_override("normal_font_size", 18)
	text_rtb.add_theme_font_size_override("bold_font_size", 20)
	text_rtb.add_theme_color_override("default_color", DeskTheme.COLOR_INK)
	
	var content = ""
	content += "[b]◆ 嘘バレのペナルティとリスク[/b]\n"
	content += "嘘がバレてしまっても、[color=#33cc33]申告点が本来の実点まで戻るだけ[/color]です（追加の大きな減点はありません）。\n"
	content += "嘘をつくリスクは低めに設定されているため、[color=#ff3333]ガンガン嘘をついてライバルにプレッシャーをかけ、場を乱しましょう！[/color]\n\n"
	
	content += "[b]◆ 嘘をつける上限（盛り幅）[/b]\n"
	content += "基本上限は [color=#ff3333]実点＋24点[/color] まで嘘の申告が可能です。特定のアイテムを装備することで上限を拡張できます。\n\n"
	
	content += "[b]◆ ダウト成功ボーナス[/b]\n"
	content += "嘘を見破ると、相手の盛り幅の [color=#33cc33]75% ＋ 6点[/color] （勉強会チャット使用時はさらに＋6点）をボーナスとして獲得します。\n\n"
	
	content += "[b]◆ ダウト失敗ペナルティ[/b]\n"
	content += "正直な人に誤ってダウトすると減点になります（日程経過で [color=#ff3333]10点〜18点[/color]）。\n"
	content += "座布団で半減、耳栓で-10点の軽減が可能です。\n\n"
	
	content += "[b]◆ 勝敗の決め方（最終得点）[/b]\n"
	content += "5日間の「申告した点数の合計」を競いますが、ダウト（嘘の指摘）の結果によって最終得点が大きく変動します！\n"
	content += "【最終得点】 ＝ [color=#ff9900]5日間の申告点 ＋ ダウト成功ボーナス － ダウト失敗ペナルティ － 嘘バレによる実点への減算[/color]\n"
	content += "つまり、[color=#ff9900][b]ただカードを引くだけでなく、上手に嘘をつき、相手の嘘を見破ることで勝利に近づきます！[/b][/color]"
	
	text_rtb.text = content
	vbox.add_child(text_rtb)
	
	var txt_pnl = rtb.get_parent().get_parent()
	if txt_pnl and txt_pnl is PanelContainer:
		txt_pnl.visible = false
