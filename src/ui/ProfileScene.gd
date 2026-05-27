class_name ProfileScene
extends Control

var notebook_panel: PanelContainer
var name_input: LineEdit
var confirm_btn: Button

func _ready() -> void:
	# Mahogany background
	var bg_color = ColorRect.new()
	bg_color.color = DeskTheme.COLOR_MAHOGANY
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	# Notebook spread container
	notebook_panel = PanelContainer.new()
	notebook_panel.custom_minimum_size = Vector2(800, 500)
	notebook_panel.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(notebook_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	notebook_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "生徒手帳の記帳"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var prompt = Label.new()
	prompt.text = "君の名前を教えてもらえるかな？\n（テスト報告の時に使用します）"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	vbox.add_child(prompt)
	
	# Input field
	name_input = LineEdit.new()
	name_input.placeholder_text = "名前を入力してください"
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.custom_minimum_size = Vector2(400, 60)
	name_input.max_length = 12
	name_input.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	name_input.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_input)
	
	# Confirm button
	confirm_btn = Button.new()
	confirm_btn.text = "これで記帳する"
	confirm_btn.custom_minimum_size = Vector2(260, 65)
	confirm_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	confirm_btn.add_theme_font_size_override("font_size", 22)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	vbox.add_child(confirm_btn)
	
	# Entrance slide in from bottom
	var target_pos = Vector2((1920 - 800) / 2.0, (1080 - 500) / 2.0)
	DeskTheme.animate_entrance(notebook_panel, target_pos, Vector2(0, 300), 0.5)

func _on_confirm_pressed() -> void:
	var player_name_val = name_input.text.strip_edges()
	if player_name_val == "":
		player_name_val = "あなた"
		
	DeskTheme.animate_click(confirm_btn, Vector2.ONE, 0.08)
	
	Global.player_name = player_name_val
	Global.save_game()
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
	)
