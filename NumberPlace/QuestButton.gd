extends Node2D

var qNumber

func _ready():
	pass # Replace with function body.

func set_q_number(num):
	$Button.text = "#%06d" % num
