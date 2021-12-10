extends Node2D

var buttons = []
onready var g = get_node("/root/Global")

func sec_to_MSStr(t):
	var sec = t % 60
	var mnt = t / 60
	return "%02d:%02d" % [mnt, sec]
func _ready():
	for i in range(3):
		buttons.push_back(get_node("Button%d" % i))
	load_stats()
	for i in range(3):
		var n = g.stats[i]["NSolved"] if g.stats[i].has("NSolved") else 0
		buttons[i].get_node("NSolvedLabel").text = "クリア回数: %d" % n
		var txt = "平均タイム: "
		if n == 0:
			txt += "N/A"
		else:
			var avg : int = int(g.stats[i]["TotalSec"] / n)
			txt += sec_to_MSStr(avg)
		buttons[i].get_node("AveTimeLabel").text = txt
		txt = "最短タイム: "
		if g.stats[i].has("BestTime"):
			txt += sec_to_MSStr(g.stats[i]["BestTime"])
		else:
			txt += "N/A"
		buttons[i].get_node("BestTimeLabel").text = txt
	if !g.qRandom:
		$LineEdit.text = g.qName
	pass # Replace with function body.

func load_stats():
	var file = File.new()
	if file.file_exists(g.StatsFileName):		# 統計情報ファイル
		file.open(g.StatsFileName, File.READ)
		g.stats = file.get_var()
		file.close()
	else:
		g.stats = [{}, {}, {}, ]		# [0] for 入門問題生成
	print(g.stats)
func to_MainScene(qLevel):
	print($LineEdit.text)
	g.qLevel = qLevel
	g.qName = $LineEdit.text
	g.qRandom = $LineEdit.text == ""
	get_tree().change_scene("res://MainScene.tscn")
	pass # Replace with function body.

func _on_Button0_pressed():
	to_MainScene(0)
	pass # Replace with function body.

func _on_Button1_pressed():
	to_MainScene(1)
	pass # Replace with function body.

func _on_Button2_pressed():
	to_MainScene(2)
	pass # Replace with function body.
