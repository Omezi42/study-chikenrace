extends Control

var audio_manager = null
var slot_buttons: Dictionary = {}

func _ready():
	# Retrieve AudioManager if it exists in the tree
	audio_manager = get_tree().root.get_node_or_null("AudioManager")
	
	# Background (Chalkboard style)
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.18, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	margin.add_child(vbox)
	
	var title = DeskTheme.create_label("デッキ編成 (Loadout)", 48, DeskTheme.COLOR_CHALK_YELLOW, true)
	vbox.add_child(title)
	
	var desc = DeskTheme.create_label("1〜10枚の枠に設定するアイテムを選択してください", 24, DeskTheme.COLOR_CHALK_WHITE, true)
	vbox.add_child(desc)
	
	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 30)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)
	
	for i in range(1, 11):
		var slot_vbox = VBoxContainer.new()
		slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_vbox.add_theme_constant_override("separation", 10)
		
		var label = DeskTheme.create_label("%d枚の枠" % i, 24, DeskTheme.COLOR_CHALK_WHITE, true)
		slot_vbox.add_child(label)
		
		var current_item = Global.current_loadout.get(i, Enums.ItemType.STICKY_NOTE)
		var item_name = _get_item_name(current_item)
		var btn = DeskTheme.create_button(item_name, Vector2(180, 80), DeskTheme.COLOR_SAFE, Color("0e5057"), false, 20)
		slot_buttons[i] = btn
		
		btn.pressed.connect(func():
			if audio_manager: audio_manager.play_se("click")
			_show_item_select_popup(i, btn)
		)
		
		slot_vbox.add_child(btn)
		grid.add_child(slot_vbox)
		
	var back_btn = DeskTheme.create_button("タイトルへ戻る", Vector2(300, 70), Color("bd4f4f"), Color("8a3939"), false, 24)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func():
		if audio_manager: audio_manager.play_se("click")
		get_tree().change_scene_to_file("res://Title.tscn")
	)
	vbox.add_child(back_btn)

func _get_item_name(item_type: int) -> String:
	match item_type:
		Enums.ItemType.STICKY_NOTE: return "付箋"
		Enums.ItemType.ERASER: return "消しゴム"
		Enums.ItemType.RULER: return "定規"
		Enums.ItemType.WORD_BOOK: return "単語帳"
		Enums.ItemType.CHEAT_SHEET: return "ズルカンペ"
		Enums.ItemType.COMPASS: return "コンパス"
		Enums.ItemType.ENERGY_DRINK: return "エナドリ"
		Enums.ItemType.RED_SHEET: return "赤シート"
		Enums.ItemType.MECHANICAL_PENCIL: return "シャーペン"
		Enums.ItemType.THICK_BOOK: return "分厚い参考書"
		Enums.ItemType.DELETE_CARD: return "忘却のノート"
	return "???"

func _show_item_select_popup(slot_num: int, update_btn: Button):
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_NOTE
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = DeskTheme.COLOR_INK
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(800, 600)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer_top)
	
	vbox.add_child(DeskTheme.create_label("%d枚の枠にセットするアイテムを選択" % slot_num, 28, DeskTheme.COLOR_INK, true))
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.add_child(grid)
	
	for item_type in Global.unlocked_items:
		if item_type == Enums.ItemType.DELETE_CARD:
			continue
		var item_btn = DeskTheme.create_button(_get_item_name(item_type), Vector2(220, 70), DeskTheme.COLOR_SAFE, Color("0e5057"), false, 20)
		item_btn.pressed.connect(func():
			if audio_manager: audio_manager.play_se("click")
			Global.current_loadout[slot_num] = item_type
			Global.save_data()
			update_btn.text = _get_item_name(item_type)
			overlay.queue_free()
		)
		grid.add_child(item_btn)
		
	var close_btn = DeskTheme.create_button("キャンセル", Vector2(240, 60), Color("bd4f4f"), Color("8a3939"), false, 22)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func():
		if audio_manager: audio_manager.play_se("click")
		overlay.queue_free()
	)
	vbox.add_child(close_btn)
	
	var spacer_bottom = Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer_bottom)
