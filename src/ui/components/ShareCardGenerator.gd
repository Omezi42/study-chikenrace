class_name ShareCardGenerator
extends Node

static func generate_and_copy_share_image(parent: Node, showdown_data: Dictionary) -> void:
	# オフスクリーンでレンダリングするための SubViewport を作成
	var viewport = SubViewport.new()
	viewport.size = Vector2(1200, 630) # X(Twitter)のOGP推奨サイズ
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(viewport)
	
	# 結果カードのレイアウトを作成
	var card_bg = ColorRect.new()
	card_bg.color = Color("2e1a05") # 黒板・木目調のダークブラウン
	card_bg.custom_minimum_size = Vector2(1200, 630)
	viewport.add_child(card_bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	card_bg.add_child(vbox)
	
	# タイトル
	var title_lbl = Label.new()
	title_lbl.text = "【テスト勉強チキンレース】結果発表！"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", DeskTheme.get_font())
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_lbl)
	
	# 偏差値表示
	var dev_lbl = Label.new()
	var final_dev = showdown_data.get("deviation_value", 50.0)
	dev_lbl.text = "最終偏差値: 偏差値 %.1f" % final_dev
	dev_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dev_lbl.add_theme_font_override("font", DeskTheme.get_font())
	dev_lbl.add_theme_font_size_override("font_size", 76)
	dev_lbl.add_theme_color_override("font_color", Color("ffd54f")) # ゴールド
	vbox.add_child(dev_lbl)
	
	# スコア内訳
	var score_lbl = Label.new()
	var total_score = showdown_data.get("final_scores", {}).get("player", 0)
	score_lbl.text = "合計得点: %d 点" % total_score
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_override("font", DeskTheme.get_font())
	score_lbl.add_theme_font_size_override("font_size", 36)
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(score_lbl)
	
	# 描画更新のために1フレーム待つ
	await parent.get_tree().process_frame
	await parent.get_tree().process_frame
	
	# 画像データとして取得
	var img = viewport.get_texture().get_image()
	
	# Web環境（Unityroom等）とネイティブ環境で保存・共有ロジックを分岐
	if OS.has_feature("web"):
		_web_share_image(img)
	else:
		_native_save_image(img)
		
	# 後片付け
	viewport.queue_free()

static func _web_share_image(img: Image) -> void:
	var png_buffer = img.save_png_to_buffer()
	var base64_str = Marshalls.raw_to_base64(png_buffer)
	var js_window = JavaScriptBridge.get_interface("window")
	if js_window and js_window.has_method("onShareImageGenerated"):
		js_window.onShareImageGenerated(base64_str)
	else:
		push_warning("JavaScript 'onShareImageGenerated' method not found.")

static func _native_save_image(img: Image) -> void:
	var path = "user://chikenrace_result.png"
	img.save_png(path)
	OS.shell_open(ProjectSettings.globalize_path(path))
