extends Node2D

var settings = {}		# 設定辞書
var qLevel = 0			# 問題レベル [0, 1, 2]
var qName = ""			# 問題名

var show_hint_guide = false
var hint_pos : int = -1			# ヒントで数字が入る位置
var hint_bit : int = 0		# ヒントで入る数字ビット
var hint_type : int = -1
var candidates_bit = []		# 入力可能ビット論理和
var cell_bit = []			# 現在の状態

const settingsFileName = "user://NumberPlace_stgs.dat"

func _ready():
	pass # Replace with function body.
