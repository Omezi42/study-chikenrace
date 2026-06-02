class_name DeskTheme
extends Node

# Color Palette Constants
const COLOR_MAHOGANY = Color("eddcc9")
const COLOR_CRAFT = Color("f4efe6")
const COLOR_INK = Color("1e2022")
const COLOR_HIGHLIGHTER = Color("fff176")
const COLOR_TENSION = Color("ff4081")
const COLOR_GREEN = Color("00e676")
const COLOR_BONUS = Color("40c057")
const COLOR_CHALK_WHITE = Color(1.0, 1.0, 1.0, 0.8)
const COLOR_CHALK_YELLOW = Color("ffe066")

# Role Type Colors
const COLOR_ROLE_DEFENSE = Color("00e676")  # Green (守り)
const COLOR_ROLE_PUSH = Color("ff9100")     # Orange (押し)
const COLOR_ROLE_BLUFF = Color("d500f9")    # Purple (ブラフ)
const COLOR_ROLE_PREP = Color("2979ff")     # Blue (仕込み)

# Font File Paths
const FONT_HANDWRITING = "res://assets/hgrsmp.ttf"
const _preloaded_font = preload(FONT_HANDWRITING)

static func get_font() -> Font:
	return _preloaded_font

# UI Constant Tokens (レイアウト定数)
const MARGIN_LARGE = 35
const MARGIN_DEFAULT = 30
const MARGIN_MEDIUM = 25
const MARGIN_SMALL = 20
const MARGIN_TINY = 15

const FONT_SIZE_GIANT = 54
const FONT_SIZE_TITLE_LARGE = 40
const FONT_SIZE_TITLE = 32
const FONT_SIZE_SUBTITLE = 28
const FONT_SIZE_LARGE = 26
const FONT_SIZE_NORMAL = 22
const FONT_SIZE_SMALL = 18
const FONT_SIZE_TINY = 16
const FONT_SIZE_MINI = 14

# Static Tween Animation Helper Functions

# 1. Hover Bounce & Random Angle Rotation
static func animate_hover(node: Control, is_hovered: bool, base_scale: Vector2 = Vector2.ONE, duration: float = 0.15) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	var tween = scene_tree.create_tween().bind_node(node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_hovered:
		var target_scale = base_scale * 1.06
		# Give a slight random rotation between -2 and 2 degrees to feel like a loose sticky note or card
		var target_rotation = randf_range(-2.0, 2.0)
		tween.tween_property(node, "scale", target_scale, duration)
		tween.tween_property(node, "rotation_degrees", target_rotation, duration)
	else:
		tween.tween_property(node, "scale", base_scale, duration)
		tween.tween_property(node, "rotation_degrees", 0.0, duration)

# 2. Click Pushdown & Bounce Transition
static func animate_click(node: Control, base_scale: Vector2 = Vector2.ONE, duration: float = 0.08) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	
	if scene_tree.root.has_node("AudioManager"):
		var audio = scene_tree.root.get_node("AudioManager")
		audio.play_se(audio.SE_CLICK)
		
	var tween = scene_tree.create_tween().bind_node(node).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var shrink_scale = base_scale * 0.92
	tween.tween_property(node, "scale", shrink_scale, duration)
	tween.tween_property(node, "scale", base_scale, duration)

# 3. Notebook/Panel Entrance Transition (Bottom to Center)
static func animate_entrance(node: Control, target_position: Vector2, start_offset: Vector2 = Vector2(0, 400), duration: float = 0.5) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	node.position = target_position + start_offset
	node.modulate.a = 0.0
	var tween = scene_tree.create_tween().bind_node(node).set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", target_position, duration)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.6)

# 4. 3D-like Card Flip Transition
static func animate_card_flip(node: Control, duration: float = 0.35, on_mid_flip: Callable = Callable()) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	var original_scale = node.scale
	var tween = scene_tree.create_tween().bind_node(node).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Shrink horizontally to 0 (midway flip)
	tween.tween_property(node, "scale:x", 0.0, duration * 0.5)
	
	# Call back to change texture/content
	if on_mid_flip.is_valid():
		tween.tween_callback(on_mid_flip)
		
	# Grow horizontally back to original
	tween.tween_property(node, "scale:x", original_scale.x, duration * 0.5).set_ease(Tween.EASE_OUT)

# 5. Screen / Node Position Shake (Cameras or UI elements)
static func shake_node(node: Node2D, intensity: float, duration: float, shake_count: int = 8) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	var original_pos = node.position
	var tween = scene_tree.create_tween().bind_node(node).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step_duration = duration / shake_count
	
	for i in range(shake_count - 1):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", original_pos + offset, step_duration)
		
	# Return to original
	tween.tween_property(node, "position", original_pos, step_duration)

# 6. UI Control Element Position Shake
static func shake_control(node: Control, intensity: float, duration: float, shake_count: int = 8) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	var original_pos = node.position
	var tween = scene_tree.create_tween().bind_node(node).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step_duration = duration / shake_count
	
	for i in range(shake_count - 1):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", original_pos + offset, step_duration)
		
	tween.tween_property(node, "position", original_pos, step_duration)

# 7. Vignette Alert Pulse Animation
static func pulse_vignette(node: Control, base_modulate: Color, alert_level: float) -> void:
	if not node or not node.is_inside_tree():
		return
	# Remove any existing tweens to avoid conflicts
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
		
	var target_color = base_modulate
	target_color.a = clamp(alert_level * 0.45, 0.0, 0.5)
	
	var pulse_speed = 0.5
	if alert_level >= 0.8:
		pulse_speed = 0.25 # Speed up pulse for extreme danger
		
	var tween = scene_tree.create_tween().bind_node(node).set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate", target_color, pulse_speed)
	
	var dim_color = base_modulate
	dim_color.a = clamp(alert_level * 0.1, 0.0, 0.1)
	tween.tween_property(node, "modulate", dim_color, pulse_speed)

# Helper to create customized hand-drawn look panel stylebox
static func create_craft_panel() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_CRAFT
	style.border_color = COLOR_INK
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	# Richer shadow to look like stacked pages
	style.shadow_color = Color(0.12, 0.08, 0.05, 0.25)
	style.shadow_size = 12
	style.shadow_offset = Vector2(5, 5)
	return style

# Helper to create left page stylebox (no right border, no right rounded corners for binding integration)
static func create_left_page_style() -> StyleBoxFlat:
	var style = create_craft_panel()
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.border_width_right = 0
	return style

# Helper to create right page stylebox (no left border, no left rounded corners for binding integration)
static func create_right_page_style() -> StyleBoxFlat:
	var style = create_craft_panel()
	style.corner_radius_top_left = 0
	style.corner_radius_bottom_left = 0
	style.border_width_left = 0
	return style

# Helper to overlay notebook ruled lines
static func add_ruled_lines(parent_node: Control, line_color: Color = Color(0.2, 0.6, 0.8, 0.08)) -> void:
	if not parent_node:
		return
	var ruled_rect = RuledLinesDrawer.new()
	ruled_rect.line_color = line_color
	ruled_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ruled_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_node.add_child(ruled_rect)
	parent_node.move_child(ruled_rect, 0) # Place in background

# Helper to overlay spiral binding
static func add_spiral_binding(hbox: HBoxContainer, height: float = 750.0) -> void:
	if not hbox:
		return
	var binding_control = Control.new()
	binding_control.custom_minimum_size = Vector2(0, height) # Width 0 so pages touch
	binding_control.clip_contents = false
	hbox.add_child(binding_control)
	
	if hbox.get_child_count() > 1:
		hbox.move_child(binding_control, 1) # Put in middle
		
	var drawer = SpiralDrawer.new()
	drawer.custom_minimum_size = Vector2(0, height)
	drawer.clip_contents = false
	drawer.center_x = 0.0
	binding_control.add_child(drawer)

# Helper to overlay a central spiral binding on a single notebook panel.
static func add_spiral_binding_overlay(parent_node: Control, size: Vector2, line_color: Color = Color(0.1, 0.08, 0.05, 0.35)) -> void:
	if not parent_node:
		return
	var binding = Control.new()
	binding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	binding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	binding.clip_contents = false
	parent_node.add_child(binding)
	parent_node.move_child(binding, 0)

	var drawer = SpiralDrawer.new()
	drawer.line_color = line_color
	drawer.custom_minimum_size = size
	drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawer.center_x = size.x * 0.5
	binding.add_child(drawer)

# 8. Floating Sticky-Note Toast Message
static func show_toast(caller_node: Node, text: String, duration: float = 1.8) -> void:
	if not caller_node or not caller_node.is_inside_tree():
		return
	var scene_tree = caller_node.get_tree()
	if not scene_tree or not scene_tree.root:
		return
		
	# Create CanvasLayer to overlay everything
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # High layer to be on top
	scene_tree.root.add_child(canvas)
	
	# Create Toast PanelContainer
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 60)
	panel.pivot_offset = Vector2(230, 30)
	
	# Styling (like a cute yellow sticky note or craft paper)
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_HIGHLIGHTER # Bright sticky note yellow
	style.border_color = COLOR_INK
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load(FONT_HANDWRITING))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", COLOR_INK)
	panel.add_child(label)
	
	canvas.add_child(panel)
	
	# Positioning (bottom center of the screen)
	var screen_w = 1920
	var screen_h = 1080
	var viewport_size = scene_tree.root.get_viewport().get_visible_rect().size
	if viewport_size.x > 0:
		screen_w = viewport_size.x
		screen_h = viewport_size.y
		
	var start_pos = Vector2((screen_w - 460) / 2.0, screen_h - 100)
	var end_pos = Vector2((screen_w - 460) / 2.0, screen_h - 160)
	
	panel.position = start_pos
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	
	# Tween animate slide up and fade in
	var tween = scene_tree.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position", end_pos, 0.3)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)
	
	# Hold for a moment, then fade out and queue_free
	var timer = scene_tree.create_timer(duration)
	timer.timeout.connect(func():
		if panel and panel.is_inside_tree():
			var fade_tween = scene_tree.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fade_tween.tween_property(panel, "position", end_pos - Vector2(0, 30), 0.3)
			fade_tween.tween_property(panel, "modulate:a", 0.0, 0.25)
			fade_tween.chain().tween_callback(func():
				canvas.queue_free()
			)
	)

# 9. Page-Flip Transition Animation
static func animate_page_flip(outgoing_node: Control, incoming_node: Control, duration: float = 0.45) -> void:
	if not incoming_node or not incoming_node.is_inside_tree():
		if outgoing_node and outgoing_node.is_inside_tree():
			outgoing_node.queue_free()
		return
	
	incoming_node.pivot_offset = incoming_node.custom_minimum_size / 2.0 if incoming_node.size == Vector2.ZERO else incoming_node.size / 2.0
	incoming_node.scale.x = 0.0
	incoming_node.modulate.a = 0.8
	
	var scene_tree = incoming_node.get_tree()
	if not scene_tree:
		return
		
	var tween = scene_tree.create_tween().bind_node(incoming_node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if outgoing_node and outgoing_node.is_inside_tree():
		outgoing_node.pivot_offset = outgoing_node.custom_minimum_size / 2.0 if outgoing_node.size == Vector2.ZERO else outgoing_node.size / 2.0
		var out_tween = scene_tree.create_tween().bind_node(outgoing_node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(outgoing_node, "scale:x", 0.0, duration * 0.5)
		out_tween.tween_property(outgoing_node, "modulate:a", 0.0, duration * 0.5)
		out_tween.chain().tween_callback(func(): outgoing_node.queue_free())
		
		tween.tween_property(incoming_node, "scale:x", 1.0, duration).set_delay(duration * 0.4)
		tween.tween_property(incoming_node, "modulate:a", 1.0, duration).set_delay(duration * 0.4)
	else:
		tween.tween_property(incoming_node, "scale:x", 1.0, duration)
		tween.tween_property(incoming_node, "modulate:a", 1.0, duration)

# 10. Notebook Page Turn Transition for the study/battle flow
static func animate_notebook_turn(outgoing_node: Control, incoming_node: Control, duration: float = 0.55, turn_from_left: bool = false) -> void:
	if not incoming_node or not incoming_node.is_inside_tree():
		if outgoing_node and outgoing_node.is_inside_tree():
			outgoing_node.queue_free()
		return

	var scene_tree = incoming_node.get_tree()
	if not scene_tree:
		return

	var incoming_pivot = incoming_node.custom_minimum_size / 2.0 if incoming_node.size == Vector2.ZERO else incoming_node.size / 2.0
	var outgoing_pivot = incoming_pivot
	incoming_node.pivot_offset = incoming_pivot
	incoming_node.modulate.a = 0.0
	incoming_node.scale = Vector2(0.02, 1.0)

	var offset_dir = -1.0 if turn_from_left else 1.0
	incoming_node.position += Vector2(140.0 * offset_dir, 0.0)

	var tween = scene_tree.create_tween().bind_node(incoming_node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if outgoing_node and outgoing_node.is_inside_tree():
		outgoing_node.pivot_offset = outgoing_pivot
		var out_tween = scene_tree.create_tween().bind_node(outgoing_node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(outgoing_node, "scale:x", 0.02, duration * 0.45)
		out_tween.tween_property(outgoing_node, "modulate:a", 0.0, duration * 0.45)
		out_tween.tween_property(outgoing_node, "position:x", outgoing_node.position.x - (120.0 * offset_dir), duration * 0.45)
		out_tween.chain().tween_callback(func(): outgoing_node.queue_free())

	tween.tween_property(incoming_node, "position:x", incoming_node.position.x - (140.0 * offset_dir), duration)
	tween.tween_property(incoming_node, "scale:x", 1.0, duration)
	tween.tween_property(incoming_node, "modulate:a", 1.0, duration * 0.8)

# 11. Natural notebook-like cross transition for phase switches.
static func animate_soft_phase_transition(outgoing_node: Control, incoming_node: Control, duration: float = 0.42, from_left: bool = false) -> void:
	if not incoming_node or not incoming_node.is_inside_tree():
		if outgoing_node and outgoing_node.is_inside_tree():
			outgoing_node.queue_free()
		return

	var scene_tree = incoming_node.get_tree()
	if not scene_tree:
		return

	var viewport_size = incoming_node.get_viewport_rect().size
	var slide = min(viewport_size.x * 0.08, 120.0)
	var dir = -1.0 if from_left else 1.0

	incoming_node.modulate.a = 0.0
	incoming_node.position += Vector2(slide * dir, 0.0)

	var tween = scene_tree.create_tween().bind_node(incoming_node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(incoming_node, "position:x", incoming_node.position.x - (slide * dir), duration)
	tween.tween_property(incoming_node, "modulate:a", 1.0, duration * 0.85)

	if outgoing_node and outgoing_node.is_inside_tree():
		var out_tween = scene_tree.create_tween().bind_node(outgoing_node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(outgoing_node, "position:x", outgoing_node.position.x - (slide * dir), duration)
		out_tween.tween_property(outgoing_node, "modulate:a", 0.0, duration * 0.8)
		out_tween.chain().tween_callback(func(): outgoing_node.queue_free())

# Inner class for ruled lines
class RuledLinesDrawer:
	extends Control
	
	var line_color: Color
	
	func _draw() -> void:
		var step = 30.0
		var h = size.y
		var w = size.x
		var y = 40.0
		while y < h - 20.0:
			draw_line(Vector2(20, y), Vector2(w - 20, y), line_color, 1.5)
			y += step
			
		# Red left margin line
		draw_line(Vector2(50, 10), Vector2(50, h - 10), Color("ff6b6b", 0.18), 2.0)

# Inner class for spiral binding
class SpiralDrawer:
	extends Control

	var center_x: float = 0.0
	var line_color: Color = Color(0.05, 0.04, 0.02, 0.45)
	
	func _draw() -> void:
		var h = size.y
		var cy = 40.0
		var step = 32.0
		
		# Draw dark spine shadow (center folding crease)
		draw_rect(Rect2(center_x - 30, 0, 60, h), Color(0.1, 0.08, 0.05, 0.12)) # Broad soft crease shadow
		draw_rect(Rect2(center_x - 15, 0, 30, h), Color(0.1, 0.08, 0.05, 0.18)) # Narrower crease shadow
		draw_line(Vector2(center_x, 0), Vector2(center_x, h), line_color, 2.5) # Central seam line
		
		# Draw silver rings looping through paper holes
		while cy < h - 30.0:
			# Left & right paper holes (small dark circles)
			draw_circle(Vector2(center_x - 14, cy), 3.0, Color("1e2022", 0.65))
			draw_circle(Vector2(center_x + 14, cy - 2.5), 3.0, Color("1e2022", 0.65))
			
			# Shadow under the ring coil
			draw_line(Vector2(center_x - 14, cy + 2.5), Vector2(center_x + 14, cy), Color(0.1, 0.08, 0.05, 0.22), 4.5)
			
			# Ring loop (silver metallic line)
			draw_line(Vector2(center_x - 14, cy), Vector2(center_x + 14, cy - 2.5), Color(0.76, 0.76, 0.8), 4.5)
			
			# Specular highlight core
			draw_line(Vector2(center_x - 10, cy - 0.6), Vector2(center_x + 10, cy - 2.0), Color.WHITE, 1.5)
			
			cy += step




static func apply_white_button_style(btn: Button) -> void:
	if not btn:
		return
	
	# Normal stylebox (white background, ink border)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color.WHITE
	style_normal.border_color = COLOR_INK
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
	btn.add_theme_color_override("font_color", COLOR_INK)
	btn.add_theme_color_override("font_hover_color", COLOR_INK)
	btn.add_theme_color_override("font_pressed_color", COLOR_INK)
	btn.add_theme_color_override("font_focus_color", COLOR_INK)
	btn.add_theme_color_override("font_hover_pressed_color", COLOR_INK)
	
	# Check children for labels (used for custom handwriting look in some parts)
	for child in btn.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", COLOR_INK)
