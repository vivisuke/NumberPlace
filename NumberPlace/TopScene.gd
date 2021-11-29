extends Node2D

onready var g = get_node("/root/Global")

func _ready():
	$LineEdit.text = g.qName
	pass # Replace with function body.

func to_MainScene(qLevel):
	print($LineEdit.text)
	g.qLevel = qLevel
	g.qName = $LineEdit.text
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
