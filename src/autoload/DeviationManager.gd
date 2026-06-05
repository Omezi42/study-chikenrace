extends Node

# プレイヤーの偏差値に応じたリーグ分類を取得
func get_deviation_league(dev_val: float) -> String:
	var val = dev_val
	if val >= 65.0:
		return Constants.LEAGUE_S
	elif val >= 58.0:
		return Constants.LEAGUE_A
	elif val >= 50.0:
		return Constants.LEAGUE_B
	elif val >= 42.0:
		return Constants.LEAGUE_C
	else:
		return Constants.LEAGUE_F

# 所属リーグの日本語表示名を取得
func get_deviation_league_name(league: String) -> String:
	match league:
		Constants.LEAGUE_S: return "S級（天才）"
		Constants.LEAGUE_A: return "A級（秀才）"
		Constants.LEAGUE_B: return "B級（優等生）"
		Constants.LEAGUE_C: return "C級（凡人）"
		Constants.LEAGUE_F: return "F級（赤点候補）"
		_: return "C級（凡人）"
