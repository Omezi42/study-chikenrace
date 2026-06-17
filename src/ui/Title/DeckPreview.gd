class_name DeckPreview
extends VBoxContainer

signal preset_selected(preset_idx: int)

var preset_buttons_hbox: HBoxContainer
var title_preset_buttons: Array[Button] = []
var deck_icons_grid: GridContainer

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# プリセット選択ボタンHBox
	preset_buttons_hbox = HBoxContainer.new()
	preset_buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	preset_buttons_hbox.add_theme_constant_override("separation", 10)
	add_child(preset_buttons_hbox)
	
	# P1, P2, P3の作成
	for i in range(1, 4):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 36)
		btn.add_theme_font_override("font", DeskTheme.get_font())
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		
		# デフォルトスタイル (付箋風)
		var style = StyleBoxFlat.new()
		style.bg_color = Color("f5f5f5")
		style.border_color = Color("cccccc")
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		btn.add_theme_stylebox_override("normal", style)
		
		var idx = i
		btn.pressed.connect(func():
			btn.release_focus()
			DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
			preset_selected.emit(idx)
		)
		
		preset_buttons_hbox.add_child(btn)
		title_preset_buttons.append(btn)
		
	# デッキグリッド
	deck_icons_grid = GridContainer.new()
	deck_icons_grid.columns = 5
	deck_icons_grid.add_theme_constant_override("h_separation", 16)
	deck_icons_grid.add_theme_constant_override("v_separation", 14)
	deck_icons_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	deck_icons_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(deck_icons_grid)

func update_deck(deck: Dictionary, selected_preset_idx: int, preset_names: Dictionary) -> void:
	# 1. プリセットボタンのハイライト更新
	for i in range(title_preset_buttons.size()):
		var btn = title_preset_buttons[i]
		var idx = i + 1
		btn.text = preset_names.get(str(idx), "P%d" % idx)
		
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		
		if idx == selected_preset_idx:
			style.bg_color = Color("fff9c4") # 薄い黄色 (アクティブ)
			style.border_color = DeskTheme.COLOR_TENSION
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 1
		else:
			style.bg_color = Color("faf6f0")
			style.border_color = Color("d7ccc8")
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 2
			
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

	# 2. グリッドの更新
	for child in deck_icons_grid.get_children():
		child.queue_free()
		
	for i in range(1, 11):
		var item_id = deck.get(i, "")
		
		var slot_vbox = VBoxContainer.new()
		slot_vbox.add_theme_constant_override("separation", 2)
		slot_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var num_lbl = Label.new()
		num_lbl.text = str(i)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_override("font", DeskTheme.get_font())
		num_lbl.add_theme_font_size_override("font_size", 18)
		num_lbl.add_theme_color_override("font_color", Color("7d6c5d"))
		slot_vbox.add_child(num_lbl)
		
		var icon_container = PanelContainer.new()
		icon_container.custom_minimum_size = Vector2(72, 72)
		icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		var c_style = StyleBoxFlat.new()
		c_style.bg_color = DeskTheme.COLOR_CRAFT
		c_style.corner_radius_top_left = 6
		c_style.corner_radius_top_right = 6
		c_style.corner_radius_bottom_left = 6
		c_style.corner_radius_bottom_right = 6
		c_style.border_width_left = 2
		c_style.border_width_right = 2
		c_style.border_width_top = 2
		c_style.border_width_bottom = 2
		c_style.border_color = Color(DeskTheme.COLOR_INK, 0.25)
		icon_container.add_theme_stylebox_override("panel", c_style)
		
		if item_id != "":
			var img_path = CardData.get_item_image_path(item_id)
			var item_name = ""
			var item_desc = ""
			var item_role = ""
			if CardData.ITEMS.has(item_id):
				var info = CardData.ITEMS[item_id]
				item_name = info.get("name", "")
				item_desc = info.get("description", "")
				item_role = CardData.get_role_name(info.get("role", ""))
			
			icon_container.tooltip_text = "%s\n【%s】\n%s" % [item_name, item_role, item_desc]
			
			if img_path != "":
				var img_rect = TextureRect.new()
				img_rect.texture = load(img_path)
				img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				img_rect.custom_minimum_size = Vector2(52, 52)
				var margin = MarginContainer.new()
				margin.add_theme_constant_override("margin_left", 6)
				margin.add_theme_constant_override("margin_right", 6)
				margin.add_theme_constant_override("margin_top", 6)
				margin.add_theme_constant_override("margin_bottom", 6)
				margin.add_child(img_rect)
				icon_container.add_child(margin)
		else:
			icon_container.tooltip_text = "未編成"
			var lbl = Label.new()
			lbl.text = "+"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_override("font", DeskTheme.get_font())
			lbl.add_theme_font_size_override("font_size", 20)
			lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.3))
			icon_container.add_child(lbl)
			
		slot_vbox.add_child(icon_container)
		deck_icons_grid.add_child(slot_vbox)
