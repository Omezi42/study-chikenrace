class_name RulebookModal
extends CanvasLayer

static func create_and_show(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = RulebookModal.new()
	parent_node.add_child(canvas)

func _ready() -> void:
	layer = 100
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(900, 680)
	modal.pivot_offset = Vector2(450, 340)
	modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(modal)
	
	var viewport_size = get_viewport().get_visible_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Header with Title and Close Button
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "テスト勉強チキンレース 公式ルールブック"
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = " × 閉じる "
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.custom_minimum_size = Vector2(100, 36)
	DeskTheme.apply_white_button_style(close_btn)
	header_hbox.add_child(close_btn)
	
	# ScrollContainer for Rule Text
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var rtb = RichTextLabel.new()
	rtb.bbcode_enabled = true
	rtb.add_theme_font_override("normal_font", DeskTheme.get_font())
	rtb.add_theme_font_override("bold_font", DeskTheme.get_font())
	rtb.add_theme_font_size_override("normal_font_size", 16)
	rtb.add_theme_font_size_override("bold_font_size", 18)
	rtb.add_theme_color_override("default_color", DeskTheme.COLOR_INK)
	rtb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var rules_text = "[center][font_size=28][b]テスト勉強チキンレースのルール[/b][/font_size][/center]\n\n"
	rules_text += "[font_size=18][b]1. ゲームの概要と勝利条件[/b][/font_size]\n"
	rules_text += "プレイヤーと3人のライバルが、テスト勉強の成果（通常プレイは1日間、5日制は5日間）を競い合います。\n"
	rules_text += "最終答え合わせ終了後（通常プレイは1日目の終わり、5日制は5日目の終わり）、[b]最終得点（申告点 ＋ ダウト成功ボーナス － ダウト失敗ペナルティ － 嘘バレペナルティ）[/b]が最も高い人が合格（優勝）となります。\n\n"
	rules_text += "[font_size=18][b]2. 自習フェーズ（勉強チキンレース）[/b][/font_size]\n"
	rules_text += "毎日3時限（アイテムで最大4時限）の自習を行い、カードを引いて点数を高めます。\n"
	rules_text += "・[b]バースト（寝落ち）[/b]: 手札に同じ値（数字）のカードが重複した瞬間、その時限の点数はすべて [color=red]0点[/color] になります。\n"
	rules_text += "・[b]休憩[/b]: 任意のタイミングでドローを止めて休憩し、その時点の点数を確定（実点）できます。\n"
	rules_text += "・[b]山札の構成 (55枚)[/b]: デッキスロットNには、該当カードが「N枚」入ります（スロット10には10枚）。値の大きいスロットに設定されたアイテムは引きやすいですが、手札に重なりやすいためバースト（寝落ち）の危険性が高くなります。\n\n"
	rules_text += "[font_size=18][b]3. 得点計算[/b][/font_size]\n"
	rules_text += "・[b]基礎点[/b]: 手札のカードの値（およびシャーペン等の加算・青ペン等の倍率効果）の合計。\n"
	rules_text += "・[b]文房具効果[/b]: 手札にある文房具アイテムによる得点加算や倍率効果の合計。各アイテムにホバーすると詳細な効果が表示されます。\n\n"
	rules_text += "[font_size=18][b]4. チキスタ投稿と『嘘（ブラフ）』[/b][/font_size]\n"
	rules_text += "一日の終わりに、今日の獲得実点の合計を勉強SNS『チキスタ』に投稿します。\n"
	rules_text += "・実点より高い点数を申告してライバルを焦らせる（ブラフをかける）ことができます（基本上限 [b]+24点[/b]、アイテムで拡張可能）。\n\n"
	rules_text += "[font_size=18][b]5. ダウト投票と嘘の露見[/b][/font_size]\n"
	rules_text += "ライバルのドロー数や使用アイテムの履歴を確認し、嘘を見破って「ダウト」を仕掛けます。ダウトは毎日最大3回まで行えます。\n"
	rules_text += "・[b]自動露見確率[/b]: 誰もダウトしなくても、盛り幅が大きいと一日の終わりに自動で嘘がバレます。（確率: [color=ff9100](盛り幅/40)^2[/color]）\n"
	rules_text += "・[b]嘘バレペナルティ[/b]: 嘘がバレた際、申告点は実点まで減算され、さらに[color=red]「盛り幅の50%」[/color]（解答写し使用時はその2倍）の点数がペナルティとして最終得点から減算されます。\n"
	rules_text += "・[b]ダウト成功ボーナス[/b]: 相手の盛り幅の75% + 6点（勉強会チャット使用時はさらに+6点）を獲得。\n"
	rules_text += "・[b]ダウト失敗ペナルティ[/b]: 正直な人に誤ってダウトすると減点（日程経過で [b]10点〜18点[/b]）。座布団で半減、耳栓で-10点軽減。\n\n"
	rules_text += "[font_size=18][b]6. タイブレーク[/b][/font_size]\n"
	rules_text += "最終得点が同点の場合、マッチを通じてバースト（寝落ち）した回数がより少ないプレイヤーが勝者となります。\n"
	rtb.text = rules_text
	scroll.add_child(rtb)
	
	close_btn.pressed.connect(func():
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			queue_free()
		)
	)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
