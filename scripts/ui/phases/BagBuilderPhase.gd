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

	var note_panel: Control = NotebookBuilderScript.create()
	ctx.active_notebook = note_panel
	note_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note_panel.offset_left = 420.0
	note_panel.offset_top = 80.0
	note_panel.offset_right = -120.0
	note_panel.offset_bottom = -80.0
	ctx.screen_content.add_child(note_panel)

	var left_margin: MarginContainer = note_panel.find_child("LeftContent", true, false) as MarginContainer
	var right_margin: MarginContainer = note_panel.find_child("RightContent", true, false) as MarginContainer

	# 左ページ：タイトルと説明
	var left_v: VBoxContainer = VBoxContainer.new()
	left_v.alignment = BoxContainer.ALIGNMENT_CENTER
	left_v.add_theme_constant_override("separation", 24)
	left_margin.add_child(left_v)

	var current_day: int = Global.play_count + 1
	var current_hour: int = ctx.game_session.current_hour if is_instance_valid(ctx) and ctx.game_session else 1
	
	left_v.add_child(DeskTheme.create_label("Day %d" % current_day, 24, DeskTheme.COLOR_MUTED, true))
	left_v.add_child(DeskTheme.create_label("%d時限目の計画" % current_hour, 42, DeskTheme.COLOR_INK, true))
	
	# 手書きの装飾ディバイダー（ノート風）
	var div: Panel = Panel.new()
	div.custom_minimum_size = Vector2(0, 3)
	var div_style: StyleBoxFlat = StyleBoxFlat.new()
	div_style.bg_color = DeskTheme.COLOR_MUTED
	div.add_theme_stylebox_override("panel", div_style)
	left_v.add_child(div)
	
	left_v.add_child(DeskTheme.create_label("今回の時間割に混ぜる文房具を\n1つ選んでノートに挟んでください。", 20, DeskTheme.COLOR_INK, true))

	# 右ページ：アイテムカード3枚 ＆ 付箋説明パネル
	var right_v: VBoxContainer = VBoxContainer.new()
	right_v.alignment = BoxContainer.ALIGNMENT_CENTER
	right_v.add_theme_constant_override("separation", 32)
	right_margin.add_child(right_v)

	var cards_hbox: HBoxContainer = HBoxContainer.new()
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_hbox.add_theme_constant_override("separation", 20)
	right_v.add_child(cards_hbox)

	# 説明付箋
	var desc_sticky: PanelContainer = DeskTheme.create_sticky_note(Color("fffae6"), Vector2(560, 160), 1.5)
	right_v.add_child(desc_sticky)

	var desc_margin: MarginContainer = MarginContainer.new()
	desc_margin.add_theme_constant_override("margin_left", 24)
	desc_margin.add_theme_constant_override("margin_right", 24)
	desc_margin.add_theme_constant_override("margin_top", 16)
	desc_margin.add_theme_constant_override("margin_bottom", 16)
	desc_sticky.add_child(desc_margin)

	var desc_vbox: VBoxContainer = VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 6)
	desc_margin.add_child(desc_vbox)

	var desc_title: Label = DeskTheme.create_label("文房具を選んでください", 22, DeskTheme.COLOR_INK)
	desc_vbox.add_child(desc_title)

	var desc_detail: Label = DeskTheme.create_label("カードにカーソルを合わせると、その効果とスロット番号がここに表示されます。", 15, DeskTheme.COLOR_MUTED)
	desc_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_vbox.add_child(desc_detail)

	# カード生成
	var items: Array = _items_to_offer(current_day, current_hour)
	for i in range(items.size()):
		var item_type: int = items[i]
		var card: Control = _create_item_card(item_type, desc_title, desc_detail, desc_sticky)
		cards_hbox.add_child(card)
		
		# 少しランダムに傾けてリアルな「机に散らばったカード」感を出す
		card.rotation_degrees = randf_range(-3.0, 3.0)

	DeskTheme.animate_entrance(note_panel)


func _items_to_offer(current_day: int, current_hour: int) -> Array:
	var pool: Array = ItemLibrary.STARTER_POOL.duplicate()
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


func _create_item_card(item_type: int, desc_title: Label, desc_detail: Label, desc_sticky: PanelContainer) -> Control:
	var slot_num: int = GameBalance.loadout_number_for_item(item_type) if item_type != Enums.ItemType.DELETE_CARD else -1
	var card: Control = DeskTheme.create_item_card_large(item_type, slot_num)
	
	# カードサイズを少しスケールダウンして3枚収まりやすくする
	card.scale = Vector2(0.85, 0.85)
	card.custom_minimum_size = Vector2(190, 260) * 0.85
	card.pivot_offset = Vector2(190, 260) / 2.0
	
	# クリック用透過オーバーレイボタン
	var click_btn: Button = Button.new()
	click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	click_btn.add_theme_stylebox_override("normal", empty_style)
	click_btn.add_theme_stylebox_override("hover", empty_style)
	click_btn.add_theme_stylebox_override("pressed", empty_style)
	click_btn.add_theme_stylebox_override("focus", empty_style)
	card.add_child(click_btn)
	
	var base_color: Color = ItemLibrary.color(item_type)
	var title_text: String = ItemLibrary.name(item_type)
	
	# ホバー時に付箋説明を更新する処理
	card.mouse_entered.connect(func():
		desc_title.text = title_text if slot_num < 0 else "%s [スロット %d]" % [title_text, slot_num]
		desc_title.add_theme_color_override("font_color", base_color.darkened(0.2))
		desc_detail.text = ItemLibrary.description(item_type)
		
		# 付箋の背景色をアイテムカラーベースで変化させる
		var style: StyleBoxFlat = desc_sticky.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.bg_color = base_color.lightened(0.82)
		style.border_width_left = 6
		style.border_color = base_color
		desc_sticky.add_theme_stylebox_override("panel", style)
	)
	
	click_btn.pressed.connect(func():
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
	
	return card


func _show_delete_card_dialog():
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctx.screen_content.add_child(overlay)

	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
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

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	DeskTheme.apply_font(vbox)
	panel.add_child(vbox)

	vbox.add_child(DeskTheme.create_label("忘却のノート", 24, DeskTheme.COLOR_INK, true))
	vbox.add_child(DeskTheme.create_label("山札か捨て札から1枚だけ削除します", 14, DeskTheme.COLOR_MUTED, true))

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.add_child(grid)

	var unique_cards: Array = []
	var seen: Dictionary = {}
	if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
		var deck_obj: RefCounted = ctx.game_session.deck
		var all_cards: Array = []
		all_cards.append_array(deck_obj.deck)
		all_cards.append_array(deck_obj.used_cards)
		for c in all_cards:
			var key: String = "%d_%d" % [c.item_type, c.number]
			if seen.get(key, false):
				continue
			seen[key] = true
			unique_cards.append({"type": c.item_type, "number": c.number})

	unique_cards.sort_custom(func(a, b): return a.number < b.number)

	for card_info in unique_cards:
		var c_type: int = card_info.type
		var c_num: int = card_info.number
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(130, 60)
		var btn_style: StyleBoxFlat = StyleBoxFlat.new()
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
		btn.pressed.connect((func(t: int, n: int):
			if ctx.audio_manager:
				ctx.audio_manager.play_se("click")
			if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
				ctx.game_session.deck.remove_target_card(t, n)
			overlay.queue_free()
			ToastOverlayScript.show_toast(ctx.ui_root, "数字%dのカードを削除" % n, DeskTheme.COLOR_SAFE)
			phase_completed.emit()
		).bind(c_type, c_num))
		grid.add_child(btn)

	var cancel_btn: Button = DeskTheme.create_button("やめる", Vector2(160, 44), Color("868e96"), Color("495057"))
	cancel_btn.pressed.connect(func():
		if ctx.audio_manager:
			ctx.audio_manager.play_se("click")
		overlay.queue_free()
	)
	vbox.add_child(cancel_btn)
