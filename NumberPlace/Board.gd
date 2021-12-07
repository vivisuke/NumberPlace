extends ColorRect

const N_VERT = 9
const N_HORZ = 9
const CELL_WIDTH = 54
const BOX_WIDTH = CELL_WIDTH * 3
const BOARD_WIDTH = CELL_WIDTH * N_HORZ
const bgcol = Color("e0e0e0")

func _ready():
	pass # Replace with function body.

func _draw():
	draw_rect(Rect2(0, 0, BOX_WIDTH, BOX_WIDTH), bgcol)
	draw_rect(Rect2(BOX_WIDTH, BOX_WIDTH, BOX_WIDTH, BOX_WIDTH), bgcol)
	draw_rect(Rect2(BOX_WIDTH*2, 0, BOX_WIDTH, BOX_WIDTH), bgcol)
	draw_rect(Rect2(0, BOX_WIDTH*2, BOX_WIDTH, BOX_WIDTH), bgcol)
	draw_rect(Rect2(BOX_WIDTH*2, BOX_WIDTH*2, BOX_WIDTH, BOX_WIDTH), bgcol)
	pass

