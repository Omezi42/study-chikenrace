class_name PageFlipButton
extends Button

# Properties
@export var is_next: bool = true

# Animation states
var hover_progress: float = 0.0
var press_progress: float = 0.0

func _ready() -> void:
	# Enable custom drawing and remove default background/borders
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Empty styles for all states to prevent default hover/pressed visuals
	var empty = StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", empty)
	
	# Connect interaction signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_mouse_entered() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "hover_progress", 1.0, 0.2)
	tween.tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.2)

func _on_mouse_exited() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "hover_progress", 0.0, 0.2)
	tween.tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.2)

func _on_button_down() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "press_progress", 1.0, 0.1)
	tween.tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.1)

func _on_button_up() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "press_progress", 0.0, 0.1)
	tween.tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.1)

func _draw() -> void:
	var w = size.x
	var h = size.y
	
	# Calculate visual offsets based on hover/press animations
	# Hover lifts it up/sideways slightly, press squishes it
	var base_scale = 1.0 + (hover_progress * 0.12) - (press_progress * 0.1)
	var rotation_angle = (hover_progress * 5.0) if is_next else (hover_progress * -5.0)
	var alpha = lerpf(0.65, 1.0, hover_progress)
	
	# Apply transform for smooth animation of the drawn elements
	draw_set_transform(
		Vector2(w / 2.0, h / 2.0),
		deg_to_rad(rotation_angle),
		Vector2(base_scale, base_scale)
	)
	
	# Ink color with dynamic opacity matching study game style
	var draw_color = DeskTheme.COLOR_INK
	draw_color.a = alpha
	
	# Line thickness increases slightly on hover
	var line_width = lerpf(3.0, 4.5, hover_progress)
	
	# Draw curved arrow using quadratic bezier curve
	# The curve arches upward over the character
	var start: Vector2
	var control: Vector2
	var end: Vector2
	
	# Relative positions mapped around center (0,0)
	if is_next:
		start = Vector2(-35, -10)
		control = Vector2(0, -35)
		end = Vector2(35, -10)
	else:
		start = Vector2(35, -10)
		control = Vector2(0, -35)
		end = Vector2(-35, -10)
		
	var points = PackedVector2Array()
	var steps = 16
	for i in range(steps + 1):
		var t = float(i) / steps
		var pt = _get_bezier_point(start, control, end, t)
		points.append(pt)
		
	# Draw the curve line
	draw_polyline(points, draw_color, line_width, true)
	
	# Draw Arrowhead (arrow pointing direction)
	# Derivative at end point gives the tangent vector
	var tangent = _get_bezier_tangent(start, control, end, 1.0).normalized()
	var arrow_len = 12.0
	var arrow_angle = deg_to_rad(30.0) # Angle of arrowhead wings
	
	# Left and Right wings of the arrowhead pointing backwards from tangent
	var wing1 = -tangent.rotated(arrow_angle) * arrow_len
	var wing2 = -tangent.rotated(-arrow_angle) * arrow_len
	
	draw_line(end, end + wing1, draw_color, line_width, true)
	draw_line(end, end + wing2, draw_color, line_width, true)
	
	# Draw Kanji Text ("次へ" or "戻る") below the arrow
	var font = DeskTheme.get_font()
	if font == null:
		font = get_theme_font("font")
	var text = "次へ" if is_next else "戻る"
	var text_size = 28
	
	# Centered below the curve
	var text_pos = Vector2(0, 24)
	
	# Draw string centered
	var text_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, text_size).x
	var font_h = font.get_height(text_size)
	var draw_pos = text_pos + Vector2(-text_w / 2.0, font_h / 4.0)
	
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, text_size, draw_color)

func _get_bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var omt = 1.0 - t
	return omt * omt * p0 + 2.0 * omt * t * p1 + t * t * p2

func _get_bezier_tangent(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return 2.0 * (1.0 - t) * (p1 - p0) + 2.0 * t * (p2 - p1)
