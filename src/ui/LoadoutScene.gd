class_name LoadoutScene
extends Control

var slots_grid: GridContainer
var back_btn: Button
var _preset_tab_bar: PresetTabBar

# Bottom preview panel
var _preview_panel: PanelContainer
var _preview_icon: TextureRect
var _preview_name: Label
var _preview_role: Label
var _preview_desc: Label

# Active selected slot (for preview display)
var _last_selected_slot_num: int = 1

func _ready() -> void:
	# 1. Outer Mahogany wooden frame
	var frame = ColorRect.new()
	frame.color = Color("#4e342e") # Deep brown mahogany
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	
	# Margin to expose the wooden edge
	var board_margin = MarginContainer.new()
	board_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_margin.add_theme_constant_override("margin_left", DeskTheme.MARGIN_LARGE)
	board_margin.add_theme_constant_override("margin_right", DeskTheme.MARGIN_LARGE)
	board_margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_LARGE)
	board_margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_LARGE)
	add_child(board_margin)
	
	# Corkboard texture base
	var cork_base = PanelContainer.new()
	var base_style = StyleBoxFlat.new()
	base_style.bg_color = Color.BLACK
	base_style.border_width_left = 4
	base_style.border_width_right = 4
	base_style.border_width_top = 4
	base_style.border_width_bottom = 4
	base_style.border_color = Color("#261a17")
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
	
	# Center container for UI elements (1-column layout)
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	# Notebook Panel (Loose-leaf paper style)
	var notebook = PanelContainer.new()
	var leaf_style = StyleBoxFlat.new()
	leaf_style.bg_color = Color("#fdfdfa") # Loose-leaf paper color
	leaf_style.border_width_left = 8
	leaf_style.border_color = Color("#3a6b5c") # Spine binding accent
	leaf_style.corner_radius_top_left = 6
	leaf_style.corner_radius_top_right = 10
	leaf_style.corner_radius_bottom_left = 6
	leaf_style.corner_radius_bottom_right = 10
	leaf_style.shadow_color = Color(0, 0, 0, 0.18)
	leaf_style.shadow_size = 12
	leaf_style.shadow_offset = Vector2(4, 5)
	leaf_style.content_margin_left = 28
	leaf_style.content_margin_right = 28
	leaf_style.content_margin_top = 20
	leaf_style.content_margin_bottom = 20
	notebook.custom_minimum_size = Vector2(1440, 900)
	notebook.add_theme_stylebox_override("panel", leaf_style)
	center_container.add_child(notebook)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 14)
	notebook.add_child(main_vbox)
	
	# Title Row: title + back button
	var title_row = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(title_row)
	
	back_btn = Button.new()
	back_btn.text = "戻る"
	back_btn.custom_minimum_size = Vector2(100, 40)
	back_btn.add_theme_font_override("font", DeskTheme.get_font())
	back_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	Global.apply_white_button_style(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	back_btn.mouse_entered.connect(func(): DeskTheme.animate_hover(back_btn, true, Vector2.ONE, 0.08))
	back_btn.mouse_exited.connect(func(): DeskTheme.animate_hover(back_btn, false, Vector2.ONE, 0.08))
	title_row.add_child(back_btn)
	
	var title_lbl = Label.new()
	title_lbl.text = "明日の持ち物チェックリスト"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title_row.add_child(title_lbl)
	
	# Spacer to balance the back button width
	var title_spacer = Control.new()
	title_spacer.custom_minimum_size = Vector2(100, 0)
	title_row.add_child(title_spacer)
	
	# Subtitle
	var sub_title = Label.new()
	sub_title.text = "スロットの番号 (P1〜10) と同じ枚数のカードがデッキに入り、引き当てた時に効果が発動するぞ！"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_title.add_theme_font_override("font", DeskTheme.get_font())
	sub_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_MINI)
	sub_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.55))
	main_vbox.add_child(sub_title)
	
	# Preset Tab Bar
	_preset_tab_bar = PresetTabBar.new()
	_preset_tab_bar.preset_loaded.connect(func(_idx):
		populate_slots()
		_update_preview()
	)
	_preset_tab_bar.preset_saved.connect(func(_idx):
		pass
	)
	main_vbox.add_child(_preset_tab_bar)
	
	# Main 5-column grid (5x2 = 10 slots)
	slots_grid = GridContainer.new()
	slots_grid.columns = 5
	slots_grid.add_theme_constant_override("h_separation", 16)
	slots_grid.add_theme_constant_override("v_separation", 16)
	slots_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(slots_grid)
	
	# Horizontal Preview Panel
	_preview_panel = PanelContainer.new()
	_preview_panel.custom_minimum_size = Vector2(1320, 130)
	var preview_style = StyleBoxFlat.new()
	preview_style.bg_color = Color("#f5eed9")
	preview_style.border_color = Color(DeskTheme.COLOR_INK, 0.25)
	preview_style.border_width_left = 2
	preview_style.border_width_right = 2
	preview_style.border_width_top = 2
	preview_style.border_width_bottom = 2
	preview_style.corner_radius_top_left = 6
	preview_style.corner_radius_top_right = 6
	preview_style.corner_radius_bottom_left = 6
	preview_style.corner_radius_bottom_right = 6
	preview_style.content_margin_left = 16
	preview_style.content_margin_right = 16
	preview_style.content_margin_top = 10
	preview_style.content_margin_bottom = 10
	_preview_panel.add_theme_stylebox_override("panel", preview_style)
	main_vbox.add_child(_preview_panel)
	
	var preview_hbox = HBoxContainer.new()
	preview_hbox.add_theme_constant_override("separation", 20)
	_preview_panel.add_child(preview_hbox)
	
	_preview_icon = TextureRect.new()
	_preview_icon.custom_minimum_size = Vector2(64, 64)
	_preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_hbox.add_child(_preview_icon)
	
	var preview_info_vbox = VBoxContainer.new()
	preview_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_hbox.add_child(preview_info_vbox)
	
	var preview_name_row = HBoxContainer.new()
	preview_name_row.add_theme_constant_override("separation", 12)
	preview_info_vbox.add_child(preview_name_row)
	
	_preview_name = Label.new()
	_preview_name.add_theme_font_override("font", DeskTheme.get_font())
	_preview_name.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_LARGE)
	_preview_name.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	preview_name_row.add_child(_preview_name)
	
	_preview_role = Label.new()
	_preview_role.add_theme_font_override("font", DeskTheme.get_font())
	_preview_role.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	preview_name_row.add_child(_preview_role)
	
	_preview_desc = Label.new()
	_preview_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_desc.add_theme_font_override("font", DeskTheme.get_font())
	_preview_desc.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	_preview_desc.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	preview_info_vbox.add_child(_preview_desc)
	
	populate_slots()
	_update_preview()
	
	if Global.is_tutorial_mode:
		Global.show_tutorial_dialog(
			self,
			"デッキ編成（カバン構築）画面へようこそ！\n\n1〜10の数字スロットに筆記用具アイテムを装備できます。授業中（チキンレース）にその数字のカードを引き当てた瞬間、そのアイテムの効果が自動で発動するよ！\n\nスロットをクリックして自由に付け替えを試してみてね。確認したら『戻る』を押して、ゲームを開始しよう！",
			Vector2(100, 80)
		)

func populate_slots() -> void:
	for child in slots_grid.get_children():
		child.queue_free()
		
	for i in range(1, 11):
		var item_id = Global.current_deck.get(i, "")
		var slot_card = DeckSlotCard.create(i, item_id)
		
		# Slot actions
		slot_card.slot_clicked.connect(func(slot_num):
			_last_selected_slot_num = slot_num
			_open_item_select_modal(slot_num)
		)
		
		# Connect focus / hover to update preview panel
		slot_card.mouse_entered.connect(func():
			_update_preview_for_slot(i)
		)
		slot_card.mouse_exited.connect(func():
			_update_preview() # Reset to last selected
		)
		
		slots_grid.add_child(slot_card)

func _open_item_select_modal(slot_num: int) -> void:
	var current_item_id = Global.current_deck.get(slot_num, "")
	ItemSelectModal.create_and_show(self, slot_num, current_item_id, func(item_id):
		_on_item_equipped(slot_num, item_id)
	)

func _on_item_equipped(slot_num: int, item_id: String) -> void:
	# Duplicate prevention check
	var duplicate_slot = -1
	for s_idx in Global.current_deck.keys():
		if int(s_idx) != slot_num and Global.current_deck[s_idx] == item_id:
			duplicate_slot = int(s_idx)
			break
			
	var item_info = CardData.ITEMS.get(item_id, {})
	var item_color = CardData.get_role_color(item_info.get("role", CardData.ROLE_PREP))
			
	if duplicate_slot != -1:
		var prev_item = Global.current_deck.get(slot_num, "")
		Global.current_deck[duplicate_slot] = prev_item
		Global.current_deck[slot_num] = item_id
		DeskTheme.show_toast(self, "ポケット %d と入れ替えました！" % duplicate_slot, 1.8, item_color)
	else:
		Global.current_deck[slot_num] = item_id
		var item_name = item_info.get("name", "アイテム")
		DeskTheme.show_toast(self, "%s を準備しました！" % item_name, 1.8, item_color)
		
	Global.save_game()
	populate_slots()
	_update_preview()

func _update_preview() -> void:
	_update_preview_for_slot(_last_selected_slot_num)

func _update_preview_for_slot(slot_num: int) -> void:
	var item_id = Global.current_deck.get(slot_num, "")
	var item = CardData.ITEMS.get(item_id, {})
	if item.is_empty():
		_preview_icon.texture = null
		_preview_name.text = "空きスロット (ポケット %d)" % slot_num
		_preview_role.text = ""
		_preview_desc.text = "スロットをクリックして、所持している文房具を装備してください。"
		return
		
	var img_path = CardData.get_item_image_path(item_id)
	if img_path != "":
		_preview_icon.texture = load(img_path)
	else:
		_preview_icon.texture = null
		
	_preview_name.text = item["name"]
	var role_name = CardData.get_role_name(item["role"])
	_preview_role.text = "[ 系統: %s ]" % role_name
	_preview_role.add_theme_color_override("font_color", CardData.get_role_color(item["role"]))
	_preview_desc.text = item["description"]

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
