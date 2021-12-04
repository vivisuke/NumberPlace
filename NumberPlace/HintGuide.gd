extends ColorRect

enum {
	HORZ = 1,
	VERT,
	BOX,
}
const N_VERT = 9
const N_HORZ = 9
const N_CELLS = N_HORZ * N_VERT
const CELL_WIDTH = 53

const R = 22
const HD = 16
const WD = 4
const AHL = 16		# 矢じり長さ

#var hint_pos = -1			# ヒントで数字が入る位置
#var hint_bit : int = 0		# ヒントで入る数字ビット
#var hint_type = -1
#var candidates_bit = []		# 入力可能ビット論理和

onready var g = get_node("/root/Global")

func _ready():
	pass # Replace with function body.

func xyToIX(x, y) -> int: return x + y * N_HORZ
#func num_to_bit(n : int): return 1 << (n-1) if n != 0 else 0
func _draw():
	if !g.show_hint_guide: return
	#if g.hint_pos < 0 || g.hint_bit == 0 || g.hint_type < 0:
	#	return
	#b = num_to_bit(hint_num)
	var x = g.hint_pos % N_HORZ
	var y = g.hint_pos / N_HORZ
	if g.hint_type == HORZ:
		for h in range(N_HORZ):
			var ix = xyToIX(h, y)
			if g.cell_bit[ix] == 0 && (g.candidates_bit[ix] & g.hint_bit) == 0:
				var px = (h + 0.5) * CELL_WIDTH
				var py = (y + 0.5) * CELL_WIDTH
				draw_line(Vector2(px-HD, py-HD), Vector2(px+HD, py+HD), Color.red, WD)
				draw_line(Vector2(px-HD, py+HD), Vector2(px+HD, py-HD), Color.red, WD)
				for v in range(N_VERT):
					var ix2 = xyToIX(h, v)
					if g.cell_bit[ix2] == g.hint_bit:
						var py2 = (v + 0.5) * CELL_WIDTH
						#draw_circle(Vector2(px, py2), HD, Color.red)
						draw_arc(Vector2(px, py2), R, 0, 3.1416*2, 256, Color.red, WD)
						if abs(y - v) > 1:
							var uy = min(py, py2) + CELL_WIDTH/2
							var dy = max(py, py2) - CELL_WIDTH/2
							draw_line(Vector2(px, uy), Vector2(px, dy), Color.red, WD)
							if py < py2:	# ↑ 描画
								draw_line(Vector2(px, uy), Vector2(px-AHL, uy+AHL), Color.red, WD)
								draw_line(Vector2(px, uy), Vector2(px+AHL, uy+AHL), Color.red, WD)
							else:			# ↓ 描画
								draw_line(Vector2(px, dy), Vector2(px-AHL, dy-AHL), Color.red, WD)
								draw_line(Vector2(px, dy), Vector2(px+AHL, dy-AHL), Color.red, WD)
	if g.hint_type == VERT:
		for v in range(N_VERT):
			var ix = xyToIX(x, v)
			if g.cell_bit[ix] == 0 && (g.candidates_bit[ix] & g.hint_bit) == 0:
				var px = (x + 0.5) * CELL_WIDTH
				var py = (v + 0.5) * CELL_WIDTH
				draw_line(Vector2(px-HD, py-HD), Vector2(px+HD, py+HD), Color.red, WD)
				draw_line(Vector2(px-HD, py+HD), Vector2(px+HD, py-HD), Color.red, WD)
				for h in range(N_VERT):
					var ix2 = xyToIX(h, v)
					if g.cell_bit[ix2] == g.hint_bit:
						var px2 = (h + 0.5) * CELL_WIDTH
						draw_arc(Vector2(px2, py), R, 0, 3.1416*2, 256, Color.red, WD)
						if abs(x - h) > 1:
							var lx = min(px, px2) + CELL_WIDTH/2
							var rx = max(px, px2) - CELL_WIDTH/2
							draw_line(Vector2(lx, py), Vector2(rx, py), Color.red, WD)
							if px < px2:	# ← 描画
								draw_line(Vector2(lx, py), Vector2(lx+AHL, py-AHL), Color.red, WD)
								draw_line(Vector2(lx, py), Vector2(lx+AHL, py+AHL), Color.red, WD)
							else:			# → 描画
								draw_line(Vector2(rx, py), Vector2(rx-AHL, py-AHL), Color.red, WD)
								draw_line(Vector2(rx, py), Vector2(rx-AHL, py+AHL), Color.red, WD)
	if g.hint_type == BOX:	# 3x3 ブロック
		var x0 = x - x % 3
		var y0 = y - y % 3
		for v in range(3):
			for h in range(3):
				var ix = xyToIX(x0 + h, y0 + v)
				if g.cell_bit[ix] == 0 && (g.candidates_bit[ix] & g.hint_bit) == 0:
					var px = (x0 + h + 0.5) * CELL_WIDTH
					var py = (y0 + v + 0.5) * CELL_WIDTH
					# バツ描画
					draw_line(Vector2(px-HD, py-HD), Vector2(px+HD, py+HD), Color.red, WD)
					draw_line(Vector2(px-HD, py+HD), Vector2(px+HD, py-HD), Color.red, WD)
					for h2 in range(N_HORZ):
						var ix2 = xyToIX(h2, y0 + v)
						if g.cell_bit[ix2] == g.hint_bit:
							var px2 = (h2 + 0.5) * CELL_WIDTH
							draw_arc(Vector2(px2, py), R, 0, 3.1416*2, 256, Color.red, WD)
							if abs(x0 + h - h2) > 1:
								var lx = min(px, px2) + CELL_WIDTH/2
								var rx = max(px, px2) - CELL_WIDTH/2
								if px < px2:	# ← 描画
									var i = 1
									while h + i < 3 && g.cell_bit[ix+i] == 0 && (g.candidates_bit[ix+i] & g.hint_bit) == 0:
										i += 1
										lx += CELL_WIDTH
									if rx - lx > CELL_WIDTH/2:
										draw_line(Vector2(lx, py), Vector2(lx+AHL, py-AHL), Color.red, WD)
										draw_line(Vector2(lx, py), Vector2(lx+AHL, py+AHL), Color.red, WD)
								else:			# → 描画
									var i = -1
									while h + i >= 0 && g.cell_bit[ix+i] == 0 && (g.candidates_bit[ix+i] & g.hint_bit) == 0:
										i -= 1
										rx -= CELL_WIDTH
									if rx - lx > CELL_WIDTH/2:
										draw_line(Vector2(rx, py), Vector2(rx-AHL, py-AHL), Color.red, WD)
										draw_line(Vector2(rx, py), Vector2(rx-AHL, py+AHL), Color.red, WD)
								if rx - lx > CELL_WIDTH/2:
									draw_line(Vector2(lx, py), Vector2(rx, py), Color.red, WD)
					for v2 in range(N_VERT):	# 縦方向探索
						var ix2 = xyToIX(x0 + h, v2)
						if g.cell_bit[ix2] == g.hint_bit:
							var py2 = (v2 + 0.5) * CELL_WIDTH
							draw_arc(Vector2(px, py2), R, 0, 3.1416*2, 256, Color.red, WD)
							if abs(y0 + v - v2) > 1:
								var uy = min(py, py2) + CELL_WIDTH/2
								var dy = max(py, py2) - CELL_WIDTH/2
								if py < py2:	# ↑ 描画
									var i = 1
									while( v + i < 3 && g.cell_bit[ix+i*N_HORZ] == 0 &&
											(g.candidates_bit[ix+i*N_HORZ] & g.hint_bit) == 0):
										i += 1
										uy += CELL_WIDTH
									if dy - uy > CELL_WIDTH/2:
										draw_line(Vector2(px, uy), Vector2(px-AHL, uy+AHL), Color.red, WD)
										draw_line(Vector2(px, uy), Vector2(px+AHL, uy+AHL), Color.red, WD)
								else:			# ↓ 描画
									var i = -1
									while( v + i >= 0 && g.cell_bit[ix+i*N_HORZ] == 0 &&
											(g.candidates_bit[ix+i*N_HORZ] & g.hint_bit) == 0):
										i -= 1
										dy -= CELL_WIDTH
									if dy - uy > CELL_WIDTH/2:
										draw_line(Vector2(px, dy), Vector2(px-AHL, dy-AHL), Color.red, WD)
										draw_line(Vector2(px, dy), Vector2(px+AHL, dy-AHL), Color.red, WD)
								if dy - uy > CELL_WIDTH/2:
									draw_line(Vector2(px, uy), Vector2(px, dy), Color.red, WD)
	pass
