class_name LoadoutScene
extends Control

var slots_grid: GridContainer
var back_btn: Button

# Select modal
var select_modal: PanelContainer
var select_grid: GridContainer
var active_slot_idx: int = -1

func _ready() -> void:
	# 木枠（のっぺりした外側の淵）
	var frame = ColorRect.new()
	frame.color = Color("#4e342e") # 落ち着いた木枠の色（焦げ茶）
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	
	# 枠の太さ（マージン）を設定
	var board_margin = MarginContainer.new()
	board_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_margin.add_theme_constant_override("margin_left", 36)
	board_margin.add_theme_constant_override("margin_right", 36)
	board_margin.add_theme_constant_override("margin_top", 36)
	board_margin.add_theme_constant_override("margin_bottom", 36)
	add_child(board_margin)
	
	# コルクボード部分のベース（木枠から一段落ち込んでいる立体感を出すための影付き）
	var cork_base = PanelContainer.new()
	var base_style = StyleBoxFlat.new()
	base_style.bg_color = Color.BLACK # テクスチャの下敷き
	base_style.border_width_left = 4
	base_style.border_width_right = 4
	base_style.border_width_top = 4
	base_style.border_width_bottom = 4
	base_style.border_color = Color("#261a17") # コルクと木枠の間の暗い溝
	cork_base.add_theme_stylebox_override("panel", base_style)
	board_margin.add_child(cork_base)
	
	var cork_panel = Panel.new()
	
	var cork_style = StyleBoxTexture.new()
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.15
	noise.cellular_jitter = 1.0
	noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	
	var tex = NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([Color("7a5632"), Color("9e754a"), Color("b48b59")])
	tex.color_ramp = grad
	
	cork_style.texture = tex
	cork_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	cork_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	cork_panel.add_theme_stylebox_override("panel", cork_style)
	cork_base.add_child(cork_panel)
	
	# Center container for VBox
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 35)
	center_container.add_child(main_vbox)
	
	# Title Box (付箋風・画用紙風の背景にしてコルクボードとのコントラストを出す)
	var title_panel = PanelContainer.new()
	title_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color("#fdfbf7") # わずかにクリーム色
	title_style.border_width_left = 3
	title_style.border_width_right = 3
	title_style.border_width_top = 3
	title_style.border_width_bottom = 3
	title_style.border_color = DeskTheme.COLOR_INK
	title_style.corner_radius_top_left = 2
	title_style.corner_radius_top_right = 6
	title_style.corner_radius_bottom_left = 6
	title_style.corner_radius_bottom_right = 2
	title_style.shadow_color = Color(0, 0, 0, 0.15)
	title_style.shadow_size = 6
	title_style.shadow_offset = Vector2(4, 4)
	title_style.content_margin_left = 30
	title_style.content_margin_right = 30
	title_style.content_margin_top = 16
	title_style.content_margin_bottom = 16
	title_panel.add_theme_stylebox_override("panel", title_style)
	main_vbox.add_child(title_panel)
	
	var title_vbox = VBoxContainer.new()
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_vbox.add_theme_constant_override("separation", 8)
	title_panel.add_child(title_vbox)
	
	# Title
	var title = Label.new()
	title.text = "デッキ編成（付箋スロット割当）"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title_vbox.add_child(title)
	
	var sub_title = Label.new()
	sub_title.text = "1〜10の数字のカードを引いた時に、対応するスロットのアイテムの効果が発動します。"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	sub_title.add_theme_font_size_override("font_size", 20)
	sub_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	title_vbox.add_child(sub_title)
	
	# 5x2 slots grid
	slots_grid = GridContainer.new()
	slots_grid.columns = 5
	slots_grid.add_theme_constant_override("h_separation", 30)
	slots_grid.add_theme_constant_override("v_separation", 30)
	main_vbox.add_child(slots_grid)
	
	# Populate 10 slots
	populate_slots()
	
	# Back button
	back_btn = Button.new()
	back_btn.text = "タイトルに戻る"
	back_btn.custom_minimum_size = Vector2(320, 70)
	back_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	back_btn.add_theme_font_size_override("font_size", 26)
	Global.apply_white_button_style(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	main_vbox.add_child(back_btn)
	
	# SELECT MODAL (hidden initially)
	setup_select_modal()

func populate_slots() -> void:
	for child in slots_grid.get_children():
		child.queue_free()
		
	for i in range(1, 11):
		var item_id = Global.current_deck.get(i, "")
		var item = CardData.ITEMS.get(item_id, {"name": "空き", "role": CardData.ROLE_PREP})
		
		# Slotted sticky note panel
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(240, 200)
		slot_btn.pivot_offset = Vector2(120, 100)
		
		# Slight loose tilt angles
		slot_btn.rotation_degrees = randf_range(-2.0, 2.0)
		
		var note_style = StyleBoxFlat.new()
		note_style.bg_color = DeskTheme.COLOR_CRAFT
		note_style.border_color = CardData.get_role_color(item["role"])
		note_style.border_width_top = 28 # Top sticky binding part
		note_style.border_width_left = 2
		note_style.border_width_right = 2
		note_style.border_width_bottom = 2
		note_style.corner_radius_bottom_left = 6
		note_style.corner_radius_bottom_right = 6
		note_style.shadow_color = Color(0, 0, 0, 0.25)
		note_style.shadow_size = 8
		note_style.shadow_offset = Vector2(4, 4)
		
		slot_btn.add_theme_stylebox_override("normal", note_style)
		slot_btn.add_theme_stylebox_override("hover", note_style)
		slot_btn.add_theme_stylebox_override("pressed", note_style)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_btn.add_child(vbox)
		
		var num_lbl = Label.new()
		num_lbl.text = "スロット " + str(i)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		num_lbl.add_theme_font_size_override("font_size", 14)
		num_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
		vbox.add_child(num_lbl)
		
		# Show item image if equipped (and isn't empty)
		if item_id != "":
			var img_path = CardData.get_item_image_path(item_id)
			if img_path != "":
				var img_rect = TextureRect.new()
				img_rect.texture = load(img_path)
				img_rect.custom_minimum_size = Vector2(64, 64)
				img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				img_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				vbox.add_child(img_rect)
			else:
				var spacer = Control.new()
				spacer.custom_minimum_size = Vector2(64, 20)
				vbox.add_child(spacer)
		else:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(64, 40)
			vbox.add_child(spacer)
			
		var name_lbl = Label.new()
		name_lbl.text = item["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(name_lbl)
		
		# Hover animations
		slot_btn.mouse_entered.connect(func(): DeskTheme.animate_hover(slot_btn, true, Vector2.ONE, 0.12))
		slot_btn.mouse_exited.connect(func(): DeskTheme.animate_hover(slot_btn, false, Vector2.ONE, 0.12))
		slot_btn.pressed.connect(func():
			DeskTheme.animate_click(slot_btn, Vector2.ONE, 0.08)
			_on_slot_clicked(i)
		)
		
		slots_grid.add_child(slot_btn)

func setup_select_modal() -> void:
	select_modal = PanelContainer.new()
	select_modal.custom_minimum_size = Vector2(900, 650)
	select_modal.pivot_offset = Vector2(450, 325)
	select_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(select_modal)
	select_modal.position = get_viewport_rect().size * 0.5 - select_modal.pivot_offset
	select_modal.visible = false
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	margin.add_theme_constant_override("margin_top", 35)
	margin.add_theme_constant_override("margin_bottom", 35)
	select_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "アイテムの入れ替え"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	# Scroll for unlocked items
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	select_grid = GridContainer.new()
	select_grid.columns = 4
	select_grid.add_theme_constant_override("h_separation", 20)
	select_grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(select_grid)
	
	var close_btn = Button.new()
	close_btn.text = "閉じる"
	close_btn.custom_minimum_size = Vector2(200, 55)
	close_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	close_btn.add_theme_font_size_override("font_size", 20)
	Global.apply_white_button_style(close_btn)
	close_btn.pressed.connect(func():
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		select_modal.visible = false
	)
	vbox.add_child(close_btn)

func _on_slot_clicked(slot_num: int) -> void:
	active_slot_idx = slot_num
	select_modal.visible = true
	
	# Spawn unlocked items in modal grid
	populate_select_list()
	
	# Smooth modal scale pop-in (zoom) without wobbly overshoot
	select_modal.scale = Vector2(0.85, 0.85)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(select_modal, "scale", Vector2.ONE, 0.25)

func populate_select_list() -> void:
	for child in select_grid.get_children():
		child.queue_free()
		
	for item_id in Global.unlocked_items:
		var item = CardData.ITEMS.get(item_id, {})
		if item.is_empty():
			continue
			
		var item_btn = Button.new()
		item_btn.text = ""
		item_btn.custom_minimum_size = Vector2(180, 70)
		
		# Role colors on border
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = DeskTheme.COLOR_CRAFT
		btn_style.border_color = CardData.get_role_color(item["role"])
		btn_style.border_width_left = 3
		btn_style.border_width_right = 3
		btn_style.border_width_top = 3
		btn_style.border_width_bottom = 3
		btn_style.corner_radius_top_left = 4
		btn_style.corner_radius_top_right = 4
		btn_style.corner_radius_bottom_left = 4
		btn_style.corner_radius_bottom_right = 4
		
		var btn_hover = btn_style.duplicate() as StyleBoxFlat
		btn_hover.bg_color = Color("e5dec9") # slightly darker craft
		
		item_btn.add_theme_stylebox_override("normal", btn_style)
		item_btn.add_theme_stylebox_override("hover", btn_hover)
		item_btn.add_theme_stylebox_override("pressed", btn_hover)
		item_btn.add_theme_stylebox_override("focus", btn_style)
		
		var btn_hbox = HBoxContainer.new()
		btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_hbox.add_theme_constant_override("separation", 8)
		btn_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_btn.add_child(btn_hbox)
		
		var img_path = CardData.get_item_image_path(item_id)
		if img_path != "":
			var icon_rect = TextureRect.new()
			icon_rect.texture = load(img_path)
			icon_rect.custom_minimum_size = Vector2(36, 36)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			btn_hbox.add_child(icon_rect)
			
		var name_lbl = Label.new()
		name_lbl.text = item["name"]
		name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		btn_hbox.add_child(name_lbl)
		
		item_btn.pressed.connect(func():
			DeskTheme.animate_click(item_btn, Vector2.ONE, 0.08)
			_on_item_selected(item_id)
		)
		select_grid.add_child(item_btn)

func _on_item_selected(item_id: String) -> void:
	var duplicate_slot = -1
	for slot_idx in Global.current_deck.keys():
		if int(slot_idx) != active_slot_idx and Global.current_deck[slot_idx] == item_id:
			duplicate_slot = int(slot_idx)
			break
			
	if duplicate_slot != -1:
		var prev_item = Global.current_deck[active_slot_idx]
		Global.current_deck[duplicate_slot] = prev_item
		Global.current_deck[active_slot_idx] = item_id
		DeskTheme.show_toast(self, "スロット %d と入れ替えました！" % duplicate_slot)
	else:
		Global.current_deck[active_slot_idx] = item_id
		var item_name = CardData.ITEMS.get(item_id, {}).get("name", "アイテム")
		DeskTheme.show_toast(self, "%s を装備しました！" % item_name)
		
	Global.save_game()
	select_modal.visible = false
	populate_slots()

func _on_back_pressed() -> void:
	DeskTheme.animate_click(back_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
	)
