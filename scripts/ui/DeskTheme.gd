class_name DeskTheme
extends RefCounted

const COLOR_NOTE = Color("f5f0e6")
const COLOR_NOTE_DARK = Color("d5c7a7")
const COLOR_INK = Color("2c363f")
const COLOR_SAFE = Color("1e7b85") # 深みのあるダークティール！白文字が超ハッキリ見える！
const COLOR_BURST = Color("ff6b6b")
const COLOR_BONUS = Color("ffe66d")
const COLOR_MUTED = Color("8a8279")
const COLOR_DESK_WARM = Color("c09f80")
const COLOR_ACCENT_GOLD = Color("f0c040")
const COLOR_BLUFF_RED = Color("d94040")
const COLOR_BLUFF_MILD = Color("e89030") # マイルドなブラフ警告用（オレンジ・ゴールド系）
const COLOR_SHADOW = Color(0.06, 0.04, 0.02, 0.30)
const COLOR_GLASS = Color(1, 1, 1, 0.12)
const COLOR_CHALK_WHITE = Color(0.95, 0.95, 0.95, 0.9)
const COLOR_CHALK_YELLOW = Color(1.0, 0.9, 0.4, 0.9)

static func _load_asset(path: String) -> Resource:
	if not ResourceLoader.exists(path):
		push_warning("DeskTheme: asset not found: %s" % path)
		return null
	var res = load(path)
	if res == null:
		push_warning("DeskTheme: failed to load: %s" % path)
	return res

static var DESK_TEXTURE: Texture2D = _load_asset("res://assets/机の背景画像-ノート無し.png")
static var CARD_FRONT: Texture2D = _load_asset("res://assets/カード背景画像.png")
static var CARD_BACK: Texture2D = _load_asset("res://assets/カード裏面画像.png")
static var HANAMARU_TEXTURE: Texture2D = _load_asset("res://assets/はなまるスタンプ.png")
static var DEFAULT_FONT: Font = _load_asset("res://assets/hgrsmp.ttf")
static var BLACKBOARD_TEXTURE: Texture2D = _load_asset("res://assets/黒板.png")
static var ITEM_ERASER: Texture2D = _load_asset("res://assets/split/item_eraser.png")
static var ITEM_PEN: Texture2D = _load_asset("res://assets/split/item_pen.png")
static var ITEM_RULER: Texture2D = _load_asset("res://assets/split/item_ruler.png")

static var SUBJECT_JAPANESE: Texture2D = _load_asset("res://assets/split/subject_japanese.png")
static var SUBJECT_MATH: Texture2D = _load_asset("res://assets/split/subject_math.png")
static var SUBJECT_ENGLISH: Texture2D = _load_asset("res://assets/split/subject_english.png")
static var SUBJECT_SCIENCE: Texture2D = _load_asset("res://assets/split/subject_science.png")
static var SUBJECT_SOCIAL: Texture2D = _load_asset("res://assets/split/subject_social.png")

static func decorate_scene(root: Control, dim_alpha: float = 0.14) -> void:
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	if DESK_TEXTURE:
		var bg = TextureRect.new()
		bg.texture = DESK_TEXTURE
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bg)
	else:
		var fallback = ColorRect.new()
		fallback.color = COLOR_DESK_WARM
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(fallback)
	
	var vignette = ColorRect.new()
	vignette.color = Color(0.0, 0.0, 0.0, dim_alpha)
	vignette.anchor_left = 0.0
	vignette.anchor_top = 0.0
	vignette.anchor_right = 1.0
	vignette.anchor_bottom = 1.0
	vignette.offset_left = 0
	vignette.offset_top = 0
	vignette.offset_right = 0
	vignette.offset_bottom = 0
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

static func apply_font(target: Control) -> void:
	if DEFAULT_FONT and (target is Label or target is Button or target is LineEdit or target is TextEdit):
		target.add_theme_font_override("font", DEFAULT_FONT)
	for child in target.get_children():
		if child is Control:
			apply_font(child)



static func create_notebook_panel(min_size: Vector2, margin_left: int = 54, margin_top: int = 42, margin_right: int = 54, margin_bottom: int = 42) -> Control:
	var root = Control.new()
	root.custom_minimum_size = min_size
	root.size = min_size
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var shadow = Panel.new()
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shadow.offset_left = 10; shadow.offset_top = 12; shadow.offset_right = 10; shadow.offset_bottom = 12
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = COLOR_SHADOW
	shadow_style.corner_radius_top_left = 14; shadow_style.corner_radius_top_right = 14
	shadow_style.corner_radius_bottom_left = 14; shadow_style.corner_radius_bottom_right = 14
	shadow.add_theme_stylebox_override("panel", shadow_style)
	root.add_child(shadow)
	var paper = ColorRect.new()
	paper.color = COLOR_NOTE
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(paper)
	var content = MarginContainer.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", margin_left)
	content.add_theme_constant_override("margin_top", margin_top)
	content.add_theme_constant_override("margin_right", margin_right)
	content.add_theme_constant_override("margin_bottom", margin_bottom)
	root.add_child(content)
	return root

static func create_sticky_note(tint: Color, min_size: Vector2, rotation_deg: float = 0.0) -> PanelContainer:
	var note = PanelContainer.new()
	note.custom_minimum_size = min_size
	var style = StyleBoxFlat.new()
	style.bg_color = tint
	style.corner_radius_top_left = 2; style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.shadow_color = COLOR_SHADOW
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 5)
	note.add_theme_stylebox_override("panel", style)
	note.rotation_degrees = rotation_deg
	note.pivot_offset = min_size / 2.0
	return note

static func create_glass_panel(min_size: Vector2) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.size = min_size
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.08, 0.72)
	style.corner_radius_top_left = 16; style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16; style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

static func create_blackboard_panel(min_size: Vector2) -> Control:
	var root = Control.new()
	root.custom_minimum_size = min_size
	
	var aspect = AspectRatioContainer.new()
	aspect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if BLACKBOARD_TEXTURE:
		var img_size = BLACKBOARD_TEXTURE.get_size()
		aspect.ratio = img_size.x / img_size.y
	else:
		aspect.ratio = 1.4
	
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	root.add_child(aspect)
	
	var board_base = Control.new()
	aspect.add_child(board_base)
	
	if BLACKBOARD_TEXTURE:
		var bg = TextureRect.new()
		bg.texture = BLACKBOARD_TEXTURE
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		board_base.add_child(bg)
	else:
		var bg = Panel.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.25, 0.18, 1.0)
		style.border_width_left = 16; style.border_width_right = 16
		style.border_width_top = 16; style.border_width_bottom = 16
		style.border_color = Color(0.4, 0.25, 0.15, 1.0)
		style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
		style.shadow_color = COLOR_SHADOW
		style.shadow_size = 8
		bg.add_theme_stylebox_override("panel", style)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		board_base.add_child(bg)
	
	var content = MarginContainer.new()
	content.name = "Content"
	# 木枠や消しゴム部分を避け、緑の部分だけにコンテンツが乗るようにパーセンテージでアンカーを設定
	# スクリーンショットから、上部枠が厚め、下部が消しゴムでさらに厚めであることを考慮
	content.anchor_left = 0.07
	content.anchor_top = 0.12
	content.anchor_right = 0.93
	content.anchor_bottom = 0.80
	content.offset_left = 0; content.offset_top = 0; content.offset_right = 0; content.offset_bottom = 0
	board_base.add_child(content)
	
	return root

static func create_subject_card_large(subject: int, weight: int) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(190, 260)
	container.size = Vector2(190, 260)
	
	# 立体的なドロップシャドウ (Sprint 1)
	var shadow_rect = Panel.new()
	shadow_rect.name = "DropShadow"
	shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color.TRANSPARENT
	shadow_style.shadow_color = Color(0, 0, 0, 0.28)
	shadow_style.shadow_size = 5
	shadow_style.shadow_offset = Vector2(4, 6)
	shadow_style.corner_radius_top_left = 14; shadow_style.corner_radius_top_right = 14
	shadow_style.corner_radius_bottom_left = 14; shadow_style.corner_radius_bottom_right = 14
	shadow_rect.add_theme_stylebox_override("panel", shadow_style)
	container.add_child(shadow_rect)
	
	var bg = TextureRect.new()
	bg.texture = CARD_FRONT
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(bg)
	
	var subj_col = subject_color(subject)
	
	var content_v = VBoxContainer.new()
	content_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_v.alignment = BoxContainer.ALIGNMENT_CENTER
	content_v.add_theme_constant_override("separation", 12)
	container.add_child(content_v)
	
	# 重み表示
	var weight_lbl = create_label(str(weight), 56, subj_col, true)
	content_v.add_child(weight_lbl)
	
	# 教科アイコンと名前
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	content_v.add_child(hbox)
	
	var tex = subject_texture(subject)
	if tex:
		var icon = create_icon_rect(tex, Vector2(28, 28))
		hbox.add_child(icon)
		
	hbox.add_child(create_label(subject_name(subject), 20, COLOR_INK, true))
	
	# 左上にミニバッジを追加（重ね合わされても見えるように）
	var mini_badge = PanelContainer.new()
	mini_badge.name = "MiniBadge"
	mini_badge.custom_minimum_size = Vector2(40, 26)
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = subj_col
	badge_style.corner_radius_top_left = 6
	badge_style.corner_radius_top_right = 6
	badge_style.corner_radius_bottom_left = 6
	badge_style.corner_radius_bottom_right = 6
	mini_badge.add_theme_stylebox_override("panel", badge_style)
	
	var mini_lbl = create_label("%s%d" % [subject_name(subject).left(1), weight], 13, Color.WHITE, true)
	mini_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mini_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mini_badge.add_child(mini_lbl)
	
	container.add_child(mini_badge)
	mini_badge.position = Vector2(12, 12)
	
	# ホバー・インタラクションエフェクトの追加 (Sprint 1)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.pivot_offset = Vector2(190, 260) / 2.0
	
	container.mouse_entered.connect(func():
		var tw = container.create_tween().set_parallel(true)
		tw.tween_property(container, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(container, "rotation_degrees", randf_range(-2.5, 2.5), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# 影の浮遊Tween (Sprint 1)
		tw.tween_property(shadow_rect, "position", Vector2(8, 12), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var style_dup = shadow_style.duplicate() as StyleBoxFlat
		style_dup.shadow_size = 14
		shadow_rect.add_theme_stylebox_override("panel", style_dup)
		
		var tw_shadow = container.create_tween()
		tw_shadow.tween_property(bg, "self_modulate", Color(1.04, 1.04, 1.08), 0.12)
	)
	container.mouse_exited.connect(func():
		var tw = container.create_tween().set_parallel(true)
		tw.tween_property(container, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(container, "rotation_degrees", 0.0, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# 影の復元 (Sprint 1)
		tw.tween_property(shadow_rect, "position", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var style_dup = shadow_style.duplicate() as StyleBoxFlat
		style_dup.shadow_size = 5
		shadow_rect.add_theme_stylebox_override("panel", style_dup)
		
		var tw_shadow = container.create_tween()
		tw_shadow.tween_property(bg, "self_modulate", Color.WHITE, 0.15)
	)
	
	return container

static func create_item_card_large(item_type: int, number: int = -1) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(190, 260)
	container.size = Vector2(190, 260)
	
	# 立体的なドロップシャドウ (Sprint 1)
	var shadow_rect = Panel.new()
	shadow_rect.name = "DropShadow"
	shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color.TRANSPARENT
	shadow_style.shadow_color = Color(0, 0, 0, 0.28)
	shadow_style.shadow_size = 5
	shadow_style.shadow_offset = Vector2(4, 6)
	shadow_style.corner_radius_top_left = 14; shadow_style.corner_radius_top_right = 14
	shadow_style.corner_radius_bottom_left = 14; shadow_style.corner_radius_bottom_right = 14
	shadow_rect.add_theme_stylebox_override("panel", shadow_style)
	container.add_child(shadow_rect)
	
	var bg = TextureRect.new()
	bg.texture = CARD_FRONT
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# アイテムは少し暗い色味にModulate
	bg.modulate = Color(0.9, 0.9, 0.95)
	container.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	container.add_child(vbox)
	
	var item_tex = item_texture(item_type)
	if item_tex:
		var icon = create_icon_rect(item_tex, Vector2(100, 100))
		vbox.add_child(icon)
		
	var name_str = ""
	var col = Color("5c5766")
	var it_char = "?"
	
	match item_type:
		Enums.ItemType.STICKY_NOTE:
			name_str = "付箋"; col = Color("ffd43b"); it_char = "付"
		Enums.ItemType.ERASER:
			name_str = "消しゴム"; col = Color("adb5bd"); it_char = "消"
		Enums.ItemType.RULER:
			name_str = "定規"; col = Color("4dabf7"); it_char = "定"
		Enums.ItemType.WORD_BOOK:
			name_str = "単語帳"; col = Color("3bc9db"); it_char = "単"
		Enums.ItemType.CHEAT_SHEET:
			name_str = "カンペ"; col = Color("94d82d"); it_char = "カ"
		Enums.ItemType.COMPASS:
			name_str = "コンパス"; col = Color("748ffc"); it_char = "コ"
		Enums.ItemType.ENERGY_DRINK:
			name_str = "エナドリ"; col = Color("fcc419"); it_char = "エ"
		Enums.ItemType.RED_SHEET:
			name_str = "赤シート"; col = Color("ff6b6b"); it_char = "赤"
		Enums.ItemType.MECHANICAL_PENCIL:
			name_str = "シャーペン"; col = Color("868e96"); it_char = "シ"
		Enums.ItemType.THICK_BOOK:
			name_str = "参考書"; col = Color("845ef7"); it_char = "参"
		Enums.ItemType.DELETE_CARD:
			name_str = "忘却ノート"; col = Color("495057"); it_char = "忘"
			
	var name_display = "%s (%d)" % [name_str, number] if number > 0 else name_str
	vbox.add_child(create_label(name_display, 20, col, true))
	
	# 左上にミニバッジを追加（重ね合わされても見えるように）
	var mini_badge = PanelContainer.new()
	mini_badge.name = "MiniBadge"
	mini_badge.custom_minimum_size = Vector2(30, 26)
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = col
	badge_style.corner_radius_top_left = 6
	badge_style.corner_radius_top_right = 6
	badge_style.corner_radius_bottom_left = 6
	badge_style.corner_radius_bottom_right = 6
	mini_badge.add_theme_stylebox_override("panel", badge_style)
	
	var mini_lbl = create_label(it_char, 13, Color.WHITE, true)
	mini_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mini_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mini_badge.add_child(mini_lbl)
	
	container.add_child(mini_badge)
	mini_badge.position = Vector2(12, 12)

	# 右上に数字バッジを追加（重ね合わされても数字がひと目で確認できるように）
	if number > 0:
		var num_badge = PanelContainer.new()
		num_badge.name = "NumberBadge"
		num_badge.custom_minimum_size = Vector2(34, 30)
		var num_style = StyleBoxFlat.new()
		if item_type == Enums.ItemType.CHEAT_SHEET or item_type == Enums.ItemType.ALL_NIGHTER or item_type == Enums.ItemType.ANSWER_KEY:
			num_style.bg_color = Color("d94040")
		elif item_type == Enums.ItemType.THICK_BOOK or item_type == Enums.ItemType.CRAM_SCHOOL:
			num_style.bg_color = COLOR_ACCENT_GOLD
		else:
			num_style.bg_color = Color("1a2636")
		num_style.corner_radius_top_left = 6
		num_style.corner_radius_top_right = 6
		num_style.corner_radius_bottom_left = 6
		num_style.corner_radius_bottom_right = 6
		num_style.border_width_left = 2; num_style.border_width_top = 2
		num_style.border_width_right = 2; num_style.border_width_bottom = 2
		num_style.border_color = Color.WHITE
		num_badge.add_theme_stylebox_override("panel", num_style)
		
		var num_lbl = create_label(str(number), 14, Color.WHITE, true)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_badge.add_child(num_lbl)
		
		container.add_child(num_badge)
		num_badge.position = Vector2(190 - 34 - 12, 12)
	
	# ホバー・インタラクションエフェクトの追加 (Sprint 1)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.pivot_offset = Vector2(190, 260) / 2.0
	
	container.mouse_entered.connect(func():
		var tw = container.create_tween().set_parallel(true)
		tw.tween_property(container, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(container, "rotation_degrees", randf_range(-2.5, 2.5), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# 影の浮遊Tween (Sprint 1)
		tw.tween_property(shadow_rect, "position", Vector2(8, 12), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var style_dup = shadow_style.duplicate() as StyleBoxFlat
		style_dup.shadow_size = 14
		shadow_rect.add_theme_stylebox_override("panel", style_dup)
		
		var tw_shadow = container.create_tween()
		tw_shadow.tween_property(bg, "self_modulate", Color(1.04, 1.04, 1.08), 0.12)
	)
	container.mouse_exited.connect(func():
		var tw = container.create_tween().set_parallel(true)
		tw.tween_property(container, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(container, "rotation_degrees", 0.0, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# 影の復元 (Sprint 1)
		tw.tween_property(shadow_rect, "position", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var style_dup = shadow_style.duplicate() as StyleBoxFlat
		style_dup.shadow_size = 5
		shadow_rect.add_theme_stylebox_override("panel", style_dup)
		
		var tw_shadow = container.create_tween()
		tw_shadow.tween_property(bg, "self_modulate", Color.WHITE, 0.15)
	)
	
	return container

static func create_gauge_bar(value: float, max_val: float, fill_color: Color, bar_size: Vector2 = Vector2(200, 18)) -> Control:
	var wrap_ctrl = PanelContainer.new()
	wrap_ctrl.custom_minimum_size = bar_size
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.14, 0.12, 0.10, 0.18)
	bg_style.corner_radius_top_left = 4; bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4; bg_style.corner_radius_bottom_right = 4
	wrap_ctrl.add_theme_stylebox_override("panel", bg_style)
	# 塗り部分（角丸付き）
	var fill = Panel.new()
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 4; fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4; fill_style.corner_radius_bottom_right = 4
	fill.add_theme_stylebox_override("panel", fill_style)
	fill.anchor_bottom = 1.0
	var ratio: float = clamp(value / max(max_val, 1.0), 0.0, 1.0)
	fill.offset_right = max(4.0, bar_size.x * ratio)
	wrap_ctrl.add_child(fill)
	return wrap_ctrl

static func create_dialog_overlay(root: Control, title_text: String, build_content: Callable, min_size: Vector2 = Vector2(1000, 720)) -> ColorRect:
	var overlay = ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.07, 0.76)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	
	# 黒板調パネルを生成！学校世界観にピッタリ調和します
	var board = create_blackboard_panel(min_size)
	board.anchor_left = 0.5; board.anchor_top = 0.5; board.anchor_right = 0.5; board.anchor_bottom = 0.5
	board.offset_left = -min_size.x / 2.0; board.offset_top = -min_size.y / 2.0
	board.offset_right = min_size.x / 2.0; board.offset_bottom = min_size.y / 2.0
	overlay.add_child(board)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	apply_font(vbox)
	vbox.add_theme_constant_override("separation", 24)
	board.find_child("Content", true, false).add_child(vbox)
	
	# チョークイエローでタイトルを大きく描写
	vbox.add_child(create_label(title_text, 38, COLOR_CHALK_YELLOW, true))
	
	# チョークで引いたような手描き風の白い下線ディバイダー (Sprint 2)
	var divider = Panel.new()
	divider.custom_minimum_size = Vector2(0, 4)
	var div_style = StyleBoxFlat.new()
	div_style.bg_color = COLOR_CHALK_WHITE
	div_style.corner_radius_top_left = 2; div_style.corner_radius_top_right = 2
	div_style.corner_radius_bottom_left = 2; div_style.corner_radius_bottom_right = 2
	div_style.shadow_color = Color(1.0, 1.0, 1.0, 0.15)
	div_style.shadow_size = 2
	divider.add_theme_stylebox_override("panel", div_style)
	vbox.add_child(divider)
	
	# スペーサー
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	if build_content.is_valid():
		build_content.call(vbox)
	return overlay

static func create_floating_badge(text: String, tint: Color, font_size: int = 18) -> PanelContainer:
	var badge = PanelContainer.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style = StyleBoxFlat.new()
	style.bg_color = tint
	style.corner_radius_top_left = 20; style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20; style.corner_radius_bottom_right = 20
	style.content_margin_left = 16; style.content_margin_right = 16
	badge.add_theme_stylebox_override("panel", style)
	badge.add_child(create_label(text, font_size, Color.WHITE if tint.v < 0.6 else COLOR_INK, true))
	return badge

static func create_app_stamp(text: String, tint: Color, font_size: int = 24) -> Control:
	var root = Control.new()
	root.custom_minimum_size = Vector2(240, 80)
	root.size = Vector2(240, 80)
	
	# 外枠の影
	var shadow = Panel.new()
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.12)
	shadow_style.corner_radius_top_left = 14; shadow_style.corner_radius_top_right = 14
	shadow_style.corner_radius_bottom_left = 14; shadow_style.corner_radius_bottom_right = 14
	shadow_style.shadow_color = Color(0, 0, 0, 0.20)
	shadow_style.shadow_size = 5
	shadow_style.shadow_offset = Vector2(3, 5)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	root.add_child(shadow)
	
	# 外枠のインク背景
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(tint.r, tint.g, tint.b, 0.12) # インクの透け感
	bg_style.border_width_left = 5; bg_style.border_width_right = 5
	bg_style.border_width_top = 5; bg_style.border_width_bottom = 5
	bg_style.border_color = tint
	bg_style.corner_radius_top_left = 12; bg_style.corner_radius_top_right = 12
	bg_style.corner_radius_bottom_left = 12; bg_style.corner_radius_bottom_right = 12
	bg.add_theme_stylebox_override("panel", bg_style)
	root.add_child(bg)
	
	# 内枠のライン
	var inner = Panel.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 9; inner.offset_top = 9; inner.offset_right = -9; inner.offset_bottom = -9
	var inner_style = StyleBoxFlat.new()
	inner_style.bg_color = Color.TRANSPARENT
	inner_style.border_width_left = 2; inner_style.border_width_right = 2
	inner_style.border_width_top = 2; inner_style.border_width_bottom = 2
	inner_style.border_color = Color(tint.r, tint.g, tint.b, 0.65)
	inner_style.corner_radius_top_left = 8; inner_style.corner_radius_top_right = 8
	inner_style.corner_radius_bottom_left = 8; inner_style.corner_radius_bottom_right = 8
	inner.add_theme_stylebox_override("panel", inner_style)
	root.add_child(inner)
	
	# ラベル
	var lbl = create_label(text, font_size, tint, true)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# インクのにじみ・スタンプ感を出すための極厚アウトライン
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.add_theme_color_override("font_outline_color", Color(tint.r, tint.g, tint.b, 0.22))
	root.add_child(lbl)
	
	return root

static func create_mini_stamp(text: String, tint: Color, font_size: int = 13) -> Control:
	var root = Control.new()
	root.custom_minimum_size = Vector2(130, 36)
	root.size = Vector2(130, 36)
	
	# インク背景
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(tint.r, tint.g, tint.b, 0.12)
	bg_style.border_width_left = 2; bg_style.border_width_right = 2
	bg_style.border_width_top = 2; bg_style.border_width_bottom = 2
	bg_style.border_color = tint
	bg_style.corner_radius_top_left = 6; bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6; bg_style.corner_radius_bottom_right = 6
	bg.add_theme_stylebox_override("panel", bg_style)
	root.add_child(bg)
	
	# 内枠
	var inner = Panel.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 4; inner.offset_top = 4; inner.offset_right = -4; inner.offset_bottom = -4
	var inner_style = StyleBoxFlat.new()
	inner_style.bg_color = Color.TRANSPARENT
	inner_style.border_width_left = 1; inner_style.border_width_right = 1
	inner_style.border_width_top = 1; inner_style.border_width_bottom = 1
	inner_style.border_color = Color(tint.r, tint.g, tint.b, 0.6)
	inner_style.corner_radius_top_left = 4; inner_style.corner_radius_top_right = 4
	inner_style.corner_radius_bottom_left = 4; inner_style.corner_radius_bottom_right = 4
	inner.add_theme_stylebox_override("panel", inner_style)
	root.add_child(inner)
	
	# ラベル
	var lbl = create_label(text, font_size, tint, true)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(tint.r, tint.g, tint.b, 0.20))
	root.add_child(lbl)
	
	return root

static func animate_entrance(node: Control, delay: float = 0.0) -> void:
	node.modulate.a = 0
	var orig_y = node.position.y
	node.position.y = orig_y + 20.0
	var tw = node.create_tween().set_parallel(true)
	tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
	tw.tween_property(node, "position:y", orig_y, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)

static func create_button(text: String, min_size: Vector2, fill: Color = COLOR_SAFE, edge: Color = Color("0e5057"), dark_text: bool = false, font_size: int = 20) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.size = min_size
	if DEFAULT_FONT:
		btn.add_theme_font_override("font", DEFAULT_FONT)
	btn.add_theme_font_size_override("font_size", font_size) # 文字サイズを適用！
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = 14; style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14; style.corner_radius_bottom_right = 14
	style.border_width_bottom = 5; style.border_color = edge
	btn.add_theme_stylebox_override("normal", style)
	var hov = style.duplicate()
	hov.bg_color = fill.lightened(0.1)
	btn.add_theme_stylebox_override("hover", hov)
	var prs = style.duplicate()
	prs.bg_color = fill.darkened(0.1)
	prs.border_width_bottom = 2
	prs.content_margin_top = 3
	btn.add_theme_stylebox_override("pressed", prs)
	btn.add_theme_color_override("font_color", COLOR_INK if dark_text else Color.WHITE)
	return btn

static func create_label(text: String, size: int, color: Color = COLOR_INK, centered: bool = false) -> Label:
	var label = Label.new()
	label.text = text
	if DEFAULT_FONT:
		label.add_theme_font_override("font", DEFAULT_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if centered: label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label



static func create_icon_rect(texture: Texture2D, min_size: Vector2) -> TextureRect:
	var rect = TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = min_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect

static func style_input(control: Control) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_width_bottom = 2
	style.border_color = COLOR_INK
	style.content_margin_left = 10
	control.add_theme_stylebox_override("normal", style)
	control.add_theme_stylebox_override("focus", style)

static func create_stat_chip(text: String, tint: Color, font_size: int = 16) -> PanelContainer:
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = tint
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	style.content_margin_left = 10; style.content_margin_right = 10
	chip.add_theme_stylebox_override("panel", style)
	# 常に白文字にすることで、抜群の視認性と高級感を担保します！
	chip.add_child(create_label(text, font_size, Color.WHITE, true))
	return chip

static func subject_color(subject: int) -> Color:
	match subject:
		Enums.Subject.JAPANESE: return Color("d95b59")
		Enums.Subject.MATH: return Color("4a7de0")
		Enums.Subject.ENGLISH: return Color("c78300") # 白文字が映える高級アパレル調アンバー
		Enums.Subject.SCIENCE: return Color("56b97a")
		Enums.Subject.SOCIAL_STUDIES: return Color("8a68d8")
	return COLOR_MUTED

static func subject_name(subject: int) -> String:
	match subject:
		Enums.Subject.JAPANESE: return "国語"
		Enums.Subject.MATH: return "数学"
		Enums.Subject.ENGLISH: return "英語"
		Enums.Subject.SCIENCE: return "理科"
		Enums.Subject.SOCIAL_STUDIES: return "社会"
	return "???"

static func item_texture(item_type: int) -> Texture2D:
	match item_type:
		Enums.ItemType.STICKY_NOTE: return ITEM_PEN
		Enums.ItemType.ERASER: return ITEM_ERASER
		Enums.ItemType.RULER: return ITEM_RULER
		Enums.ItemType.WORD_BOOK: return ITEM_RULER
		Enums.ItemType.CHEAT_SHEET: return ITEM_PEN
		Enums.ItemType.COMPASS: return ITEM_RULER
		Enums.ItemType.ENERGY_DRINK: return ITEM_PEN
		Enums.ItemType.RED_SHEET: return ITEM_RULER
		Enums.ItemType.MECHANICAL_PENCIL: return ITEM_PEN
		Enums.ItemType.THICK_BOOK: return ITEM_RULER
	return null

static func subject_texture(subject: int) -> Texture2D:
	match subject:
		Enums.Subject.JAPANESE: return SUBJECT_JAPANESE
		Enums.Subject.MATH: return SUBJECT_MATH
		Enums.Subject.ENGLISH: return SUBJECT_ENGLISH
		Enums.Subject.SCIENCE: return SUBJECT_SCIENCE
		Enums.Subject.SOCIAL_STUDIES: return SUBJECT_SOCIAL
	return null
