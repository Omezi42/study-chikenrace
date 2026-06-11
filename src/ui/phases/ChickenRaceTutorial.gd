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
		"佐藤くん：「自習フェーズ（勉強チキンレース）へようこそ！\n\nここでは山札からカードを引き、今日の勉強成果（実点）を高めます。まずは、基本的なルールと寝落ち（バースト）について学びましょう！」",
		dialog_pos,
		func():
			tutorial_dialog_node = phase.show_tutorial_dialog(
				"佐藤くん：「【カードドローと寝落ちバースト】\n山札からカードを引くと、カードの数字がそのまま実点になるよ。\nでも、手札の中に同じ数字のカードが2枚重なった瞬間、寝落ち（バースト）して0点になるから注意してね！」",
				dialog_pos,
				func():
					tutorial_dialog_node = phase.show_tutorial_dialog(
						"佐藤くん：「【お役立ち文房具アイテム】\n僕たちのデッキには『単語帳』や『付箋』など、山札をのぞき見したり得点を伸ばすアイテムが入っているんだ。ドローした瞬間に自動で発動するよ！\n\nそれじゃあ、実際に『勉強カードを引く』を押して1枚引いてみて！」",
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
		"佐藤くん：「2時限目が始まったよ！山札は1時限目の状態を引き継いでいるんだ。\n\nさっき引いた『8』と『5』は捨て札にあるから、もう山札からは出ないよ。山札の残り枚数も減っているね！それじゃあ、1枚引いてみよう！」",
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
					"佐藤くん：「単語帳（8）を引いたね！カードの数字がそのまま得点になるよ。\n単語帳の効果で、山札の次のカードが3枚『のぞき見』できたね！これで何が出るか先読みできるんだ。右上の黄色い付箋は山札の残り枚数、眠気インジケーターはバーストする確率だよ。\n\nもう1枚引いてみて！」",
					dialog_pos
				)
			2:
				phase.draw_btn.disabled = true # Prevent drawing further
				phase.stop_btn.disabled = false # Enable stop
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"佐藤くん：「2枚目は付箋（5）を引いて、合計13点になったね！\n付箋の効果で、次に引くカードにボーナス点が入る状態になったよ！\nここで重要なのが『カウンティング（山札の把握）』だ。さっき引いた『8』と今回の『5』は、次の時限になると捨て札にいくので、もう山札からは出なくなる。何を引いたか覚えておくのがコツだよ！\n\n今回は安全のために『休憩する』を押して、得点を確定させよう！」",
					dialog_pos
				)
	elif current_hour == 2:
		match tutorial_step:
			1:
				phase.stop_btn.disabled = true
				phase.draw_btn.disabled = false
				tutorial_dialog_node = phase.show_tutorial_dialog(
					"佐藤くん：「定規（3）を引いたね！\n山札の初期構成では『3』は3枚入っているよ。もし次も『3』を引くとバーストしてしまうんだ。確率も上昇しているね。\n\n今回はバーストを体験するために、あえてもう1枚引いてみて！」",
					dialog_pos
				)
			2:
				# 2枚目を引いたらバーストするので、ここには到達しないか、即座に遷移する
				phase.draw_btn.disabled = true
				phase.stop_btn.disabled = true

func cleanup() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
