class_name GachaScene
extends Control

const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")
const ToastOverlayScript = preload("res://scripts/ui/components/ToastOverlay.gd")
const ItemLibrary = preload("res://scripts/core/ItemLibrary.gd")

var coins_label: Label
var result_label: Label
var gacha_btn: Button
var back_btn: Button
var card_area: Control
var _is_rolling: bool = false
var audio_manager: AudioManager = null


func _ready():
	DeskTheme.decorate_scene(self, 0.24)
	
	audio_manager = AudioManager.new()
	add_child(audio_manager)

	var ui_root: Control = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)

	# ノートパネルの大きさを縦に伸ばしてカード領域を追加
	var page: Control = DeskTheme.create_notebook_panel(Vector2(640, 720), 40, 30, 40, 30)
	page.anchor_left = 0.5
	page.anchor_top = 0.5
	page.anchor_right = 0.5
	page.anchor_bottom = 0.5
	page.offset_left = -320
	page.offset_top = -360
	page.offset_right = 320
	page.offset_bottom = 360
	ui_root.add_child(page)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	DeskTheme.apply_font(vbox)
	page.get_node("Content").add_child(vbox)

	vbox.add_child(DeskTheme.create_label("購買部ガチャ", 34, DeskTheme.COLOR_INK, true))

	coins_label = DeskTheme.create_label("所持コイン: %d" % Global.coins, 22, Color("e67700"), true)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(coins_label)

	# ===== カード配置・演出エリア =====
	var card_area_wrapper: CenterContainer = CenterContainer.new()
	card_area_wrapper.custom_minimum_size = Vector2(190, 260)
	vbox.add_child(card_area_wrapper)
	
	card_area = Control.new()
	card_area.custom_minimum_size = Vector2(190, 260)
	card_area.size = Vector2(190, 260)
	card_area_wrapper.add_child(card_area)
	
	# カードのスロット点線枠
	var border_panel: Panel = Panel.new()
	border_panel.name = "BorderPanel"
	border_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var border_style: StyleBoxFlat = StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0.03)
	border_style.border_width_left = 2; border_style.border_width_top = 2
	border_style.border_width_right = 2; border_style.border_width_bottom = 2
	border_style.border_color = Color("d3c3a4", 0.6)
	border_style.corner_radius_top_left = 14; border_style.corner_radius_top_right = 14
	border_style.corner_radius_bottom_left = 14; border_style.corner_radius_bottom_right = 14
	border_panel.add_theme_stylebox_override("panel", border_style)
	card_area.add_child(border_panel)

	gacha_btn = DeskTheme.create_button("ガチャを引く (100コイン)", Vector2(300, 56), DeskTheme.COLOR_ACCENT_GOLD, Color("b38f30"))
	gacha_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gacha_btn.pressed.connect(_on_gacha_pressed)
	vbox.add_child(gacha_btn)

	result_label = DeskTheme.create_label("新しい文房具を引こう", 18, DeskTheme.COLOR_SAFE, true)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.custom_minimum_size = Vector2(500, 50)
	vbox.add_child(result_label)

	back_btn = DeskTheme.create_button("タイトルへ戻る", Vector2(250, 48), DeskTheme.COLOR_MUTED, Color("666666"))
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func():
		if audio_manager:
			audio_manager.play_se("click")
		SceneTransition.fade_to_scene("res://Title.tscn")
	)
	vbox.add_child(back_btn)

	DeskTheme.animate_entrance(page)


func _on_gacha_pressed():
	if _is_rolling:
		return
	if Global.coins < 100:
		ToastOverlayScript.show_toast(self, "コインが足りません", DeskTheme.COLOR_BLUFF_RED)
		return

	_is_rolling = true
	gacha_btn.disabled = true
	back_btn.disabled = true

	Global.coins -= 100
	coins_label.text = "所持コイン: %d" % Global.coins

	# 既存のカード演出をクリア
	for child in card_area.get_children():
		if child.name != "BorderPanel":
			child.queue_free()

	# カード裏面を配置してパック開封の準備
	var roll_card: Control = Control.new()
	roll_card.custom_minimum_size = Vector2(190, 260)
	roll_card.size = Vector2(190, 260)
	roll_card.pivot_offset = Vector2(190, 260) / 2.0
	
	var back_tex: TextureRect = TextureRect.new()
	back_tex.texture = DeskTheme.CARD_BACK
	back_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	roll_card.add_child(back_tex)
	card_area.add_child(roll_card)

	# パック開封時のガタガタ物理振動Tween
	var orig_pos: Vector2 = roll_card.position
	var shake_tween: Tween = roll_card.create_tween().set_loops()
	shake_tween.tween_callback(func():
		roll_card.position = orig_pos + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
		roll_card.rotation_degrees = randf_range(-3.0, 3.0)
	)
	shake_tween.tween_interval(0.04)

	var pool: Array = ItemLibrary.all_item_types()
	var roll_count: int = 18
	for _i in range(roll_count):
		var temp_item: int = pool[randi() % pool.size()]
		result_label.text = "開封中... %s" % ItemLibrary.name(temp_item)
		result_label.add_theme_color_override("font_color", Color("868e96"))
		if audio_manager:
			audio_manager.play_se("draw")
		await get_tree().create_timer(0.05).timeout

	shake_tween.kill()
	roll_card.queue_free()

	# 最終的に獲得するアイテムを決定
	var item: int = pool[randi() % pool.size()]
	var item_name: String = ItemLibrary.name(item)

	var slot_num: int = GameBalance.loadout_number_for_item(item) if item != Enums.ItemType.DELETE_CARD else -1
	var card_front: Control = DeskTheme.create_item_card_large(item, slot_num)
	card_front.pivot_offset = Vector2(190, 260) / 2.0
	card_front.scale = Vector2(0.1, 0.1)
	card_front.rotation_degrees = randf_range(-25.0, -15.0)
	card_area.add_child(card_front)

	# カード出現ズームインTween（バウンスさせつつ）
	var front_tween: Tween = card_front.create_tween().set_parallel(true)
	front_tween.tween_property(card_front, "scale", Vector2(1.15, 1.15), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	front_tween.tween_property(card_front, "rotation_degrees", randf_range(-2.0, 2.0), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await front_tween.finished

	var settle_tween: Tween = card_front.create_tween()
	settle_tween.tween_property(card_front, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

	# 祝賀紙吹雪パーティクル
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.position = card_area.global_position + Vector2(95, 130)
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 40
	particles.lifetime = 1.4
	particles.explosiveness = 0.9
	particles.spread = 180.0
	particles.gravity = Vector2(0, 220.0)
	particles.initial_velocity_min = 140.0
	particles.initial_velocity_max = 280.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	var grad: Gradient = Gradient.new()
	grad.set_offsets(PackedFloat32Array([0.0, 0.33, 0.66, 1.0]))
	grad.set_colors(PackedColorArray([Color("ffc9c9"), Color("ffd8a8"), Color("ffec99"), Color("a5d8ff")]))
	particles.color_ramp = grad
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	add_child(particles)

	if audio_manager:
		audio_manager.play_se("combo")

	var timer: SceneTreeTimer = get_tree().create_timer(1.6)
	timer.timeout.connect(particles.queue_free)

	# 解放 or レベルアップロジック適用
	if not Global.unlocked_items.has(item):
		Global.unlocked_items.append(item)
		Global.item_levels[item] = 1
		result_label.text = "【新規解放】\n%s が使えるようになった！" % item_name
		result_label.add_theme_color_override("font_color", DeskTheme.COLOR_ACCENT_GOLD)
		ToastOverlayScript.show_toast(self, "新しい文房具を入手！", DeskTheme.COLOR_SAFE)
	else:
		if not Global.item_levels.has(item):
			Global.item_levels[item] = 1
		Global.item_levels[item] += 1
		result_label.text = "【レベルアップ】\n%s Lv.%d に強化！" % [item_name, Global.item_levels[item]]
		result_label.add_theme_color_override("font_color", DeskTheme.COLOR_SAFE)
		ToastOverlayScript.show_toast(self, "文房具がレベルアップ！", DeskTheme.COLOR_SAFE)

	Global.save_data()

	_is_rolling = false
	gacha_btn.disabled = false
	back_btn.disabled = false
