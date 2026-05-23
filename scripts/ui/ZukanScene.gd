class_name ZukanScene
extends Control

const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")
const ItemLibrary = preload("res://scripts/core/ItemLibrary.gd")

var audio_manager = null
var detail_container: VBoxContainer
var list_container: VBoxContainer
var item_list: Array = []


func _ready():
	audio_manager = get_tree().root.get_node_or_null("AudioManager")
	DeskTheme.decorate_scene(self, 0.24)

	for item_type in ItemLibrary.all_item_types():
		item_list.append({
			"type": item_type,
			"name": ItemLibrary.name(item_type),
			"desc": ItemLibrary.description(item_type),
			"number": GameBalance.loadout_number_for_item(item_type) if item_type != Enums.ItemType.DELETE_CARD else -1,
			"color": ItemLibrary.color(item_type)
		})

	var ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)

	var notebook = DeskTheme.create_notebook_panel(Vector2(1400, 800), 50, 45, 50, 45)
	notebook.anchor_left = 0.5
	notebook.anchor_top = 0.5
	notebook.anchor_right = 0.5
	notebook.anchor_bottom = 0.5
	notebook.offset_left = -700
	notebook.offset_top = -400
	notebook.offset_right = 700
	notebook.offset_bottom = 400
	ui_root.add_child(notebook)

	var content_node = notebook.get_node("Content")
	var page_split = HBoxContainer.new()
	page_split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_split.add_theme_constant_override("separation", 60)
	content_node.add_child(page_split)

	var left_page = VBoxContainer.new()
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.add_theme_constant_override("separation", 16)
	page_split.add_child(left_page)

	left_page.add_child(DeskTheme.create_label("文房具図鑑", 38, DeskTheme.COLOR_INK, true))
	left_page.add_child(DeskTheme.create_label("実装済みアイテムの役割と使用状況", 16, DeskTheme.COLOR_MUTED, false))

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_page.add_child(scroll)

	list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.add_theme_constant_override("separation", 10)
	scroll.add_child(list_container)

	for item_data in item_list:
		list_container.add_child(_create_list_item(item_data))

	var back_btn = DeskTheme.create_button("タイトルへ戻る", Vector2(240, 50), Color("bd4f4f"), Color("8a3939"), false, 18)
	back_btn.pressed.connect(func():
		if audio_manager:
			audio_manager.play_se("click")
		get_tree().change_scene_to_file("res://Title.tscn")
	)
	left_page.add_child(back_btn)

	var right_page = VBoxContainer.new()
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.add_theme_constant_override("separation", 20)
	page_split.add_child(right_page)

	right_page.add_child(DeskTheme.create_label("詳細", 30, DeskTheme.COLOR_INK, true))
	detail_container = VBoxContainer.new()
	detail_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_container.add_theme_constant_override("separation", 24)
	right_page.add_child(detail_container)

	_select_item(item_list[0])
	DeskTheme.animate_entrance(notebook)


func _create_list_item(item_data: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(500, 54)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("fdfcf7")
	style_normal.border_width_left = 6
	style_normal.border_color = item_data.color
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.content_margin_left = 12
	style_normal.content_margin_right = 12

	var style_hover = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color("f7f3e3")
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	btn.add_child(hbox)

	var color_rect = ColorRect.new()
	color_rect.color = item_data.color
	color_rect.custom_minimum_size = Vector2(12, 12)
	color_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(color_rect)

	var num_str = "[%d]" % item_data.number if item_data.number > 0 else "[特殊]"
	hbox.add_child(DeskTheme.create_label(num_str, 18, DeskTheme.COLOR_MUTED, true))
	hbox.add_child(DeskTheme.create_label(item_data.name, 20, DeskTheme.COLOR_INK, true))

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var usage = Global.get_item_usage(item_data.type)
	hbox.add_child(DeskTheme.create_label("使用 %d" % usage, 16, DeskTheme.COLOR_MUTED, true))

	btn.pressed.connect(func():
		_select_item(item_data)
	)
	return btn


func _select_item(item_data: Dictionary):
	if audio_manager:
		audio_manager.play_se("click")

	for child in detail_container.get_children():
		child.queue_free()

	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 35)
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_container.add_child(main_hbox)

	var card_wrapper = Control.new()
	card_wrapper.custom_minimum_size = Vector2(200, 280)
	card_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(card_wrapper)

	var card_node = DeskTheme.create_item_card_large(item_data.type)
	card_wrapper.add_child(card_node)
	card_node.position = Vector2(5, 10)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 14)
	main_hbox.add_child(info_vbox)

	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 15)
	info_vbox.add_child(name_hbox)
	name_hbox.add_child(DeskTheme.create_label(item_data.name, 32, DeskTheme.COLOR_INK, true))

	var subject_val = Enums.ITEM_SUBJECT_MAP.get(item_data.type, Enums.Subject.NONE)
	if subject_val != Enums.Subject.NONE:
		name_hbox.add_child(DeskTheme.create_stat_chip(DeskTheme.subject_name(subject_val), DeskTheme.subject_color(subject_val), 16))

	var is_unlocked = Global.unlocked_items.has(item_data.type)
	if is_unlocked:
		info_vbox.add_child(DeskTheme.create_stat_chip("解放済み", DeskTheme.COLOR_SAFE, 15))
	else:
		info_vbox.add_child(DeskTheme.create_stat_chip("未解放", Color("bd4f4f"), 15))

	info_vbox.add_child(DeskTheme.create_label("使用回数: %d" % Global.get_item_usage(item_data.type), 18, DeskTheme.COLOR_INK, false))

	var divider = ColorRect.new()
	divider.color = Color(0.8, 0.75, 0.65, 0.5)
	divider.custom_minimum_size = Vector2(0, 2)
	detail_container.add_child(divider)

	var desc_panel = PanelContainer.new()
	var desc_style = StyleBoxFlat.new()
	desc_style.bg_color = Color("fcfcf9")
	desc_style.border_width_left = 6
	desc_style.border_color = item_data.color
	desc_style.corner_radius_top_right = 8
	desc_style.corner_radius_bottom_right = 8
	desc_style.content_margin_left = 16
	desc_style.content_margin_right = 16
	desc_style.content_margin_top = 14
	desc_style.content_margin_bottom = 14
	desc_panel.add_theme_stylebox_override("panel", desc_style)
	detail_container.add_child(desc_panel)

	var desc_text = DeskTheme.create_label(item_data.desc, 18, DeskTheme.COLOR_INK, false)
	desc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_panel.add_child(desc_text)
