# scripts/ui/phases/DailyLikesPhase.gd
class_name DailyLikesPhase
extends RefCounted

const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")

signal phase_completed()

var ctx: RefCounted
var phone_node: Control
var next_day_btn: Button

func _init(context: RefCounted):
	self.ctx = context

func start():
	# AIの他プレイヤーへのいいね（ダウト）投票シミュレーションを実行
	if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.ai_manager:
		ctx.game_session.ai_manager.simulate_ai_votes(Global.play_count)
	
	_show_daily_likes_screen()

func _show_daily_likes_screen():
	# 画面クリア
	for child in ctx.screen_content.get_children():
		child.queue_free()
	
	# 左側にスマホを配置したUI (build_standard_smartphoneはcreate_mockup(ctx, false)で左側に配置される)
	var app_container = SmartphoneBuilderScript.build_standard_smartphone(ctx)
	phone_node = ctx.bag_ui_elements.get("report_page")
	if is_instance_valid(phone_node):
		# ズームロックを設定（勝手にしまえないように）
		phone_node.set_meta("lock_zoom", true)
		# タイムラインを強制的にズームイン状態のサイズ・位置にして見やすくする
		phone_node.position = Vector2(80, 100)
		phone_node.scale = Vector2(1.2, 1.2)
		phone_node.rotation_degrees = 0.0
	
	# 右側に「明日の勉強へ進む」ボタンを配置
	next_day_btn = DeskTheme.create_button("明日の勉強へ進む", Vector2(320, 64), DeskTheme.COLOR_SAFE, Color("0e5057"))
	next_day_btn.anchor_left = 1.0
	next_day_btn.anchor_top = 1.0
	next_day_btn.offset_left = -450
	next_day_btn.offset_top = -200
	next_day_btn.pivot_offset = Vector2(160, 32)
	ctx.screen_content.add_child(next_day_btn)
	
	next_day_btn.pressed.connect(func(): _on_next_day_pressed())
	
	# ボタンのインタラクションアニメーション
	next_day_btn.mouse_entered.connect(func():
		var tw = next_day_btn.create_tween()
		tw.tween_property(next_day_btn, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
	)
	next_day_btn.mouse_exited.connect(func():
		var tw = next_day_btn.create_tween()
		tw.tween_property(next_day_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)

func _on_next_day_pressed():
	if ctx.audio_manager: ctx.audio_manager.play_se("click")
	
	# スマホとボタンを退場させるアニメーション
	var tw = ctx.screen_content.create_tween().set_parallel(true)
	if is_instance_valid(phone_node):
		tw.tween_property(phone_node, "position:y", 1200, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(phone_node, "scale", Vector2(0.5, 0.5), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if is_instance_valid(next_day_btn):
		tw.tween_property(next_day_btn, "modulate:a", 0.0, 0.3)
	
	await tw.finished
	phase_completed.emit()