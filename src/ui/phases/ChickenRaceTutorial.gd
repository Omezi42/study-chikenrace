class_name ChickenRaceTutorial
extends RefCounted

var phase: ChickenRacePhase
var tutorial_step: int = 0
var tutorial_dialog_node: PanelContainer = null

func _init(p_phase: ChickenRacePhase) -> void:
	phase = p_phase

func start() -> void:
	tutorial_step = 0
	phase.stop_btn.disabled = true # Cannot stop yet
	phase.draw_btn.disabled = true # Must read description first
	
	var viewport_size = phase.get_viewport_rect().size
	tutorial_dialog_node = phase.show_tutorial_dialog(
		"佐藤くん：「自習フェーズ（勉強チキンレース）へようこそ！\n\nここでは山札からカードを引き、今日の勉強成果（実点）を高めます。まずは、基本的なルールと寝落ち（バースト）について学びましょう！」",
		Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12),
		func():
			tutorial_dialog_node = phase.show_tutorial_dialog(
				"佐藤くん：「【カードドローと寝落ちバースト】\n山札からカードを引くと、カードの数字がそのまま実点になるよ。\nでも、手札の中に同じ数字のカードが2枚重なった瞬間、寝落ち（バースト）して0点になるから注意してね！」",
				Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12),
				func():
					tutorial_dialog_node = phase.show_tutorial_dialog(
						"佐藤くん：「【お役立ち文房具アイテム】\n僕たちのデッキには『消しゴム』や『定規』など、寝落ちを防いだり得点を伸ばすアイテムが入っているんだ。ドローした瞬間に自動で発動するよ！\n\nそれじゃあ、実際に『勉強カードを引く』を押して1枚引いてみて！」",
						Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12)
					)
					phase.draw_btn.disabled = false
			)
	)

func advance_step() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
		
	tutorial_step += 1
	var viewport_size = phase.get_viewport_rect().size
	
	match tutorial_step:
		1:
			phase.stop_btn.disabled = true
			phase.draw_btn.disabled = false
			tutorial_dialog_node = phase.show_tutorial_dialog(
				"佐藤くん：「カードを引いたね！カードの数字がそのまま得点になるよ。\n右上の黄色い付箋は山札の残り枚数、眠気インジケーターは次にドローした時にバーストする確率なんだ。\n\nもう1枚引いてみて！」",
				Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12)
			)
		2:
			phase.stop_btn.disabled = true
			phase.draw_btn.disabled = false
			tutorial_dialog_node = phase.show_tutorial_dialog(
				"佐藤くん：「2枚目を引いたね！手札が増えるほどバースト確率も上昇するよ。\n手札のカードにマウスを重ねると、その文房具の効果が左側の『カード説明』に表示されるよ。\n\nもう1枚引いてみて！」",
				Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12)
			)
		3:
			phase.draw_btn.disabled = true # Prevent drawing further
			phase.stop_btn.disabled = false # Enable stop
			tutorial_dialog_node = phase.show_tutorial_dialog(
				"佐藤くん：「3枚目を引いたね！眠気もかなり限界に近づいているよ。\nこれ以上ドローするのが危ないと思ったら、いつでも『休憩する』を押して点数を確定できるよ。\n\n今回は安全のために『休憩する』を押して、時限を終わらせよう！」",
				Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12)
			)

func cleanup() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
