extends ReferenceRect

signal pressed(num)

var number

func _ready():
	pass # Replace with function body.

func set_q_number(num):
	number = num
	$Button.text = "#%06d" % num

func _on_Button_pressed():
	emit_signal("pressed", number)
	pass # Replace with function body.
