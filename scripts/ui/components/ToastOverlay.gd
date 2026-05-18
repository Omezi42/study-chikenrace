class_name ToastOverlay
extends RefCounted
## トースト通知（フローティングバッジ）を画面に表示するヘルパークラス。

static func show_toast(parent: Control, msg: String, color: Color = DeskTheme.COLOR_INK) -> void:
	if not is_instance_valid(parent):
		return
		
	var toast = DeskTheme.create_floating_badge(msg, color, 16)
	parent.add_child(toast)
	
	# サイズ確定後の位置調整のため微小なディレイを挟むか、手動で仮調整
	var view_size = parent.get_viewport_rect().size
	# parentが画面全体に広がっていない可能性も考慮
	if parent.size.x > 100:
		view_size = parent.size
		
	toast.position = Vector2(view_size.x / 2.0 - toast.size.x / 2.0, view_size.y / 2.0)
	
	# おもちゃ感のあるアニメーション
	var tw = toast.create_tween()
	tw.tween_property(toast, "position:y", toast.position.y - 50, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.5)
	tw.tween_property(toast, "modulate:a", 0.0, 0.3)
	tw.tween_callback(toast.queue_free)
