class_name GachaUIBuilder
extends RefCounted

static func build_layout(scene: GachaScene) -> void:
	# 段ボール風（購買部のダンボール箱）背景
	var cardboard = Panel.new()
	cardboard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.add_child(cardboard)
	
	var board_style = StyleBoxTexture.new()
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.8
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	var tex = NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color("#c09664"), Color("#a67c52")]) # 段ボール色
	tex.color_ramp = grad
	
	board_style.texture = tex
	board_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	board_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	cardboard.add_theme_stylebox_override("panel", board_style)
	
	# 購買部のひさし（オーニング：赤白ストライプ）
	var awning = ColorRect.new()
	awning.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	awning.custom_minimum_size = Vector2(0, 60)
	awning.size = Vector2(1920, 60)
	
	# ストライプ模様をShaderを使わずにHBoxContainerで作る
	var stripe_hbox = HBoxContainer.new()
	stripe_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stripe_hbox.add_theme_constant_override("separation", 0)
	awning.add_child(stripe_hbox)
	
	for i in range(32): # 1920 / 60 = 32
		var stripe = ColorRect.new()
		stripe.custom_minimum_size = Vector2(60, 60)
		stripe.color = Color("#e53935") if i % 2 == 0 else Color.WHITE
		stripe_hbox.add_child(stripe)
		
	# ひさしの下に落ちる影
	var awning_shadow = ColorRect.new()
	awning_shadow.color = Color(0, 0, 0, 0.2)
	awning_shadow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	awning_shadow.position = Vector2(0, 60)
	awning_shadow.custom_minimum_size = Vector2(0, 20)
	awning_shadow.size = Vector2(1920, 20)
	scene.add_child(awning)
	scene.add_child(awning_shadow)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.add_child(center_container)
	
	var center_vbox = VBoxContainer.new()
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_MEDIUM)
	center_container.add_child(center_vbox)
	
	var title = Label.new()
	title.text = "購買部ガチャ（アイテムカプセル）"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE_LARGE)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	center_vbox.add_child(title)
	
	var coin_lbl = Label.new()
	coin_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_lbl.add_theme_font_override("font", DeskTheme.get_font())
	coin_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	coin_lbl.add_theme_color_override("font_color", Color("ff8f00")) # Gold color
	center_vbox.add_child(coin_lbl)
	scene.coin_lbl = coin_lbl
	
	# Larger Wrapper to hold both Gacha Machine and Card Result
	var slot_wrapper = Control.new()
	slot_wrapper.custom_minimum_size = Vector2(360, 440)
	slot_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_vbox.add_child(slot_wrapper)
	
	# 1. Gacha Machine UI Container (starts visible)
	var machine_wrapper = Control.new()
	machine_wrapper.custom_minimum_size = Vector2(320, 420)
	machine_wrapper.size = Vector2(320, 420)
	machine_wrapper.position = Vector2(20, 10)
	machine_wrapper.pivot_offset = Vector2(160, 210)
	slot_wrapper.add_child(machine_wrapper)
	scene.machine_wrapper = machine_wrapper
	
	# Machine Red Base
	var machine_body = PanelContainer.new()
	machine_body.custom_minimum_size = Vector2(280, 220)
	machine_body.size = Vector2(280, 220)
	machine_body.position = Vector2(20, 200)
	var body_style = StyleBoxFlat.new()
	body_style.bg_color = Color("c62828") # Bright red
	body_style.border_color = DeskTheme.COLOR_INK
	body_style.border_width_left = 4
	body_style.border_width_right = 4
	body_style.border_width_top = 4
	body_style.border_width_bottom = 4
	body_style.corner_radius_top_left = 12
	body_style.corner_radius_top_right = 12
	body_style.corner_radius_bottom_left = 16
	body_style.corner_radius_bottom_right = 16
	body_style.shadow_color = Color(0, 0, 0, 0.2)
	body_style.shadow_size = 8
	body_style.shadow_offset = Vector2(4, 4)
	machine_body.add_theme_stylebox_override("panel", body_style)
	machine_wrapper.add_child(machine_body)
	
	# Semi-transparent glass dome
	var glass_dome = PanelContainer.new()
	glass_dome.custom_minimum_size = Vector2(240, 200)
	glass_dome.size = Vector2(240, 200)
	glass_dome.position = Vector2(40, 10)
	var glass_style = StyleBoxFlat.new()
	glass_style.bg_color = Color("e3f2fd", 0.5) # transparent blue glass
	glass_style.border_color = DeskTheme.COLOR_INK
	glass_style.border_width_left = 4
	glass_style.border_width_right = 4
	glass_style.border_width_top = 4
	glass_style.border_width_bottom = 0
	glass_style.corner_radius_top_left = 120
	glass_style.corner_radius_top_right = 120
	glass_dome.add_theme_stylebox_override("panel", glass_style)
	machine_wrapper.add_child(glass_dome)
	
	# Decorative capsules inside dome
	var capsules_container = Control.new()
	capsules_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capsules_container.pivot_offset = Vector2(120, 100)
	glass_dome.add_child(capsules_container)
	scene.capsules_container = capsules_container
	
	var cap_colors = [Color("ff1744"), Color("2979ff"), Color("00e676"), Color("ffd600"), Color("d500f9")]
	for i in range(12):
		var cap_size = randf_range(30, 36)
		
		# Inner dummy capsule wrapper
		var cap = Control.new()
		cap.custom_minimum_size = Vector2(cap_size, cap_size)
		cap.size = Vector2(cap_size, cap_size)
		cap.pivot_offset = Vector2(cap_size / 2.0, cap_size / 2.0)
		cap.position = Vector2(randf_range(30, 170), randf_range(100, 150))
		cap.rotation_degrees = randf_range(-45.0, 45.0)
		capsules_container.add_child(cap)
		
		# Colored top half (蓋)
		var shell_t = PanelContainer.new()
		shell_t.custom_minimum_size = Vector2(cap_size, cap_size / 2.0)
		shell_t.size = Vector2(cap_size, cap_size / 2.0)
		var style_t = StyleBoxFlat.new()
		style_t.bg_color = cap_colors[randi() % cap_colors.size()]
		style_t.corner_radius_top_left = cap_size / 2.0
		style_t.corner_radius_top_right = cap_size / 2.0
		style_t.border_color = DeskTheme.COLOR_INK
		style_t.border_width_left = 2
		style_t.border_width_top = 2
		style_t.border_width_right = 2
		style_t.border_width_bottom = 1
		shell_t.add_theme_stylebox_override("panel", style_t)
		cap.add_child(shell_t)
		
		# White/Gray bottom half (本体)
		var shell_b = PanelContainer.new()
		shell_b.custom_minimum_size = Vector2(cap_size, cap_size / 2.0)
		shell_b.size = Vector2(cap_size, cap_size / 2.0)
		shell_b.position = Vector2(0, cap_size / 2.0)
		var style_b = StyleBoxFlat.new()
		style_b.bg_color = Color("f5f5f5")
		style_b.corner_radius_bottom_left = cap_size / 2.0
		style_b.corner_radius_bottom_right = cap_size / 2.0
		style_b.border_color = DeskTheme.COLOR_INK
		style_b.border_width_left = 2
		style_b.border_width_bottom = 2
		style_b.border_width_right = 2
		style_b.border_width_top = 1
		shell_b.add_theme_stylebox_override("panel", style_b)
		cap.add_child(shell_b)
		
	# Dispenser Hole
	var dispenser = PanelContainer.new()
	dispenser.custom_minimum_size = Vector2(70, 60)
	dispenser.size = Vector2(70, 60)
	dispenser.position = Vector2(125, 340)
	var disp_style = StyleBoxFlat.new()
	disp_style.bg_color = Color("151515")
	disp_style.border_color = DeskTheme.COLOR_INK
	disp_style.border_width_left = 3
	disp_style.border_width_right = 3
	disp_style.border_width_top = 3
	disp_style.border_width_bottom = 3
	disp_style.corner_radius_top_left = 30
	disp_style.corner_radius_top_right = 30
	dispenser.add_theme_stylebox_override("panel", disp_style)
	machine_wrapper.add_child(dispenser)
	
	# Lever Button
	var lever_btn = Button.new()
	lever_btn.custom_minimum_size = Vector2(80, 80)
	lever_btn.size = Vector2(80, 80)
	lever_btn.position = Vector2(120, 230)
	lever_btn.pivot_offset = Vector2(40, 40)
	var lever_style = StyleBoxFlat.new()
	lever_style.bg_color = Color("cfd8dc")
	lever_style.border_color = DeskTheme.COLOR_INK
	lever_style.border_width_left = 4
	lever_style.border_width_right = 4
	lever_style.border_width_top = 4
	lever_style.border_width_bottom = 4
	lever_style.corner_radius_top_left = 40
	lever_style.corner_radius_top_right = 40
	lever_style.corner_radius_bottom_left = 40
	lever_style.corner_radius_bottom_right = 40
	lever_btn.add_theme_stylebox_override("normal", lever_style)
	lever_btn.add_theme_stylebox_override("hover", lever_style)
	lever_btn.add_theme_stylebox_override("pressed", lever_style)
	lever_btn.add_theme_stylebox_override("disabled", lever_style)
	machine_wrapper.add_child(lever_btn)
	scene.lever_btn = lever_btn
	
	var lever_handle = ColorRect.new()
	lever_handle.color = DeskTheme.COLOR_INK
	lever_handle.custom_minimum_size = Vector2(60, 14)
	lever_handle.size = Vector2(60, 14)
	lever_handle.position = Vector2(10, 33)
	lever_btn.add_child(lever_handle)
	
	# 2. Card Slot (starts hidden/scaled to zero)
	var card_slot = PanelContainer.new()
	card_slot.custom_minimum_size = Vector2(240, 320)
	card_slot.size = Vector2(240, 320)
	card_slot.position = Vector2(60, 60)
	card_slot.pivot_offset = Vector2(120, 160)
	card_slot.scale = Vector2.ZERO
	
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = DeskTheme.COLOR_MAHOGANY
	slot_style.border_color = Color(DeskTheme.COLOR_INK, 0.4)
	slot_style.border_width_left = 3
	slot_style.border_width_right = 3
	slot_style.border_width_top = 3
	slot_style.border_width_bottom = 3
	slot_style.corner_radius_top_left = 8
	slot_style.corner_radius_top_right = 8
	slot_style.corner_radius_bottom_left = 8
	slot_style.corner_radius_bottom_right = 8
	card_slot.add_theme_stylebox_override("panel", slot_style)
	slot_wrapper.add_child(card_slot)
	scene.card_slot = card_slot
	
	var slot_vbox = VBoxContainer.new()
	slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_TINY)
	slot_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot.add_child(slot_vbox)
	
	var card_title = Label.new()
	card_title.text = "？"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_title.add_theme_font_override("font", DeskTheme.get_font())
	card_title.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_TITLE)
	card_title.add_theme_color_override("font_color", Color(Color.WHITE, 0.3))
	slot_vbox.add_child(card_title)
	scene.card_title = card_title
	
	var item_texture = TextureRect.new()
	item_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_texture.custom_minimum_size = Vector2(140, 140)
	item_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item_texture.visible = false
	slot_vbox.add_child(item_texture)
	scene.item_texture = item_texture
	
	# Particles setup
	var particles = CPUParticles2D.new()
	particles.position = Vector2(120, 160)
	particles.emitting = false
	particles.amount = 40
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 1.2
	particles.spread = 180.0
	particles.gravity = Vector2(0, 100)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 140.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = Color("fff176")
	card_slot.add_child(particles)
	scene.particles = particles
	
	var result_lbl = Label.new()
	result_lbl.text = "ガチャを回してみよう！"
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_override("font", DeskTheme.get_font())
	result_lbl.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	result_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	center_vbox.add_child(result_lbl)
	scene.result_lbl = result_lbl
	
	# Actions
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", DeskTheme.MARGIN_MEDIUM)
	center_vbox.add_child(btn_hbox)
	
	var pull_btn = Button.new()
	pull_btn.add_to_group("important_button")
	var cost = int(BalanceConfig.get_value("rewards.gacha_cost", 50))
	pull_btn.text = "1回引く (" + str(cost) + "コイン)"
	pull_btn.custom_minimum_size = Vector2(260, 65)
	pull_btn.add_theme_font_override("font", DeskTheme.get_font())
	pull_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	
	var pull_style_normal = StyleBoxFlat.new()
	pull_style_normal.bg_color = DeskTheme.COLOR_HIGHLIGHTER
	pull_style_normal.border_color = DeskTheme.COLOR_INK
	pull_style_normal.border_width_left = 3
	pull_style_normal.border_width_right = 3
	pull_style_normal.border_width_top = 3
	pull_style_normal.border_width_bottom = 3
	pull_style_normal.corner_radius_top_left = 6
	pull_style_normal.corner_radius_top_right = 6
	pull_style_normal.corner_radius_bottom_left = 6
	pull_style_normal.corner_radius_bottom_right = 6
	pull_style_normal.shadow_color = Color(0.12, 0.08, 0.05, 0.15)
	pull_style_normal.shadow_size = 4
	pull_style_normal.shadow_offset = Vector2(2, 2)
	
	var pull_style_hover = pull_style_normal.duplicate() as StyleBoxFlat
	pull_style_hover.bg_color = Color("ffff8d")
	pull_style_hover.shadow_size = 6
	pull_style_hover.shadow_offset = Vector2(3, 3)
	
	var pull_style_pressed = pull_style_normal.duplicate() as StyleBoxFlat
	pull_style_pressed.bg_color = Color("ffd54f")
	pull_style_pressed.shadow_size = 1
	pull_style_pressed.shadow_offset = Vector2(1, 1)
	
	var pull_style_disabled = pull_style_normal.duplicate() as StyleBoxFlat
	pull_style_disabled.bg_color = Color("e0e0e0")
	pull_style_disabled.border_color = Color("9e9e9e")
	pull_style_disabled.shadow_size = 0
	
	pull_btn.add_theme_stylebox_override("normal", pull_style_normal)
	pull_btn.add_theme_stylebox_override("hover", pull_style_hover)
	pull_btn.add_theme_stylebox_override("pressed", pull_style_pressed)
	pull_btn.add_theme_stylebox_override("disabled", pull_style_disabled)
	pull_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	pull_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	pull_btn.add_theme_color_override("font_hover_color", DeskTheme.COLOR_INK)
	pull_btn.add_theme_color_override("font_pressed_color", DeskTheme.COLOR_INK)
	pull_btn.add_theme_color_override("font_disabled_color", Color("9e9e9e"))

	pull_btn.pressed.connect(func():
		pull_btn.release_focus()
		DeskTheme.animate_click(pull_btn, Vector2.ONE, 0.08)
		scene._on_pull_pressed()
	)
	btn_hbox.add_child(pull_btn)
	scene.pull_btn = pull_btn
	
	var odds_btn = Button.new()
	odds_btn.add_to_group("important_button")
	odds_btn.text = "提供割合"
	odds_btn.custom_minimum_size = Vector2(160, 65)
	odds_btn.add_theme_font_override("font", DeskTheme.get_font())
	odds_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	odds_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	Global.apply_white_button_style(odds_btn)
	odds_btn.pressed.connect(func():
		odds_btn.release_focus()
		DeskTheme.animate_click(odds_btn, Vector2.ONE, 0.08)
		scene._on_odds_pressed()
	)
	btn_hbox.add_child(odds_btn)
	
	var back_btn = Button.new()
	back_btn.add_to_group("important_button")
	back_btn.text = "戻る"
	back_btn.custom_minimum_size = Vector2(160, 65)
	back_btn.add_theme_font_override("font", DeskTheme.get_font())
	back_btn.add_theme_font_size_override("font_size", DeskTheme.FONT_SIZE_NORMAL)
	back_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	Global.apply_white_button_style(back_btn)
	back_btn.pressed.connect(func():
		back_btn.release_focus()
		scene._on_back_pressed()
	)
	btn_hbox.add_child(back_btn)
	scene.back_btn = back_btn
	
	# Skip Button (Top Right)
	var gacha_skip_btn = Button.new()
	gacha_skip_btn.add_to_group("important_button")
	gacha_skip_btn.text = "演出スキップ >>"
	gacha_skip_btn.custom_minimum_size = Vector2(160, 45)
	gacha_skip_btn.visible = false
	gacha_skip_btn.pressed.connect(scene._on_gacha_skip_pressed)
	Global.apply_white_button_style(gacha_skip_btn)
	gacha_skip_btn.position = Vector2(1730, 24)
	scene.add_child(gacha_skip_btn)
	scene.gacha_skip_btn = gacha_skip_btn

static func build_odds_modal(scene: GachaScene) -> void:
	# Create modal overlay for odds display
	var odds_layer = CanvasLayer.new()
	odds_layer.layer = 110
	scene.add_child(odds_layer)
	
	var overlay_bg = ColorRect.new()
	overlay_bg.color = Color(0, 0, 0, 0.4)
	overlay_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	odds_layer.add_child(overlay_bg)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 480)
	panel.pivot_offset = Vector2(250, 240)
	panel.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	odds_layer.add_child(panel)
	
	var viewport_size = scene.get_viewport().get_visible_rect().size
	panel.position = viewport_size * 0.5 - panel.pivot_offset
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_DEFAULT) # 20 -> 30
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "提供割合"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 320) # 460 -> 440 to avoid border cluttering
	vbox.add_child(scroll)
	
	var items_vbox = VBoxContainer.new()
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_vbox.add_theme_constant_override("separation", DeskTheme.MARGIN_TINY) # 8 -> 15
	scroll.add_child(items_vbox)
	
	var total_weight = 0
	for w in scene.GACHA_WEIGHTS.values():
		total_weight += w
		
	# Group by rarity for display
	var item_roles = {}
	for id in scene.GACHA_WEIGHTS.keys():
		var role = CardData.ITEMS[id].get("role", "support")
		if not item_roles.has(role):
			item_roles[role] = []
		item_roles[role].append(id)
		
	for role in item_roles.keys():
		var role_title = Label.new()
		var role_name = "サポート (コモン)"
		if role == "attack": role_name = "アタック (レア)"
		if role == "defense": role_name = "ディフェンス (アンコモン)"
		
		role_title.text = "【" + role_name + "】"
		role_title.add_theme_font_override("font", DeskTheme.get_font())
		role_title.add_theme_font_size_override("font_size", 18)
		role_title.add_theme_color_override("font_color", CardData.get_role_color(role))
		items_vbox.add_child(role_title)
		
		for id in item_roles[role]:
			var item = CardData.ITEMS[id]
			var w = scene.GACHA_WEIGHTS[id]
			var percent = float(w) / total_weight * 100.0
			
			var hbox = HBoxContainer.new()
			var name_lbl = Label.new()
			name_lbl.text = item["name"]
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_lbl.add_theme_font_override("font", DeskTheme.get_font())
			name_lbl.add_theme_font_size_override("font_size", 16)
			name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			hbox.add_child(name_lbl)
			
			var pct_lbl = Label.new()
			pct_lbl.text = "%.1f %%" % percent
			pct_lbl.add_theme_font_override("font", DeskTheme.get_font())
			pct_lbl.add_theme_font_size_override("font_size", 16)
			pct_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			hbox.add_child(pct_lbl)
			
			items_vbox.add_child(hbox)
	
	var close_btn = Button.new()
	close_btn.add_to_group("important_button")
	close_btn.text = "閉じる"
	close_btn.custom_minimum_size = Vector2(200, 50)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	Global.apply_white_button_style(close_btn)
	close_btn.pressed.connect(func():
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		var t = scene.get_tree().create_timer(0.1)
		t.timeout.connect(func(): odds_layer.queue_free())
	)
	vbox.add_child(close_btn)
	
	panel.scale = Vector2.ZERO
	var tween = scene.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)
