class_name CramDeckPreviewModal
extends PanelContainer

var on_confirm_callback: Callable
var preview_grid: GridContainer
var title_lbl: Label

static func create_and_show(parent: Node, on_confirm: Callable) -> CramDeckPreviewModal:
	var modal = CramDeckPreviewModal.new()
	modal.on_confirm_callback = on_confirm
	parent.add_child(modal)
	modal.custom_minimum_size = Vector2(980, 680)
	modal.pivot_offset = Vector2(490, 340)
	modal.position = parent.get_viewport_rect().size * 0.5 - modal.pivot_offset
	return modal

func _ready() -> void:
	add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Title
	title_lbl = Label.new()
	title_lbl.text = "一夜漬け: 今シーズンのミニデッキ (8枚)"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title_lbl)
	
	# Subtitle / Info
	var info_lbl = Label.new()
	info_lbl.text = "このモードではカスタムデッキではなく、シーズンごとに固定された以下の8枚 of アイテム構成で戦います。\n(Slotの番号と同じ枚数のカードがデッキに入ります。例: Slot 8にはそのアイテムが8枚)"
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.add_theme_font_override("font", DeskTheme.get_font())
	info_lbl.add_theme_font_size_override("font_size", 14)
	info_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	vbox.add_child(info_lbl)
	
	# Preview Box
	var preview_panel = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(920, 410)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#fbf9f4")
	style.border_color = DeskTheme.COLOR_INK
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	preview_panel.add_theme_stylebox_override("panel", style)
	vbox.add_child(preview_panel)
	
	var preview_margin = MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 15)
	preview_margin.add_theme_constant_override("margin_right", 15)
	preview_margin.add_theme_constant_override("margin_top", 15)
	preview_margin.add_theme_constant_override("margin_bottom", 15)
	preview_panel.add_child(preview_margin)
	
	preview_grid = GridContainer.new()
	preview_grid.columns = 4
	preview_grid.add_theme_constant_override("h_separation", 18)
	preview_grid.add_theme_constant_override("v_separation", 18)
	preview_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_margin.add_child(preview_grid)
	
	# Action buttons (Confirm / Cancel)
	var action_hbox = HBoxContainer.new()
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(action_hbox)
	
	var confirm_btn = Button.new()
	confirm_btn.text = "このデッキで開始！"
	confirm_btn.custom_minimum_size = Vector2(240, 60)
	confirm_btn.add_theme_font_override("font", DeskTheme.get_font())
	confirm_btn.add_theme_font_size_override("font_size", 20)
	Global.apply_white_button_style(confirm_btn)
	confirm_btn.pressed.connect(func():
		DeskTheme.animate_click(confirm_btn, Vector2.ONE, 0.08)
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func():
			queue_free()
			if on_confirm_callback.is_valid():
				on_confirm_callback.call()
		)
	)
	action_hbox.add_child(confirm_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "キャンセル"
	cancel_btn.custom_minimum_size = Vector2(160, 60)
	cancel_btn.add_theme_font_override("font", DeskTheme.get_font())
	cancel_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(cancel_btn)
	cancel_btn.pressed.connect(func():
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func():
			queue_free()
		)
	)
	action_hbox.add_child(cancel_btn)
	
	_update_preview()
	
	# Entry animation
	scale = Vector2.ZERO
	if get_tree() != null:
		var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.3)

func _update_preview() -> void:
	for child in preview_grid.get_children():
		child.queue_free()
		
	var season_deck = Global.get_cram_season_deck()
	
	for i in range(1, 9):
		var item_id = season_deck.get(i, "")
		var item = CardData.ITEMS.get(item_id, {"name": "空き", "role": CardData.ROLE_PREP, "description": ""})
		
		var preview_box = PanelContainer.new()
		preview_box.custom_minimum_size = Vector2(200, 165)
		var style = StyleBoxFlat.new()
		style.bg_color = DeskTheme.COLOR_CRAFT
		style.border_color = CardData.get_role_color(item["role"])
		style.border_width_top = 22
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		preview_box.add_theme_stylebox_override("panel", style)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		preview_box.add_child(vbox)
		
		var num_lbl = Label.new()
		num_lbl.text = "Slot " + str(i) + " (" + str(i) + "枚)"
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_override("font", DeskTheme.get_font())
		num_lbl.add_theme_font_size_override("font_size", 14)
		num_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
		vbox.add_child(num_lbl)
		
		if item_id != "":
			var img_path = CardData.get_item_image_path(item_id)
			if img_path != "":
				var img = TextureRect.new()
				img.texture = load(img_path)
				img.custom_minimum_size = Vector2(54, 54)
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				vbox.add_child(img)
			else:
				var spacer = Control.new()
				spacer.custom_minimum_size = Vector2(54, 15)
				vbox.add_child(spacer)
				
		var name_lbl = Label.new()
		name_lbl.text = item["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(name_lbl)
		
		# Tooltip representation
		preview_box.tooltip_text = "%s\n%s" % [item["name"], item["description"]]
		
		preview_grid.add_child(preview_box)
