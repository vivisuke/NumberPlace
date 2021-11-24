extends Node2D

#enum {
#	HORZ = 1,
#	VERT,
#	BOX
#}

const N_VERT = 9
const N_HORZ = 9
const N_CELLS = N_HORZ * N_VERT
const CELL_WIDTH = 53
const BIT_1 = 1
const BIT_2 = 1<<1
const BIT_3 = 1<<2
const BIT_4 = 1<<3
const BIT_5 = 1<<4
const BIT_6 = 1<<5
const BIT_7 = 1<<6
const BIT_8 = 1<<7
const BIT_9 = 1<<8
const ALL_BITS = (1<<N_HORZ) - 1

var cell_bit = []			# 各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var candidates_bit = []		# 入力可能ビット論理和
var column_used = []		# 各カラムの使用済みビット
var box_used = []			# 各3x3ブロックの使用済みビット
var rmix_list = []			# 削除位置リスト
var rmixix					# 次に削除する要素位置
var nRemoved
#var line_used_bits
var clue_labels = []			# 手がかり数字用ラベル配列
var input_labels = []			# 入力数字用ラベル配列
var ClueLabel = load("res://ClueLabel.tscn")
var InputLabel = load("res://InputLabel.tscn")
var rng = RandomNumberGenerator.new()

func _ready():
	randomize()
	rng.randomize()
	cell_bit.resize(N_CELLS)
	candidates_bit.resize(N_CELLS)
	column_used.resize(N_HORZ)
	box_used.resize(N_HORZ)
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var label = ClueLabel.instance()
			clue_labels.push_back(label)
			label.rect_position = Vector2(x*CELL_WIDTH, y*CELL_WIDTH+2)
			label.text = String((x+y)%9 + 1)
			$Board.add_child(label)
			label = InputLabel.instance()
			input_labels.push_back(label)
			label.rect_position = Vector2(x*CELL_WIDTH, y*CELL_WIDTH+2)
			label.text = ""
			$Board.add_child(label)
	#gen_ans()
	gen_quest()
	pass
func _process(delta):
	if !rmix_list.empty():
		var sv = cell_bit.duplicate()
		var x = rmix_list[rmixix] % N_HORZ
		var y = rmix_list[rmixix] / N_HORZ
		remove_clue(x, y)
		remove_clue(y, x)
		remove_clue(N_HORZ - 1 - x, N_VERT - 1 - y)
		remove_clue(N_VERT - 1 - y, N_HORZ - 1 - x)
		if !can_solve():
			print("CAN NOT SOLVE")
			cell_bit = sv
			var ix = xyToIX(x, y)
			clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			ix = xyToIX(y, x)
			clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			ix = xyToIX(N_HORZ - 1 - x, N_VERT - 1 - y)
			clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			ix = xyToIX(N_VERT - 1 - y, N_HORZ - 1 - x)
			clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
		else:
			nRemoved += 1
			print("can solve, nRemoved = ", nRemoved)
		rmixix += 1
		if rmixix == rmix_list.size():
			rmix_list.clear()
			print("*** quest is generated ***")
			print("nEmpty = ", nEmpty())
	pass
func nEmpty():
	var n = 0
	for i in range(clue_labels.size()):
		if clue_labels[i].text == "": n += 1
	return n
func xyToIX(x, y) -> int: return x + y * N_HORZ
func bit_to_num(b):
	var mask = 1
	for i in range(N_HORZ):
		if (b & mask) != 0: return i + 1
		mask <<= 1
	return 0
func bit_to_numstr(b):
	if b == 0: return ""
	return String(bit_to_num(b))
func print_cells():
	var ix = 0
	for y in range(N_VERT):
		var lst = []
		for x in range(N_HORZ):
			lst.push_back(bit_to_num(cell_bit[ix]))
			ix += 1
		print(lst)
	print("")
func print_candidates():
	var ix = 0
	for y in range(N_VERT):
		var txt = ""
		for x in range(N_HORZ):
			txt += "%03x " % candidates_bit[ix]
			ix += 1
		print(txt)
	print("")
func print_box_used():
	var txt = ""
	for i in range(box_used.size()):
		txt += "%03x " % box_used[i]
	print(txt)
func update_cell_labels():		# 前提：cell_bit[ix] は 0 でない
	var ix = 0
	for y in range(N_VERT):
		for x in range(N_HORZ):
			clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			ix += 1
func update_input_labels():		# clue_labels
	var ix = 0
	for y in range(N_VERT):
		for x in range(N_HORZ):
			if clue_labels[ix].text == "" && cell_bit[ix] != 0:
				input_labels[ix].text = bit_to_numstr(cell_bit[ix])
			ix += 1
	
func init_candidates():		# 各セルの候補数字計算
	for i in range(N_CELLS):
		candidates_bit[i] = ALL_BITS if cell_bit[i] == 0 else 0
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var b = cell_bit[xyToIX(x, y)]
			if b != 0:
				for t in range(N_HORZ):
					candidates_bit[xyToIX(t, y)] &= ~b
					candidates_bit[xyToIX(x, t)] &= ~b
				var x0 = x - x % 3		# 3x3ブロック左上位置
				var y0 = y - y % 3
				for v in range(3):
					for h in range(3):
						candidates_bit[xyToIX(x0 + h, y0 + v)] &= ~b
	pass
func update_candidates(ix : int, b : int):		# ix に b を入れたときの候補数字更新
	candidates_bit[ix] = 0
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	for t in range(N_HORZ):
		candidates_bit[xyToIX(t, y)] &= ~b
		candidates_bit[xyToIX(x, t)] &= ~b
	var x0 = x - x % 3		# 3x3ブロック左上位置
	var y0 = y - y % 3
	for v in range(3):
		for h in range(3):
			candidates_bit[xyToIX(x0 + h, y0 + v)] &= ~b

func clear_input():		# 手がかり数字が空のセルの入力ラベルクリア
	for i in range(N_CELLS):
		if clue_labels[i].text == "":
			input_labels[i].text = ""
			cell_bit[i] = 0
# cell_bit[ix] 数字を入れる
# return: true for 解答生成成功
func gen_ans_sub(ix : int, line_used):
	#print_cells()
	#print_box_used()
	var x : int = ix % N_HORZ
	if x == 0: line_used = 0
	var x3 = x / 3
	var y3 = ix / (N_HORZ*3)
	var bix = y3 * 3 + x3
	var used = line_used | column_used[x] | box_used[bix]
	if used == ALL_BITS: return false		# 全数字が使用済み
	var lst = []
	var mask = BIT_1
	for i in range(N_HORZ):
		if (used & mask) == 0: lst.push_back(mask)		# 数字未使用の場合
		mask <<= 1
	if ix == N_CELLS - 1:
		cell_bit[ix] = lst[0]
		return true
	if lst.size() > 1: lst.shuffle()
	for i in range(lst.size()):
		cell_bit[ix] = lst[i]
		column_used[x] |= lst[i]
		box_used[bix] |= lst[i]
		if gen_ans_sub(ix+1, line_used | lst[i]): return true
		column_used[x] &= ~lst[i]
		box_used[bix] &= ~lst[i]
	cell_bit[ix] = 0
	return false;

func gen_ans():		# 解答生成
	for i in range(box_used.size()): box_used[i] = 0
	for i in range(cell_bit.size()): cell_bit[i] = 0
	var t = []
	for i in range(N_HORZ): t.push_back(1<<i)
	t.shuffle()
	for i in range(N_HORZ):
		cell_bit[i] = t[i]
		column_used[i] = t[i]
		box_used[i/3] |= t[i]
	#print(cell_bit)
	gen_ans_sub(N_HORZ, 0)
	print_cells()
	update_cell_labels()
	for i in range(N_CELLS): input_labels[i].text = ""		# 入力ラベル全消去
	pass
func remove_clue(x, y):
	var ix = xyToIX(x, y)
	clue_labels[ix].text = ""
	cell_bit[ix] = 0
func gen_quest():
	gen_ans()
	var lst = []
	if true:
		if true:
			for y in range(5):
				for x in range(y, N_HORZ - y):
					lst.push_back(xyToIX(x, y))
			lst.shuffle()
			for i in range(9):
				var x = lst[i] % N_HORZ
				var y = lst[i] / N_HORZ
				remove_clue(x, y)
				remove_clue(y, x)
				remove_clue(N_HORZ - 1 - x, N_VERT - 1 - y)
				remove_clue(N_VERT - 1 - y, N_HORZ - 1 - x)
		else:
			for y in range(5):
				for x in range(5):
					lst.push_back(xyToIX(x, y))
			lst.shuffle()
			for i in range(12):
				var x = lst[i] % N_HORZ
				var y = lst[i] / N_HORZ
				remove_clue(x, y)
				remove_clue(N_HORZ - 1 - x, y)
				remove_clue(x, N_VERT - 1 - y)
				remove_clue(N_HORZ - 1 - x, N_VERT - 1 - y)
	else:
		for i in range(N_CELLS): lst.push_back(i)
		lst.shuffle()
		for i in range(3*9):
			clue_labels[lst[i]].text = ""
			#input_labels[lst[i]].text = "8"
			cell_bit[lst[i]] = 0
	#
	init_candidates()			# 各セルの候補数字計算
	print_candidates()
func gen_quest_greedy():
	gen_ans()
	#for i in range(N_CELLS): input_labels[i].text = ""
	var lst = []
	for y in range(5):
		for x in range(y, N_HORZ - y):
			lst.push_back(xyToIX(x, y))
	lst.shuffle()
	var stack = []
	for i in range(lst.size()):
		stack.push_back(cell_bit)		# 現在の状態を保存
		var x = lst[i] % N_HORZ
		var y = lst[i] / N_HORZ
		remove_clue(x, y)
		remove_clue(y, x)
		remove_clue(N_HORZ - 1 - x, N_VERT - 1 - y)
		remove_clue(N_VERT - 1 - y, N_HORZ - 1 - x)
		if !can_solve():
			cell_bit = stack.pop_back()
			var ix = xyToIX(x, y)
			clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			ix = xyToIX(y, x)
			clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			ix = xyToIX(N_HORZ - 1 - x, N_VERT - 1 - y)
			clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			ix = xyToIX(N_VERT - 1 - y, N_HORZ - 1 - x)
			clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			init_candidates()
	pass
func search_fullhouse() -> Array:	# [] for not found, [pos, bit]
	var pos
	for y in range(N_VERT):
		var t = ALL_BITS
		for x in range(N_HORZ):
			if cell_bit[xyToIX(x, y)] == 0:
				pos = xyToIX(x, y)
			else:
				t &= ~cell_bit[xyToIX(x, y)]
		if t != 0 && (t & -t) == t:		# 1ビットだけ → フルハウス
			return [pos, t]
	for x in range(N_HORZ):
		var t = ALL_BITS
		for y in range(N_VERT):
			if cell_bit[xyToIX(x, y)] == 0:
				pos = xyToIX(x, y)
			else:
				t &= ~cell_bit[xyToIX(x, y)]
		if t != 0 && (t & -t) == t:		# 1ビットだけ → フルハウス
			return [pos, t]
	for y0 in range(0, N_VERT, 3):
		for x0 in range(0, N_HORZ, 3):
			#var ix = xyToIX(x, y)
			var t = ALL_BITS
			for v in range(3):
				for h in range(3):
					if cell_bit[xyToIX(x0+h, y0+v)] == 0:
						pos = xyToIX(x0+h, y0+v)
					else:
						t &= ~cell_bit[xyToIX(x0+h, y0+v)]
				if t != 0 && (t & -t) == t:		# 1ビットだけ → フルハウス
					return [pos, t]
	return []
func search_nakid_single() -> Array:	# [] for not found, [pos, bit]
	for ix in range(N_CELLS):
		var b = candidates_bit[ix]
		if b != 0 && (b & -b) == b:
			return [ix, b]
	return []
func search_hidden_single() -> Array:	# [] for not found, [pos, bit]
	for y0 in range(0, N_VERT, 3):
		for x0 in range(0, N_HORZ, 3):
			var b0 = 0
			var b1 = 0
			for v in range(3):
				for h in range(3):
					var b = candidates_bit[xyToIX(x0+h, y0+v)]
					b1 |= (b0 & b)
					b0 ^= b
			b0 &= ~b1
			if b0 != 0:
				b0 = b0 & -b0
				for v in range(3):
					for h in range(3):
						if (b0 & candidates_bit[xyToIX(x0+h, y0+v)]) != 0:
							return [xyToIX(x0+h, y0+v), b0]
				
	return []
func _on_TestButton_pressed():
	#gen_quest()
	#gen_quest_greedy()
	if rmix_list.empty():
		gen_ans()
		for y in range(5):
			for x in range(y, N_HORZ - y):
				rmix_list.push_back(xyToIX(x, y))
		rmix_list.shuffle()
		rmixix = 0		# 次に削除する位置
		nRemoved = 0
		print("rmix_list: ", rmix_list)
		print("rmixix: ", rmixix)
	else:
		print("rmixix: ", rmixix)
		if rmixix >= rmix_list.size():
			rmix_list.clear()
		else:
			var sv = cell_bit.duplicate()
			var x = rmix_list[rmixix] % N_HORZ
			var y = rmix_list[rmixix] / N_HORZ
			remove_clue(x, y)
			remove_clue(y, x)
			remove_clue(N_HORZ - 1 - x, N_VERT - 1 - y)
			remove_clue(N_VERT - 1 - y, N_HORZ - 1 - x)
			if !can_solve():
				print("CAN NOT SOLVE")
				cell_bit = sv
				var ix = xyToIX(x, y)
				clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
				ix = xyToIX(y, x)
				clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
				ix = xyToIX(N_HORZ - 1 - x, N_VERT - 1 - y)
				clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
				ix = xyToIX(N_VERT - 1 - y, N_HORZ - 1 - x)
				clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			else:
				nRemoved += 1
				print("can solve, nRemoved = ", nRemoved)
			rmixix += 1
			if rmixix == rmix_list.size():
				print("*** quest is generated ***")
	pass
func step_solve() -> bool:
	var pb = search_fullhouse()
	#print("Hullhouse: ", pb)
	if pb != []:
		cell_bit[pb[0]] = pb[1]
		#input_labels[pb[0]].text = String(bit_to_num(pb[1]))
		update_candidates(pb[0], pb[1])
		#print_candidates()
		return true
	pb = search_hidden_single()
	#print("Hidden Single: ", pb)
	if pb != []:
		cell_bit[pb[0]] = pb[1]
		#input_labels[pb[0]].text = String(bit_to_num(pb[1]))
		update_candidates(pb[0], pb[1])
		#print_candidates()
		return true
	pb = search_nakid_single()
	#print("Nakid Single: ", pb)
	if pb != []:
		cell_bit[pb[0]] = pb[1]
		#input_labels[pb[0]].text = String(bit_to_num(pb[1]))
		update_candidates(pb[0], pb[1])
		#print_candidates()
		return true
	return false
func _on_SolveButton_pressed():
	if is_filled():
		clear_input()
	else:
		step_solve()
		update_input_labels()
	print_candidates()
	pass # Replace with function body.
func can_solve():
	clear_input()
	init_candidates()
	while step_solve():
		pass
	return is_filled()
func is_filled():	# セルが全部埋まっているか？
	for i in range(cell_bit.size()):
		if cell_bit[i] == 0: return false
	return true
func _on_QustButton_pressed():
	if can_solve():
		print("solved")
	else:
		print("not solved")
	update_input_labels()
	pass # Replace with function body.
