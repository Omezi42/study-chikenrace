class_name TitleScene
extends Control

var bg_tex: TextureRect
var main_notebook: PanelContainer
var title_logo: TitleLogo
var mode_button_group: Control
var sticky_buttons: Array[Control] = []

const NATIONAL_NAMES = [
	"東大理三志望", "早慶合格マシーン", "徹夜明けの浪人生", "定期テストの神", 
	"赤点回避の守護神", "進研ゼミの覇者", "赤門くぐり隊", "偏差値70の天才",
	"単語帳と友達", "エナドリ中毒者", "短期集中のプロ", "授業中居眠りマン",
	"ガリ勉強眼鏡", "天才肌の帰国子女", "数学オリンピック選手"
]

func _ready() -> void:
	Global.is_tutorial_mode = false
	
	# 背景画像
	bg_tex = TextureRect.new()
	if ResourceLoader.exists("res://assets/机の背景画像-ノート無し.png"):
		bg_tex.texture = load("res://assets/机の背景画像-ノート無し.png")
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_tex)
	
	# 中央配置用のラッパー (確実に中央に固定するため)
	var center_wrapper = CenterContainer.new()
	center_wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_wrapper)
	
	# 中央の大きなノートコンテナ
	main_notebook = PanelContainer.new()
	main_notebook.custom_minimum_size = Vector2(800, 800)
	main_notebook.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	
	# 罫線を追加
	DeskTheme.add_ruled_lines(main_notebook)
	center_wrapper.add_child(main_notebook)
	
	# ノート内の要素を配置するVBox
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 50)
	main_notebook.add_child(vbox)
	
	# ロゴ
	var logo_container = CenterContainer.new()
	logo_container.custom_minimum_size = Vector2(0, 250)
	vbox.add_child(logo_container)
	
	title_logo = TitleLogo.new()
	title_logo.scale = Vector2(1.8, 1.8)
	logo_container.add_child(title_logo)
	
	# モードボタン群
	mode_button_group = VBoxContainer.new()
	mode_button_group.add_theme_constant_override("separation", 35)
	mode_button_group.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(mode_button_group)
	
	# 各ボタンの追加（付箋風）
	_add_sticky_button("チュートリアル", "遊び方とルールを対戦しながら学ぶ", "green", 2.0, func():
		Global.is_tutorial_mode = true
		Global.game_mode = Constants.MODE_CPU
		Global.opponent_profiles = {
			"cpu_sato": {"name": "佐藤くん"},
			"cpu_suzuki": {"name": "鈴木さん"},
			"cpu_takahashi": {"name": "高橋くん"}
		}
		if Global.player_name == "":
			Global.player_name = "プレイヤー"
		var tree = get_tree()
		if tree:
			Global.change_scene_with_fade(tree, "res://Main.tscn")
	)
	
	_add_sticky_button("ソロ模試", "CPUと対戦するオフラインモード", "blue", -1.5, func():
		Global.game_mode = Constants.MODE_CPU
		_start_cpu_match()
	)
	
	_add_sticky_button("フレンド対戦", "合言葉で友達と対戦", "yellow", 1.0, func():
		FriendLobbyModal.create_selection_modal(self)
	)
	
	_add_sticky_button("ランダム対戦", "全国のプレイヤーと対戦", "red", -0.8, func():
		Global.game_mode = Constants.MODE_RANDOM
		if not has_node("/root/WebRTCManager"):
			return
		var wrm = get_node("/root/WebRTCManager")
		ModeSelectionModal._show_matching_lobby(self, null, wrm, NATIONAL_NAMES, func(): FriendLobbyModal.create_selection_modal(self))
	)
	
	# 右下・左下に散らばっていた設定や遊び方の付箋を、ノート内にまとめる
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(bottom_hbox)
	
	_add_small_sticky(bottom_hbox, "あそびかた", "green", -3.0, func():
		RulebookModal.create_and_show(self)
	)
	
	_add_small_sticky(bottom_hbox, "設定・名前", "orange", 4.5, func():
		SettingsModal.create_and_show(self)
	)
	
	# BGM
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_MAIN, 1.5)
		
	# アニメーション開始
	_start_entrance_animation()

func _start_entrance_animation() -> void:
	# Positionでのアニメーションはレイアウトコンフリクトを起こしやすいため、
	# ScaleとAlphaのフェードインに変更して安全かつリッチに表示する
	main_notebook.modulate.a = 0.0
	main_notebook.pivot_offset = main_notebook.custom_minimum_size / 2.0
	main_notebook.scale = Vector2(0.9, 0.9)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(main_notebook, "scale", Vector2.ONE, 0.6)
	tween.tween_property(main_notebook, "modulate:a", 1.0, 0.5)
	
	# 付箋のフェードイン（時間差）
	for i in range(sticky_buttons.size()):
		var btn = sticky_buttons[i]
		btn.modulate.a = 0.0
		var delay = 0.3 + i * 0.15
		var inner_tween = create_tween().bind_node(btn).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		inner_tween.tween_interval(delay)
		inner_tween.tween_property(btn, "modulate:a", 1.0, 0.3)
		inner_tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.4).from(Vector2(0.5, 0.5))
		


func _add_sticky_button(title_text: String, desc_text: String, color: String, rot: float, callback: Callable) -> void:
	var btn_container = CenterContainer.new()
	btn_container.custom_minimum_size = Vector2(400, 90)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(380, 85)
	btn.add_theme_stylebox_override("normal", DeskTheme.create_sticky_note_style(color))
	
	# ホバーやプレスのスタイルも少し変更（浮き出る感じ）
	var hover_style = DeskTheme.create_sticky_note_style(color)
	hover_style.shadow_size = 8
	hover_style.shadow_offset = Vector2(3, 4)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", DeskTheme.create_sticky_note_style(color))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	btn.rotation_degrees = rot
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	
	var inner = VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner)
	
	var title_lbl = Label.new()
	title_lbl.text = title_text
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	inner.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc_text
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.7))
	inner.add_child(desc_lbl)
	
	btn.mouse_entered.connect(func(): DeskTheme.animate_hover(btn, true, Vector2.ONE))
	btn.mouse_exited.connect(func(): DeskTheme.animate_hover(btn, false, Vector2.ONE))
	
	btn.pressed.connect(func():
		DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
		callback.call()
	)
	
	btn_container.add_child(btn)
	mode_button_group.add_child(btn_container)
	sticky_buttons.append(btn)

func _add_small_sticky(parent: Control, text: String, color: String, rot: float, callback: Callable) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(200, 60)
	btn.add_theme_stylebox_override("normal", DeskTheme.create_sticky_note_style(color))
	
	var hover_style = DeskTheme.create_sticky_note_style(color)
	hover_style.shadow_size = 6
	hover_style.shadow_offset = Vector2(2, 3)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", DeskTheme.create_sticky_note_style(color))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	btn.text = text
	btn.add_theme_font_override("font", DeskTheme.get_font())
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	
	btn.rotation_degrees = rot
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	
	btn.mouse_entered.connect(func(): DeskTheme.animate_hover(btn, true, Vector2.ONE))
	btn.mouse_exited.connect(func(): DeskTheme.animate_hover(btn, false, Vector2.ONE))
	
	btn.pressed.connect(func():
		DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
		callback.call()
	)
	
	parent.add_child(btn)
	sticky_buttons.append(btn)


func _start_cpu_match() -> void:
	var pool = NATIONAL_NAMES.duplicate()
	pool.shuffle()
	var cpu_pool_keys = AIManager.CPU_OPPONENTS.keys().duplicate()
	cpu_pool_keys.shuffle()
	
	Global.opponent_profiles = {
		"cpu_sato": {
			"id": cpu_pool_keys[0],
			"name": pool[0]
		},
		"cpu_suzuki": {
			"id": cpu_pool_keys[1],
			"name": pool[1]
		},
		"cpu_takahashi": {
			"id": cpu_pool_keys[2],
			"name": pool[2]
		}
	}
	Global.save_game()
	
	var start_game = func():
		if Global.player_name == "":
			SettingsModal.create_and_show(self)
		else:
			Global.change_scene_with_fade(get_tree(), "res://Main.tscn")

	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(start_game)
