class_name CozyDoodleNode
extends Control
## 手書き落書き・コーヒーの輪染みを描画するプロシージャル・カスタム描画ノード
## GameScene.gd の内部クラスから独立化

var doodle_type: int = 0 # 0: coffee ring, 1: stars, 2: spiral, 3: tally marks
var color: Color = Color(0.5, 0.45, 0.4, 0.15)

func _init(type: int, col: Color = Color(0.5, 0.45, 0.4, 0.15)):
	self.doodle_type = type
	self.color = col
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
func _draw():
	match doodle_type:
		0: # Coffee ring stain (輪染み)
			var center = Vector2(80, 80)
			var radius = 45.0
			# 二重の薄い茶色の輪っかを描画
			draw_arc(center, radius, 0, TAU, 64, color, 1.5, true)
			draw_arc(center, radius + 1.5, 0.2, TAU - 0.5, 64, color * 0.8, 0.8, true)
			# 輪染みの垂れたシミをいくつかドットで描画
			draw_circle(center + Vector2(radius + 4, 10), 1.8, color * 1.2)
			draw_circle(center + Vector2(radius - 8, 38), 2.2, color * 1.0)
		1: # Hand-drawn Star (⭐)
			var center = Vector2(40, 40)
			var points = []
			var r_outer = 16.0
			var r_inner = 7.0
			for i in range(10):
				var angle = i * PI / 5.0 - PI / 2.0
				var r = r_outer if i % 2 == 0 else r_inner
				points.append(center + Vector2(cos(angle), sin(angle)) * r)
			# 連続する線で手書きの星を描く
			for i in range(10):
				draw_line(points[i], points[(i + 1) % 10], color * 1.5, 1.2, true)
			# ちいさいうずまきやハッシュマークも添える
			draw_arc(center + Vector2(25, -15), 5.0, 0, PI * 1.5, 16, color, 1.0, true)
		2: # Spiral doodle (落書きうずまき)
			var center = Vector2(50, 50)
			var last_p = center
			var num_rotations = 4.0
			var max_radius = 24.0
			for step in range(1, 100):
				var t = float(step) / 100.0
				var angle = t * num_rotations * TAU
				var r = t * max_radius
				var p = center + Vector2(cos(angle), sin(angle)) * r
				draw_line(last_p, p, color * 1.3, 1.0, true)
				last_p = p
		3: # Tally marks (正の字)
			var base = Vector2(20, 20)
			var sz = 24.0
			# 正の字を手書き風に歪ませて描く
			# 1画目: 横線
			draw_line(base + Vector2(0, sz*0.2), base + Vector2(sz, sz*0.2), color * 1.6, 1.5, true)
			# 2画目: 縦線
			draw_line(base + Vector2(sz*0.4, sz*0.2), base + Vector2(sz*0.4, sz*0.8), color * 1.6, 1.5, true)
			# 3画目: 横線（中）
			draw_line(base + Vector2(sz*0.4, sz*0.5), base + Vector2(sz*0.8, sz*0.5), color * 1.6, 1.5, true)
			# 4画目: 縦線（右）
			draw_line(base + Vector2(sz*0.8, sz*0.5), base + Vector2(sz*0.8, sz*0.8), color * 1.6, 1.5, true)
			# 5画目: 横線（下）
			draw_line(base + Vector2(sz*0.2, sz*0.8), base + Vector2(sz*0.9, sz*0.8), color * 1.6, 1.5, true)
