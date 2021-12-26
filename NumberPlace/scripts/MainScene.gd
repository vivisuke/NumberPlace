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
const CELL_WIDTH = 54
const CELL_WIDTH3 = CELL_WIDTH/3
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
const DFCLT_HIDDEN_SINGLE_LINE = 5
const DFCLT_NAKID_SINGLE = 10
#const OPT_BEGINNER = 0
#const OPT_EASY = 1
#const OPT_NORMAL = 2
const N_EMPTY_BEGINNER = 32
const UNDO_TYPE_CELL = 0		# セル数字入力
const UNDO_TYPE_MEMO = 1		# メモ数字反転
const UNDO_TYPE_AUTO_MEMO = 2	# 自動メモ
const UNDO_ITEM_TYPE = 0
const UNDO_ITEM_IX = 1
const UNDO_ITEM_NUM = 2			# for メモ数字
const UNDO_ITEM_OLD = 2			# for セル数字
const UNDO_ITEM_NEW = 3			# for セル数字
const UNDO_ITEM_MEMOIX = 4		# メモ数字反転位置リスト
const UNDO_ITEM_MEMO = 5		# 数字を入れた位置のメモ数字（ビット値）
const UNDO_ITEM_MEMO_LST = 1
const IX_POS = 0
const IX_BIT = 1
const IX_TYPE = 2
const NUM_FONT_SIZE = 40
const MEMO_FONT_SIZE = 20
const LVL_BEGINNER = 0
const LVL_EASY = 1
const LVL_NORMAL = 2
#const LVL_NOT_SYMMETRIC = 3
enum {
	ID_RESTART = 1,
	ID_SOUND,			# 効果音
}

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
	"ちなみに、この解法テクニックを\n「フルハウス」と呼びます。", false,
]
const HINT_NAKID_SINGLE = [
	"ピンク強調された縦・横・3x3ブロックに、\nとある数字以外が全部あります。", false,
	"この場合、ピンク強調された部分に“%d”\n以外の数字が全部あります。 ", false,
	"したがって、黄色強調された部分の空欄\nには“%d”だけを入れることができます。", false,
	"ちなみに、この解法テクニックを\n「裸のシングル」と呼びます。", false,
]
const HINT_HIDDEN_SINGLE = [
	"とある数字が、強調された領域の一箇所に\nしか入れることができません。", false,
	"この場合、バツの場所に“%d”を入れる\nことが出来ません。", true,
	"したがって、バツがない空欄には“%d”が\n入ります。", true, 
	"ちなみに、この解法テクニックを\n「隠れたシングル」と呼びます。", true,
]

const SETTINGS_FILE_NAME = "user://settings.dat"

var symmetric = true		# 対称形問題
var qCreating = false		# 問題生成中
var solvedStat = false		# クリア済み状態
var paused = false			# ポーズ状態
var sound = true			# 効果音
var menuPopuped = false
var hint_showed = false
var memo_mode = false		# メモ（候補数字）エディットモード
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
var num_buttons = []		# 各数字ボタンリスト [0] -> 削除ボタン、[1] -> Button1, ...
var num_used = []			# 各数字使用数（手がかり数字＋入力数字）
var ans_bit = []			# 解答の各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var cell_bit = []			# 各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var candidates_bit = []		# 入力可能ビット論理和
var column_used = []		# 各カラムの使用済みビット
var box_used = []			# 各3x3ブロックの使用済みビット
var rmix_list = []			# 削除位置リスト
var rmixix					# 次に削除する要素位置
var cur_num = -1			# 選択されている数字ボタン、-1 for 選択無し
var cur_cell_ix = -1		# 選択されているセルインデックス、-1 for 選択無し
var input_num = 0			# 入力された数字
var nRemoved
#var line_used_bits
var clue_labels = []		# 手がかり数字用ラベル配列
var input_labels = []		# 入力数字用ラベル配列
var memo_labels = []		# メモ（候補数字）用ラベル配列（２次元）
var memo_text = []			# ポーズ復活時用ラベルテキスト配列（２次元）
var shock_wave_timer = -1
var undo_ix = 0
var undo_stack = []			# 要素：[ix old new]、old, new は 0～9 の数値、0 for 空欄
#var settings = {}			# 設定辞書
var ClueLabel = load("res://ClueLabel.tscn")
var InputLabel = load("res://InputLabel.tscn")
var MemoLabel = load("res://MemoLabel.tscn")
var FallingChar = load("res://FallingChar.tscn")
var rng = RandomNumberGenerator.new()

onready var g = get_node("/root/Global")

func _ready():
	rng.randomize()
	print("g.qLevel = ", g.qLevel)		# 問題難易度レベル、0, 1, 2
	if g.qNumber != 0:
		g.qName = "%06d" % g.qNumber
	elif g.qName == "":
		gen_qName()
	#seed((g.qName+String(g.qLevel)).hash())
	#print($TitleBar/Label.text)
	$TitleBar/Label.text = titleText()
	$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
	#$MessLabel.text = ""
	#$Board/HintGuide.hide()
	g.show_hint_guide = false
	$Board/HintGuide.update()
	g.load_settings()
	sound = !g.settings.has("Sound") || g.settings["Sound"]
	cell_bit.resize(N_CELLS)
	candidates_bit.resize(N_CELLS)
	memo_text.resize(N_CELLS)
	column_used.resize(N_HORZ)
	box_used.resize(N_HORZ)
	num_used.resize(N_HORZ + 1)		# +1 for 0
	init_labels()
	#
	var pu = $TitleBar/MenuButton.get_popup()
	pu.connect("id_pressed", self, "_on_PopupMenuPressed")
	pu.connect("modal_closed", self, "on_ModalClosed")
	#pu.font = $TitleBar/Label.font
	#var pu = $TitleBar/MenuButton/PopupMenu2
	var txr = $TextureSoundON.texture if sound else $TextureSoundOFF.texture
	pu.add_icon_item(txr, "Sound", ID_SOUND)
	pu.add_icon_item($TextureRestart.texture, "Restartリスタート", ID_RESTART)
	#
	num_buttons.push_back($DeleteButton)
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
	#num_buttons[cur_num].grab_focus()
	#update_cell_cursor()
	#update_NEmptyLabel()
	#update_undo_redo()
	update_all_status()
	$CanvasLayer/ColorRect.material.set_shader_param("size", 0)
	#$SoundButton.pressed = !g.settings.has("Sound") || g.settings["Sound"]
	pass
func init_labels():
	# 手がかり数字、入力数字用 Label 生成
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var px = x * CELL_WIDTH
			var py = y * CELL_WIDTH
			var label = ClueLabel.instance()
			clue_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = String((x+y)%9 + 1)
			$Board.add_child(label)
			label = InputLabel.instance()
			input_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = ""
			$Board.add_child(label)
			var lst = []
			for v in range(3):
				for h in range(3):
					label = MemoLabel.instance()
					lst.push_back(label)
					label.rect_position = Vector2(px + CELL_WIDTH3*h, py + CELL_WIDTH3*v)
					label.text = ""		# String(v*3+h+1)
					$Board.add_child(label)
			memo_labels.push_back(lst)
					
func gen_qName():
	g.qRandom = true
	g.qName = ""
	for i in range(15):
		var r = rng.randi_range(0, 10+26-1)
		if r < 10: g.qName += String(r+1)
		else: g.qName += "%c" % (r - 10 + 0x61)		# 0x61 is 'a'
func titleText() -> String:
	var tt = ""
	if g.qLevel == LVL_BEGINNER: tt = "【入門】"
	elif g.qLevel == 1: tt = "【初級】"
	elif g.qLevel == 2: tt = "【初中級】"
	#elif g.qLevel == LVL_NOT_SYMMETRIC: tt = "【非対称】"
	return tt + "“" + g.qName + "”"
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
	if sound:
		if input_num > 0 && num_used[input_num] >= 9:
			$AudioNumCompleted.play()
		else:
			$AudioNumClicked.play()
func is_all_solved_todaysQuest():
	return g.tqSolvedSec[0] >= 0 && g.tqSolvedSec[1] >= 0 && g.tqSolvedSec[2] >= 0
func on_solved():
	$CanvasLayer/ColorRect.show()
	shock_wave_timer = 0.0      # start shock wave
	solvedStat = true
	if sound:
		$AudioSolved.play()		# 効果音再生
	var ix = g.qLevel
	if g.todaysQuest:		# 今日の問題の場合
		if g.tqSolvedSec[ix] < 0 || int(elapsedTime) < g.tqSolvedSec[ix]:
			g.tqSolvedSec[ix] = int(elapsedTime)	# 最短クリア時間更新
		if is_all_solved_todaysQuest() && g.tqConsSolvedDays != g.tqConsYesterdayDays + 1:
			# 全問クリアの場合
			g.tqConsSolvedDays = g.tqConsYesterdayDays + 1
			if g.tqConsSolvedDays > g.tqMaxConsSolvedDays:
				g.tqMaxConsSolvedDays = g.tqConsSolvedDays		# 最大連続クリア日数
			g.env[g.KEY_N_COINS] += g.TODAYS_QUEST_N_COINS
			$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
			g.save_environment()
		g.tqSolvedYMD = g.today_string()
		g.save_todaysQuest()
	else:	# 今日の問題でない場合
		if g.qNumber != 0:		# 問題集の場合
			if g.nSolved[g.qLevel] == g.qNumber - 1:	
				g.nSolved[g.qLevel] += 1
				g.save_nSolved()
				$NextButton.disabled = false
			ix += 3		# for 統計情報
		if g.stats[ix].has("NSolved"):
			g.stats[ix]["NSolved"] += 1
		else:
			g.stats[ix]["NSolved"] = 1
		if g.stats[ix].has("TotalSec"):
			g.stats[ix]["TotalSec"] += int(elapsedTime)
		else:
			g.stats[ix]["TotalSec"] = int(elapsedTime)
		if !g.stats[ix].has("BestTime") || int(elapsedTime) < g.stats[ix]["BestTime"]:
			g.stats[ix]["BestTime"] = int(elapsedTime)
		g.save_stats()
	update_all_status()
func remove_all_memo_at(ix):
	for i in range(N_HORZ):
		memo_labels[ix][i].text = ""
func remove_all_memo():
	for ix in range(N_CELLS):
		for i in range(N_HORZ):
			memo_labels[ix][i].text = ""
	for v in range(N_VERT*3):
		for h in range(N_HORZ*3):
			$Board/MemoTileMap.set_cell(h, v, TILE_NONE)
func remove_memo_num(ix : int, num : int):		# ix に num を入れたときに、メモ数字削除
	var lst = []
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	for h in range(N_HORZ):
		var ix2 = xyToIX(h, y)
		if memo_labels[ix2][num-1].text != "":
			memo_labels[ix2][num-1].text = ""
			lst.push_back(ix2)
		ix2 = xyToIX(x, h)
		if memo_labels[ix2][num-1].text != "":
			memo_labels[ix2][num-1].text = ""
			lst.push_back(ix2)
	var x0 = x - x % 3
	var y0 = y - y % 3
	for v in range(3):
		for h in range(3):
			var ix2 = xyToIX(x0 + h, y0 + v)
			if memo_labels[ix2][num-1].text != "":
				memo_labels[ix2][num-1].text = ""
				lst.push_back(ix2)
	return lst
func flip_memo_num(ix : int, num : int):
	if memo_labels[ix][num-1].text == "":
		memo_labels[ix][num-1].text = String(num)
	else:
		memo_labels[ix][num-1].text = ""
func clear_all_memo(ix):
	for i in range(N_HORZ): memo_labels[ix][i].text = ""
func _input(event):
	if menuPopuped: return
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP || event.button_index == BUTTON_WHEEL_DOWN:
				return
		if paused: return
		var mp = $Board/TileMap.world_to_map($Board/TileMap.get_local_mouse_position())
		print(mp)
		if mp.x < 0 || mp.x >= N_HORZ || mp.y < 0 || mp.y >= N_VERT:
			return		# 盤面セル以外の場合
		if hint_showed:
			close_hint()
			return
		input_num = -1
		var ix = xyToIX(mp.x, mp.y)
		if clue_labels[ix].text != "":
			# undone: 手がかり数字ボタン選択
			num_button_pressed(int(clue_labels[ix].text), true)
		else:
			if cur_num < 0:			# 数字ボタン非選択の場合
				clear_cell_cursor()
				if ix == cur_cell_ix:
					cur_cell_ix = -1
				else:
					cur_cell_ix = ix
					#$Board/TileMap.set_cellv(mp, TILE_CURSOR)
					do_emphasize(ix, CELL, false)
				update_all_status()
				return
			if cur_num == 0:
				if input_labels[ix].text != "":
					add_falling_char(input_labels[ix].text, ix)
					push_to_undo_stack([UNDO_TYPE_CELL, ix, int(input_labels[ix].text), 0, [], 0])		# ix, old, new
					input_labels[ix].text = ""
				else:
					# undone: Undo/Redo 対応
					for i in range(N_HORZ):
						memo_labels[ix][i].text = ""	# メモ数字削除
			# 数字ボタン選択状態の場合 → セルにその数字を入れる or メモ数字反転
			elif !memo_mode:
				if input_labels[ix].text != "":
					add_falling_char(input_labels[ix].text, ix)
				var num_str = String(cur_num)
				if input_labels[ix].text == num_str:	# 同じ数字が入っていれば消去
					push_to_undo_stack([UNDO_TYPE_CELL, ix, int(cur_num), 0, [], 0])		# ix, old, new
					input_labels[ix].text = ""
				else:	# 上書き
					input_num = int(cur_num)
					var lst = remove_memo_num(ix, cur_num)
					var mb = get_memo_bits(ix)
					push_to_undo_stack([UNDO_TYPE_CELL, ix, int(input_labels[ix].text), input_num, lst, mb])
					#undo_stack.back().back() = lst
					input_labels[ix].text = num_str
				for i in range(N_HORZ): memo_labels[ix][i].text = ""	# メモ数字削除
			else:	# メモ数字エディットモード
				if get_cell_numer(ix) != 0:
					return		# 空欄でない場合
				push_to_undo_stack([UNDO_TYPE_MEMO, ix, cur_num])
				flip_memo_num(ix, cur_num)
		#update_undo_redo()
		#update_num_buttons_disabled()
		#update_cell_cursor(cur_num)
		#update_NEmptyLabel()
		#check_duplicated()
		update_all_status()
		sound_effect()
		if !solvedStat && is_solved():
			on_solved()
	if event is InputEventKey && event.is_pressed():
		print(event.as_text())
		if paused: return
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
		if symmetric:
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
		if rmixix == rmix_list.size() || g.qLevel == LVL_BEGINNER && nEmpty() >= N_EMPTY_BEGINNER :
			qCreating = false
			update_cell_labels()
			can_solve()			# 難易度を再計算
			rmix_list.clear()
			undo_ix = 0
			undo_stack = []
			clear_input()		# 手がかり数字が空のセルの入力ラベルクリア
			cur_num = -1
			cur_cell_ix = -1
			#set_num_cursor(1)
			#num_buttons[cur_num].grab_focus()
			update_all_status()
			#update_cell_cursor()
			#update_num_buttons_disabled()
			#update_NEmptyLabel()
			#check_duplicated()
			if g.qNumber != 0:		# 問題集の場合
				if g.qNumber <= g.nSolved[g.qLevel]:
					$NextButton.disabled = false
			else:		# 自動問題生成の場合
				$NextButton.disabled = false
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
func sec_to_MSStr(t):
	var sec = t % 60
	var mnt = t / 60
	return "%02d:%02d" % [mnt, sec]
func update_all_status():
	update_undo_redo()
	update_cell_cursor(cur_num)
	update_NEmptyLabel()
	update_num_buttons_disabled()
	check_duplicated()
	$HintButton.disabled = solvedStat
	$CheckButton.disabled = solvedStat
	if qCreating:
		$MessLabel.text = "問題生成中..."
	elif solvedStat:
		var n = g.stats[g.qLevel]["NSolved"]
		var avg : int = int(g.stats[g.qLevel]["TotalSec"] / n)
		var txt = sec_to_MSStr(avg)
		var bst = sec_to_MSStr(g.stats[g.qLevel]["BestTime"])
		$MessLabel.text = "グッジョブ！ クリア回数: %d、平均: %s、最短: %s" % [n, txt, bst]
	elif paused:
		$MessLabel.text = "ポーズ中です。解除にはポーズボタンを押してください。"
	elif cur_num > 0:
		$MessLabel.text = "現数字（%d）を入れるセルをクリックしてください。" % cur_num
	elif cur_cell_ix >= 0:
		$MessLabel.text = "セルに入れる数字ボタンをクリックしてください。"
	else:
		$MessLabel.text = "数字ボタンまたは空セルをクリックしてください。"
	$CheckButton.disabled = g.env[g.KEY_N_COINS] <= 0
	$HintButton.disabled = g.env[g.KEY_N_COINS] <= 0
	$AutoMemoButton.disabled = g.env[g.KEY_N_COINS] < 2
	
func get_cell_numer(ix) -> int:		# ix 位置に入っている数字の値を返す、0 for 空欄
	if clue_labels[ix].text != "":
		return int(clue_labels[ix].text)
	if input_labels[ix].text != "":
		return int(input_labels[ix].text)
	return 0
func get_memo_bits(ix) -> int:
	var bits = 0
	var mask = BIT_1
	for i in range(N_HORZ):
		if memo_labels[ix][i].text != "": bits |= mask
		mask <<= 1
	return bits
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
		num_buttons[i+1].disabled = num_used[i+1] >= N_HORZ
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
	
func init_cell_bit():		# clue_labels, input_labels から 各セルの cell_bit 更新
	for ix in range(N_CELLS):
		var n = get_cell_numer(ix)
		if n == 0:
			cell_bit[ix] = 0
		else:
			cell_bit[ix] = num_to_bit(n)
func init_candidates():		# cell_bit から各セルの候補数字計算
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
	qCreating = true
	$MessLabel.text = "問題生成中..."
	$NextButton.disabled = true
	symmetric = g.qLevel != LVL_NORMAL
	solvedStat = false
	#seed((g.qName+String(g.qLevel)).hash())
	var stxt = g.qName+String(g.qLevel)
	if g.qNumber != 0: stxt += "Q"
	seed(stxt.hash())
	#optGrade = $OptionButton.get_selected_id()
	#g.settings["QuestLevel"] = optGrade
	#g.save_settings()
	if true:
		if rmix_list.empty():
			clear_cell_cursor()
			update_num_buttons_disabled()
			gen_ans()
			if symmetric:
				for y in range(5):
					for x in range(y, N_HORZ - y):
						rmix_list.push_back(xyToIX(x, y))
			else:
				for ix in range(N_CELLS): rmix_list.push_back(ix)
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
		return DFCLT_HIDDEN_SINGLE if pb[IX_TYPE] == BOX else DFCLT_HIDDEN_SINGLE_LINE
	#if g.qLevel < OPT_NORMAL: return 0
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
	if num > 0 && !paused:
		var num_str = String(num)
		for y in range(N_VERT):
			for x in range(N_HORZ):
				var ix = xyToIX(x, y)
				if num != 0 && get_cell_numer(ix) == num:
					$Board/TileMap.set_cell(x, y, TILE_CURSOR)
				else:
					$Board/TileMap.set_cell(x, y, TILE_NONE)
				for v in range(3):
					for h in range(3):
						var n = v * 3 + h + 1
						var t = TILE_NONE
						if memo_labels[ix][n-1].text == num_str:
							t = TILE_CURSOR
						$Board/MemoTileMap.set_cell(x*3+h, y*3+v, t)
	else:
		for y in range(N_VERT):
			for x in range(N_HORZ):
				$Board/TileMap.set_cell(x, y, TILE_NONE)
				for v in range(3):
					for h in range(3):
						$Board/MemoTileMap.set_cell(x*3+h, y*3+v, TILE_NONE)
		if cur_cell_ix >= 0:
			do_emphasize(cur_cell_ix, CELL, false)
func set_num_cursor(num):	# 当該ボタンだけを選択状態に
	cur_num = num
	for i in range(num_buttons.size()):
		num_buttons[i].pressed = (i == num)
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
	if paused: return			# ポーズ中
	in_button_pressed = true
	if cur_cell_ix >= 0:		# セルが選択されている場合
		if num == 0:			# 削除ボタン押下の場合
			var old = get_cell_numer(cur_cell_ix)
			if old != 0:
				add_falling_char(input_labels[cur_cell_ix].text, cur_cell_ix)
				push_to_undo_stack([UNDO_TYPE_CELL, cur_cell_ix, old, 0, [], 0])
				input_labels[cur_cell_ix].text = ""
			else:
				remove_all_memo_at(cur_cell_ix)
		else:
			if !memo_mode:
				if button_pressed:
					var old = get_cell_numer(cur_cell_ix)
					if old != 0:
						add_falling_char(input_labels[cur_cell_ix].text, cur_cell_ix)
					if num == old:		# 同じ数字を入れる → 削除
						push_to_undo_stack([UNDO_TYPE_CELL, cur_cell_ix, old, 0, [], 0])
						input_labels[cur_cell_ix].text = ""
					else:
						input_num = num
						var lst = remove_memo_num(cur_cell_ix, num)
						var mb = get_memo_bits(cur_cell_ix)
						push_to_undo_stack([UNDO_TYPE_CELL, cur_cell_ix, old, num, lst, mb])
						#undo_stack.back().back() = lst
						input_labels[cur_cell_ix].text = String(num)
					for i in range(N_HORZ): memo_labels[cur_cell_ix][i].text = ""
					num_buttons[num].pressed = false
					update_all_status()
					sound_effect()
					if !solvedStat && is_solved():
						on_solved()
			else:		# メモ数字エディットモード
				if get_cell_numer(cur_cell_ix) != 0:
					return		# 空欄でない場合
				push_to_undo_stack([UNDO_TYPE_MEMO, cur_cell_ix, num])
				flip_memo_num(cur_cell_ix, num)
		num_buttons[num].pressed = false
	else:	# セルが選択されていない場合
		#cur_num = num
		if button_pressed:
			set_num_cursor(num)
			#for i in range(num_buttons.size()):
			#	#if i + 1 != num: num_buttons[i].pressed = false
			#	num_buttons[i].pressed = (i + 1 == num)
		else:
			cur_num = -1		# toggled
		update_cell_cursor(cur_num)
	in_button_pressed = false
	update_all_status()
	pass

func _on_DeleteButton_toggled(button_pressed):
	num_button_pressed(0, button_pressed)		# 0 for delete
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
	if paused: return		# ポーズ中
	if g.todaysQuest:		# 今日の問題の場合
		g.qLevel += 1
		if g.qLevel > 2: g.qLevel = 0
	elif g.qNumber == 0:		# 問題自動生成の場合
		g.qRandom = true		# 
		gen_qName()
	else:					# 問題集の場合
		g.qNumber += 1
		g.qName = "%06d" % g.qNumber
	#seed((g.qName+String(g.qLevel)).hash())
	$TitleBar/Label.text = titleText()
	remove_all_memo()
	gen_quest_greedy()
	cur_cell_ix = -1
	cur_num = -1

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
			var lst = []
			for i in range(N_HORZ):
				lst.push_back(memo_labels[ix][i].text)
				memo_labels[ix][i].text = ""
			memo_text[ix] = lst
		for i in range(N_HORZ+1):
			num_buttons[i].disabled = true
	else:
		for ix in range(N_CELLS):
			if clue_labels[ix].text != "":
				clue_labels[ix].text = bit_to_numstr(cell_bit[ix])
			elif input_labels[ix].text != "":
				input_labels[ix].text = bit_to_numstr(cell_bit[ix])
			for i in range(N_HORZ):
				memo_labels[ix][i].text = memo_text[ix][i]
	update_all_status()
	pass # Replace with function body.

func _on_RestartButton_pressed():
	if paused: return		# ポーズ中
	for ix in range(N_CELLS):
		if input_labels[ix].text != "":
			add_falling_char(input_labels[ix].text, ix)
			input_labels[ix].text = ""
		for i in range(N_HORZ):
			memo_labels[ix][i].text = ""
	undo_stack = []
	undo_ix = 0
	update_all_status()
	#num_buttons[cur_num-1].grab_focus()
	num_button_pressed(cur_num, true)
	pass # Replace with function body.
func flip_memo_bits(ix, bits):
	var mask = BIT_1
	for n in range(N_HORZ):
		if (bits & mask) != 0:
			flip_memo_num(ix, n+1)
		mask <<= 1
func set_memo_bits(ix, bits):
	var mask = BIT_1
	for i in range(N_HORZ):
		if (bits & mask) != 0:
			memo_labels[ix][i].text = String(i+1)
		else:
			memo_labels[ix][i].text = ""
		mask <<= 1
func _on_UndoButton_pressed():
	if paused: return		# ポーズ中
	undo_ix -= 1
	var item = undo_stack[undo_ix]
	if item[UNDO_ITEM_TYPE] == UNDO_TYPE_CELL:
		var txt = String(item[UNDO_ITEM_OLD]) if item[UNDO_ITEM_OLD] != 0 else ""
		input_labels[item[UNDO_ITEM_IX]].text = txt
		var lst = item[UNDO_ITEM_MEMOIX]
		for i in range(lst.size()):
			flip_memo_num(lst[i], item[UNDO_ITEM_NEW])
		var mb = item[UNDO_ITEM_MEMO]
		flip_memo_bits(item[UNDO_ITEM_IX], mb)
	elif item[UNDO_ITEM_TYPE] == UNDO_TYPE_MEMO:
		flip_memo_num(item[UNDO_ITEM_IX], item[UNDO_ITEM_NUM])
	elif item[UNDO_ITEM_TYPE] == UNDO_TYPE_AUTO_MEMO:
		var lst = item[UNDO_ITEM_MEMO_LST]
		for ix in range(N_CELLS):
			set_memo_bits(ix, lst[ix])
	update_all_status()
	pass

func _on_RedoButton_pressed():
	if paused: return		# ポーズ中
	var item = undo_stack[undo_ix]
	if item[UNDO_ITEM_TYPE] == UNDO_TYPE_CELL:
		var txt = String(item[UNDO_ITEM_NEW]) if item[UNDO_ITEM_NEW] != 0 else ""
		input_labels[item[UNDO_ITEM_IX]].text = txt
		var lst = item[UNDO_ITEM_MEMOIX]
		for i in range(lst.size()):
			flip_memo_num(lst[i], item[UNDO_ITEM_NEW])
		if item[UNDO_ITEM_NEW] != 0: clear_all_memo(item[UNDO_ITEM_IX])
	elif item[UNDO_ITEM_TYPE] == UNDO_TYPE_MEMO:
		flip_memo_num(item[UNDO_ITEM_IX], item[UNDO_ITEM_NUM])
	elif item[UNDO_ITEM_TYPE] == UNDO_TYPE_AUTO_MEMO:
		do_auto_memo()
	undo_ix += 1
	update_all_status()
	pass

func _on_SoundButton_pressed():
	sound = !sound
	g.settings["Sound"] = sound
	g.save_settings()
	var pu = $TitleBar/MenuButton.get_popup()
	var txr = $TextureSoundON.texture if sound else $TextureSoundOFF.texture
	pu.set_item_icon(pu.get_item_index(ID_SOUND), txr)
	pass # Replace with function body.


func _on_BackButton_pressed():
	if g.todaysQuest:
		get_tree().change_scene("res://TodaysQuest.tscn")
	elif g.qNumber == 0:
		get_tree().change_scene("res://TopScene.tscn")
	else:
		get_tree().change_scene("res://LevelScene.tscn")
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
	if paused: return
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
func clear_memo_emphasis():
	for y in range(N_VERT*3):
		for x in range(N_HORZ*3):
			$Board/MemoTileMap.set_cell(x, y, TILE_NONE)
func _on_HintButton_pressed():
	if paused: return		# ポーズ中
	g.env[g.KEY_N_COINS] -= 1
	$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
	g.save_environment()
	$MessLabel.text = ""
	clear_memo_emphasis()
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
			if cur_num > 0:		# 数字ボタン選択時
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
	if cur_num > 0:		# 数字ボタン選択時
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
	if paused: return		# ポーズ中
	cur_cell_ix = -1
	update_cell_cursor(0)
	#cur_num = -1
	set_num_cursor(-1)
	update_all_status()
func _on_CheckButton_pressed():
	if paused: return		# ポーズ中
	g.env[g.KEY_N_COINS] -= 1
	$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
	g.save_environment()
	var err = false
	for ix in range(N_CELLS):
		if input_labels[ix].text != "" && input_labels[ix].text != bit_to_numstr(ans_bit[ix]):
			err = true
			input_labels[ix].add_color_override("font_color", COLOR_INCORRECT)
	if err:
		$MessLabel.text = "間違って入っている数字（赤色）があります。"
	else:
		$MessLabel.text = "間違って入っている数字はありません。"
	pass # Replace with function body.

func do_auto_memo():
	init_cell_bit()
	init_candidates()		# 可能候補数字計算
	var lst = []
	for ix in range(N_CELLS):
		var bits = 0	
		if get_cell_numer(ix) != 0:		# 数字が入っている場合
			for i in range(N_HORZ):
				memo_labels[ix][i].text = ""
		else:							# 数字が入っていない場合
			var mask = BIT_1
			for i in range(N_HORZ):
				if memo_labels[ix][i].text != "": bits |= mask
				if (candidates_bit[ix] & mask) != 0:
					memo_labels[ix][i].text = String(i+1)
				else:
					memo_labels[ix][i].text = ""
				mask <<= 1
		lst.push_back(bits)
	return lst
func _on_AutoMemoButton_pressed():
	if paused: return		# ポーズ中
	if qCreating: return	# 問題生成中
	g.env[g.KEY_N_COINS] -= 2
	$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
	g.save_environment()
	var lst = do_auto_memo()
	push_to_undo_stack([UNDO_TYPE_AUTO_MEMO, lst])
	update_all_status()
	pass # Replace with function body.


func _on_MemoButton_toggled(button_pressed):
	memo_mode = button_pressed
	print(memo_mode)
	var sz = MEMO_FONT_SIZE if memo_mode else NUM_FONT_SIZE
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/arialbd.ttf")
	font.size = sz
	#print(font)
	for i in range(N_HORZ):
		num_buttons[i+1].add_font_override("font", font)
	pass # Replace with function body.
#
func _on_PopupMenuPressed(id):
	menuPopuped = false
	print("_on_PopupMenuPressed(id = ", id, ")")
	if id == ID_RESTART:
		_on_RestartButton_pressed()
	elif id == ID_SOUND:
		_on_SoundButton_pressed()

func on_ModalClosed():
	menuPopuped = false
	print("on_ModalClosed")


func _on_MenuButton_button_down():
	menuPopuped = true
	print("_on_MenuButton_button_down")
	pass # Replace with function body.


func _on_MenuButton_button_up():
	print("_on_MenuButton_button_up")
	pass # Replace with function body.


func _on_DelMemoButton_pressed():
	remove_all_memo()
	pass # Replace with function body.
