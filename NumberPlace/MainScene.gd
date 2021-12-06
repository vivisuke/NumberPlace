extends Node2D

enum {
	HORZ = 1,
	VERT,
	BOX,
	CELL,
}

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
const TILE_NONE = -1
const TILE_CURSOR = 0
const TILE_LTBLUE = 1				# 強調カーソル（薄青）
const TILE_LTORANGE = 2				# 強調カーソル（薄橙）
const TILE_PINK = 3					# 強調カーソル（薄ピンク）
const COLOR_INCORRECT = Color.red
const COLOR_DUP = Color.red
const COLOR_CLUE = Color.black
const COLOR_INPUT = Color("#2980b9")	# VELIZE HOLE
const DFCLT_FULLHOUSE = 1
const DFCLT_HIDDEN_SINGLE = 2
const DFCLT_NAKID_SINGLE = 10
const OPT_BEGINNER = 0
const OPT_EASY = 1
const OPT_NORMAL = 2
const N_EMPTY_BEGINNER = 32
const UNDO_ITEM_IX = 0
const UNDO_ITEM_OLD = 1
const UNDO_ITEM_NEW = 2
const IX_POS = 0
const IX_BIT = 1
const IX_TYPE = 2

const HINT_DUPLICATED = [
	"縦横3x3ブロックに重複した数字（赤色）\nがあり、ヒントを表示できません。", false
]
const HINT_MISTAKE = [
	"間違って入っている数字があるため\nヒントを表示できません。", false
]
const HINT_FULLHOUSE = [
	"ピンク強調された部分に空欄がひとつだけ\nしかありません。", false,
	"この場合、空欄に入れることができるのは、\n既に入っていない“%d”だけです。", false,
	#"したがって、明黄色強調された部分の空欄\nには“%d”が入ります。", false,
	"ちなみに、この解法テクニックを\n「フルハウス」と呼びます。", true,
]
const HINT_NAKID_SINGLE = [
	"ピンク強調された縦・横・3x3ブロックに、\nとある数字以外が全部あります。", false,
	"この場合、ピンク強調された部分に“%d”\n以外の数字が全部あります。 ", false,
	"したがって、黄色強調された部分の空欄\nには“%d”だけを入れることができます。", false,
	"ちなみに、この解法テクニックを\n「裸のシングル」と呼びます。", true,
]
const HINT_HIDDEN_SINGLE = [
	"とある数字が、強調された領域の一箇所に\nしか入れることができません。", false,
	"この場合、バツの場所に“%d”を入れる\nことが出来ません。", true,
	"したがって、バツがない空欄には“%d”が\n入ります。", true, 
	"ちなみに、この解法テクニックを\n「隠れたシングル」と呼びます。", true,
]

const SETTINGS_FILE_NAME = "user://settings.dat"

var solvedStat = false		# クリア済み状態
var paused = false
var hint_showed = false
var in_button_pressed = false	# ボタン押下処理中
#var hint_num				# ヒントで確定する数字、[1, 9]
var hint_numstr				# ヒントで確定する数字、[1, 9]
var hint_ix = 0				# 0, 1, 2, ...
var hint_texts = []			# ヒントテキスト配列
#var restarted = false
var elapsedTime = 0.0   	# 経過時間（単位：秒）
var nEmpty = 0				# 空欄数
var nDuplicated = 0			# 重複数字数
#var optGrade = -1			# 問題グレード、0: 入門、1:初級、2:ノーマル（初中級）
var diffculty = 0			# 難易度、フルハウス: 1, 隠れたシングル: 2, 裸のシングル: 10pnt？
var num_buttons = []		# 各数字ボタンリスト [0] -> Button1
var num_used = []			# 各数字使用数（手がかり数字＋入力数字）
var ans_bit = []			# 解答の各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var cell_bit = []			# 各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var candidates_bit = []		# 入力可能ビット論理和
var column_used = []		# 各カラムの使用済みビット
var box_used = []			# 各3x3ブロックの使用済みビット
var rmix_list = []			# 削除位置リスト
var rmixix					# 次に削除する要素位置
var cur_num = 0				# 選択されている数字ボタン、0 for 選択無し
var cur_cell_ix = -1		# 選択されているセルインデックス、-1 for 選択無し
var input_num = 0			# 入力された数字
var nRemoved
#var line_used_bits
var clue_labels = []		# 手がかり数字用ラベル配列
var input_labels = []		# 入力数字用ラベル配列
var shock_wave_timer = -1
var undo_ix = 0
var undo_stack = []			# 要素：[ix old new]、old, new は 0～9 の数値、0 for 空欄
#var settings = {}			# 設定辞書
var ClueLabel = load("res://ClueLabel.tscn")
var InputLabel = load("res://InputLabel.tscn")
var FallingChar = load("res://FallingChar.tscn")
var rng = RandomNumberGenerator.new()

onready var g = get_node("/root/Global")

func _ready():
	rng.randomize()
	print("g.qLevel = ", g.qLevel)		# 問題難易度レベル、0, 1, 2
	if g.qName == "":
		gen_qName()
	seed((g.qName+String(g.qLevel)).hash())
	#print($TitleBar/Label.text)
	$TitleBar/Label.text = titleText()
	#$Board/HintGuide.hide()
	g.show_hint_guide = false
	$Board/HintGuide.update()
	load_settings()
	cell_bit.resize(N_CELLS)
	candidates_bit.resize(N_CELLS)
	column_used.resize(N_HORZ)
	box_used.resize(N_HORZ)
	num_used.resize(N_HORZ + 1)		# +1 for 0
	# 手がかり数字、入力数字用 Label 生成
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
	#
	for i in range(N_HORZ):
		num_buttons.push_back(get_node("Button%d" % (i+1)))
	#$OptionButton.add_item(" Beginner")
	#$OptionButton.add_item(" Easy")
	#$OptionButton.add_item(" Normal")
	#gen_ans()
	#if g.settings.has("QuestLevel"):
	#	$OptionButton.select(int(g.settings["QuestLevel"]))
	gen_quest_greedy()
	#cur_num = 1
	#num_buttons[cur_num - 1].grab_focus()
	#update_cell_cursor()
	update_NEmptyLabel()
	update_undo_redo()
	$CanvasLayer/ColorRect.material.set_shader_param("size", 0)
	$SoundButton.pressed = !g.settings.has("Sound") || g.settings["Sound"]
	pass
func gen_qName():
	g.qRandom = true
	g.qName = ""
	for i in range(15):
		var r = rng.randi_range(0, 10+26-1)
		if r < 10: g.qName += String(r+1)
		else: g.qName += "%c" % (r - 10 + 0x61)		# 0x61 is 'a'
func titleText() -> String:
	var tt
	if g.qLevel == 0: tt = "【入門】"
	elif g.qLevel == 1: tt = "【初級】"
	elif g.qLevel == 2: tt = "【初中級】"
	return tt + "“" + g.qName + "”"
func load_settings():
	var file = File.new()
	if file.file_exists(g.SettingsFileName):		# 設定ファイル
		file.open(g.SettingsFileName, File.READ)
		g.settings = file.get_var()
		file.close()
		#print(g.settings)
func save_settings():
	var file = File.new()
	file.open(g.SettingsFileName, File.WRITE)
	file.store_var(g.settings)
	file.close()
func save_stats():
	var file = File.new()
	file.open(g.StatsFileName, File.WRITE)
	file.store_var(g.stats)
	file.close()
func update_NEmptyLabel():
	nEmpty = 0
	for ix in range(N_CELLS):
		if get_cell_numer(ix) == 0: nEmpty += 1
	$NEmptyLabel.text = "#spc: %d" % nEmpty
func update_undo_redo():
	$UndoButton.disabled = undo_ix == 0
	$RedoButton.disabled = undo_ix == undo_stack.size()
func push_to_undo_stack(item):
	if undo_stack.size() > undo_ix:
		undo_stack.resize(undo_ix)
	undo_stack.push_back(item)
	undo_ix += 1
func sound_effect():
	if $SoundButton.is_pressed():
		if input_num != 0 && num_used[input_num] >= 9:
			$AudioNumCompleted.play()
		else:
			$AudioNumClicked.play()
func on_solved():
	$CanvasLayer/ColorRect.show()
	shock_wave_timer = 0.0      # start shock wave
	solvedStat = true
	if $SoundButton.is_pressed(): $AudioSolved.play()
	if g.stats[g.qLevel].has("NSolved"):
		g.stats[g.qLevel]["NSolved"] += 1
	else:
		g.stats[g.qLevel]["NSolved"] = 1
	if g.stats[g.qLevel].has("TotalSec"):
		g.stats[g.qLevel]["TotalSec"] += int(elapsedTime)
	else:
		g.stats[g.qLevel]["TotalSec"] = int(elapsedTime)
	save_stats()
func _input(event):
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP || event.button_index == BUTTON_WHEEL_DOWN:
				return
		var mp = $Board/TileMap.world_to_map($Board/TileMap.get_local_mouse_position())
		print(mp)
		if mp.x < 0 || mp.x >= N_HORZ || mp.y < 0 || mp.y >= N_VERT: return
		if hint_showed:
			close_hint()
			return
		input_num = 0
		var ix = xyToIX(mp.x, mp.y)
		if clue_labels[ix].text != "":
			# undone: 手がかり数字ボタン選択
			num_button_pressed(int(clue_labels[ix].text), true)
		else:
			if cur_num == 0:			# 数字ボタン非選択の場合
				clear_cell_cursor()
				if ix == cur_cell_ix:
					cur_cell_ix = -1
				else:
					cur_cell_ix = ix
					#$Board/TileMap.set_cellv(mp, TILE_CURSOR)
					do_emphasize(ix, CELL, false)
				return
			if input_labels[ix].text != "":
				add_falling_char(input_labels[ix].text, ix)
			var num_str = String(cur_num)
			if input_labels[ix].text == num_str:
				push_to_undo_stack([ix, int(cur_num), 0])		# ix, old, new
				input_labels[ix].text = ""
			else:
				input_num = int(cur_num)
				push_to_undo_stack([ix, int(input_labels[ix].text), input_num])
				input_labels[ix].text = num_str
		update_undo_redo()
		update_num_buttons_disabled()
		update_cell_cursor(cur_num)
		update_NEmptyLabel()
		check_duplicated()
		sound_effect()
		if !solvedStat && is_solved():
			on_solved()
	if event is InputEventKey && event.is_pressed():
		print(event.as_text())
		if event.as_text() != "Alt" && hint_showed:
			close_hint()
			return
		if event.as_text() == "W" :
			shock_wave_timer = 0.0      # start shock wave
		var n = int(event.as_text())
		if n >= 1 && n <= 9:
			num_button_pressed(n, true)
	pass
func is_solved():
	return nEmpty == 0 && nDuplicated == 0
func _process(delta):
	if !is_solved() && !paused:
		elapsedTime += delta
		var sec = int(elapsedTime)
		var h = sec / (60*60)
		sec -= h * (60*60)
		var m = sec / 60
		sec -= m * 60
		$TimeLabel.text = "%02d:%02d:%02d" % [h, m, sec]
	#if cur_num != 0: set_num_cursor(cur_num)
	if !rmix_list.empty():		# 問題自動生成中
		var sv = cell_bit.duplicate()
		var x = rmix_list[rmixix] % N_HORZ
		var y = rmix_list[rmixix] / N_HORZ
		var lst = []
		lst.push_back(xyToIX(x, y))
		lst.push_back(xyToIX(y, x))
		lst.push_back(xyToIX(N_HORZ - 1 - x, N_VERT - 1 - y))
		lst.push_back(xyToIX(N_VERT - 1 - y, N_HORZ - 1 - x))
		for i in range(lst.size()):
			remove_clue_ix(lst[i])
		#remove_clue(x, y)
		#remove_clue(y, x)
		#remove_clue(N_HORZ - 1 - x, N_VERT - 1 - y)
		#remove_clue(N_VERT - 1 - y, N_HORZ - 1 - x)
		if !can_solve():
			print("CAN NOT SOLVE")
			cell_bit = sv
			for i in range(lst.size()):
				clue_labels[lst[i]].text = "?"	#bit_to_numstr(cell_bit[lst[i]])
			#var ix = xyToIX(x, y)
			#clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			#ix = xyToIX(y, x)
			#clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			#ix = xyToIX(N_HORZ - 1 - x, N_VERT - 1 - y)
			#clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			#ix = xyToIX(N_VERT - 1 - y, N_HORZ - 1 - x)
			#clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
		else:
			nRemoved += 1
			print("can solve, nRemoved = ", nRemoved)
		rmixix += 1
		if rmixix == rmix_list.size() || g.qLevel == OPT_BEGINNER && nEmpty() >= N_EMPTY_BEGINNER :
			update_cell_labels()
			can_solve()			# 難易度を再計算
			rmix_list.clear()
			clear_input()		# 手がかり数字が空のセルの入力ラベルクリア
			#cur_num = 1
			set_num_cursor(1)
			#num_buttons[cur_num - 1].grab_focus()
			update_all_status()
			#update_cell_cursor()
			#update_num_buttons_disabled()
			#update_NEmptyLabel()
			#check_duplicated()
			$DfcltLabel.text = "難易度: %.1f" % (diffculty/10.0)
			print("*** quest is generated ***")
			print("nEmpty = ", nEmpty())
			print("diffculty = ", diffculty)
			print("g.qLevel = ", g.qLevel)
			print_cells()
			elapsedTime = 0.0
	if shock_wave_timer >= 0:
		shock_wave_timer += delta
		$CanvasLayer/ColorRect.material.set_shader_param("size", shock_wave_timer)
		if shock_wave_timer > 2:
			shock_wave_timer = -1.0
	pass
func update_all_status():
	update_undo_redo()
	update_cell_cursor(cur_num)
	update_NEmptyLabel()
	update_num_buttons_disabled()
	check_duplicated()
func get_cell_numer(ix) -> int:		# ix 位置に入っている数字の値を返す、0 for 空欄
	if clue_labels[ix].text != "":
		return int(clue_labels[ix].text)
	if input_labels[ix].text != "":
		return int(input_labels[ix].text)
	return 0
func nEmpty():
	var n = 0
	for i in range(clue_labels.size()):
		if clue_labels[i].text == "": n += 1
	return n
func xyToIX(x, y) -> int: return x + y * N_HORZ
func num_to_bit(n : int): return 1 << (n-1) if n != 0 else 0
func bit_to_num(b):
	var mask = 1
	for i in range(N_HORZ):
		if (b & mask) != 0: return i + 1
		mask <<= 1
	return 0
func bit_to_numstr(b):
	if b == 0: return ""
	return String(bit_to_num(b))
func is_duplicated(ix : int):
	var n = get_cell_numer(ix)
	if n == 0: return false
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	for t in range(N_HORZ):
		if t != x && get_cell_numer(xyToIX(t, y)) == n:
			return true
		if t != y && get_cell_numer(xyToIX(x, t)) == n:
			return true
	var x0 = x - x % 3		# 3x3ブロック左上位置
	var y0 = y - y % 3
	for v in range(3):
		for h in range(3):
			var ix3 = xyToIX(x0+h, y0+v)
			if ix3 != ix && get_cell_numer(ix3) == n:
				return true
	return false
func check_duplicated():
	nDuplicated = 0
	for ix in range(N_CELLS):
		if is_duplicated(ix):
			nDuplicated += 1
			clue_labels[ix].add_color_override("font_color", COLOR_DUP)
			input_labels[ix].add_color_override("font_color", COLOR_DUP)
		else:
			clue_labels[ix].add_color_override("font_color", COLOR_CLUE)
			input_labels[ix].add_color_override("font_color", COLOR_INPUT)
	pass
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
func update_num_buttons_disabled():		# 使い切った数字ボタンをディセーブル
	#var nUsed = []		# 各数字の使用数 [0] for EMPTY
	for i in range(N_HORZ+1): num_used[i] = 0
	for ix in range(N_CELLS):
		num_used[get_cell_numer(ix)] += 1
	for i in range(N_HORZ):
		num_buttons[i].disabled = num_used[i+1] >= N_HORZ
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
	for i in range(N_CELLS):
		clue_labels[i].text = "?"
		input_labels[i].text = ""
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
	#update_cell_labels()
	ans_bit = cell_bit.duplicate()
	for i in range(N_CELLS): input_labels[i].text = ""		# 入力ラベル全消去
	pass
func remove_clue_ix(ix):
	clue_labels[ix].text = ""
	cell_bit[ix] = 0
func remove_clue(x, y):
	remove_clue_ix(xyToIX(x, y))
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
	solvedStat = false
	#optGrade = $OptionButton.get_selected_id()
	#g.settings["QuestLevel"] = optGrade
	#save_settings()
	if true:
		if rmix_list.empty():
			clear_cell_cursor()
			update_num_buttons_disabled()
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
func search_fullhouse() -> Array:	# [] for not found, [pos, bit, type], type: HORZ | VERT | BOX
	var pos
	for y in range(N_VERT):
		var t = ALL_BITS
		for x in range(N_HORZ):
			if cell_bit[xyToIX(x, y)] == 0:
				pos = xyToIX(x, y)
			else:
				t &= ~cell_bit[xyToIX(x, y)]
		if t != 0 && (t & -t) == t:		# 1ビットだけ → フルハウス
			return [pos, t, HORZ]
	for x in range(N_HORZ):
		var t = ALL_BITS
		for y in range(N_VERT):
			if cell_bit[xyToIX(x, y)] == 0:
				pos = xyToIX(x, y)
			else:
				t &= ~cell_bit[xyToIX(x, y)]
		if t != 0 && (t & -t) == t:		# 1ビットだけ → フルハウス
			return [pos, t, VERT]
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
					return [pos, t, BOX]
	return []
func search_nakid_single() -> Array:	# [] for not found, [pos, bit]
	for ix in range(N_CELLS):
		var b = candidates_bit[ix]
		if b != 0 && (b & -b) == b:
			return [ix, b]
	return []
func search_hidden_single() -> Array:	# [] for not found, [pos, bit]
	# return []		# for test
	# 3x3 ブロックで探索
	if true:		# false for Test
		for y0 in range(0, N_VERT, 3):
			for x0 in range(0, N_HORZ, 3):
				# (x0, y0) の 3x3 ブロック内で、可能なビットの数を数える
				var b0 = 0
				var b1 = 0
				for v in range(3):
					for h in range(3):
						var b = candidates_bit[xyToIX(x0+h, y0+v)]
						b1 |= (b0 & b)
						b0 ^= b
				b0 &= ~b1		# 隠れたシングルのビットがあるか
				if b0 != 0:		# 隠れたシングルがある場合
					b0 = b0 & -b0		# 最右ビットを取り出す
					for v in range(3):
						for h in range(3):
							if (b0 & candidates_bit[xyToIX(x0+h, y0+v)]) != 0:
								return [xyToIX(x0+h, y0+v), b0, BOX]

	# 水平方向検索
	if true:		# false for Test
		for y in range(N_VERT):
			var b0 = 0
			var b1 = 0
			for x in range(N_HORZ):
				var b = candidates_bit[xyToIX(x, y)]
				b1 |= (b0 & b)
				b0 ^= b
			b0 &= ~b1		# 隠れたシングルのビットがあるか
			if b0 != 0:		# 隠れたシングルがある場合
				b0 = b0 & -b0		# 最右ビットを取り出す
				for x in range(N_HORZ):
					if (b0 & candidates_bit[xyToIX(x, y)]) != 0:
						return [xyToIX(x, y), b0, HORZ]
	# 垂直方向検索
	for x in range(N_HORZ):
		var b0 = 0
		var b1 = 0
		for y in range(N_VERT):
			var b = candidates_bit[xyToIX(x, y)]
			b1 |= (b0 & b)
			b0 ^= b
		b0 &= ~b1		# 隠れたシングルのビットがあるか
		if b0 != 0:		# 隠れたシングルがある場合
			b0 = b0 & -b0		# 最右ビットを取り出す
			for y in range(N_VERT):
				if (b0 & candidates_bit[xyToIX(x, y)]) != 0:
					return [xyToIX(x, y), b0, VERT]
	return []
func _on_TestButton_pressed():
	#gen_quest()
	gen_quest_greedy()
	if false:
		if rmix_list.empty():
			clear_cell_cursor()
			update_num_buttons_disabled()
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
func step_solve() -> int:
	var pb = search_fullhouse()
	#print("Hullhouse: ", pb)
	if pb != []:
		cell_bit[pb[0]] = pb[1]
		#input_labels[pb[0]].text = String(bit_to_num(pb[1]))
		update_candidates(pb[0], pb[1])
		#print_candidates()
		return DFCLT_FULLHOUSE
	pb = search_hidden_single()
	#print("Hidden Single: ", pb)
	if pb != []:
		cell_bit[pb[IX_POS]] = pb[IX_BIT]
		#input_labels[pb[0]].text = String(bit_to_num(pb[1]))
		update_candidates(pb[IX_POS], pb[IX_BIT])
		#print_candidates()
		return DFCLT_HIDDEN_SINGLE
	if g.qLevel < OPT_NORMAL: return 0
	pb = search_nakid_single()
	#print("Nakid Single: ", pb)
	if pb != []:
		cell_bit[pb[IX_POS]] = pb[IX_BIT]
		#input_labels[pb[0]].text = String(bit_to_num(pb[1]))
		update_candidates(pb[IX_POS], pb[IX_BIT])
		#print_candidates()
		return DFCLT_NAKID_SINGLE
	return 0
func _on_SolveButton_pressed():
	if is_filled():
		clear_input()
	else:
		step_solve()
		update_input_labels()
	print_candidates()
	pass # Replace with function body.
func can_solve():
	var sv = cell_bit.duplicate()
	clear_input()
	init_candidates()
	diffculty = 0
	while true:
		var d = step_solve()
		if d == 0: break
		diffculty += d
	var f = is_filled()
	cell_bit = sv
	return f
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

func clear_cell_cursor():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/TileMap.set_cell(x, y, TILE_NONE)
func update_cell_cursor(num):		# 選択数字ボタンと同じ数字セルを強調
	if num != 0:
		for y in range(N_VERT):
			for x in range(N_HORZ):
				if num != 0 && get_cell_numer(xyToIX(x, y)) == num:
					$Board/TileMap.set_cell(x, y, TILE_CURSOR)
				else:
					$Board/TileMap.set_cell(x, y, TILE_NONE)
	else:
		for y in range(N_VERT):
			for x in range(N_HORZ):
				$Board/TileMap.set_cell(x, y, TILE_NONE)
		if cur_cell_ix >= 0:
			do_emphasize(cur_cell_ix, CELL, false)
func set_num_cursor(num):	# 当該ボタンだけを選択状態に
	cur_num = num
	for i in range(num_buttons.size()):
		num_buttons[i].pressed = (i + 1 == num)
func add_falling_char(num_str, ix : int):
	var fc = FallingChar.instance()
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	fc.position = $Board.rect_position + Vector2(x*CELL_WIDTH, y*CELL_WIDTH)
	fc.get_node("Label").text = num_str
	var th = rng.randf_range(0, 3.1415926535*2)
	fc.linear_velocity = Vector2(cos(th), sin(th))*100
	fc.angular_velocity = rng.randf_range(0, 1)
	add_child(fc)

func num_button_pressed(num : int, button_pressed):
	if in_button_pressed: return		# ボタン押下処理中の場合
	in_button_pressed = true
	if cur_cell_ix >= 0:		# セルが選択されている場合
		if button_pressed:
			var old = get_cell_numer(cur_cell_ix)
			if old != 0:
				add_falling_char(input_labels[cur_cell_ix].text, cur_cell_ix)
			if num == old:		# 同じ数字を入れる → 削除
				push_to_undo_stack([cur_cell_ix, old, 0])
				input_labels[cur_cell_ix].text = ""
			else:
				input_num = num
				push_to_undo_stack([cur_cell_ix, old, num])
				input_labels[cur_cell_ix].text = String(num)
			num_buttons[num-1].pressed = false
			update_all_status()
			sound_effect()
			if !solvedStat && is_solved():
				on_solved()
	else:		# セルが選択されていない場合
		#cur_num = num
		if button_pressed:
			set_num_cursor(num)
			#for i in range(num_buttons.size()):
			#	#if i + 1 != num: num_buttons[i].pressed = false
			#	num_buttons[i].pressed = (i + 1 == num)
		else:
			cur_num = 0		# toggled
		update_cell_cursor(cur_num)
	in_button_pressed = false
	pass

func _on_Button1_toggled(button_pressed):
	num_button_pressed(1, button_pressed)
func _on_Button2_toggled(button_pressed):
	num_button_pressed(2, button_pressed)
func _on_Button3_toggled(button_pressed):
	num_button_pressed(3, button_pressed)
func _on_Button4_toggled(button_pressed):
	num_button_pressed(4, button_pressed)
func _on_Button5_toggled(button_pressed):
	num_button_pressed(5, button_pressed)
func _on_Button6_toggled(button_pressed):
	num_button_pressed(6, button_pressed)
func _on_Button7_toggled(button_pressed):
	num_button_pressed(7, button_pressed)
func _on_Button8_toggled(button_pressed):
	num_button_pressed(8, button_pressed)
func _on_Button9_toggled(button_pressed):
	num_button_pressed(9, button_pressed)

func _on_NextButton_pressed():
	g.qRandom = true
	gen_qName()
	$TitleBar/Label.text = titleText()
	gen_quest_greedy()

func _on_PauseButton_pressed():
	if !rmix_list.empty(): return		# 問題自動生成中はポーズ禁止
	paused = !paused
	if paused:
		for ix in range(N_CELLS):
			if clue_labels[ix].text != "":
				cell_bit[ix] = num_to_bit(int(clue_labels[ix].text))
				clue_labels[ix].text = "?"
			elif input_labels[ix].text != "":
				cell_bit[ix] = num_to_bit(int(input_labels[ix].text))
				input_labels[ix].text = "?"
			else:
				cell_bit[ix] = 0
	else:
		for ix in range(N_CELLS):
			if clue_labels[ix].text != "":
				clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			elif input_labels[ix].text != "":
				input_labels[ix].text = bit_to_numstr(cell_bit[ix])
	pass # Replace with function body.

func _on_RestartButton_pressed():
	for ix in range(N_CELLS):
		if input_labels[ix].text != "":
			add_falling_char(input_labels[ix].text, ix)
			input_labels[ix].text = ""
	update_all_status()
	#num_buttons[cur_num-1].grab_focus()
	num_button_pressed(cur_num, true)
	pass # Replace with function body.

func _on_UndoButton_pressed():
	undo_ix -= 1
	var item = undo_stack[undo_ix]
	var txt = String(item[UNDO_ITEM_OLD]) if item[UNDO_ITEM_OLD] != 0 else ""
	input_labels[item[UNDO_ITEM_IX]].text = txt
	update_all_status()
	pass

func _on_RedoButton_pressed():
	var item = undo_stack[undo_ix]
	var txt = String(item[UNDO_ITEM_NEW]) if item[UNDO_ITEM_NEW] != 0 else ""
	input_labels[item[UNDO_ITEM_IX]].text = txt
	undo_ix += 1
	update_all_status()
	pass

func _on_SoundButton_pressed():
	g.settings["Sound"] = $SoundButton.pressed
	save_settings()
	pass # Replace with function body.


func _on_BackButton_pressed():
	get_tree().change_scene("res://TopScene.tscn")
	pass # Replace with function body.

func update_cell_bit():
	for ix in range(N_CELLS):
		cell_bit[ix] = num_to_bit(get_cell_numer(ix))
func reset_TileMap():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/TileMap.set_cell(x, y, -1)
func do_emphasize(ix : int, type, fullhouse):
	reset_TileMap()
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	if type == BOX || type == CELL:
		var x0 = x - x % 3
		var y0 = y - y % 3
		for v in range(3):
			for h in range(3):
				$Board/TileMap.set_cell(x0+h, y0+v, TILE_PINK)
	if type == HORZ || type == CELL:
		for h in range(N_HORZ):
			$Board/TileMap.set_cell(h, y, TILE_PINK)
	if type == VERT || type == CELL:
		for v in range(N_VERT):
			$Board/TileMap.set_cell(x, v, TILE_PINK)
	if type == CELL || fullhouse:
		$Board/TileMap.set_cell(x, y, TILE_CURSOR)
func hint_hidden_single() -> bool:
	var hs = search_hidden_single()
	if hs == []: return false
	do_emphasize(hs[IX_POS], hs[IX_TYPE], false)
	hint_numstr = bit_to_numstr(hs[IX_BIT])
	hint_texts = HINT_HIDDEN_SINGLE
	print(bit_to_numstr(hs[IX_BIT]))
	g.hint_pos = hs[IX_POS]
	g.hint_bit = hs[IX_BIT]
	g.hint_type = hs[IX_TYPE]
	g.cell_bit = cell_bit
	g.candidates_bit = candidates_bit
	#var hg = $Board/HintGuide
	#print(hg)
	$Board/HintGuide.update()		# 再描画
	return true
func hint_nakid_single():
	var ns = search_nakid_single()
	if ns == []: return false
	do_emphasize(ns[IX_POS], CELL, false)
	hint_numstr = bit_to_numstr(ns[IX_BIT])
	hint_texts = HINT_NAKID_SINGLE
	print(bit_to_numstr(ns[IX_BIT]))
	g.hint_pos = ns[IX_POS]
	g.hint_bit = ns[IX_BIT]
	return true
func show_hint():
	hint_showed = true
	hint_ix = 0
	$HintLayer.show()
	$HintLayer/Label.text = hint_texts[0]
	$HintLayer/PageLabel.text = "1/%d" % (hint_texts.size()/2)
	$HintLayer/PrevHintButton.disabled = true
	$HintLayer/NextHintButton.disabled = hint_ix == hint_texts.size() - 2
	g.show_hint_guide = hint_texts[hint_ix + 1]
	$Board/HintGuide.update()
func hint_prev_next_page(d):
	hint_ix += d * 2
	$HintLayer/Label.text = hint_texts[hint_ix].replace("%d", hint_numstr)
	$HintLayer/PageLabel.text = "%d/%d" % [(hint_ix/2+1), (hint_texts.size()/2)]
	$HintLayer/PrevHintButton.disabled = hint_ix == 0
	$HintLayer/NextHintButton.disabled = hint_ix == hint_texts.size() - 2
	g.show_hint_guide = hint_texts[hint_ix + 1]
	$Board/HintGuide.update()
func is_no_mistake():		# 間違って入っている数字が無いか？
	for ix in range(N_CELLS):
		var n = get_cell_numer(ix)
		if n != 0 && bit_to_num(ans_bit[ix]) != n: return false
	return true
func _on_HintButton_pressed():
	hint_texts = []
	update_cell_bit()
	init_candidates()
	if nDuplicated != 0:
		hint_texts = HINT_DUPLICATED
	elif !is_no_mistake():
		hint_texts = HINT_MISTAKE
	else:
		var fh = search_fullhouse()
		if fh != []:
			g.hint_pos = fh[IX_POS]
			g.hint_bit = fh[IX_BIT]
			do_emphasize(fh[IX_POS], fh[IX_TYPE], true)
			hint_numstr = bit_to_numstr(fh[IX_BIT])
			hint_texts = HINT_FULLHOUSE
		else:
			if cur_num != 0:	# 数字ボタン選択時
				if !hint_hidden_single():
					hint_nakid_single()
			else:
				if !hint_nakid_single():
					hint_hidden_single()
	if hint_texts != []:
		show_hint()
	pass # Replace with function body.

func close_hint():
	$HintLayer.hide()
	hint_showed = false
	set_num_cursor(cur_num)
	g.show_hint_guide = false
	$Board/HintGuide.update()
	if cur_num != 0:
		#cur_num = bit_to_num(g.hint_bit)
		set_num_cursor(bit_to_num(g.hint_bit))
	else:
		cur_cell_ix = g.hint_pos
	update_cell_cursor(cur_num)
func _on_CloseHintButton_pressed():
	close_hint()
	pass # Replace with function body.

func _on_PrevHintButton_pressed():
	hint_prev_next_page(-1)
func _on_NextHintButton_pressed():
	hint_prev_next_page(1)
func _on_DeselectButton_pressed():
	cur_cell_ix = -1
	update_cell_cursor(0)
	#cur_num = 0
	set_num_cursor(0)
func _on_CheckButton_pressed():
	for ix in range(N_CELLS):
		if input_labels[ix].text != "" && input_labels[ix].text != bit_to_numstr(ans_bit[ix]):
			input_labels[ix].add_color_override("font_color", COLOR_INCORRECT)
	pass # Replace with function body.
