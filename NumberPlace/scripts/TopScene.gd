extends Node2D

var buttons = []
onready var g = get_node("/root/Global")

#func sec_to_MSStr(t):
#	var sec = t % 60
#	var mnt = t / 60
#	return "%02d:%02d" % [mnt, sec]
func _ready():
	g.load_environment()
	if !g.env.has(g.KEY_LOGIN_DATE) || g.env[g.KEY_LOGIN_DATE] != g.today_string():
		g.env[g.KEY_LOGIN_DATE] = g.today_string()
		g.env[g.KEY_N_COINS] += g.DAYLY_N_COINS
		g.save_environment()
	$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
	g.load_stats()
	var data = g.auto_load()
	print("auto_loaded: ", data)
	if data != {} && data.has("solving") && data["solving"]:
		g.qLevel = data["qLevel"]
		g.qNumber = data["qNumber"]
		g.qName = data["qName"]
		g.qRandom = data["qRandom"]
		g.todaysQuest = data["todaysQuest"]
		if g.todaysQuest:
			if data["today"] == g.today_string():	# 今日の問題 && 日付が変わっていない場合
				print("todaysQuest")
				get_tree().change_scene("res://MainScene.tscn")
				return
			else:
				g.qName = ""
		else:
			get_tree().change_scene("res://MainScene.tscn")
			return
	g.auto_save(false, [])
	g.saved_data = {}
	for i in range(6):
		buttons.push_back(get_node("Button%d" % i))
	for i in range(6):
		var n = g.stats[i]["NSolved"] if g.stats[i].has("NSolved") else 0
		buttons[i].get_node("NSolvedLabel").text = "クリア回数: %d" % n
		var txt = "平均タイム: "
		if n == 0:
			txt += "N/A"
		else:
			var avg : int = int(g.stats[i]["TotalSec"] / n)
			txt += g.sec_to_MSStr(avg)
		buttons[i].get_node("AveTimeLabel").text = txt
		txt = "最短タイム: "
		if g.stats[i].has("BestTime"):
			txt += g.sec_to_MSStr(g.stats[i]["BestTime"])
		else:
			txt += "N/A"
		buttons[i].get_node("BestTimeLabel").text = txt
	if !g.qRandom:
		$LineEdit.text = g.qName
	pass # Replace with function body.

func to_MainScene(qLevel):
	print($LineEdit.text)
	g.qLevel = qLevel
	g.qName = $LineEdit.text
	g.qRandom = $LineEdit.text == ""
	g.qNumber = 0
	get_tree().change_scene("res://MainScene.tscn")
	pass # Replace with function body.
func to_LevelScene(qLevel):
	print($LineEdit.text)
	g.qLevel = qLevel
	g.qName = $LineEdit.text
	g.qRandom = $LineEdit.text == ""
	get_tree().change_scene("res://LevelScene.tscn")

func _on_Button0_pressed():
	to_MainScene(0)
func _on_Button1_pressed():
	to_MainScene(1)
func _on_Button2_pressed():
	to_MainScene(2)
func _on_Button3_pressed():
	to_LevelScene(0)
func _on_Button4_pressed():
	to_LevelScene(1)
func _on_Button5_pressed():
	to_LevelScene(2)


func _on_Button6_pressed():
	get_tree().change_scene("res://TodaysQuest.tscn")
	pass # Replace with function body.
