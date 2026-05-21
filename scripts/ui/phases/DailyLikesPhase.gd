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
	
	# 日次の即時暴露や教科ごとのトップ配当は廃止され、すべて最終日答え合わせで処理されます。
	phase_completed.emit()