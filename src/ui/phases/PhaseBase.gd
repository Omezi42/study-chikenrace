class_name PhaseBase
extends Control

signal phase_finished(data: Dictionary)

var session: GameSession
var smartphone_pane: Control
var notebook_pane: Control

# Virtual initialization method
func setup(p_session: GameSession, setup_data: Dictionary = {}) -> void:
	session = p_session
	_on_setup(setup_data)

# To be overridden by subclasses
func _on_setup(_setup_data: Dictionary) -> void:
	pass

# Helper to emit phase finished signal
func finish_phase(result_data: Dictionary = {}, next_phase: String = "") -> void:
	if next_phase != "":
		result_data["next_phase"] = next_phase
	phase_finished.emit(result_data)

func fit_control_to_viewport(node: Control, base_size: Vector2, margin: Vector2 = Vector2(48, 48), min_scale: float = 0.35, center: bool = true) -> float:
	if not node:
		return 1.0
	var viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0

	var available_size = viewport_size - margin
	var fit_scale = min(available_size.x / base_size.x, available_size.y / base_size.y)
	fit_scale = clamp(fit_scale, min_scale, 3.0)
	node.pivot_offset = Vector2.ZERO
	node.scale = Vector2.ONE * fit_scale
	if center:
		var actual_scaled_size = node.custom_minimum_size * fit_scale
		if actual_scaled_size == Vector2.ZERO:
			actual_scaled_size = base_size * fit_scale
		node.position = (viewport_size - actual_scaled_size) * 0.5
	return fit_scale

func show_tutorial_dialog(text: String, pos: Vector2 = Vector2.ZERO, next_callback: Callable = Callable()) -> Node:
	return Global.show_tutorial_dialog(self, text, pos, next_callback)

