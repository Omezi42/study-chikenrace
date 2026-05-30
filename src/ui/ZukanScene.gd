class_name ZukanScene
extends Control

# UI Elements
var list_container: VBoxContainer
var card_panel: PanelContainer
var item_texture: TextureRect
var card_title: Label
var card_description: Label
var card_role_lbl: Label
var usage_count_lbl: Label
var stars_container: HBoxContainer
var back_btn: Button

var selected_item_id: String = ""

func _ready() -> void:
	# Mahogany background
	var bg_color = ColorRect.new()
	bg_color.color = DeskTheme.COLOR_MAHOGANY
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	# Load desk background if exists
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/机の背景画像-ノート無し.png"):
		bg_tex.texture = load("res://assets/机の背景画像-ノート無し.png")
	bg_tex.modulate = Color.WHITE
	add_child(bg_tex)
	
	# 見やすさのため薄いオーバーレイを敷く
	var dimmer = ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.2)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 0)
	center_container.add_child(main_hbox)
	
	# LEFT PAGE: Notebook Catalog List
	var left_page = PanelContainer.new()
	left_page.custom_minimum_size = Vector2(750, 850)
	left_page.add_theme_stylebox_override("panel", DeskTheme.create_left_page_style())
	main_hbox.add_child(left_page)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 20)
	left_page.add_child(left_vbox)
	
	var left_margin = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 30)
	left_margin.add_theme_constant_override("margin_right", 30)
	left_margin.add_theme_constant_override("margin_top", 30)
	left_margin.add_theme_constant_override("margin_bottom", 30)
	left_vbox.add_child(left_margin)
	
	var left_inner = VBoxContainer.new()
	left_inner.add_theme_constant_override("separation", 20)
	left_margin.add_child(left_inner)
	
	var left_title = Label.new()
	left_title.text = "参考書アイテム図鑑"
	left_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	left_title.add_theme_font_size_override("font_size", 32)
	left_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	left_inner.add_child(left_title)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 680)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_inner.add_child(scroll)
	
	list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.add_theme_constant_override("separation", 12)
	scroll.add_child(list_container)
	
	# RIGHT PAGE: Selected Item Details
	var right_page = PanelContainer.new()
	right_page.custom_minimum_size = Vector2(750, 850)
	right_page.add_theme_stylebox_override("panel", DeskTheme.create_right_page_style())
	main_hbox.add_child(right_page)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 25)
	right_page.add_child(right_vbox)
	
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 35)
	right_margin.add_theme_constant_override("margin_right", 35)
	right_margin.add_theme_constant_override("margin_top", 35)
	right_margin.add_theme_constant_override("margin_bottom", 35)
	right_vbox.add_child(right_margin)
	
	var right_inner = VBoxContainer.new()
	right_inner.add_theme_constant_override("separation", 25)
	right_margin.add_child(right_inner)
	
	# Card Visual Container
	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(240, 320)
	card_panel.pivot_offset = Vector2(120, 160)
	card_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_inner.add_child(card_panel)
	
	item_texture = TextureRect.new()
	item_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_texture.custom_minimum_size = Vector2(200, 200)
	item_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item_texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_panel.add_child(item_texture)
	
	card_title = Label.new()
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	card_title.add_theme_font_size_override("font_size", 26)
	card_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	card_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_panel.add_child(card_title)
	
	# Description
	var desc_vbox = VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 10)
	right_inner.add_child(desc_vbox)
	
	card_role_lbl = Label.new()
	card_role_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	card_role_lbl.add_theme_font_size_override("font_size", 22)
	desc_vbox.add_child(card_role_lbl)
	
	card_description = Label.new()
	card_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_description.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	card_description.add_theme_font_size_override("font_size", 22)
	card_description.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	desc_vbox.add_child(card_description)
	
	# Stars & Usage
	usage_count_lbl = Label.new()
	usage_count_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	usage_count_lbl.add_theme_font_size_override("font_size", 18)
	usage_count_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	right_inner.add_child(usage_count_lbl)
	
	stars_container = HBoxContainer.new()
	stars_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	stars_container.add_theme_constant_override("separation", 10)
	right_inner.add_child(stars_container)
	
	# Back button
	back_btn = Button.new()
	back_btn.text = "タイトルに戻る"
	back_btn.custom_minimum_size = Vector2(320, 70)
	back_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	back_btn.add_theme_font_size_override("font_size", 26)
	Global.apply_white_button_style(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	right_inner.add_child(back_btn)
	
	# Populate catalog items
	populate_catalog()
	
	# Auto-select first unlocked item if any
	if Global.unlocked_items.size() > 0:
		select_item(Global.unlocked_items[0])
		
	# Apply notebook visual details
	DeskTheme.add_ruled_lines(left_page)
	DeskTheme.add_ruled_lines(right_page)
	DeskTheme.add_spiral_binding(main_hbox, 850.0)

func populate_catalog() -> void:
	for child in list_container.get_children():
		child.queue_free()
		
	# Render 24 items (excluding system tokens like item_forget_notebook)
	for item_id in CardData.ITEMS.keys():
		var item = CardData.ITEMS[item_id]
		if item_id == "item_forget_notebook":
			continue
			
		var is_unlocked = item_id in Global.unlocked_items
		
		# Create list button
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(620, 65)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = DeskTheme.COLOR_CRAFT
		btn_style.border_width_left = 6
		btn_style.border_width_right = 1
		btn_style.border_width_top = 1
		btn_style.border_width_bottom = 1
		btn_style.corner_radius_top_left = 4
		btn_style.corner_radius_bottom_left = 4
		
		if is_unlocked:
			btn_style.border_color = CardData.get_role_color(item["role"])
			btn.text = ""
			
			var btn_hbox = HBoxContainer.new()
			btn_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
			btn_hbox.add_theme_constant_override("separation", 10)
			btn_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			btn_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(btn_hbox)
			
			var space = Control.new()
			space.custom_minimum_size = Vector2(8, 0)
			btn_hbox.add_child(space)
			
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
			name_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
			name_lbl.add_theme_font_size_override("font_size", 20)
			name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			btn_hbox.add_child(name_lbl)
			
			btn.pressed.connect(func():
				DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
				select_item(item_id)
			)
		else:
			btn_style.border_color = Color.GRAY
			btn.text = "  ？？？ (未解放)"
			btn.add_theme_color_override("font_color", Color.GRAY)
			btn.disabled = true
			
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("disabled", btn_style)
		btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		btn.add_theme_font_size_override("font_size", 22)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		list_container.add_child(btn)

func select_item(item_id: String) -> void:
	selected_item_id = item_id
	var item = CardData.ITEMS[item_id]
	
	card_title.text = item["name"]
	card_description.text = item["description"]
	card_role_lbl.text = "系統: " + CardData.get_role_name(item["role"])
	card_role_lbl.add_theme_color_override("font_color", CardData.get_role_color(item["role"]))
	
	# Usage count
	var usage = int(Global.item_usage_counts.get(item_id, 0))
	usage_count_lbl.text = "通算使用回数: " + str(usage) + " 回"
	
	# Star level and requirements
	var stars = Global.get_item_stars(item_id)
	for child in stars_container.get_children():
		child.queue_free()
		
	# Spawn 5 star symbols (active vs inactive)
	for i in range(1, 6):
		var star_lbl = Label.new()
		if i <= stars:
			star_lbl.text = "★"
			star_lbl.add_theme_color_override("font_color", Color("ffd700")) # Active Gold
		else:
			star_lbl.text = "☆"
			star_lbl.add_theme_color_override("font_color", Color.GRAY)
		star_lbl.add_theme_font_size_override("font_size", 30)
		stars_container.add_child(star_lbl)
		
	# Slide & flip card visual on select
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = DeskTheme.COLOR_CRAFT
	card_style.border_color = CardData.get_role_color(item["role"])
	card_style.border_width_left = 4
	card_style.border_width_right = 4
	card_style.border_width_top = 4
	card_style.border_width_bottom = 4
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_panel.add_theme_stylebox_override("panel", card_style)
	
	var tex_path = CardData.get_item_image_path(item_id)
	card_panel.scale = Vector2.ONE
	DeskTheme.animate_card_flip(card_panel, 0.3, func():
		if tex_path != "" and ResourceLoader.exists(tex_path):
			item_texture.texture = load(tex_path)
			item_texture.visible = true
			card_title.visible = false
		else:
			item_texture.texture = null
			item_texture.visible = false
			card_title.visible = true
	)

func _on_back_pressed() -> void:
	DeskTheme.animate_click(back_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
	)
