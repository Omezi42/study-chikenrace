class_name ConnectionErrorModal
extends CanvasLayer

static func create_and_show(parent_node: Node, error_text: String = "通信が切断されました。\nタイトル画面に戻ります。") -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = ConnectionErrorModal.new()
	canvas.error_msg = error_text
	parent_node.add_child(canvas)

var error_msg: String = "通信が切断されました。\nタイトル画面に戻ります。"

func _ready() -> void:
	layer = 120 # settings よりも高く設定
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.6)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(460, 260)
	modal.pivot_offset = Vector2(230, 130)
	modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(modal)
	
	var viewport_size = get_viewport().get_visible_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", DeskTheme.MARGIN_DEFAULT)
	margin.add_theme_constant_override("margin_right", DeskTheme.MARGIN_DEFAULT)
	margin.add_theme_constant_override("margin_top", DeskTheme.MARGIN_DEFAULT)
	margin.add_theme_constant_override("margin_bottom", DeskTheme.MARGIN_DEFAULT)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_MEDIUM)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Title with Tension Color
	var title = Label.new()
	title.text = "⚠️ 通信エラー"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	vbox.add_child(title)
	
	var label = Label.new()
	label.text = error_msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DeskTheme.get_font())
	label.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(label)
	
	var return_btn = Button.new()
	return_btn.text = "タイトルへ戻る"
	return_btn.custom_minimum_size = Vector2(200, 48)
	return_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return_btn.add_theme_font_override("font", DeskTheme.get_font())
	return_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	Global.apply_white_button_style(return_btn)
	vbox.add_child(return_btn)
	
	return_btn.pressed.connect(func():
		return_btn.release_focus()
		DeskTheme.animate_click(return_btn, Vector2.ONE, 0.08)
		
		# Close modal and force title screen
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.15)
		out_tween.tween_callback(func():
			queue_free()
			var tree = get_tree()
			if tree and tree.root.has_node("Global"):
				var global = tree.root.get_node("Global")
				global.change_scene_with_fade(tree, "res://Title.tscn")
		)
	)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.25)
