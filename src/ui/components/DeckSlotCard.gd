class_name DeckSlotCard
extends Button

## スロット番号（1〜10）
var slot_num: int = 0
## 装備中のアイテムID
var item_id: String = ""

signal slot_clicked(slot_num: int)

# Internal refs
var _vbox: VBoxContainer
var _header_hbox: HBoxContainer
var _role_dot: ColorRect
var _num_lbl: Label
var _icon_rect: TextureRect
var _empty_icon: Label
var _name_lbl: Label
var _count_lbl: Label
var _prob_bar: ColorRect
var _prob_bg: ColorRect

static func create(p_slot_num: int, p_item_id: String) -> DeckSlotCard:
	var card = DeckSlotCard.new()
	card.slot_num = p_slot_num
	card.item_id = p_item_id
	return card

func _ready() -> void:
	custom_minimum_size = Vector2(250, 220)
	pivot_offset = Vector2(125, 110)
	text = ""
	
	# Slight organic tilt
	rotation_degrees = randf_range(-1.0, 1.0)
	
	_apply_style()
	_build_content()
	_setup_tooltip()
	_setup_animations()

func _apply_style() -> void:
	var item = _get_item()
	var is_empty = (item_id == "")
	var role_color = CardData.get_role_color(item.get("role", CardData.ROLE_PREP))
	
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_CRAFT
	style.border_color = role_color if not is_empty else Color(DeskTheme.COLOR_INK, 0.18)
	style.border_width_top = 20
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.16)
	style.shadow_size = 6
	style.shadow_offset = Vector2(2, 3)
	
	var hover_style = style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color("ede7d6")
	hover_style.shadow_size = 10
	
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", hover_style)
	add_theme_stylebox_override("focus", style)

func _build_content() -> void:
	var item = _get_item()
	var is_empty = (item_id == "")
	var role_color = CardData.get_role_color(item.get("role", CardData.ROLE_PREP))
	var prob = (float(slot_num) / 55.0) * 100.0
	
	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 3)
	_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vbox)
	
	# Header: role dot + slot label
	_header_hbox = HBoxContainer.new()
	_header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_header_hbox.add_theme_constant_override("separation", 5)
	_header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_header_hbox)
	
	if not is_empty:
		_role_dot = ColorRect.new()
		_role_dot.custom_minimum_size = Vector2(8, 8)
		_role_dot.color = role_color
		_role_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_header_hbox.add_child(_role_dot)
	
	_num_lbl = Label.new()
	if not is_empty:
		var role_name = CardData.get_role_name(item["role"])
		_num_lbl.text = "%s  P%d" % [role_name, slot_num]
	else:
		_num_lbl.text = "ポケット %d" % slot_num
	_num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_num_lbl.add_theme_font_override("font", DeskTheme.get_font())
	_num_lbl.add_theme_font_size_override("font_size", 14)
	_num_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.75))
	_num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_hbox.add_child(_num_lbl)
	
	# Item icon or empty placeholder
	if not is_empty:
		var img_path = CardData.get_item_image_path(item_id)
		if img_path != "":
			_icon_rect = TextureRect.new()
			_icon_rect.texture = load(img_path)
			_icon_rect.custom_minimum_size = Vector2(64, 64)
			_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_vbox.add_child(_icon_rect)
		else:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(64, 20)
			_vbox.add_child(spacer)
	else:
		_empty_icon = Label.new()
		_empty_icon.text = "＋"
		_empty_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_empty_icon.add_theme_font_override("font", DeskTheme.get_font())
		_empty_icon.add_theme_font_size_override("font_size", 30)
		_empty_icon.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.4))
		_empty_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_vbox.add_child(_empty_icon)
	
	# Item name
	_name_lbl = Label.new()
	_name_lbl.text = item.get("name", "空き") if not is_empty else "タップして装備"
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.add_theme_font_override("font", DeskTheme.get_font())
	_name_lbl.add_theme_font_size_override("font_size", 18 if not is_empty else 14)
	_name_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK if not is_empty else Color(DeskTheme.COLOR_INK, 0.6))
	_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_name_lbl)
	
	# Card count + probability bar
	var count_row = HBoxContainer.new()
	count_row.alignment = BoxContainer.ALIGNMENT_CENTER
	count_row.add_theme_constant_override("separation", 6)
	count_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(count_row)
	
	_count_lbl = Label.new()
	_count_lbl.text = "%d枚 (%.1f%%)" % [slot_num, prob]
	_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_lbl.add_theme_font_override("font", DeskTheme.get_font())
	_count_lbl.add_theme_font_size_override("font_size", 13)
	_count_lbl.add_theme_color_override("font_color", role_color if not is_empty else Color(DeskTheme.COLOR_INK, 0.6))
	_count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_row.add_child(_count_lbl)
	
	# Mini probability bar
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(50, 6)
	bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_row.add_child(bar_container)
	
	_prob_bg = ColorRect.new()
	_prob_bg.color = Color(DeskTheme.COLOR_INK, 0.08)
	_prob_bg.size = Vector2(50, 6)
	_prob_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(_prob_bg)
	
	_prob_bar = ColorRect.new()
	_prob_bar.color = role_color if not is_empty else Color(DeskTheme.COLOR_INK, 0.35)
	_prob_bar.size = Vector2(50 * (prob / 20.0), 6)  # Scale: 20% = full bar
	_prob_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(_prob_bar)

func _setup_tooltip() -> void:
	var item = _get_item()
	var is_empty = (item_id == "")
	var prob = (float(slot_num) / 55.0) * 100.0
	var prob_desc = "頻出ポケット (高確率！)" if slot_num >= 8 else ("レアポケット (一発逆転！)" if slot_num <= 2 else "中確率ポケット")
	
	if not is_empty:
		tooltip_text = "%s: %s\n(山札に%d枚入っています。出現率: %.1f%% / %s)" % [item["name"], item.get("description", ""), slot_num, prob, prob_desc]
	else:
		tooltip_text = "ポケット %d: 空きスロット\n(山札に%d枚入っています。出現率: %.1f%% / %s)\nクリックして装備" % [slot_num, slot_num, prob, prob_desc]

func _setup_animations() -> void:
	mouse_entered.connect(func():
		DeskTheme.animate_hover(self, true, Vector2.ONE, 0.12)
	)
	mouse_exited.connect(func():
		DeskTheme.animate_hover(self, false, Vector2.ONE, 0.12)
	)
	pressed.connect(func():
		release_focus()
		DeskTheme.animate_click(self, Vector2.ONE, 0.08)
		slot_clicked.emit(slot_num)
	)

func _get_item() -> Dictionary:
	if item_id == "":
		return {"name": "空き", "role": CardData.ROLE_PREP}
	return CardData.ITEMS.get(item_id, {"name": "空き", "role": CardData.ROLE_PREP})
