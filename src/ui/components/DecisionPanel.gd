class_name DecisionPanel
extends PanelContainer

# UI Elements
var score_label: Label
var burst_gauge: ProgressBar
var burst_text: Label
var deck_count_label: Label
var draw_count_label: Label
var expected_value_label: Label

# Colors
const COLOR_SAFE = Color("00e676")   # Green
const COLOR_WARN = Color("ffea00")   # Yellow
const COLOR_DANGER = Color("ff1744") # Red

func _init() -> void:
	# Basic styling
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_CRAFT
	style.border_color = DeskTheme.COLOR_INK
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	style.shadow_color = Color(0, 0, 0, 0.1)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	add_theme_stylebox_override("panel", style)
	
	custom_minimum_size = Vector2(300, 200)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# 1. Title
	var title = Label.new()
	title.text = "決断パネル"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)

	var separator = ColorRect.new()
	separator.custom_minimum_size = Vector2(0, 2)
	separator.color = DeskTheme.COLOR_INK
	vbox.add_child(separator)

	# 2. Score Info
	var score_hbox = HBoxContainer.new()
	vbox.add_child(score_hbox)
	
	var score_title = Label.new()
	score_title.text = "現在得点:"
	score_title.add_theme_font_override("font", DeskTheme.get_font())
	score_title.add_theme_font_size_override("font_size", 20)
	score_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	score_hbox.add_child(score_title)
	
	score_hbox.add_child(_create_spacer())
	
	score_label = Label.new()
	score_label.text = "0点"
	score_label.add_theme_font_override("font", DeskTheme.get_font())
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	score_hbox.add_child(score_label)

	# 3. Deck Info
	var deck_hbox = HBoxContainer.new()
	vbox.add_child(deck_hbox)

	var deck_title = Label.new()
	deck_title.text = "残り山札 / 引いた枚数:"
	deck_title.add_theme_font_override("font", DeskTheme.get_font())
	deck_title.add_theme_font_size_override("font_size", 16)
	deck_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
	deck_hbox.add_child(deck_title)

	deck_hbox.add_child(_create_spacer())

	var count_vbox = VBoxContainer.new()
	count_vbox.alignment = BoxContainer.ALIGNMENT_END
	deck_hbox.add_child(count_vbox)

	deck_count_label = Label.new()
	deck_count_label.text = "山札: --枚"
	deck_count_label.add_theme_font_override("font", DeskTheme.get_font())
	deck_count_label.add_theme_font_size_override("font_size", 16)
	deck_count_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	count_vbox.add_child(deck_count_label)

	draw_count_label = Label.new()
	draw_count_label.text = "手札: 0枚"
	draw_count_label.add_theme_font_override("font", DeskTheme.get_font())
	draw_count_label.add_theme_font_size_override("font_size", 16)
	draw_count_label.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	count_vbox.add_child(draw_count_label)

	# 4. Burst Gauge
	var burst_vbox = VBoxContainer.new()
	vbox.add_child(burst_vbox)

	var burst_title_hbox = HBoxContainer.new()
	vbox.add_child(burst_title_hbox)

	var burst_title = Label.new()
	burst_title.text = "バースト危険度:"
	burst_title.add_theme_font_override("font", DeskTheme.get_font())
	burst_title.add_theme_font_size_override("font_size", 18)
	burst_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	burst_title_hbox.add_child(burst_title)

	burst_title_hbox.add_child(_create_spacer())

	burst_text = Label.new()
	burst_text.text = "0% (安全)"
	burst_text.add_theme_font_override("font", DeskTheme.get_font())
	burst_text.add_theme_font_size_override("font_size", 18)
	burst_text.add_theme_color_override("font_color", COLOR_SAFE)
	burst_title_hbox.add_child(burst_text)

	burst_gauge = ProgressBar.new()
	burst_gauge.custom_minimum_size = Vector2(0, 15)
	burst_gauge.max_value = 100.0
	burst_gauge.value = 0.0
	burst_gauge.show_percentage = false
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0,0,0,0.1)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	burst_gauge.add_theme_stylebox_override("background", bg_style)
	burst_vbox.add_child(burst_gauge)

	# 5. Expected Value
	var expected_hbox = HBoxContainer.new()
	vbox.add_child(expected_hbox)

	var expected_title = Label.new()
	expected_title.text = "次を引く期待値:"
	expected_title.add_theme_font_override("font", DeskTheme.get_font())
	expected_title.add_theme_font_size_override("font_size", 16)
	expected_title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	expected_hbox.add_child(expected_title)

	expected_hbox.add_child(_create_spacer())

	expected_value_label = Label.new()
	expected_value_label.text = "+0.0点"
	expected_value_label.add_theme_font_override("font", DeskTheme.get_font())
	expected_value_label.add_theme_font_size_override("font_size", 18)
	expected_value_label.add_theme_color_override("font_color", DeskTheme.COLOR_BONUS)
	expected_hbox.add_child(expected_value_label)


func _create_spacer() -> Control:
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func update_info(score: int, burst_prob: float, deck_count: int, hand_count: int, expected_val: float) -> void:
	score_label.text = str(score) + "点"
	deck_count_label.text = "山札: " + str(deck_count) + "枚"
	draw_count_label.text = "手札: " + str(hand_count) + "枚"
	
	var prob_percent = int(burst_prob * 100)
	burst_gauge.value = prob_percent
	
	var fg_style = StyleBoxFlat.new()
	fg_style.corner_radius_top_left = 4
	fg_style.corner_radius_top_right = 4
	fg_style.corner_radius_bottom_left = 4
	fg_style.corner_radius_bottom_right = 4
	
	var status_text = ""
	var status_color = COLOR_SAFE
	if prob_percent < 20:
		status_text = " (安全)"
		status_color = COLOR_SAFE
	elif prob_percent < 50:
		status_text = " (注意)"
		status_color = COLOR_WARN
	else:
		status_text = " (危険)"
		status_color = COLOR_DANGER

	fg_style.bg_color = status_color
	burst_gauge.add_theme_stylebox_override("fill", fg_style)
	
	burst_text.text = str(prob_percent) + "%" + status_text
	burst_text.add_theme_color_override("font_color", status_color)

	if expected_val >= 0:
		expected_value_label.text = "+" + str(snapped(expected_val, 0.1)) + "点"
		expected_value_label.add_theme_color_override("font_color", DeskTheme.COLOR_BONUS)
	else:
		expected_value_label.text = str(snapped(expected_val, 0.1)) + "点"
		expected_value_label.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
