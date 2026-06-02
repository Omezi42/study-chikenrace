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
		"自習フェーズ（勉強チキンレース）へようこそ！\n\nここでは山札からカードを引き、勉強成果（実点）を高めます。まずは、点数を大きく伸ばす『教科』と『コンボ』の仕様を学びましょう！",
		Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12),
		func():
			tutorial_dialog_node = phase.show_tutorial_dialog(
				"【教科とコンボボーナス】\nカードには5つの教科（国・英・数・理・社）があります。\n・同教科を連続で引くと『コンボ』となり得点ボーナス加算！\n・5教科をすべて手札に揃えると、合計点の22%（10〜28点）が加算される『5教科ボーナス』が発生します！",
				Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12),
				func():
					tutorial_dialog_node = phase.show_tutorial_dialog(
						"【仕込みアイテム：付箋】\n初期カードの『付箋』は、次のドローで特定の教科を確定で出現させる効果（山札にあれば）を持ちます。教科コンボや5教科ボーナスを狙うのに非常に強力です！\n\nそれでは、実際に『勉強カードを引く』を押して1枚引いてみましょう！",
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
				"カードを引きました！カードの左上には『教科アイコン』、中央には大きく『点数（数字）』が書かれています。\n\nもう1枚引いてみましょう！",
				Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12)
			)
		2:
			phase.stop_btn.disabled = true
			phase.draw_btn.disabled = false
			tutorial_dialog_node = phase.show_tutorial_dialog(
				"2枚目を引きました！もし手札に同じ数字のカードが重なると「寝落ち（バースト）」してこの時限の点数は0点になります。\n右上の「眠気」パーセントがバーストする確率です。安全第一で、もう1枚引いてみましょう！",
				Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12)
			)
		3:
			phase.draw_btn.disabled = true # これ以上ドローさせない
			phase.stop_btn.disabled = false # 休憩を有効化
			tutorial_dialog_node = phase.show_tutorial_dialog(
				"3枚目を引きました！同じ教科を連続して引くと「コンボボーナス」が入ります！\n眠気も上がってきたので、ここらで『休憩する』を押して自習を終え、本日の成果（点数）を確定させましょう！",
				Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12)
			)

func cleanup() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
