extends Control

# Preload Phase Scripts
const BagBuilderPhaseClass = preload("res://src/ui/phases/BagBuilderPhase.gd")
const ChickenRacePhaseClass = preload("res://src/ui/phases/ChickenRacePhase.gd")
const ReportPhaseClass = preload("res://src/ui/phases/ReportPhase.gd")
const DailyLikesPhaseClass = preload("res://src/ui/phases/DailyLikesPhase.gd")
const DayTransitionPhaseClass = preload("res://src/ui/phases/DayTransitionPhase.gd")
const WaitingPhaseClass = preload("res://src/ui/phases/WaitingPhase.gd")



var session: GameSession
var active_phase_node: PhaseBase

# Desk background
var bg_color_rect: ColorRect
var bg_texture: TextureRect
var phase_layer: Control

func _ready() -> void:
	# Add Desk background mahogany wood tone
	bg_color_rect = ColorRect.new()
	bg_color_rect.color = DeskTheme.COLOR_MAHOGANY
	bg_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color_rect)
	
	# Load background texture if exists
	bg_texture = TextureRect.new()
	bg_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/机の背景画像-ノート無し.png"):
		bg_texture.texture = load("res://assets/机の背景画像-ノート無し.png")
	elif ResourceLoader.exists("res://assets/机の背景画像.png"):
		bg_texture.texture = load("res://assets/机の背景画像.png")
	bg_texture.modulate = Color.WHITE
	add_child(bg_texture)
	
	# Phase layer fills the screen; individual phases manage their own internal layout.
	phase_layer = Control.new()
	phase_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(phase_layer)
	
	session = GameSession.new()
	session.start_session(Global.current_deck)
	
	# Start loop with BagBuilderPhase
	change_phase(Constants.PHASE_BAG_BUILDER)

func change_phase(phase_type: String, setup_data: Dictionary = {}) -> void:
	var old_node = active_phase_node
	active_phase_node = null
	
	# Instantiate correct class
	match phase_type:
		Constants.PHASE_BAG_BUILDER:
			active_phase_node = BagBuilderPhaseClass.new()
		Constants.PHASE_CHICKEN_RACE:
			active_phase_node = ChickenRacePhaseClass.new()
		Constants.PHASE_REPORT:
			active_phase_node = ReportPhaseClass.new()
		Constants.PHASE_DAILY_LIKES:
			active_phase_node = DailyLikesPhaseClass.new()
		Constants.PHASE_DAY_TRANSITION:
			active_phase_node = DayTransitionPhaseClass.new()
		Constants.PHASE_WAITING:
			active_phase_node = WaitingPhaseClass.new()
			
	if active_phase_node:
		active_phase_node.phase_finished.connect(_on_phase_finished.bind(phase_type))
		phase_layer.add_child(active_phase_node)
		active_phase_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Initialize
		active_phase_node.setup(session, setup_data)
		
		# Use a softer paper-like transition for bag building / chicken race swaps.
		if old_node and old_node.is_inside_tree():
			if (old_node is BagBuilderPhaseClass and active_phase_node is ChickenRacePhaseClass):
				DeskTheme.animate_soft_phase_transition(old_node, active_phase_node, 0.42, false)
			elif (old_node is ChickenRacePhaseClass and active_phase_node is BagBuilderPhaseClass):
				DeskTheme.animate_soft_phase_transition(old_node, active_phase_node, 0.42, true)
			else:
				DeskTheme.animate_page_flip(old_node, active_phase_node, 0.45)
		else:
			DeskTheme.animate_page_flip(old_node, active_phase_node, 0.45)

func _on_phase_finished(result_data: Dictionary, phase_type: String) -> void:
	# 動的な状態遷移指定（ステートマシン化）
	if result_data.has("next_phase") and result_data["next_phase"] != "":
		var next_p = result_data["next_phase"]
		# result_data自体をセットアップデータとして次のフェーズに持ち越す
		change_phase(next_p, result_data)
		return
		
	match phase_type:
		Constants.PHASE_BAG_BUILDER:
			change_phase(Constants.PHASE_CHICKEN_RACE)
		Constants.PHASE_CHICKEN_RACE:
			if session.player_hours_history_today.size() >= session.max_hours_today:
				change_phase(Constants.PHASE_REPORT, {"actual_score": result_data.get("actual_score", 0)})
			else:
				session.current_hour += 1
				change_phase(Constants.PHASE_BAG_BUILDER)
		Constants.PHASE_REPORT:
			if Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
				# Upload mid-day moves (scores, actual, hours) to server before waiting
				var bm = null
				var main_loop = Engine.get_main_loop()
				if main_loop is SceneTree:
					bm = main_loop.root.get_node_or_null("BackendManager")
				if bm:
					var mid_move = {
						"actual_score": session.player_actual_score_today,
						"declared_score": session.player_declared_score_today,
						"hours_history": session.player_hours_history_today.duplicate(),
						"doubts_made": [],
						"doubts_submitted": false
					}
					bm.upload_friend_move(Global.friend_room_code, session.current_day, mid_move)
				change_phase(Constants.PHASE_WAITING, {"day": session.current_day, "final_wait": false})
			else:
				change_phase(Constants.PHASE_DAILY_LIKES)
				
		Constants.PHASE_DAILY_LIKES:
			# Day ends. Compute AIs and compile doubts.
			session.end_day()
			
			if Global.game_mode == Constants.MODE_DAILY:
				Global.daily_current_day = session.current_day
				Global.save_game()
				
				if session.current_day > 5:
					# Match complete! Show results and reset daily exam progression state
					Global.daily_current_day = 1
					Global.daily_my_records.clear()
					Global.daily_opponent_ghosts.clear()
					Global.save_game()
					
					Global.active_showdown_results = session.calculate_final_showdown()
					Global.change_scene_with_fade(get_tree(), "res://ResultScene.tscn")
				else:
					show_daily_finished_modal()
			elif Global.game_mode in [Constants.MODE_FRIEND, Constants.MODE_RANDOM]:
				# In friend match, current_day was advanced in end_day() (e.g. from 5 to 6)
				if session.current_day > 5:
					# Day 5 doubts submitted. Now wait for everyone to finish Day 5 doubts before final reveal
					change_phase(Constants.PHASE_WAITING, {"day": 5, "final_wait": true})
				else:
					# For Day 1-4, we can advance immediately without waiting for other's doubts
					change_phase(Constants.PHASE_DAY_TRANSITION)
			else:
				# Check if 5-day cycle is complete (for normal CPU game)
				if session.current_day > 5:
					# Store showdown results globally to persist across scene change
					Global.active_showdown_results = session.calculate_final_showdown()
					# Route to Result Scene
					Global.change_scene_with_fade(get_tree(), "res://ResultScene.tscn")
				else:
					change_phase(Constants.PHASE_DAY_TRANSITION)
					
		Constants.PHASE_WAITING:
			var moves = result_data.get("moves", [])
			var prev_moves = result_data.get("prev_moves", [])
			var is_final = result_data.get("final_wait", false)
			
			if is_final or (session.current_day > 5 and moves.size() > 0): # Day 5 results wait complete
				# Process Day 5 doubts resolution
				session.evaluate_friend_day_moves(5, moves)
				
				# Store showdown results globally to persist across scene change
				Global.active_showdown_results = session.calculate_final_showdown()
				# Route to Result Scene
				Global.change_scene_with_fade(get_tree(), "res://ResultScene.tscn")
			else:
				# Day X (X <= 5) chicken race complete wait.
				# Evaluate previous day's doubts if target day > 1
				var target_day = result_data.get("day", session.current_day)
				if target_day > 1 and prev_moves.size() > 0:
					session.evaluate_friend_day_moves(target_day - 1, prev_moves)
					
				# Also populate today's moves into current day session match history
				# so that DailyLikesPhase can render their timeline posts
				session.evaluate_friend_day_moves(target_day, moves)
				
				# Proceed to DailyLikesPhase (timeline and doubt choosing)
				change_phase(Constants.PHASE_DAILY_LIKES)

		Constants.PHASE_DAY_TRANSITION:
			change_phase(Constants.PHASE_BAG_BUILDER)

func show_daily_finished_modal() -> void:
	var modal = PanelContainer.new()
	modal.custom_minimum_size = Vector2(600, 300)
	modal.size = Vector2(600, 300)
	modal.pivot_offset = Vector2(300, 150)
	
	var style = StyleBoxFlat.new()
	style.bg_color = DeskTheme.COLOR_CRAFT
	style.border_color = DeskTheme.COLOR_INK
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 15
	style.shadow_offset = Vector2(6, 6)
	modal.add_theme_stylebox_override("panel", style)
	
	add_child(modal)
	var viewport_size = get_viewport_rect().size
	modal.position = viewport_size * 0.5 - modal.pivot_offset
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "今日の自習完了！ 🎉"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", DeskTheme.COLOR_INK)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "本日のデイリー試験の成績はチキスタに投稿されました。\n明日になると次の日（Day %d）に進むことができます！" % Global.daily_current_day
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(DeskTheme.COLOR_INK, 0.8))
	vbox.add_child(desc)
	
	var ok_btn = Button.new()
	ok_btn.text = "タイトルへ戻る"
	ok_btn.custom_minimum_size = Vector2(180, 45)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_btn.add_theme_font_override("font", load(DeskTheme.FONT_HANDWRITING))
	ok_btn.add_theme_font_size_override("font_size", 18)
	vbox.add_child(ok_btn)
	
	ok_btn.pressed.connect(func():
		DeskTheme.animate_click(ok_btn, Vector2.ONE, 0.08)
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func():
			modal.queue_free()
			Global.change_scene_with_fade(get_tree(), "res://Title.tscn")
		)
	)
	
	modal.scale = Vector2.ZERO
	var tween = create_tween().bind_node(modal).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.3)
