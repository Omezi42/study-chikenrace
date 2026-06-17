class_name PresetTabBar
extends PanelContainer

signal preset_loaded(idx: int)
signal preset_saved(idx: int)

var _tabs_hbox: HBoxContainer
var _preset_buttons: Array[Button] = []
var _save_btn: Button
var _name_edit: LineEdit
var _rename_btn: Button
var _active_label: Label

func _ready() -> void:
	_apply_panel_style()
	
	var main_hbox = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 16)
	add_child(main_hbox)
	
	# Header
	var header = Label.new()
	header.text = "デッキ"
	header.add_theme_font_override("font", DeskTheme.get_font())
	header.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
	header.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	main_hbox.add_child(header)
	
	# Tab buttons
	_tabs_hbox = HBoxContainer.new()
	_tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs_hbox.add_theme_constant_override("separation", 8)
	main_hbox.add_child(_tabs_hbox)
	
	_preset_buttons.clear()
	for i in range(1, 4):
		var btn = Button.new()
		btn.text = Global.deck_preset_names.get(str(i), "P%d" % i)
		btn.custom_minimum_size = Vector2(140, 40)
		btn.add_theme_font_override("font", DeskTheme.get_font())
		btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_SMALL)
		Global.apply_white_button_style(btn)
		var idx = i  # Capture for closure
		btn.pressed.connect(func():
			btn.release_focus()
			DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
			_load_preset(idx)
		)
		btn.mouse_entered.connect(func(): DeskTheme.animate_hover(btn, true, Vector2.ONE, 0.08))
		btn.mouse_exited.connect(func(): DeskTheme.animate_hover(btn, false, Vector2.ONE, 0.08))
		_tabs_hbox.add_child(btn)
		_preset_buttons.append(btn)
	
	# Separator
	var sep = VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 0)
	main_hbox.add_child(sep)
	
	# Active preset info
	_active_label = Label.new()
	_active_label.text = "選択中: P1"
	_active_label.add_theme_font_override("font", DeskTheme.get_font())
	_active_label.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_MINI)
	_active_label.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	main_hbox.add_child(_active_label)
	
	# Save button
	_save_btn = Button.new()
	_save_btn.text = "保存"
	_save_btn.icon = load("res://assets/icons/save.svg")
	_save_btn.custom_minimum_size = Vector2(90, 36)
	_save_btn.expand_icon = true
	_save_btn.add_theme_color_override("icon_normal_color", DeskTheme.COLOR_INK)
	_save_btn.add_theme_color_override("icon_hover_color", DeskTheme.COLOR_INK)
	_save_btn.add_theme_color_override("icon_pressed_color", DeskTheme.COLOR_INK)
	_save_btn.add_theme_font_override("font", DeskTheme.get_font())
	_save_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_MINI)
	Global.apply_white_button_style(_save_btn)
	_save_btn.pressed.connect(func():
		_save_btn.release_focus()
		DeskTheme.animate_click(_save_btn, Vector2.ONE, 0.08)
		_save_preset(Global.selected_preset_idx)
	)
	main_hbox.add_child(_save_btn)
	
	# Name edit
	var name_hbox = HBoxContainer.new()
	name_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	name_hbox.add_theme_constant_override("separation", 4)
	main_hbox.add_child(name_hbox)
	
	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(160, 36)
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.placeholder_text = "名前"
	_name_edit.add_theme_font_override("font", DeskTheme.get_font())
	_name_edit.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TINY)
	_name_edit.text_submitted.connect(func(new_name):
		_rename_active_preset(new_name)
	)
	name_hbox.add_child(_name_edit)
	
	_rename_btn = Button.new()
	_rename_btn.text = "適用"
	_rename_btn.custom_minimum_size = Vector2(60, 36)
	_rename_btn.add_theme_font_override("font", DeskTheme.get_font())
	_rename_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TINY)
	Global.apply_white_button_style(_rename_btn)
	_rename_btn.pressed.connect(func():
		_rename_btn.release_focus()
		DeskTheme.animate_click(_rename_btn, Vector2.ONE, 0.08)
		_rename_active_preset(_name_edit.text)
	)
	name_hbox.add_child(_rename_btn)
	
	_update_highlights()

func _apply_panel_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#fbf8f3")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = DeskTheme.COLOR_INK
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.1)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	add_theme_stylebox_override("panel", style)

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
	
	var preset_name = Global.deck_preset_names.get(str(preset_idx), "P%d" % preset_idx)
	DeskTheme.show_toast(self, "%s を読み込みました！" % preset_name, 1.5, Color("#4a90e2"))
	_update_highlights()
	preset_loaded.emit(preset_idx)

func _save_preset(preset_idx: int) -> void:
	var key = str(preset_idx)
	Global.deck_presets[key] = Global.get_deck_as_string_keys()
	Global.selected_preset_idx = preset_idx
	Global.save_game()
	
	var preset_name = Global.deck_preset_names.get(str(preset_idx), "P%d" % preset_idx)
	DeskTheme.show_toast(self, "%s に現在の構成を保存しました！" % preset_name, 1.5, Color("#417505"))
	_update_highlights()
	preset_saved.emit(preset_idx)

func _rename_active_preset(new_name: String) -> void:
	var clean_name = new_name.strip_edges()
	if clean_name != "":
		var idx_str = str(Global.selected_preset_idx)
		Global.deck_preset_names[idx_str] = clean_name
		Global.save_game()
		DeskTheme.show_toast(self, "名前を「%s」に変更しました！" % clean_name, 1.2, Color("#4a90e2"))
		_update_highlights()

func _update_highlights() -> void:
	var active_name = Global.deck_preset_names.get(str(Global.selected_preset_idx), "P%d" % Global.selected_preset_idx)
	if _active_label:
		_active_label.text = "選択中: %s" % active_name
	if _name_edit and not _name_edit.has_focus():
		_name_edit.text = active_name
	
	for i in range(_preset_buttons.size()):
		var btn = _preset_buttons[i]
		var idx = i + 1
		var name_str = Global.deck_preset_names.get(str(idx), "P%d" % idx)
		btn.text = name_str
		
		# Calculate dynamic font size for long deck names (> 8 chars)
		var base_size = DeskTheme.FONT_SIZE_SMALL
		var font_size = base_size
		if name_str.length() > 8:
			font_size = clampi(int(float(base_size) * 8.0 / float(name_str.length())), 9, base_size)
		btn.add_theme_font_size_override("font_size", font_size)
		
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
			btn.add_theme_stylebox_override("hover", active_style)
			btn.add_theme_stylebox_override("pressed", active_style)
		else:
			Global.apply_white_button_style(btn)
