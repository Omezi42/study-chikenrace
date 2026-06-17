class_name ItemSelectModal
extends PanelContainer

signal item_equipped(item_id: String)
signal closed()

# Config
var slot_num: int = 0
var current_equipped_id: String = ""
var on_equipped_callback: Callable

# Internal references
var _search_input: LineEdit
var _role_filter: OptionButton
var _select_grid: GridContainer
var _detail_icon: TextureRect
var _detail_name: Label
var _detail_role: Label
var _detail_desc: Label
var _equip_btn: Button
var _close_btn: Button
var _selected_item_id: String = ""

static func create_and_show(parent: Node, p_slot_num: int, p_current_id: String, on_equipped: Callable) -> ItemSelectModal:
	# Add background darken overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.45)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.name = "ItemSelectModalOverlay"
	parent.add_child(overlay)

	var modal = ItemSelectModal.new()
	modal.slot_num = p_slot_num
	modal.current_equipped_id = p_current_id
	modal.on_equipped_callback = on_equipped
	overlay.add_child(modal)
	
	modal.custom_minimum_size = Vector2(1100, 750)
	modal.pivot_offset = Vector2(550, 375)
	modal.position = overlay.get_viewport_rect().size * 0.5 - modal.pivot_offset
	
	# Entry animation
	modal.scale = Vector2(0.9, 0.9)
	modal.modulate = Color(1, 1, 1, 0)
	var tween = modal.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.25)
	tween.tween_property(modal, "modulate", Color.WHITE, 0.2)
	
	return modal

func _ready() -> void:
	add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	# Header with title and close button
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "ポケット %d の文房具を選択" % slot_num
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	header_hbox.add_child(title_lbl)
	
	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(40, 40)
	_close_btn.add_theme_font_override("font", DeskTheme.get_font())
	_close_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(_close_btn)
	_close_btn.pressed.connect(func():
		_close_btn.release_focus()
		DeskTheme.animate_click(_close_btn, Vector2.ONE, 0.08)
		close_modal()
	)
	_close_btn.mouse_entered.connect(func(): DeskTheme.animate_hover(_close_btn, true, Vector2.ONE, 0.08))
	_close_btn.mouse_exited.connect(func(): DeskTheme.animate_hover(_close_btn, false, Vector2.ONE, 0.08))
	header_hbox.add_child(_close_btn)
	
	# Main Content Area: Split into Left (List) and Right (Details)
	var content_hbox = HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 24)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_hbox)
	
	# LEFT SIDE: Item List
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 12)
	content_hbox.add_child(left_vbox)
	
	# Search & Filter bar
	var filter_hbox = HBoxContainer.new()
	filter_hbox.add_theme_constant_override("separation", 12)
	left_vbox.add_child(filter_hbox)
	
	_search_input = LineEdit.new()
	_search_input.placeholder_text = "アイテム名で検索..."
	_search_input.custom_minimum_size = Vector2(300, 40)
	_search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_input.add_theme_font_override("font", DeskTheme.get_font())
	_search_input.add_theme_font_size_override("font_size", 16)
	_search_input.text_changed.connect(func(_new_text):
		_populate_items()
	)
	filter_hbox.add_child(_search_input)
	
	_role_filter = OptionButton.new()
	_role_filter.add_item("すべての系統", 0)
	_role_filter.add_item("守り", 1)
	_role_filter.add_item("押し", 2)
	_role_filter.add_item("ブラフ", 3)
	_role_filter.add_item("仕込み", 4)
	_role_filter.custom_minimum_size = Vector2(160, 40)
	_role_filter.add_theme_font_override("font", DeskTheme.get_font())
	_role_filter.add_theme_font_size_override("font_size", 16)
	_role_filter.item_selected.connect(func(_idx):
		_populate_items()
	)
	filter_hbox.add_child(_role_filter)
	
	# List background container
	var list_panel = PanelContainer.new()
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var inner_style = StyleBoxFlat.new()
	inner_style.bg_color = Color("#fbf8f3")
	inner_style.border_color = Color(DeskTheme.COLOR_INK, 0.15)
	inner_style.border_width_left = 2
	inner_style.border_width_right = 2
	inner_style.border_width_top = 2
	inner_style.border_width_bottom = 2
	inner_style.corner_radius_top_left = 6
	inner_style.corner_radius_top_right = 6
	inner_style.corner_radius_bottom_left = 6
	inner_style.corner_radius_bottom_right = 6
	list_panel.add_theme_stylebox_override("panel", inner_style)
	left_vbox.add_child(list_panel)
	
	var list_margin = MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 12)
	list_margin.add_theme_constant_override("margin_right", 12)
	list_margin.add_theme_constant_override("margin_top", 12)
	list_margin.add_theme_constant_override("margin_bottom", 12)
	list_panel.add_child(list_margin)
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_margin.add_child(scroll)
	
	_select_grid = GridContainer.new()
	_select_grid.columns = 2
	_select_grid.add_theme_constant_override("h_separation", 12)
	_select_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_select_grid)
	
	# RIGHT SIDE: Detail Panel
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(380, 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color("#fbf9f4")
	detail_style.border_color = DeskTheme.COLOR_INK
	detail_style.border_width_left = 3
	detail_style.border_width_right = 3
	detail_style.border_width_top = 3
	detail_style.border_width_bottom = 3
	detail_style.corner_radius_top_left = 8
	detail_style.corner_radius_top_right = 8
	detail_style.corner_radius_bottom_left = 8
	detail_style.corner_radius_bottom_right = 8
	detail_style.content_margin_left = 20
	detail_style.content_margin_right = 20
	detail_style.content_margin_top = 20
	detail_style.content_margin_bottom = 20
	right_panel.add_theme_stylebox_override("panel", detail_style)
	content_hbox.add_child(right_panel)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 16)
	right_panel.add_child(right_vbox)
	
	var detail_header = Label.new()
	detail_header.text = "文房具詳細"
	detail_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_header.add_theme_font_override("font", DeskTheme.get_font())
	detail_header.add_theme_font_size_override("font_size", 16)
	detail_header.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	right_vbox.add_child(detail_header)
	
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(120, 120)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_vbox.add_child(_detail_icon)
	
	_detail_name = Label.new()
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name.add_theme_font_override("font", DeskTheme.get_font())
	_detail_name.add_theme_font_size_override("font_size", 26)
	_detail_name.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	right_vbox.add_child(_detail_name)
	
	_detail_role = Label.new()
	_detail_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_role.add_theme_font_override("font", DeskTheme.get_font())
	_detail_role.add_theme_font_size_override("font_size", 18)
	right_vbox.add_child(_detail_role)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(DeskTheme.COLOR_INK, 0.15)
	right_vbox.add_child(divider)
	
	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_desc.add_theme_font_override("font", DeskTheme.get_font())
	_detail_desc.add_theme_font_size_override("font_size", 18)
	_detail_desc.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	right_vbox.add_child(_detail_desc)
	
	_equip_btn = Button.new()
	_equip_btn.text = "このアイテムを装備"
	_equip_btn.custom_minimum_size = Vector2(240, 52)
	_equip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_equip_btn.add_theme_font_override("font", DeskTheme.get_font())
	_equip_btn.add_theme_font_size_override("font_size", 20)
	Global.apply_white_button_style(_equip_btn)
	_equip_btn.pressed.connect(func():
		_equip_btn.release_focus()
		DeskTheme.animate_click(_equip_btn, Vector2.ONE, 0.08)
		if _selected_item_id != "":
			item_equipped.emit(_selected_item_id)
			if on_equipped_callback.is_valid():
				on_equipped_callback.call(_selected_item_id)
			close_modal()
	)
	_equip_btn.mouse_entered.connect(func(): DeskTheme.animate_hover(_equip_btn, true, Vector2.ONE, 0.08))
	_equip_btn.mouse_exited.connect(func(): DeskTheme.animate_hover(_equip_btn, false, Vector2.ONE, 0.08))
	right_vbox.add_child(_equip_btn)
	
	# Init list and details
	_populate_items()
	_update_details(current_equipped_id)

func close_modal() -> void:
	var overlay = get_parent()
	
	# Exit animation
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.2)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
	if overlay is ColorRect:
		tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.2)
		
	tween.chain().tween_callback(func():
		closed.emit()
		if overlay:
			overlay.queue_free()
		else:
			queue_free()
	)

func _populate_items() -> void:
	for child in _select_grid.get_children():
		child.queue_free()
		
	var filter_text = _search_input.text.to_lower()
	var filter_role_idx = _role_filter.selected
	
	var items_to_show = []
	for item_id in Global.unlocked_items:
		var item = CardData.ITEMS.get(item_id, {})
		if item.is_empty():
			continue
		if filter_text != "" and not filter_text in item["name"].to_lower():
			continue
		if filter_role_idx > 0:
			var role_map = {
				1: CardData.ROLE_DEFENSE,
				2: CardData.ROLE_PUSH,
				3: CardData.ROLE_BLUFF,
				4: CardData.ROLE_PREP
			}
			var target_role = role_map.get(filter_role_idx, "")
			if item["role"] != target_role:
				continue
		items_to_show.append(item)
		
	var role_order = {
		CardData.ROLE_DEFENSE: 0,
		CardData.ROLE_PUSH: 1,
		CardData.ROLE_BLUFF: 2,
		CardData.ROLE_PREP: 3
	}
	
	items_to_show.sort_custom(func(a, b):
		var a_equipped = (a["id"] == current_equipped_id)
		var b_equipped = (b["id"] == current_equipped_id)
		if a_equipped != b_equipped:
			return a_equipped
		var a_role_priority = role_order.get(a["role"], 99)
		var b_role_priority = role_order.get(b["role"], 99)
		if a_role_priority != b_role_priority:
			return a_role_priority < b_role_priority
		return a["id"] < b["id"]
	)
	
	for item in items_to_show:
		var item_id = item["id"]
		var is_equipped = (item_id == current_equipped_id)
		
		var item_btn = Button.new()
		item_btn.text = ""
		item_btn.custom_minimum_size = Vector2(230, 80)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color("#f5eedb") if is_equipped else DeskTheme.COLOR_CRAFT
		btn_style.border_color = CardData.get_role_color(item["role"])
		btn_style.border_width_left = 3
		btn_style.border_width_right = 3
		btn_style.border_width_top = 3
		btn_style.border_width_bottom = 3
		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_left = 6
		btn_style.corner_radius_bottom_right = 6
		if is_equipped:
			btn_style.border_width_left = 5
			btn_style.border_width_right = 5
			btn_style.border_width_top = 5
			btn_style.border_width_bottom = 5
			
		var btn_hover = btn_style.duplicate() as StyleBoxFlat
		btn_hover.bg_color = Color("#e7ddc4")
		
		item_btn.add_theme_stylebox_override("normal", btn_style)
		item_btn.add_theme_stylebox_override("hover", btn_hover)
		item_btn.add_theme_stylebox_override("pressed", btn_hover)
		item_btn.add_theme_stylebox_override("focus", btn_style)
		
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 10)
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_btn.add_child(hbox)
		
		var img_path = CardData.get_item_image_path(item_id)
		if img_path != "":
			var icon_rect = TextureRect.new()
			icon_rect.texture = load(img_path)
			icon_rect.custom_minimum_size = Vector2(48, 48)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox.add_child(icon_rect)
			
		var v_lbls = VBoxContainer.new()
		v_lbls.alignment = BoxContainer.ALIGNMENT_CENTER
		v_lbls.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(v_lbls)
		
		var name_lbl = Label.new()
		name_lbl.text = item["name"]
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		v_lbls.add_child(name_lbl)
		
		if is_equipped:
			var eq_lbl = Label.new()
			eq_lbl.text = "[ 現在装備中 ]"
			eq_lbl.add_theme_font_override("font", DeskTheme.get_font())
			eq_lbl.add_theme_font_size_override("font_size", 12)
			eq_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
			v_lbls.add_child(eq_lbl)
			
		item_btn.mouse_entered.connect(func(): DeskTheme.animate_hover(item_btn, true, Vector2.ONE, 0.08))
		item_btn.mouse_exited.connect(func(): DeskTheme.animate_hover(item_btn, false, Vector2.ONE, 0.08))
		item_btn.pressed.connect(func():
			item_btn.release_focus()
			DeskTheme.animate_click(item_btn, Vector2.ONE, 0.08)
			_update_details(item_id)
		)
		
		_select_grid.add_child(item_btn)

func _update_details(item_id: String) -> void:
	var item = CardData.ITEMS.get(item_id, {})
	if item.is_empty():
		_detail_icon.texture = null
		_detail_name.text = "選択してください"
		_detail_role.text = ""
		_detail_desc.text = "左側のアイテムリストから文房具を選ぶと、ここに効果の詳細が表示されます。"
		_equip_btn.visible = false
		_selected_item_id = ""
		return
		
	var img_path = CardData.get_item_image_path(item_id)
	if img_path != "":
		_detail_icon.texture = load(img_path)
	else:
		_detail_icon.texture = null
		
	_detail_name.text = item["name"]
	
	var role_name = CardData.get_role_name(item["role"])
	_detail_role.text = "系統: %s" % role_name
	_detail_role.add_theme_color_override("font_color", CardData.get_role_color(item["role"]))
	
	_detail_desc.text = item["description"]
	_selected_item_id = item_id
	_equip_btn.visible = true
