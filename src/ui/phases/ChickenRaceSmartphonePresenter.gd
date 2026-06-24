class_name ChickenRaceSmartphonePresenter
extends RefCounted

var phase: ChickenRacePhase

func _init(p_phase: ChickenRacePhase) -> void:
	phase = p_phase

func update_ui() -> void:
	# Update nothing since we simplified the UI
	pass

func update_member_badge_ui(player_id: String) -> void:
	pass
