class_name TitleLogo
extends VBoxContainer

var text1_container: Control
var highlighter_line: ColorRect
var label_test_study: Label
var label_chicken_race: Label

var wobble_timer: Timer

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", -5)
	
	# PIVOTを設定
	custom_minimum_size = Vector2(500, 220)
	pivot_offset = custom_minimum_size / 2.0
	
	# --- 1段目「テスト勉強」コンテナ ---
	text1_container = Control.new()
	text1_container.custom_minimum_size = Vector2(500, 80)
	text1_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	text1_container.pivot_offset = text1_container.custom_minimum_size / 2.0
	add_child(text1_container)
	
	# 蛍光イエローマーカーライン (背後)
	highlighter_line = ColorRect.new()
	highlighter_line.color = DeskTheme.COLOR_HIGHLIGHTER
	highlighter_line.custom_minimum_size = Vector2(420, 36)
	highlighter_line.size = Vector2(420, 36)
	highlighter_line.position = Vector2(40, 30)
	highlighter_line.pivot_offset = Vector2(0, 18)
	highlighter_line.scale.x = 0.0
	text1_container.add_child(highlighter_line)
	
	# 「テスト勉強」テキスト
	label_test_study = Label.new()
	label_test_study.text = "テスト勉強"
	label_test_study.add_theme_font_override("font", DeskTheme.get_font())
	label_test_study.add_theme_font_size_override("font_size", 54)
	label_test_study.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	label_test_study.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label_test_study.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_test_study.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_test_study.pivot_offset = Vector2(250, 40)
	text1_container.add_child(label_test_study)
	
	# --- 2段目「チキンレース」テキスト ---
	label_chicken_race = Label.new()
	label_chicken_race.text = "チキンレース"
	label_chicken_race.add_theme_font_override("font", DeskTheme.get_font())
	label_chicken_race.add_theme_font_size_override("font_size", 72)
	label_chicken_race.add_theme_color_override("font_color", DeskTheme.COLOR_TENSION)
	label_chicken_race.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_chicken_race.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_chicken_race.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label_chicken_race.custom_minimum_size = Vector2(500, 100)
	label_chicken_race.pivot_offset = Vector2(250, 50)
	add_child(label_chicken_race)
	
	# アニメーション開始
	_start_animations()

func _start_animations() -> void:
	# 1. マーカーラインの起動演出 (0.3秒遅延で scale.x: 0 -> 1)
	var highlighter_tween = create_tween().bind_node(self).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	highlighter_tween.tween_interval(0.3)
	highlighter_tween.tween_property(highlighter_line, "scale:x", 1.0, 0.4)
	
	# 2. 緩やかな心拍パルスアニメーション
	# (親が設定したscaleを壊さないよう、中身の各テキストコントロールを個別にTweenする)
	var pulse_tween = create_tween().bind_node(self).set_loops()
	pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 1.0 -> 1.03 (2.2秒周期でゆったりと)
	pulse_tween.tween_property(label_test_study, "scale", Vector2(1.03, 1.03), 0.25)
	pulse_tween.parallel().tween_property(label_chicken_race, "scale", Vector2(1.03, 1.03), 0.25)
	
	# 1.03 -> 1.0
	pulse_tween.tween_property(label_test_study, "scale", Vector2(1.0, 1.0), 0.35)
	pulse_tween.parallel().tween_property(label_chicken_race, "scale", Vector2(1.0, 1.0), 0.35)
	
	pulse_tween.tween_interval(1.6) # 合計 2.2秒のインターバル
	
	# 3. 緩やかな手書きゆらゆら (0.4秒間隔に遅くし、揺れ幅を抑える)
	wobble_timer = Timer.new()
	wobble_timer.wait_time = 0.4
	wobble_timer.autostart = true
	wobble_timer.timeout.connect(_on_wobble_timeout)
	add_child(wobble_timer)

func _on_wobble_timeout() -> void:
	# 回転角度を小さく (+-0.4度)
	label_test_study.rotation_degrees = randf_range(-0.4, 0.4)
	label_chicken_race.rotation_degrees = randf_range(-0.4, 0.4)
