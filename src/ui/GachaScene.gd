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
var gacha_skip_btn: Button
var current_capsule: Control = null
var current_float_tween: Tween = null
var skip_triggered: bool = false
var result_detail_panel: PanelContainer



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

# ガチャ排出率ウェイト (合計1000)
const GACHA_WEIGHTS = {
	# レア (各2.0%、合計10.0%)
	"item_energy_drink": 20,
	"item_cheat_sheet": 20,
	"item_copy_answer": 20,
	"item_night_note": 20,
	"item_cram_school_print": 20,
	# アンコモン (各7.5%、合計30.0%)
	"item_red_sheet": 75,
	"item_thick_book": 75,
	"item_amulet": 75,
	"item_cafe_latte": 75,
	# コモン (各12.0%、合計60.0%)
	"item_compass": 120,
	"item_timer": 120,
	"item_study_chat": 120,
	"item_expected_questions": 120,
	"item_earplugs": 120
}

func _ready() -> void:
	GachaUIBuilder.build_layout(self)
	
	update_coins_ui()


func update_coins_ui() -> void:
	coin_lbl.text = "所持コイン: " + str(Global.coins) + " 枚"
	var cost = int(BalanceConfig.get_value("rewards.gacha_cost", 50))
	if Global.coins < cost:
		pull_btn.disabled = true
	else:
		pull_btn.disabled = false

func _on_pull_pressed() -> void:
	var cost = int(BalanceConfig.get_value("rewards.gacha_cost", 50))
	if is_pulling or Global.coins < cost:
		return
		
	is_pulling = true
	pull_btn.disabled = true
	back_btn.disabled = true
	skip_triggered = false
	if is_instance_valid(gacha_skip_btn):
		gacha_skip_btn.visible = true
	
	Global.coins -= cost
	Global.save_game()
	update_coins_ui()
	
	result_lbl.text = "レバーを回している..."

	
	# Hide previous card if visible
	if card_slot.scale.x > 0.0:
		var fade_out = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fade_out.tween_property(card_slot, "scale", Vector2.ZERO, 0.2)
		if is_instance_valid(result_detail_panel):
			var detail_fade = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			detail_fade.tween_property(result_detail_panel, "scale", Vector2.ZERO, 0.2)
			detail_fade.tween_callback(func(): result_detail_panel.queue_free())

	
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
		if not skip_triggered:
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
	
	current_capsule = capsule
	
	# Animate capsule flying out & bouncing in center (complete 360-degree rotation)
	var cap_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cap_tween.tween_property(capsule, "position", Vector2(120, 150), 0.5)
	cap_tween.tween_property(capsule, "scale", Vector2(1.8, 1.8), 0.5)
	cap_tween.tween_property(capsule, "rotation_degrees", 360.0, 0.5)
	
	cap_tween.chain().tween_callback(func():
		if skip_triggered:
			return
		# Spawn Prompt Label directly under slot_wrapper so it doesn't rotate with the capsule
		prompt_lbl = Label.new()
		prompt_lbl.text = "タップして開封！"
		prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt_lbl.add_theme_font_override("font", DeskTheme.get_font())
		prompt_lbl.add_theme_font_size_override("font_size", 16)
		prompt_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		# Positioned below the capsule: capsule center is at (180, 210), prompt is placed at bottom-center
		prompt_lbl.position = Vector2(180 - 64, 270)
		slot_wrapper.add_child(prompt_lbl)
		
		# Floating animation loop for the label
		current_float_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		current_float_tween.tween_property(prompt_lbl, "position:y", 274.0, 0.4)
		current_float_tween.tween_property(prompt_lbl, "position:y", 266.0, 0.4)
		
		cap_btn.pressed.connect(func():
			if cap_btn.disabled:
				return
			cap_btn.disabled = true
			if is_instance_valid(current_float_tween):
				current_float_tween.kill()
			if is_instance_valid(prompt_lbl):
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
	# Pick random item with weights
	var drawn_item_id = pick_gacha_item()
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
	
	# Clean up previous stamp (Loop 15)
	if card_slot.has_node("EraserStamp"):
		card_slot.get_node("EraserStamp").queue_free()
		
	# Bounce zoom card pop entry
	card_slot.scale = Vector2(0.1, 0.1)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_slot, "scale", Vector2.ONE, 0.35)
	
	# Create eraser stamp node (Loop 15)
	var stamp = PanelContainer.new()
	stamp.name = "EraserStamp"
	stamp.custom_minimum_size = Vector2(110, 44)
	stamp.size = Vector2(110, 44)
	card_slot.add_child(stamp)
	
	stamp.pivot_offset = Vector2(55, 22)
	stamp.position = Vector2(240 - 110 - 5, 320 - 44 - 5) # Bottom-right of the card slot with tight margins to avoid overlapping the center illustration
	stamp.rotation_degrees = -15.0
	
	var stamp_style = StyleBoxFlat.new()
	stamp_style.bg_color = Color(1.0, 0.9, 0.9, 0.0) # Transparent background
	stamp_style.border_color = Color("c62828") # Red stamp ink
	stamp_style.border_width_left = 3
	stamp_style.border_width_right = 3
	stamp_style.border_width_top = 3
	stamp_style.border_width_bottom = 3
	stamp_style.corner_radius_top_left = 4
	stamp_style.corner_radius_top_right = 4
	stamp_style.corner_radius_bottom_left = 4
	stamp_style.corner_radius_bottom_right = 4
	stamp.add_theme_stylebox_override("panel", stamp_style)
	
	var stamp_lbl = Label.new()
	stamp_lbl.text = "新 解 放" if is_new else "獲 得 済"
	stamp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp_lbl.add_theme_font_override("font", DeskTheme.get_font())
	stamp_lbl.add_theme_font_size_override("font_size", 15)
	stamp_lbl.add_theme_color_override("font_color", Color("c62828"))
	stamp.add_child(stamp_lbl)
	
	stamp.scale = Vector2(3.0, 3.0)
	stamp.modulate.a = 0.0
	
	# Delay stamp animation until card slot finishes pop entry
	var s_tween = create_tween()
	s_tween.tween_interval(0.35)
	s_tween.parallel().tween_property(stamp, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	s_tween.parallel().tween_property(stamp, "modulate:a", 1.0, 0.15)
	s_tween.tween_callback(func():
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_se(AudioManager.SE_PLACE)
		DeskTheme.shake_control(card_slot, 6.0, 0.15)
	)
	
	# Confetti burst
	particles.emitting = true
	
	# Show item detail panel on the right side of the card
	show_result_detail_panel(drawn_item_id, is_new)
	
	var timer = get_tree().create_timer(0.6)
	timer.timeout.connect(func():
		is_pulling = false
		update_coins_ui()
		back_btn.disabled = false
		if is_instance_valid(gacha_skip_btn):
			gacha_skip_btn.visible = false
	)

func _on_gacha_skip_pressed() -> void:
	if not is_pulling or skip_triggered:
		return
	skip_triggered = true
	if is_instance_valid(gacha_skip_btn):
		gacha_skip_btn.visible = false
	
	if is_instance_valid(current_capsule):
		current_capsule.queue_free()
	if is_instance_valid(prompt_lbl):
		prompt_lbl.queue_free()
	if is_instance_valid(current_float_tween):
		current_float_tween.kill()
		
	reveal_gacha_result()


func _on_back_pressed() -> void:
	DeskTheme.animate_click(back_btn, Vector2.ONE, 0.08)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
	)

func pick_gacha_item() -> String:
	var total_weight = 0
	for item_id in GACHA_WEIGHTS.keys():
		total_weight += GACHA_WEIGHTS[item_id]
		
	var roll = randi() % total_weight
	var current_sum = 0
	for item_id in GACHA_WEIGHTS.keys():
		current_sum += GACHA_WEIGHTS[item_id]
		if roll < current_sum:
			return item_id
			
	return GACHA_WEIGHTS.keys()[0]

func _on_odds_pressed() -> void:
	GachaUIBuilder.build_odds_modal(self)

func show_result_detail_panel(item_id: String, is_new: bool) -> void:
	if is_instance_valid(result_detail_panel):
		result_detail_panel.queue_free()
		
	var item = CardData.ITEMS.get(item_id, {})
	if item.is_empty():
		return
		
	result_detail_panel = PanelContainer.new()
	result_detail_panel.custom_minimum_size = Vector2(340, 320)
	result_detail_panel.size = Vector2(340, 320)
	result_detail_panel.position = Vector2(320, 60) # Right of card_slot which is at (60, 60)
	result_detail_panel.pivot_offset = Vector2(170, 160)
	
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color("#fbf9f4")
	detail_style.border_color = CardData.get_role_color(item["role"])
	detail_style.border_width_left = 3
	detail_style.border_width_right = 3
	detail_style.border_width_top = 3
	detail_style.border_width_bottom = 3
	detail_style.corner_radius_top_left = 8
	detail_style.corner_radius_top_right = 8
	detail_style.corner_radius_bottom_left = 8
	detail_style.corner_radius_bottom_right = 8
	detail_style.content_margin_left = 20
	detail_style.content_margin_right = 20
	detail_style.content_margin_top = 20
	detail_style.content_margin_bottom = 20
	result_detail_panel.add_theme_stylebox_override("panel", detail_style)
	
	card_slot.get_parent().add_child(result_detail_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	result_detail_panel.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "アイテム効果詳細"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	vbox.add_child(title_lbl)
	
	var name_lbl = Label.new()
	name_lbl.text = item["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(name_lbl)
	
	var role_lbl = Label.new()
	var role_name = CardData.get_role_name(item["role"])
	role_lbl.text = "系統: %s" % role_name
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl.add_theme_font_override("font", DeskTheme.get_font())
	role_lbl.add_theme_font_size_override("font_size", 14)
	role_lbl.add_theme_color_override("font_color", CardData.get_role_color(item["role"]))
	vbox.add_child(role_lbl)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(DeskTheme.COLOR_INK, 0.15)
	vbox.add_child(divider)
	
	var desc_lbl = Label.new()
	desc_lbl.text = item["description"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(desc_lbl)
	
	var bonus_lbl = Label.new()
	if is_new:
		bonus_lbl.text = "★ 新しくカバンに編成可能になりました！"
		bonus_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_GREEN)
	else:
		bonus_lbl.text = "★ 重複ボーナス: 使用可能回数 +10回！"
		bonus_lbl.add_theme_color_override("font_color", Color("388e3c"))
	bonus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_lbl.add_theme_font_override("font", DeskTheme.get_font())
	bonus_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(bonus_lbl)
	
	result_detail_panel.scale = Vector2.ZERO
	result_detail_panel.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_detail_panel, "scale", Vector2.ONE, 0.4)
	tween.tween_property(result_detail_panel, "modulate:a", 1.0, 0.3)

