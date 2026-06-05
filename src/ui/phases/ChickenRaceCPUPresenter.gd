class_name ChickenRaceCPUPresenter
extends RefCounted

var phase: ChickenRacePhase

func _init(p_phase: ChickenRacePhase) -> void:
	phase = p_phase

func init_cpu_simulation_states() -> void:
	phase.cpu_sim_states.clear()
	var day_idx = phase.session.current_day
	var hour_idx = phase.session.current_hour
	var day_data = phase.session.match_history.get(day_idx, {})
	
	for opp_id in Global.opponent_profiles.keys():
		var max_draws = 0
		var bursted = false
		if day_data.has(opp_id):
			var opp_records = day_data[opp_id].get("hours", [])
			if opp_records.size() >= hour_idx:
				var hour_rec = opp_records[hour_idx - 1]
				max_draws = hour_rec.get("draws", 0)
				bursted = hour_rec.get("bursted", false)
				
		phase.cpu_sim_states[opp_id] = {
			"current_draws": 0,
			"max_draws": max_draws,
			"bursted": bursted,
			"status": "studying"
		}
		_update_member_badge_ui(opp_id)

func advance_cpu_simulations() -> void:
	for opp_id in phase.cpu_sim_states.keys():
		var state = phase.cpu_sim_states[opp_id]
		if state["status"] != "studying":
			continue
			
		if state["current_draws"] < state["max_draws"]:
			state["current_draws"] += 1
			if state["current_draws"] == state["max_draws"]:
				if state["bursted"]:
					state["status"] = "bursted"
				else:
					state["status"] = "stopped"
		else:
			if state["bursted"]:
				state["status"] = "bursted"
			else:
				state["status"] = "stopped"
				
		_update_member_badge_ui(opp_id)

func fast_forward_cpus_to_end() -> void:
	for opp_id in phase.cpu_sim_states.keys():
		var state = phase.cpu_sim_states[opp_id]
		while state["status"] == "studying":
			state["current_draws"] += 1
			if state["current_draws"] >= state["max_draws"]:
				if state["bursted"]:
					state["status"] = "bursted"
				else:
					state["status"] = "stopped"
			_update_member_badge_ui(opp_id)

func _update_member_badge_ui(member_id: String) -> void:
	if not phase.member_labels.has(member_id):
		return
	var label = phase.member_labels[member_id]
	var display_name = ""
	var icon = ""
	
	if member_id == "player":
		display_name = Global.player_name if Global.player_name != "" else "あなた"
		icon = "[自分]"
		var hand_size = phase.current_hand_cards.size()
		if phase.has_bursted:
			label.text = icon + " " + display_name + "\n[寝落ち]！"
			var style = phase.member_panels["player"].get_theme_stylebox("panel") as StyleBoxFlat
			if style:
				style.bg_color = Color("ffcdd2")
		else:
			label.text = icon + " " + display_name + "\n勉強: " + str(hand_size) + "枚"
	else:
		if Global.opponent_profiles.has(member_id):
			display_name = Global.opponent_profiles[member_id].get("name", "ライバル")
		icon = "[他]"
		
		var state = phase.cpu_sim_states[member_id]
		var style = phase.member_panels[member_id].get_theme_stylebox("panel") as StyleBoxFlat
		
		if state["status"] == "studying":
			label.text = icon + " " + display_name + "\n勉強: " + str(state["current_draws"]) + "枚"
		elif state["status"] == "stopped":
			label.text = icon + " " + display_name + "\n休憩"
			if style:
				style.bg_color = Color("c8e6c9")
		elif state["status"] == "bursted":
			label.text = icon + " " + display_name + "\n休憩"
			if style:
				style.bg_color = Color("c8e6c9")
