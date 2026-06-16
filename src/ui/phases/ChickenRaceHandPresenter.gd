class_name ChickenRaceHandPresenter
extends RefCounted

var phase: ChickenRacePhase

func _init(p_phase: ChickenRacePhase) -> void:
	phase = p_phase

func repopulate_hand_visuals() -> void:
	for child in phase.hand_container.get_children():
		child.queue_free()
		
	phase.current_hand_cards.clear()
	var idx = 0
	for card in phase.session.player_deck.hand:
		phase.current_hand_cards.append(card)
		var card_ui = phase.create_card_visual(card)
		card_ui.set_meta("hand_index", idx)
		phase.hand_container.add_child(card_ui)
		idx += 1
		
	arrange_hand_fan()
	phase.update_active_effects_ui()

func arrange_hand_fan() -> void:
	var children = phase.hand_container.get_children()
	var count = children.size()
	if count == 0:
		return
		
	var max_arc = 24.0 # degrees
	var step_angle = max_arc / max(1, count - 1)
	var radius = 350.0
	
	var center_x = phase.hand_container.custom_minimum_size.x / 2.0
	var base_y = 20.0
	
	for idx in range(count):
		var child = children[idx] as Control
		var angle_offset = -max_arc / 2.0 + idx * step_angle
		if count == 1:
			angle_offset = 0.0
			
		var rad = deg_to_rad(angle_offset)
		var offset_x = radius * sin(rad)
		var offset_y = -radius * (1.0 - cos(rad))
		
		var scale_mult = 1.0
		if count > 5:
			scale_mult = clamp(1.0 - (count - 5) * 0.08, 0.65, 1.0)
		child.set_meta("fan_scale", scale_mult)
		child.set_meta("fan_rotation", angle_offset)
		child.set_meta("fan_position", Vector2(center_x + offset_x - (child.custom_minimum_size.x * scale_mult) / 2.0, base_y + offset_y))
		child.scale = Vector2.ONE * scale_mult
		child.rotation_degrees = angle_offset
		child.position = child.get_meta("fan_position", Vector2(center_x, base_y))

func _on_card_ui_pressed(card: Dictionary, card_ui: Button) -> void:
	if phase.is_animating or card_ui.is_queued_for_deletion() or card_ui.disabled:
		return
	if phase.is_selecting_card:
		card_ui.disabled = true
		var hand_idx = card_ui.get_meta("hand_index", -1)
		if hand_idx != -1:
			phase._on_card_selected_from_hand(hand_idx, card)
	else:
		phase.show_card_detail(card)

func _on_card_ui_mouse_entered(card: Dictionary, card_ui: Button) -> void:
	if phase.hovered_card_ui and phase.hovered_card_ui != card_ui:
		_clear_hovered_card()
	phase.hovered_card_ui = card_ui
	if not phase.is_selecting_card:
		phase.show_card_detail(card)
	
	card_ui.z_index = 10
	if is_instance_valid(phase.hovered_card_tween):
		phase.hovered_card_tween.kill()
	
	var tween = phase.create_tween().bind_node(card_ui).set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	phase.hovered_card_tween = tween
	var scale_mult = 1.15 if phase.is_selecting_card else 1.12
	var base_scale = float(card_ui.get_meta("fan_scale", 1.0))
	var base_pos = card_ui.get_meta("fan_position", card_ui.position)
	var base_rot = float(card_ui.get_meta("fan_rotation", card_ui.rotation_degrees))
	tween.tween_property(card_ui, "scale", Vector2.ONE * (base_scale * scale_mult), 0.12 / phase.speed_mult)
	
	var lift_y = -35 if phase.is_selecting_card else -25
	tween.tween_property(card_ui, "position", base_pos + Vector2(0, lift_y), 0.12 / phase.speed_mult)
	tween.tween_property(card_ui, "rotation_degrees", base_rot, 0.12 / phase.speed_mult)
	
	if phase.is_selecting_card:
		card_ui.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_card_ui_mouse_exited(card_ui: Button) -> void:
	if phase.hovered_card_ui == card_ui:
		if is_instance_valid(phase.hovered_card_tween):
			phase.hovered_card_tween.kill()
		phase.hovered_card_tween = null
		phase.hovered_card_ui = null
	phase.show_card_detail({})
	
	_reset_hovered_card(card_ui)

func _reset_hovered_card(card_ui: Button) -> void:
	if not card_ui:
		return
	card_ui.z_index = 0
	card_ui.modulate = Color.WHITE
	
	var base_scale = float(card_ui.get_meta("fan_scale", 1.0))
	var base_rot = float(card_ui.get_meta("fan_rotation", 0.0))
	var base_pos = card_ui.get_meta("fan_position", card_ui.position)
	
	var tween = phase.create_tween().bind_node(card_ui).set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_ui, "scale", Vector2.ONE * base_scale, 0.12 / phase.speed_mult)
	tween.tween_property(card_ui, "rotation_degrees", base_rot, 0.12 / phase.speed_mult)
	tween.tween_property(card_ui, "position", base_pos, 0.12 / phase.speed_mult)

func _clear_hovered_card() -> void:
	if is_instance_valid(phase.hovered_card_tween):
		phase.hovered_card_tween.kill()
	phase.hovered_card_tween = null
	if phase.hovered_card_ui:
		_reset_hovered_card(phase.hovered_card_ui)
		phase.hovered_card_ui = null
	phase.show_card_detail({})
	arrange_hand_fan()
