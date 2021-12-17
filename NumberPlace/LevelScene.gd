extends Node2D

onready var g = get_node("/root/Global")


func _ready():
	for i in range(100):
		var btn = Button.new()
		btn.text = "Quest %d" % (i+1)
		$ScrollContainer/VBoxContainer.add_child(btn)
		btn.connect("pressed", self, "_on_QuestButton_pressed")
	pass # Replace with function body.



func _on_BackButton_pressed():
	get_tree().change_scene("res://TopScene.tscn")
	pass # Replace with function body.
func _on_QuestButton_pressed():
	g.qNumber = 1	# 暫定コード
	get_tree().change_scene("res://MainScene.tscn")
	pass # Replace with function body.
