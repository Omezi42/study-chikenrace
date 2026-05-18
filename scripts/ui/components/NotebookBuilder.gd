class_name NotebookBuilder
extends RefCounted
## 見開きノートUIを生成するファクトリクラス。
## 元の GameScene.gd 内の _create_double_page_notebook() を独立コンポーネント化しました。

static func create() -> PanelContainer:
	var root = PanelContainer.new()
	root.custom_minimum_size = Vector2(1260, 920)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var root_style = StyleBoxEmpty.new()
	root.add_theme_stylebox_override("panel", root_style)
	
	# ドロップシャドウ用の巨大パネル
	var shadow = Panel.new()
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shadow.offset_left = 12; shadow.offset_top = 16; shadow.offset_right = -12; shadow.offset_bottom = -16
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.06, 0.04, 0.02, 0.24)
	shadow_style.corner_radius_top_left = 24; shadow_style.corner_radius_top_right = 24
	shadow_style.corner_radius_bottom_left = 24; shadow_style.corner_radius_bottom_right = 24
	shadow_style.shadow_color = Color(0, 0, 0, 0.2)
	shadow_style.shadow_size = 20
	shadow.add_theme_stylebox_override("panel", shadow_style)
	root.add_child(shadow)
	
	# ノート見開き外枠（表紙の厚み部分、少しはみ出る茶色の革）
	var cover = Panel.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cover_style = StyleBoxFlat.new()
	cover_style.bg_color = Color("8c6d4f") # 温かみのある革バインダーの茶色
	cover_style.corner_radius_top_left = 20; cover_style.corner_radius_top_right = 20
	cover_style.corner_radius_bottom_left = 20; cover_style.corner_radius_bottom_right = 20
	cover_style.border_width_left = 4; cover_style.border_width_right = 4
	cover_style.border_width_top = 4; cover_style.border_width_bottom = 4
	cover_style.border_color = Color("5c4033")
	cover.add_theme_stylebox_override("panel", cover_style)
	root.add_child(cover)
	
	# ノート本体の見開き用紙（HBoxContainer）
	var pages_hbox = HBoxContainer.new()
	pages_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages_hbox.add_theme_constant_override("separation", 0)
	pages_hbox.offset_left = 10; pages_hbox.offset_top = 10; pages_hbox.offset_right = -10; pages_hbox.offset_bottom = -10
	root.add_child(pages_hbox)
	
	# 左ページ (用紙)
	var left_page = PanelContainer.new()
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lp_style = StyleBoxFlat.new()
	lp_style.bg_color = Color("fdfbf7") # キャンパスノートの温かみのある白（僅かに黄み）
	lp_style.corner_radius_top_left = 16; lp_style.corner_radius_bottom_left = 16
	left_page.add_theme_stylebox_override("panel", lp_style)
	pages_hbox.add_child(left_page)
	
	# 左ページ罫線描画用のコンテナ
	var left_lines = Control.new()
	left_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_page.add_child(left_lines)
	
	# 左ページに情緒ある手書き落書きを追加
	var doodle_left_coffee = CozyDoodleNode.new(0, Color("8c6d4f", 0.07)) # 薄いコーヒー染み
	doodle_left_coffee.position = Vector2(10, 720) # 左下
	left_lines.add_child(doodle_left_coffee)
	
	var doodle_left_star = CozyDoodleNode.new(1, Color("5c5340", 0.12)) # 手書きの星と渦
	doodle_left_star.position = Vector2(500, 40) # 右上
	left_lines.add_child(doodle_left_star)
	
	# 赤い縦のマージン線
	var left_red_line = ColorRect.new()
	left_red_line.color = Color("ffcccc", 0.7)
	left_red_line.custom_minimum_size = Vector2(1.5, 0)
	left_red_line.anchor_bottom = 1.0
	left_red_line.offset_left = 54
	left_lines.add_child(left_red_line)
	# 青い横罫線
	for i in range(1, 23):
		var y = i * 38 + 18
		var line = ColorRect.new()
		line.color = Color("e0eaf5", 0.6) # 薄い水色罫線
		line.custom_minimum_size = Vector2(0, 1)
		line.anchor_right = 1.0
		line.offset_top = y
		left_lines.add_child(line)
		
	var left_margin = MarginContainer.new()
	left_margin.name = "LeftContent"
	left_margin.add_theme_constant_override("margin_left", 64)
	left_margin.add_theme_constant_override("margin_top", 32)
	left_margin.add_theme_constant_override("margin_right", 24)
	left_margin.add_theme_constant_override("margin_bottom", 24)
	left_page.add_child(left_margin)
	
	# 中央バインダー / リング
	var spine = Control.new()
	spine.custom_minimum_size = Vector2(48, 0)
	spine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages_hbox.add_child(spine)
	
	# 背表紙の黒いスリット影
	var spine_shadow = ColorRect.new()
	spine_shadow.color = Color("0f0c08", 0.15)
	spine_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spine.add_child(spine_shadow)
	
	# リアルなスチールリングを縦に並べる
	var rings_v = VBoxContainer.new()
	rings_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rings_v.alignment = BoxContainer.ALIGNMENT_CENTER
	rings_v.add_theme_constant_override("separation", 28)
	spine.add_child(rings_v)
	for r in range(18):
		var ring = Panel.new()
		ring.custom_minimum_size = Vector2(28, 12)
		ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var ring_style = StyleBoxFlat.new()
		ring_style.bg_color = Color("b0b8c0") # スチールシルバー
		ring_style.border_width_left = 1; ring_style.border_width_right = 1
		ring_style.border_width_top = 2; ring_style.border_width_bottom = 2
		ring_style.border_color = Color("404850") # リングの影
		ring_style.corner_radius_top_left = 6; ring_style.corner_radius_top_right = 6
		ring_style.corner_radius_bottom_left = 6; ring_style.corner_radius_bottom_right = 6
		ring_style.shadow_color = Color(1, 1, 1, 0.4)
		ring_style.shadow_size = 2
		ring.add_theme_stylebox_override("panel", ring_style)
		rings_v.add_child(ring)
		
	# 右ページ (用紙)
	var right_page = PanelContainer.new()
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rp_style = StyleBoxFlat.new()
	rp_style.bg_color = Color("fdfbf7")
	rp_style.corner_radius_top_right = 16; rp_style.corner_radius_bottom_right = 16
	right_page.add_theme_stylebox_override("panel", rp_style)
	pages_hbox.add_child(right_page)
	
	# 右ページ罫線
	var right_lines = Control.new()
	right_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_page.add_child(right_lines)
	
	# 右ページに手書き落書きを追加
	var doodle_right_spiral = CozyDoodleNode.new(2, Color("4b5c70", 0.12)) # 手書きのうずまき
	doodle_right_spiral.position = Vector2(40, 80) # 左上
	right_lines.add_child(doodle_right_spiral)
	
	var doodle_right_tally = CozyDoodleNode.new(3, Color("b24c4c", 0.14)) # 赤ペンで書いた「正」の字（勉強の記録感）
	doodle_right_tally.position = Vector2(540, 750) # 右下
	right_lines.add_child(doodle_right_tally)
	
	# 赤い縦のマージン線
	var right_red_line = ColorRect.new()
	right_red_line.color = Color("ffcccc", 0.7)
	right_red_line.custom_minimum_size = Vector2(1.5, 0)
	right_red_line.anchor_bottom = 1.0
	right_red_line.offset_left = 54
	right_lines.add_child(right_red_line)
	# 青い横罫線
	for i in range(1, 23):
		var y = i * 38 + 18
		var line = ColorRect.new()
		line.color = Color("e0eaf5", 0.6)
		line.custom_minimum_size = Vector2(0, 1)
		line.anchor_right = 1.0
		line.offset_top = y
		right_lines.add_child(line)
		
	var right_margin = MarginContainer.new()
	right_margin.name = "RightContent"
	right_margin.add_theme_constant_override("margin_left", 64)
	right_margin.add_theme_constant_override("margin_top", 32)
	right_margin.add_theme_constant_override("margin_right", 24)
	right_margin.add_theme_constant_override("margin_bottom", 24)
	right_page.add_child(right_margin)
	
	return root
