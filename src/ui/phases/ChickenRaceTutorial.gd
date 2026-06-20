class_name ChickenRaceTutorial
extends RefCounted

var phase: ChickenRacePhase
var tutorial_step: int = 0
var tutorial_dialog_node: PanelContainer = null
var current_hour: int = 1

# ハイライト管理用
var active_tweens: Array[Tween] = []
var restored_nodes: Dictionary = {} # node -> { "scale": Vector2, "modulate": Color }

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
	var dialog_pos = Vector2(viewport_size.x * 0.6, viewport_size.y * 0.08)
	
	var t = phase.get_tree().create_timer(0.2)
	t.timeout.connect(func():
		tutorial_dialog_node = phase.show_tutorial_dialog(
			"勉強カードを引くと、カードの数字がそのまま点数（勉強時間）になります。まずは1枚引いてみましょう。",
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
	var dialog_pos = Vector2(viewport_size.x * 0.6, viewport_size.y * 0.08)
	
	tutorial_dialog_node = phase.show_tutorial_dialog(
		"筆記用具（アイテム）を引くと、有利な特殊効果が発動します。カードを引いてみましょう。",
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
	var dialog_pos = Vector2(viewport_size.x * 0.6, viewport_size.y * 0.08)
	
	tutorial_dialog_node = phase.show_tutorial_dialog(
		"すでに場に出ているカードと同じ数字のカードを引くと「バースト（寝落ち）」になり、その回の点数は0点になります。リスクを体感するため、カードを引いてみましょう。",
		dialog_pos
	)
	phase.draw_btn.disabled = false
	highlight(phase.draw_btn)
	
	if is_instance_valid(phase.draw_history_container):
		highlight(phase.draw_history_container)

func advance_step() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
		
	clear_highlights()
	tutorial_step += 1
	
	var viewport_size = phase.get_viewport_rect().size
	var dialog_pos = Vector2(viewport_size.x * 0.6, viewport_size.y * 0.08)
	
	if current_hour == 1:
		match tutorial_step:
			1:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"さらに高い点数を目指して勉強を重ねます。もう一枚引いてみましょう。",
					dialog_pos
				)
				highlight(phase.draw_btn)
			2:
				phase.draw_btn.disabled = true 
				phase.stop_btn.disabled = false 
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"手札と同じ数字のカードを引くと「バースト（寝落ち）」して0点になります。安全のために『休憩』を押して、現在の合計点を確定させましょう。",
					dialog_pos
				)
				highlight(phase.stop_btn)
	elif current_hour == 2:
		match tutorial_step:
			1:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"のぞき見効果で次に引くカードがわかれば、安全にドローを続けられます。もう一枚引いてみましょう。",
					dialog_pos
				)
				highlight(phase.draw_btn)
				if is_instance_valid(phase.active_peek_sticky):
					highlight(phase.active_peek_sticky)
			2:
				phase.draw_btn.disabled = true 
				phase.stop_btn.disabled = false 
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"シャーペンの継続効果が発動しました。十分に点数が稼げたので、休憩して時限を終えましょう。",
					dialog_pos
				)
				highlight(phase.stop_btn)
				if is_instance_valid(phase.active_effects_hbox):
					highlight(phase.active_effects_hbox)
	elif current_hour == 3:
		match tutorial_step:
			1:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"すでに場にある『3』のカードをもう一度引くとバーストします。あえてもう一枚引いてバースト（0点になること）を体験してみましょう。",
					dialog_pos
				)
				highlight(phase.draw_btn)
			2:
				phase.draw_btn.disabled = true
				phase.stop_btn.disabled = true

func cleanup() -> void:
	clear_highlights()
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null

