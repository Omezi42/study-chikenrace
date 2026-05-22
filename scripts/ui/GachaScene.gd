class_name GachaScene
extends Control

const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")

var coins_label: Label
var result_label: Label
var gacha_btn: Button
var back_btn: Button
var _is_rolling: bool = false


func _ready():
	DeskTheme.decorate_scene(self, 0.24)
	
	var ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)
	
	var page = DeskTheme.create_notebook_panel(Vector2(600, 500), 40, 40, 40, 40)
	page.anchor_left = 0.5
	page.anchor_top = 0.5
	page.anchor_right = 0.5
	page.anchor_bottom = 0.5
	page.offset_left = -300
	page.offset_top = -250
	page.offset_right = 300
	page.offset_bottom = 250
	ui_root.add_child(page)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	DeskTheme.apply_font(vbox)
	page.get_node("Content").add_child(vbox)
	
	var title = DeskTheme.create_label("購買部 (ガチャ)", 36, DeskTheme.COLOR_INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	coins_label = DeskTheme.create_label("所持コイン: %d枚" % Global.coins, 24, Color("e67700"), true)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(coins_label)
	
	gacha_btn = DeskTheme.create_button("ガチャを引く (100コイン)", Vector2(300, 60), DeskTheme.COLOR_ACCENT_GOLD, Color("b38f30"))
	gacha_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gacha_btn.pressed.connect(_on_gacha_pressed)
	vbox.add_child(gacha_btn)
	
	result_label = DeskTheme.create_label("新しい文房具を手に入れよう！", 20, DeskTheme.COLOR_SAFE, true)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.custom_minimum_size = Vector2(500, 60)
	vbox.add_child(result_label)
	
	back_btn = DeskTheme.create_button("タイトルへ戻る", Vector2(250, 50), DeskTheme.COLOR_MUTED, Color("666666"))
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://Title.tscn")
	)
	vbox.add_child(back_btn)
	
	DeskTheme.animate_entrance(page)

func _on_gacha_pressed():
	if _is_rolling:
		return
	if Global.coins < 100:
		ToastOverlayScript.show_toast(self, "コインが足りません！", DeskTheme.COLOR_BLUFF_RED)
		return
		
	_is_rolling = true
	gacha_btn.disabled = true
	back_btn.disabled = true
	
	Global.coins -= 100
	coins_label.text = "所持コイン: %d枚" % Global.coins
	
	var pool = [
		Enums.ItemType.STICKY_NOTE, Enums.ItemType.ERASER, Enums.ItemType.RULER,
		Enums.ItemType.WORD_BOOK, Enums.ItemType.CHEAT_SHEET, Enums.ItemType.COMPASS,
		Enums.ItemType.ENERGY_DRINK, Enums.ItemType.RED_SHEET, Enums.ItemType.MECHANICAL_PENCIL,
		Enums.ItemType.THICK_BOOK, Enums.ItemType.DELETE_CARD
	]
	
	# ドラムロール演出
	var roll_count = 20
	var delay = 0.05
	for i in range(roll_count):
		var temp_item = pool[randi() % pool.size()]
		result_label.text = "【開封中...】 %s" % _get_item_name(temp_item)
		result_label.add_theme_color_override("font_color", Color("868e96"))
		await get_tree().create_timer(delay).timeout
		
	var item = pool[randi() % pool.size()]
	var item_name = _get_item_name(item)
	
	if not Global.unlocked_items.has(item):
		Global.unlocked_items.append(item)
		Global.item_levels[item] = 1
		result_label.text = "【新規獲得】 %s を手に入れた！" % item_name
		result_label.add_theme_color_override("font_color", DeskTheme.COLOR_ACCENT_GOLD)
		ToastOverlayScript.show_toast(self, "新しい文房具をゲット！", DeskTheme.COLOR_SAFE)
	else:
		if not Global.item_levels.has(item):
			Global.item_levels[item] = 1
		Global.item_levels[item] += 1
		var new_level = Global.item_levels[item]
		result_label.text = "【レベルアップ】 %s がLv.%dになった！" % [item_name, new_level]
		result_label.add_theme_color_override("font_color", DeskTheme.COLOR_SAFE)
		ToastOverlayScript.show_toast(self, "文房具が強化された！", DeskTheme.COLOR_SAFE)
		
	Global.save_data()
	
	_is_rolling = false
	gacha_btn.disabled = false
	back_btn.disabled = false

func _get_item_name(item_type: int) -> String:
	match item_type:
		Enums.ItemType.STICKY_NOTE: return "付箋"
		Enums.ItemType.ERASER: return "消しゴム"
		Enums.ItemType.RULER: return "定規"
		Enums.ItemType.WORD_BOOK: return "単語帳"
		Enums.ItemType.CHEAT_SHEET: return "ズルカンペ"
		Enums.ItemType.COMPASS: return "コンパス"
		Enums.ItemType.ENERGY_DRINK: return "エナジードリンク"
		Enums.ItemType.RED_SHEET: return "赤シート"
		Enums.ItemType.MECHANICAL_PENCIL: return "シャーペン"
		Enums.ItemType.THICK_BOOK: return "分厚い参考書"
		Enums.ItemType.DELETE_CARD: return "忘却のノート"
	return "謎のアイテム"
