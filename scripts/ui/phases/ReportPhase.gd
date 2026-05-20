# scripts/ui/phases/ReportPhase.gd
class_name ReportPhase
extends RefCounted
const NotebookBuilderScript = preload("res://scripts/ui/components/NotebookBuilder.gd")
const SmartphoneBuilderScript = preload("res://scripts/ui/components/SmartphoneBuilder.gd")


signal phase_completed()

var ctx: RefCounted
var scores: Dictionary
var reported_scores: Dictionary = {}
var slider_labels: Dictionary = {}

# UI参照保持
var ui_elements: Dictionary = {}

func _init(context: RefCounted):
	self.ctx = context

func start(today_scores: Dictionary):
	self.scores = today_scores
	_show_report_screen()

func _show_report_screen():
	for child in ctx.screen_content.get_children():
		child.queue_free()
	ui_elements.clear()
	reported_scores.clear()
	slider_labels.clear()
	
	# 背景に見開きノートを置く（ふせんフェーズと同じ世界観を維持）
	var notebook = NotebookBuilderScript.create()
	notebook.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notebook.offset_left = 420.0
	notebook.offset_top = 80.0
	notebook.offset_right = -120.0
	notebook.offset_bottom = -80.0
	ctx.screen_content.add_child(notebook)
	ctx.active_notebook = notebook
	
	# 左側の机の上エリア（スマホ置き場）
	var left_area = Control.new()
	left_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_area.anchor_right = 0.3 # 画面左側30%
	ctx.screen_content.add_child(left_area)
	
	var app_container = SmartphoneBuilderScript.create_mockup(ctx, true)
	var phone = ctx.bag_ui_elements.get("report_page")
	if is_instance_valid(phone):
		phone.set_meta("lock_zoom", true)
	
	# 1. アプリヘッダー (Studyplus風)
	var app_header = PanelContainer.new()
	app_header.custom_minimum_size = Vector2(0, 52)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color("ffffff") # 白クリーンなヘッダー
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
	
	# アプリ内メインスクロールエリア
	var app_scroll = ScrollContainer.new()
	app_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app_container.add_child(app_scroll)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 12)
	app_scroll.add_child(scroll_vbox)
	
	# パディング用 MarginContainer
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
	
	# 報告画面タイトル＆説明カード
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
	
	title_v.add_child(DeskTheme.create_label("[ 本日の学習報告（成績発表） ]", 18, DeskTheme.COLOR_INK, true))
	title_v.add_child(DeskTheme.create_label("スライダーを動かして勉強時間を報告しよう！\n(嘘を盛るリスク・謙虚にするボーナスあり)", 13, DeskTheme.COLOR_MUTED, true))
	
	# スライダーリストカード
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
	
	var is_burst = true
	for val in scores.values():
		if val > 0:
			is_burst = false
			break

	for s in range(5):
		var actual_val = scores.get(s, 0)
		reported_scores[s] = actual_val
		var s_row = HBoxContainer.new()
		s_row.add_theme_constant_override("separation", 6)
		list_v.add_child(s_row)
		
		# 教科名
		var name_lbl = DeskTheme.create_label(DeskTheme.subject_name(s), 16, DeskTheme.subject_color(s), true)
		name_lbl.custom_minimum_size = Vector2(48, 0)
		s_row.add_child(name_lbl)
		
		# 実際スコア（グラフィカルな青いバッジ）
		var actual_badge = PanelContainer.new()
		var ab_style = StyleBoxFlat.new()
		ab_style.bg_color = Color("3a86f0")
		ab_style.corner_radius_top_left = 6
		ab_style.corner_radius_top_right = 6
		ab_style.corner_radius_bottom_left = 6
		ab_style.corner_radius_bottom_right = 6
		ab_style.content_margin_left = 6
		ab_style.content_margin_right = 6
		ab_style.content_margin_top = 2
		ab_style.content_margin_bottom = 2
		actual_badge.add_theme_stylebox_override("panel", ab_style)
		s_row.add_child(actual_badge)
		
		var actual_lbl = DeskTheme.create_label("%d点" % actual_val, 13, Color.WHITE, true)
		actual_badge.add_child(actual_lbl)
		
		# ➖➕付きスライダー
		var slider_h = HBoxContainer.new()
		slider_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider_h.add_theme_constant_override("separation", 4)
		s_row.add_child(slider_h)
		
		# -ボタン (クリックでボヨヨン ＆ ホバーぷっくり)
		var minus_btn = DeskTheme.create_button("-", Vector2(32, 32), Color("e9edf2"), Color("b8c4d1"), true)
		minus_btn.add_theme_font_size_override("font_size", 11)
		minus_btn.pivot_offset = Vector2(16, 16)
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
		
		# 木製定規風スライダー (過少申告不可: min は実際のスコア, maxは状況に応じた嘘上限)
		var slider = HSlider.new()
		slider.min_value = actual_val
		slider.max_value = 10 if is_burst else min(20, actual_val + 10)
		slider.value = actual_val

		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# 消しゴム風つまみのカスタムテーマ適用
		var eraser_style = StyleBoxFlat.new()
		eraser_style.bg_color = DeskTheme.COLOR_BLUFF_RED # 消しゴムの赤
		eraser_style.corner_radius_top_left = 5; eraser_style.corner_radius_top_right = 5
		eraser_style.corner_radius_bottom_left = 5; eraser_style.corner_radius_bottom_right = 5
		eraser_style.expand_margin_top = 6; eraser_style.expand_margin_bottom = 6
		eraser_style.expand_margin_left = 9; eraser_style.expand_margin_right = 9
		slider.add_theme_stylebox_override("grabber", eraser_style)
		slider.add_theme_stylebox_override("grabber_highlight", eraser_style)
		
		var ruler_bg = StyleBoxFlat.new()
		ruler_bg.bg_color = Color("dfd5b8") # 木製定規の温かいベージュ
		ruler_bg.corner_radius_top_left = 3; ruler_bg.corner_radius_top_right = 3
		ruler_bg.corner_radius_bottom_left = 3; ruler_bg.corner_radius_bottom_right = 3
		ruler_bg.expand_margin_top = 2; ruler_bg.expand_margin_bottom = 2
		slider.add_theme_stylebox_override("slider", ruler_bg)
		slider_h.add_child(slider)
		
		# +ボタン (クリックでボヨヨン ＆ ホバーぷっくり)
		var plus_btn = DeskTheme.create_button("+", Vector2(32, 32), DeskTheme.COLOR_ACCENT_GOLD, Color("b38f30"))
		plus_btn.add_theme_font_size_override("font_size", 11)
		plus_btn.pivot_offset = Vector2(16, 16)
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
		
		var report_h = HBoxContainer.new()
		report_h.custom_minimum_size = Vector2(85, 0)
		report_h.alignment = BoxContainer.ALIGNMENT_CENTER
		report_h.add_theme_constant_override("separation", 4)
		s_row.add_child(report_h)
		
		var status_icon = DeskTheme.create_label("🟢", 14, Color.WHITE, true)
		report_h.add_child(status_icon)
		
		var report_lbl = DeskTheme.create_label("%d点" % actual_val, 15, DeskTheme.COLOR_INK, true)
		report_h.add_child(report_lbl)
		
		slider_labels[s] = {"hbox": report_h, "label": report_lbl, "icon": status_icon, "actual_val": actual_val}
		
		# 前回の値を保持して整数値の変化だけを検知する
		var last_val = { "val": actual_val }
		
		# +-物理ボタンの連動
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
		
		# スライダー入力のリアルタイム変更イベント
		slider.value_changed.connect(func(val):
			var i_val = int(val)
			if i_val == last_val["val"]:
				return # 値が変わっていなければスキップ
			last_val["val"] = i_val
			reported_scores[s] = i_val
			
			# スライダー自体の物理ダイヤル振動フィードバック
			var s_tw = slider.create_tween()
			s_tw.tween_property(slider, "position:y", slider.position.y - 1.5, 0.03)
			s_tw.tween_property(slider, "position:y", slider.position.y, 0.05).set_trans(Tween.TRANS_BACK)
			if ctx.audio_manager: ctx.audio_manager.play_se("place") # カチッというダイヤル音代わり
			
			var label_data = slider_labels[s] as Dictionary
			var lbl = label_data["label"] as Label
			var icon = label_data["icon"] as Label
			var hbox = label_data["hbox"] as HBoxContainer
			
			hbox.pivot_offset = hbox.size / 2.0
			var tw = hbox.create_tween()
			if i_val > actual_val:
				lbl.text = "%d点" % i_val
				lbl.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
				icon.text = "⚠️"
				tw.tween_property(hbox, "scale", Vector2(1.22, 1.22), 0.08).set_trans(Tween.TRANS_CUBIC)
				tw.tween_property(hbox, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
				if ctx.audio_manager:
					ctx.audio_manager.play_se("click")
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
		
	# 💡 動的警告通知カード（Studyplus風）
	var warning_card = PanelContainer.new()
	warning_card.custom_minimum_size = Vector2(0, 100)
	var wc_style = StyleBoxFlat.new()
	wc_style.bg_color = Color("f1f8ff") # 初期は正直（水色系）
	wc_style.corner_radius_top_left = 16; wc_style.corner_radius_top_right = 16
	wc_style.corner_radius_bottom_left = 16; wc_style.corner_radius_bottom_right = 16
	wc_style.border_width_bottom = 2
	wc_style.border_color = Color("d0e1fd")
	warning_card.add_theme_stylebox_override("panel", wc_style)
	content_v.add_child(warning_card)
	
	ui_elements["warning_card_style"] = wc_style # リアルタイムに背景と枠線をTweenで変えるために保持
	ui_elements["warning_card"] = warning_card # スケールTweenのために保持
	
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
	
	var warning_hint = DeskTheme.create_label("※嘘がバレると盛った差分の2倍減点！謙虚なら応援で大ボーナス！", 12, DeskTheme.COLOR_MUTED, true)
	warning_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_v.add_child(warning_hint)
	
	# フッター（固定の提出ボタン）
	var footer = PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 80)
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = Color("ffffff") # 白背景
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
	
	# 投稿ボタンホバーバウンド (極上インタラクション)
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
	var lie_diff_total = 0
	
	for s in scores:
		if reported_scores[s] > scores[s]:
			lie_diff_total += (reported_scores[s] - scores[s])
			
	var warning_lbl = ui_elements["noise_warning"] as Label
	var warning_title = ui_elements["noise_warning_title"] as Label
	var wc_style = ui_elements["warning_card_style"] as StyleBoxFlat
	var card = ui_elements["warning_card"] as Control
	card.pivot_offset = card.size / 2.0
	var tw = card.create_tween().set_parallel(true)
	
	if lie_diff_total > 0:
		var penalty = lie_diff_total * 2
		warning_title.text = "[ 嘘つきリスク警告！ ]"
		warning_title.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
		warning_lbl.text = "報告に嘘(盛り)が混ざっています！\n見破られた場合の減点: 最大 −%d点！" % penalty
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
	
	# 全教科の盛り合計サマリーを警告カード外に表示
	var total_lie = 0
	var lie_subjects = 0
	for s_idx in scores:
		var diff = reported_scores[s_idx] - scores[s_idx]
		if diff > 0:
			total_lie += diff
			lie_subjects += 1
	
	var summary_key = "lie_summary"
	var content_v_ref = ui_elements.get("content_v")
	if not ui_elements.has(summary_key) and is_instance_valid(content_v_ref):
		var sum_lbl = DeskTheme.create_label("", 12, DeskTheme.COLOR_MUTED, true)
		sum_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_v_ref.add_child(sum_lbl)
		ui_elements[summary_key] = sum_lbl
	
	var sum_lbl = ui_elements[summary_key] as Label
	if total_lie > 0:
		sum_lbl.text = "盛り合計: +%d点 (%d教科)  バレたら: −%d点" % [total_lie, lie_subjects, total_lie * 2]
		sum_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_BLUFF_RED)
	else:
		sum_lbl.text = "全教科正直に報告中 ✔"
		sum_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_SAFE)

func _submit_final():
	var page_panel = ctx.bag_ui_elements.get("report_page") # これはスマホ本体 (phone)
	if is_instance_valid(page_panel):
		# 物理スライドダウン ＆ 縮小退場アニメーション！
		var exit_tw = page_panel.create_tween().set_parallel(true)
		exit_tw.tween_property(page_panel, "position:y", 1200, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		exit_tw.tween_property(page_panel, "scale", Vector2(0.5, 0.5), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		if ctx.audio_manager: ctx.audio_manager.play_se("place")
		await exit_tw.finished
	else:
		if ctx.audio_manager: ctx.audio_manager.play_se("click")
		
	# ノイズシステム廃止のため daily_noises は常に0でリセット
	# 実際と報告のスコア記録を保存
	for s in scores:
		Global.daily_noises[s] = 0
		Global.last_actual_scores[s] = scores[s]
		Global.last_reported_scores[s] = reported_scores[s]
		
	# 前日のトップ教科を保存
	Global.last_top_subjects.clear()
	var tops = ctx.backend_manager.get_subject_top_scores()
	for s in tops.keys():
		if tops[s]["name"] == Global.player_name:
			Global.last_top_subjects.append(s)
			
	# 【新ルール】報告した点数（嘘含む）の合計がそのまま実際の点数として数えられ、合計スコアに加算される
	var reported_total = 0
	for s in reported_scores:
		reported_total += reported_scores[s]
	Global.total_score += reported_total
	Global.play_count += 1
	
	# スコア履歴にスナップショットを記録（報告スコアベースで記録）
	var day_entry = {
		"day": Global.play_count,
		"total": Global.total_score,
		"subjects": {},
		"actual_subjects": {},
		"rivals": []
	}
	for s in reported_scores:
		day_entry["subjects"][s] = reported_scores[s]
	for s in scores:
		day_entry["actual_subjects"][s] = scores[s]
	for rival in ctx.backend_manager.current_scores:
		day_entry["rivals"].append({"name": rival.get("name", "???"), "score": rival.get("score", 0)})
	Global.score_history.append(day_entry)
	
	# デイリー教科トップボーナス判定: 各教科でその日のスコアが1位なら+5点を蓄積
	var daily_tops = ctx.backend_manager.get_subject_top_scores()
	for s in range(5):
		var top = daily_tops[s]
		if top["name"] == Global.player_name and top["score"] > 0:
			var bonus_key = "%d_%d" % [Global.play_count, s]
			Global.daily_subject_top_bonus[bonus_key] = 5
	
	Global.save_data()
	
	# Supabaseサーバーへ提出
	ctx.backend_manager.submit_score(Global.player_name, reported_scores)
	
	# 7日間プレイ完了で最終シーズンリザルトへ
	if Global.play_count >= 7:
		SceneTransition.fade_to_scene("res://ResultScene.tscn")
	else:
		phase_completed.emit()