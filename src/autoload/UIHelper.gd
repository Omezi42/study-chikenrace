extends Node

var loading_overlay: CanvasLayer = null

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

# Global helper to perform smooth scene changes with a paper fade overlay
func show_toast(text: String, duration: float = 1.8, bg_color: Color = Color()) -> void:
	DeskTheme.show_toast(self, text, duration, bg_color)

func change_scene_with_fade(tree: SceneTree, target_scene_path: String, duration: float = 0.35) -> void:
	if tree.root.has_node("AudioManager"):
		tree.root.get_node("AudioManager").play_ui(AudioManager.SE_WHOOSH)
		
	# Create CanvasLayer to overlay transition
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	tree.root.add_child.call_deferred(canvas)
	
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
		var lbl = loading_overlay.get_node_or_null("Center/Panel/Margin/VBox/Label")
		if not lbl:
			lbl = loading_overlay.get_node_or_null("Panel/Margin/VBox/Label")
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
	
	var center = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_overlay.add_child(center)
	
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(300, 140)
	
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
	center.add_child(panel)
	
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

func show_tutorial_dialog(parent: Control, text: String, pos: Vector2 = Vector2(700, 50), next_callback: Callable = Callable()) -> Node:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	
	var scene_tree = parent.get_tree()
	var rs_scale = 1.0
	if scene_tree and scene_tree.root.has_node("ResponsiveScaler"):
		rs_scale = scene_tree.root.get_node("ResponsiveScaler").get_scale()
	
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_theme_constant_override("margin_top", int(20 * rs_scale))
	margin_container.add_theme_constant_override("margin_left", int(20 * rs_scale))
	margin_container.add_theme_constant_override("margin_right", int(20 * rs_scale))
	margin_container.add_theme_constant_override("margin_bottom", int(20 * rs_scale))
	canvas.add_child(margin_container)
	
	var dialog = PanelContainer.new()
	dialog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(dialog)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("ffffff") # White dialog for clean mobile feel
	style.border_color = DeskTheme.COLOR_INK
	style.border_width_left = int(4 * rs_scale)
	style.border_width_right = int(4 * rs_scale)
	style.border_width_top = int(4 * rs_scale)
	style.border_width_bottom = int(6 * rs_scale)
	style.corner_radius_top_left = int(16 * rs_scale)
	style.corner_radius_top_right = int(16 * rs_scale)
	style.corner_radius_bottom_left = int(16 * rs_scale)
	style.corner_radius_bottom_right = int(16 * rs_scale)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = int(15 * rs_scale)
	style.shadow_offset = Vector2(0, int(6 * rs_scale))
	dialog.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(24 * rs_scale))
	margin.add_theme_constant_override("margin_right", int(24 * rs_scale))
	margin.add_theme_constant_override("margin_top", int(20 * rs_scale))
	margin.add_theme_constant_override("margin_bottom", int(20 * rs_scale))
	dialog.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", int(15 * rs_scale))
	margin.add_child(vbox)
	
	var body = Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", DeskTheme.get_font())
	body.add_theme_font_size_override("font_size", int(26 * rs_scale))
	body.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(body)
	
	if next_callback.is_valid():
		var btn = Button.new()
		btn.text = "次へ >"
		btn.custom_minimum_size = Vector2(int(140 * rs_scale), int(48 * rs_scale))
		btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		btn.add_theme_font_override("font", DeskTheme.get_font())
		btn.add_theme_font_size_override("font_size", int(22 * rs_scale))
		apply_action_button_style(btn)
		btn.pressed.connect(func():
			DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
			var out_tween = parent.create_tween().bind_node(margin_container)
			out_tween.tween_property(margin_container, "position:y", -300.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			out_tween.tween_callback(func():
				canvas.queue_free()
				next_callback.call()
			)
		)
		vbox.add_child(btn)
		
	parent.add_child(canvas)
	
	# Initial positioning for slide-in animation
	get_tree().process_frame.connect(func():
		if is_instance_valid(margin_container):
			margin_container.position.y = -margin_container.size.y - 50
			var tween = parent.create_tween().bind_node(margin_container).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(margin_container, "position:y", 0.0, 0.4)
	, CONNECT_ONE_SHOT)
	
	return canvas

func apply_white_button_style(btn: Button) -> void:
	if not btn:
		return
	
	# Normal stylebox (white background, ink border)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color.WHITE
	style_normal.border_color = DeskTheme.COLOR_INK
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 5
	style_normal.corner_radius_top_left = 12
	style_normal.corner_radius_top_right = 12
	style_normal.corner_radius_bottom_left = 12
	style_normal.corner_radius_bottom_right = 12
	style_normal.shadow_color = Color(0, 0, 0, 0.1)
	style_normal.shadow_size = 6
	style_normal.shadow_offset = Vector2(0, 4)
	style_normal.content_margin_left = 20
	style_normal.content_margin_right = 20
	
	# Hover stylebox
	var style_hover = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color("f8f9fa")
	style_hover.border_width_bottom = 6
	style_hover.shadow_size = 8
	style_hover.shadow_offset = Vector2(0, 6)
	
	# Pressed stylebox
	var style_pressed = style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = Color("e9ecef")
	style_pressed.border_width_bottom = 2
	style_pressed.shadow_size = 0
	style_pressed.shadow_offset = Vector2(0, 0)
	
	var style_focus = StyleBoxEmpty.new()
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_focus)
	
	# Text colors
	btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	btn.add_theme_color_override("font_hover_color", DeskTheme.COLOR_INK)
	btn.add_theme_color_override("font_pressed_color", DeskTheme.COLOR_INK)

func apply_action_button_style(btn: Button) -> void:
	if not btn: return
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = DeskTheme.COLOR_BONUS # Green
	style_normal.border_color = DeskTheme.COLOR_INK
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 6
	style_normal.corner_radius_top_left = 12
	style_normal.corner_radius_top_right = 12
	style_normal.corner_radius_bottom_left = 12
	style_normal.corner_radius_bottom_right = 12
	style_normal.shadow_color = Color(0, 0, 0, 0.15)
	style_normal.shadow_size = 8
	style_normal.shadow_offset = Vector2(0, 5)
	
	var style_hover = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = DeskTheme.COLOR_BONUS.lightened(0.1)
	style_hover.border_width_bottom = 7
	style_hover.shadow_offset = Vector2(0, 7)
	
	var style_pressed = style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = DeskTheme.COLOR_BONUS.darkened(0.1)
	style_pressed.border_width_bottom = 2
	style_pressed.shadow_offset = Vector2(0, 0)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

func apply_danger_button_style(btn: Button) -> void:
	if not btn: return
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = DeskTheme.COLOR_TENSION # Pink/Red
	style_normal.border_color = DeskTheme.COLOR_INK
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 6
	style_normal.corner_radius_top_left = 12
	style_normal.corner_radius_top_right = 12
	style_normal.corner_radius_bottom_left = 12
	style_normal.corner_radius_bottom_right = 12
	style_normal.shadow_color = Color(0, 0, 0, 0.15)
	style_normal.shadow_size = 8
	style_normal.shadow_offset = Vector2(0, 5)
	
	var style_hover = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = DeskTheme.COLOR_TENSION.lightened(0.1)
	style_hover.border_width_bottom = 7
	style_hover.shadow_offset = Vector2(0, 7)
	
	var style_pressed = style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = DeskTheme.COLOR_TENSION.darkened(0.1)
	style_pressed.border_width_bottom = 2
	style_pressed.shadow_offset = Vector2(0, 0)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)


func _on_node_added(node: Node) -> void:
	if node is Control:
		(func(n): if is_instance_valid(n): _apply_improved_typography(n)).call_deferred(node)

func _apply_improved_typography(node: Node) -> void:
	if not is_instance_valid(node):
		return
		
	var root = get_tree().root
	var global = root.get_node_or_null("Global")

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
			
		var am = root.get_node_or_null("AudioManager")
		if am:
			var should_play_hover = node.is_in_group("important_button") or node.has_meta("play_hover")
			if should_play_hover:
				if not node.mouse_entered.is_connected(am.play_ui_hover):
					node.mouse_entered.connect(am.play_ui_hover)
			else:
				if node.mouse_entered.is_connected(am.play_ui_hover):
					node.mouse_entered.disconnect(am.play_ui_hover)
		
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
			
		if OS.has_feature("web"):
			if not node.gui_input.is_connected(_on_line_edit_gui_input.bind(node)):
				node.gui_input.connect(_on_line_edit_gui_input.bind(node))

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

func _on_line_edit_gui_input(event: InputEvent, line_edit: LineEdit) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_mobile_input(line_edit)
	elif event is InputEventScreenTouch and event.pressed:
		_show_mobile_input(line_edit)

func _show_mobile_input(line_edit: LineEdit) -> void:
	if not OS.has_feature("web"):
		return
	
	var is_mobile = JavaScriptBridge.eval("/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);")
	if is_mobile:
		var prompt_msg = "テキストを入力してください"
		if line_edit.placeholder_text != "":
			prompt_msg = line_edit.placeholder_text
			
		var js_code = "window.prompt('%s', '%s');" % [prompt_msg, line_edit.text.replace("'", "\\'")]
		var result = JavaScriptBridge.eval(js_code)
		if result != null:
			line_edit.text = str(result)
			line_edit.text_changed.emit(line_edit.text)
			line_edit.text_submitted.emit(line_edit.text)
