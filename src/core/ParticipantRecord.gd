class_name ParticipantRecord
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var actual_score: int = 0
@export var declared_score: int = 0
@export var hours: Array = []
@export var doubts_made: Array = []
@export var doubts_received: Array = []
@export var is_doubt_exposed: bool = false
@export var auto_exposed: bool = false
@export var emote: String = "normal"

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"actual_score": actual_score,
		"declared_score": declared_score,
		"hours": hours,
		"doubts_made": doubts_made,
		"doubts_received": doubts_received,
		"is_doubt_exposed": is_doubt_exposed,
		"auto_exposed": auto_exposed,
		"emote": emote
	}

static func from_dict(dict: Dictionary, p_id: String = "") -> ParticipantRecord:
	var rec = ParticipantRecord.new()
	rec.id = str(dict.get("id", p_id))
	rec.name = str(dict.get("name", dict.get("username", "")))
	rec.actual_score = int(dict.get("actual_score", 0))
	rec.declared_score = int(dict.get("declared_score", 0))
	
	rec.hours.clear()
	var raw_hours = dict.get("hours", dict.get("hours_history", []))
	if raw_hours is Array:
		for h in raw_hours:
			if h is Dictionary:
				rec.hours.append(h)
			
	rec.doubts_made.clear()
	var raw_doubts_made = dict.get("doubts_made", [])
	if raw_doubts_made is Array:
		for dm in raw_doubts_made:
			rec.doubts_made.append(str(dm))
		
	rec.doubts_received.clear()
	var raw_doubts_received = dict.get("doubts_received", [])
	if raw_doubts_received is Array:
		for dr in raw_doubts_received:
			rec.doubts_received.append(str(dr))
		
	rec.is_doubt_exposed = bool(dict.get("is_doubt_exposed", false))
	rec.auto_exposed = bool(dict.get("auto_exposed", false))
	rec.emote = str(dict.get("emote", "normal"))
	return rec
