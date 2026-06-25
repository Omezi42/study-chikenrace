class_name PlayerIdCard
extends PanelContainer

signal profile_pressed

var name_lbl: Label
var title_lbl: Label

var coin_lbl: Label
var profile_btn: Button
var parent_scene: Node

func _ready() -> void:
	# カード型パネルのスタイル
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = Color("faf6f0")
	info_style.border_width_left = 6
	info_style.border_color = Color("3a6b5c") # Sage green
	info_style.content_margin_left = 23
	info_style.content_margin_right = 23
	info_style.content_margin_top = 15
	info_style.content_margin_bottom = 15
	add_theme_stylebox_override("panel", info_style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	add_child(main_vbox)
	
	# 学生証ヘッダー (ステッカー風)
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	
	var card_title = Label.new()
	card_title.text = "学生証"
	card_title.add_theme_font_override("font", DeskTheme.get_font())
	card_title.add_theme_font_size_override("font_size", 28)
	card_title.add_theme_color_override("font_color", Color("3a6b5c"))
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(card_title)
	
	# 称号
	title_lbl = Label.new()
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color("795548"))
	main_vbox.add_child(title_lbl)
	
	# ユーザー名
	name_lbl = Label.new()
	name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	main_vbox.add_child(name_lbl)
	
	# 偏差値表示

	
	# プロフィール/ログインボタン
	profile_btn = Button.new()
	profile_btn.custom_minimum_size = Vector2(0, 48)
	profile_btn.add_theme_font_override("font", DeskTheme.get_font())
	profile_btn.add_theme_font_size_override("font_size", 20)
	Global.apply_white_button_style(profile_btn)
	if ResourceLoader.exists("res://assets/icons/user.svg"):
		profile_btn.icon = load("res://assets/icons/user.svg")
		profile_btn.expand_icon = true
	profile_btn.pressed.connect(func():
		profile_btn.release_focus()
		DeskTheme.animate_click(profile_btn, Vector2.ONE, 0.08)
		profile_pressed.emit()
	)
	main_vbox.add_child(profile_btn)

func update_data(player_name: String, player_title: String, logged_in: bool) -> void:
	name_lbl.text = player_name
	title_lbl.text = "称号: " + player_title
	
	if logged_in:
		profile_btn.text = " プロフィール詳細"
	else:
		profile_btn.text = " ログイン / 新規登録"
