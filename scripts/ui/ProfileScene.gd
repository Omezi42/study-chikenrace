class_name ProfileScene
extends Control

const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")

func _ready():
	DeskTheme.decorate_scene(self, 0.16)
	var page = DeskTheme.create_notebook_panel(Vector2(620, 420), 80, 62, 80, 50)
	page.anchor_left = 0.5; page.anchor_top = 0.5; page.anchor_right = 0.5; page.anchor_bottom = 0.5
	page.offset_left = -310; page.offset_top = -210; page.offset_right = 310; page.offset_bottom = 210
	add_child(page)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 25)
	DeskTheme.apply_font(vbox)
	page.get_node("Content").add_child(vbox)

	vbox.add_child(DeskTheme.create_label("名前を入力してください", 30, DeskTheme.COLOR_INK, true))
	
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "学籍番号（名前）"
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.custom_minimum_size = Vector2(340, 56)
	DeskTheme.style_input(line_edit)
	vbox.add_child(line_edit)

	var btn = DeskTheme.create_button("この名前で始める", Vector2(280, 70), DeskTheme.COLOR_SAFE, Color("2d928a"))
	btn.pressed.connect(func():
		var n = line_edit.text.strip_edges()
		if n == "": n = "名無し学生" + str(randi_range(100, 999))
		Global.player_name = n; Global.save_data()
		SceneTransition.fade_to_scene("res://Main.tscn")
	)
	vbox.add_child(btn)
