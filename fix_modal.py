import re

with open('src/ui/phases/DailyLikesUIBuilder.gd', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace block 1
target1 = '''\tvar canvas = CanvasLayer.new()
\tcanvas.layer = 160
\tscene_tree.root.add_child(canvas)
\t
\tvar bg = ColorRect.new()
\tbg.color = Color(0, 0, 0, 0.6)
\tbg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\tcanvas.add_child(bg)
\t
\tvar modal = PanelContainer.new()
\tmodal.custom_minimum_size = Vector2(750, 500)
\tmodal.pivot_offset = Vector2(375, 250)'''

repl1 = '''\tvar viewport_size = scene_tree.root.get_viewport().get_visible_rect().size
\tvar screen_w = viewport_size.x if viewport_size.x > 0 else 1920
\tvar screen_h = viewport_size.y if viewport_size.y > 0 else 1080
\tvar is_portrait = screen_w < screen_h
\t
\tvar canvas = CanvasLayer.new()
\tcanvas.layer = 160
\tscene_tree.root.add_child(canvas)
\t
\tvar bg = ColorRect.new()
\tbg.color = Color(0, 0, 0, 0.6)
\tbg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\tcanvas.add_child(bg)
\t
\tvar center = CenterContainer.new()
\tcenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\tcanvas.add_child(center)
\t
\tvar modal = PanelContainer.new()
\tvar modal_w = min(screen_w * 0.9, 750.0)
\tmodal.custom_minimum_size = Vector2(modal_w, 0)
\t# pivot_offset is estimated for the animation
\tmodal.pivot_offset = Vector2(modal_w / 2.0, 250.0)'''

text = text.replace(target1, repl1)

target2 = '''\tmodal.add_theme_stylebox_override("panel", base_style)
\tcanvas.add_child(modal)
\t
\tvar viewport_size = scene_tree.root.get_viewport().get_visible_rect().size
\tvar screen_w = viewport_size.x if viewport_size.x > 0 else 1920
\tvar screen_h = viewport_size.y if viewport_size.y > 0 else 1080
\tmodal.position = Vector2((screen_w - 750) / 2.0, (screen_h - 500) / 2.0)
\t
\tvar margin = MarginContainer.new()
\tmargin.add_theme_constant_override("margin_left", 30)
\tmargin.add_theme_constant_override("margin_right", 30)
\tmargin.add_theme_constant_override("margin_top", 25)
\tmargin.add_theme_constant_override("margin_bottom", 25)
\tmodal.add_child(margin)
\t
\tvar vbox = VBoxContainer.new()
\tvbox.add_theme_constant_override("separation", 20)'''

repl2 = '''\tmodal.add_theme_stylebox_override("panel", base_style)
\tcenter.add_child(modal)
\t
\tvar margin = MarginContainer.new()
\tmargin.add_theme_constant_override("margin_left", 30 if not is_portrait else 15)
\tmargin.add_theme_constant_override("margin_right", 30 if not is_portrait else 15)
\tmargin.add_theme_constant_override("margin_top", 25)
\tmargin.add_theme_constant_override("margin_bottom", 25)
\tmodal.add_child(margin)
\t
\tvar vbox = VBoxContainer.new()
\tvbox.add_theme_constant_override("separation", 20 if not is_portrait else 15)'''

text = text.replace(target2, repl2)

target3 = '''\tvar title_lbl = Label.new()
\ttitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\ttitle_lbl.add_theme_font_override("font", DeskTheme.get_font())
\ttitle_lbl.add_theme_font_size_override("font_size", 36)'''

repl3 = '''\tvar title_lbl = Label.new()
\ttitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\ttitle_lbl.add_theme_font_override("font", DeskTheme.get_font())
\ttitle_lbl.add_theme_font_size_override("font_size", 36 if not is_portrait else 28)'''

text = text.replace(target3, repl3)

target4 = '''\tvar desc_lbl = Label.new()
\tdesc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tdesc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
\tdesc_lbl.add_theme_font_override("font", DeskTheme.get_font())
\tdesc_lbl.add_theme_font_size_override("font_size", 18)'''

repl4 = '''\tvar desc_lbl = Label.new()
\tdesc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tdesc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
\tdesc_lbl.add_theme_font_override("font", DeskTheme.get_font())
\tdesc_lbl.add_theme_font_size_override("font_size", 18 if not is_portrait else 15)'''

text = text.replace(target4, repl4)

target5 = '''\tvar cards_hbox = HBoxContainer.new()
\tcards_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
\tcards_hbox.add_theme_constant_override("separation", 30)
\tvbox.add_child(cards_hbox)'''

repl5 = '''\tvar cards_container
\tif is_portrait:
\t\tcards_container = VBoxContainer.new()
\telse:
\t\tcards_container = HBoxContainer.new()
\tcards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
\tcards_container.add_theme_constant_override("separation", 30 if not is_portrait else 15)
\tvbox.add_child(cards_container)'''

text = text.replace(target5, repl5)
text = text.replace("cards_hbox.add_child", "cards_container.add_child")

target6 = '''static func show_tutorial_finish_modal(phase: DailyLikesPhase) -> void:
\tvar modal = PanelContainer.new()
\tmodal.custom_minimum_size = Vector2(650, 400)
\tmodal.size = Vector2(650, 400)
\tmodal.pivot_offset = Vector2(325, 200)'''

repl6 = '''static func show_tutorial_finish_modal(phase: DailyLikesPhase) -> void:
\tvar viewport_size = phase.get_viewport_rect().size
\tvar screen_w = viewport_size.x if viewport_size.x > 0 else 1920
\tvar screen_h = viewport_size.y if viewport_size.y > 0 else 1080
\tvar is_portrait = screen_w < screen_h
\t
\tvar center = CenterContainer.new()
\tcenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\tphase.add_child(center)
\t
\tvar modal = PanelContainer.new()
\tvar modal_w = min(screen_w * 0.9, 650.0)
\tmodal.custom_minimum_size = Vector2(modal_w, 0)
\t# estimation for scale animation pivot
\tmodal.pivot_offset = Vector2(modal_w / 2.0, 200.0)'''

text = text.replace(target6, repl6)

target7 = '''\tmodal.add_theme_stylebox_override("panel", style)
\t
\tphase.add_child(modal)
\tvar viewport_size = phase.get_viewport_rect().size
\tmodal.position = viewport_size * 0.5 - modal.pivot_offset
\t
\tvar margin = MarginContainer.new()
\tmargin.add_theme_constant_override("margin_left", 30)
\tmargin.add_theme_constant_override("margin_right", 30)
\tmargin.add_theme_constant_override("margin_top", 30)
\tmargin.add_theme_constant_override("margin_bottom", 30)
\tmodal.add_child(margin)'''

repl7 = '''\tmodal.add_theme_stylebox_override("panel", style)
\t
\tcenter.add_child(modal)
\t
\tvar margin = MarginContainer.new()
\tmargin.add_theme_constant_override("margin_left", 30 if not is_portrait else 20)
\tmargin.add_theme_constant_override("margin_right", 30 if not is_portrait else 20)
\tmargin.add_theme_constant_override("margin_top", 30 if not is_portrait else 24)
\tmargin.add_theme_constant_override("margin_bottom", 30 if not is_portrait else 24)
\tmodal.add_child(margin)'''

text = text.replace(target7, repl7)

target8 = '''\tvar title = Label.new()
\ttitle.text = "チュートリアル完了！"
\ttitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\ttitle.add_theme_font_override("font", DeskTheme.get_font())
\ttitle.add_theme_font_size_override("font_size", 32)'''

repl8 = '''\tvar title = Label.new()
\ttitle.text = "チュートリアル完了！"
\ttitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\ttitle.add_theme_font_override("font", DeskTheme.get_font())
\ttitle.add_theme_font_size_override("font_size", 32 if not is_portrait else 26)'''

text = text.replace(target8, repl8)

target9 = '''\tvar body = Label.new()
\tbody.text = "お疲れ様でした！『テスト勉強チキンレース』の基本的な遊び方（カードを引く駆け引き、寝落ちのリスク、点数報告でのブラフ、嘘とダウトの見極め）をマスターしました。\\n\\nソロ模試やランダム対戦でライバルたちを実力と駆け引きで圧倒し、勝利を掴み取りましょう！"
\tbody.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
\tbody.add_theme_font_override("font", DeskTheme.get_font())
\tbody.add_theme_font_size_override("font_size", 18)'''

repl9 = '''\tvar body = Label.new()
\tbody.text = "お疲れ様でした！『テスト勉強チキンレース』の基本的な遊び方（カードを引く駆け引き、寝落ちのリスク、点数報告でのブラフ、嘘とダウトの見極め）をマスターしました。\\n\\nソロ模試やランダム対戦でライバルたちを実力と駆け引きで圧倒し、勝利を掴み取りましょう！"
\tbody.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
\tbody.add_theme_font_override("font", DeskTheme.get_font())
\tbody.add_theme_font_size_override("font_size", 18 if not is_portrait else 15)'''

text = text.replace(target9, repl9)

with open('src/ui/phases/DailyLikesUIBuilder.gd', 'w', encoding='utf-8') as f:
    f.write(text)

print("Done")
