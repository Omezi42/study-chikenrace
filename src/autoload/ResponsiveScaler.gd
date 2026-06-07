# -*- coding: utf-8 -*-
# Loop 16追加: P1/P2 レスポンシブ対応
# 画面サイズに応じて全UIのスケールを管理するAutoloadサービス
class_name ResponsiveScaler
extends Node

# デザイン基準サイズ（GameScene.custom_minimum_size）
const DESIGN_WIDTH: float = 1500.0
const DESIGN_HEIGHT: float = 850.0

# |scale_changed| = (new_scale: float) — スケール変動時に全購読者に通知
signal scale_changed(new_scale: float)

var current_scale: float = 1.0

func _ready() -> void:
	# 画面サイズ変更時にスケールを再計算
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_update_scale()

func _on_viewport_size_changed() -> void:
	_update_scale()

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
	
	# 最小0.4〜最大1.0にクランプ
	new_scale = clamp(new_scale, 0.4, 1.0)
	
	if abs(new_scale - current_scale) > 0.002:
		var old_scale = current_scale
		current_scale = new_scale
		scale_changed.emit(current_scale)
		print_debug("[ResponsiveScaler] Scale: %.3f -> %.3f (viewport: %.0fx%.0f)" % [old_scale, current_scale, vp_w, vp_h])

# デザイン基準サイズ比を返す（フォントサイズやマージンのスケーリング用）
func get_scale() -> float:
	return current_scale

# デザイン上の pixel 値を実際の画面 pixel 値に変換
func real_size(design_px: float) -> float:
	return design_px * current_scale

# アダプティブフォントサイズを返す（最低12px、最大はbase_size）
func adaptive_font_size(base: int, min_size: int = 12) -> int:
	return int(clamp(base * current_scale, min_size, base))
