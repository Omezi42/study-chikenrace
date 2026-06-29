# -*- coding: utf-8 -*-
# 画面サイズや画面向きに応じて全UIのスケールを管理するAutoloadサービス
extends Node

# デザイン基準サイズ（GameScene.custom_minimum_size）をモバイル縦画面に合わせる
const DESIGN_WIDTH: float = 540.0
const DESIGN_HEIGHT: float = 960.0

signal scale_changed(new_scale: float)
signal orientation_changed(is_portrait: bool)

var current_scale: float = 1.0
var _last_is_portrait: bool = false

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_last_is_portrait = is_portrait()
	_update_scale()

func _on_viewport_size_changed() -> void:
	_update_scale()
	var current_portrait = is_portrait()
	if current_portrait != _last_is_portrait:
		_last_is_portrait = current_portrait
		orientation_changed.emit(current_portrait)

func is_portrait() -> bool:
	var viewport = get_viewport()
	if not viewport:
		return false
	var size = viewport.get_visible_rect().size
	return size.x < size.y

func get_viewport_size() -> Vector2:
	var viewport = get_viewport()
	if not viewport:
		return Vector2(1920, 1080)
	var size = viewport.get_visible_rect().size
	if size.x == 0 or size.y == 0:
		return Vector2(1920, 1080)
	return size

func fit_scale_for_size(target_size: Vector2, margin: Vector2 = Vector2(40, 40), min_scale: float = 0.35) -> float:
	var vp_size = get_viewport_size()
	var avail_w = max(vp_size.x - margin.x, 100.0)
	var avail_h = max(vp_size.y - margin.y, 100.0)
	var scale_w = avail_w / target_size.x
	var scale_h = avail_h / target_size.y
	var s = min(scale_w, scale_h)
	return clamp(s, min_scale, 3.0)

func _update_scale() -> void:
	var viewport = get_viewport()
	if not viewport:
		return
		
	var visible = viewport.get_visible_rect()
	var vp_w = visible.size.x
	var vp_h = visible.size.y
	
	if vp_w <= 0 or vp_h <= 0:
		return
	
	# Letterbox: 小さい方に合わせてスケール決定（デザインがはみ出さない）
	var ratio_w = vp_w / DESIGN_WIDTH
	var ratio_h = vp_h / DESIGN_HEIGHT
	var new_scale = min(ratio_w, ratio_h)
	
	new_scale = clamp(new_scale, 0.35, 3.0)
	
	if abs(new_scale - current_scale) > 0.002:
		var old_scale = current_scale
		current_scale = new_scale
		scale_changed.emit(current_scale)

func get_scale() -> float:
	return current_scale

func real_size(design_px: float) -> float:
	return design_px * current_scale

func adaptive_font_size(base: int, min_size: int = 12) -> int:
	return int(clamp(base * current_scale, min_size, base))

# テストプレイ用ショートカット: F1キーでPC横画面とスマホ縦画面をワンタッチ切り替え
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			toggle_test_window_size()

func toggle_test_window_size() -> void:
	var win = get_window()
	if not win:
		return
	var cur_size = win.size
	if cur_size.x > cur_size.y:
		# スマホ縦画面解像度に変更
		win.size = Vector2i(540, 960)
	else:
		# PC横画面解像度に戻す
		win.size = Vector2i(1500, 850)
		
	if not win.is_embedded():
		var screen_size = DisplayServer.screen_get_size()
		win.position = (screen_size - win.size) / 2
