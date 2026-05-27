class_name BagBuilderPhase
extends PhaseBase

var card_options: Array[Dictionary] = []
var selected_option_idx: int = -1

# Programmatic UI elements
var notebook: PanelContainer
var title_label: Label
var cards_container: HBoxContainer
var description_box: PanelContainer
var desc_title: Label
var desc_body: Label
var desc_role_label: Label

func _on_setup(setup_data: Dictionary) -> void:
	custom_minimum_size = Vector2(1400, 800)
	size = Vector2(1400, 800)
	
	notebook = PanelContainer.new()
	notebook.custom_minimum_size = Vector2(1400, 800)
	notebook.size = Vector2(1400, 800)
	notebook.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(notebook)
	
	DeskTheme.add_ruled_lines(notebook)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(1400, 800)
	main_vbox.size = Vector2(1400, 800)
	main_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	main_vbox.add_theme_constant_override("separation", 45)
	notebook.add_child(main_vbox)
	
	# Top spacer to lock vertical positions regardless of description panel changes
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 80)
	main_vbox.add_child(top_spacer)
	
	# Title
	title_label = Label.new()
	title_label.text = "%d時限目のカバン整理：追加するアイテムを1つ選んでください" % session.current_hour
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	main_vbox.add_child(title_label)
	
	# HBox for 3 Cards
	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 60)
	main_vbox.add_child(cards_container)
	
	# Description Sticky Note (PanelContainer)
	description_box = PanelContainer.new()
	description_box.custom_minimum_size = Vector2(850, 240)
	description_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var craft_style = DeskTheme.create_craft_panel()
	description_box.add_theme_stylebox_override("panel", craft_style)
	main_vbox.add_child(description_box)
	
	# Margin Container inside description box
	var desc_margin = MarginContainer.new()
	desc_margin.add_theme_constant_override("margin_left", 20)
	desc_margin.add_theme_constant_override("margin_right", 20)
	desc_margin.add_theme_constant_override("margin_top", 15)
	desc_margin.add_theme_constant_override("margin_bottom", 15)
	description_box.add_child(desc_margin)
	
	var desc_vbox = VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 12)
	desc_margin.add_child(desc_vbox)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	desc_vbox.add_child(header_hbox)
	
	desc_title = Label.new()
	desc_title.text = "アイテムを選択してください"
	desc_title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	desc_title.add_theme_font_size_override("font_size", 28)
	desc_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	header_hbox.add_child(desc_title)
	
	desc_role_label = Label.new()
	desc_role_label.text = ""
	desc_role_label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	desc_role_label.add_theme_font_size_override("font_size", 22)
	header_hbox.add_child(desc_role_label)
	
	desc_body = Label.new()
	desc_body.text = "カードをホバーするとここに説明が表示されます。"
	desc_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_body.custom_minimum_size = Vector2(810, 140)
	desc_body.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	desc_body.add_theme_font_size_override("font_size", 22)
	desc_body.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	desc_vbox.add_child(desc_body)
	
	# Generate 3 card choices from Gacha/Unlocked pool
	generate_choices()
	populate_cards_ui()
	
	# Slide in transition on the notebook panel instead of the parent Phase control
	DeskTheme.animate_entrance(notebook, Vector2.ZERO, Vector2(0, 300), 0.5)
	
	if Global.is_tutorial_mode and session.current_day == 1 and session.current_hour == 1:
		show_tutorial_dialog("カバン整理フェーズへようこそ！\nここでは自習ノート（山札）に追加するアイテムを1つ選びます。追加されたアイテムは自習中に引くことができ、様々な強力な効果を発揮します。\n\nどれでも好きなカードを1つクリックして選んでみましょう！", Vector2(440, 20))

# Pick 3 random items that are unlocked or from gacha (excluding system tokens)
func generate_choices() -> void:
	card_options.clear()
	var pool = []
	for item_id in CardData.ITEMS.keys():
		var item = CardData.ITEMS[item_id]
		# Only offer cards that are unlocked OR in the gacha pool, excluding system items like forget notebook
		if item_id != "item_forget_notebook":
			pool.append(item)
			
	pool.shuffle()
	for i in range(min(3, pool.size())):
		var item_copy = pool[i].duplicate()
		item_copy["value"] = randi_range(1, 10)
		card_options.append(item_copy)

func populate_cards_ui() -> void:
	for child in cards_container.get_children():
		child.queue_free()
		
	for idx in range(card_options.size()):
		var item = card_options[idx]
		
		# Create Card visual
		var card_button = Button.new()
		card_button.custom_minimum_size = Vector2(240, 330)
		card_button.pivot_offset = Vector2(120, 165)
		
		# Craft paper style for the card
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
		card_button.add_theme_stylebox_override("normal", card_style)
		card_button.add_theme_stylebox_override("hover", card_style)
		card_button.add_theme_stylebox_override("pressed", card_style)
		
		var card_vbox = VBoxContainer.new()
		card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_theme_constant_override("separation", 14)
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_button.add_child(card_vbox)
		
		# Subject Badge (positioned absolutely in top-left)
		var sub_icon_path = CardData.get_subject_icon_path(item["subject"])
		if sub_icon_path != "":
			var sub_color = Color.GRAY
			match item["subject"]:
				CardData.SUBJECT_MATH: sub_color = Color("2979ff")
				CardData.SUBJECT_ENGLISH: sub_color = Color("ff1744")
				CardData.SUBJECT_JAPANESE: sub_color = Color("00c853")
				CardData.SUBJECT_SCIENCE: sub_color = Color("ff9100")
				CardData.SUBJECT_SOCIAL: sub_color = Color("aa00ff")
				
			var subject_badge = PanelContainer.new()
			subject_badge.position = Vector2(10, 10)
			subject_badge.custom_minimum_size = Vector2(32, 32)
			subject_badge.size = Vector2(32, 32)
			
			var badge_style = StyleBoxFlat.new()
			badge_style.bg_color = sub_color
			badge_style.corner_radius_top_left = 16
			badge_style.corner_radius_top_right = 16
			badge_style.corner_radius_bottom_left = 16
			badge_style.corner_radius_bottom_right = 16
			badge_style.content_margin_left = 4
			badge_style.content_margin_right = 4
			badge_style.content_margin_top = 4
			badge_style.content_margin_bottom = 4
			subject_badge.add_theme_stylebox_override("panel", badge_style)
			
			var icon_rect = TextureRect.new()
			icon_rect.texture = load(sub_icon_path)
			icon_rect.custom_minimum_size = Vector2(24, 24)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			subject_badge.add_child(icon_rect)
			
			card_button.add_child(subject_badge)
		
		# Value Badge (positioned absolutely in top-right)
		var value_badge = PanelContainer.new()
		value_badge.position = Vector2(240 - 42, 10)
		value_badge.custom_minimum_size = Vector2(32, 32)
		value_badge.size = Vector2(32, 32)
		
		var val_badge_style = StyleBoxFlat.new()
		val_badge_style.bg_color = DeskTheme.COLOR_INK
		val_badge_style.corner_radius_top_left = 16
		val_badge_style.corner_radius_top_right = 16
		val_badge_style.corner_radius_bottom_left = 16
		val_badge_style.corner_radius_bottom_right = 16
		value_badge.add_theme_stylebox_override("panel", val_badge_style)
		
		var val_lbl = Label.new()
		val_lbl.text = str(item["value"])
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		val_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		val_lbl.add_theme_font_size_override("font_size", 18)
		val_lbl.add_theme_color_override("font_color", Color.WHITE)
		value_badge.add_child(val_lbl)
		
		card_button.add_child(value_badge)
		
		# Image
		var img_path = CardData.get_item_image_path(item["id"])
		if img_path != "":
			var tex_rect = TextureRect.new()
			tex_rect.texture = load(img_path)
			tex_rect.custom_minimum_size = Vector2(140, 140)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			card_vbox.add_child(tex_rect)
		else:
			# Spacer
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(140, 60)
			card_vbox.add_child(spacer)
			
		# Name Label
		var label = Label.new()
		label.text = item["name"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		card_vbox.add_child(label)
		
		# Short Effect Label
		var effect_lbl = Label.new()
		var short_eff = CardData.get_item_short_effect(item["id"])
		if short_eff != "":
			effect_lbl.text = "【" + short_eff + "】"
		else:
			effect_lbl.text = ""
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_lbl.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
		effect_lbl.add_theme_font_size_override("font_size", 14)
		effect_lbl.add_theme_color_override("font_color", Color("ff4081") if item["role"] == CardData.ROLE_PUSH else Color(DeskTheme.COLOR_INK, 0.6))
		card_vbox.add_child(effect_lbl)
		
		# Connect Signals for Juiciness
		card_button.mouse_entered.connect(_on_card_hovered.bind(idx, card_button, true))
		card_button.mouse_exited.connect(_on_card_hovered.bind(idx, card_button, false))
		card_button.pressed.connect(_on_card_selected.bind(idx, card_button))
		
		cards_container.add_child(card_button)

func _on_card_hovered(idx: int, button: Button, is_hover: bool) -> void:
	DeskTheme.animate_hover(button, is_hover, Vector2.ONE, 0.15)
	
	if is_hover:
		var item = card_options[idx]
		desc_title.text = item["name"]
		desc_body.text = item["description"] + "\n\n【このカードの値: " + str(item["value"]) + "】\n※手札に加わると " + str(item["value"]) + " 点として加算されますが、自習中に同じ数字を引くと寝落ち（バースト）します。"
		desc_role_label.text = " [" + CardData.get_role_name(item["role"]) + "]"
		desc_role_label.add_theme_color_override("font_color", CardData.get_role_color(item["role"]))
		
		# Dynamic craft panel highlighted color
		var highlight_style = DeskTheme.create_craft_panel()
		highlight_style.border_color = CardData.get_role_color(item["role"])
		description_box.add_theme_stylebox_override("panel", highlight_style)
	else:
		# Reset description
		desc_title.text = "アイテムを選択してください"
		desc_body.text = "カードをホバーするとここに説明が表示されます。"
		desc_role_label.text = ""
		description_box.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())

func _on_card_selected(idx: int, button: Button) -> void:
	selected_option_idx = idx
	DeskTheme.animate_click(button, Vector2.ONE, 0.08)
	
	# Sound click
	# (In final game, BGM/SE would play, but tests don't require SE files to exist to compile)
	
	# Wait for click animation to finish before closing
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		var chosen_item = card_options[selected_option_idx]
		
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_se(AudioManager.SE_PLACE)
		
		# Apply selected item to player's session deck (adds 1 copy of value = 0 utility card to deck)
		# Utility card:得点には加算されず、バーストの危険もありません
		var new_card = {
			"value": chosen_item["value"], 
			"subject": chosen_item["subject"] if chosen_item["subject"] != CardData.SUBJECT_NONE else "math",
			"item_id": chosen_item["id"],
			"name": chosen_item["name"]
		}
		session.player_deck.cards.append(new_card)
		session.player_deck.draw_pile.append(new_card)
		session.player_deck.shuffle_draw_pile()
		
		finish_phase({
			"selected_item_id": chosen_item["id"],
			"selected_item_name": chosen_item["name"]
		})
	)
