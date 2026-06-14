extends Node

var canvas_layer: CanvasLayer

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 125  # Ensure it is drawn on top of most UI elements
	add_child(canvas_layer)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			spawn_effect(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			spawn_effect(event.position)

func spawn_effect(pos: Vector2) -> void:
	var effect = ClickEffect.new()
	effect.position = pos
	canvas_layer.add_child(effect)

# Custom Control node to draw the ripple effect
class ClickEffect extends Control:
	var radius: float = 0.0
	var max_radius: float = 40.0
	var alpha: float = 0.8
	# Ink blue color that fits a study/sketch theme
	var color: Color = Color("2b6cb0") 

	func _ready() -> void:
		# Start Tweens to animate ripple size and opacity
		var tween = create_tween().set_parallel(true)
		
		# Animate the outer ring radius
		tween.tween_property(self, "radius", max_radius, 0.35)\
			.set_trans(Tween.TRANS_LINEAR)\
			.set_ease(Tween.EASE_OUT)
			
		# Animate alpha to fade out
		tween.tween_property(self, "alpha", 0.0, 0.35)\
			.set_trans(Tween.TRANS_LINEAR)\
			.set_ease(Tween.EASE_OUT)
			
		# Queue free after tween completion
		tween.chain().tween_callback(queue_free)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var current_color = color
		current_color.a = alpha
		
		# Draw outer ripple circle outline
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, current_color, 2.5, true)
		
		# Draw inner solid soft circle with lower opacity
		var fill_color = current_color
		fill_color.a = alpha * 0.2
		draw_circle(Vector2.ZERO, radius * 0.7, fill_color)
		
		# Spawn minor ink drops/particles around
		var drop_color = current_color
		drop_color.a = alpha * 0.6
		
		# We can draw 3 static small dots that expand slightly outward
		var offsets = [
			Vector2(1.2, 0.8).normalized(),
			Vector2(-0.8, -1.2).normalized(),
			Vector2(-1.0, 1.0).normalized()
		]
		for offset in offsets:
			var dot_pos = offset * (radius * 0.9)
			draw_circle(dot_pos, 2.0 * (1.0 - (radius / max_radius)), drop_color)
