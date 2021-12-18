extends Node2D

onready var g = get_node("/root/Global")

#var QuestButton = load("res://QuestButton.tscn")
var QuestPanel = load("res://QuestPanel.tscn")


func _ready():
	var txt = ""
	if g.qLevel == 0: txt = "入門"
	elif g.qLevel == 1: txt = "初級"
	elif g.qLevel == 2: txt = "初中級"
	txt += "問題集"
	$TitleBar/Label.text = txt
	for i in range(20):
		#var btn = Button.new()
		#btn.text = "Quest %d" % (i+1)
		#var btn = QuestButton.instance()
		var btn = QuestPanel.instance()
		btn.set_q_number(i + 1)
		$ScrollContainer/VBoxContainer.add_child(btn)
		btn.connect("pressed", self, "_on_QuestButton_pressed")
	pass # Replace with function body.



func _on_BackButton_pressed():
	get_tree().change_scene("res://TopScene.tscn")
	pass # Replace with function body.
func _on_QuestButton_pressed(num):
	g.qNumber = num
	get_tree().change_scene("res://MainScene.tscn")
	pass # Replace with function body.
