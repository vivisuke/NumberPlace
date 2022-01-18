extends Node2D

onready var g = get_node("/root/Global")

func _ready():
	g.todaysQuest = true
	$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
	g.load_todaysQuest()
	var today_string = g.today_string()
	if g.tqSolvedYMD != today_string:		# 日付が変わっている場合
		if g.tqSolvedYMD == g.yesterday_string():	# 昨日までの記録がある場合
			g.tqConsYesterdayDays = g.tqConsSolvedDays
		else:
			g.tqConsYesterdayDays = 0
		g.tqConsSolvedDays = 0				# 連続クリア日数
		g.tqSolvedYMD = today_string
		g.tqSolvedSec = [-1, -1, -1]
	$ConsDaysLabel.text = "連続クリア日数：%d" % g.tqConsSolvedDays
	$ConsYesterdayLabel.text = "昨日の連続クリア日数：%d" % g.tqConsYesterdayDays
	$MaxConsDaysLabel.text = "最大連続クリア日数：%d" % g.tqMaxConsSolvedDays
	for i in range(3):
		if g.tqSolvedSec[i] >= 0:
			var btn = get_node("Button%d" % i)
			btn.set_button_icon($SolvedTexture.texture)
			var tm = "N/A" if g.tqSolvedSec[i] < 0 else g.sec_to_MSStr(g.tqSolvedSec[i])
			get_node("Button%d/TimeLabel" % i).text = tm
	$DateLabel.text = g.today_string()
	#
	#print(g.yesterday_string())
	pass

func _on_BackButton_pressed():
	g.todaysQuest = false
	g.qName = ""
	get_tree().change_scene("res://TopScene.tscn")
	pass

func to_MainScene(qLevel):
	g.qLevel = qLevel
	g.qRandom = false
	g.qNumber = 0
	g.qName = g.today_string()
	get_tree().change_scene("res://MainScene.tscn")
func _on_Button0_pressed():
	to_MainScene(0)
func _on_Button1_pressed():
	to_MainScene(1)
func _on_Button2_pressed():
	to_MainScene(2)
