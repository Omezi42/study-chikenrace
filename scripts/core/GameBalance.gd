class_name GameBalance
extends RefCounted

## スコア・ブラフ・ダウトのバランス定数（GDD と実装の単一ソース）

# 嘘の報告（ブラフ）上限
const BLUFF_CAP_BASE := 35
const BLUFF_CAP_PER_CHEAT_SHEET := 35

# タイムライン・ダウト（👍）
const DOUBT_SUCCESS_EXTRA := 15      # 見破り成功: 相手の盛り分 + この値
const DOUBT_FAIL_PENALTY := 20       # 見破り失敗: この値を減点
const MAX_DOUBT_VOTES_PER_DAY := 3

# 最終暴露で自分の嘘がバレたとき（Showdown）
const PLAYER_LIE_EXPOSED_EXTRA := 15  # 盛り分に加算して減点

# ストップ時ボーナス（引いた数字とは別）
const STOP_BONUS_RULER := 10
const STOP_BONUS_STICKY_NOTE := 30

# コンボ（同教科連続）
const COMBO_BONUS_PER_STACK := 10

# 5教科コンプリート
const FIVE_SUBJECTS_BONUS := 200


static func max_bluff_cap(cheat_sheet_count: int) -> int:
	return BLUFF_CAP_BASE + cheat_sheet_count * BLUFF_CAP_PER_CHEAT_SHEET


static func loadout_number_for_item(item_type: int) -> int:
	for slot in range(1, 11):
		if Global.current_loadout.get(slot, -1) == item_type:
			return slot
	return clampi(item_type, 1, 10)


static func doubt_success_reward(lie_amount: int) -> int:
	return maxi(0, lie_amount) + DOUBT_SUCCESS_EXTRA


static func player_lie_exposed_penalty(lie_amount: int) -> int:
	return maxi(0, lie_amount) + PLAYER_LIE_EXPOSED_EXTRA


static func apply_doubt_vote(game_session, rival_reported: int, rival_actual: int, is_lying_flag: bool) -> Dictionary:
	var lie := maxi(0, rival_reported - rival_actual)
	var is_lying := is_lying_flag or lie > 0
	if not is_instance_valid(game_session):
		return {"success": false, "delta": 0, "lie": lie}
	if is_lying:
		var delta := doubt_success_reward(lie)
		game_session.hidden_bonus_score += delta
		return {"success": true, "delta": delta, "lie": lie}
	game_session.hidden_bonus_score -= DOUBT_FAIL_PENALTY
	return {"success": false, "delta": -DOUBT_FAIL_PENALTY, "lie": 0}
