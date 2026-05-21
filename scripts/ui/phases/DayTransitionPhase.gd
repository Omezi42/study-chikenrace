# scripts/ui/phases/DayTransitionPhase.gd
class_name DayTransitionPhase
extends RefCounted

signal phase_completed()

var ctx: RefCounted

func _init(context: RefCounted):
	self.ctx = context

func start():
	_show_day_transition()

func _show_day_transition():
	for child in ctx.screen_content.get_children():
		child.queue_free()
	
	# 暗転フェードとカレンダーパネルの生成
	var overlay = ColorRect.new()
	overlay.color = Color("1e1c19") # 木製デスクに合うダークブラウン
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctx.screen_content.add_child(overlay)
	
	var cal_panel = PanelContainer.new()
	cal_panel.custom_minimum_size = Vector2(320, 360)
	var cal_style = StyleBoxFlat.new()
	cal_style.bg_color = Color("faf8f5") # 紙の白
	cal_style.border_width_left = 6; cal_style.border_width_right = 6
	cal_style.border_width_top = 24; cal_style.border_width_bottom = 8 # 日めくり金具の赤を上部に
	cal_style.border_color = Color("c93d3d") # 金具の赤
	cal_style.corner_radius_top_left = 12; cal_style.corner_radius_top_right = 12
	cal_style.corner_radius_bottom_left = 12; cal_style.corner_radius_bottom_right = 12
	cal_style.shadow_color = Color(0, 0, 0, 0.3)
	cal_style.shadow_size = 16
	cal_panel.add_theme_stylebox_override("panel", cal_style)
	cal_panel.anchor_left = 0.5; cal_panel.anchor_top = 0.5; cal_panel.anchor_right = 0.5; cal_panel.anchor_bottom = 0.5
	cal_panel.offset_left = -160; cal_panel.offset_top = -180; cal_panel.offset_right = 160; cal_panel.offset_bottom = 180
	overlay.add_child(cal_panel)
	
	var cal_v = VBoxContainer.new()
	cal_v.alignment = BoxContainer.ALIGNMENT_CENTER
	cal_v.add_theme_constant_override("separation", 16)
	DeskTheme.apply_font(cal_v)
	cal_panel.add_child(cal_v)
	
	cal_v.add_child(DeskTheme.create_label("Day", 24, DeskTheme.COLOR_MUTED, true))
	
	# 前の日付を表示
	var day_lbl = DeskTheme.create_label(str(Global.play_count), 96, Color("d94040"), true)
	day_lbl.add_theme_font_size_override("font_size", 96)
	cal_v.add_child(day_lbl)
	
	# 前日スコアサマリー
	var last_total = Global.last_reported_score
	if last_total > 0:
		cal_v.add_child(DeskTheme.create_label("本日の成果: %d点獲得！" % last_total, 14, DeskTheme.COLOR_SAFE, true))
	else:
		cal_v.add_child(DeskTheme.create_label("放課後のテスト勉強が終了しました...", 14, DeskTheme.COLOR_MUTED, true))
	
	# 残り日数
	var remaining = 7 - Global.play_count
	if remaining > 0:
		var remain_color = DeskTheme.COLOR_BLUFF_RED if remaining <= 2 else DeskTheme.COLOR_ACCENT_GOLD if remaining <= 4 else DeskTheme.COLOR_MUTED
		var remain_text = "あと%d日！" % remaining if remaining > 1 else "明日が最終日！"
		cal_v.add_child(DeskTheme.create_label(remain_text, 16, remain_color, true))
	
	# ぽよんと登場
	cal_panel.pivot_offset = cal_panel.size / 2.0
	cal_panel.scale = Vector2(0.3, 0.3)
	var tw = cal_panel.create_tween()
	tw.tween_property(cal_panel, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if ctx.audio_manager: ctx.audio_manager.play_se("place")
	await tw.finished
	await ctx.screen_content.get_tree().create_timer(0.6).timeout
	
	# カレンダーめくりアニメーション
	if ctx.audio_manager: ctx.audio_manager.play_se("draw") # ペラッ音
	var rip_tw = cal_panel.create_tween()
	rip_tw.set_parallel(true)
	# 破れて右上にシュルシュルと飛んで消える！
	rip_tw.tween_property(cal_panel, "position", cal_panel.position + Vector2(300, -500), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	rip_tw.tween_property(cal_panel, "rotation_degrees", 45.0, 0.45).set_trans(Tween.TRANS_SINE)
	rip_tw.tween_property(cal_panel, "scale", Vector2(0.2, 0.2), 0.45)
	await rip_tw.finished
	
	# 新しい日付のカレンダーが現れる！
	var new_cal = cal_panel.duplicate() as PanelContainer
	overlay.add_child(new_cal)
	var new_v = new_cal.get_child(0) as VBoxContainer
	var new_day_lbl = new_v.get_child(1) as Label
	new_day_lbl.text = str(Global.play_count + 1)
	new_cal.position = overlay.size / 2.0 - new_cal.custom_minimum_size / 2.0
	new_cal.pivot_offset = new_cal.custom_minimum_size / 2.0
	new_cal.scale = Vector2(0.2, 0.2)
	new_cal.rotation_degrees = -30.0
	
	var new_tw = new_cal.create_tween()
	new_tw.set_parallel(true)
	new_tw.tween_property(new_cal, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	new_tw.tween_property(new_cal, "rotation_degrees", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	if ctx.audio_manager: ctx.audio_manager.play_se("combo")
	await new_tw.finished
	await ctx.screen_content.get_tree().create_timer(0.8).timeout
	
	# 暗転を解除してカバン構築画面へ
	var fade_tw = overlay.create_tween()
	fade_tw.tween_property(overlay, "modulate:a", 0.0, 0.25)
	await fade_tw.finished
	overlay.queue_free()
	
	phase_completed.emit()
