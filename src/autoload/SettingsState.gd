# SettingsState.gd
extends Node


signal settings_changed

var bgm_volume: float = 0.5
var se_volume: float = 0.5
var is_muted: bool = false
var use_handwriting_font: bool = true

func apply_settings() -> void:
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.bgm_volume = bgm_volume
		audio.se_volume = se_volume
		audio.is_muted = is_muted
	settings_changed.emit()

func save_data_to_dict() -> Dictionary:
	return {
		"bgm_volume": bgm_volume,
		"se_volume": se_volume,
		"is_muted": is_muted,
		"use_handwriting_font": use_handwriting_font
	}

func load_data_from_dict(data: Dictionary) -> void:
	if "bgm_volume" in data: bgm_volume = float(data["bgm_volume"])
	if "se_volume" in data: se_volume = float(data["se_volume"])
	if "is_muted" in data: is_muted = bool(data["is_muted"])
	if "use_handwriting_font" in data: use_handwriting_font = bool(data["use_handwriting_font"])
	apply_settings()
