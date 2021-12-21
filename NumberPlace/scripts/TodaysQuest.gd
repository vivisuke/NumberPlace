extends Node2D

onready var g = get_node("/root/Global")

func _ready():
	g.todaysQuest = true
	pass

func _on_BackButton_pressed():
	g.todaysQuest = false
	get_tree().change_scene("res://TopScene.tscn")
	pass

func to_MainScene(qLevel):
	g.qLevel = qLevel
	g.qRandom = false
	g.qNumber = 0
	var d = OS.get_date()
	g.qName = "%04d/%02d/%02d" % [d["year"], d["month"], d["day"]]
	get_tree().change_scene("res://MainScene.tscn")
func _on_Button0_pressed():
	to_MainScene(0)
func _on_Button1_pressed():
	to_MainScene(1)
func _on_Button2_pressed():
	to_MainScene(2)
