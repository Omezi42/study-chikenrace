class_name TutorialModal
extends PanelContainer

var current_tutorial_page: int = 1
var tutorial_slide_tex: TextureRect
var tutorial_desc_lbl: Label
var tutorial_back_btn: Button
var tutorial_next_btn: Button
var tutorial_page_lbl: Label

func _init() -> void:
	custom_minimum_size = Vector2(1000, 770)
	pivot_offset = Vector2(500, 385)
	
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_CRAFT
	style.border_color = DeskTheme.COLOR_INK
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 15
	style.shadow_offset = Vector2(6, 6)
	add_theme_stylebox_override("panel", style)
	
	position = get_viewport_rect().size * 0.5 - pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Title
	var header_title = Label.new()
	header_title.text = "テスト勉強チキンレースのあそびかた 📝"
	header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	header_title.add_theme_font_size_override("font_size", 24)
	header_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(header_title)
	
	# Texture Rect for slide
	tutorial_slide_tex = TextureRect.new()
	tutorial_slide_tex.custom_minimum_size = Vector2(960, 520)
	tutorial_slide_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(tutorial_slide_tex)
	
	# Description Label below slide
	tutorial_desc_lbl = Label.new()
	tutorial_desc_lbl.custom_minimum_size = Vector2(960, 80)
	tutorial_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_desc_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	tutorial_desc_lbl.add_theme_font_size_override("font_size", 18)
	tutorial_desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(tutorial_desc_lbl)
	
	# Bottom Nav HBox
	var nav_hbox = HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(nav_hbox)
	
	tutorial_back_btn = Button.new()
	tutorial_back_btn.text = "◀ 前へ"
	tutorial_back_btn.custom_minimum_size = Vector2(120, 45)
	tutorial_back_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	tutorial_back_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(tutorial_back_btn)
	tutorial_back_btn.pressed.connect(_on_tutorial_back_pressed)
	nav_hbox.add_child(tutorial_back_btn)
	
	tutorial_page_lbl = Label.new()
	tutorial_page_lbl.text = "1 / 5"
	tutorial_page_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	tutorial_page_lbl.add_theme_font_size_override("font_size", 20)
	tutorial_page_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	nav_hbox.add_child(tutorial_page_lbl)
	
	tutorial_next_btn = Button.new()
	tutorial_next_btn.text = "次へ ▶"
	tutorial_next_btn.custom_minimum_size = Vector2(120, 45)
	tutorial_next_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	tutorial_next_btn.add_theme_font_size_override("font_size", 18)
	Global.apply_white_button_style(tutorial_next_btn)
	tutorial_next_btn.pressed.connect(_on_tutorial_next_pressed)
	nav_hbox.add_child(tutorial_next_btn)
	
func _ready() -> void:
	update_tutorial_slide()
	scale = Vector2.ZERO
	if get_tree() != null:
		var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.3)

func update_tutorial_slide() -> void:
	var path = "res://assets/tutorial/slide%d.png" % current_tutorial_page
	if ResourceLoader.exists(path):
		tutorial_slide_tex.texture = load(path)
	tutorial_page_lbl.text = "%d / 5" % current_tutorial_page
	tutorial_back_btn.disabled = (current_tutorial_page == 1)
	if current_tutorial_page == 5:
		tutorial_next_btn.text = "閉じる ✖"
	else:
		tutorial_next_btn.text = "次へ ▶"
		
	# Update description text
	match current_tutorial_page:
		1:
			tutorial_desc_lbl.text = "【① ゲームの基本ルール】\n『テスト勉強チキンレース』は、実点と申告点を競い合う5日間の勉強チキンレースゲームです。毎日3時限（または4時限）の自習を行い、カードを引いて勉強成果（実点）を高めます。"
		2:
			tutorial_desc_lbl.text = "【② 自習ノートと眠気（バースト）】\n山札からカードを引いて点数を積み上げます。ただし、手札と同じ数字のカードを引くと「寝落ち（バースト）」となり、その時限の点数はすべて0点になります！適度なところで「休憩する」を押して点数を確保しましょう。"
		3:
			tutorial_desc_lbl.text = "【③ アイテムの活用とコンボボーナス】\n各カードには様々な効果があります。消しゴムでバーストを無効化したり、シャーペンで点数をアップできます。また、同じ教科を連続で引くと「コンボ」、5教科すべて揃えると「5教科ボーナス」が発生します！"
		4:
			tutorial_desc_lbl.text = "【④ チキスタへの投稿と『嘘（ブラフ）』】\n一日の終わりに、今日の点数を勉強SNS『チキスタ』に投稿します。実際の点数より高く「嘘（ブラフ）」の点数を申告してライバルを焦らせることができます。ただし、盛りすぎるとダウトされる危険性が高まります！"
		5:
			tutorial_desc_lbl.text = "【⑤ 最終答え合わせと勝敗】\n5日目の終了後、全員の「実点」「申告点」「ダウト結果」が黒板で大公開されます！ダウトに成功すれば相手の盛り点をもらえ、失敗すればペナルティを受けます。最終的に最も点数の高い人が合格（優勝）です！"

func _on_tutorial_back_pressed() -> void:
	DeskTheme.animate_click(tutorial_back_btn, Vector2.ONE, 0.08)
	if current_tutorial_page > 1:
		current_tutorial_page -= 1
		update_tutorial_slide()

func _on_tutorial_next_pressed() -> void:
	DeskTheme.animate_click(tutorial_next_btn, Vector2.ONE, 0.08)
	if current_tutorial_page < 5:
		current_tutorial_page += 1
		update_tutorial_slide()
	else:
		if get_tree() != null:
			var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
			tween.chain().tween_callback(func():
				queue_free()
			)
