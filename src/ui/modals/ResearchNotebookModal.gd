# -*- coding: utf-8 -*-
class_name ResearchNotebookModal
extends CanvasLayer

static func create_and_show(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = ResearchNotebookModal.new()
	parent_node.add_child(canvas)

func _ready() -> void:
	layer = 101
	
	# Background dim overlay
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.45)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)
	
	# Modal Container
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(560, 620)
	modal.pivot_offset = Vector2(280, 310)
	
	# Use craft panel styling from DeskTheme
	modal.add_theme_stylebox_override("panel", DeskTheme.create_craft_panel())
	add_child(modal)
	
	var viewport_size = get_viewport().get_visible_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
	# Entrance animation
	modal.scale = Vector2.ZERO
	var entry_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entry_tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)
	
	# Title Area
	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(title_vbox)
	
	var title = Label.new()
	title.text = "📖 研究ノート"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DeskTheme.get_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	title_vbox.add_child(title)
	
	var sub_title = Label.new()
	sub_title.text = "— 上級者向けメニュー —"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_title.add_theme_font_override("font", DeskTheme.get_font())
	sub_title.add_theme_font_size_override("font_size", 13)
	sub_title.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.5))
	title_vbox.add_child(sub_title)
	
	# Divider
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(DeskTheme.COLOR_INK, 0.15)
	vbox.add_child(divider)
	
	# Scroll area for buttons (just in case screen is small)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var buttons_vbox = VBoxContainer.new()
	buttons_vbox.add_theme_constant_override("separation", 12)
	buttons_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(buttons_vbox)
	
	# 1. 5日制モード (じっくり対戦)
	_add_menu_button(
		buttons_vbox,
		"📚 5日制モード (じっくり対戦)",
		"3時限×5日間の授業を戦い抜き、ライバルの嘘を見破る心理戦モード",
		func():
			_close_modal()
			var parent = get_parent()
			if parent.has_method("show_mode_selection_modal"):
				parent.show_mode_selection_modal()
	)
	
	# 2. カバン整理 (デッキ編成)
	_add_menu_button(
		buttons_vbox,
		"🎒 カバン整理 (デッキ編成)",
		"手札をのぞき見る『単語帳』や、寝落ちを防ぐ『消しゴム』などデッキをカスタマイズ",
		func():
			_close_modal()
			Global.change_scene_with_fade(get_tree(), "res://LoadoutScene.tscn")
	)
	
	# 3. 購買部ガチャ
	_add_menu_button(
		buttons_vbox,
		"🪙 購買部ガチャ",
		"コインを使って、新しい効果を持った便利な文房具アイテムをアンロック",
		func():
			_close_modal()
			Global.change_scene_with_fade(get_tree(), "res://GachaScene.tscn")
	)
	
	# 4. アイテム図鑑
	_add_menu_button(
		buttons_vbox,
		"📖 アイテム図鑑",
		"解放した文房具の効果や、使い込んで獲得した星レベル（育成状況）を確認",
		func():
			_close_modal()
			Global.change_scene_with_fade(get_tree(), "res://ZukanScene.tscn")
	)
	
	# 5. あそびかた (チュートリアル)
	_add_menu_button(
		buttons_vbox,
		"❓ あそびかた (チュートリアル)",
		"佐藤くんが勉強チキンレースの基本から『ブラフとダウト』のコツまで解説する練習試合",
		func():
			_close_modal()
			Global.is_tutorial_mode = true
			Global.game_mode = Constants.MODE_CPU
			Global.opponent_profiles = {
				"cpu_sato": {"name": "佐藤くん", "deviation": 51.5},
				"cpu_suzuki": {"name": "鈴木さん", "deviation": 48.0},
				"cpu_takahashi": {"name": "高橋くん", "deviation": 54.2}
			}
			if Global.player_name == "":
				Global.player_name = "プレイヤー"
			Global.change_scene_with_fade(get_tree(), "res://Main.tscn")
	)
	
	# 6. 設定
	_add_menu_button(
		buttons_vbox,
		"⚙️ 音量・システム設定",
		"BGMやSEの音量調整、ミュート切り替え、手書きフォントの設定",
		func():
			_close_modal()
			SettingsModal.create_and_show(get_parent())
	)
	
	# Close Button at bottom
	var close_btn = Button.new()
	close_btn.text = "閉じる"
	close_btn.custom_minimum_size = Vector2(160, 45)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_override("font", DeskTheme.get_font())
	close_btn.add_theme_font_size_override("font_size", 16)
	Global.apply_white_button_style(close_btn)
	close_btn.pressed.connect(func():
		close_btn.release_focus()
		DeskTheme.animate_click(close_btn, Vector2.ONE, 0.08)
		_close_modal()
	)
	vbox.add_child(close_btn)

func _add_menu_button(parent: Node, title_text: String, desc_text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 60)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Apply standard white button style
	Global.apply_white_button_style(btn)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_theme_constant_override("separation", 2)
	inner_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title_text
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	inner_vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc_text
	desc_lbl.add_theme_font_override("font", DeskTheme.get_font())
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.55))
	inner_vbox.add_child(desc_lbl)
	
	btn.pressed.connect(func():
		btn.release_focus()
		DeskTheme.animate_click(btn, Vector2.ONE, 0.08)
		# Delay callback slightly for click animation feel
		var timer = get_tree().create_timer(0.08)
		timer.timeout.connect(callback)
	)
	
	parent.add_child(btn)

func _close_modal() -> void:
	# Fade out and queue_free
	var out_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	out_tween.chain().tween_callback(queue_free)
