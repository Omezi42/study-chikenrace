extends Node

var loading_overlay: CanvasLayer = null

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

# Global helper to perform smooth scene changes with a paper fade overlay
func show_toast(text: String, duration: float = 1.8, bg_color: Color = Color()) -> void:
	DeskTheme.show_toast(self, text, duration, bg_color)

func change_scene_with_fade(tree: SceneTree, target_scene_path: String, duration: float = 0.35) -> void:
	# Create CanvasLayer to overlay transition
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	tree.root.add_child(canvas)
	
	var fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color("eddcc9") # Bright paper color
	fade_rect.modulate.a = 0.0
	canvas.add_child(fade_rect)
	
	# Fade out current scene
	var tween = tree.create_tween().bind_node(fade_rect)
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	tween.tween_callback(func():
		# Change scene
		tree.change_scene_to_file(target_scene_path)
		
		# Fade in new scene
		var tween_in = tree.create_tween().bind_node(fade_rect)
		tween_in.tween_property(fade_rect, "modulate:a", 0.0, duration)
		tween_in.tween_callback(func():
			canvas.queue_free()
		)
	)

func show_loading(text: String = "通信中...") -> void:
	if is_instance_valid(loading_overlay):
		var lbl = loading_overlay.get_node_or_null("Panel/Margin/VBox/Label")
		if lbl:
			lbl.text = text
		return
		
	loading_overlay = CanvasLayer.new()
	loading_overlay.layer = 200
	add_child(loading_overlay)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.4)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_overlay.add_child(bg)
	
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(300, 140)
	panel.pivot_offset = Vector2(150, 70)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("f4efe6") # Craft paper color
	style.border_color = Color("1e2022")
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.12, 0.08, 0.05, 0.25)
	style.shadow_size = 12
	style.shadow_offset = Vector2(5, 5)
	panel.add_theme_stylebox_override("panel", style)
	loading_overlay.add_child(panel)
	
	var viewport_size = get_viewport().get_visible_rect().size
	panel.position = viewport_size * 0.5 - panel.pivot_offset
	
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var label = Label.new()
	label.name = "Label"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load("res://assets/hgrsmp.ttf"))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("1e2022"))
	vbox.add_child(label)
	
	var spinner = Control.new()
	spinner.custom_minimum_size = Vector2(40, 40)
	spinner.pivot_offset = Vector2(20, 20)
	vbox.add_child(spinner)
	
	var spinner_lbl = Label.new()
	spinner_lbl.text = "+"
	spinner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	spinner_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spinner_lbl.add_theme_font_size_override("font_size", 24)
	spinner.add_child(spinner_lbl)
	
	var spinner_tween = spinner.create_tween().set_loops()
	spinner_tween.tween_property(spinner, "rotation_degrees", 360.0, 1.2).from(0.0)

func hide_loading() -> void:
	if is_instance_valid(loading_overlay):
		loading_overlay.queue_free()
		loading_overlay = null

func show_tutorial_dialog(parent: Control, text: String, pos: Vector2 = Vector2(700, 50), next_callback: Callable = Callable()) -> PanelContainer:
	var dialog = PanelContainer.new()
	dialog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.custom_minimum_size = Vector2(520, 220)
	dialog.size = Vector2(520, 220)
	var viewport_size = parent.get_viewport_rect().size
	if pos == Vector2(700, 50):
		dialog.position = viewport_size * 0.5 - dialog.pivot_offset
	else:
		dialog.position = Vector2(
			clamp(pos.x, 0.0, max(viewport_size.x - dialog.size.x, 0.0)),
			clamp(pos.y, 0.0, max(viewport_size.y - dialog.size.y, 0.0))
		)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("fff59d") # 明るい付箋イエロー
	style.border_color = Color("fbc02d") # 濃いイエロー
	style.border_width_left = 8
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 12
	style.shadow_offset = Vector2(4, 4)
	dialog.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	dialog.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var header = Label.new()
	header.text = "📌 佐藤くんのメモ"
	header.add_theme_font_override("font", DeskTheme.get_font())
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(header)

	
	var body = Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", DeskTheme.get_font())
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(body)
	
	if next_callback.is_valid():
		var btn = Button.new()
		btn.text = "次へ >"
		btn.custom_minimum_size = Vector2(100, 36)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		btn.add_theme_font_override("font", DeskTheme.get_font())
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func():
			DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
			var out_tween = parent.create_tween().bind_node(dialog)
			out_tween.tween_property(dialog, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			out_tween.tween_callback(func():
				dialog.queue_free()
				next_callback.call()
			)
		)
		vbox.add_child(btn)
		
	parent.add_child(dialog)
	
	dialog.scale = Vector2.ZERO
	dialog.pivot_offset = Vector2(260, 110)
	var tween = parent.create_tween().bind_node(dialog).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dialog, "scale", Vector2.ONE, 0.3)
	
	return dialog

func apply_white_button_style(btn: Button) -> void:
	if not btn:
		return
	
	# Normal stylebox (white background, ink border)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color.WHITE
	style_normal.border_color = DeskTheme.COLOR_INK
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 3
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	style_normal.shadow_color = Color(0.12, 0.08, 0.05, 0.15)
	style_normal.shadow_size = 4
	style_normal.shadow_offset = Vector2(2, 2)
	
	# Hover stylebox (very light cream tint)
	var style_hover = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color("fffde7")
	style_hover.border_width_left = 4
	style_hover.border_width_right = 4
	style_hover.border_width_top = 4
	style_hover.border_width_bottom = 4
	style_hover.shadow_size = 6
	style_hover.shadow_offset = Vector2(3, 3)
	
	# Pressed stylebox (slightly darker grey)
	var style_pressed = style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = Color("e0e0e0")
	style_pressed.shadow_size = 1
	style_pressed.shadow_offset = Vector2(1, 1)

	var style_focus = StyleBoxEmpty.new()
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_focus)
	
	# Text colors
	btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	btn.add_theme_color_override("font_hover_color", DeskTheme.COLOR_INK)
	btn.add_theme_color_override("font_pressed_color", DeskTheme.COLOR_INK)
	btn.add_theme_color_override("font_focus_color", DeskTheme.COLOR_INK)
	btn.add_theme_color_override("font_hover_pressed_color", DeskTheme.COLOR_INK)
	
	# Check children for labels
	for child in btn.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", DeskTheme.COLOR_INK)

func _on_node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_apply_improved_typography", node)

func _apply_improved_typography(node: Node) -> void:
	if not is_instance_valid(node):
		return
		
	var root = get_tree().root
	var global = root.get_node_or_null("Global")
	var use_handwriting = global.use_handwriting_font if global else true
	var current_font = DeskTheme.get_font()

	if node is Label:
		if current_font:
			node.add_theme_font_override("font", current_font)
		else:
			node.remove_theme_font_override("font")
			
		var font_color = node.get_theme_color("font_color")
		if font_color == Color(0,0,0,0) or font_color == null:
			font_color = DeskTheme.COLOR_INK
			
		var font_size = node.get_theme_font_size("font_size")
		var outline_sz = 0
		if font_size > 0:
			if font_size > 24:
				outline_sz = 2
			elif font_size > 18:
				outline_sz = 1
			else:
				outline_sz = 0
			
		# Only use outlines when text color is light (e.g. value >= 0.7) and needs contrast,
		# or if the text is very large. Otherwise, clear the outline or keep it extremely subtle.
		if outline_sz > 0:
			if font_color.v < 0.4:
				# Dark text: Use a very soft, semi-transparent light outline only if necessary, or none.
				node.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.4))
			else:
				# Light text: Use a dark outline for readability on light backgrounds
				node.add_theme_color_override("font_outline_color", Color("1e2022", 0.8))
			node.add_theme_constant_override("outline_size", outline_sz)
		else:
			node.remove_theme_constant_override("outline_size")
		
		node.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.05, 0.15))
		node.add_theme_constant_override("shadow_offset_x", 1)
		node.add_theme_constant_override("shadow_offset_y", 1)
		node.add_theme_constant_override("shadow_outline_size", 1)

	elif node is RichTextLabel:
		if current_font:
			node.add_theme_font_override("normal_font", current_font)
			node.add_theme_font_override("bold_font", current_font)
			node.add_theme_font_override("italics_font", current_font)
			node.add_theme_font_override("bold_italics_font", current_font)
			node.add_theme_font_override("mono_font", current_font)
		else:
			node.remove_theme_font_override("normal_font")
			node.remove_theme_font_override("bold_font")
			node.remove_theme_font_override("italics_font")
			node.remove_theme_font_override("bold_italics_font")
			node.remove_theme_font_override("mono_font")

		var font_size = node.get_theme_font_size("font_size")
		var outline_sz = 0
		if font_size > 0:
			if font_size > 24:
				outline_sz = 2
			elif font_size > 18:
				outline_sz = 1
			else:
				outline_sz = 0

		if outline_sz > 0:
			node.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.4))
			node.add_theme_constant_override("outline_size", outline_sz)
		else:
			node.remove_theme_constant_override("outline_size")
		node.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.05, 0.15))
		node.add_theme_constant_override("shadow_offset_x", 1)
		node.add_theme_constant_override("shadow_offset_y", 1)

	elif node is Button:
		if current_font:
			node.add_theme_font_override("font", current_font)
		else:
			node.remove_theme_font_override("font")
		
		var font_size = node.get_theme_font_size("font_size")
		var outline_sz = 0
		if font_size > 0:
			if font_size > 24:
				outline_sz = 2
			elif font_size > 18:
				outline_sz = 1
			else:
				outline_sz = 0

		if outline_sz > 0:
			node.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.4))
			node.add_theme_constant_override("outline_size", outline_sz)
		else:
			node.remove_theme_constant_override("outline_size")
		
	elif node is LineEdit:
		if current_font:
			node.add_theme_font_override("font", current_font)
		else:
			node.remove_theme_font_override("font")
		
		var font_size = node.get_theme_font_size("font_size")
		var outline_sz = 0
		if font_size > 0:
			if font_size > 24:
				outline_sz = 2
			elif font_size > 18:
				outline_sz = 1
			else:
				outline_sz = 0

		if outline_sz > 0:
			node.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.4))
			node.add_theme_constant_override("outline_size", outline_sz)
		else:
			node.remove_theme_constant_override("outline_size")

func refresh_typography() -> void:
	var root = get_tree().root
	_apply_to_subtree(root)

func _apply_to_subtree(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is Control:
		_apply_improved_typography(node)
	for child in node.get_children():
		_apply_to_subtree(child)
