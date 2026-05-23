class_name ToastOverlay
extends RefCounted
## トースト通知（フローティングバッジ）を画面に表示するヘルパークラス。

static func show_toast(parent: Control, msg: String, color: Color = DeskTheme.COLOR_SAFE) -> void:
	if not is_instance_valid(parent):
		return
		
	# アナログ手触りな付箋トーストを生成 (Sprint 3)
	var rotation = randf_range(-4.0, 4.0)
	var sticky = DeskTheme.create_sticky_note(color, Vector2(340, 90), rotation)
	parent.add_child(sticky)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	sticky.add_child(margin)
	
	# インクカラーは暗めの色、白文字のコントラストを配慮
	var text_color = Color.WHITE if color.v < 0.6 else DeskTheme.COLOR_INK
	var lbl = DeskTheme.create_label(msg, 18, text_color, true)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(lbl)
	
	# サイズ確定後の位置調整
	var view_size = parent.get_viewport_rect().size
	if parent.size.x > 100:
		view_size = parent.size
		
	var start_pos = Vector2(view_size.x / 2.0 - 170, view_size.y * 0.75) # 画面下部にフッと滑り込む
	sticky.position = start_pos + Vector2(0, 100) # 開始位置は下
	sticky.modulate.a = 0.0
	sticky.pivot_offset = Vector2(170, 45)
	
	# 物理的にフッと舞い降りるスライドアニメーション (Sprint 3)
	var tw = sticky.create_tween().set_parallel(true)
	tw.tween_property(sticky, "position", start_pos, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sticky, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(sticky, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_CUBIC)
	
	var tw_bounce = sticky.create_tween()
	tw_bounce.tween_interval(0.15)
	tw_bounce.tween_property(sticky, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	var tw_fade = sticky.create_tween()
	tw_fade.tween_interval(2.2) # 少し長めに表示して読ませる
	tw_fade.tween_property(sticky, "modulate:a", 0.0, 0.35)
	tw_fade.tween_callback(sticky.queue_free)
