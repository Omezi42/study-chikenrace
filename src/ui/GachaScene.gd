class_name GachaScene
extends Control

# UI Elements
var coin_lbl: Label
var pull_btn: Button
var back_btn: Button
var card_slot: PanelContainer
var card_title: Label
var result_lbl: Label
var particles: CPUParticles2D
var item_texture: TextureRect

# Gacha Machine Elements
var machine_wrapper: Control
var lever_btn: Button
var capsules_container: Control
var prompt_lbl: Label

var is_pulling: bool = false

# Unlocked item list to pull from (14 items in Gacha)
const GACHA_POOL = [
	"item_cheat_sheet",
	"item_compass",
	"item_energy_drink",
	"item_red_sheet",
	"item_thick_book",
	"item_amulet",
	"item_night_note",
	"item_copy_answer",
	"item_timer",
	"item_study_chat",
	"item_expected_questions",
	"item_cafe_latte",
	"item_earplugs",
	"item_cram_school_print"
]

func _ready() -> void:
	# Mahogany background
	var bg_color = ColorRect.new()
	bg_color.color = DeskTheme.COLOR_MAHOGANY
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	var center_vbox = VBoxContainer.new()
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.add_theme_constant_override("separation", 24)
	center_container.add_child(center_vbox)
	
	var title = Label.new()
	title.text = "購買部ガチャ（アイテムカプセル）"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	center_vbox.add_child(title)
	
	coin_lbl = Label.new()
	coin_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	coin_lbl.add_theme_font_size_override("font_size", 24)
	coin_lbl.add_theme_color_override("font_color", Color("ff8f00")) # Gold color
	center_vbox.add_child(coin_lbl)
	
	# Larger Wrapper to hold both Gacha Machine and Card Result
	var slot_wrapper = Control.new()
	slot_wrapper.custom_minimum_size = Vector2(360, 440)
	slot_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_vbox.add_child(slot_wrapper)
	
	# 1. Gacha Machine UI Container (starts visible)
	machine_wrapper = Control.new()
	machine_wrapper.custom_minimum_size = Vector2(320, 420)
	machine_wrapper.size = Vector2(320, 420)
	machine_wrapper.position = Vector2(20, 10)
	machine_wrapper.pivot_offset = Vector2(160, 210)
	slot_wrapper.add_child(machine_wrapper)
	
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
	
	# Decorative capsules inside dome (2-color capsule rendering)
	capsules_container = Control.new()
	capsules_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capsules_container.pivot_offset = Vector2(120, 100)
	glass_dome.add_child(capsules_container)
	
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
	lever_btn = Button.new()
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
	
	var lever_handle = ColorRect.new()
	lever_handle.color = DeskTheme.COLOR_INK
	lever_handle.custom_minimum_size = Vector2(60, 14)
	lever_handle.size = Vector2(60, 14)
	lever_handle.position = Vector2(10, 33)
	lever_btn.add_child(lever_handle)
	
	# 2. Card Slot (starts hidden/scaled to zero, centered inside slot_wrapper)
	card_slot = PanelContainer.new()
	card_slot.custom_minimum_size = Vector2(240, 320)
	card_slot.size = Vector2(240, 320)
	card_slot.position = Vector2(60, 60) # centered inside (360, 440) wrapper
	card_slot.pivot_offset = Vector2(120, 160)
	card_slot.scale = Vector2.ZERO # hidden initially
	
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
	
	var slot_vbox = VBoxContainer.new()
	slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_vbox.add_theme_constant_override("separation", 15)
	slot_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot.add_child(slot_vbox)
	
	card_title = Label.new()
	card_title.text = "？"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	card_title.add_theme_font_size_override("font_size", 30)
	card_title.add_theme_color_override("font_color", Color(Color.WHITE, 0.3))
	slot_vbox.add_child(card_title)
	
	item_texture = TextureRect.new()
	item_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_texture.custom_minimum_size = Vector2(140, 140)
	item_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item_texture.visible = false
	slot_vbox.add_child(item_texture)
	
	# Particles setup
	particles = CPUParticles2D.new()
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
	
	result_lbl = Label.new()
	result_lbl.text = "ガチャを回してみよう！"
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	result_lbl.add_theme_font_size_override("font_size", 22)
	result_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.6))
	center_vbox.add_child(result_lbl)
	
	# Actions
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 25)
	center_vbox.add_child(btn_hbox)
	
	pull_btn = Button.new()
	pull_btn.text = "1回引く (50コイン)"
	pull_btn.custom_minimum_size = Vector2(260, 65)
	pull_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	pull_btn.add_theme_font_size_override("font_size", 22)
	pull_btn.pressed.connect(func():
		DeskTheme.animate_click(pull_btn, Vector2.ONE, 0.08)
		_on_pull_pressed()
	)
	btn_hbox.add_child(pull_btn)
	
	back_btn = Button.new()
	back_btn.text = "戻る"
	back_btn.custom_minimum_size = Vector2(160, 65)
	back_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	back_btn.add_theme_font_size_override("font_size", 22)
	back_btn.pressed.connect(_on_back_pressed)
	btn_hbox.add_child(back_btn)
	
	update_coins_ui()

func update_coins_ui() -> void:
	coin_lbl.text = "所持コイン: " + str(Global.coins) + " 枚"
	if Global.coins < 50:
		pull_btn.disabled = true
	else:
		pull_btn.disabled = false

func _on_pull_pressed() -> void:
	if is_pulling or Global.coins < 50:
		return
		
	is_pulling = true
	pull_btn.disabled = true
	back_btn.disabled = true
	
	Global.coins -= 50
	Global.save_game()
	update_coins_ui()
	
	result_lbl.text = "レバーを回している..."
	
	# Hide previous card if visible
	if card_slot.scale.x > 0.0:
		var fade_out = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fade_out.tween_property(card_slot, "scale", Vector2.ZERO, 0.2)
	
	# Animate rotary lever rotation
	var lever_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	lever_btn.rotation_degrees = 0.0
	lever_tween.tween_property(lever_btn, "rotation_degrees", 360.0, 0.6)
	
	# Shake the machine body
	DeskTheme.shake_control(machine_wrapper, 10.0, 0.7, 14)
	
	# Shake the capsules inside the glass dome intensely (simulate jiggling physics)
	DeskTheme.shake_control(capsules_container, 18.0, 0.7, 16)
	
	# Jiggle individual capsules randomly
	for cap in capsules_container.get_children():
		var original_pos = cap.position
		var jiggle_tween = create_tween().set_loops(6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var rand_offset = Vector2(randf_range(-12.0, 12.0), randf_range(-20.0, -5.0))
		jiggle_tween.tween_property(cap, "position", original_pos + rand_offset, 0.06)
		jiggle_tween.tween_property(cap, "position", original_pos, 0.06)
	
	var timer = get_tree().create_timer(0.7)
	timer.timeout.connect(func():
		spawn_capsule(machine_wrapper.get_parent())
	)

func spawn_capsule(slot_wrapper: Control) -> void:
	result_lbl.text = "カプセルが出てきた！"
	
	var capsule_colors = [Color("ff1744"), Color("2979ff"), Color("00e676"), Color("ffd600"), Color("d500f9")]
	var cap_color = capsule_colors[randi() % capsule_colors.size()]
	
	var capsule = Control.new()
	capsule.custom_minimum_size = Vector2(120, 120)
	capsule.size = Vector2(120, 120)
	capsule.pivot_offset = Vector2(60, 60)
	capsule.position = Vector2(120, 310) 
	capsule.scale = Vector2(0.3, 0.3)
	slot_wrapper.add_child(capsule)
	
	var shell_t = PanelContainer.new()
	shell_t.custom_minimum_size = Vector2(120, 60)
	shell_t.size = Vector2(120, 60)
	var style_t = StyleBoxFlat.new()
	style_t.bg_color = cap_color
	style_t.corner_radius_top_left = 60
	style_t.corner_radius_top_right = 60
	style_t.border_color = DeskTheme.COLOR_INK
	style_t.border_width_left = 4
	style_t.border_width_top = 4
	style_t.border_width_right = 4
	style_t.border_width_bottom = 2
	shell_t.add_theme_stylebox_override("panel", style_t)
	capsule.add_child(shell_t)
	
	var shell_b = PanelContainer.new()
	shell_b.custom_minimum_size = Vector2(120, 60)
	shell_b.size = Vector2(120, 60)
	shell_b.position = Vector2(0, 60)
	var style_b = StyleBoxFlat.new()
	style_b.bg_color = Color("f5f5f5")
	style_b.corner_radius_bottom_left = 60
	style_b.corner_radius_bottom_right = 60
	style_b.border_color = DeskTheme.COLOR_INK
	style_b.border_width_left = 4
	style_b.border_width_bottom = 4
	style_b.border_width_right = 4
	style_b.border_width_top = 2
	shell_b.add_theme_stylebox_override("panel", style_b)
	capsule.add_child(shell_b)
	
	var cap_btn = TextureButton.new()
	cap_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capsule.add_child(cap_btn)
	
	# Animate capsule flying out & bouncing in center (complete 360-degree rotation)
	var cap_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cap_tween.tween_property(capsule, "position", Vector2(120, 150), 0.5)
	cap_tween.tween_property(capsule, "scale", Vector2(1.8, 1.8), 0.5)
	cap_tween.tween_property(capsule, "rotation_degrees", 360.0, 0.5)
	
	cap_tween.chain().tween_callback(func():
		# Spawn Prompt Label directly under slot_wrapper so it doesn't rotate with the capsule
		prompt_lbl = Label.new()
		prompt_lbl.text = "タップして開封！"
		prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		prompt_lbl.add_theme_font_size_override("font_size", 16)
		prompt_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		# Positioned below the capsule: capsule center is at (180, 210), prompt is placed at bottom-center
		prompt_lbl.position = Vector2(180 - 64, 270)
		slot_wrapper.add_child(prompt_lbl)
		
		# Floating animation loop for the label
		var float_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.tween_property(prompt_lbl, "position:y", 274.0, 0.4)
		float_tween.tween_property(prompt_lbl, "position:y", 266.0, 0.4)
		
		cap_btn.pressed.connect(func():
			float_tween.kill()
			prompt_lbl.queue_free()
			_on_capsule_clicked(capsule, shell_t, shell_b)
		)
	)

func _on_capsule_clicked(capsule: Control, shell_t: PanelContainer, shell_b: PanelContainer) -> void:
	capsule.get_child(2).queue_free() # remove button
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_se(AudioManager.SE_PLACE)
		
	var split_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	split_tween.tween_property(shell_t, "position:y", -120.0, 0.4)
	split_tween.tween_property(shell_t, "modulate:a", 0.0, 0.3)
	split_tween.tween_property(shell_b, "position:y", 180.0, 0.4)
	split_tween.tween_property(shell_b, "modulate:a", 0.0, 0.3)
	split_tween.tween_property(capsule, "scale", Vector2(1.5, 1.5), 0.2)
	
	split_tween.chain().tween_callback(func():
		capsule.queue_free()
		reveal_gacha_result()
	)

func reveal_gacha_result() -> void:
	# Pick random item from pool
	var drawn_item_id = GACHA_POOL[randi() % GACHA_POOL.size()]
	var item = CardData.ITEMS[drawn_item_id]
	
	var is_new = not drawn_item_id in Global.unlocked_items
	
	if is_new:
		Global.unlock_item(drawn_item_id)
		result_lbl.text = "【 新規アイテム解放！ 】"
		result_lbl.add_theme_color_override("font_color", Color("ffd700"))
		DeskTheme.show_toast(self, "新アイテム「%s」を獲得！" % item["name"])
	else:
		# Duplicate: add 10 to usage counts!
		Global.add_item_usage(drawn_item_id, 10)
		result_lbl.text = "【 重複ボーナス：使用回数 +10回！ 】"
		result_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
		DeskTheme.show_toast(self, "重複ボーナス：「%s」の使用回数+10！" % item["name"])
		
	card_title.text = item["name"]
	var img_path = CardData.get_item_image_path(drawn_item_id)
	if img_path != "":
		item_texture.texture = load(img_path)
		item_texture.visible = true
	else:
		item_texture.visible = false
	
	# Card styling
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = DeskTheme.COLOR_CRAFT
	card_style.border_color = CardData.get_role_color(item["role"])
	card_style.border_width_left = 4
	card_style.border_width_right = 4
	card_style.border_width_top = 4
	card_style.border_width_bottom = 4
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_slot.add_theme_stylebox_override("panel", card_style)
	card_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	
	# Bounce zoom card pop entry
	card_slot.scale = Vector2(0.1, 0.1)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_slot, "scale", Vector2.ONE, 0.35)
	
	# Confetti burst
	particles.emitting = true
	
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(func():
		is_pulling = false
		update_coins_ui()
		back_btn.disabled = false
	)

func _on_back_pressed() -> void:
	DeskTheme.animate_click(back_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
	)
