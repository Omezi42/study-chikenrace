class_name BagBuilderPhase
extends RefCounted

const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")

signal phase_completed()

var ctx: RefCounted


func _init(context: RefCounted):
	self.ctx = context


func start():
	_show_item_selection()


func _show_item_selection():
	for child in ctx.screen_content.get_children():
		child.queue_free()

	SmartphoneBuilderScript.build_standard_smartphone(ctx)

	var note_panel = NotebookBuilderScript.create()
	ctx.active_notebook = note_panel
	note_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note_panel.offset_left = 420.0
	note_panel.offset_top = 80.0
	note_panel.offset_right = -120.0
	note_panel.offset_bottom = -80.0
	ctx.screen_content.add_child(note_panel)

	var left_margin = note_panel.find_child("LeftContent", true, false) as MarginContainer
	var right_margin = note_panel.find_child("RightContent", true, false) as MarginContainer

	var left_v = VBoxContainer.new()
	left_v.alignment = BoxContainer.ALIGNMENT_CENTER
	left_v.add_theme_constant_override("separation", 24)
	left_margin.add_child(left_v)

	var current_day = Global.play_count + 1
	var current_hour = ctx.game_session.current_hour if is_instance_valid(ctx) and ctx.game_session else 1
	left_v.add_child(DeskTheme.create_label("Day %d - %d時限目" % [current_day, current_hour], 38, DeskTheme.COLOR_INK, true))
	left_v.add_child(DeskTheme.create_label("この時限に混ぜる文房具を1つ選びます", 20, DeskTheme.COLOR_MUTED, true))

	var right_v = VBoxContainer.new()
	right_v.alignment = BoxContainer.ALIGNMENT_CENTER
	right_v.add_theme_constant_override("separation", 24)
	right_margin.add_child(right_v)

	for item_type in _items_to_offer(current_day, current_hour):
		_create_item_button(right_v, item_type)

	DeskTheme.animate_entrance(note_panel)


func _items_to_offer(current_day: int, current_hour: int) -> Array:
	var pool = ItemLibrary.STARTER_POOL.duplicate()
	if current_day >= 2 or current_hour >= 2:
		pool.append_array(ItemLibrary.ADVANCED_POOL)
	pool.shuffle()

	var items_to_show: Array = []
	if current_hour == 3:
		items_to_show.append(Enums.ItemType.DELETE_CARD)
		for item_type in pool:
			if items_to_show.size() >= 3:
				break
			if item_type == Enums.ItemType.DELETE_CARD:
				continue
			items_to_show.append(item_type)
	else:
		for item_type in pool:
			if items_to_show.size() >= 3:
				break
			if item_type == Enums.ItemType.DELETE_CARD:
				continue
			items_to_show.append(item_type)
	return items_to_show


func _create_item_button(parent: Control, item_type: int):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(320, 110)

	var style = StyleBoxFlat.new()
	var base_color = ItemLibrary.color(item_type)
	style.bg_color = base_color.lightened(0.8)
	style.border_color = base_color
	style.border_width_bottom = 4
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	btn.add_child(vbox)

	var slot_num = GameBalance.loadout_number_for_item(item_type) if item_type != Enums.ItemType.DELETE_CARD else -1
	var title_text = ItemLibrary.name(item_type) if slot_num < 0 else "%s [数字 %d]" % [ItemLibrary.name(item_type), slot_num]
	vbox.add_child(DeskTheme.create_label(title_text, 24, base_color.darkened(0.2), true))

	var desc_label = DeskTheme.create_label(ItemLibrary.description(item_type), 14, DeskTheme.COLOR_MUTED, true)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	btn.pressed.connect(func():
		if ctx.audio_manager:
			ctx.audio_manager.play_se("click")
		if item_type == Enums.ItemType.DELETE_CARD:
			Global.increment_item_usage(Enums.ItemType.DELETE_CARD)
			_show_delete_card_dialog()
			return
		if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
			ctx.game_session.deck.add_item_card(item_type)
		phase_completed.emit()
	)

	parent.add_child(btn)


func _show_delete_card_dialog():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctx.screen_content.add_child(overlay)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("faf8f5")
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(680, 440)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -340
	panel.offset_top = -220
	panel.offset_right = 340
	panel.offset_bottom = 220
	overlay.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	DeskTheme.apply_font(vbox)
	panel.add_child(vbox)

	vbox.add_child(DeskTheme.create_label("忘却のノート", 24, DeskTheme.COLOR_INK, true))
	vbox.add_child(DeskTheme.create_label("山札か捨て札から1枚だけ削除します", 14, DeskTheme.COLOR_MUTED, true))

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.add_child(grid)

	var unique_cards = []
	var seen := {}
	if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
		var deck_obj = ctx.game_session.deck
		var all_cards = []
		all_cards.append_array(deck_obj.deck)
		all_cards.append_array(deck_obj.used_cards)
		for c in all_cards:
			var key = "%d_%d" % [c.item_type, c.number]
			if seen.get(key, false):
				continue
			seen[key] = true
			unique_cards.append({"type": c.item_type, "number": c.number})

	unique_cards.sort_custom(func(a, b): return a.number < b.number)

	for card_info in unique_cards:
		var c_type = card_info.type
		var c_num = card_info.number
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 60)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = ItemLibrary.color(c_type).lightened(0.6)
		btn_style.border_color = ItemLibrary.color(c_type)
		btn_style.border_width_bottom = 2
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.text = "%s [%d]" % [ItemLibrary.name(c_type), c_num]
		btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		btn.pressed.connect(func():
			if ctx.audio_manager:
				ctx.audio_manager.play_se("click")
			if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
				ctx.game_session.deck.remove_target_card(c_type, c_num)
			overlay.queue_free()
			ToastOverlayScript.show_toast(ctx.ui_root, "数字%dのカードを削除" % c_num, DeskTheme.COLOR_SAFE)
			phase_completed.emit()
		)
		grid.add_child(btn)

	var cancel_btn = DeskTheme.create_button("やめる", Vector2(160, 44), Color("868e96"), Color("495057"))
	cancel_btn.pressed.connect(func():
		if ctx.audio_manager:
			ctx.audio_manager.play_se("click")
		overlay.queue_free()
	)
	vbox.add_child(cancel_btn)
