# scripts/ui/phases/BagBuilderPhase.gd
class_name BagBuilderPhase
extends RefCounted

const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")
const GameBalanceScript = preload("res://scripts/core/GameBalance.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")

signal phase_completed()

var ctx: RefCounted

var ITEM_MASTER = [
	{ "type": Enums.ItemType.ERASER, "name": "消しゴム", "desc": "場のカード1枚を無効化", "color": Color("adb5bd") },
	{ "type": Enums.ItemType.RULER, "name": "定規", "desc": "ストップ時に+%d点ボーナス" % GameBalanceScript.STOP_BONUS_RULER, "color": Color("4dabf7") },
	{ "type": Enums.ItemType.WORD_BOOK, "name": "単語帳", "desc": "山札の上3枚を見て危険カードを下へ", "color": Color("3bc9db") },
	{ "type": Enums.ItemType.CHEAT_SHEET, "name": "ズルいカンペ", "desc": "嘘の上限+%d点" % GameBalanceScript.BLUFF_CAP_PER_CHEAT_SHEET, "color": Color("94d82d") },
	{ "type": Enums.ItemType.COMPASS, "name": "コンパス", "desc": "引いたとき枠の数字分が得点", "color": Color("748ffc") },
	{ "type": Enums.ItemType.ENERGY_DRINK, "name": "エナジードリンク", "desc": "次のバーストを1回防ぐ", "color": Color("fcc419") },
	{ "type": Enums.ItemType.RED_SHEET, "name": "赤シート", "desc": "次に引くカードの得点2倍", "color": Color("ff6b6b") },
	{ "type": Enums.ItemType.MECHANICAL_PENCIL, "name": "シャーペン", "desc": "引いたとき枠の数字分が得点", "color": Color("868e96") },
	{ "type": Enums.ItemType.THICK_BOOK, "name": "分厚い参考書", "desc": "引いたあと強制2枚ドロー", "color": Color("845ef7") },
	{ "type": Enums.ItemType.STICKY_NOTE, "name": "付箋", "desc": "ストップ時に+%d点ボーナス" % GameBalanceScript.STOP_BONUS_STICKY_NOTE, "color": Color("ffd43b") },
	{ "type": Enums.ItemType.DELETE_CARD, "name": "忘却のノート", "desc": "山札から1枚選んで削除（デッキ整理）", "number": -1, "color": Color("495057") }
]

func _init(context: RefCounted):
	self.ctx = context

func start():
	_show_item_selection()

func _show_item_selection():
	# 以前のUI要素をクリア
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
	
	# ---- Left Page ----
	var left_v = VBoxContainer.new()
	left_v.alignment = BoxContainer.ALIGNMENT_CENTER
	left_v.add_theme_constant_override("separation", 24)
	left_margin.add_child(left_v)
	
	var current_day = Global.play_count + 1
	var current_hour = 1
	if is_instance_valid(ctx) and ctx.game_session:
		current_hour = ctx.game_session.current_hour
		
	var title = DeskTheme.create_label("Day %d - %d時間目" % [current_day, current_hour], 38, DeskTheme.COLOR_INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_v.add_child(title)
	left_v.add_child(DeskTheme.create_label("デッキに追加するアイテムを選んでね！", 20, DeskTheme.COLOR_MUTED, true))
	
	# ---- Right Page ----
	var right_v = VBoxContainer.new()
	right_v.alignment = BoxContainer.ALIGNMENT_CENTER
	right_v.add_theme_constant_override("separation", 24)
	right_margin.add_child(right_v)
	
	# アイテムをランダムに3つ選出（5, 6時間目は DELETE_CARD を必ず1つ入れる。他は出さない）
	var items_to_show = []
	var pool = []
	for item in ITEM_MASTER:
		if item.type != Enums.ItemType.DELETE_CARD:
			pool.append(item)
			
	pool.shuffle()
	
	if current_hour == 3:
		items_to_show.append(ITEM_MASTER[ITEM_MASTER.size() - 1]) # DELETE_CARD
		items_to_show.append_array(pool.slice(0, 2))
	else:
		items_to_show = pool.slice(0, 3)
		
	items_to_show.shuffle() # 表示順をランダム化
	
	for item_data in items_to_show:
		_create_item_button(right_v, item_data)
	
	DeskTheme.animate_entrance(note_panel)

func _create_item_button(parent: Control, item_data: Dictionary):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(300, 100)
	var style = StyleBoxFlat.new()
	var base_color = item_data.color
	style.bg_color = base_color.lightened(0.8)
	style.border_color = base_color
	style.border_width_bottom = 4
	style.border_width_left = 2; style.border_width_right = 2; style.border_width_top = 2
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	btn.add_child(vbox)
	
	var slot_num = GameBalanceScript.loadout_number_for_item(item_data.type) if item_data.type != Enums.ItemType.DELETE_CARD else -1
	var title_text = item_data.name if slot_num < 0 else "%s（数字:%d）" % [item_data.name, slot_num]
	vbox.add_child(DeskTheme.create_label(title_text, 28, base_color.darkened(0.2), true))
	
	var desc_label = DeskTheme.create_label(item_data.desc, 14, DeskTheme.COLOR_MUTED, true)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)
	
	btn.pressed.connect(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		
		if item_data.type == Enums.ItemType.DELETE_CARD:
			Global.increment_item_usage(Enums.ItemType.DELETE_CARD)
			_show_delete_card_dialog()
		else:
			# 通常のアイテム追加
			if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
				ctx.game_session.deck.add_item_card(item_data.type)
			elif "player_deck" in ctx:
				ctx.player_deck.add_item_card(item_data.type)
			
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
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(600, 400)
	panel.anchor_left = 0.5; panel.anchor_top = 0.5; panel.anchor_right = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -300; panel.offset_top = -200; panel.offset_right = 300; panel.offset_bottom = 200
	overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	DeskTheme.apply_font(vbox)
	panel.add_child(vbox)
	
	var title = DeskTheme.create_label("忘却のノート — デッキを1枚整理", 24, DeskTheme.COLOR_INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(DeskTheme.create_label("同じ数字が2枚以上あるとバースト危険！\n消したい組み合わせをタップ", 14, DeskTheme.COLOR_MUTED, true))
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.add_child(grid)
	
	# デッキ内のユニークなカード・アイテムを収集（枚数つき）
	var unique_cards = []
	var number_counts: Dictionary = {}
	if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
		var deck_obj = ctx.game_session.deck
		var all_cards = []
		all_cards.append_array(deck_obj.deck)
		all_cards.append_array(deck_obj.used_cards)
		for c in all_cards:
			number_counts[c.number] = number_counts.get(c.number, 0) + 1
		
		for c in all_cards:
			var key = str(c.item_type) + "_" + str(c.number)
			var found = false
			for u in unique_cards:
				if u.key == key:
					found = true
					u.count += 1
					break
			if not found:
				unique_cards.append({"key": key, "type": c.item_type, "number": c.number, "count": 1})
	
	unique_cards.sort_custom(func(a, b):
		return a.number < b.number
	)
	
	for card_info in unique_cards:
		var c_type = card_info.type
		var c_num = card_info.number
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 60)
		var btn_style = StyleBoxFlat.new()
		
		var display_text = ""
		var item_name = "アイテム"
		var base_color = Color("e9ecef")
		for master in ITEM_MASTER:
			if master.type == c_type:
				item_name = master.name
				base_color = master.color
				break
		btn_style.bg_color = base_color.lightened(0.6)
		btn_style.border_color = base_color
		btn_style.border_width_bottom = 2
		var cnt = card_info.get("count", 1)
		var dup_total = number_counts.get(c_num, cnt)
		display_text = "%s [%d]" % [item_name, c_num]
		if cnt > 1:
			display_text += " x%d" % cnt
		if dup_total >= 2:
			btn_style.bg_color = Color("ffe3e3")
			btn_style.border_color = DeskTheme.COLOR_BLUFF_RED
			
		btn_style.corner_radius_top_left = 8; btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8; btn_style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.text = display_text
		btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		
		btn.pressed.connect(func():
			if ctx.audio_manager: ctx.audio_manager.play_se("click")
			if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
				ctx.game_session.deck.remove_target_card(c_type, c_num)
			overlay.queue_free()
			if is_instance_valid(ctx.ui_root):
				ToastOverlayScript.show_toast(ctx.ui_root, "数字%dのカードを1枚整理した！" % c_num, DeskTheme.COLOR_SAFE)
			phase_completed.emit()
		)
		grid.add_child(btn)
	
	var cancel_btn = DeskTheme.create_button("やめる", Vector2(160, 44), Color("868e96"), Color("495057"))
	cancel_btn.pressed.connect(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		overlay.queue_free()
	)
	vbox.add_child(cancel_btn)
