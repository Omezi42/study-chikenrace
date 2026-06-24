class_name TitleScene
extends Control

var bg_color: ColorRect
var title_logo: TitleLogo
var mode_button_group: VBoxContainer
var top_right_btn_hbox: HBoxContainer

const NATIONAL_NAMES = [
	"東大理三志望", "早慶合格マシーン", "徹夜明けの浪人生", "定期テストの神", 
	"赤点回避の守護神", "進研ゼミの覇者", "赤門くぐり隊", "偏差値70の天才",
	"単語帳と友達", "エナドリ中毒者", "短期集中のプロ", "授業中居眠りマン",
	"ガリ勉強眼鏡", "天才肌の帰国子女", "数学オリンピック選手"
]

func _ready() -> void:
	Global.is_tutorial_mode = false
	
	bg_color = ColorRect.new()
	bg_color.color = DeskTheme.COLOR_CRAFT
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 60)
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)
	
	var logo_container = CenterContainer.new()
	logo_container.custom_minimum_size = Vector2(0, 300)
	main_vbox.add_child(logo_container)
	
	title_logo = TitleLogo.new()
	title_logo.scale = Vector2(2.0, 2.0)
	logo_container.add_child(title_logo)
	
	mode_button_group = VBoxContainer.new()
	mode_button_group.add_theme_constant_override("separation", 24)
	mode_button_group.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(mode_button_group)
	
	_add_mode_button("ソロ模試", "CPUと対戦するオフラインモード", func():
		DeskTheme.animate_click(mode_button_group.get_child(0), Vector2.ONE, 0.08)
		Global.game_mode = Constants.MODE_CPU
		_start_cpu_match()
	)
	
	_add_mode_button("フレンド対戦", "合言葉で友達と対戦", func():
		DeskTheme.animate_click(mode_button_group.get_child(1), Vector2.ONE, 0.08)
		FriendLobbyModal.create_selection_modal(self)
	)
	
	_add_mode_button("ランダム対戦", "全国のプレイヤーと対戦", func():
		DeskTheme.animate_click(mode_button_group.get_child(2), Vector2.ONE, 0.08)
		Global.game_mode = Constants.MODE_RANDOM
		if not has_node("/root/WebRTCManager"):
			return
		var wrm = get_node("/root/WebRTCManager")
		ModeSelectionModal._show_matching_lobby(self, null, wrm, NATIONAL_NAMES, func(): FriendLobbyModal.create_selection_modal(self))
	)
	
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_hbox.add_theme_constant_override("separation", 40)
	main_vbox.add_child(bottom_hbox)
	
	var how_to_btn = Button.new()
	how_to_btn.text = "あそびかた"
	how_to_btn.custom_minimum_size = Vector2(200, 60)
	how_to_btn.add_theme_font_override("font", DeskTheme.get_font())
	how_to_btn.add_theme_font_size_override("font_size", 20)
	Global.apply_white_button_style(how_to_btn)
	how_to_btn.pressed.connect(func():
		DeskTheme.animate_click(how_to_btn, Vector2.ONE, 0.08)
		RulebookModal.create_and_show(self)
	)
	bottom_hbox.add_child(how_to_btn)
	
	var settings_btn = Button.new()
	settings_btn.text = "設定・名前"
	settings_btn.custom_minimum_size = Vector2(200, 60)
	settings_btn.add_theme_font_override("font", DeskTheme.get_font())
	settings_btn.add_theme_font_size_override("font_size", 20)
	Global.apply_white_button_style(settings_btn)
	settings_btn.pressed.connect(func():
		DeskTheme.animate_click(settings_btn, Vector2.ONE, 0.08)
		SettingsModal.create_and_show(self)
	)
	bottom_hbox.add_child(settings_btn)
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_MAIN, 1.5)

func _add_mode_button(title_text: String, desc_text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(500, 100)
	Global.apply_white_button_style(btn)
	
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
	desc_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	inner.add_child(desc_lbl)
	
	btn.pressed.connect(callback)
	mode_button_group.add_child(btn)

func _start_cpu_match() -> void:
	var pool = NATIONAL_NAMES.duplicate()
	pool.shuffle()
	var cpu_pool_keys = AIManager.CPU_OPPONENTS.keys().duplicate()
	cpu_pool_keys.shuffle()
	
	Global.opponent_profiles = {
		"cpu_sato": {
			"id": cpu_pool_keys[0],
			"name": pool[0],
			"deviation": 50.0
		},
		"cpu_suzuki": {
			"id": cpu_pool_keys[1],
			"name": pool[1],
			"deviation": 50.0
		},
		"cpu_takahashi": {
			"id": cpu_pool_keys[2],
			"name": pool[2],
			"deviation": 50.0
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
