class_name ZukanScene
extends Control

const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")

var audio_manager = null
var detail_container: VBoxContainer
var list_container: VBoxContainer

var ITEM_MASTER_LIST = [
	{ "type": Enums.ItemType.STICKY_NOTE, "name": "付箋", "desc": "ストップ時にボーナス得点+30点が入ります。\n(バースト数字: 1)", "number": 1, "color": Color("ffd43b") },
	{ "type": Enums.ItemType.ERASER, "name": "消しゴム", "desc": "場のカード（他のアイテム）の数字1枚を無効化します（バースト回避に有用です）。\n(バースト数字: 2)", "number": 2, "color": Color("adb5bd") },
	{ "type": Enums.ItemType.RULER, "name": "定規", "desc": "ストップ時にボーナス得点+10点が入ります。\n(バースト数字: 3)", "number": 3, "color": Color("4dabf7") },
	{ "type": Enums.ItemType.WORD_BOOK, "name": "単語帳", "desc": "山札の上3枚を見て、バースト原因となる危険なカードがあれば一番下に送ります。\n(バースト数字: 4)", "number": 4, "color": Color("3bc9db") },
	{ "type": Enums.ItemType.CHEAT_SHEET, "name": "ズルいカンペ", "desc": "嘘（ブラフ）の申告スコア上限がさらに+50点追加されます。\n(バースト数字: 5)", "number": 5, "color": Color("94d82d") },
	{ "type": Enums.ItemType.COMPASS, "name": "コンパス", "desc": "引いた瞬間にスコアに+15点ボーナスが加算されます。\n(バースト数字: 6)", "number": 6, "color": Color("748ffc") },
	{ "type": Enums.ItemType.ENERGY_DRINK, "name": "エナジードリンク", "desc": "次に引くバーストを1回だけ防ぐシールドを得ます。\n(バースト数字: 7)", "number": 7, "color": Color("fcc419") },
	{ "type": Enums.ItemType.RED_SHEET, "name": "赤シート", "desc": "次に引くカードの得点を2倍にします。\n(バースト数字: 8)", "number": 8, "color": Color("ff6b6b") },
	{ "type": Enums.ItemType.MECHANICAL_PENCIL, "name": "シャーペン", "desc": "引いた瞬間にスコアに+5点ボーナスが加算されます。\n(バースト数字: 9)", "number": 9, "color": Color("868e96") },
	{ "type": Enums.ItemType.THICK_BOOK, "name": "分厚い参考書", "desc": "引いた瞬間に山札からさらに強制的に2枚追加ドローします。\n(バースト数字: 10)", "number": 10, "color": Color("845ef7") },
	{ "type": Enums.ItemType.DELETE_CARD, "name": "忘却のノート", "desc": "デッキ（山札・捨て札）から任意の数字のカード・アイテムを1枚選んで完全削除します。\n（インゲームの5,6時間目限定で出現する特殊なアイテムです）", "number": -1, "color": Color("495057") }
]

func _ready():
	audio_manager = get_tree().root.get_node_or_null("AudioManager")
	
	# Background (Chalkboard style for consistent metadata vibe)
	DeskTheme.decorate_scene(self, 0.24)
	
	var ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)
	
	# Huge notebook panel (double page layout)
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
	
	# Layout split into left page & right page via HBox
	var page_split = HBoxContainer.new()
	page_split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_split.add_theme_constant_override("separation", 60)
	content_node.add_child(page_split)
	
	# --- Left Page (List) ---
	var left_page = VBoxContainer.new()
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.add_theme_constant_override("separation", 16)
	page_split.add_child(left_page)
	
	# Header
	var title = DeskTheme.create_label("文房具図鑑", 38, DeskTheme.COLOR_INK, true)
	left_page.add_child(title)
	
	var subtitle = DeskTheme.create_label("インゲームでアイテムを使うと熟練度が上がります", 16, DeskTheme.COLOR_MUTED, false)
	left_page.add_child(subtitle)
	
	# List Scroll container
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_page.add_child(scroll)
	
	list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.add_theme_constant_override("separation", 10)
	scroll.add_child(list_container)
	
	# Populate list
	for item_data in ITEM_MASTER_LIST:
		var item_btn = _create_list_item(item_data)
		list_container.add_child(item_btn)
		
	# Back to Title button (at bottom of left page)
	var back_btn = DeskTheme.create_button("タイトルへ戻る", Vector2(240, 50), Color("bd4f4f"), Color("8a3939"), false, 18)
	back_btn.pressed.connect(func():
		if audio_manager: audio_manager.play_se("click")
		get_tree().change_scene_to_file("res://Title.tscn")
	)
	left_page.add_child(back_btn)
	
	# --- Right Page (Details) ---
	var right_page = VBoxContainer.new()
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.add_theme_constant_override("separation", 20)
	page_split.add_child(right_page)
	
	# Detail box header
	var detail_header = DeskTheme.create_label("文房具の詳細情報", 30, DeskTheme.COLOR_INK, true)
	right_page.add_child(detail_header)
	
	detail_container = VBoxContainer.new()
	detail_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_container.add_theme_constant_override("separation", 24)
	right_page.add_child(detail_container)
	
	# Show the first item details by default
	_select_item(ITEM_MASTER_LIST[0])
	
	DeskTheme.animate_entrance(notebook)

func _create_list_item(item_data: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(500, 54)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("fdfcf7") # Note color tint
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
	
	var style_pressed = style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = Color("ebdcb9")
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_hover)
	
	# Create inner layout manually to avoid generic button theme
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 12)
	btn.add_child(hbox)
	
	# Mini color badge
	var color_rect = ColorRect.new()
	color_rect.color = item_data.color
	color_rect.custom_minimum_size = Vector2(12, 12)
	color_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(color_rect)
	
	# Number label
	var num_str = "[%d]" % item_data.number if item_data.number > 0 else "[削除]"
	var num_label = DeskTheme.create_label(num_str, 18, DeskTheme.COLOR_MUTED, true)
	hbox.add_child(num_label)
	
	# Name label
	var name_label = DeskTheme.create_label(item_data.name, 20, DeskTheme.COLOR_INK, true)
	hbox.add_child(name_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Stars summary
	var usage = Global.get_item_usage(item_data.type)
	var stars = _calc_stars(usage)
	
	var stars_lbl = DeskTheme.create_label("★".repeat(stars) + "☆".repeat(5 - stars), 16, Color("f0c040") if stars > 0 else DeskTheme.COLOR_MUTED, true)
	hbox.add_child(stars_lbl)
	
	btn.pressed.connect(func():
		_select_item(item_data)
	)
	
	return btn

func _select_item(item_data: Dictionary):
	if audio_manager: audio_manager.play_se("click")
	
	# Clear old children
	for child in detail_container.get_children():
		child.queue_free()
		
	# Split card and details horizontally
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 35)
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_container.add_child(main_hbox)
	
	# Card wrapper Control
	var card_wrapper = Control.new()
	card_wrapper.custom_minimum_size = Vector2(200, 280)
	card_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(card_wrapper)
	
	var card_node = DeskTheme.create_item_card_large(item_data.type)
	card_wrapper.add_child(card_node)
	card_node.position = Vector2(5, 10)
	_animate_card_bounce(card_node)
	
	# Details VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 14)
	main_hbox.add_child(info_vbox)
	
	# Row 1: Name and Subject
	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 15)
	info_vbox.add_child(name_hbox)
	
	var name_label = DeskTheme.create_label(item_data.name, 32, DeskTheme.COLOR_INK, true)
	name_hbox.add_child(name_label)
	
	var subject_val = Enums.ITEM_SUBJECT_MAP.get(item_data.type, Enums.Subject.NONE)
	var subject_name_str = DeskTheme.subject_name(subject_val)
	var subject_col = DeskTheme.subject_color(subject_val)
	if subject_val != Enums.Subject.NONE:
		var subj_chip = DeskTheme.create_stat_chip(subject_name_str, subject_col, 16)
		name_hbox.add_child(subj_chip)
		
	# Row 2: Stars and Level status
	var status_hbox = HBoxContainer.new()
	status_hbox.add_theme_constant_override("separation", 15)
	info_vbox.add_child(status_hbox)
	
	var is_unlocked = Global.unlocked_items.has(item_data.type)
	if is_unlocked:
		var level = Global.get_item_level(item_data.type)
		var lvl_chip = DeskTheme.create_stat_chip("強化レベル: Lv.%d" % level, DeskTheme.COLOR_SAFE, 15)
		status_hbox.add_child(lvl_chip)
	else:
		var lock_chip = DeskTheme.create_stat_chip("未所持 (ガチャ限定)", Color("bd4f4f"), 15)
		status_hbox.add_child(lock_chip)
		
	# Row 3: Usage statistics
	var usage = Global.get_item_usage(item_data.type)
	var usage_label = DeskTheme.create_label("現在の使用回数: %d 回" % usage, 18, DeskTheme.COLOR_INK, false)
	info_vbox.add_child(usage_label)
	
	# Row 4: Proficiency Stars
	var stars = _calc_stars(usage)
	var stars_hbox = HBoxContainer.new()
	stars_hbox.add_theme_constant_override("separation", 8)
	info_vbox.add_child(stars_hbox)
	
	var stars_title = DeskTheme.create_label("熟練度: ", 18, DeskTheme.COLOR_INK, false)
	stars_hbox.add_child(stars_title)
	
	var stars_stars = HBoxContainer.new()
	var filled_stars = DeskTheme.create_label("★".repeat(stars), 20, Color("f0c040"), true)
	var empty_stars = DeskTheme.create_label("☆".repeat(5 - stars), 20, DeskTheme.COLOR_MUTED, true)
	stars_stars.add_child(filled_stars)
	stars_stars.add_child(empty_stars)
	stars_hbox.add_child(stars_stars)
	
	# Row 5: Next level progression gauge
	var prof_info = _get_proficiency_progress(usage)
	var next_star_label = DeskTheme.create_label(prof_info.next_desc, 14, DeskTheme.COLOR_MUTED, false)
	info_vbox.add_child(next_star_label)
	
	var gauge = DeskTheme.create_gauge_bar(prof_info.progress, 1.0, Color("4dabf7"), Vector2(300, 14))
	info_vbox.add_child(gauge)
	
	# Divider
	var divider = ColorRect.new()
	divider.color = Color(0.8, 0.75, 0.65, 0.5)
	divider.custom_minimum_size = Vector2(0, 2)
	detail_container.add_child(divider)
	
	# Description Card Block
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

func _animate_card_bounce(card_node: Control):
	card_node.pivot_offset = Vector2(95, 130) # Center of 190x260 card
	card_node.scale = Vector2(0.8, 0.8)
	var tween = card_node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_node, "scale", Vector2(1.0, 1.0), 0.4)

func _calc_stars(usage: int) -> int:
	if usage >= 50: return 5
	if usage >= 30: return 4
	if usage >= 15: return 3
	if usage >= 5: return 2
	if usage >= 1: return 1
	return 0

func _get_proficiency_progress(usage: int) -> Dictionary:
	var stars = _calc_stars(usage)
	var next_needed = 1
	var base = 0
	
	if usage >= 50:
		stars = 5
		base = 50
		next_needed = 50
	elif usage >= 30:
		stars = 4
		base = 30
		next_needed = 50
	elif usage >= 15:
		stars = 3
		base = 15
		next_needed = 30
	elif usage >= 5:
		stars = 2
		base = 5
		next_needed = 15
	elif usage >= 1:
		stars = 1
		base = 1
		next_needed = 5
	else:
		stars = 0
		base = 0
		next_needed = 1
		
	var progress = 1.0
	var next_desc = "熟練度MAX！ (マスター)"
	if stars < 5:
		var den = next_needed - base
		if den > 0:
			progress = float(usage - base) / float(den)
		else:
			progress = 0.0
		next_desc = "次の星まで あと %d 回 (現在: %d/%d)" % [next_needed - usage, usage, next_needed]
		
	return {
		"progress": progress,
		"next_desc": next_desc
	}
