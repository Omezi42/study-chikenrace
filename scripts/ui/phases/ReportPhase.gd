# scripts/ui/phases/ReportPhase.gd
class_name ReportPhase
extends RefCounted
const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")
const DeskTheme = preload("res://scripts/ui/DeskTheme.gd")
const GameBalanceScript = preload("res://scripts/core/GameBalance.gd")

signal phase_completed()

var ctx: RefCounted
var actual_score: int
var reported_score: int

# UI参照保持
var ui_elements: Dictionary = {}

func _init(context: RefCounted):
	self.ctx = context

func start(today_score_dict: Dictionary):
	# 以前はDictionaryだったが、これからは {"score": int} の形式で受け取る
	self.actual_score = today_score_dict.get("score", 0)
	self.reported_score = self.actual_score
	if is_instance_valid(ctx) and ctx.backend_manager:
		ctx.backend_manager.clear_daily_votes()
	_show_report_screen()

func _show_report_screen():
	for child in ctx.screen_content.get_children():
		child.queue_free()
	ui_elements.clear()
	
	var notebook = NotebookBuilderScript.create()
	notebook.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notebook.offset_left = 420.0
	notebook.offset_top = 80.0
	notebook.offset_right = -120.0
	notebook.offset_bottom = -80.0
	ctx.screen_content.add_child(notebook)
	ctx.active_notebook = notebook
	
	var left_area = Control.new()
	left_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_area.anchor_right = 0.3
	ctx.screen_content.add_child(left_area)
	
	var app_container = SmartphoneBuilderScript.create_mockup(ctx, true)
	var phone = ctx.bag_ui_elements.get("report_page")
	if is_instance_valid(phone):
		phone.set_meta("lock_zoom", true)
	
	var app_header = PanelContainer.new()
	app_header.custom_minimum_size = Vector2(0, 52)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color("ffffff")
	header_style.border_width_bottom = 2
	header_style.border_color = Color("e1e4e6")
	app_header.add_theme_stylebox_override("panel", header_style)
	app_container.add_child(app_header)
	
	var app_header_h = HBoxContainer.new()
	app_header_h.add_theme_constant_override("separation", 8)
	app_header_h.alignment = BoxContainer.ALIGNMENT_CENTER
	app_header.add_child(app_header_h)
	
	var app_icon = ColorRect.new()
	app_icon.custom_minimum_size = Vector2(26, 26)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = DeskTheme.COLOR_SAFE
	icon_style.corner_radius_top_left = 6; icon_style.corner_radius_top_right = 6
	icon_style.corner_radius_bottom_left = 6; icon_style.corner_radius_bottom_right = 6
	app_icon.add_theme_stylebox_override("panel", icon_style)
	app_header_h.add_child(app_icon)
	
	var app_icon_lbl = DeskTheme.create_label("S", 13, Color.WHITE)
	app_icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app_icon.add_child(app_icon_lbl)
	
	var app_title = DeskTheme.create_label("チキスタ !", 16, DeskTheme.COLOR_SAFE, true)
	app_header_h.add_child(app_title)
	
	var app_scroll = ScrollContainer.new()
	app_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app_container.add_child(app_scroll)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 12)
	app_scroll.add_child(scroll_vbox)
	
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 12)
	margin_c.add_theme_constant_override("margin_top", 12)
	margin_c.add_theme_constant_override("margin_right", 12)
	margin_c.add_theme_constant_override("margin_bottom", 12)
	scroll_vbox.add_child(margin_c)
	
	var content_v = VBoxContainer.new()
	content_v.add_theme_constant_override("separation", 12)
	margin_c.add_child(content_v)
	ui_elements["content_v"] = content_v
	
	var title_card = PanelContainer.new()
	var tc_style = StyleBoxFlat.new()
	tc_style.bg_color = Color("f8f9fa")
	tc_style.corner_radius_top_left = 12; tc_style.corner_radius_top_right = 12
	tc_style.corner_radius_bottom_left = 12; tc_style.corner_radius_bottom_right = 12
	title_card.add_theme_stylebox_override("panel", tc_style)
	content_v.add_child(title_card)
	
	var tm = MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 10); tm.add_theme_constant_override("margin_right", 10)
	tm.add_theme_constant_override("margin_top", 8); tm.add_theme_constant_override("margin_bottom", 8)
	title_card.add_child(tm)
	
	var title_v = VBoxContainer.new()
	title_v.add_theme_constant_override("separation", 2)
	tm.add_child(title_v)
	
	title_v.add_child(DeskTheme.create_label("[ 本日の学習報告 ]", 18, DeskTheme.COLOR_INK, true))
	title_v.add_child(DeskTheme.create_label("スライダーを動かして点数を盛ろう！\n(嘘がバレると盛った分の2倍減点！)", 13, DeskTheme.COLOR_MUTED, true))
	
	var list_card = PanelContainer.new()
	var lc_style = StyleBoxFlat.new()
	lc_style.bg_color = Color.WHITE
	lc_style.corner_radius_top_left = 16; lc_style.corner_radius_top_right = 16
	lc_style.corner_radius_bottom_left = 16; lc_style.corner_radius_bottom_right = 16
	lc_style.border_width_bottom = 2
	lc_style.border_color = Color("e6e8eb")
	list_card.add_theme_stylebox_override("panel", lc_style)
	content_v.add_child(list_card)
	
	var lm = MarginContainer.new()
	lm.add_theme_constant_override("margin_left", 8); lm.add_theme_constant_override("margin_right", 8)
	lm.add_theme_constant_override("margin_top", 12); lm.add_theme_constant_override("margin_bottom", 12)
	list_card.add_child(lm)
	
	var list_v = VBoxContainer.new()
	list_v.add_theme_constant_override("separation", 16)
	lm.add_child(list_v)
	
	var is_burst = (actual_score == 0)
	
	var card_v = VBoxContainer.new()
	card_v.add_theme_constant_override("separation", 6)
	list_v.add_child(card_v)
	
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	card_v.add_child(info_row)
	
	var name_lbl = DeskTheme.create_label("総合スコア", 16, DeskTheme.COLOR_INK, true)
	name_lbl.custom_minimum_size = Vector2(70, 0)
	info_row.add_child(name_lbl)
	
	var actual_badge = PanelContainer.new()
	var ab_style = StyleBoxFlat.new()
	ab_style.bg_color = Color("3a86f0")
	ab_style.corner_radius_top_left = 6; ab_style.corner_radius_top_right = 6
	ab_style.corner_radius_bottom_left = 6; ab_style.corner_radius_bottom_right = 6
	ab_style.content_margin_left = 6; ab_style.content_margin_right = 6
	ab_style.content_margin_top = 2; ab_style.content_margin_bottom = 2
	actual_badge.add_theme_stylebox_override("panel", ab_style)
	info_row.add_child(actual_badge)
	
	var actual_lbl = DeskTheme.create_label("実際:%d点" % actual_score, 13, Color.WHITE, true)
	actual_badge.add_child(actual_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(spacer)
	
	var report_h = HBoxContainer.new()
	report_h.alignment = BoxContainer.ALIGNMENT_CENTER
	report_h.add_theme_constant_override("separation", 4)
	info_row.add_child(report_h)
	
	var status_icon = DeskTheme.create_label("🟢", 14, Color.WHITE, true)
	report_h.add_child(status_icon)
	
	var report_lbl = DeskTheme.create_label("%d点" % actual_score, 15, DeskTheme.COLOR_INK, true)
	report_h.add_child(report_lbl)
	
	var slider_h = HBoxContainer.new()
	slider_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_h.add_theme_constant_override("separation", 8)
	card_v.add_child(slider_h)
	
	var minus_btn = DeskTheme.create_button("-", Vector2(36, 36), Color("e9edf2"), Color("b8c4d1"), true)
	minus_btn.add_theme_font_size_override("font_size", 14)
	minus_btn.pivot_offset = Vector2(18, 18)
	slider_h.add_child(minus_btn)
	
	minus_btn.mouse_entered.connect(func():
		minus_btn.pivot_offset = minus_btn.size / 2.0
		var tw = minus_btn.create_tween()
		tw.tween_property(minus_btn, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
	)
	minus_btn.mouse_exited.connect(func():
		var tw = minus_btn.create_tween()
		tw.tween_property(minus_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	
	var cheat_count = 0
	if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.deck:
		cheat_count = ctx.game_session.deck.cheat_sheet_count
	var bluff_cap = GameBalanceScript.max_bluff_cap(cheat_count)

	var slider = HSlider.new()
	slider.min_value = actual_score
	slider.max_value = bluff_cap if is_burst else actual_score + bluff_cap
	slider.value = actual_score
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var eraser_style = StyleBoxFlat.new()
	eraser_style.bg_color = DeskTheme.COLOR_BLUFF_RED
	eraser_style.corner_radius_top_left = 5; eraser_style.corner_radius_top_right = 5
	eraser_style.corner_radius_bottom_left = 5; eraser_style.corner_radius_bottom_right = 5
	eraser_style.expand_margin_top = 8; eraser_style.expand_margin_bottom = 8
	eraser_style.expand_margin_left = 10; eraser_style.expand_margin_right = 10
	slider.add_theme_stylebox_override("grabber", eraser_style)
	slider.add_theme_stylebox_override("grabber_highlight", eraser_style)
	
	var ruler_bg = StyleBoxFlat.new()
	ruler_bg.bg_color = Color("dfd5b8")
	ruler_bg.corner_radius_top_left = 3; ruler_bg.corner_radius_top_right = 3
	ruler_bg.corner_radius_bottom_left = 3; ruler_bg.corner_radius_bottom_right = 3
	ruler_bg.expand_margin_top = 3; ruler_bg.expand_margin_bottom = 3
	slider.add_theme_stylebox_override("slider", ruler_bg)
	slider_h.add_child(slider)
	
	var plus_btn = DeskTheme.create_button("+", Vector2(36, 36), DeskTheme.COLOR_ACCENT_GOLD, Color("b38f30"))
	plus_btn.add_theme_font_size_override("font_size", 14)
	plus_btn.pivot_offset = Vector2(18, 18)
	slider_h.add_child(plus_btn)
	
	plus_btn.mouse_entered.connect(func():
		plus_btn.pivot_offset = plus_btn.size / 2.0
		var tw = plus_btn.create_tween()
		tw.tween_property(plus_btn, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
	)
	plus_btn.mouse_exited.connect(func():
		var tw = plus_btn.create_tween()
		tw.tween_property(plus_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	
	var bluff_hint_text = "バーストでも盛れる上限: %d点まで" % bluff_cap if is_burst else "盛れる上限: 実スコア＋最大%d点まで" % bluff_cap
	var bluff_hint = DeskTheme.create_label(bluff_hint_text, 12, DeskTheme.COLOR_MUTED, true)
	bluff_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_v.add_child(bluff_hint)
	
	ui_elements["slider_data"] = {"hbox": report_h, "label": report_lbl, "icon": status_icon}
	
	var last_val = { "val": actual_score }
	minus_btn.pressed.connect(func():
		if slider.value > slider.min_value:
			slider.value -= 1
			var m_tw = minus_btn.create_tween()
			m_tw.tween_property(minus_btn, "scale", Vector2(0.85, 0.85), 0.04)
			m_tw.tween_property(minus_btn, "scale", Vector2(1.0, 1.0), 0.07).set_trans(Tween.TRANS_BACK)
	)
	plus_btn.pressed.connect(func():
		if slider.value < slider.max_value:
			slider.value += 1
			var p_tw = plus_btn.create_tween()
			p_tw.tween_property(plus_btn, "scale", Vector2(0.85, 0.85), 0.04)
			p_tw.tween_property(plus_btn, "scale", Vector2(1.0, 1.0), 0.07).set_trans(Tween.TRANS_BACK)
	)
	
	slider.value_changed.connect(func(val):
		var i_val = int(val)
		if i_val == last_val["val"]: return
		last_val["val"] = i_val
		reported_score = i_val
		
		var s_tw = slider.create_tween()
		s_tw.tween_property(slider, "position:y", slider.position.y - 1.5, 0.03)
		s_tw.tween_property(slider, "position:y", slider.position.y, 0.05).set_trans(Tween.TRANS_BACK)
		if ctx.audio_manager: ctx.audio_manager.play_se("place")
		
		var label_data = ui_elements["slider_data"] as Dictionary
		var lbl = label_data["label"] as Label
		var icon = label_data["icon"] as Label
		var hbox = label_data["hbox"] as HBoxContainer
		
		hbox.pivot_offset = hbox.size / 2.0
		var tw = hbox.create_tween()
		if i_val > actual_score:
			lbl.text = "%d点" % i_val
			lbl.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
			icon.text = "⚠️"
			tw.tween_property(hbox, "scale", Vector2(1.22, 1.22), 0.08).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(hbox, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
			if ctx.audio_manager: ctx.audio_manager.play_se("click")
		else:
			lbl.text = "%d点" % i_val
			lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
			icon.text = "🟢"
			tw.tween_property(hbox, "scale", Vector2(1.0, 1.0), 0.08)
			if ctx.audio_manager:
				ctx.audio_manager.play_se("click")
				ctx.audio_manager.play_se("click")
		_update_report_warning()
	)
	
	var warning_card = PanelContainer.new()
	warning_card.custom_minimum_size = Vector2(0, 100)
	var wc_style = StyleBoxFlat.new()
	wc_style.bg_color = Color("f1f8ff")
	wc_style.corner_radius_top_left = 16; wc_style.corner_radius_top_right = 16
	wc_style.corner_radius_bottom_left = 16; wc_style.corner_radius_bottom_right = 16
	wc_style.border_width_bottom = 2
	wc_style.border_color = Color("d0e1fd")
	warning_card.add_theme_stylebox_override("panel", wc_style)
	content_v.add_child(warning_card)
	
	ui_elements["warning_card_style"] = wc_style
	ui_elements["warning_card"] = warning_card
	
	var wm = MarginContainer.new()
	wm.add_theme_constant_override("margin_left", 12); wm.add_theme_constant_override("margin_right", 12)
	wm.add_theme_constant_override("margin_top", 10); wm.add_theme_constant_override("margin_bottom", 10)
	warning_card.add_child(wm)
	
	var warning_v = VBoxContainer.new()
	warning_v.alignment = BoxContainer.ALIGNMENT_CENTER
	warning_v.add_theme_constant_override("separation", 6)
	wm.add_child(warning_v)
	
	var warning_title = DeskTheme.create_label("[ 報告ステータス ]", 15, Color("2b5c8f"), true)
	warning_v.add_child(warning_title)
	ui_elements["noise_warning_title"] = warning_title
	
	var warning_desc = DeskTheme.create_label("正直な報告です！\n(応援されたら＋10点！)", 16, DeskTheme.COLOR_INK, true)
	warning_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_v.add_child(warning_desc)
	ui_elements["noise_warning"] = warning_desc
	
	var warning_hint = DeskTheme.create_label("※嘘がバレると盛った差分の2倍減点！謙虚なら応援でボーナス！", 12, DeskTheme.COLOR_MUTED, true)
	warning_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_v.add_child(warning_hint)
	
	var footer = PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 80)
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = Color("ffffff")
	footer_style.border_width_top = 2
	footer_style.border_color = Color("e1e4e6")
	footer.add_theme_stylebox_override("panel", footer_style)
	app_container.add_child(footer)
	
	var fm = MarginContainer.new()
	fm.add_theme_constant_override("margin_left", 16); fm.add_theme_constant_override("margin_right", 16)
	fm.add_theme_constant_override("margin_top", 10); fm.add_theme_constant_override("margin_bottom", 10)
	footer.add_child(fm)
	
	var submit_btn = DeskTheme.create_button("学習報告をチキスタに投稿", Vector2(0, 52), DeskTheme.COLOR_SAFE, Color("2d928a"))
	submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_btn.pressed.connect(func(): _submit_final())
	fm.add_child(submit_btn)
	
	submit_btn.pivot_offset = submit_btn.size / 2.0
	submit_btn.mouse_entered.connect(func():
		submit_btn.pivot_offset = submit_btn.size / 2.0
		var tw = submit_btn.create_tween()
		tw.tween_property(submit_btn, "scale", Vector2(1.06, 1.06), 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
	)
	submit_btn.mouse_exited.connect(func():
		var tw = submit_btn.create_tween()
		tw.tween_property(submit_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	_update_report_warning()

func _update_report_warning():
	var diff = reported_score - actual_score
	
	var warning_lbl = ui_elements["noise_warning"] as Label
	var warning_title = ui_elements["noise_warning_title"] as Label
	var wc_style = ui_elements["warning_card_style"] as StyleBoxFlat
	var card = ui_elements["warning_card"] as Control
	card.pivot_offset = card.size / 2.0
	var tw = card.create_tween().set_parallel(true)
	
	if diff > 0:
		var penalty = GameBalanceScript.player_lie_exposed_penalty(diff)
		warning_title.text = "[ 嘘つきリスク警告！ ]"
		warning_title.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
		warning_lbl.text = "報告に嘘(盛り)が混ざっています！\n見破られた場合の減点: −%d点！" % penalty
		warning_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
		tw.tween_property(wc_style, "bg_color", Color("fff5f5"), 0.15)
		tw.tween_property(wc_style, "border_color", Color("ffd5d5"), 0.15)
		var scale_tw = card.create_tween()
		scale_tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.08).set_trans(Tween.TRANS_CUBIC)
		scale_tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_BACK)
	else:
		warning_title.text = "[ 報告ステータス: 正真 ]"
		warning_title.add_theme_color_override("font_color", Color("2b5c8f"))
		warning_lbl.text = "正直な報告です！\n(応援されたら＋10点！)"
		warning_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
		tw.tween_property(wc_style, "bg_color", Color("f1f8ff"), 0.15)
		tw.tween_property(wc_style, "border_color", Color("d0e1fd"), 0.15)
	
	var summary_key = "lie_summary"
	var content_v_ref = ui_elements.get("content_v")
	if not ui_elements.has(summary_key) and is_instance_valid(content_v_ref):
		var sum_lbl = DeskTheme.create_label("", 12, DeskTheme.COLOR_MUTED, true)
		sum_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_v_ref.add_child(sum_lbl)
		ui_elements[summary_key] = sum_lbl
	
	var sum_lbl = ui_elements[summary_key] as Label
	if diff > 0:
		sum_lbl.text = "盛り分: +%d点  バレたら: −%d点" % [diff, GameBalanceScript.player_lie_exposed_penalty(diff)]
		sum_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
	else:
		sum_lbl.text = "正直に報告中 ✔"
		sum_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_SAFE)

func _submit_final():
	var page_panel = ctx.bag_ui_elements.get("report_page")
	if is_instance_valid(page_panel):
		var exit_tw = page_panel.create_tween().set_parallel(true)
		exit_tw.tween_property(page_panel, "position:y", 1200, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		exit_tw.tween_property(page_panel, "scale", Vector2(0.5, 0.5), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		if ctx.audio_manager: ctx.audio_manager.play_se("place")
		await exit_tw.finished
	else:
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		
	# Globalの記録用変数を単一スコア版に変更（事前にGlobal.gdを修正する必要あり）
	if "last_actual_score" in Global:
		Global.last_actual_score = actual_score
		Global.last_reported_score = reported_score
	
	# Global.total_score には実際のスコアではなく申告スコアを加算
	Global.total_score += reported_score
	Global.play_count += 1
	
	var daily_hidden = 0
	if is_instance_valid(ctx) and ctx.game_session:
		daily_hidden = ctx.game_session.hidden_bonus_score
		ctx.game_session.hidden_bonus_score = 0

	var day_entry = {
		"day": Global.play_count,
		"total": Global.total_score,
		"actual_score": actual_score,
		"reported_score": reported_score,
		"hidden_bonus": daily_hidden,
		"rivals": []
	}
	if is_instance_valid(ctx) and ctx.game_session and ctx.game_session.ai_manager:
		var daily_res = ctx.game_session.ai_manager.get_daily_results()
		for r_name in daily_res:
			var res = daily_res[r_name]
			day_entry["rivals"].append({
				"name": r_name,
				"score": res["reported_score"],
				"actual_score": res["actual_score"],
				"is_lying": res["is_lying"]
			})
	elif ctx.backend_manager and "current_scores" in ctx.backend_manager:
		for rival in ctx.backend_manager.current_scores:
			day_entry["rivals"].append({"name": rival.get("name", "???"), "score": rival.get("score", 0), "actual_score": rival.get("score", 0), "is_lying": false})
	Global.score_history.append(day_entry)
	
	Global.save_data()
	
	if ctx.backend_manager:
		ctx.backend_manager.submit_score(Global.player_name, {"score": reported_score})
	
	if Global.play_count >= 5:
		SceneTransition.fade_to_scene("res://ResultScene.tscn")
	else:
		phase_completed.emit()