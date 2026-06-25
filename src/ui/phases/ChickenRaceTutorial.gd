class_name ChickenRaceTutorial
extends RefCounted

var phase: ChickenRacePhase
var tutorial_step: int = 0
var tutorial_dialog_node: PanelContainer = null
var current_hour: int = 1

# ハイライト管理用
var active_tweens: Array[Tween] = []
var restored_nodes: Dictionary = {}

func _init(p_phase: ChickenRacePhase) -> void:
	phase = p_phase

func highlight(node: Control) -> void:
	if not node or not node.is_inside_tree():
		return
	if not restored_nodes.has(node):
		restored_nodes[node] = {
			"scale": node.scale,
			"modulate": node.modulate
		}
	var tween = DeskTheme.flash_highlight(node)
	if tween:
		active_tweens.append(tween)

func clear_highlights() -> void:
	for tween in active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()
	
	for node in restored_nodes.keys():
		if is_instance_valid(node):
			node.scale = restored_nodes[node]["scale"]
			node.modulate = restored_nodes[node]["modulate"]
	restored_nodes.clear()

func start() -> void:
	tutorial_step = 0
	current_hour = 1
	phase.stop_btn.disabled = true
	phase.draw_btn.disabled = true
	
	clear_highlights()
	DeskTheme.show_toast(phase, "チュートリアルへようこそ！", 2.5, DeskTheme.COLOR_GREEN)
	
	var viewport_size = phase.get_viewport_rect().size
	var dialog_pos = Vector2(viewport_size.x * 0.58, viewport_size.y * 0.08)
	
	var t = phase.get_tree().create_timer(0.2)
	t.timeout.connect(func():
		tutorial_dialog_node = phase.show_tutorial_dialog(
			"勉強カードを引くと、数字がそのまま得点になります。このゲームでは『数字が大きいカードほど山札に多く入っていて引きやすい』のが特徴です。まずは1枚引いてみましょう。",
			dialog_pos
		)
		phase.draw_btn.disabled = false
		highlight(phase.draw_btn)
	)

func start_hour_2() -> void:
	tutorial_step = 0
	current_hour = 2
	phase.stop_btn.disabled = true
	phase.draw_btn.disabled = true
	
	clear_highlights()
	
	var viewport_size = phase.get_viewport_rect().size
	var dialog_pos = Vector2(viewport_size.x * 0.58, viewport_size.y * 0.08)
	
	tutorial_dialog_node = phase.show_tutorial_dialog(
		"第2時限目です。今度はもう少し枚数を引いて、高得点（10点以上）を狙ってみましょう！まずはカードを引いてください。",
		dialog_pos
	)
	phase.draw_btn.disabled = false
	highlight(phase.draw_btn)

func start_hour_3() -> void:
	tutorial_step = 0
	current_hour = 3
	phase.stop_btn.disabled = true
	phase.draw_btn.disabled = true
	
	clear_highlights()
	
	var viewport_size = phase.get_viewport_rect().size
	var dialog_pos = Vector2(viewport_size.x * 0.58, viewport_size.y * 0.08)
	
	tutorial_dialog_node = phase.show_tutorial_dialog(
		"最後の時限です。すでに手札にある数字と同じ数字を引き直すと『寝落ち（バースト）』になり、その時限は0点になります。まずは1枚引いてみましょう。",
		dialog_pos
	)
	phase.draw_btn.disabled = false
	highlight(phase.draw_btn)

func advance_step() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
		
	clear_highlights()
	tutorial_step += 1
	
	var viewport_size = phase.get_viewport_rect().size
	var dialog_pos = Vector2(viewport_size.x * 0.58, viewport_size.y * 0.08)
	
	if current_hour == 1:
		match tutorial_step:
			1:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"5点のカードを引きました！山札には『5』が5枚、『10』は10枚も入っています。数字が大きいほど高得点を狙えますが、同じ数字を引き直して寝落ち（0点）になる確率も上がります。もう1枚引いてみましょう。",
					dialog_pos
				)
				highlight(phase.draw_btn)
			2:
				phase.draw_btn.disabled = true 
				phase.stop_btn.disabled = false 
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"合計9点になりました！これ以上引いて同じ数字が出ると0点になってしまいます。安全のために『休憩』を押して得点を確定させましょう。",
					dialog_pos
				)
				highlight(phase.stop_btn)
	elif current_hour == 2:
		match tutorial_step:
			1:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"6点です。まだまだ安全に伸ばせます。もう1枚引きましょう！",
					dialog_pos
				)
				highlight(phase.draw_btn)
			2:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"合計9点になりました。いい調子！さらにもう1枚攻めてみましょう。",
					dialog_pos
				)
				highlight(phase.draw_btn)
			3:
				phase.draw_btn.disabled = true 
				phase.stop_btn.disabled = false 
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"合計13点になりました！素晴らしい高得点です。寝落ちする前に『休憩』して時限を終えましょう。",
					dialog_pos
				)
				highlight(phase.stop_btn)
	elif current_hour == 3:
		match tutorial_step:
			1:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"7点のカードです。山札に『7』は多く入っているため、引き直して寝落ちする危険が高いです！リスクを知るため、あえてもう一度引いて寝落ちを体験してみましょう。",
					dialog_pos
				)
				highlight(phase.draw_btn)

func on_burst_triggered() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
	clear_highlights()
	DeskTheme.show_toast(phase, "寝落ち（バースト）してしまい、この時限は0点になりました！欲張りすぎには注意しましょう。", 3.5, DeskTheme.COLOR_TENSION)

func cleanup() -> void:
	clear_highlights()
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null

