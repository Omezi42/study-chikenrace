# scripts/ui/phases/DailyLikesPhase.gd
class_name DailyLikesPhase
extends RefCounted
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")


signal phase_completed()

var ctx: RefCounted

func _init(context: RefCounted):
	self.ctx = context

func start():
	_trigger_daily_likes_sequence()

func _trigger_daily_likes_sequence():
	if Global.play_count == 0:
		phase_completed.emit()
		return
		
	if ctx.bag_ui_elements.get("bonus_given_done", false):
		phase_completed.emit()
		return
		
	ctx.bag_ui_elements["bonus_given_done"] = true
	
	# A. 前日の王座（日次トップ）配当の付与
	if Global.last_top_subjects.size() > 0:
		var bonus_earned = 0
		var bonus_text = ""
		for s in Global.last_top_subjects:
			bonus_earned += 5
			bonus_text += " " + DeskTheme.subject_name(s)
		if bonus_earned > 0:
			Global.total_score += bonus_earned
			ToastOverlayScript.show_toast(ctx.ui_root, "日次トップ配当＋%d点！ (王座: %s)" % [bonus_earned, bonus_text], DeskTheme.COLOR_ACCENT_GOLD)
			if ctx.audio_manager: ctx.audio_manager.play_se("combo")
			await ctx.screen_content.get_tree().create_timer(1.2).timeout
			
	# B. 全体報告に対する「いいね」被弾判定（1回の大きなスタンプ！）
	var score_changed = false
	var lie_diff_total = 0
	var modest_diff_total = 0
	
	for s in range(5):
		var actual = Global.last_actual_scores.get(s, 0)
		var reported = Global.last_reported_scores.get(s, 0)
		if reported > actual: lie_diff_total += (reported - actual)
		elif reported < actual: modest_diff_total += (actual - reported)
		
	# ターゲット（ノートパネル全体を揺らす）
	var note_panel_node = null
	for c in ctx.screen_content.get_children():
		if c is PanelContainer:
			note_panel_node = c
			break
			
	if note_panel_node == null: note_panel_node = ctx.screen_content
	
	await ctx.screen_content.get_tree().create_timer(0.5).timeout
	
	if lie_diff_total > 0:
		# 1. 嘘報告だった場合の「見破り」判定（50%の確率）
		if randf() < 0.5:
			score_changed = true
			var penalty = lie_diff_total * 2
			Global.total_score = max(0, Global.total_score - penalty)
			
			var stamp = DeskTheme.create_app_stamp("見破り！", DeskTheme.COLOR_BLUFF_RED, 28)
			stamp.position = note_panel_node.size / 2.0 - stamp.size / 2.0
			note_panel_node.add_child(stamp)
			stamp.pivot_offset = stamp.size / 2.0
			stamp.scale = Vector2(4.0, 4.0)
			stamp.modulate.a = 0.0
			var tw = stamp.create_tween().set_parallel(true)
			tw.tween_property(stamp, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_property(stamp, "modulate:a", 1.0, 0.08)
			tw.tween_property(stamp, "rotation_degrees", randf_range(-15.0, 15.0), 0.15)
			if ctx.audio_manager: ctx.audio_manager.play_se("burst")
			ToastOverlayScript.show_toast(ctx.ui_root, "【見破り】嘘の報告がバレた！\n(偽造合計%d点 × 2) −%d点！" % [lie_diff_total, penalty], DeskTheme.COLOR_BLUFF_RED)
			
			var s_tw = note_panel_node.create_tween()
			s_tw.tween_property(note_panel_node, "position:y", note_panel_node.position.y + 8, 0.06)
			s_tw.tween_property(note_panel_node, "position:y", note_panel_node.position.y - 8, 0.06)
			s_tw.tween_property(note_panel_node, "position:y", note_panel_node.position.y, 0.06)
	elif modest_diff_total > 0:
		# 3. 謙虚報告だった場合の「応援」判定（50%の確率）
		if randf() < 0.5:
			score_changed = true
			var modest_bonus = 10 + modest_diff_total * 3
			Global.total_score += modest_bonus
			
			var stamp = DeskTheme.create_app_stamp("応援！", DeskTheme.COLOR_SAFE, 28)
			stamp.position = note_panel_node.size / 2.0 - stamp.size / 2.0
			note_panel_node.add_child(stamp)
			stamp.pivot_offset = stamp.size / 2.0
			stamp.scale = Vector2(4.0, 4.0)
			stamp.modulate.a = 0.0
			var tw = stamp.create_tween().set_parallel(true)
			tw.tween_property(stamp, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_property(stamp, "modulate:a", 1.0, 0.08)
			tw.tween_property(stamp, "rotation_degrees", randf_range(-15.0, 15.0), 0.15)
			if ctx.audio_manager: ctx.audio_manager.play_se("combo")
			ToastOverlayScript.show_toast(ctx.ui_root, "【謙虚応援】控えめな報告にいいね！\nボーナス (基本10＋差分%d点×3): ＋%d点！" % [modest_diff_total, modest_bonus], DeskTheme.COLOR_SAFE)
			
			var s_tw = note_panel_node.create_tween()
			s_tw.tween_property(note_panel_node, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_CUBIC)
			s_tw.tween_property(note_panel_node, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
	else:
		# 2. 正直報告だった場合の「応援」判定（50%の確率）
		if randf() < 0.5:
			score_changed = true
			Global.total_score += 10 # 正直ボーナスを少し強化
			
			var stamp = DeskTheme.create_app_stamp("応援！", DeskTheme.COLOR_SAFE, 28)
			stamp.position = note_panel_node.size / 2.0 - stamp.size / 2.0
			note_panel_node.add_child(stamp)
			stamp.pivot_offset = stamp.size / 2.0
			stamp.scale = Vector2(4.0, 4.0)
			stamp.modulate.a = 0.0
			var tw = stamp.create_tween().set_parallel(true)
			tw.tween_property(stamp, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_property(stamp, "modulate:a", 1.0, 0.08)
			tw.tween_property(stamp, "rotation_degrees", randf_range(-15.0, 15.0), 0.15)
			if ctx.audio_manager: ctx.audio_manager.play_se("combo")
			ToastOverlayScript.show_toast(ctx.ui_root, "【応援】正直な努力にいいね！ ＋10点！", DeskTheme.COLOR_SAFE)
			
			var s_tw = note_panel_node.create_tween()
			s_tw.tween_property(note_panel_node, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_CUBIC)
			s_tw.tween_property(note_panel_node, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
			
	# 変化があった場合のみHUD（合計スコア）を再更新し、データを即保存
	if score_changed:
		Global.save_data()
		
	# 演出の余韻待ち
	await ctx.screen_content.get_tree().create_timer(1.0).timeout
	
	phase_completed.emit()