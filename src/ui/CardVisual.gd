class_name CardVisual
extends Button

## カード1枚のUI表示を担う再利用可能なコンポーネント。
## ChickenRacePhase から create_card_visual() の生コードを分離し、
## UIレイアウトの保守性を大幅に向上させる。
## 
## 使用例:
##   var card_ui = CardVisual.new(card_data)
##   hand_container.add_child(card_ui)

var card_data: Dictionary = {}

## カードデータを渡してインスタンスを初期化する
static func create(p_card: Dictionary) -> CardVisual:
	var instance = CardVisual.new()
	instance.card_data = p_card
	instance._build_ui()
	return instance

func _build_ui() -> void:
	custom_minimum_size = Vector2(160, 220)
	pivot_offset = Vector2(80, 110)
	
	var item_id: String = card_data.get("item_id", "")
	var item_info: Dictionary = CardData.ITEMS.get(item_id, {"role": CardData.ROLE_PREP, "name": card_data.get("name", "アイテム")})
	
	# カード外枠スタイル（役割別の枠色）
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = DeskTheme.COLOR_CRAFT
	card_style.border_color = CardData.get_role_color(item_info.get("role", CardData.ROLE_PREP))
	card_style.border_width_left = 3
	card_style.border_width_right = 3
	card_style.border_width_top = 3
	card_style.border_width_bottom = 8 # Thick bottom border for shadow/depth
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.shadow_color = Color(0, 0, 0, 0.15)
	card_style.shadow_size = 5
	card_style.shadow_offset = Vector2(2, 4)
	
	var card_hover = card_style.duplicate() as StyleBoxFlat
	card_hover.shadow_size = 8
	card_hover.shadow_offset = Vector2(4, 6)
	card_hover.bg_color = DeskTheme.COLOR_CRAFT.lightened(0.02)
	
	var card_pressed = card_style.duplicate() as StyleBoxFlat
	card_pressed.border_width_bottom = 3
	card_pressed.shadow_size = 1
	card_pressed.shadow_offset = Vector2(1, 1)
	
	add_theme_stylebox_override("normal", card_style)
	add_theme_stylebox_override("hover", card_hover)
	add_theme_stylebox_override("pressed", card_pressed)
	add_theme_stylebox_override("focus", card_style)
	
	var card_vbox = VBoxContainer.new()
	card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_theme_constant_override("separation", 6)
	add_child(card_vbox)
	
	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_top", 14)
	card_vbox.add_child(top_margin)
	
	# 点数（大きく中央に表示）
	var val_label = Label.new()
	val_label.text = str(card_data.get("value", 0))
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_label.add_theme_font_override("font", DeskTheme.get_font())
	val_label.add_theme_font_size_override("font_size", 44)
	val_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	card_vbox.add_child(val_label)
	
	# アイテム画像
	var img_path = CardData.get_item_image_path(item_id)
	if img_path != "":
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(img_path)
		tex_rect.custom_minimum_size = Vector2(80, 80)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_vbox.add_child(tex_rect)
	else:
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(80, 20)
		card_vbox.add_child(spacer)
	
	# アイテム名
	var name_lbl = Label.new()
	name_lbl.text = item_info.get("name", "カード")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	card_vbox.add_child(name_lbl)
	
	# 効果の短い説明
	var short_eff = CardData.get_item_short_effect(item_id)
	if short_eff != "":
		var effect_lbl = Label.new()
		effect_lbl.text = "【" + short_eff + "】"
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_lbl.add_theme_font_override("font", DeskTheme.get_font())
		effect_lbl.add_theme_font_size_override("font_size", 10)
		var role = item_info.get("role", CardData.ROLE_PREP)
		var eff_color = Color("ff4081") if role == CardData.ROLE_PUSH else Color(DeskTheme.COLOR_INK, 0.6)
		effect_lbl.add_theme_color_override("font_color", eff_color)
		card_vbox.add_child(effect_lbl)

	# 共通ホバーアニメーションの接続（自習画面の扇状配置以外で有効）
	mouse_entered.connect(func():
		if not has_meta("fan_position"):
			DeskTheme.animate_hover(self, true, Vector2.ONE, 0.15)
	)
	mouse_exited.connect(func():
		if not has_meta("fan_position"):
			DeskTheme.animate_hover(self, false, Vector2.ONE, 0.15)
	)


## カードUIのVBoxを返す（アニメーション時に可視性を制御するため）
func get_vbox() -> VBoxContainer:
	for c in get_children():
		if c is VBoxContainer:
			return c
	return null
