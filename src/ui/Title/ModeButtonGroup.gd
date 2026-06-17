class_name ModeButtonGroup
extends HBoxContainer

signal exam_pressed
signal friend_pressed
signal random_pressed

var exam_btn: Button
var friend_btn: Button
var random_btn: Button

func _ready() -> void:
	add_theme_constant_override("separation", 15)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 模試ボタン (青の付箋)
	exam_btn = _create_sticky_button("模試", "res://assets/icons/book.svg", Color("e3f2fd"), Color("90caf9"))
	exam_btn.pressed.connect(func(): exam_pressed.emit())
	add_child(exam_btn)
	
	# フレンド戦ボタン (緑の付箋)
	friend_btn = _create_sticky_button("フレンド戦", "res://assets/icons/users.svg", Color("e8f5e9"), Color("a5d6a7"))
	friend_btn.pressed.connect(func(): friend_pressed.emit())
	add_child(friend_btn)
	
	# ランダムマッチボタン (オレンジの付箋)
	random_btn = _create_sticky_button("ランダム戦", "res://assets/icons/globe.svg", Color("fff3e0"), Color("ffcc80"))
	random_btn.pressed.connect(func(): random_pressed.emit())
	add_child(random_btn)

func _create_sticky_button(text: String, icon_path: String, bg_color: Color, border_color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 110)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_override("font", DeskTheme.get_font())
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	
	# アイコン設定
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	
	# 付箋のスタイル
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = bg_color
	normal_style.border_width_bottom = 4
	normal_style.border_color = border_color
	normal_style.content_margin_top = 45 # テキストを下部に寄せるため
	normal_style.content_margin_bottom = 10
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.05)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.border_width_bottom = 1
	pressed_style.content_margin_top = 48
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# ホバー・クリック時のバウンスアニメーション接続
	btn.mouse_entered.connect(func():
		DeskTheme.animate_hover(btn, true)
	)
	btn.mouse_exited.connect(func():
		DeskTheme.animate_hover(btn, false)
	)
	btn.pressed.connect(func():
		btn.release_focus()
		DeskTheme.animate_click(btn)
	)
	
	# pivotを設定してアニメーションの中心をボタンの中央にする
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	
	return btn
