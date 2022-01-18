extends Node2D

const INIT_N_COINS = 10
const DAYLY_N_COINS = 2
const TODAYS_QUEST_N_COINS = 3
const KEY_N_COINS = "nCoins"
const KEY_LOGIN_DATE = "LoginDate"

var env = {}			# 環境辞書
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
var tqConsYesterdayDays = 0			# 昨日までの連続クリア日数
var tqConsSolvedDays = 0			# 連続クリア日数
var tqMaxConsSolvedDays = 0			# 最大連続クリア日数
var elapsedTime = 0.0   	# 経過時間（単位：秒）

var show_hint_guide = false
var hint_pos : int = -1			# ヒントで数字が入る位置
var hint_bit : int = 0		# ヒントで入る数字ビット
var hint_type : int = -1
var candidates_bit = []		# 入力可能ビット論理和
var cell_bit = []			# 現在の状態
var saved_data = {}			# 自動保存データ

const AutoSaveFileName	= "user://NumberPlace_autosave.dat"		# 自動保存ファイル
const EnvFileName	= "user://NumberPlace_env.dat"				# 環境ファイル
const SettingsFileName	= "user://NumberPlace_stgs.dat"
const StatsFileName		= "user://NumberPlace_stats.dat"
const NSolvedFileName	= "user://NumberPlace_nSolved.dat"
const TodaysQuestFileName	= "user://NumberPlace_todaysQuest.dat"

func _ready():
	pass # Replace with function body.
#
func sec_to_MSStr(t):
	var sec = t % 60
	var mnt = t / 60
	return "%02d:%02d" % [mnt, sec]
#
func today_string():
	var d = OS.get_date()
	return "%04d/%02d/%02d" % [d["year"], d["month"], d["day"]]
func yesterday_string():
	var u = OS.get_unix_time_from_datetime(OS.get_datetime())
	var y = OS.get_datetime_from_unix_time(u - 60*60*24)	# 24時間前
	return "%04d/%02d/%02d" % [y["year"], y["month"], y["day"]]
#
func auto_load():
	var file = File.new()
	if !file.file_exists(AutoSaveFileName):
		saved_data = {}
	else:
		file.open(AutoSaveFileName, File.READ)
		saved_data = file.get_var()
		file.close()
	return saved_data
func auto_save(solving : bool, board : Array):
	if !solving:
		saved_data = {}
	else:
		#var data = {}
		saved_data["solving"] = solving
		saved_data["board"] = board
		saved_data["today"] = today_string()
		saved_data["qLevel"] = qLevel
		saved_data["qNumber"] = qNumber
		saved_data["qName"] = qName
		saved_data["qRandom"] = qRandom
		saved_data["elapsedTime"] = elapsedTime
		saved_data["todaysQuest"] = todaysQuest
	var file = File.new()
	file.open(AutoSaveFileName, File.WRITE)
	file.store_var(saved_data)
	file.close()
#
func load_environment():
	var file = File.new()
	if file.file_exists(EnvFileName):		# 設定ファイル
		file.open(EnvFileName, File.READ)
		env = file.get_var()
		file.close()
	if !env.has(KEY_N_COINS): env[KEY_N_COINS] = INIT_N_COINS
	if env[KEY_N_COINS] < 0: env[KEY_N_COINS] = 0
	if env[KEY_N_COINS] == 0: env[KEY_N_COINS] = 50		# for Test
func save_environment():
	var file = File.new()
	file.open(EnvFileName, File.WRITE)
	file.store_var(env)
	file.close()
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
	file.store_var([tqSolvedYMD, tqSolvedSec, tqConsSolvedDays, tqMaxConsSolvedDays])
	file.close()
func load_todaysQuest():
	var file = File.new()
	if file.file_exists(TodaysQuestFileName):		# 統計情報ファイル
		file.open(TodaysQuestFileName, File.READ)
		var data = file.get_var()
		print("today's data = ", data)
		tqSolvedYMD = data[0]
		tqSolvedSec = data[1]
		if data.size() >= 4:
			tqConsSolvedDays = data[2]
			tqMaxConsSolvedDays = data[3]
		else:
			tqConsSolvedDays = 0
			tqMaxConsSolvedDays = 0
		file.close()
	else:
		tqSolvedYMD = ""
		tqSolvedSec = [-1, -1, -1]
