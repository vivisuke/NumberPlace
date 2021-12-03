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

const HD = 20
const WD = 4

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
	if g.hint_pos < 0 || g.hint_bit == 0 || g.hint_type < 0:
		return
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
	pass
