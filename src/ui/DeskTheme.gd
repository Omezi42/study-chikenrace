class_name DeskTheme
extends Node

# Color Palette Constants
const COLOR_MAHOGANY = Color("eddcc9")
const COLOR_CRAFT = Color("f4efe6")
const COLOR_INK = Color("1e2022")
const COLOR_HIGHLIGHTER = Color("fff176")
const COLOR_TENSION = Color("ff4081")
const COLOR_GREEN = Color("00e676")
const COLOR_BONUS = Color("40c057")
const COLOR_CHALK_WHITE = Color(1.0, 1.0, 1.0, 0.8)
const COLOR_CHALK_YELLOW = Color("ffe066")

# Role Type Colors
const COLOR_ROLE_DEFENSE = Color("00e676")  # Green (守り)
const COLOR_ROLE_PUSH = Color("ff9100")     # Orange (押し)
const COLOR_ROLE_BLUFF = Color("d500f9")    # Purple (ブラフ)
const COLOR_ROLE_PREP = Color("2979ff")     # Blue (仕込み)

# Font File Paths
const FONT_HANDWRITING = "res://assets/hgrsmp.ttf"

# Static Tween Animation Helper Functions

# 1. Hover Bounce & Random Angle Rotation
static func animate_hover(node: Control, is_hovered: bool, base_scale: Vector2 = Vector2.ONE, duration: float = 0.15) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	var tween = scene_tree.create_tween().bind_node(node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_hovered:
		var target_scale = base_scale * 1.06
		# Give a slight random rotation between -2 and 2 degrees to feel like a loose sticky note or card
		var target_rotation = randf_range(-2.0, 2.0)
		tween.tween_property(node, "scale", target_scale, duration)
		tween.tween_property(node, "rotation_degrees", target_rotation, duration)
	else:
		tween.tween_property(node, "scale", base_scale, duration)
		tween.tween_property(node, "rotation_degrees", 0.0, duration)

# 2. Click Pushdown & Bounce Transition
static func animate_click(node: Control, base_scale: Vector2 = Vector2.ONE, duration: float = 0.08) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	
	if scene_tree.root.has_node("AudioManager"):
		var audio = scene_tree.root.get_node("AudioManager")
		audio.play_se(audio.SE_CLICK)
		
	var tween = scene_tree.create_tween().bind_node(node).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var shrink_scale = base_scale * 0.92
	tween.tween_property(node, "scale", shrink_scale, duration)
	tween.tween_property(node, "scale", base_scale, duration)

# 3. Notebook/Panel Entrance Transition (Bottom to Center)
static func animate_entrance(node: Control, target_position: Vector2, start_offset: Vector2 = Vector2(0, 400), duration: float = 0.5) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	node.position = target_position + start_offset
	node.modulate.a = 0.0
	var tween = scene_tree.create_tween().bind_node(node).set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", target_position, duration)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.6)

# 4. 3D-like Card Flip Transition
static func animate_card_flip(node: Control, duration: float = 0.35, on_mid_flip: Callable = Callable()) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	var original_scale = node.scale
	var tween = scene_tree.create_tween().bind_node(node).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Shrink horizontally to 0 (midway flip)
	tween.tween_property(node, "scale:x", 0.0, duration * 0.5)
	
	# Call back to change texture/content
	if on_mid_flip.is_valid():
		tween.tween_callback(on_mid_flip)
		
	# Grow horizontally back to original
	tween.tween_property(node, "scale:x", original_scale.x, duration * 0.5).set_ease(Tween.EASE_OUT)

# 5. Screen / Node Position Shake (Cameras or UI elements)
static func shake_node(node: Node2D, intensity: float, duration: float, shake_count: int = 8) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	var original_pos = node.position
	var tween = scene_tree.create_tween().bind_node(node).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step_duration = duration / shake_count
	
	for i in range(shake_count - 1):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", original_pos + offset, step_duration)
		
	# Return to original
	tween.tween_property(node, "position", original_pos, step_duration)

# 6. UI Control Element Position Shake
static func shake_control(node: Control, intensity: float, duration: float, shake_count: int = 8) -> void:
	if not node or not node.is_inside_tree():
		return
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
	var original_pos = node.position
	var tween = scene_tree.create_tween().bind_node(node).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step_duration = duration / shake_count
	
	for i in range(shake_count - 1):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", original_pos + offset, step_duration)
		
	tween.tween_property(node, "position", original_pos, step_duration)

# 7. Vignette Alert Pulse Animation
static func pulse_vignette(node: Control, base_modulate: Color, alert_level: float) -> void:
	if not node or not node.is_inside_tree():
		return
	# Remove any existing tweens to avoid conflicts
	var scene_tree = node.get_tree()
	if not scene_tree:
		return
		
	var target_color = base_modulate
	target_color.a = clamp(alert_level * 0.45, 0.0, 0.5)
	
	var pulse_speed = 0.5
	if alert_level >= 0.8:
		pulse_speed = 0.25 # Speed up pulse for extreme danger
		
	var tween = scene_tree.create_tween().bind_node(node).set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate", target_color, pulse_speed)
	
	var dim_color = base_modulate
	dim_color.a = clamp(alert_level * 0.1, 0.0, 0.1)
	tween.tween_property(node, "modulate", dim_color, pulse_speed)

# Helper to create customized hand-drawn look panel stylebox
static func create_craft_panel() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_CRAFT
	style.border_color = COLOR_INK
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	# Richer shadow to look like stacked pages
	style.shadow_color = Color(0.12, 0.08, 0.05, 0.25)
	style.shadow_size = 12
	style.shadow_offset = Vector2(5, 5)
	return style

# Helper to create left page stylebox (no right border, no right rounded corners for binding integration)
static func create_left_page_style() -> StyleBoxFlat:
	var style = create_craft_panel()
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.border_width_right = 0
	return style

# Helper to create right page stylebox (no left border, no left rounded corners for binding integration)
static func create_right_page_style() -> StyleBoxFlat:
	var style = create_craft_panel()
	style.corner_radius_top_left = 0
	style.corner_radius_bottom_left = 0
	style.border_width_left = 0
	return style

# Helper to overlay notebook ruled lines
static func add_ruled_lines(parent_node: Control, line_color: Color = Color(0.2, 0.6, 0.8, 0.08)) -> void:
	if not parent_node:
		return
	var ruled_rect = RuledLinesDrawer.new()
	ruled_rect.line_color = line_color
	ruled_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ruled_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_node.add_child(ruled_rect)
	parent_node.move_child(ruled_rect, 0) # Place in background

# Helper to overlay spiral binding
static func add_spiral_binding(hbox: HBoxContainer, height: float = 750.0) -> void:
	if not hbox:
		return
	var binding_control = Control.new()
	binding_control.custom_minimum_size = Vector2(0, height) # Width 0 so pages touch
	binding_control.clip_contents = false
	hbox.add_child(binding_control)
	
	if hbox.get_child_count() > 1:
		hbox.move_child(binding_control, 1) # Put in middle
		
	var drawer = SpiralDrawer.new()
	drawer.custom_minimum_size = Vector2(0, height)
	drawer.clip_contents = false
	binding_control.add_child(drawer)

# 8. Floating Sticky-Note Toast Message
static func show_toast(caller_node: Node, text: String, duration: float = 1.8) -> void:
	if not caller_node or not caller_node.is_inside_tree():
		return
	var scene_tree = caller_node.get_tree()
	if not scene_tree or not scene_tree.root:
		return
		
	# Create CanvasLayer to overlay everything
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # High layer to be on top
	scene_tree.root.add_child(canvas)
	
	# Create Toast PanelContainer
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 60)
	panel.pivot_offset = Vector2(230, 30)
	
	# Styling (like a cute yellow sticky note or craft paper)
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_HIGHLIGHTER # Bright sticky note yellow
	style.border_color = COLOR_INK
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load(FONT_HANDWRITING))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", COLOR_INK)
	panel.add_child(label)
	
	canvas.add_child(panel)
	
	# Positioning (bottom center of the screen)
	var screen_w = 1920
	var screen_h = 1080
	var viewport_size = scene_tree.root.get_viewport().get_visible_rect().size
	if viewport_size.x > 0:
		screen_w = viewport_size.x
		screen_h = viewport_size.y
		
	var start_pos = Vector2((screen_w - 460) / 2.0, screen_h - 100)
	var end_pos = Vector2((screen_w - 460) / 2.0, screen_h - 160)
	
	panel.position = start_pos
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	
	# Tween animate slide up and fade in
	var tween = scene_tree.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position", end_pos, 0.3)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)
	
	# Hold for a moment, then fade out and queue_free
	var timer = scene_tree.create_timer(duration)
	timer.timeout.connect(func():
		if panel and panel.is_inside_tree():
			var fade_tween = scene_tree.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fade_tween.tween_property(panel, "position", end_pos - Vector2(0, 30), 0.3)
			fade_tween.tween_property(panel, "modulate:a", 0.0, 0.25)
			fade_tween.chain().tween_callback(func():
				canvas.queue_free()
			)
	)

# 9. Page-Flip Transition Animation
static func animate_page_flip(outgoing_node: Control, incoming_node: Control, duration: float = 0.45) -> void:
	if not incoming_node or not incoming_node.is_inside_tree():
		if outgoing_node and outgoing_node.is_inside_tree():
			outgoing_node.queue_free()
		return
	
	incoming_node.pivot_offset = incoming_node.custom_minimum_size / 2.0 if incoming_node.size == Vector2.ZERO else incoming_node.size / 2.0
	incoming_node.scale.x = 0.0
	incoming_node.modulate.a = 0.8
	
	var scene_tree = incoming_node.get_tree()
	if not scene_tree:
		return
		
	var tween = scene_tree.create_tween().bind_node(incoming_node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if outgoing_node and outgoing_node.is_inside_tree():
		outgoing_node.pivot_offset = outgoing_node.custom_minimum_size / 2.0 if outgoing_node.size == Vector2.ZERO else outgoing_node.size / 2.0
		var out_tween = scene_tree.create_tween().bind_node(outgoing_node).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(outgoing_node, "scale:x", 0.0, duration * 0.5)
		out_tween.tween_property(outgoing_node, "modulate:a", 0.0, duration * 0.5)
		out_tween.chain().tween_callback(func(): outgoing_node.queue_free())
		
		tween.tween_property(incoming_node, "scale:x", 1.0, duration).set_delay(duration * 0.4)
		tween.tween_property(incoming_node, "modulate:a", 1.0, duration).set_delay(duration * 0.4)
	else:
		tween.tween_property(incoming_node, "scale:x", 1.0, duration)
		tween.tween_property(incoming_node, "modulate:a", 1.0, duration)

# Inner class for ruled lines
class RuledLinesDrawer:
	extends Control
	
	var line_color: Color
	
	func _draw() -> void:
		var step = 30.0
		var h = size.y
		var w = size.x
		var y = 40.0
		while y < h - 20.0:
			draw_line(Vector2(20, y), Vector2(w - 20, y), line_color, 1.5)
			y += step
			
		# Red left margin line
		draw_line(Vector2(50, 10), Vector2(50, h - 10), Color("ff6b6b", 0.18), 2.0)

# Inner class for spiral binding
class SpiralDrawer:
	extends Control
	
	func _draw() -> void:
		var h = size.y
		var cy = 40.0
		var step = 32.0
		var center_x = 0.0
		
		# Draw dark spine shadow (center folding crease)
		draw_rect(Rect2(center_x - 30, 0, 60, h), Color(0.1, 0.08, 0.05, 0.12)) # Broad soft crease shadow
		draw_rect(Rect2(center_x - 15, 0, 30, h), Color(0.1, 0.08, 0.05, 0.18)) # Narrower crease shadow
		draw_line(Vector2(center_x, 0), Vector2(center_x, h), Color(0.05, 0.04, 0.02, 0.45), 2.5) # Central seam line
		
		# Draw silver rings looping through paper holes
		while cy < h - 30.0:
			# Left & right paper holes (small dark circles)
			draw_circle(Vector2(center_x - 14, cy), 3.0, Color("1e2022", 0.65))
			draw_circle(Vector2(center_x + 14, cy - 2.5), 3.0, Color("1e2022", 0.65))
			
			# Shadow under the ring coil
			draw_line(Vector2(center_x - 14, cy + 2.5), Vector2(center_x + 14, cy), Color(0.1, 0.08, 0.05, 0.22), 4.5)
			
			# Ring loop (silver metallic line)
			draw_line(Vector2(center_x - 14, cy), Vector2(center_x + 14, cy - 2.5), Color(0.76, 0.76, 0.8), 4.5)
			
			# Specular highlight core
			draw_line(Vector2(center_x - 10, cy - 0.6), Vector2(center_x + 10, cy - 2.0), Color.WHITE, 1.5)
			
			cy += step

static func show_rulebook(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	parent_node.add_child(canvas)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(900, 680)
	modal.pivot_offset = Vector2(450, 340)
	modal.add_theme_stylebox_override("panel", create_craft_panel())
	canvas.add_child(modal)
	modal.position = Vector2((1920 - 900) / 2.0, (1080 - 680) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Header with Title and Close Button
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "📝 テスト勉強チキンレース 公式ルールブック"
	title.add_theme_font_override("font", load(FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = " ✖ 閉じる "
	close_btn.add_theme_font_override("font", load(FONT_HANDWRITING))
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.custom_minimum_size = Vector2(100, 36)
	header_hbox.add_child(close_btn)
	
	# ScrollContainer for Rule Text
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var rtb = RichTextLabel.new()
	rtb.bbcode_enabled = true
	rtb.add_theme_font_override("normal_font", load(FONT_HANDWRITING))
	rtb.add_theme_font_override("bold_font", load(FONT_HANDWRITING))
	rtb.add_theme_font_size_override("normal_font_size", 16)
	rtb.add_theme_font_size_override("bold_font_size", 18)
	rtb.add_theme_color_override("default_color", COLOR_INK)
	rtb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var rules_text = "[center][font_size=28][b]テスト勉強チキンレースのルール[/b][/font_size][/center]\n\n"
	rules_text += "[font_size=18][b]1. ゲームの概要と勝利条件[/b][/font_size]\n"
	rules_text += "プレイヤーと3人のライバルが、5日間の勉強の成果（得点）を競い合います。\n"
	rules_text += "最終日の答え合わせ終了後、[b]最終得点（申告点 ＋ ダウト成功ボーナス － ダウト失敗ペナルティ － 嘘バレペナルティ）[/b]が最も高い人が合格（優勝）となります。\n\n"
	rules_text += "[font_size=18][b]2. 自習フェーズ（勉強チキンレース）[/b][/font_size]\n"
	rules_text += "毎日3時限（アイテムで最大4時限）の自習を行い、カードを引いて点数を高めます。\n"
	rules_text += "・[b]バースト（寝落ち）[/b]: 手札に同じ値（数字）のカードが重複した瞬間、その時限の点数はすべて [color=red]0点[/color] になります。\n"
	rules_text += "・[b]休憩[/b]: 任意のタイミングでドローを止めて休憩し、その時点の点数を確定（実点）できます。\n"
	rules_text += "・[b]山札の構成 (55枚)[/b]: デッキスロットNには、該当カードが「N枚」入ります（スロット10には10枚）。値の大きいスロットに設定されたアイテムは引きやすいですが、手札に重なりやすいためバースト（寝落ち）の危険性が高くなります。\n\n"
	rules_text += "[font_size=18][b]3. 得点計算とコンボボーナス[/b][/font_size]\n"
	rules_text += "・[b]基礎点[/b]: 手札のカードの値（およびシャーペン等の加算・青ペン等の倍率効果）の合計。\n"
	rules_text += "・[b]教科コンボ[/b]: 同じ教科のカードを連続して引くと、コンボ加算が発生します。\n"
	rules_text += "  [color=d500f9]2連続: +3点 / 3連続: +7点 / 4連続: +12点 / 5連続以上: 12 + (連続数-4)*5 点[/color]\n"
	rules_text += "・[b]5教科ボーナス[/b]: 手札に5教科（国・英・数・理・社）すべてが揃うと、基礎点の [b]22%[/b] がボーナス加算（[b]下限10点〜上限28点[/b]）。\n\n"
	rules_text += "[font_size=18][b]4. チキスタ投稿と『嘘（ブラフ）』[/b][/font_size]\n"
	rules_text += "一日の終わりに、今日の獲得実点の合計を勉強SNS『チキスタ』に投稿します。\n"
	rules_text += "・実点より高い点数を申告してライバルを焦らせる（ブラフをかける）ことができます（基本上限 [b]+24点[/b]、アイテムで拡張可能）。\n\n"
	rules_text += "[font_size=18][b]5. ダウト投票と嘘の露見[/b][/font_size]\n"
	rules_text += "ライバルのドロー数や使用アイテムの履歴を確認し、嘘を見破って「ダウト」を仕掛けます。ダウトは毎日最大3回まで行えます。\n"
	rules_text += "・[b]自動露見確率[/b]: 誰もダウトしなくても、盛り幅が大きいと一日の終わりに自動で嘘がバレます。（確率: [color=ff9100](盛り幅/40)^2[/color]）\n"
	rules_text += "・[b]嘘バレペナルティ[/b]: 嘘がバレた際、申告点は実点まで減算され、さらに「盛り幅（解答写し使用時はその2倍）」の点数がペナルティとして最終得点から減算されます。\n"
	rules_text += "・[b]ダウト成功ボーナス[/b]: 相手の盛り幅 + 6点（勉強会チャット使用時はさらに+6点）を獲得。\n"
	rules_text += "・[b]ダウト失敗ペナルティ[/b]: 正直な人に誤ってダウトすると減点（日程経過で [b]10点〜18点[/b]）。座布団で半減、耳栓で-10点軽減。\n\n"
	rules_text += "[font_size=18][b]6. タイブレーク[/b][/font_size]\n"
	rules_text += "最終得点が同点の場合、5日間でバースト（寝落ち）した回数がより少ないプレイヤーが勝者となります。\n"
	rtb.text = rules_text
	scroll.add_child(rtb)
	
	close_btn.pressed.connect(func():
		animate_click(close_btn, Vector2.ONE, 0.08)
		var out_tween = parent_node.create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			canvas.queue_free()
		)
	)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	var tween = parent_node.create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)

static func show_settings(parent_node: Node) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = CanvasLayer.new()
	canvas.layer = 101
	parent_node.add_child(canvas)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.4)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(500, 480)
	modal.pivot_offset = Vector2(250, 240)
	modal.add_theme_stylebox_override("panel", create_craft_panel())
	canvas.add_child(modal)
	modal.position = Vector2((1920 - 500) / 2.0, (1080 - 480) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "⚙️ オプション設定"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", COLOR_INK)
	vbox.add_child(title)
	
	var audio = parent_node.get_node("/root/AudioManager")
	
	# BGM Volume
	var bgm_vbox = VBoxContainer.new()
	bgm_vbox.add_theme_constant_override("separation", 5)
	vbox.add_child(bgm_vbox)
	
	var bgm_label = Label.new()
	bgm_label.text = "BGM 音量: %d%%" % int(audio.bgm_volume * 100)
	bgm_label.add_theme_font_override("font", load(FONT_HANDWRITING))
	bgm_label.add_theme_font_size_override("font_size", 16)
	bgm_label.add_theme_color_override("font_color", COLOR_INK)
	bgm_vbox.add_child(bgm_label)
	
	var bgm_slider = HSlider.new()
	bgm_slider.min_value = 0.0
	bgm_slider.max_value = 1.0
	bgm_slider.step = 0.05
	bgm_slider.value = audio.bgm_volume
	bgm_vbox.add_child(bgm_slider)
	bgm_slider.value_changed.connect(func(val):
		audio.bgm_volume = val
		bgm_label.text = "BGM 音量: %d%%" % int(val * 100)
	)
	
	# SE Volume
	var se_vbox = VBoxContainer.new()
	se_vbox.add_theme_constant_override("separation", 5)
	vbox.add_child(se_vbox)
	
	var se_label = Label.new()
	se_label.text = "SE 音量: %d%%" % int(audio.se_volume * 100)
	se_label.add_theme_font_override("font", load(FONT_HANDWRITING))
	se_label.add_theme_font_size_override("font_size", 16)
	se_label.add_theme_color_override("font_color", COLOR_INK)
	se_vbox.add_child(se_label)
	
	var se_slider = HSlider.new()
	se_slider.min_value = 0.0
	se_slider.max_value = 1.0
	se_slider.step = 0.05
	se_slider.value = audio.se_volume
	se_vbox.add_child(se_slider)
	se_slider.value_changed.connect(func(val):
		audio.se_volume = val
		se_label.text = "SE 音量: %d%%" % int(val * 100)
	)
	
	# Mute Checkbox HBox
	var mute_hbox = HBoxContainer.new()
	mute_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(mute_hbox)
	
	var mute_label = Label.new()
	mute_label.text = "すべての音声をミュートする: "
	mute_label.add_theme_font_override("font", load(FONT_HANDWRITING))
	mute_label.add_theme_font_size_override("font_size", 16)
	mute_label.add_theme_color_override("font_color", COLOR_INK)
	mute_hbox.add_child(mute_label)
	
	var mute_check = CheckButton.new()
	mute_check.button_pressed = audio.is_muted
	mute_check.toggled.connect(func(pressed):
		audio.is_muted = pressed
	)
	mute_hbox.add_child(mute_check)
	
	# Rules button inside Settings
	var rule_btn = Button.new()
	rule_btn.text = "📖 ルールブックを閲覧"
	rule_btn.custom_minimum_size = Vector2(300, 45)
	rule_btn.add_theme_font_override("font", load(FONT_HANDWRITING))
	rule_btn.add_theme_font_size_override("font_size", 16)
	rule_btn.pressed.connect(func():
		animate_click(rule_btn, Vector2.ONE, 0.08)
		show_rulebook(parent_node)
	)
	vbox.add_child(rule_btn)
	
	# Bottom Buttons HBox
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(bottom_hbox)
	
	# Check if we are in game (not on the Title screen)
	var is_in_game = false
	if parent_node and parent_node.get_tree() and parent_node.get_tree().current_scene:
		if not (parent_node.get_tree().current_scene is TitleScene):
			is_in_game = true
			
	if is_in_game:
		var return_btn = Button.new()
		return_btn.text = "🚪 タイトルへ戻る"
		return_btn.custom_minimum_size = Vector2(200, 45)
		return_btn.add_theme_font_override("font", load(FONT_HANDWRITING))
		return_btn.add_theme_font_size_override("font_size", 18)
		return_btn.pressed.connect(func():
			animate_click(return_btn, Vector2.ONE, 0.08)
			show_confirm_dialog(parent_node, "本当にタイトルへ戻りますか？\n（進行状況は破棄されます）", func():
				# Close settings and change scene
				if canvas and canvas.is_inside_tree():
					canvas.queue_free()
				if parent_node.get_tree().root.has_node("Global"):
					parent_node.get_tree().root.get_node("Global").change_scene_with_fade(parent_node.get_tree(), "res://Title.tscn")
			)
		)
		bottom_hbox.add_child(return_btn)
	
	# Close Button
	var close_btn = Button.new()
	close_btn.text = " ✖ 閉じる "
	close_btn.custom_minimum_size = Vector2(200, 45)
	close_btn.add_theme_font_override("font", load(FONT_HANDWRITING))
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func():
		animate_click(close_btn, Vector2.ONE, 0.08)
		var out_tween = parent_node.create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			canvas.queue_free()
		)
	)
	bottom_hbox.add_child(close_btn)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	var tween = parent_node.create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)

static func show_confirm_dialog(parent_node: Node, text: String, on_confirm: Callable) -> void:
	if not parent_node or not parent_node.is_inside_tree():
		return
		
	var canvas = CanvasLayer.new()
	canvas.layer = 105 # Higher than settings
	parent_node.add_child(canvas)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.5)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg_overlay)
	
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(400, 200)
	modal.pivot_offset = Vector2(200, 100)
	modal.add_theme_stylebox_override("panel", create_craft_panel())
	canvas.add_child(modal)
	modal.position = Vector2((1920 - 400) / 2.0, (1080 - 200) / 2.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 20)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load(FONT_HANDWRITING))
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", COLOR_INK)
	vbox.add_child(label)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_hbox)
	
	var yes_btn = Button.new()
	yes_btn.text = "はい"
	yes_btn.custom_minimum_size = Vector2(120, 45)
	yes_btn.add_theme_font_override("font", load(FONT_HANDWRITING))
	yes_btn.add_theme_font_size_override("font_size", 18)
	yes_btn.add_theme_color_override("font_color", Color("d32f2f")) # Red text for destructive action
	btn_hbox.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "いいえ"
	no_btn.custom_minimum_size = Vector2(120, 45)
	no_btn.add_theme_font_override("font", load(FONT_HANDWRITING))
	no_btn.add_theme_font_size_override("font_size", 18)
	btn_hbox.add_child(no_btn)
	
	yes_btn.pressed.connect(func():
		animate_click(yes_btn, Vector2.ONE, 0.08)
		var out_tween = parent_node.create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			canvas.queue_free()
			if on_confirm.is_valid():
				on_confirm.call()
		)
	)
	
	no_btn.pressed.connect(func():
		animate_click(no_btn, Vector2.ONE, 0.08)
		var out_tween = parent_node.create_tween().bind_node(modal).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out_tween.tween_property(modal, "scale", Vector2.ZERO, 0.2)
		out_tween.tween_callback(func():
			canvas.queue_free()
		)
	)
	
	# Entrance Animation
	modal.scale = Vector2.ZERO
	var anim_tween = parent_node.create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(modal, "scale", Vector2.ONE, 0.3)

