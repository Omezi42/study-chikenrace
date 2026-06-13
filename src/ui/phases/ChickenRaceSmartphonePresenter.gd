class_name ChickenRaceSmartphonePresenter
extends RefCounted

var phase: ChickenRacePhase

func _init(p_phase: ChickenRacePhase) -> void:
	phase = p_phase

func update_ui() -> void:
	if phase.header_left:
		phase.header_left.text = "自習ノート - %d時限目" % phase.session.current_hour
	var score_info = phase.session.player_deck.calculate_hand_score()
	phase.actual_score_label.text = str(score_info["total_score"]) + "点"
	
	var prob = phase.session.player_deck.get_burst_probability()
	var pct = int(prob * 100)
	var has_timer = phase.session.player_deck.timer_active
	
	if pct == 0:
		phase.burst_prob_label.text = "眠気：安全" + (" (0%)" if has_timer else "")
		phase.led_indicator.color = DeskTheme.COLOR_GREEN
		phase.alert_banner.color.a = 0.0
	elif pct < 45:
		phase.burst_prob_label.text = "眠気：眠くなってきた" + (" (" + str(pct) + "%)" if has_timer else "")
		phase.led_indicator.color = Color.YELLOW
		phase.alert_banner.color.a = 0.0
	elif pct < 80:
		phase.burst_prob_label.text = "眠気：限界に近い！" + (" (" + str(pct) + "%)" if has_timer else "")
		phase.led_indicator.color = Color.ORANGE
		phase.alert_banner.color.a = 0.3
		phase.alert_banner.color = Color(DeskTheme.COLOR_TENSION, 0.3)
	else:
		phase.burst_prob_label.text = "眠気：意識が飛びそう！！" + (" (" + str(pct) + "%)" if has_timer else "")
		phase.led_indicator.color = DeskTheme.COLOR_TENSION
		phase.alert_banner.color.a = 0.8
		phase.alert_banner.color = Color(DeskTheme.COLOR_TENSION, 0.8)
		DeskTheme.pulse_vignette(phase.alert_banner, Color(DeskTheme.COLOR_TENSION), prob)
		
	if phase.session.player_deck.energy_drink_active:
		phase.burst_prob_label.text += " [注意]ドロー時25%で即寝落ち！"
		
	update_active_effects_ui()
	
	if is_instance_valid(phase.deck_count_lbl) and is_instance_valid(phase.deck_warning_lbl) and is_instance_valid(phase.deck_sticky):
		var deck_size = phase.session.player_deck.draw_pile.size()
		phase.deck_count_lbl.text = str(deck_size) + "枚"
		
		var sticky_style = phase.deck_sticky.get_theme_stylebox("panel") as StyleBoxFlat
		if deck_size <= 3:
			phase.deck_warning_lbl.visible = true
			if sticky_style:
				sticky_style.bg_color = Color("ffcdd2")
		else:
			phase.deck_warning_lbl.visible = false
			if sticky_style:
				sticky_style.bg_color = Color("fff59d")

func update_active_effects_ui() -> void:
	if not phase.active_effects_hbox:
		return
		
	for child in phase.active_effects_hbox.get_children():
		child.queue_free()
		
	var deck = phase.session.player_deck
	var active_list = []
	
	if deck.eraser_charges > 0:
		active_list.append({"name": "消しゴム効果", "color": DeskTheme.COLOR_ROLE_DEFENSE, "desc": "次の1枚のみ眠気回避"})
		
	if deck.red_sheet_active:
		active_list.append({"name": "赤シート", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "被り時に自動破棄"})
		
	if deck.next_draw_bonus_points > 0:
		active_list.append({"name": "シャーペン", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "ドロー得点+3点残: %d枚" % deck.next_draw_bonus_points})
		
	if deck.highlighter_active:
		active_list.append({"name": "蛍光ペン", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "ドロー得点+1点（全カード）"})
		
	if deck.blue_pen_active:
		active_list.append({"name": "青ペン", "color": DeskTheme.COLOR_ROLE_PREP, "desc": "ドロー得点+2点（全カード）"})
		
	if deck.energy_drink_active:
		active_list.append({"name": "エナジードリンク", "color": DeskTheme.COLOR_TENSION, "desc": "得点2倍（ドロー時25%寝落ち）"})
		
	if deck.timer_active:
		active_list.append({"name": "タイマー", "color": DeskTheme.COLOR_ROLE_PREP, "desc": "眠気確率%を表示中"})
		
	if deck.compass_active:
		active_list.append({"name": "コンパス", "color": DeskTheme.COLOR_ROLE_PREP, "desc": "山札の被りカードを探知中"})
		
	if deck.amulet_active:
		active_list.append({"name": "お守り", "color": DeskTheme.COLOR_ROLE_DEFENSE, "desc": "寝落ち時に得点の50%キープ"})
		
	if deck.cram_school_print_active:
		active_list.append({"name": "塾プリント", "color": DeskTheme.COLOR_ROLE_PUSH, "desc": "時限の最終得点＋10点"})
		
	for eff in active_list:
		var badge = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = DeskTheme.COLOR_CRAFT
		style.border_color = eff["color"]
		style.border_width_left = 3
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 2
		style.content_margin_bottom = 2
		badge.add_theme_stylebox_override("panel", style)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 1)
		badge.add_child(vbox)
		
		var title_lbl = Label.new()
		title_lbl.text = eff["name"]
		title_lbl.add_theme_font_override("font", DeskTheme.get_font())
		title_lbl.add_theme_font_size_override("font_size", 10)
		title_lbl.add_theme_color_override("font_color", eff["color"])
		vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = eff["desc"]
		desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		vbox.add_child(desc_lbl)
		
		phase.active_effects_hbox.add_child(badge)
