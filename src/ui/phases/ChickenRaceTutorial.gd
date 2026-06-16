class_name ChickenRaceTutorial
extends RefCounted

var phase: ChickenRacePhase
var tutorial_step: int = 0
var tutorial_dialog_node: PanelContainer = null
var current_hour: int = 1

func _init(p_phase: ChickenRacePhase) -> void:
	phase = p_phase

func start() -> void:
	tutorial_step = 0
	current_hour = 1
	phase.stop_btn.disabled = true # Cannot stop yet
	phase.draw_btn.disabled = true # Must read description first
	
	var viewport_size = phase.get_viewport_rect().size
	var dialog_pos = Vector2(viewport_size.x * 0.05, viewport_size.y * 0.22)
	
	tutorial_dialog_node = phase.show_tutorial_dialog(
		"おーい！次のテスト、マジでヤバいらしいぞ！\n一緒に『一夜漬け』で乗り切ろうぜ。\n\nルールは簡単、カードを引いて勉強するだけ！でも居眠り（バースト）には気をつけろよ！",
		dialog_pos,
		func():
			tutorial_dialog_node = phase.show_tutorial_dialog(
				"勉強すればするほど点数は上がるけど、同じ勉強内容（カードの数字）が重なった瞬間、脳みそがパンクして『居眠り（バースト）』しちゃうんだ。\n\nそうなったらその時間は 0点 になるからな！",
				dialog_pos,
				func():
					tutorial_dialog_node = phase.show_tutorial_dialog(
						"でも安心しろよ！俺たちの筆箱には『単語帳』とか『付箋』みたいな便利ツールが入ってる。引いた瞬間に効果が出るから、うまく使おうぜ！\n\nほら、まずは『勉強カードを引く』を押して1枚引いてみて！",
						dialog_pos
					)
					phase.draw_btn.disabled = false
			)
	)

func start_hour_2() -> void:
	tutorial_step = 0
	current_hour = 2
	phase.stop_btn.disabled = true
	phase.draw_btn.disabled = true
	
	var viewport_size = phase.get_viewport_rect().size
	var dialog_pos = Vector2(viewport_size.x * 0.05, viewport_size.y * 0.22)
	
	tutorial_dialog_node = phase.show_tutorial_dialog(
		"2時限目が始まったぞ！山札はさっきの続きからだ。\n\nさっき引いたカードは捨て札にあるから、もう山札からは出ない。引いた数字を覚えておくのがコツだ。さあ、もう1枚いこう！",
		dialog_pos
	)
	phase.draw_btn.disabled = false

func advance_step() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
		
	tutorial_step += 1
	var viewport_size = phase.get_viewport_rect().size
	var dialog_pos = Vector2(viewport_size.x * 0.05, viewport_size.y * 0.22)
	
	if current_hour == 1:
		match tutorial_step:
			1:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"お、『単語帳』を引いたな！カードの数字がそのまま得点になるぞ。\n単語帳の効果で、次のカードが3枚『のぞき見』できたな！これで次に出る数字が先読みできる。\n\nよし、もう1枚引いてみよう！",
					dialog_pos
				)
			2:
				phase.draw_btn.disabled = true # Prevent drawing further
				phase.stop_btn.disabled = false # Enable stop
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"2枚目は『付箋』を引いて、合計13点になったぞ！\n付箋の効果で、次に引くカードにボーナスが入るようになった！\n\n今回は上出来だしバーストしたら勿体ないから、安全のために『休憩する』を押して、得点を確定させよう！",
					dialog_pos
				)
	elif current_hour == 2:
		match tutorial_step:
			1:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"『3』を引いたな！\n山札の初期構成では『3』は3枚入ってる。もし次も『3』を引くとバースト（居眠り）してしまうぞ！確率も上がってるな。\n\nここは居眠りを体験するために、あえてもう1枚引いてみてくれ！",
					dialog_pos
				)
			2:
				phase.draw_btn.disabled = true
				phase.stop_btn.disabled = true

func cleanup() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
