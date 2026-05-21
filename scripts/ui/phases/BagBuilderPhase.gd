# scripts/ui/phases/BagBuilderPhase.gd
class_name BagBuilderPhase
extends RefCounted

const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")

signal phase_completed()

var ctx: RefCounted

var ITEM_MASTER = [
	{ "type": Enums.ItemType.ERASER, "name": "消しゴム", "desc": "場のカード1枚を無効化\n(バースト数字: 2)", "number": 2, "color": Color("adb5bd") },
	{ "type": Enums.ItemType.ENERGY_DRINK, "name": "エナジードリンク", "desc": "次に引くバーストを1回防ぐ\n(バースト数字: 7)", "number": 7, "color": Color("fcc419") },
	{ "type": Enums.ItemType.WORD_BOOK, "name": "単語帳", "desc": "山札の上3枚を見て戻す\n(バースト数字: 4)", "number": 4, "color": Color("3bc9db") },
	{ "type": Enums.ItemType.RED_SHEET, "name": "赤シート", "desc": "次に引く通常カード得点2倍\n(バースト数字: 8)", "number": 8, "color": Color("ff6b6b") },
	{ "type": Enums.ItemType.THICK_BOOK, "name": "分厚い参考書", "desc": "強制的に2枚追加ドロー\n(バースト数字: 10)", "number": 10, "color": Color("845ef7") },
	{ "type": Enums.ItemType.STICKY_NOTE, "name": "付箋", "desc": "ストップ時ボーナス+30点\n(バースト数字: 1)", "number": 1, "color": Color("ffd43b") },
	{ "type": Enums.ItemType.CHEAT_SHEET, "name": "ズルいカンペ", "desc": "嘘の上限がさらに+50点\n(バースト数字: 5)", "number": 5, "color": Color("94d82d") }
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
	
	# アイテムをランダムに3つ選出
	var items_to_show = ITEM_MASTER.duplicate()
	items_to_show.shuffle()
	items_to_show = items_to_show.slice(0, 3)
	
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
	
	vbox.add_child(DeskTheme.create_label(item_data.name, 28, base_color.darkened(0.2), true))
	
	var desc_label = DeskTheme.create_label(item_data.desc, 14, DeskTheme.COLOR_MUTED, true)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)
	
	btn.pressed.connect(func():
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		
		# デッキにアイテムを追加
		if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
			ctx.game_session.deck.add_item_card(item_data.type, item_data.number)
		elif "player_deck" in ctx:
			ctx.player_deck.add_item_card(item_data.type, item_data.number)
		
		phase_completed.emit()
	)
	
	parent.add_child(btn)
