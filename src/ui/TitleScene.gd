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
	
	# 中央の大きなノートコンテナ（直接配置で正確にセンタリング）
	main_notebook = PanelContainer.new()
	main_notebook.custom_minimum_size = Vector2(760, 680)
	var craft_panel = DeskTheme.create_craft_panel()
	craft_panel.content_margin_top = 24
	craft_panel.content_margin_bottom = 28
	main_notebook.add_theme_stylebox_override("panel", craft_panel)
	
	# 罫線を追加
	DeskTheme.add_ruled_lines(main_notebook)
	add_child(main_notebook)
	
	# ノート内の要素を配置するVBox
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	main_notebook.add_child(vbox)
	
	# ロゴ
	var logo_container = CenterContainer.new()
	logo_container.custom_minimum_size = Vector2(0, 160)
	vbox.add_child(logo_container)
	
	title_logo = TitleLogo.new()
	title_logo.scale = Vector2(1.5, 1.5)
	logo_container.add_child(title_logo)
	
	# モードボタン群
	mode_button_group = VBoxContainer.new()
	mode_button_group.add_theme_constant_override("separation", 12)
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
		_show_difficulty_selection()
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
	bottom_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(bottom_hbox)
	
	_add_small_sticky(bottom_hbox, "あそびかた", "green", -2.0, func():
		RulebookModal.create_and_show(self)
	)
	
	_add_small_sticky(bottom_hbox, "設定・名前", "orange", 2.0, func():
		SettingsModal.create_and_show(self)
	)
	
	# BGM
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm(AudioManager.BGM_MAIN, 1.5)
		
	# アニメーション開始
	if has_node("/root/ResponsiveScaler"):
		var rs = get_node("/root/ResponsiveScaler")
		if not rs.scale_changed.is_connected(_on_scale_changed):
			rs.scale_changed.connect(_on_scale_changed)
	_start_entrance_animation()
	
	# フレンド対戦から戻ってきた場合は自動的にロビーを開く
	if Global.return_to_friend_lobby:
		Global.return_to_friend_lobby = false
		FriendLobbyModal.show_lobby(self, Global.friend_room_code, Global.friend_is_host)

func _get_target_notebook_scale() -> Vector2:
	return Vector2.ONE

func _on_scale_changed(_new_scale: float) -> void:
	_update_layout()

func _update_layout() -> void:
	if not is_instance_valid(main_notebook):
		return
	var vp_size = get_viewport_rect().size
	if vp_size.x == 0:
		vp_size = Vector2(1500, 850)
		
	# ビットマップ引き伸ばしによる「文字のぼやけ」を完全に防止するため scale は絶対に等倍 1.0 に固定する
	main_notebook.scale = Vector2.ONE
	
	var is_portrait = vp_size.y > vp_size.x
	
	# ノートのサイズを画面に合わせていっぱいに広げる（「真ん中にちっちゃくあるだけ」を完全に廃止！）
	var target_w: float
	var target_h: float
	if is_portrait:
		# 縦画面：画面幅・高さの約92〜94%をしっかり使って広々と配置
		target_w = clamp(vp_size.x - 32.0, 320.0, vp_size.x - 20.0)
		target_h = clamp(vp_size.y - 48.0, 480.0, vp_size.y - 20.0)
	else:
		# 横画面：PC等の画面中央にバランスよく配置。モバイルの横画面でもはみ出ないように高さを制限
		var min_h = min(vp_size.y - 10.0, 640.0)
		target_h = clamp(vp_size.y - 20.0, min_h, 840.0)
		target_w = clamp(target_h * 0.95, 300.0, 850.0)
		
	main_notebook.custom_minimum_size = Vector2(target_w, target_h)
	main_notebook.size = Vector2(target_w, target_h)
	
	# ノートを画面中央に正確に配置
	main_notebook.pivot_offset = Vector2.ZERO
	main_notebook.position = Vector2((vp_size.x - target_w) * 0.5, (vp_size.y - target_h) * 0.5)
	
	# ノートの大きさに合わせて全UI要素（ロゴ、ボタン、フォント）の拡大倍率（ui_scale）を均等に計算
	# これにより「タイトルだけ拡大されてほかはちっちゃい」問題を完全に解決しつつ、フォントがネイティブにクッキリ描画される！
	# スマホ画面において縦方向の解像度に沿ってぴったり収まるように高さを基準にスケールを算出
	var ui_scale_w = target_w / 480.0
	var ui_scale_h = target_h / 750.0
	var ui_scale = clamp(min(ui_scale_w, ui_scale_h), 0.5, 2.5) if is_portrait else clamp(target_h / 850.0, 0.3, 1.3)
	
	# 要素間のスペース（separation）も画面サイズに合わせて縮小することで、はみ出しを完全に防ぐ
	for child in main_notebook.get_children():
		if child is VBoxContainer:
			child.add_theme_constant_override("separation", int(18 * ui_scale))
			for sub in child.get_children():
				if sub is VBoxContainer:
					sub.add_theme_constant_override("separation", int(12 * ui_scale))
				elif sub is HBoxContainer:
					sub.add_theme_constant_override("separation", int(30 * ui_scale))
	
	# ロゴのサイズバランス調整
	if is_instance_valid(title_logo):
		var logo_s = (0.85 if is_portrait else 1.15) * ui_scale
		title_logo.scale = Vector2.ONE
		if title_logo.has_method("apply_scale"):
			title_logo.apply_scale(logo_s)
		if title_logo.get_parent() is Control:
			title_logo.get_parent().custom_minimum_size.y = 230.0 * logo_s
			
	# ボタン群（モード選択ボタン・下部ボタン）のサイズとフォントサイズを比例拡大
	var big_btn_w = min(420.0 * ui_scale, target_w - 40.0)
	var small_btn_w = min(200.0 * ui_scale, (target_w - 50.0) / 2.0)
	
	for btn in sticky_buttons:
		if not is_instance_valid(btn):
			continue
		var container = btn.get_parent() as CenterContainer
		
		var is_big = false
		for child in btn.get_children():
			if child is VBoxContainer:
				is_big = true
				if child.get_child_count() >= 2:
					var title_lbl = child.get_child(0) as Label
					var desc_lbl = child.get_child(1) as Label
					if is_instance_valid(title_lbl):
						title_lbl.add_theme_font_size_override("font_size", int(25 * ui_scale))
					if is_instance_valid(desc_lbl):
						desc_lbl.add_theme_font_size_override("font_size", int(13 * ui_scale))
				break
				
		if is_big:
			if container:
				container.custom_minimum_size = Vector2(big_btn_w, 74.0 * ui_scale)
			btn.custom_minimum_size = Vector2(big_btn_w, 68.0 * ui_scale)
			btn.size = Vector2(big_btn_w, 68.0 * ui_scale)
		else:
			btn.add_theme_font_size_override("font_size", int(19 * ui_scale))
			if container:
				container.custom_minimum_size = Vector2(small_btn_w, 54.0 * ui_scale)
			btn.custom_minimum_size = Vector2(small_btn_w - 10.0, 50.0 * ui_scale)
			btn.size = Vector2(small_btn_w - 10.0, 50.0 * ui_scale)
			
		btn.pivot_offset = btn.custom_minimum_size / 2.0

func _start_entrance_animation() -> void:
	_update_layout()
	var target_scale = main_notebook.scale
	main_notebook.modulate.a = 0.0
	main_notebook.scale = target_scale * 0.9
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(main_notebook, "scale", target_scale, 0.6)
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
	btn_container.custom_minimum_size = Vector2(400, 72)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(380, 68)
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
	title_lbl.add_theme_font_size_override("font_size", 25)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	inner.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc_text
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
	desc_lbl.add_theme_font_size_override("font_size", 13)
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
	var btn_container = CenterContainer.new()
	btn_container.custom_minimum_size = Vector2(200, 54)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(185, 50)
	btn.add_theme_stylebox_override("normal", DeskTheme.create_sticky_note_style(color))
	
	var hover_style = DeskTheme.create_sticky_note_style(color)
	hover_style.shadow_size = 6
	hover_style.shadow_offset = Vector2(2, 3)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", DeskTheme.create_sticky_note_style(color))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	btn.text = text
	btn.add_theme_font_override("font", DeskTheme.get_font())
	btn.add_theme_font_size_override("font_size", 19)
	btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	
	btn.rotation_degrees = rot
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	
	btn.mouse_entered.connect(func(): DeskTheme.animate_hover(btn, true, Vector2.ONE))
	btn.mouse_exited.connect(func(): DeskTheme.animate_hover(btn, false, Vector2.ONE))
	
	btn.pressed.connect(func():
		DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
		callback.call()
	)
	
	btn_container.add_child(btn)
	parent.add_child(btn_container)
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

func _show_difficulty_selection() -> void:
	var vp_size = get_viewport_rect().size
	var fit_s = clamp(min(vp_size.x / 540.0, vp_size.y / 960.0), 0.8, 3.0)
	var width = min(480.0, (vp_size.x * 0.95) / fit_s)
	var height = min(600.0, (max(vp_size.y, 500.0) * 0.9) / fit_s)
	
	var diff_modal = PanelContainer.new()
	diff_modal.custom_minimum_size = Vector2(width, height)
	diff_modal.pivot_offset = Vector2(width / 2.0, height / 2.0)
	diff_modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.add_child(diff_modal)
	
	diff_modal.resized.connect(func(): diff_modal.pivot_offset = diff_modal.size * 0.5)
	diff_modal.tree_exiting.connect(func(): if is_instance_valid(center): center.queue_free())
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	diff_modal.add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "難易度を選択"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(28))
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_vbox)
	
	var difficulties = [
		{"id": "easy", "name": "初級 (Easy)", "desc": "相手は慎重で、あまりダウトをしてきません。\n練習に最適です。"},
		{"id": "normal", "name": "中級 (Normal)", "desc": "標準的な強さのCPUと対戦します。\nバランスの良い難易度です。"},
		{"id": "hard", "name": "上級 (Hard)", "desc": "相手は強気で、的確にダウトを狙ってきます。\n腕試しにどうぞ。"}
	]
	
	for diff in difficulties:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(min(420.0, width - 40.0), 90)
		Global.apply_white_button_style(btn)
		
		var inner = VBoxContainer.new()
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(inner)
		
		var btn_title = Label.new()
		btn_title.text = diff["name"]
		btn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_title.add_theme_font_override("font", DeskTheme.get_font())
		btn_title.add_theme_font_size_override("font_size", DeskTheme.scaled_font(22))
		btn_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		inner.add_child(btn_title)
		
		var btn_desc = Label.new()
		btn_desc.text = diff["desc"]
		btn_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_desc.add_theme_font_override("font", DeskTheme.get_font())
		btn_desc.add_theme_font_size_override("font_size", DeskTheme.scaled_font(13))
		btn_desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
		inner.add_child(btn_desc)
		
		btn.pressed.connect(func():
			DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
			Global.cpu_difficulty = diff["id"]
			diff_modal.queue_free()
			_start_cpu_match()
		)
		btn_vbox.add_child(btn)
		
	var cancel_btn = Button.new()
	cancel_btn.text = "キャンセル"
	cancel_btn.custom_minimum_size = Vector2(160, 45)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.add_theme_font_override("font", DeskTheme.get_font())
	cancel_btn.add_theme_font_size_override("font_size", DeskTheme.scaled_font(18))
	Global.apply_white_button_style(cancel_btn)
	
	cancel_btn.pressed.connect(func():
		DeskTheme.animate_click(cancel_btn, Vector2.ONE, 0.08)
		diff_modal.queue_free()
	)
	vbox.add_child(cancel_btn)
	
	diff_modal.scale = Vector2.ZERO
	if get_tree() != null:
		var tween = get_tree().create_tween().bind_node(diff_modal).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(diff_modal, "scale", Vector2.ONE * fit_s, 0.3)
