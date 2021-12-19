extends ColorRect

const N_VERT = 9
const N_HORZ = 9
const CELL_WIDTH = 54
const BOARD_WIDTH = CELL_WIDTH * N_HORZ

func _ready():
	pass # Replace with function body.

func _draw():
	for x in range(N_HORZ+1):
		var wd = 3 if (x % 3) == 0 else 1
		draw_line(Vector2(x*CELL_WIDTH, 0), Vector2(x*CELL_WIDTH, BOARD_WIDTH), Color.black, wd)
		draw_line(Vector2(0, x*CELL_WIDTH), Vector2(BOARD_WIDTH, x*CELL_WIDTH), Color.black, wd)
	pass
