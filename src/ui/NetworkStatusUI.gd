class_name NetworkStatusUI
extends CanvasLayer

var badge_panel: PanelContainer
var status_label: Label
var icon_rect: ColorRect

var is_online: bool = true
var is_reconnecting: bool = false

func _ready() -> void:
	layer = 120 # Put it above normal UI but below modals (which are 150/160)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	
	badge_panel = PanelContainer.new()
	badge_panel.custom_minimum_size = Vector2(80, 24)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(DeskTheme.COLOR_INK, 0.85)
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 5
	style.shadow_offset = Vector2(3, 3)
	badge_panel.add_theme_stylebox_override("panel", style)
	margin.add_child(badge_panel)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	badge_panel.add_child(hbox)
	
	icon_rect = ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(8, 8)
	icon_rect.color = DeskTheme.COLOR_GREEN
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_rect)
	
	status_label = Label.new()
	status_label.text = "オンライン"
	status_label.add_theme_font_override("font", DeskTheme.get_font())
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(status_label)
	
	# Connect to Network Manager if exists
	var net_mgr = get_node_or_null("/root/WebRTCManager")
	if not net_mgr:
		net_mgr = get_node_or_null("/root/BackendManager")
	if net_mgr:
		if net_mgr.has_signal("connection_lost"):
			net_mgr.connection_lost.connect(_on_connection_lost)
		if net_mgr.has_signal("reconnect_succeeded"):
			net_mgr.reconnect_succeeded.connect(_on_reconnect_succeeded)
		if net_mgr.has_signal("reconnect_failed"):
			net_mgr.reconnect_failed.connect(_on_reconnect_failed)
			
		# Check initial state
		var is_offline = (Global.game_mode == Constants.MODE_CPU)
		if ("is_mock_room" in net_mgr) and net_mgr.is_mock_room:
			is_offline = true
		if ("auth_token" in net_mgr) and net_mgr.auth_token == "":
			is_offline = true
			
		if is_offline:
			_set_offline_mode()
		else:
			_set_online_mode()

func _process(delta: float) -> void:
	if is_reconnecting:
		badge_panel.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
	else:
		badge_panel.modulate.a = 1.0

	# 画面サイズに応じたスケール調整（モバイル横画面での巨大化防止）
	var vp_size = get_viewport().get_visible_rect().size
	if vp_size.y > 0:
		var is_portrait = vp_size.y > vp_size.x
		var scale_factor = 1.0
		if not is_portrait and vp_size.y < 600:
			# モバイル横画面のような高さが低い画面では少し小さめにする
			scale_factor = clamp(vp_size.y / 600.0, 0.6, 1.0)
		elif is_portrait:
			# モバイル縦画面では他のUIに合わせて大きくする
			scale_factor = clamp(vp_size.x / 480.0, 1.5, 3.0)
		badge_panel.scale = Vector2(scale_factor, scale_factor)
		badge_panel.pivot_offset = badge_panel.size # 右下基準でスケール

func _set_online_mode() -> void:
	is_online = true
	is_reconnecting = false
	status_label.text = "オンライン"
	icon_rect.color = DeskTheme.COLOR_GREEN

func _set_offline_mode() -> void:
	is_online = false
	is_reconnecting = false
	status_label.text = "オフライン"
	icon_rect.color = Color("9e9e9e")

func _on_connection_lost() -> void:
	if not is_online:
		return
	is_online = false
	is_reconnecting = true
	status_label.text = "再接続中..."
	icon_rect.color = DeskTheme.COLOR_TENSION

func _on_reconnect_succeeded() -> void:
	_set_online_mode()
	DeskTheme.show_toast(self, "サーバーに再接続しました", 2.0, DeskTheme.COLOR_GREEN)

func _on_reconnect_failed() -> void:
	_set_offline_mode()
	DeskTheme.show_toast(self, "サーバーから切断されました。オフラインで続行します", 3.0, DeskTheme.COLOR_TENSION)
