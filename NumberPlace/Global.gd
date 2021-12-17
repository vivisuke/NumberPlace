extends Node2D

var settings = {}		# 設定辞書
var stats = []			# 各問題レベルごとの統計情報（問題クリア数、トータルタイム（単位：秒））
var qLevel = 0			# 問題レベル [0, 1, 2]
var qNumber = 0			# [1, 2^10] for 問題番号、0 for 非問題集
var qName = ""			# 問題名
var qRandom = true		# ランダム生成問題か？

var show_hint_guide = false
var hint_pos : int = -1			# ヒントで数字が入る位置
var hint_bit : int = 0		# ヒントで入る数字ビット
var hint_type : int = -1
var candidates_bit = []		# 入力可能ビット論理和
var cell_bit = []			# 現在の状態

const SettingsFileName	= "user://NumberPlace_stgs.dat"
const StatsFileName		= "user://NumberPlace_stats.dat"

func _ready():
	pass # Replace with function body.
