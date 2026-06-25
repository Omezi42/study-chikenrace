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
	
	# カード外枠スタイル（役割別の枠色）
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = DeskTheme.COLOR_CRAFT
	card_style.border_color = DeskTheme.COLOR_INK
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
