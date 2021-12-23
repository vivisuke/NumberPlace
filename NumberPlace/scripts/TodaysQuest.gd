extends Node2D

onready var g = get_node("/root/Global")

func _ready():
	g.todaysQuest = true
	g.load_todaysQuest()
	var today_string = g.today_string()
	if g.tqSolvedYMD != today_string:
		g.tqSolvedYMD = today_string
		g.tqSolvedSec = [-1, -1, -1]
	for i in range(3):
		if g.tqSolvedSec[i] >= 0:
			var btn = get_node("Button%d" % i)
			btn.set_button_icon($SolvedTexture.texture)
	$DateLabel.text = g.today_string()
	pass

func _on_BackButton_pressed():
	g.todaysQuest = false
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
