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
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	badge_panel = PanelContainer.new()
	badge_panel.custom_minimum_size = Vector2(160, 40)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(DeskTheme.COLOR_INK, 0.85)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	badge_panel.add_theme_stylebox_override("panel", style)
	margin.add_child(badge_panel)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	badge_panel.add_child(hbox)
	
	icon_rect = ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(12, 12)
	icon_rect.color = DeskTheme.COLOR_GREEN
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_rect)
	
	status_label = Label.new()
	status_label.text = "オンライン"
	status_label.add_theme_font_override("font", DeskTheme.get_font())
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(status_label)
	
	# Connect to BackendManager if exists
	if has_node("/root/BackendManager"):
		var bm = get_node("/root/BackendManager")
		if bm.has_signal("connection_lost"):
			bm.connection_lost.connect(_on_connection_lost)
		if bm.has_signal("reconnect_succeeded"):
			bm.reconnect_succeeded.connect(_on_reconnect_succeeded)
		if bm.has_signal("reconnect_failed"):
			bm.reconnect_failed.connect(_on_reconnect_failed)
			
		# Check initial state
		if bm.is_mock_room or bm.auth_token == "":
			_set_offline_mode()
		else:
			_set_online_mode()

func _process(delta: float) -> void:
	if is_reconnecting:
		badge_panel.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
	else:
		badge_panel.modulate.a = 1.0

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
