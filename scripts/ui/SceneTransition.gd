extends CanvasLayer

var cover_top: Panel
var cover_bottom: Panel

func _ready():
	layer = 128
	
	# 上の表紙 (教科書風バインダーカバー)
	cover_top = Panel.new()
	cover_top.anchor_left = 0.0
	cover_top.anchor_right = 1.0
	cover_top.anchor_top = 0.0
	cover_top.anchor_bottom = 0.0
	cover_top.offset_left = 0
	cover_top.offset_right = 0
	cover_top.offset_top = -540 # 初期化用（画面外）
	cover_top.offset_bottom = 0
	cover_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style_top = StyleBoxFlat.new()
	style_top.bg_color = Color("4b3621") # 高級感のある革製の教科書風ダークブラウン
	style_top.border_width_bottom = 8
	style_top.border_color = Color("c93d3d") # 金具の赤
	cover_top.add_theme_stylebox_override("panel", style_top)
	add_child(cover_top)
	
	# 下の表紙
	cover_bottom = Panel.new()
	cover_bottom.anchor_left = 0.0
	cover_bottom.anchor_right = 1.0
	cover_bottom.anchor_top = 1.0
	cover_bottom.anchor_bottom = 1.0
	cover_bottom.offset_left = 0
	cover_bottom.offset_right = 0
	cover_bottom.offset_top = 0
	cover_bottom.offset_bottom = 540 # 初期化用（画面外）
	cover_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style_bottom = StyleBoxFlat.new()
	style_bottom.bg_color = Color("4b3621")
	style_bottom.border_width_top = 8
	style_bottom.border_color = Color("c93d3d")
	cover_bottom.add_theme_stylebox_override("panel", style_bottom)
	add_child(cover_bottom)

func fade_to_scene(target_path: String, duration: float = 0.3):
	# ビューポートの高さを動的に取得してFHD(1080px)など任意の解像度に完全同期
	var half_height = get_viewport().get_visible_rect().size.y / 2.0
	
	# 開始前の位置を画面解像度に合わせて瞬時に再設定（隙間バグの完全解消）
	cover_top.offset_top = -half_height
	cover_top.offset_bottom = 0.0
	cover_bottom.offset_top = 0.0
	cover_bottom.offset_bottom = half_height
	
	cover_top.mouse_filter = Control.MOUSE_FILTER_STOP
	cover_bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween().set_parallel(true)
	# 画面中央でパタンと隙間なく閉じる (Tween時間 0.3秒でSnappyに！)
	tween.tween_property(cover_top, "offset_bottom", half_height, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(cover_bottom, "offset_top", -half_height, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	get_tree().change_scene_to_file(target_path)
	await get_tree().process_frame
	
	# シーン切り替え後、解像度が変わっている可能性を考慮して高さを再取得
	half_height = get_viewport().get_visible_rect().size.y / 2.0
	
	var tween_in = create_tween().set_parallel(true)
	# 画面外へパササッと軽快に開く
	tween_in.tween_property(cover_top, "offset_bottom", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween_in.tween_property(cover_bottom, "offset_top", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween_in.finished
	
	cover_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_out_in(callback: Callable, duration: float = 0.3):
	var half_height = get_viewport().get_visible_rect().size.y / 2.0
	
	cover_top.offset_top = -half_height
	cover_top.offset_bottom = 0.0
	cover_bottom.offset_top = 0.0
	cover_bottom.offset_bottom = half_height
	
	cover_top.mouse_filter = Control.MOUSE_FILTER_STOP
	cover_bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(cover_top, "offset_bottom", half_height, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(cover_bottom, "offset_top", -half_height, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	if callback.is_valid():
		callback.call()
	
	await get_tree().process_frame
	
	half_height = get_viewport().get_visible_rect().size.y / 2.0
	
	var tween_in = create_tween().set_parallel(true)
	tween_in.tween_property(cover_top, "offset_bottom", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween_in.tween_property(cover_bottom, "offset_top", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween_in.finished
	
	cover_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
