class_name RulebookModal
extends CanvasLayer

static func create_and_show(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = RulebookModal.new()
	parent_node.add_child(canvas)

var current_page: int = 0
var max_pages: int = 5

var modal: PanelContainer
var content_clip: Control
var content_slider: HBoxContainer
var page_dots_hbox: HBoxContainer
var prev_btn: Button
var next_btn: Button
var dots: Array[ColorRect] = []

var active_page_tweens: Array[Tween] = []

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
	DeskTheme.add_ruled_lines(modal)
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
	
	# Content Area (Clipped for sliding)
	var content_container = PanelContainer.new()
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.clip_contents = true
	content_container.add_theme_stylebox_override("panel", DeskTheme.create_white_panel())
	vbox.add_child(content_container)
	
	content_clip = Control.new()
	content_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_container.add_child(content_clip)
	
	content_slider = HBoxContainer.new()
	content_slider.add_theme_constant_override("separation", 0)
	content_slider.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_clip.add_child(content_slider)
	
	# Build all pages and add to slider
	for i in range(max_pages):
		var page = _build_page(i)
		page.custom_minimum_size = Vector2(982, 542) # Width and height to fit container exactly
		content_slider.add_child(page)
	
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
	
	page_dots_hbox = HBoxContainer.new()
	page_dots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	page_dots_hbox.add_theme_constant_override("separation", 15)
	footer_hbox.add_child(page_dots_hbox)
	
	for i in range(max_pages):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.color = DeskTheme.COLOR_INK if i == 0 else DeskTheme.COLOR_CRAFT.darkened(0.2)
		var dot_container = CenterContainer.new()
		dot_container.custom_minimum_size = Vector2(16, 16)
		dot.pivot_offset = Vector2(6, 6)
		dot_container.add_child(dot)
		page_dots_hbox.add_child(dot_container)
		dots.append(dot)
	
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
		else:
			_close_modal()
	)
	footer_hbox.add_child(next_btn)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(40, 0)
	footer_hbox.add_child(spacer)
	
	var play_tutorial_btn = Button.new()
	play_tutorial_btn.text = " ★ チュートリアル対戦へ ★ "
	play_tutorial_btn.custom_minimum_size = Vector2(300, 50)
	play_tutorial_btn.add_theme_font_override("font", DeskTheme.get_font())
	play_tutorial_btn.add_theme_font_size_override("font_size", 18)
	_apply_tutorial_button_style(play_tutorial_btn)
	play_tutorial_btn.pressed.connect(_start_tutorial)
	footer_hbox.add_child(play_tutorial_btn)
	
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
	
	_show_page(0, true)

func _close_modal() -> void:
	_clear_tweens()
	var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
	out_tween.tween_callback(func(): queue_free())

func _start_tutorial() -> void:
	Global.is_tutorial_mode = true
	Global.game_mode = Constants.MODE_CPU
	Global.opponent_profiles = {
		"cpu_sato": {"name": "佐藤くん"},
		"cpu_suzuki": {"name": "鈴木さん"},
		"cpu_takahashi": {"name": "高橋くん"}
	}
	if Global.player_name == "":
		Global.player_name = "プレイヤー"
	
	_clear_tweens()
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

func _show_page(idx: int, immediate: bool = false) -> void:
	current_page = idx
	prev_btn.disabled = (current_page == 0)
	
	if current_page == max_pages - 1:
		next_btn.text = " 閉じる "
	else:
		next_btn.text = " 次へ ＞ "
	
	# Update dots
	for i in range(max_pages):
		var dot = dots[i]
		if i == current_page:
			dot.color = DeskTheme.COLOR_INK
			var tw = create_tween()
			tw.tween_property(dot, "scale", Vector2(1.2, 1.2), 0.2)
		else:
			dot.color = DeskTheme.COLOR_CRAFT.darkened(0.2)
			var tw = create_tween()
			tw.tween_property(dot, "scale", Vector2.ONE, 0.2)
			
	# Slide transition
	var target_x = -idx * 982.0
	if immediate:
		content_slider.position.x = target_x
		_play_page_animations(idx)
	else:
		_clear_tweens()
		var tween = create_tween().bind_node(content_slider).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(content_slider, "position:x", target_x, 0.4)
		tween.tween_callback(func(): _play_page_animations(idx))

func _clear_tweens() -> void:
	for t in active_page_tweens:
		if t and t.is_valid():
			t.kill()
	active_page_tweens.clear()

func _play_page_animations(idx: int) -> void:
	var page_node = content_slider.get_child(idx)
	if page_node.has_method("play_animations"):
		var tweens = page_node.play_animations()
		if tweens is Array:
			active_page_tweens.append_array(tweens)

# ==========================================
# Page Building
# ==========================================

# --- Page 0: Intro ---
func _setup_page_0(page: Control, visual_area: Control, rtb: RichTextLabel) -> void:
	var ctrl = Control.new()
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual_area.add_child(ctrl)
	
	var title = _create_title_label("① テストまであと3日！", DeskTheme.COLOR_GREEN)
	title.position = Vector2(350, 20)
	ctrl.add_child(title)
	
	# Mock Notebook UI
	var notebook = PanelContainer.new()
	notebook.custom_minimum_size = Vector2(400, 250)
	notebook.position = Vector2(290, 80)
	notebook.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	DeskTheme.add_ruled_lines(notebook)
	ctrl.add_child(notebook)
	
	var c1 = CardVisual.create({"value": 4})
	c1.scale = Vector2(0.8, 0.8)
	c1.position = Vector2(330, 110)
	c1.rotation_degrees = -5
	ctrl.add_child(c1)
	
	var c2 = CardVisual.create({"value": 10})
	c2.scale = Vector2(0.8, 0.8)
	c2.position = Vector2(450, 110)
	c2.rotation_degrees = 5
	ctrl.add_child(c2)

	var c3 = CardVisual.create({"value": 7})
	c3.scale = Vector2(0.8, 0.8)
	c3.position = Vector2(570, 110)
	c3.rotation_degrees = 15
	ctrl.add_child(c3)
	
	rtb.text = "[center][b][font_size=24]熾烈な勉強レース開幕[/font_size][/b][/center]\n実点（実際の勉強成果）と申告点（嘘）を競う[color=#ff4081][b]3日間[/b][/color]のチキンレース！\n最終的に一番点数の高い人が優勝です。"
	
	page.set_meta("play_animations", func() -> Array[Tween]:
		var tw = page.create_tween().set_loops()
		tw.tween_property(c1, "position:y", 100.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(c2, "position:y", 120.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(c3, "position:y", 100.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		tw.tween_property(c1, "position:y", 110.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(c2, "position:y", 110.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(c3, "position:y", 110.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return [tw]
	)
	page.set_script(preload("res://src/ui/modals/RulebookPageProxy.gd"))

func _build_page(idx: int) -> Control:
	var page = Control.new()
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(vbox)
	
	var visual_area = Control.new()
	visual_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(visual_area)
	
	var text_panel = PanelContainer.new()
	text_panel.custom_minimum_size = Vector2(0, 140)
	var tp_style = StyleBoxFlat.new()
	tp_style.bg_color = Color(0, 0, 0, 0.03)
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
		0: _setup_page_0(page, visual_area, rtb) # Intro
		1: _setup_page_1(page, visual_area, rtb) # Draw
		2: _setup_page_2(page, visual_area, rtb) # Burst
		3: _setup_page_3(page, visual_area, rtb) # Report
		4: _setup_page_4(page, visual_area, rtb) # Doubt
		
	return page

func _create_title_label(text: String, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", DeskTheme.get_font())
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

# --- Page 1: Overview (Card Drawing) ---
func _setup_page_1(page: Control, visual_area: Control, rtb: RichTextLabel) -> void:
	var ctrl = Control.new()
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual_area.add_child(ctrl)
	
	var title = _create_title_label("② 自習で実点を積む", DeskTheme.COLOR_GREEN)
	title.position = Vector2(350, 20)
	ctrl.add_child(title)
	
	# Mock Notebook UI (Target area)
	var notebook = PanelContainer.new()
	notebook.custom_minimum_size = Vector2(400, 250)
	notebook.position = Vector2(480, 80)
	notebook.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	DeskTheme.add_ruled_lines(notebook)
	ctrl.add_child(notebook)
	
	var deck = TextureRect.new()
	if ResourceLoader.exists("res://assets/cards/card_back.png"):
		deck.texture = load("res://assets/cards/card_back.png")
	deck.position = Vector2(100, 100)
	deck.scale = Vector2(0.8, 0.8)
	ctrl.add_child(deck)
	
	var deck_lbl = Label.new()
	deck_lbl.text = "山札"
	deck_lbl.add_theme_font_override("font", DeskTheme.get_font())
	deck_lbl.add_theme_font_size_override("font_size", 20)
	deck_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	deck_lbl.position = Vector2(130, 240)
	ctrl.add_child(deck_lbl)
	
	var c1 = CardVisual.create({"value": 4})
	c1.scale = Vector2(0.8, 0.8)
	c1.position = Vector2(520, 110)
	c1.rotation_degrees = -5
	ctrl.add_child(c1)
	
	var c2 = CardVisual.create({"value": 10})
	c2.scale = Vector2(0.8, 0.8)
	c2.position = Vector2(640, 110)
	c2.rotation_degrees = 5
	ctrl.add_child(c2)
	
	var c3 = CardVisual.create({"value": 7})
	c3.scale = Vector2(0.8, 0.8)
	c3.position = Vector2(100, 100)
	c3.modulate.a = 0
	ctrl.add_child(c3)
	
	var c3_back = TextureRect.new()
	if ResourceLoader.exists("res://assets/cards/card_back.png"):
		c3_back.texture = load("res://assets/cards/card_back.png")
	c3_back.scale = Vector2(0.8, 0.8)
	c3_back.position = Vector2(100, 100)
	c3_back.modulate.a = 0
	ctrl.add_child(c3_back)
	
	rtb.text = "[center][b][font_size=24]カードを引いて点数を稼げ！[/font_size][/b][/center]\n1日3回ある「自習」で山札からカードを引きます。\n引いたカードの数字がそのままあなたの「実点」になります。"
	
	page.set_meta("play_animations", func() -> Array[Tween]:
		var tw = page.create_tween().set_loops()
		# Reset
		tw.tween_callback(func():
			c3.position = Vector2(100, 100)
			c3.modulate.a = 0.0
			c3.scale = Vector2(0.0, 0.8)
			c3.rotation_degrees = 15.0
			
			c3_back.position = Vector2(100, 100)
			c3_back.modulate.a = 0.0
			c3_back.scale = Vector2(0.8, 0.8)
			c3_back.rotation_degrees = 0
		)
		tw.tween_interval(0.5)
		
		# Draw back
		tw.tween_property(c3_back, "modulate:a", 1.0, 0.1)
		tw.parallel().tween_property(c3_back, "position", Vector2(760, 110), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(c3_back, "rotation_degrees", 15.0, 0.6)
		
		# Flip
		tw.tween_property(c3_back, "scale:x", 0.0, 0.2).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			c3.position = c3_back.position
			c3.modulate.a = 1.0
			c3_back.modulate.a = 0.0
		)
		tw.tween_property(c3, "scale:x", 0.8, 0.2).set_ease(Tween.EASE_OUT)
		
		tw.tween_interval(1.5)
		# Fade out c3 to restart
		tw.tween_property(c3, "modulate:a", 0.0, 0.3)
		return [tw]
	)
	page.set_script(preload("res://src/ui/modals/RulebookPageProxy.gd"))

# --- Page 2: Burst (Card draw + Shake + UI) ---
func _setup_page_2(page: Control, visual_area: Control, rtb: RichTextLabel) -> void:
	var ctrl = Control.new()
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual_area.add_child(ctrl)
	
	var title = _create_title_label("③ 欲張るな危険！「バースト」", Color("#ff4081"))
	title.position = Vector2(300, 10)
	ctrl.add_child(title)
	
	# Center Notebook
	var notebook = PanelContainer.new()
	notebook.custom_minimum_size = Vector2(500, 260)
	notebook.position = Vector2(240, 60)
	notebook.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	DeskTheme.add_ruled_lines(notebook)
	ctrl.add_child(notebook)
	
	var c7_1 = CardVisual.create({"value": 7})
	c7_1.scale = Vector2(0.8, 0.8)
	c7_1.position = Vector2(300, 80)
	c7_1.rotation_degrees = -5
	ctrl.add_child(c7_1)
	
	var deck = TextureRect.new()
	if ResourceLoader.exists("res://assets/cards/card_back.png"):
		deck.texture = load("res://assets/cards/card_back.png")
	deck.position = Vector2(50, 100)
	deck.scale = Vector2(0.8, 0.8)
	ctrl.add_child(deck)
	
	var c7_2 = CardVisual.create({"value": 7})
	c7_2.scale = Vector2(0.8, 0.8)
	c7_2.position = Vector2(50, 100)
	c7_2.modulate.a = 0
	ctrl.add_child(c7_2)
	
	var c7_2_back = TextureRect.new()
	if ResourceLoader.exists("res://assets/cards/card_back.png"):
		c7_2_back.texture = load("res://assets/cards/card_back.png")
	c7_2_back.scale = Vector2(0.8, 0.8)
	c7_2_back.position = Vector2(50, 100)
	c7_2_back.modulate.a = 0
	ctrl.add_child(c7_2_back)
	
	var burst_lbl = Label.new()
	burst_lbl.text = "寝落ち\n(バースト)!"
	burst_lbl.add_theme_font_override("font", DeskTheme.get_font())
	burst_lbl.add_theme_font_size_override("font_size", 54)
	burst_lbl.add_theme_color_override("font_color", Color.WHITE)
	burst_lbl.add_theme_color_override("font_outline_color", Color("#d50000"))
	burst_lbl.add_theme_constant_override("outline_size", 16)
	burst_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burst_lbl.position = Vector2(350, 100)
	burst_lbl.rotation_degrees = -10
	burst_lbl.scale = Vector2.ZERO
	ctrl.add_child(burst_lbl)
	
	rtb.text = "[center][b][font_size=24]同じ数字で即寝落ち！[/font_size][/b][/center]\n[color=#ff4081][b]手札と同じ数字[/b][/color]を引くと「[color=#ff4081][b]寝落ち（バースト）[/b][/color]」して[b]0点[/b]に！\n欲張らず、適度なところで「休憩」して点数を確定させましょう。"
	
	page.set_meta("play_animations", func() -> Array[Tween]:
		var tw = page.create_tween().set_loops()
		tw.tween_callback(func():
			c7_2.position = Vector2(50, 100)
			c7_2.modulate = Color.TRANSPARENT
			c7_2.scale = Vector2(0.0, 0.8)
			c7_2.rotation_degrees = 8.0
			
			c7_2_back.position = Vector2(50, 100)
			c7_2_back.modulate = Color.TRANSPARENT
			c7_2_back.scale = Vector2(0.8, 0.8)
			c7_2_back.rotation_degrees = 0
			
			c7_1.modulate = Color.WHITE
			burst_lbl.scale = Vector2.ZERO
			notebook.position = Vector2(240, 60)
		)
		tw.tween_interval(0.5)
		# Draw back
		tw.tween_property(c7_2_back, "modulate:a", 1.0, 0.1)
		tw.parallel().tween_property(c7_2_back, "position", Vector2(460, 90), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(c7_2_back, "rotation_degrees", 8.0, 0.5)
		
		# Flip
		tw.tween_property(c7_2_back, "scale:x", 0.0, 0.2).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			c7_2.position = c7_2_back.position
			c7_2.modulate = Color.WHITE
			c7_2_back.modulate.a = 0.0
		)
		tw.tween_property(c7_2, "scale:x", 0.8, 0.2).set_ease(Tween.EASE_OUT)
		
		# Burst impact
		tw.chain().tween_callback(func():
			var shake_tw = page.create_tween()
			for i in range(5):
				shake_tw.tween_property(notebook, "position:x", 240 + randf_range(-10, 10), 0.05)
			shake_tw.tween_property(notebook, "position:x", 240, 0.05)
		)
		tw.parallel().tween_property(burst_lbl, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE)
		tw.parallel().tween_property(c7_1, "modulate", Color(1.0, 0.3, 0.3), 0.3)
		tw.parallel().tween_property(c7_2, "modulate", Color(1.0, 0.3, 0.3), 0.3)
		
		tw.tween_interval(2.0)
		return [tw]
	)
	page.set_script(preload("res://src/ui/modals/RulebookPageProxy.gd"))

# --- Page 3: SNS Share (Phone UI & Slider move) ---
func _setup_page_3(page: Control, visual_area: Control, rtb: RichTextLabel) -> void:
	var ctrl = Control.new()
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual_area.add_child(ctrl)
	
	var title = _create_title_label("④ SNS報告は戦場。「嘘」も戦略！", Color("#2979ff"))
	title.position = Vector2(300, 0)
	ctrl.add_child(title)
	
	var phone_wrapper = Control.new()
	phone_wrapper.position = Vector2(500, 240)
	phone_wrapper.scale = Vector2(0.5, 0.5)
	ctrl.add_child(phone_wrapper)
	
	# SMARTPHONE CONTAINER (Perfect Replica)
	var phone_panel = PanelContainer.new()
	phone_panel.custom_minimum_size = Vector2(420, 800)
	phone_panel.size = Vector2(420, 800)
	phone_panel.pivot_offset = Vector2(210, 400)
	phone_panel.position = Vector2(-210, -400) # Center around wrapper
	
	var phone_style = StyleBoxFlat.new()
	phone_style.bg_color = DeskTheme.COLOR_INK
	phone_style.border_color = Color("37474f")
	phone_style.border_width_left = 12
	phone_style.border_width_right = 12
	phone_style.border_width_top = 32
	phone_style.border_width_bottom = 32
	phone_style.corner_radius_top_left = 28
	phone_style.corner_radius_top_right = 28
	phone_style.corner_radius_bottom_left = 28
	phone_style.corner_radius_bottom_right = 28
	phone_panel.add_theme_stylebox_override("panel", phone_style)
	phone_wrapper.add_child(phone_panel)
	
	var phone_vbox = VBoxContainer.new()
	phone_vbox.add_theme_constant_override("separation", 10)
	phone_panel.add_child(phone_vbox)
	
	var status_bar = Label.new()
	status_bar.text = "16:00  |  チキスタ投稿"
	status_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_bar.add_theme_font_size_override("font_size", 16)
	status_bar.add_theme_color_override("font_color", Color.WHITE)
	phone_vbox.add_child(status_bar)
	
	var app_margin = MarginContainer.new()
	app_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_margin.add_theme_constant_override("margin_left", 20)
	app_margin.add_theme_constant_override("margin_right", 20)
	app_margin.add_theme_constant_override("margin_top", 15)
	app_margin.add_theme_constant_override("margin_bottom", 15)
	phone_vbox.add_child(app_margin)
	
	var app_vbox = VBoxContainer.new()
	app_vbox.add_theme_constant_override("separation", 24)
	app_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	app_margin.add_child(app_vbox)
	
	var post_card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = DeskTheme.COLOR_CRAFT
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.border_color = Color("cfd8dc")
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	post_card.add_theme_stylebox_override("panel", card_style)
	app_vbox.add_child(post_card)
	
	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 20)
	card_margin.add_theme_constant_override("margin_right", 20)
	card_margin.add_theme_constant_override("margin_top", 20)
	card_margin.add_theme_constant_override("margin_bottom", 20)
	post_card.add_child(card_margin)
	
	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 18)
	card_margin.add_child(card_vbox)
	
	var card_title = Label.new()
	card_title.text = "今日の勉強報告"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.add_theme_font_override("font", DeskTheme.get_font())
	card_title.add_theme_font_size_override("font_size", 28)
	card_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	card_vbox.add_child(card_title)
	
	var actual_hbox = HBoxContainer.new()
	actual_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_child(actual_hbox)
	
	var actual_title = Label.new()
	actual_title.text = "実際の実点（正直）： "
	actual_title.add_theme_font_override("font", DeskTheme.get_font())
	actual_title.add_theme_font_size_override("font_size", 18)
	actual_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	actual_hbox.add_child(actual_title)
	
	var actual_val = Label.new()
	actual_val.text = "20 点"
	actual_val.add_theme_font_override("font", DeskTheme.get_font())
	actual_val.add_theme_font_size_override("font_size", 22)
	actual_val.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	actual_hbox.add_child(actual_val)
	
	var decl_title = Label.new()
	decl_title.text = "投稿する申告点数："
	decl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decl_title.add_theme_font_override("font", DeskTheme.get_font())
	decl_title.add_theme_font_size_override("font_size", 18)
	decl_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	card_vbox.add_child(decl_title)
	
	var declared_score_label = Label.new()
	declared_score_label.text = "20点"
	declared_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	declared_score_label.add_theme_font_override("font", DeskTheme.get_font())
	declared_score_label.add_theme_font_size_override("font_size", 54)
	declared_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	card_vbox.add_child(declared_score_label)
	
	var report_slider = HSlider.new()
	report_slider.min_value = 20
	report_slider.max_value = 50
	report_slider.value = 20
	report_slider.step = 1
	report_slider.custom_minimum_size = Vector2(320, 60)
	report_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var slider_bg = StyleBoxFlat.new()
	slider_bg.bg_color = Color("d1bfae")
	slider_bg.border_color = Color("a68a73")
	slider_bg.border_width_bottom = 2
	slider_bg.expand_margin_top = 10
	slider_bg.expand_margin_bottom = 10
	report_slider.add_theme_stylebox_override("slider", slider_bg)
	
	# Load or mock the eraser texture
	var grabber_icon = ImageTexture.create_from_image(Image.create(30, 20, false, Image.FORMAT_RGBA8))
	if ResourceLoader.exists("res://assets/ui/eraser.png"):
		grabber_icon = load("res://assets/ui/eraser.png")
	report_slider.add_theme_icon_override("grabber", grabber_icon)
	report_slider.add_theme_icon_override("grabber_highlight", grabber_icon)
	
	card_vbox.add_child(report_slider)
	
	var emote_title = Label.new()
	emote_title.text = "表情（ポーカーフェイス）："
	emote_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emote_title.add_theme_font_override("font", DeskTheme.get_font())
	emote_title.add_theme_font_size_override("font_size", 16)
	emote_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	card_vbox.add_child(emote_title)

	var emote_hbox = HBoxContainer.new()
	emote_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	emote_hbox.add_theme_constant_override("separation", 16)
	card_vbox.add_child(emote_hbox)

	var emotes = [
		{"key": "normal", "text": "[普通]"},
		{"key": "confident", "text": "[自信あり]"},
		{"key": "anxious", "text": "[不安]"}
	]
	
	var emote_btn_style_normal = StyleBoxFlat.new()
	emote_btn_style_normal.bg_color = Color("eceff1")
	emote_btn_style_normal.corner_radius_top_left = 6
	emote_btn_style_normal.corner_radius_top_right = 6
	emote_btn_style_normal.corner_radius_bottom_left = 6
	emote_btn_style_normal.corner_radius_bottom_right = 6
	emote_btn_style_normal.content_margin_left = 12
	emote_btn_style_normal.content_margin_right = 12
	emote_btn_style_normal.content_margin_top = 6
	emote_btn_style_normal.content_margin_bottom = 6

	var emote_btn_style_selected = StyleBoxFlat.new()
	emote_btn_style_selected.bg_color = Color("1e88e5") # Active blue
	emote_btn_style_selected.corner_radius_top_left = 6
	emote_btn_style_selected.corner_radius_top_right = 6
	emote_btn_style_selected.corner_radius_bottom_left = 6
	emote_btn_style_selected.corner_radius_bottom_right = 6
	emote_btn_style_selected.content_margin_left = 12
	emote_btn_style_selected.content_margin_right = 12
	emote_btn_style_selected.content_margin_top = 6
	emote_btn_style_selected.content_margin_bottom = 6
	
	for em in emotes:
		var btn = Button.new()
		btn.text = em.text
		btn.add_theme_font_override("font", DeskTheme.get_font())
		btn.add_theme_font_size_override("font_size", 14)
		if em.key == "normal":
			btn.add_theme_stylebox_override("normal", emote_btn_style_selected)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.add_theme_stylebox_override("normal", emote_btn_style_normal)
			btn.add_theme_color_override("font_color", Color("455a64"))
		btn.add_theme_stylebox_override("hover", emote_btn_style_normal)
		btn.add_theme_stylebox_override("pressed", emote_btn_style_selected)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		emote_hbox.add_child(btn)
	
	# Update label when slider moves
	report_slider.value_changed.connect(func(v):
		declared_score_label.text = str(int(v)) + "点"
		if v > 20:
			declared_score_label.add_theme_color_override("font_color", Color("#d500f9"))
		else:
			declared_score_label.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	)
	
	var post_btn = Button.new()
	post_btn.text = "投稿する"
	post_btn.custom_minimum_size = Vector2(160, 40)
	post_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = DeskTheme.COLOR_INK
	btn_style.corner_radius_top_left = 20
	btn_style.corner_radius_top_right = 20
	btn_style.corner_radius_bottom_left = 20
	btn_style.corner_radius_bottom_right = 20
	post_btn.add_theme_stylebox_override("normal", btn_style)
	post_btn.add_theme_color_override("font_color", Color.WHITE)
	phone_vbox.add_child(post_btn)
	
	rtb.text = "[center][b][font_size=24]スライダーで点数を盛れ！[/font_size][/b][/center]\n1日の終わりに成果を投稿します。ここで実際の点数より高く「[color=#d500f9][b]嘘（ブラフ）[/b][/color]」を申告してライバルを焦らせることも可能！"
	
	var cursor = _create_cursor()
	cursor.position = Vector2(600, 300)
	cursor.modulate.a = 0
	ctrl.add_child(cursor)
	
	page.set_meta("play_animations", func() -> Array[Tween]:
		var tw = page.create_tween().set_loops()
		tw.tween_callback(func(): 
			report_slider.value = 20
			cursor.position = Vector2(650, 300)
			cursor.modulate.a = 0
			cursor.scale = Vector2.ONE
		)
		tw.tween_interval(0.5)
		tw.tween_property(cursor, "modulate:a", 1.0, 0.2)
		tw.tween_property(cursor, "position", Vector2(580, 205), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Click and drag
		tw.tween_property(cursor, "scale", Vector2(0.8, 0.8), 0.1)
		tw.tween_property(report_slider, "value", 44.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(cursor, "position", Vector2(650, 205), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Release
		tw.tween_property(cursor, "scale", Vector2.ONE, 0.1)
		
		# Move to post button
		tw.tween_property(cursor, "position", Vector2(620, 265), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Post button click simulation
		tw.tween_property(cursor, "scale", Vector2(0.8, 0.8), 0.1)
		tw.parallel().tween_property(post_btn, "scale", Vector2(0.95, 0.95), 0.1)
		tw.tween_property(cursor, "scale", Vector2.ONE, 0.1)
		tw.parallel().tween_property(post_btn, "scale", Vector2.ONE, 0.1)
		
		tw.tween_property(cursor, "modulate:a", 0.0, 0.2)
		tw.tween_interval(1.5)
		return [tw]
	)
	page.set_script(preload("res://src/ui/modals/RulebookPageProxy.gd"))

# --- Page 4: Doubt (Click button -> Result pop) ---
func _setup_page_4(page: Control, visual_area: Control, rtb: RichTextLabel) -> void:
	var ctrl = Control.new()
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual_area.add_child(ctrl)
	
	var title = _create_title_label("⑤ 最終答え合わせで大逆転！", Color("#d50000"))
	title.position = Vector2(300, 10)
	ctrl.add_child(title)
	
	# Result Timeline Mock
	var post_panel = PanelContainer.new()
	post_panel.custom_minimum_size = Vector2(400, 120)
	post_panel.position = Vector2(290, 80)
	var pp_style = StyleBoxFlat.new()
	pp_style.bg_color = DeskTheme.COLOR_CRAFT
	pp_style.border_color = Color("#cfd8dc")
	pp_style.border_width_left = 2
	pp_style.border_width_right = 2
	pp_style.border_width_top = 2
	pp_style.border_width_bottom = 2
	pp_style.corner_radius_top_left = 8
	pp_style.corner_radius_top_right = 8
	pp_style.corner_radius_bottom_left = 8
	pp_style.corner_radius_bottom_right = 8
	post_panel.add_theme_stylebox_override("panel", pp_style)
	ctrl.add_child(post_panel)
	
	var pp_vbox = VBoxContainer.new()
	pp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	post_panel.add_child(pp_vbox)
	
	var pp_name = Label.new()
	pp_name.text = "ライバルの投稿"
	pp_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pp_name.add_theme_font_override("font", DeskTheme.get_font())
	pp_name.add_theme_font_size_override("font_size", 16)
	pp_name.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	pp_vbox.add_child(pp_name)
	
	var pp_score = Label.new()
	pp_score.text = "「65点取りました！」"
	pp_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pp_score.add_theme_font_override("font", DeskTheme.get_font())
	pp_score.add_theme_font_size_override("font_size", 24)
	pp_score.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	pp_vbox.add_child(pp_score)
	
	var doubt_btn = Button.new()
	doubt_btn.text = "ダウト！"
	doubt_btn.custom_minimum_size = Vector2(200, 80)
	doubt_btn.position = Vector2(390, 220)
	doubt_btn.add_theme_font_override("font", DeskTheme.get_font())
	doubt_btn.add_theme_font_size_override("font_size", 40)
	var d_bstyle = StyleBoxFlat.new()
	d_bstyle.bg_color = Color("#e53935")
	d_bstyle.border_width_bottom = 8
	d_bstyle.border_color = Color("#b71c1c")
	d_bstyle.corner_radius_top_left = 20
	d_bstyle.corner_radius_top_right = 20
	d_bstyle.corner_radius_bottom_left = 20
	d_bstyle.corner_radius_bottom_right = 20
	doubt_btn.add_theme_stylebox_override("normal", d_bstyle)
	doubt_btn.add_theme_color_override("font_color", Color.WHITE)
	doubt_btn.pivot_offset = doubt_btn.custom_minimum_size / 2.0
	ctrl.add_child(doubt_btn)
	
	var result_lbl = Label.new()
	result_lbl.text = "ダウト成功！ 相手の盛り点を奪った！"
	result_lbl.add_theme_font_override("font", DeskTheme.get_font())
	result_lbl.add_theme_font_size_override("font_size", 32)
	result_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	result_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	result_lbl.add_theme_constant_override("outline_size", 8)
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.position = Vector2(200, 160)
	result_lbl.scale = Vector2.ZERO
	result_lbl.pivot_offset = Vector2(300, 20)
	ctrl.add_child(result_lbl)
	
	rtb.text = "[center][b][font_size=24]嘘を見破って得点を奪え！[/font_size][/b][/center]\n3日目の最後に全員の点数が大公開！\n他人の嘘を「[color=#d50000][b]ダウト[/b][/color]」で見破れば、相手の盛り点をもらえます。"
	
	var cursor = _create_cursor()
	cursor.position = Vector2(580, 320)
	cursor.modulate.a = 0
	ctrl.add_child(cursor)
	
	page.set_meta("play_animations", func() -> Array[Tween]:
		var tw = page.create_tween().set_loops()
		tw.tween_callback(func():
			result_lbl.scale = Vector2.ZERO
			cursor.position = Vector2(580, 320)
			cursor.modulate.a = 0
			cursor.scale = Vector2.ONE
		)
		tw.tween_interval(0.5)
		
		# Move cursor
		tw.tween_property(cursor, "modulate:a", 1.0, 0.2)
		tw.tween_property(cursor, "position", Vector2(490, 260), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Button press simulation
		tw.tween_property(cursor, "scale", Vector2(0.8, 0.8), 0.1)
		tw.parallel().tween_property(doubt_btn, "scale", Vector2(0.9, 0.9), 0.1)
		
		tw.tween_property(cursor, "scale", Vector2.ONE, 0.1)
		tw.parallel().tween_property(doubt_btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BOUNCE)
		
		# Result pop
		tw.tween_property(result_lbl, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BOUNCE)
		tw.tween_property(result_lbl, "scale", Vector2.ONE, 0.1)
		
		tw.tween_property(cursor, "modulate:a", 0.0, 0.2)
		tw.tween_interval(2.0)
		return [tw]
	)
	page.set_script(preload("res://src/ui/modals/RulebookPageProxy.gd"))

func _create_cursor() -> Polygon2D:
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(16, 16), Vector2(10, 16), Vector2(14, 24), Vector2(10, 26), Vector2(6, 18), Vector2(0, 22)
	])
	poly.color = Color.WHITE
	var outline = Line2D.new()
	outline.points = poly.polygon
	outline.closed = true
	outline.width = 2
	outline.default_color = Color.BLACK
	poly.add_child(outline)
	# Add slight drop shadow
	var shadow = Polygon2D.new()
	shadow.polygon = poly.polygon
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.position = Vector2(2, 2)
	shadow.show_behind_parent = true
	poly.add_child(shadow)
	return poly
