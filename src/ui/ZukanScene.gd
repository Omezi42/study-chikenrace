class_name ZukanScene
extends Control

# Constants for Titles
const ALL_TITLES: Array[String] = [
	Constants.TITLE_DEV_GOD, Constants.TITLE_CRAM_GENIUS, Constants.TITLE_SAFE_CHAMP,
	Constants.TITLE_RICH_STUDENT, Constants.TITLE_STORM, Constants.TITLE_OVERACHIEVER,
	Constants.TITLE_SNIPER, Constants.TITLE_CHIKEN_HERO, Constants.TITLE_POKER_FACE,
	Constants.TITLE_STATIONERY_MASTER, Constants.TITLE_SPEED_RUNNER, Constants.TITLE_WOLF_BOY,
	Constants.TITLE_DOUBT_SPAMMER, Constants.TITLE_LIE_DETECTOR, Constants.TITLE_CHARISMA,
	Constants.TITLE_TODAI, Constants.TITLE_LUCKY_SEVEN, Constants.TITLE_RED_FAIL,
	Constants.TITLE_CRAM_HONEST, Constants.TITLE_SAFETY_FIRST, Constants.TITLE_EASY_TARGET,
	Constants.TITLE_DEBT_KING, Constants.TITLE_GLASS_HEART, Constants.TITLE_EXCELLENT,
	Constants.TITLE_UNDERACHIEVER, Constants.TITLE_AVERAGE
]

const TITLE_DESCRIPTIONS: Dictionary = {
	Constants.TITLE_DEV_GOD: "偏差値70以上を達成して試合を終える",
	Constants.TITLE_CRAM_GENIUS: "一夜漬け/模試モードでスコア100/150以上かつ1位を獲得する",
	Constants.TITLE_SAFE_CHAMP: "バースト回数0で1位を獲得する",
	Constants.TITLE_RICH_STUDENT: "500コイン以上を所持して1位を獲得する",
	Constants.TITLE_STORM: "1試合で3回以上バーストする",
	Constants.TITLE_OVERACHIEVER: "嘘を一度もつかずに高得点（一夜漬け150点、通常200点以上）を達成する",
	Constants.TITLE_SNIPER: "嘘を一度もつかずに、他プレイヤーへのダウトを2回以上成功させる",
	Constants.TITLE_CHIKEN_HERO: "バースト回数1回以下で超高得点（一夜漬け180点、通常250点以上）を達成する",
	Constants.TITLE_POKER_FACE: "すべての日に嘘を申告し、かつ一度もダウトで見破られない",
	Constants.TITLE_STATIONERY_MASTER: "参考書アイテムを24種類以上解放する",
	Constants.TITLE_SPEED_RUNNER: "試合を合計50回以上プレイする",
	Constants.TITLE_WOLF_BOY: "嘘が他プレイヤーに見破られた回数が3回以上になる",
	Constants.TITLE_DOUBT_SPAMMER: "他プレイヤーへのダウトが4回以上成功する",
	Constants.TITLE_LIE_DETECTOR: "他プレイヤーへのダウトが3回以上成功する",
	Constants.TITLE_CHARISMA: "2回以上嘘をつき、一度も見破られずに高得点（一夜漬け150点、通常200点以上）を達成する",
	Constants.TITLE_TODAI: "1試合で高スコア（一夜漬け200点、通常300点以上）を達成する",
	Constants.TITLE_LUCKY_SEVEN: "最終スコアの1の位が7の状態で1位を獲得する",
	Constants.TITLE_RED_FAIL: "最終スコアが50点以下で終わる",
	Constants.TITLE_CRAM_HONEST: "嘘を一度もつかずにそこそこの得点（一夜漬け120点、通常180点以上）を達成する",
	Constants.TITLE_SAFETY_FIRST: "1試合で一度もバーストしない",
	Constants.TITLE_EASY_TARGET: "ダウト成功0かつ嘘見破られ1回以上で終わる",
	Constants.TITLE_DEBT_KING: "所持コイン10以下で最下位（4位）になる",
	Constants.TITLE_GLASS_HEART: "2回以上嘘をつき、ついた嘘がすべて見破られる",
	Constants.TITLE_EXCELLENT: "1位を獲得する",
	Constants.TITLE_UNDERACHIEVER: "最下位（4位）になる",
	Constants.TITLE_AVERAGE: "一般的な成績で試合を終了する"
}

# UI Elements
var tab_item_btn: Button
var tab_title_btn: Button

# Left page containers
var left_scroll_item: ScrollContainer
var left_scroll_title: ScrollContainer
var list_container: VBoxContainer
var title_grid_container: GridContainer
var left_title_label: Label

# Right page containers
var right_inner_item: VBoxContainer
var right_inner_title: VBoxContainer

# Right Page (Item Details)
var card_panel: PanelContainer
var item_texture: TextureRect
var card_title: Label
var card_description: Label
var card_role_lbl: Label
var usage_count_lbl: Label
var stars_container: HBoxContainer

# Right Page (Title Details)
var title_detail_stamp: PanelContainer
var title_detail_name: Label
var title_detail_desc: Label
var title_detail_status: Label

var back_btn: Button
var selected_item_id: String = ""
var selected_title_id: String = ""
var current_tab: String = "item" # "item" or "title"

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
	
	# Dimmer overlay
	var dimmer = ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.2)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 15)
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)
	
	# Tab Switching Header
	var tab_hbox = HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(tab_hbox)
	
	tab_item_btn = Button.new()
	tab_item_btn.text = "参考書図鑑"
	tab_item_btn.custom_minimum_size = Vector2(200, 50)
	tab_item_btn.add_theme_font_override("font", DeskTheme.get_font())
	tab_item_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(tab_item_btn)
	tab_hbox.add_child(tab_item_btn)
	tab_item_btn.pressed.connect(func(): _switch_tab("item"))
	
	tab_title_btn = Button.new()
	tab_title_btn.text = "獲得称号ギャラリー"
	tab_title_btn.custom_minimum_size = Vector2(200, 50)
	tab_title_btn.add_theme_font_override("font", DeskTheme.get_font())
	tab_title_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(tab_title_btn)
	tab_hbox.add_child(tab_title_btn)
	tab_title_btn.pressed.connect(func(): _switch_tab("title"))
	
	# Center Book Layout
	var center_container = CenterContainer.new()
	main_vbox.add_child(center_container)
	
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
	left_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL)
	left_page.add_child(left_vbox)
	
	var left_margin = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", DeskTheme.MARGIN_DEFAULT)
	left_margin.add_theme_constant_override("margin_right", DeskTheme.MARGIN_DEFAULT)
	left_margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_DEFAULT)
	left_margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_DEFAULT)
	left_vbox.add_child(left_margin)
	
	var left_inner = VBoxContainer.new()
	left_inner.add_theme_constant_override("separation", DeskTheme.MARGIN_SMALL)
	left_margin.add_child(left_inner)
	
	left_title_label = Label.new()
	left_title_label.text = "参考書アイテム図鑑"
	left_title_label.add_theme_font_override("font", DeskTheme.get_font())
	left_title_label.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE)
	left_title_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	left_inner.add_child(left_title_label)
	
	# Scroll for Items
	left_scroll_item = ScrollContainer.new()
	left_scroll_item.custom_minimum_size = Vector2(680, 680)
	left_scroll_item.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_inner.add_child(left_scroll_item)
	
	list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.add_theme_constant_override("separation", 12)
	left_scroll_item.add_child(list_container)
	
	# Scroll for Titles
	left_scroll_title = ScrollContainer.new()
	left_scroll_title.custom_minimum_size = Vector2(680, 680)
	left_scroll_title.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll_title.visible = false
	left_inner.add_child(left_scroll_title)
	
	title_grid_container = GridContainer.new()
	title_grid_container.columns = 3
	title_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_grid_container.add_theme_constant_override("h_separation", 15)
	title_grid_container.add_theme_constant_override("v_separation", 15)
	left_scroll_title.add_child(title_grid_container)
	
	# RIGHT PAGE: Details
	var right_page = PanelContainer.new()
	right_page.custom_minimum_size = Vector2(750, 850)
	right_page.add_theme_stylebox_override("panel", DeskTheme.create_right_page_style())
	main_hbox.add_child(right_page)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_MEDIUM)
	right_page.add_child(right_vbox)
	
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", DeskTheme.MARGIN_LARGE)
	right_margin.add_theme_constant_override("margin_right", DeskTheme.MARGIN_LARGE)
	right_margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_LARGE)
	right_margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_LARGE)
	right_vbox.add_child(right_margin)
	
	# Inner container for item details
	right_inner_item = VBoxContainer.new()
	right_inner_item.add_theme_constant_override("separation", DeskTheme.MARGIN_MEDIUM)
	right_margin.add_child(right_inner_item)
	
	# Card Visual Container
	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(240, 320)
	card_panel.pivot_offset = Vector2(120, 160)
	card_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_inner_item.add_child(card_panel)
	
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
	card_title.add_theme_font_override("font", DeskTheme.get_font())
	card_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_LARGE)
	card_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	card_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_panel.add_child(card_title)
	
	# Description
	var desc_vbox = VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 10)
	right_inner_item.add_child(desc_vbox)
	
	card_role_lbl = Label.new()
	card_role_lbl.add_theme_font_override("font", DeskTheme.get_font())
	card_role_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	desc_vbox.add_child(card_role_lbl)
	
	card_description = Label.new()
	card_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_description.add_theme_font_override("font", DeskTheme.get_font())
	card_description.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	card_description.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	desc_vbox.add_child(card_description)
	
	# Stars & Usage
	usage_count_lbl = Label.new()
	usage_count_lbl.add_theme_font_override("font", DeskTheme.get_font())
	usage_count_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	usage_count_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	right_inner_item.add_child(usage_count_lbl)
	
	stars_container = HBoxContainer.new()
	stars_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	stars_container.add_theme_constant_override("separation", 10)
	right_inner_item.add_child(stars_container)
	
	# Inner container for title details
	right_inner_title = VBoxContainer.new()
	right_inner_title.add_theme_constant_override("separation", DeskTheme.MARGIN_MEDIUM)
	right_inner_title.visible = false
	right_margin.add_child(right_inner_title)
	
	# Title Detail Stamp Visual
	title_detail_stamp = PanelContainer.new()
	title_detail_stamp.custom_minimum_size = Vector2(300, 120)
	title_detail_stamp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_inner_title.add_child(title_detail_stamp)
	
	title_detail_name = Label.new()
	title_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_detail_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_detail_name.add_theme_font_override("font", DeskTheme.get_font())
	title_detail_name.add_theme_font_size_override("font_size", 24)
	title_detail_name.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title_detail_stamp.add_child(title_detail_name)
	
	# Title Condition & Status
	var title_desc_vbox = VBoxContainer.new()
	title_desc_vbox.add_theme_constant_override("separation", 15)
	right_inner_title.add_child(title_desc_vbox)
	
	var cond_header = Label.new()
	cond_header.text = "【獲得条件】"
	cond_header.add_theme_font_override("font", DeskTheme.get_font())
	cond_header.add_theme_font_size_override("font_size", 16)
	cond_header.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	title_desc_vbox.add_child(cond_header)
	
	title_detail_desc = Label.new()
	title_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_detail_desc.add_theme_font_override("font", DeskTheme.get_font())
	title_detail_desc.add_theme_font_size_override("font_size", 18)
	title_detail_desc.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title_desc_vbox.add_child(title_detail_desc)
	
	title_detail_status = Label.new()
	title_detail_status.add_theme_font_override("font", DeskTheme.get_font())
	title_detail_status.add_theme_font_size_override("font_size", 16)
	title_desc_vbox.add_child(title_detail_status)
	
	# Back button (Common)
	back_btn = Button.new()
	back_btn.text = "タイトルに戻る"
	back_btn.custom_minimum_size = Vector2(320, 70)
	back_btn.add_theme_font_override("font", DeskTheme.get_font())
	back_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_LARGE)
	Global.apply_white_button_style(back_btn)
	back_btn.pressed.connect(func():
		back_btn.release_focus()
		_on_back_pressed()
	)
	# Common bottom placement
	right_vbox.alignment = BoxContainer.ALIGNMENT_END
	right_vbox.add_child(back_btn)
	
	# Initial setup
	_switch_tab("item")
	
	# Apply notebook visual details
	DeskTheme.add_ruled_lines(left_page)
	DeskTheme.add_ruled_lines(right_page)
	DeskTheme.add_spiral_binding(main_hbox, 850.0)

func _switch_tab(tab: String) -> void:
	current_tab = tab
	if tab == "item":
		left_title_label.text = "参考書アイテム図鑑"
		left_scroll_item.visible = true
		left_scroll_title.visible = false
		right_inner_item.visible = true
		right_inner_title.visible = false
		
		# Tab button visual indicator
		tab_item_btn.modulate = Color.WHITE
		tab_title_btn.modulate = Color(0.7, 0.7, 0.7, 0.8)
		
		populate_catalog()
		if Global.unlocked_items.size() > 0:
			select_item(Global.unlocked_items[0])
	else:
		# Count completed progress
		var unlocked_count = 0
		for t in ALL_TITLES:
			if t in Global.unlocked_titles:
				unlocked_count += 1
		
		left_title_label.text = "称号ギャラリー (%d / %d)" % [unlocked_count, ALL_TITLES.size()]
		left_scroll_item.visible = false
		left_scroll_title.visible = true
		right_inner_item.visible = false
		right_inner_title.visible = true
		
		# Tab button visual indicator
		tab_item_btn.modulate = Color(0.7, 0.7, 0.7, 0.8)
		tab_title_btn.modulate = Color.WHITE
		
		populate_titles()
		select_title(ALL_TITLES[0])

func populate_catalog() -> void:
	for child in list_container.get_children():
		child.queue_free()
		
	# Render items
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
			name_lbl.add_theme_font_override("font", DeskTheme.get_font())
			name_lbl.add_theme_font_size_override("font_size", 20)
			name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			btn_hbox.add_child(name_lbl)
			
			btn.pressed.connect(func():
				btn.release_focus()
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
		btn.add_theme_font_override("font", DeskTheme.get_font())
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
		
	# Spawn 5 star symbols
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

func populate_titles() -> void:
	for child in title_grid_container.get_children():
		child.queue_free()
		
	for title in ALL_TITLES:
		var is_unlocked = title in Global.unlocked_titles
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 75)
		
		if is_unlocked:
			btn.text = title
			btn.add_theme_stylebox_override("normal", DeskTheme.create_stamp_style(Color("c62828"), Color(1, 0.95, 0.95, 0.5)))
			btn.add_theme_color_override("font_color", Color("c62828"))
		else:
			btn.text = "？？？"
			var locked_style = DeskTheme.create_craft_panel()
			btn.modulate = Color(0.6, 0.6, 0.6, 0.5)
			btn.add_theme_stylebox_override("normal", locked_style)
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			
		btn.add_theme_font_override("font", DeskTheme.get_font())
		btn.add_theme_font_size_override("font_size", 14)
		
		btn.pressed.connect(func():
			btn.release_focus()
			DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
			select_title(title)
		)
		title_grid_container.add_child(btn)

func select_title(title: String) -> void:
	selected_title_id = title
	var is_unlocked = title in Global.unlocked_titles
	
	title_detail_name.text = title if is_unlocked else "？？？？？"
	title_detail_desc.text = TITLE_DESCRIPTIONS.get(title, "？？？")
	
	if is_unlocked:
		title_detail_stamp.modulate = Color.WHITE
		title_detail_stamp.add_theme_stylebox_override("panel", DeskTheme.create_stamp_style(Color("c62828"), Color(1, 0.95, 0.95, 0.5)))
		title_detail_name.add_theme_color_override("font_color", Color("c62828"))
		title_detail_status.text = "獲得ステータス: 獲得済み"
		title_detail_status.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	else:
		var locked_style = DeskTheme.create_craft_panel()
		title_detail_stamp.modulate = Color(0.6, 0.6, 0.6, 0.5)
		title_detail_stamp.add_theme_stylebox_override("panel", locked_style)
		title_detail_name.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		title_detail_status.text = "獲得ステータス: 未獲得"
		title_detail_status.add_theme_color_override("font_color", Color("d32f2f"))

func _on_back_pressed() -> void:
	DeskTheme.animate_click(back_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
	)
