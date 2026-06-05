# -*- coding: utf-8 -*-
extends Node

var config: Dictionary = {}

func _ready() -> void:
	_load_config()

func _load_config() -> void:
	var path = "res://data/balance_config.json"
	if not FileAccess.file_exists(path):
		push_warning("balance_config.json not found, using defaults.")
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			config = json.get_data()
		file.close()

func get_value(key_path: String, default_value: Variant = null) -> Variant:
	var keys = key_path.split(".")
	var current = config
	for key in keys:
		if current is Dictionary and current.has(key):
			current = current[key]
		else:
			return default_value
	return current
