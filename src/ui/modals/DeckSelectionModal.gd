class_name DeckSelectionModal
extends PanelContainer

var on_confirm_callback: Callable
var preview_grid: GridContainer
var preset_buttons: Array[Button] = []
var title_lbl: Label

# Detail panel elements
var detail_panel: PanelContainer
var detail_icon: TextureRect
var detail_name: Label
var detail_role: Label
var detail_desc: Label

static func create_and_show(parent: Node, on_confirm: Callable) -> DeckSelectionModal:
	var modal = DeckSelectionModal.new()
	modal.on_confirm_callback = on_confirm
	parent.add_child(modal)
	modal.custom_minimum_size = Vector2(1380, 760)
	modal.pivot_offset = Vector2(690, 380)
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
	
	var main_split = HBoxContainer.new()
	main_split.add_theme_constant_override("separation", 24)
	margin.add_child(main_split)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_split.add_child(vbox)
	
	# Title
	title_lbl = Label.new()
	title_lbl.text = "対戦準備: 使用するデッキを選択"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title_lbl)
	
	# Preset select buttons container
	var preset_hbox = HBoxContainer.new()
	preset_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	preset_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(preset_hbox)
	
	for i in range(1, 4):
		var btn = Button.new()
		btn.text = Global.deck_preset_names.get(str(i), "プリセット %d" % i)
		btn.custom_minimum_size = Vector2(240, 55)
		btn.add_theme_font_override("font", DeskTheme.get_font())
		btn.add_theme_font_size_override("font_size", 18)
		Global.apply_white_button_style(btn)
		
		btn.pressed.connect(func():
			DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
			_select_preset(i)
		)
		preset_hbox.add_child(btn)
		preset_buttons.append(btn)
		
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
	preview_grid.columns = 5
	preview_grid.add_theme_constant_override("h_separation", 18)
	preview_grid.add_theme_constant_override("v_separation", 18)
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

	# Detail Panel (Right Side)
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(360, 0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color("#fbf9f4")
	detail_style.border_color = DeskTheme.COLOR_INK
	detail_style.border_width_left = 3
	detail_style.border_width_right = 3
	detail_style.border_width_top = 3
	detail_style.border_width_bottom = 3
	detail_style.corner_radius_top_left = 6
	detail_style.corner_radius_top_right = 6
	detail_style.corner_radius_bottom_left = 6
	detail_style.corner_radius_bottom_right = 6
	detail_style.content_margin_left = 24
	detail_style.content_margin_right = 24
	detail_style.content_margin_top = 24
	detail_style.content_margin_bottom = 24
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	main_split.add_child(detail_panel)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 20)
	detail_panel.add_child(detail_vbox)
	
	var detail_title = Label.new()
	detail_title.text = "アイテム効果"
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_title.add_theme_font_override("font", DeskTheme.get_font())
	detail_title.add_theme_font_size_override("font_size", 14)
	detail_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	detail_vbox.add_child(detail_title)
	
	detail_icon = TextureRect.new()
	detail_icon.custom_minimum_size = Vector2(120, 120)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	detail_vbox.add_child(detail_icon)
	
	detail_name = Label.new()
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_name.add_theme_font_override("font", DeskTheme.get_font())
	detail_name.add_theme_font_size_override("font_size", 22)
	detail_name.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_vbox.add_child(detail_name)
	
	detail_role = Label.new()
	detail_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_role.add_theme_font_override("font", DeskTheme.get_font())
	detail_role.add_theme_font_size_override("font_size", 16)
	detail_vbox.add_child(detail_role)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(DeskTheme.COLOR_INK, 0.2)
	detail_vbox.add_child(divider)
	
	detail_desc = Label.new()
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_desc.add_theme_font_override("font", DeskTheme.get_font())
	detail_desc.add_theme_font_size_override("font_size", 16)
	detail_desc.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_vbox.add_child(detail_desc)
	
	# Initial selection load
	_select_preset(Global.selected_preset_idx)
	
	# Show first item's details initially
	var first_item_id = Global.current_deck.get(1, "")
	update_detail_panel(first_item_id)
	
	# Entry animation
	scale = Vector2.ZERO
	if get_tree() != null:
		var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.3)


func _select_preset(preset_idx: int) -> void:
	Global.selected_preset_idx = preset_idx
	var key = str(preset_idx)
	var preset = Global.deck_presets.get(key, {})
	if preset.is_empty():
		preset = {
			"1": "item_sticky_note",
			"2": "item_eraser",
			"3": "item_ruler",
			"4": "item_wordbook",
			"5": "item_mech_pencil",
			"6": "item_memo_cards",
			"7": "item_highlighter",
			"8": "item_blue_pen",
			"9": "item_cushion",
			"10": "item_memo_app"
		}
	
	Global.current_deck.clear()
	for k in preset.keys():
		Global.current_deck[int(k)] = preset[k]
	Global.validate_current_deck()
	Global.save_game()
	
	_update_preset_highlights()
	_update_preview()

func _update_preset_highlights() -> void:
	for i in range(preset_buttons.size()):
		var btn = preset_buttons[i]
		var idx = i + 1
		btn.text = Global.deck_preset_names.get(str(idx), "プリセット %d" % idx)
		if idx == Global.selected_preset_idx:
			var active_style = StyleBoxFlat.new()
			active_style.bg_color = Color("#eddcc9")
			active_style.border_color = DeskTheme.COLOR_INK
			active_style.border_width_left = 3
			active_style.border_width_right = 3
			active_style.border_width_top = 3
			active_style.border_width_bottom = 3
			active_style.corner_radius_top_left = 6
			active_style.corner_radius_top_right = 6
			active_style.corner_radius_bottom_left = 6
			active_style.corner_radius_bottom_right = 6
			btn.add_theme_stylebox_override("normal", active_style)
		else:
			Global.apply_white_button_style(btn)

func _update_preview() -> void:
	for child in preview_grid.get_children():
		child.queue_free()
		
	for i in range(1, 11):
		var item_id = Global.current_deck.get(i, "")
		var item = CardData.ITEMS.get(item_id, {"name": "空き", "role": CardData.ROLE_PREP, "description": ""})
		
		var preview_box = Button.new()
		preview_box.custom_minimum_size = Vector2(165, 175)
		
		var style = StyleBoxFlat.new()
		style.bg_color = DeskTheme.COLOR_CRAFT
		style.border_color = CardData.get_role_color(item["role"])
		style.border_width_top = 22
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		
		var style_hover = style.duplicate() as StyleBoxFlat
		style_hover.bg_color = Color("e5dec9")
		
		preview_box.add_theme_stylebox_override("normal", style)
		preview_box.add_theme_stylebox_override("hover", style_hover)
		preview_box.add_theme_stylebox_override("pressed", style_hover)
		preview_box.add_theme_stylebox_override("focus", style)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_box.add_child(vbox)
		
		var num_lbl = Label.new()
		num_lbl.text = "Slot " + str(i)
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
		
		preview_box.mouse_entered.connect(func():
			DeskTheme.animate_hover(preview_box, true, Vector2.ONE, 0.12)
		)
		preview_box.mouse_exited.connect(func():
			DeskTheme.animate_hover(preview_box, false, Vector2.ONE, 0.12)
		)
		preview_box.pressed.connect(func():
			preview_box.release_focus()
			DeskTheme.animate_click(preview_box, Vector2.ONE, 0.08)
			update_detail_panel(item_id)
		)
		
		preview_grid.add_child(preview_box)

func update_detail_panel(item_id: String) -> void:
	var item = CardData.ITEMS.get(item_id, {})
	if item.is_empty():
		detail_icon.texture = null
		detail_name.text = "選択してください"
		detail_role.text = ""
		detail_desc.text = "左側のスロットをクリックすると、ここに詳細な効果が表示されます。"
		return
		
	var img_path = CardData.get_item_image_path(item_id)
	if img_path != "":
		detail_icon.texture = load(img_path)
	else:
		detail_icon.texture = null
		
	detail_name.text = item["name"]
	var role_name = CardData.get_role_name(item["role"])
	detail_role.text = "系統: %s" % role_name
	detail_role.add_theme_color_override("font_color", CardData.get_role_color(item["role"]))
	detail_desc.text = item["description"]

