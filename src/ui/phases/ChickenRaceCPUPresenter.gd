class_name ChickenRaceCPUPresenter
extends RefCounted

var phase: ChickenRacePhase
var cpu_sim_states: Dictionary = {}

func _init(p_phase: ChickenRacePhase) -> void:
	phase = p_phase

func init_cpu_simulation_states() -> void:
	cpu_sim_states.clear()
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
				
		cpu_sim_states[opp_id] = {
			"current_draws": 0,
			"max_draws": max_draws,
			"bursted": bursted,
			"status": "studying"
		}

func advance_cpu_simulations() -> void:
	for opp_id in cpu_sim_states.keys():
		var state = cpu_sim_states[opp_id]
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

func fast_forward_cpus_to_end() -> void:
	for opp_id in cpu_sim_states.keys():
		var state = cpu_sim_states[opp_id]
		while state["status"] == "studying":
			state["current_draws"] += 1
			if state["current_draws"] >= state["max_draws"]:
				if state["bursted"]:
					state["status"] = "bursted"
				else:
					state["status"] = "stopped"
