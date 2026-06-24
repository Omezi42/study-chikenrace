class_name DailyLikesPhase
extends PhaseBase

# UI Controls
var main_hbox: HBoxContainer
var phone_panel: PanelContainer
var timeline_list: VBoxContainer
var next_day_btn: Button
var remaining_doubts_label: Label
var scroll_container: ScrollContainer
var target_scroll_y: float = 0.0
var scroll_tween: Tween

# Detail Inspection Modal
var detail_modal: PanelContainer
var detail_title: Label
var detail_body: Label
var detail_scroll: ScrollContainer
var detail_log_vbox: VBoxContainer
var detail_ellipsis: Label
var close_detail_btn: Button

# Daily state
var participants_data: Array = []
var local_doubts_count: int = 3 # 3 doubt votes per day max
var active_timeline_tweens: Array[Tween] = []
var likes_skip_btn: Button
var tutorial_dialog_node: PanelContainer = null

var active_tweens: Array[Tween] = []
var restored_nodes: Dictionary = {}


func _on_setup(setup_data: Dictionary) -> void:
	custom_minimum_size = Vector2(1500, 850)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var max_doubts = 3
	local_doubts_count = max_doubts - session.player_doubts_made_today.size()
	
	if has_node("/root/BackendManager"):
		var bm = get_node_or_null("/root/BackendManager")
		if bm and not bm.connection_lost.is_connected(_on_connection_lost):
			bm.connection_lost.connect(_on_connection_lost)
	
	DailyLikesUIBuilder.build_layout(self, setup_data)

	
	# Fetch participants data
	collect_participants()
	populate_timeline()
	update_remaining_votes()
	
	# Entrance slide in
	var from_report = setup_data.get("from_report", false)
	if is_instance_valid(phone_panel) and not from_report:
		DeskTheme.animate_entrance(phone_panel, phone_panel.position, Vector2(0, 300), 0.5)
	DeskTheme.animate_entrance(self, self.position, Vector2(0, 300), 0.5)
	
	if Global.is_tutorial_mode and session.current_day == 1:
		next_day_btn.text = "テストを開始する"
		next_day_btn.disabled = true
		clear_highlights()
		var viewport_size = get_viewport_rect().size
		var dialog_pos = Vector2(viewport_size.x - 620, viewport_size.y - 220)
		tutorial_dialog_node = show_tutorial_dialog(
			"友達のドロー回数に対して点数が高すぎる場合は嘘の可能性があります。見破ればボーナスです。怪しい友達に『ダウト！』を押してみましょう。",
			dialog_pos
		)
		highlight_rival_doubt_buttons()

func collect_participants() -> void:
	if Global.is_tutorial_mode:
		var day = session.current_day
		if not session.match_history.has(day):
			session.match_history[day] = {}
		var sato_hours: Array[Dictionary] = [
			{"draws": 1, "used_items": [], "bursted": false, "score": 6, "reaction": "余裕"},
			{"draws": 1, "used_items": [], "bursted": false, "score": 4, "reaction": "順調"},
			{"draws": 0, "used_items": [], "bursted": false, "score": 0, "reaction": "休憩"}
		]
		session.match_history[day]["cpu_sato"] = {
			"id": "cpu_sato",
			"name": "佐藤くん",
			"username": "佐藤くん",
			"declared_score": 18,
			"actual_score": 10,
			"hours": sato_hours,
			"emote": "wink"
		}
		
	participants_data.clear()
	var day_data = session.match_history[session.current_day]
	
	# Collect player
	var player_name_val = Global.player_name if Global.player_name != "" else "あなた"
	participants_data.append({
		"id": "player",
		"name": player_name_val,
		"declared_score": session.player_declared_score_today,
		"actual_score": session.player_actual_score_today,
		"hours": session.player_hours_history_today,
		"avatar_color": DeskTheme.COLOR_GREEN,
		"emote": session.player_emote_today
	})
	
	# Collect rivals (CPUs and other players)
	for opp_id in day_data.keys():
		if opp_id == "player":
			continue
			
		var opp = day_data[opp_id]
		var color_val = DeskTheme.COLOR_MAHOGANY
		var opp_name = opp.get("name", opp.get("username", "ライバル"))
		
		# Determine avatar color if it is a registered CPU
		var actual_profile_id = opp_id
		if Global.opponent_profiles.has(opp_id):
			actual_profile_id = Global.opponent_profiles[opp_id].get("id", opp_id)
			
		if actual_profile_id.begins_with("cpu_"):
			var cpu_meta = AIManager.get_cpu_info(actual_profile_id)
			if cpu_meta.get("type", "") == AIManager.TYPE_BLUFFER:
				color_val = DeskTheme.COLOR_TENSION
			elif cpu_meta.get("type", "") == AIManager.TYPE_CAUTIOUS:
				color_val = DeskTheme.COLOR_ROLE_PREP
		else:
			# For actual human friends, use blue Pen color as a distinct avatar color
			color_val = Color("2979ff") 
			
		participants_data.append({
			"id": opp_id,
			"name": opp_name,
			"declared_score": int(opp.get("declared_score", 0)),
			"actual_score": int(opp.get("actual_score", 0)),
			"hours": opp.get("hours", opp.get("hours_history", [])),
			"avatar_color": color_val,
			"emote": opp.get("emote", "normal")
		})
		
	# Sort participants by declared score descending for timeline rank
	participants_data.sort_custom(func(a, b): return a["declared_score"] > b["declared_score"])

func populate_timeline() -> void:
	for child in timeline_list.get_children():
		child.queue_free()
		
	active_timeline_tweens.clear()
	if likes_skip_btn:
		likes_skip_btn.visible = participants_data.size() > 0
		
	for idx in range(participants_data.size()):
		var p = participants_data[idx]
		
		var card = DailyLikesUIBuilder.build_timeline_card(self, p, idx)
		timeline_list.add_child(card)
		
		var tween = card.create_tween().set_parallel(true)
		active_timeline_tweens.append(tween)
		var delay = idx * 0.12
		
		tween.tween_property(card, "custom_minimum_size:y", 185.0, 0.35)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay)
			
		tween.tween_property(card, "modulate:a", 1.0, 0.28)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay)
			
		if idx == participants_data.size() - 1:
			tween.chain().tween_callback(func():
				if is_instance_valid(likes_skip_btn):
					likes_skip_btn.visible = false
			)

func update_remaining_votes() -> void:
	pass

func _on_inspect_pressed(p: Dictionary) -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
		
	DailyLikesUIBuilder.populate_inspect_modal(self, p)
	
	# Update ellipsis visibility after layout pass
	await get_tree().process_frame
	_update_ellipsis_visibility()

	if Global.is_tutorial_mode and session.current_day == 1:
		clear_highlights()
		var detail_btn = detail_modal.find_child("DetailDoubtButton", true, false)
		if detail_btn and not detail_btn.disabled:
			highlight(detail_btn)
		
		var viewport_size = get_viewport_rect().size
		var dialog_pos = Vector2(viewport_size.x - 620, viewport_size.y - 220)
		tutorial_dialog_node = show_tutorial_dialog(
			"詳細ログから友達の行動履歴を確認できます。点数に対してドロー回数が少なすぎますね。詳細パネルの『ダウト！』を押してみましょう。",
			dialog_pos
		)

func _update_ellipsis_visibility() -> void:
	if not is_instance_valid(detail_scroll) or not is_instance_valid(detail_ellipsis):
		return
	var v_scroll = detail_scroll.get_v_scroll_bar()
	if v_scroll and v_scroll.visible:
		# Check if we can scroll down further
		var max_scroll = v_scroll.max_value - v_scroll.page
		if v_scroll.value < max_scroll - 2: # small tolerance
			detail_ellipsis.visible = true
			return
	detail_ellipsis.visible = false

func _get_target_deck(p_id: String) -> Dictionary:
	if Global.opponent_profiles.has(p_id):
		var opp_id = Global.opponent_profiles[p_id].get("id", p_id)
		if AIManager.CPU_OPPONENTS.has(opp_id):
			return AIManager.CPU_OPPONENTS[opp_id].get("deck", {})
	if AIManager.CPU_OPPONENTS.has(p_id):
		return AIManager.CPU_OPPONENTS[p_id].get("deck", {})
	return {}

func _on_doubt_pressed(target_id: String, card_node: Control, btn: Button) -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
		
	if local_doubts_count <= 0:
		return
		
	# Confirm doubt
	session.add_player_doubt(target_id)
	local_doubts_count -= 1
	update_remaining_votes()
	
	# Instant doubt outcome validation
	var is_bluff = false
	var opp_name = "ライバル"
	var declared_score = 0
	var actual_score = 0
	
	var day_data = session.match_history.get(session.current_day, {})
	if day_data.has(target_id):
		var opp = day_data[target_id]
		opp_name = opp.get("name", opp.get("username", "ライバル"))
		declared_score = int(opp.get("declared_score", 0))
		actual_score = int(opp.get("actual_score", 0))
		is_bluff = declared_score != actual_score
		
	# 得失点および内訳の算出
	var my_score_change = 0
	var opp_score_change = 0
	var my_details = ""
	var opp_details = ""
	
	if is_bluff:
		# 成功時：自分にボーナス、相手に減点
		var bluff = declared_score - actual_score
		var adjusted_bluff = int(round(bluff * 0.75))
		my_score_change = adjusted_bluff + 6
		
		my_details = "・基本ボーナス: +6 点\n・嘘暴きボーナス: +%d 点 (差分の75%%)" % [adjusted_bluff]
		
		var penalty = declared_score - actual_score
		
		opp_score_change = -penalty
		opp_details = "・嘘つきペナルティ: -%d 点" % penalty
			
		btn.text = "ダウト成功！"
		btn.add_theme_color_override("font_disabled_color", DeskTheme.COLOR_GREEN)
		Global.total_doubt_successes += 1
	else:
		# 失敗時：自分に減点、相手はノーダメージ
		var penalty_base: int = BalanceConfig.get_value("exposure.fail_penalty_base", 15)
		var penalty_per_day: int = BalanceConfig.get_value("exposure.fail_penalty_per_day", 3)
		var base_fail_penalty = penalty_base + (session.current_day - 1) * penalty_per_day
		
		var penalty = base_fail_penalty
		my_details = "・お手つきペナルティ: -%d 点" % base_fail_penalty
			
		my_score_change = -penalty
		opp_score_change = 0
		opp_details = "・正直に勉強していました。\n・ペナルティはありません。"
		
		btn.text = "ダウト失敗..."
		btn.add_theme_color_override("font_disabled_color", DeskTheme.COLOR_TENSION)
		Global.total_doubt_failures += 1
		
	Global.save_game()
	btn.disabled = true
	
	# Shake card & phone
	DeskTheme.shake_control(card_node, 10.0, 0.4)
	DeskTheme.shake_control(phone_panel, 8.0, 0.35)
	
	# リッチな結果表示モーダルの呼び出し
	DailyLikesUIBuilder.show_doubt_result_modal(
		self,
		opp_name, 
		is_bluff, 
		declared_score, 
		actual_score, 
		my_score_change, 
		opp_score_change, 
		my_details, 
		opp_details
	)

func _on_doubt_modal_closed() -> void:
	if Global.is_tutorial_mode and session.current_day == 1:
		clear_highlights()
		var viewport_size = get_viewport_rect().size
		var dialog_pos = Vector2(viewport_size.x - 620, viewport_size.y - 220)
		tutorial_dialog_node = show_tutorial_dialog(
			"基本ルールは以上です。本番のテスト（ゲーム）を開始して勝利を目指しましょう！",
			dialog_pos
		)
		if is_instance_valid(next_day_btn):
			next_day_btn.disabled = false
			highlight(next_day_btn)

func show_tutorial_finish_modal() -> void:
	DailyLikesUIBuilder.show_tutorial_finish_modal(self)

func _on_next_day_pressed() -> void:
	if tutorial_dialog_node:
		tutorial_dialog_node.queue_free()
		tutorial_dialog_node = null
		
	next_day_btn.disabled = true
	DeskTheme.animate_click(next_day_btn, Vector2.ONE, 0.08)
	
	var timer = get_tree().create_timer(0.25)
	timer.timeout.connect(func():
		if Global.is_tutorial_mode:
			show_tutorial_finish_modal()
		else:
			finish_phase({
				"doubts_made": session.player_doubts_made_today
			})
	)




func _on_connection_lost() -> void:
	if not is_inside_tree():
		return
	next_day_btn.disabled = true
	ConnectionErrorModal.create_and_show(self)

func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_scroll_y = max(target_scroll_y - 80, 0)
			_animate_scroll()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var max_scroll = max(0, timeline_list.size.y - scroll_container.size.y)
			target_scroll_y = min(target_scroll_y + 80, max_scroll)
			_animate_scroll()
			accept_event()

func _animate_scroll() -> void:
	if not is_instance_valid(scroll_container) or not is_inside_tree():
		return
	if is_instance_valid(scroll_tween):
		scroll_tween.kill()
	scroll_tween = create_tween()
	scroll_tween.tween_property(scroll_container, "scroll_vertical", int(target_scroll_y), 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func _exit_tree() -> void:
	if is_instance_valid(scroll_tween):
		scroll_tween.kill()
	clear_highlights()

func highlight(node: Control) -> void:
	if not node or not node.is_inside_tree():
		return
	if not restored_nodes.has(node):
		restored_nodes[node] = {
			"scale": node.scale,
			"modulate": node.modulate
		}
	var tween = DeskTheme.flash_highlight(node)
	if tween:
		active_tweens.append(tween)

func clear_highlights() -> void:
	for tween in active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()
	for node in restored_nodes.keys():
		if is_instance_valid(node):
			node.scale = restored_nodes[node]["scale"]
			node.modulate = restored_nodes[node]["modulate"]
	restored_nodes.clear()

func highlight_rival_doubt_buttons() -> void:
	var t = get_tree().create_timer(0.4)
	t.timeout.connect(func():
		for card in timeline_list.get_children():
			var btn = card.find_child("DoubtButton", true, false)
			if btn and not btn.disabled:
				highlight(btn)
	)
