class_name LoadoutScene
extends Control

var slots_grid: GridContainer
var back_btn: Button

# Select modal
var select_modal: PanelContainer
var select_grid: GridContainer
var active_slot_idx: int = -1
var search_input: LineEdit
var role_filter: OptionButton

# Detail panel elements in select modal
var detail_panel: PanelContainer
var detail_icon: TextureRect
var detail_name: Label
var detail_role: Label
var detail_desc: Label
var equip_btn: Button
var selected_item_to_equip: String = ""


# Preset UI components
var preset_buttons: Array[Button] = []
var active_preset_label: Label
var preset_name_edit: LineEdit
var save_preset_btn: Button
var rename_preset_btn: Button

func _ready() -> void:
	# 木枠（のっぺりした外側の淵）
	var frame = ColorRect.new()
	frame.color = Color("#4e342e") # 落ち着いた木枠の色（焦げ茶）
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	
	# 枠の太さ（マージン）を設定
	var board_margin = MarginContainer.new()
	board_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_margin.add_theme_constant_override("margin_left", DeskTheme.MARGIN_LARGE)
	board_margin.add_theme_constant_override("margin_right", DeskTheme.MARGIN_LARGE)
	board_margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_LARGE)
	board_margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_LARGE)
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
	main_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_LARGE)
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
	title.text = "デッキ編成"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE_LARGE)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title_vbox.add_child(title)
	
	var sub_title = Label.new()
	sub_title.text = "1〜10の数字のカードを引いた時に、対応するスロットのアイテムの効果が発動します。"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_title.add_theme_font_override("font", DeskTheme.get_font())
	sub_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	sub_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	title_vbox.add_child(sub_title)
	
	# 5x2 slots grid
	slots_grid = GridContainer.new()
	slots_grid.columns = 5
	slots_grid.add_theme_constant_override("h_separation", DeskTheme.MARGIN_DEFAULT)
	slots_grid.add_theme_constant_override("v_separation", DeskTheme.MARGIN_DEFAULT)
	main_vbox.add_child(slots_grid)
	
	# Populate 10 slots
	populate_slots()
	
	_create_preset_ui(main_vbox)
	
	# Back button
	back_btn = Button.new()
	back_btn.text = "タイトルに戻る"
	back_btn.custom_minimum_size = Vector2(320, 70)
	back_btn.add_theme_font_override("font", DeskTheme.get_font())
	back_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_LARGE)
	Global.apply_white_button_style(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	main_vbox.add_child(back_btn)
	
	# SELECT MODAL (hidden initially)
	setup_select_modal()

	if Global.is_tutorial_mode:
		Global.show_tutorial_dialog(
			self,
			"デッキ編成（カバン構築）画面へようこそ！\n\n1〜10の数字スロットに筆記用具アイテムを装備できます。授業中（チキンレース）にその数字のカードを引き当てた瞬間、そのアイテムの効果が自動で発動するよ！\n\nスロットをクリックして自由に付け替えを試してみてね。確認したら『タイトルに戻る』を押して、ゲームを開始しよう！",
			Vector2(100, 80)
		)


func populate_slots() -> void:
	for child in slots_grid.get_children():
		child.queue_free()
		
	for i in range(1, 11):
		var item_id = Global.current_deck.get(i, "")
		var item = CardData.ITEMS.get(item_id, {"name": "空き", "role": CardData.ROLE_PREP})
		
		# Slotted sticky note panel
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(250, 215)
		slot_btn.pivot_offset = Vector2(125, 107.5)
		
		if item_id != "":
			slot_btn.tooltip_text = "%s: %s" % [item["name"], item.get("description", "")]
		else:
			slot_btn.tooltip_text = "空きスロット (クリックして装備)"
		
		# Slight loose tilt angles
		slot_btn.rotation_degrees = randf_range(-2.0, 2.0)
		
		var note_style = StyleBoxFlat.new()
		note_style.bg_color = DeskTheme.COLOR_CRAFT
		note_style.border_color = CardData.get_role_color(item["role"])
		note_style.border_width_top = 32 # Top sticky binding part
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
		vbox.add_theme_constant_override("separation", 8)
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_btn.add_child(vbox)
		
		var num_lbl = Label.new()
		num_lbl.text = "スロット " + str(i)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_override("font", DeskTheme.get_font())
		num_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
		num_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
		vbox.add_child(num_lbl)
		
		# Show item image if equipped (and isn't empty)
		if item_id != "":
			var img_path = CardData.get_item_image_path(item_id)
			if img_path != "":
				var img_rect = TextureRect.new()
				img_rect.texture = load(img_path)
				img_rect.custom_minimum_size = Vector2(80, 80)
				img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				img_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				vbox.add_child(img_rect)
			else:
				var spacer = Control.new()
				spacer.custom_minimum_size = Vector2(80, 20)
				vbox.add_child(spacer)
		else:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(80, 50)
			vbox.add_child(spacer)
			
		var name_lbl = Label.new()
		name_lbl.text = item["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(name_lbl)
		
		# Hover animations
		slot_btn.mouse_entered.connect(func(): DeskTheme.animate_hover(slot_btn, true, Vector2.ONE, 0.12))
		slot_btn.mouse_exited.connect(func(): DeskTheme.animate_hover(slot_btn, false, Vector2.ONE, 0.12))
		slot_btn.pressed.connect(func():
			slot_btn.release_focus()
			DeskTheme.animate_click(slot_btn, Vector2.ONE, 0.08)
			_on_slot_clicked(i)
		)
		
		slots_grid.add_child(slot_btn)

func setup_select_modal() -> void:
	select_modal = PanelContainer.new()
	select_modal.custom_minimum_size = Vector2(1080, 700)
	select_modal.pivot_offset = Vector2(540, 350)
	select_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(select_modal)
	select_modal.position = get_viewport_rect().size * 0.5 - select_modal.pivot_offset
	select_modal.visible = false
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", DeskTheme.MARGIN_LARGE)
	margin.add_theme_constant_override("margin_right", DeskTheme.MARGIN_LARGE)
	margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_LARGE)
	margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_LARGE)
	select_modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_MEDIUM)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "アイテムの入れ替え"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	# 検索・フィルター用 HBox
	var filter_hbox = HBoxContainer.new()
	filter_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(filter_hbox)
	
	search_input = LineEdit.new()
	search_input.placeholder_text = "アイテム名で検索..."
	search_input.custom_minimum_size = Vector2(300, 40)
	search_input.add_theme_font_override("font", DeskTheme.get_font())
	search_input.add_theme_font_size_override("font_size", 16)
	search_input.text_changed.connect(func(new_text):
		populate_select_list(new_text, role_filter.selected)
	)
	filter_hbox.add_child(search_input)
	
	role_filter = OptionButton.new()
	role_filter.add_item("すべての系統", 0)
	role_filter.add_item("守り", 1)
	role_filter.add_item("押し", 2)
	role_filter.add_item("ブラフ", 3)
	role_filter.add_item("仕込み", 4)
	role_filter.custom_minimum_size = Vector2(160, 40)
	role_filter.add_theme_font_override("font", DeskTheme.get_font())
	role_filter.add_theme_font_size_override("font_size", 16)
	role_filter.item_selected.connect(func(idx):
		populate_select_list(search_input.text, idx)
	)
	filter_hbox.add_child(role_filter)
	
	# Main split HBox
	var main_split = HBoxContainer.new()
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.add_theme_constant_override("separation", DeskTheme.MARGIN_LARGE) # 20 -> 35
	vbox.add_child(main_split)
	
	# Scroll for unlocked items (Left Side)
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_split.add_child(scroll)
	
	select_grid = GridContainer.new()
	select_grid.columns = 3 # Reduced columns to fit the detail panel on the right
	select_grid.add_theme_constant_override("h_separation", DeskTheme.MARGIN_SMALL)
	select_grid.add_theme_constant_override("v_separation", DeskTheme.MARGIN_SMALL)
	scroll.add_child(select_grid)
	
	# Detail Panel (Right Side)
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(380, 0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color("#fbf9f4") # Bright card background
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
	detail_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_MEDIUM) # 20 -> 25
	detail_panel.add_child(detail_vbox)
	
	var detail_title = Label.new()
	detail_title.text = "アイテム効果"
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_title.add_theme_font_override("font", DeskTheme.get_font())
	detail_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
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
	detail_name.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_LARGE)
	detail_name.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_vbox.add_child(detail_name)
	
	detail_role = Label.new()
	detail_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_role.add_theme_font_override("font", DeskTheme.get_font())
	detail_role.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	detail_vbox.add_child(detail_role)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(DeskTheme.COLOR_INK, 0.2)
	detail_vbox.add_child(divider)
	
	detail_desc = Label.new()
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_desc.add_theme_font_override("font", DeskTheme.get_font())
	detail_desc.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	detail_desc.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	detail_vbox.add_child(detail_desc)
	
	equip_btn = Button.new()
	equip_btn.text = "このアイテムを装備"
	equip_btn.custom_minimum_size = Vector2(200, 50)
	equip_btn.add_theme_font_override("font", DeskTheme.get_font())
	equip_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	Global.apply_white_button_style(equip_btn)
	equip_btn.visible = false
	equip_btn.pressed.connect(func():
		equip_btn.release_focus()
		DeskTheme.animate_click(equip_btn, Vector2.ONE, 0.08)
		if selected_item_to_equip != "":
			_on_item_selected(selected_item_to_equip)
	)
	detail_vbox.add_child(equip_btn)
	
	var close_btn = Button.new()
	close_btn.text = "閉じる"
	close_btn.custom_minimum_size = Vector2(200, 55)
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	Global.apply_white_button_style(close_btn)
	close_btn.pressed.connect(func():
		close_btn.release_focus()
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		select_modal.visible = false
	)
	vbox.add_child(close_btn)

func update_detail_panel(item_id: String) -> void:
	var item = CardData.ITEMS.get(item_id, {})
	if item.is_empty():
		detail_icon.texture = null
		detail_name.text = "選択してください"
		detail_role.text = ""
		detail_desc.text = "左側のアイテムリストからクリックすると、ここに詳細な効果が表示されます。"
		selected_item_to_equip = ""
		if equip_btn:
			equip_btn.visible = false
		return
		
	# Update Icon
	var img_path = CardData.get_item_image_path(item_id)
	if img_path != "":
		detail_icon.texture = load(img_path)
	else:
		detail_icon.texture = null
		
	# Update Name
	detail_name.text = item["name"]
	
	# Update Role
	var role_name = CardData.get_role_name(item["role"])
	detail_role.text = "系統: %s" % role_name
	detail_role.add_theme_color_override("font_color", CardData.get_role_color(item["role"]))
	
	# Update Description
	detail_desc.text = item["description"]

	# Update equip button state
	selected_item_to_equip = item_id
	if equip_btn:
		equip_btn.visible = true
		equip_btn.text = "このアイテムを装備"


func _on_slot_clicked(slot_num: int) -> void:
	if select_modal.visible:
		return
	active_slot_idx = slot_num
	select_modal.visible = true
	
	# Reset search and role filters
	if search_input:
		search_input.text = ""
	if role_filter:
		role_filter.selected = 0
	
	# Show current equipped item details in the panel initially
	var current_item_id = Global.current_deck.get(slot_num, "")
	update_detail_panel(current_item_id)
	
	# Spawn unlocked items in modal grid
	populate_select_list("", 0)
	
	# Smooth modal scale pop-in (zoom) without wobbly overshoot
	select_modal.scale = Vector2(0.85, 0.85)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(select_modal, "scale", Vector2.ONE, 0.25)

func populate_select_list(filter_text: String = "", filter_role_id: int = 0) -> void:
	for child in select_grid.get_children():
		child.queue_free()
		
	var items_to_show = []
	for item_id in Global.unlocked_items:
		var item = CardData.ITEMS.get(item_id, {})
		if item.is_empty():
			continue
			
		# Text search filter
		if filter_text != "" and not filter_text.to_lower() in item["name"].to_lower():
			continue
			
		# Role type filter
		if filter_role_id > 0:
			var role_map = {
				1: CardData.ROLE_DEFENSE,
				2: CardData.ROLE_PUSH,
				3: CardData.ROLE_BLUFF,
				4: CardData.ROLE_PREP
			}
			var target_role = role_map.get(filter_role_id, "")
			if item["role"] != target_role:
				continue
		items_to_show.append(item)
		
	# Sort items:
	# 1. Currently equipped in active_slot_idx first
	# 2. Then by role order (defense -> push -> bluff -> prep)
	# 3. Then by item ID
	var role_order = {
		CardData.ROLE_DEFENSE: 0,
		CardData.ROLE_PUSH: 1,
		CardData.ROLE_BLUFF: 2,
		CardData.ROLE_PREP: 3
	}
	var current_equipped_id = Global.current_deck.get(active_slot_idx, "")
	
	items_to_show.sort_custom(func(a, b):
		var a_equipped = (a["id"] == current_equipped_id)
		var b_equipped = (b["id"] == current_equipped_id)
		if a_equipped != b_equipped:
			return a_equipped # true (equipped) comes first
			
		var a_role_priority = role_order.get(a["role"], 99)
		var b_role_priority = role_order.get(b["role"], 99)
		if a_role_priority != b_role_priority:
			return a_role_priority < b_role_priority
			
		return a["id"] < b["id"]
	)
	
	for item in items_to_show:
		var item_id = item["id"]
		var is_currently_equipped = (item_id == current_equipped_id)
		
		var item_btn = Button.new()
		item_btn.text = ""
		item_btn.custom_minimum_size = Vector2(210, 85)
		
		# Role colors on border
		var btn_style = StyleBoxFlat.new()
		# Highlight background if currently equipped
		if is_currently_equipped:
			btn_style.bg_color = Color("f0eada") # Distinct background color for equipped item
		else:
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
		
		# Give equipped a slightly thicker border or different border color to stand out
		if is_currently_equipped:
			btn_style.border_width_left = 5
			btn_style.border_width_right = 5
			btn_style.border_width_top = 5
			btn_style.border_width_bottom = 5
		
		var btn_hover = btn_style.duplicate() as StyleBoxFlat
		btn_hover.bg_color = Color("e5dec9") # slightly darker craft
		
		item_btn.add_theme_stylebox_override("normal", btn_style)
		item_btn.add_theme_stylebox_override("hover", btn_hover)
		item_btn.add_theme_stylebox_override("pressed", btn_hover)
		item_btn.add_theme_stylebox_override("focus", btn_style)
		
		# VBox inside button to handle item content and "Equipped" badge
		var btn_vbox = VBoxContainer.new()
		btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_vbox.add_theme_constant_override("separation", 2)
		btn_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_btn.add_child(btn_vbox)
		
		var btn_hbox = HBoxContainer.new()
		btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_hbox.add_theme_constant_override("separation", 10)
		btn_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_vbox.add_child(btn_hbox)
		
		var img_path = CardData.get_item_image_path(item_id)
		if img_path != "":
			var icon_rect = TextureRect.new()
			icon_rect.texture = load(img_path)
			icon_rect.custom_minimum_size = Vector2(40, 40)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			btn_hbox.add_child(icon_rect)
			
		var name_lbl = Label.new()
		name_lbl.text = item["name"]
		name_lbl.add_theme_font_override("font", DeskTheme.get_font())
		name_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
		name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		btn_hbox.add_child(name_lbl)
		
		if is_currently_equipped:
			var eq_lbl = Label.new()
			eq_lbl.text = "[ 装備中 ]"
			eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			eq_lbl.add_theme_font_override("font", DeskTheme.get_font())
			eq_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
			eq_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
			btn_vbox.add_child(eq_lbl)
		
		# Connect hover interactions
		item_btn.mouse_entered.connect(func():
			DeskTheme.animate_hover(item_btn, true, Vector2.ONE, 0.12)
		)
		item_btn.mouse_exited.connect(func():
			DeskTheme.animate_hover(item_btn, false, Vector2.ONE, 0.12)
		)
		
		item_btn.pressed.connect(func():
			item_btn.release_focus()
			DeskTheme.animate_click(item_btn, Vector2.ONE, 0.08)
			update_detail_panel(item_id)
		)
		select_grid.add_child(item_btn)

func _on_item_selected(item_id: String) -> void:
	if not select_modal.visible:
		return
	select_modal.visible = false
	var duplicate_slot = -1
	for slot_idx in Global.current_deck.keys():
		if int(slot_idx) != active_slot_idx and Global.current_deck[slot_idx] == item_id:
			duplicate_slot = int(slot_idx)
			break
			
	var item_info = CardData.ITEMS.get(item_id, {})
	var item_color = CardData.get_role_color(item_info.get("role", CardData.ROLE_PREP))
			
	if duplicate_slot != -1:
		var prev_item = Global.current_deck[active_slot_idx]
		Global.current_deck[duplicate_slot] = prev_item
		Global.current_deck[active_slot_idx] = item_id
		DeskTheme.show_toast(self, "スロット %d と入れ替えました！" % duplicate_slot, 1.8, item_color)
	else:
		Global.current_deck[active_slot_idx] = item_id
		var item_name = item_info.get("name", "アイテム")
		DeskTheme.show_toast(self, "%s を装備しました！" % item_name, 1.8, item_color)
		
	Global.save_game()
	populate_slots()

func _on_back_pressed() -> void:
	if back_btn.disabled:
		return
	back_btn.disabled = true
	back_btn.release_focus()
	DeskTheme.animate_click(back_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
	)

# Preset Management
func _create_preset_ui(parent: Node) -> void:
	var preset_panel = PanelContainer.new()
	preset_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#fbf8f3") # bright beige paper
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = DeskTheme.COLOR_INK
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	preset_panel.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(preset_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL) # 12 -> 20
	preset_panel.add_child(main_vbox)
	
	# 上段: 切り替えタブ (HBoxContainer)
	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_hbox.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL) # 15 -> 20
	main_vbox.add_child(tabs_hbox)
	
	var label = Label.new()
	label.text = "プリセット選択:"
	label.add_theme_font_override("font", DeskTheme.get_font())
	label.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	tabs_hbox.add_child(label)
	
	preset_buttons.clear()
	for i in range(1, 4):
		var load_btn = Button.new()
		load_btn.text = Global.deck_preset_names.get(str(i), "プリセット %d" % i)
		load_btn.custom_minimum_size = Vector2(160, 40)
		load_btn.add_theme_font_override("font", DeskTheme.get_font())
		load_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_MINI)
		Global.apply_white_button_style(load_btn)
		load_btn.pressed.connect(func():
			load_btn.release_focus()
			DeskTheme.animate_click(load_btn, Vector2.ONE, 0.08)
			_load_preset(i)
		)
		tabs_hbox.add_child(load_btn)
		preset_buttons.append(load_btn)
		
	# 下段: 選択中プリセットの操作エリア
	var actions_hbox = HBoxContainer.new()
	actions_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(actions_hbox)
	
	active_preset_label = Label.new()
	active_preset_label.text = "選択中: プリセット 1"
	active_preset_label.add_theme_font_override("font", DeskTheme.get_font())
	active_preset_label.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	active_preset_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	actions_hbox.add_child(active_preset_label)
	
	save_preset_btn = Button.new()
	save_preset_btn.text = "現在の編成を保存"
	save_preset_btn.custom_minimum_size = Vector2(160, 36)
	save_preset_btn.add_theme_font_override("font", DeskTheme.get_font())
	save_preset_btn.add_theme_font_size_override("font_size", 12)
	Global.apply_white_button_style(save_preset_btn)
	save_preset_btn.pressed.connect(func():
		save_preset_btn.release_focus()
		DeskTheme.animate_click(save_preset_btn, Vector2.ONE, 0.08)
		_save_preset(Global.selected_preset_idx)
	)
	actions_hbox.add_child(save_preset_btn)
	
	var name_change_label = Label.new()
	name_change_label.text = "名前変更:"
	name_change_label.add_theme_font_override("font", DeskTheme.get_font())
	name_change_label.add_theme_font_size_override("font_size", 12)
	name_change_label.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	actions_hbox.add_child(name_change_label)
	
	preset_name_edit = LineEdit.new()
	preset_name_edit.custom_minimum_size = Vector2(150, 36)
	preset_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	preset_name_edit.placeholder_text = "プリセット名"
	preset_name_edit.add_theme_font_override("font", DeskTheme.get_font())
	preset_name_edit.add_theme_font_size_override("font_size", 12)
	preset_name_edit.text_submitted.connect(func(new_name):
		_rename_active_preset(new_name)
	)
	actions_hbox.add_child(preset_name_edit)
	
	rename_preset_btn = Button.new()
	rename_preset_btn.text = "適用"
	rename_preset_btn.custom_minimum_size = Vector2(60, 36)
	rename_preset_btn.add_theme_font_override("font", DeskTheme.get_font())
	rename_preset_btn.add_theme_font_size_override("font_size", 12)
	Global.apply_white_button_style(rename_preset_btn)
	rename_preset_btn.pressed.connect(func():
		rename_preset_btn.release_focus()
		DeskTheme.animate_click(rename_preset_btn, Vector2.ONE, 0.08)
		_rename_active_preset(preset_name_edit.text)
	)
	actions_hbox.add_child(rename_preset_btn)
	
	_update_preset_buttons_highlight()

func _rename_active_preset(new_name: String) -> void:
	var clean_name = new_name.strip_edges()
	if clean_name != "":
		var idx_str = str(Global.selected_preset_idx)
		Global.deck_preset_names[idx_str] = clean_name
		Global.save_game()
		DeskTheme.show_toast(self, "名前を「%s」に変更しました！" % clean_name, 1.2, Color("#4a90e2"))
		_update_preset_buttons_highlight()

func _load_preset(preset_idx: int) -> void:
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
		
	Global.selected_preset_idx = preset_idx
	Global.validate_current_deck()
	Global.save_game()
	populate_slots()
	
	var preset_name = Global.deck_preset_names.get(str(preset_idx), "プリセット %d" % preset_idx)
	DeskTheme.show_toast(self, "%s を読み込みました！" % preset_name, 1.5, Color("#4a90e2"))
	_update_preset_buttons_highlight()

func _save_preset(preset_idx: int) -> void:
	var key = str(preset_idx)
	Global.deck_presets[key] = Global.get_deck_as_string_keys()
	Global.selected_preset_idx = preset_idx
	Global.save_game()
	
	var preset_name = Global.deck_preset_names.get(str(preset_idx), "プリセット %d" % preset_idx)
	DeskTheme.show_toast(self, "%s に現在のデッキを保存しました！" % preset_name, 1.5, Color("#417505"))
	_update_preset_buttons_highlight()

func _update_preset_buttons_highlight() -> void:
	var active_name = Global.deck_preset_names.get(str(Global.selected_preset_idx), "プリセット %d" % Global.selected_preset_idx)
	if active_preset_label:
		active_preset_label.text = "選択中: %s" % active_name
	if preset_name_edit and not preset_name_edit.has_focus():
		preset_name_edit.text = active_name
		
	for i in range(preset_buttons.size()):
		var btn = preset_buttons[i]
		var idx = i + 1
		btn.text = Global.deck_preset_names.get(str(idx), "プリセット %d" % idx)
		if idx == Global.selected_preset_idx:
			var active_style = StyleBoxFlat.new()
			active_style.bg_color = Color("#eddcc9") # highlight paper color
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
			btn.add_theme_stylebox_override("hover", active_style)
			btn.add_theme_stylebox_override("pressed", active_style)
		else:
			Global.apply_white_button_style(btn)
