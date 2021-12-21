extends Node2D

var settings = {}		# 設定辞書
var stats = []			# 各問題レベルごとの統計情報（問題クリア数、トータルタイム（単位：秒））
var nSolved = [0, 0, 0]		# 各問題集ごとの問題クリア数、[0] for 入門問題集
var qLevel = 0			# 問題レベル [0, 1, 2]
var qNumber = 0			# [1, 2^10] for 問題番号、0 for 非問題集
var qName = ""			# 問題名
var qRandom = true		# ランダム生成問題か？
var todaysQuest = false		# 今日の問題か？
var tqSolvedYMD = ""		# 今日の問題を解いた日付 "YYYY/MM/DD"
var tqSolvedSec = [-1, -1, -1]		# 各今日の問題クリアタイム、-1 for 未クリア

var show_hint_guide = false
var hint_pos : int = -1			# ヒントで数字が入る位置
var hint_bit : int = 0		# ヒントで入る数字ビット
var hint_type : int = -1
var candidates_bit = []		# 入力可能ビット論理和
var cell_bit = []			# 現在の状態

const SettingsFileName	= "user://NumberPlace_stgs.dat"
const StatsFileName		= "user://NumberPlace_stats.dat"
const NSolvedFileName	= "user://NumberPlace_nSolved.dat"
const TodaysQuestFileName	= "user://NumberPlace_todaysQuest.dat"

func _ready():
	pass # Replace with function body.
#
func load_settings():
	var file = File.new()
	if file.file_exists(SettingsFileName):		# 設定ファイル
		file.open(SettingsFileName, File.READ)
		settings = file.get_var()
		file.close()
func save_settings():
	var file = File.new()
	file.open(SettingsFileName, File.WRITE)
	file.store_var(settings)
	file.close()
#
func save_stats():
	var file = File.new()
	file.open(StatsFileName, File.WRITE)
	file.store_var(stats)
	file.close()
func load_stats():
	var file = File.new()
	if file.file_exists(StatsFileName):		# 統計情報ファイル
		file.open(StatsFileName, File.READ)
		stats = file.get_var()
		file.close()
		if stats.size() == 3:
			stats += [{}, {}, {}, ]
	else:
		stats = [{}, {}, {}, {}, {}, {}, ]		# [0] for 入門問題生成
	#print(stats)
#
func save_nSolved():
	var file = File.new()
	file.open(NSolvedFileName, File.WRITE)
	file.store_var(nSolved)
	file.close()
func load_nSolved():
	var file = File.new()
	if file.file_exists(NSolvedFileName):		# 統計情報ファイル
		file.open(NSolvedFileName, File.READ)
		nSolved = file.get_var()
		file.close()
	else:
		nSolved = [0, 0, 0]		# [0] for 入門問題集
#
func save_todaysQuest():
	var file = File.new()
	file.open(TodaysQuestFileName, File.WRITE)
	file.store_var([tqSolvedYMD, tqSolvedSec])
	file.close()
func load_todaysQuest():
	var file = File.new()
	if file.file_exists(TodaysQuestFileName):		# 統計情報ファイル
		file.open(TodaysQuestFileName, File.READ)
		var data = file.get_var()
		tqSolvedYMD = data[0]
		tqSolvedSec = data[1]
		file.close()
	else:
		tqSolvedYMD = ""
		tqSolvedSec = [-1, -1, -1]
