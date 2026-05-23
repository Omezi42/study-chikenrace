extends Control

var audio_manager = null
var slot_buttons: Dictionary = {}


func _ready():
	audio_manager = get_tree().root.get_node_or_null("AudioManager")

	DeskTheme.decorate_scene(self, 0.20)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 32)
	margin.add_child(vbox)

	vbox.add_child(DeskTheme.create_floating_badge("テスト勉強チキンレース デッキ構築", DeskTheme.COLOR_SAFE, 16))
	
	var title = DeskTheme.create_label("計画付箋の編成", 48, DeskTheme.COLOR_INK, true)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	vbox.add_child(title)

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)

	for i in range(1, 11):
		# 各枠の計画スロットを付箋（Sticky Note）風にしてビジュアル強化
		var current_item = Global.current_loadout.get(i, Enums.ItemType.STICKY_NOTE)
		var item_color = ItemLibrary.color(current_item)
		
		var slot_note = DeskTheme.create_sticky_note(item_color.lightened(0.72), Vector2(190, 160), randf_range(-2.0, 2.0))
		slot_note.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid.add_child(slot_note)
		
		var slot_vbox = VBoxContainer.new()
		slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_vbox.add_theme_constant_override("separation", 10)
		slot_note.add_child(slot_vbox)

		slot_vbox.add_child(DeskTheme.create_label("%d番枠 (数字%d)" % [i, i], 16, DeskTheme.COLOR_MUTED, true))

		var btn = DeskTheme.create_button(ItemLibrary.name(current_item), Vector2(160, 64), item_color, item_color.darkened(0.25), false, 18)
		slot_buttons[i] = btn
		btn.pressed.connect(func():
			if audio_manager:
				audio_manager.play_se("click")
			_show_item_select_popup(i, btn, slot_note)
		)

		slot_vbox.add_child(btn)

	var back_btn = DeskTheme.create_button("タイトルへ戻る", Vector2(300, 70), Color("bd4f4f"), Color("8a3939"), false, 24)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func():
		if audio_manager:
			audio_manager.play_se("click")
		SceneTransition.fade_to_scene("res://Title.tscn")
	)
	vbox.add_child(back_btn)

	DeskTheme.animate_entrance(margin)


func _show_item_select_popup(slot_num: int, update_btn: Button, slot_note: PanelContainer):
	var overlay = DeskTheme.create_dialog_overlay(self, "%d番枠に置くアイテムを選択" % slot_num, func(vbox: VBoxContainer):
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(900, 480)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		vbox.add_child(scroll)

		var grid = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 20)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		scroll.add_child(grid)

		for item_type in Global.unlocked_items:
			if item_type == Enums.ItemType.DELETE_CARD:
				continue
			var item_color = ItemLibrary.color(item_type)
			var item_btn = DeskTheme.create_button(ItemLibrary.name(item_type), Vector2(260, 80), item_color, item_color.darkened(0.25), false, 20)
			item_btn.pressed.connect(func():
				if audio_manager:
					audio_manager.play_se("click")
				Global.current_loadout[slot_num] = item_type
				Global.save_data()
				update_btn.text = ItemLibrary.name(item_type)
				
				# ボタン自体の色と付箋の色を動的変更！
				var new_style = update_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
				new_style.bg_color = item_color
				new_style.border_color = item_color.darkened(0.25)
				update_btn.add_theme_stylebox_override("normal", new_style)
				
				var note_style = slot_note.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
				note_style.bg_color = item_color.lightened(0.72)
				slot_note.add_theme_stylebox_override("panel", note_style)
				
				# ダイアログオーバーレイを閉じる
				var node = vbox
				while node and not node is ColorRect:
					node = node.get_parent()
				if node:
					node.queue_free()
			)
			grid.add_child(item_btn)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		vbox.add_child(spacer)

		var close_btn = DeskTheme.create_button("キャンセル", Vector2(240, 60), Color("bd4f4f"), Color("8a3939"), false, 22)
		close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		close_btn.pressed.connect(func():
			if audio_manager:
				audio_manager.play_se("click")
			var node = vbox
			while node and not node is ColorRect:
				node = node.get_parent()
			if node:
				node.queue_free()
		)
		vbox.add_child(close_btn)
	, Vector2(1100, 820))
