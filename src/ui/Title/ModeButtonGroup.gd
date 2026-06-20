class_name ModeButtonGroup
extends VBoxContainer

signal start_pressed(mode: String)

var selected_mode: String = "national"

var buttons_hbox: HBoxContainer
var desc_label: Label
var start_button: Button

var mode_buttons: Dictionary = {}
var initial_rotations: Dictionary = {}
var normal_styles: Dictionary = {}
var active_styles: Dictionary = {}

const MODES = {
	"national": {
		"title": "模試",
		"desc": "CPUと対戦して自分の実力を試します。\n対戦成績による偏差値の変動はありません。",
		"action_text": "模試を受ける",
		"icon": "res://assets/icons/book.svg",
		"bg_color": Color("e3f2fd"),
		"border_color": Color("90caf9")
	},
	"friend": {
		"title": "フレンド戦",
		"desc": "ルームコードを共有して特定の友達と対戦します。\n対戦成績による偏差値の変動はありません。",
		"action_text": "フレンドと合流",
		"icon": "res://assets/icons/users.svg",
		"bg_color": Color("e8f5e9"),
		"border_color": Color("a5d6a7")
	},
	"random": {
		"title": "ランダム戦",
		"desc": "全国のオンラインプレイヤーとリアルタイムで対戦します。\n対戦成績に応じて偏差値が変動します。",
		"action_text": "全国マッチを開始する",
		"icon": "res://assets/icons/globe.svg",
		"bg_color": Color("fff3e0"),
		"border_color": Color("ffcc80")
	}
}

func _ready() -> void:
	add_theme_constant_override("separation", 18)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 1. ボタンを並べるHBox
	buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 15)
	buttons_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(buttons_hbox)
	
	# 各ボタンの作成
	for mode_key in MODES.keys():
		var data = MODES[mode_key]
		var btn = _create_sticky_button(mode_key, data["title"], data["icon"], data["bg_color"], data["border_color"])
		buttons_hbox.add_child(btn)
		mode_buttons[mode_key] = btn
		
		# シグナル接続
		btn.pressed.connect(func():
			_select_mode(mode_key)
		)
	
	# 2. 説明文ラベル
	desc_label = Label.new()
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_override("font", DeskTheme.get_font())
	desc_label.add_theme_font_size_override("font_size", 20) # 20pxにサイズアップ
	desc_label.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(0, 60) # 高さを少し広げる
	add_child(desc_label)
	
	# 3. アクション（開始）ボタン
	start_button = Button.new()
	start_button.add_to_group("important_button")
	start_button.custom_minimum_size = Vector2(320, 60)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.add_theme_font_override("font", DeskTheme.get_font())
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.add_theme_constant_override("outline_size", 6)
	start_button.add_theme_color_override("font_outline_color", Color("2d1a0c"))
	
	# 開始ボタンの特別なスタイル（TENSIONカラーのピンク）
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = DeskTheme.COLOR_TENSION # ff4081 (テンションピンク)
	style_normal.border_color = DeskTheme.COLOR_INK
	style_normal.border_width_left = 4
	style_normal.border_width_right = 4
	style_normal.border_width_top = 4
	style_normal.border_width_bottom = 8
	style_normal.corner_radius_top_left = 12
	style_normal.corner_radius_top_right = 12
	style_normal.corner_radius_bottom_left = 12
	style_normal.corner_radius_bottom_right = 12
	style_normal.shadow_color = Color(0, 0, 0, 0.2)
	style_normal.shadow_size = 8
	style_normal.shadow_offset = Vector2(3, 5)
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color("ff80ab") # ホバー時は少し明るいピンク
	style_hover.shadow_size = 10
	style_hover.shadow_offset = Vector2(4, 6)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color("c51162") # プレス時は濃いピンク
	style_pressed.border_width_bottom = 3
	style_pressed.shadow_size = 3
	style_pressed.shadow_offset = Vector2(1, 2)
	
	start_button.add_theme_stylebox_override("normal", style_normal)
	start_button.add_theme_stylebox_override("hover", style_hover)
	start_button.add_theme_stylebox_override("pressed", style_pressed)
	start_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	start_button.add_theme_color_override("font_color", Color.WHITE)
	start_button.add_theme_color_override("font_hover_color", Color.WHITE)
	start_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	
	start_button.pressed.connect(func():
		start_button.release_focus()
		if get_tree().root.has_node("AudioManager"):
			var audio = get_tree().root.get_node("AudioManager")
			audio.play_se(audio.SE_CLICK)
		# 軽いバウンスアニメーション
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(start_button, "scale", Vector2.ONE * 0.94, 0.06)
		tween.tween_property(start_button, "scale", Vector2.ONE, 0.06)
		tween.chain().tween_callback(func():
			start_pressed.emit(selected_mode)
		)
	)
	start_button.pivot_offset = Vector2(160, 30)
	
	start_button.mouse_entered.connect(func(): DeskTheme.animate_hover(start_button, true, Vector2.ONE, 0.1))
	start_button.mouse_exited.connect(func(): DeskTheme.animate_hover(start_button, false, Vector2.ONE, 0.1))
	
	add_child(start_button)
	
	# 初期状態の選択
	_select_mode(selected_mode)

func _create_sticky_button(mode_key: String, title_text: String, icon_path: String, bg_color: Color, border_color: Color) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(130, 115)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_contents = false
	
	# スタイルBOXの作成
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = bg_color
	normal_style.border_width_bottom = 4
	normal_style.border_color = border_color
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	normal_style.corner_radius_bottom_left = 2
	normal_style.corner_radius_bottom_right = 2
	normal_style.corner_radius_top_left = 2
	normal_style.corner_radius_top_right = 2
	normal_style.shadow_color = Color(0.15, 0.1, 0.08, 0.12)
	normal_style.shadow_size = 3
	normal_style.shadow_offset = Vector2(1, 2)
	
	# 選択されたアクティブ用のスタイルBOX
	var active_style = normal_style.duplicate()
	active_style.bg_color = bg_color.lightened(0.04)
	active_style.border_color = DeskTheme.COLOR_TENSION # アクティブな枠線カラー
	active_style.border_width_left = 2
	active_style.border_width_right = 2
	active_style.border_width_top = 2
	active_style.border_width_bottom = 6
	active_style.shadow_color = Color(0.15, 0.1, 0.08, 0.22)
	active_style.shadow_size = 7
	active_style.shadow_offset = Vector2(2, 5)
	
	normal_styles[mode_key] = normal_style
	active_styles[mode_key] = active_style
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", active_style)
	btn.add_theme_stylebox_override("pressed", active_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# 内部のレイアウト
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	
	if ResourceLoader.exists(icon_path):
		var icon_rect = TextureRect.new()
		icon_rect.texture = load(icon_path)
		icon_rect.custom_minimum_size = Vector2(36, 36)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.modulate = DeskTheme.COLOR_INK
		vbox.add_child(icon_rect)
		
	var lbl_title = Label.new()
	lbl_title.text = title_text
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_override("font", DeskTheme.get_font())
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	lbl_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl_title)
	
	# マスキングテープ
	var tape = ColorRect.new()
	tape.color = Color(1.0, 1.0, 1.0, 0.45)
	tape.custom_minimum_size = Vector2(40, 12)
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tape)
	
	tape.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tape.anchor_left = 0.5
	tape.anchor_right = 0.5
	tape.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tape.offset_top = -6
	tape.offset_left = -20
	tape.rotation_degrees = randf_range(-8.0, 8.0)
	
	btn.pivot_offset = Vector2(65, 57.5)
	
	var rot = randf_range(-2.0, 2.0)
	btn.rotation_degrees = rot
	initial_rotations[mode_key] = rot
	
	return btn

func _select_mode(mode_key: String) -> void:
	if not MODES.has(mode_key):
		return
		
	selected_mode = mode_key
	
	var data = MODES[mode_key]
	desc_label.text = data["desc"]
	start_button.text = data["action_text"]
	
	# 音声の再生
	if is_inside_tree() and get_tree().root.has_node("AudioManager"):
		var audio = get_tree().root.get_node("AudioManager")
		audio.play_se(audio.SE_CLICK)
	
	# 各ボタンのビジュアルと位置を更新
	for k in mode_buttons.keys():
		var btn = mode_buttons[k]
		var is_active = (k == mode_key)
		
		# アクティブな付箋は上に浮き上がり、目立たせる
		var target_y = -10.0 if is_active else 0.0
		var target_scale = Vector2.ONE * 1.08 if is_active else Vector2.ONE
		var target_rot = initial_rotations[k] + (randf_range(-1.0, 1.0) if is_active else 0.0)
		
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "position:y", target_y, 0.15)
		tween.tween_property(btn, "scale", target_scale, 0.15)
		tween.tween_property(btn, "rotation_degrees", target_rot, 0.15)
		
		if is_active:
			btn.add_theme_stylebox_override("normal", active_styles[k])
		else:
			btn.add_theme_stylebox_override("normal", normal_styles[k])
