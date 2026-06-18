class_name ShareCardGenerator
extends Node

static func generate_and_copy_share_image(parent: Node, showdown_data: Dictionary) -> void:
	var total_score = showdown_data.get("final_scores", {}).get("player", 0)
	var final_dev = showdown_data.get("deviation_value", 50.0)
	var title_obtained = showdown_data.get("title", "一般学生")
	
	# X(Twitter)のシェア用テキストを作成
	var tweet_text = "【テスト勉強チキンレース】学期末試験終了！\n"
	tweet_text += "合計得点: %d点 を叩き出しました！\n" % total_score
	tweet_text += "（最終偏差値: %.1f | 称号: %s）\n\n" % [final_dev, title_obtained]
	
	var game_url = "https://unityroom.com/games/studychikenrace"
	tweet_text += game_url + "\n"
	tweet_text += "#テスト勉強チキンレース\n"
	
	var x_url = "https://x.com/intent/tweet?text=" + tweet_text.uri_encode()
	OS.shell_open(x_url)
