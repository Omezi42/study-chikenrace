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
			
	# B. 日次の即時暴露は廃止され、すべて最終日答え合わせで処理されます。
	phase_completed.emit()