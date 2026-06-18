class_name RulebookModal
extends CanvasLayer

static func create_and_show(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = RulebookModal.new()
	parent_node.add_child(canvas)

var current_tab: int = 0
var slide_tex: TextureRect
var desc_rtb: RichTextLabel
var tab_buttons: Array[Button] = []

# 各タブで表示する説明文
var tab_texts: Array[String] = [
	# 1. 基本ルール
	"[font_size=20][b]◆ 1. ゲームの概要と勝利条件[/b][/font_size]\n\n" +
	"プレイヤーと3人のライバルが、テスト勉強の成果（3日間）を競い合います。\n\n" +
	"最終答え合わせ終了後（3日目の終わり）、[b]最終得点（申告点 ＋ ダウト成功ボーナス － ダウト失敗ペナルティ － 嘘バレペナルティ）[/b]が最も高い人が合格（優勝）となります。\n\n" +
	"[font_size=16][b]【ゲームの流れ】[/b][/font_size]\n" +
	"1. [b]自習フェーズ[/b]（毎日3〜4時限）：カードを引いて実点を高めます。\n" +
	"2. [b]チキスタ投稿[/b]（夕方）：実点または「嘘（ブラフ）」の点数を申告。\n" +
	"3. [b]ダウト投票[/b]（夜）：ライバルの嘘を見破るダウト投票。",
	
	# 2. 自習と寝落ち
	"[font_size=20][b]◆ 2. 自習ノートと眠気（バースト）[/b][/font_size]\n\n" +
	"自習フェーズでは、山札からカードを引いて点数を積み上げます。\n\n" +
	"・[b]寝落ち（バースト）[/b]: 手札に同じ値（数字）のカードが重複した瞬間、眠気に負けてその時限の点数はすべて [color=red]0点[/color] になってしまいます！\n" +
	"・[b]休憩[/b]: 任意のタイミングでドローを止めて休憩し、その時点の点数を確定（実点）できます。\n\n" +
	"[font_size=16][b]【山札の構成 (55枚)】[/b][/font_size]\n" +
	"デッキスロットNには、該当カードが「N枚」入ります（スロット10には10枚）。\n" +
	"値の大きいスロットに設定されたアイテムは引きやすいですが、手札に重なりやすいためバースト（寝落ち）の危険性が高くなります。",
	
	# 3. 文房具の力
	"[font_size=20][b]◆ 3. 得点計算と文房具効果[/b][/font_size]\n\n" +
	"自習中の点数は、引いたカードの値と文房具の効果によって計算されます。\n\n" +
	"・[b]基礎点[/b]: 手札のカードの値（およびシャーペン等の加算・青ペン等の倍率効果）の合計。\n" +
	"・[b]文房具効果[/b]: 手札にある文房具アイテムによる得点加算や倍率効果の合計。各アイテムにホバーすると詳細な効果が表示されます。\n\n" +
	"[font_size=16][b]【主要文房具の例】[/b][/font_size]\n" +
	"・[b]消しゴム[/b]: 重複したカードを山札に戻してシャッフルし、ドローをやり直す。\n" +
	"・[b]定規[/b]: 基礎点に固定値を追加する。\n" +
	"・[b]青ペン[/b]: 得点に倍率をかける。",
	
	# 4. 嘘とチキスタ
	"[font_size=20][b]◆ 4. チキスタ投稿と『嘘（ブラフ）』[/b][/font_size]\n\n" +
	"一日の終わりに、今日の獲得実点の合計を勉強SNS『チキスタ』に投稿します。\n\n" +
	"・[b]ブラフ（嘘の申告）[/b]: 実点より高い点数を申告してライバルを焦らせることができます（基本上限 [b]+24点[/b]、アイテムで拡張可能）。\n\n" +
	"・[b]自動露見確率[/b]: 誰もダウトしなくても、盛り幅が大きいと一日の終わりに自動で嘘がバレます。\n" +
	"  確率: [color=ff9100](盛り幅/40)^2[/color]\n\n" +
	"・[b]嘘バレペナルティ[/b]: 嘘がバレた際、申告点は実点まで減算され、さらに[color=red]「盛り幅の50%」[/color]（解答写し使用時はその2倍）の点数がペナルティとして最終得点から減算されます。",
	
	# 5. ダウトと勝敗
	"[font_size=20][b]◆ 5. ダウト投票と最終答え合わせ[/b][/font_size]\n\n" +
	"ライバルのドロー数や使用アイテムの履歴を確認し、嘘を見破って「ダウト」を仕掛けます。ダウトは毎日最大3回まで行えます。\n\n" +
	"・[b]ダウト成功ボーナス[/b]: 相手の盛り幅の [b]75% + 6点[/b] （勉強会チャット使用時はさらに+6点）を獲得。\n" +
	"・[b]ダウト失敗ペナルティ[/b]: 正静な人に誤ってダウトすると減点（日程経過で [b]10点〜18点[/b]）。座布団で半減、耳栓で-10点軽減。\n\n" +
	"[font_size=16][b]【同点時のタイブレーク】[/b][/font_size]\n" +
	"最終得点が同点の場合、マッチを通じてバースト（寝落ち）した回数がより少ないプレイヤーが勝者となります。"
]

func _ready() -> void:
	layer = 102 # SettingsModalよりも手前に表示できるように高めのレイヤーに設定
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(1050, 750)
	modal.pivot_offset = Vector2(525, 375)
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
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Header with Title and Close Button
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "テスト勉強チキンレースの遊び方"
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = " × 閉じる "
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.custom_minimum_size = Vector2(120, 40)
	DeskTheme.apply_white_button_style(close_btn)
	header_hbox.add_child(close_btn)
	close_btn.pressed.connect(func():
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			queue_free()
		)
	)
	
	# Tab Navigation Row
	var tab_hbox = HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(tab_hbox)
	
	var tab_names = ["1. 基本ルール", "2. 自習と寝落ち", "3. 文房具の力", "4. 嘘とチキスタ", "5. ダウトと勝敗"]
	for i in range(tab_names.size()):
		var tab_btn = Button.new()
		tab_btn.text = tab_names[i]
		tab_btn.add_theme_font_override("font", DeskTheme.get_font())
		tab_btn.add_theme_font_size_override("font_size", 16)
		tab_btn.custom_minimum_size = Vector2(180, 45)
		tab_btn.toggle_mode = true
		tab_hbox.add_child(tab_btn)
		tab_buttons.append(tab_btn)
		
		# Closure binding
		var idx = i
		tab_btn.pressed.connect(func():
			_select_tab(idx)
		)
	
	# Content Split Area (Horizontal)
	var content_hbox = HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 24)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_hbox)
	
	# Left: Image Container
	var img_panel = PanelContainer.new()
	img_panel.custom_minimum_size = Vector2(520, 410)
	img_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var img_style = StyleBoxFlat.new()
	img_style.bg_color = Color("faf6f0")
	img_style.border_color = DeskTheme.COLOR_INK
	img_style.border_width_left = 2
	img_style.border_width_right = 2
	img_style.border_width_top = 2
	img_style.border_width_bottom = 2
	img_style.corner_radius_top_left = 8
	img_style.corner_radius_top_right = 8
	img_style.corner_radius_bottom_left = 8
	img_style.corner_radius_bottom_right = 8
	img_panel.add_theme_stylebox_override("panel", img_style)
	content_hbox.add_child(img_panel)
	
	slide_tex = TextureRect.new()
	slide_tex.custom_minimum_size = Vector2(500, 390)
	slide_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_panel.add_child(slide_tex)
	
	# Right: Text Scroll Container
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(scroll)
	
	desc_rtb = RichTextLabel.new()
	desc_rtb.bbcode_enabled = true
	desc_rtb.add_theme_font_override("normal_font", DeskTheme.get_font())
	desc_rtb.add_theme_font_override("bold_font", DeskTheme.get_font())
	desc_rtb.add_theme_font_size_override("normal_font_size", 16)
	desc_rtb.add_theme_font_size_override("bold_font_size", 18)
	desc_rtb.add_theme_color_override("default_color", DeskTheme.COLOR_INK)
	desc_rtb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_rtb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(desc_rtb)
	
	# Footer (Tutorial Button and Close shortcut)
	var footer_hbox = HBoxContainer.new()
	footer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(footer_hbox)
	
	var play_tutorial_btn = Button.new()
	play_tutorial_btn.text = " ★ チュートリアルをプレイ！ ★ "
	play_tutorial_btn.custom_minimum_size = Vector2(400, 50)
	play_tutorial_btn.add_theme_font_override("font", DeskTheme.get_font())
	play_tutorial_btn.add_theme_font_size_override("font_size", 20)
	
	# 黄色のハイライトカラーを使用して目立たせる
	var tut_normal = StyleBoxFlat.new()
	tut_normal.bg_color = Color("fff59d") # 明るいイエロー
	tut_normal.border_color = DeskTheme.COLOR_INK
	tut_normal.border_width_left = 3
	tut_normal.border_width_right = 3
	tut_normal.border_width_top = 3
	tut_normal.border_width_bottom = 6
	tut_normal.corner_radius_top_left = 8
	tut_normal.corner_radius_top_right = 8
	tut_normal.corner_radius_bottom_left = 8
	tut_normal.corner_radius_bottom_right = 8
	
	var tut_hover = tut_normal.duplicate()
	tut_hover.bg_color = Color("fff176") # ホバー時は少し濃いイエロー
	
	var tut_pressed = tut_normal.duplicate()
	tut_pressed.border_width_bottom = 3
	
	play_tutorial_btn.add_theme_stylebox_override("normal", tut_normal)
	play_tutorial_btn.add_theme_stylebox_override("hover", tut_hover)
	play_tutorial_btn.add_theme_stylebox_override("pressed", tut_pressed)
	play_tutorial_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	play_tutorial_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	play_tutorial_btn.add_theme_color_override("font_hover_color", DeskTheme.COLOR_INK)
	play_tutorial_btn.add_theme_color_override("font_pressed_color", DeskTheme.COLOR_INK)
	
	play_tutorial_btn.pivot_offset = play_tutorial_btn.custom_minimum_size / 2.0
	play_tutorial_btn.mouse_entered.connect(func(): DeskTheme.animate_hover(play_tutorial_btn, true, Vector2.ONE, 0.1))
	play_tutorial_btn.mouse_exited.connect(func(): DeskTheme.animate_hover(play_tutorial_btn, false, Vector2.ONE, 0.1))
	
	play_tutorial_btn.pressed.connect(func():
		play_tutorial_btn.release_focus()
		DeskTheme.animate_click(play_tutorial_btn, Vector2.ONE, 0.08)
		# チュートリアルプレイ開始処理
		Global.is_tutorial_mode = true
		Global.game_mode = Constants.MODE_CPU
		Global.opponent_profiles = {
			"cpu_sato": {"name": "佐藤くん", "deviation": 51.5},
			"cpu_suzuki": {"name": "鈴木さん", "deviation": 48.0},
			"cpu_takahashi": {"name": "高橋くん", "deviation": 54.2}
		}
		if Global.player_name == "":
			Global.player_name = "プレイヤー"
		
		# フェードインアニメーションとシーン切り替え
		var out_tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			queue_free()
			var tree = get_tree()
			if tree:
				Global.change_scene_with_fade(tree, "res://Main.tscn")
		)
	)
	footer_hbox.add_child(play_tutorial_btn)
	
	# Initial Tab Selection
	_select_tab(0)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)

func _select_tab(tab_idx: int) -> void:
	current_tab = tab_idx
	
	# Update button states
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i]
		if i == tab_idx:
			btn.button_pressed = true
			btn.release_focus()
			
			# アクティブなタブのスタイル（ハイライトカラー）
			var style_active = StyleBoxFlat.new()
			style_active.bg_color = Color("c2185b") # ピンクレッド
			style_active.border_color = DeskTheme.COLOR_INK
			style_active.border_width_left = 2
			style_active.border_width_right = 2
			style_active.border_width_top = 2
			style_active.border_width_bottom = 2
			style_active.corner_radius_top_left = 6
			style_active.corner_radius_top_right = 6
			style_active.corner_radius_bottom_left = 6
			style_active.corner_radius_bottom_right = 6
			btn.add_theme_stylebox_override("normal", style_active)
			btn.add_theme_stylebox_override("hover", style_active)
			btn.add_theme_stylebox_override("pressed", style_active)
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
			btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		else:
			btn.button_pressed = false
			DeskTheme.apply_white_button_style(btn)
			btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			btn.add_theme_color_override("font_hover_color", DeskTheme.COLOR_INK)
			btn.add_theme_color_override("font_pressed_color", DeskTheme.COLOR_INK)
			
	# Update slide image
	var path = "res://assets/tutorial/slide%d.png" % (tab_idx + 1)
	if ResourceLoader.exists(path):
		slide_tex.texture = load(path)
		
	# Update description text
	desc_rtb.text = tab_texts[tab_idx]
