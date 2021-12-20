extends ReferenceRect

signal pressed(num)

var number

func _ready():
	pass # Replace with function body.

func set_q_number(num):
	number = num
	$Button.text = "#%06d" % num
func set_enabled(f):
	$Button.disabled = !f
func set_icon(icon):
	$Button.set_button_icon(icon)
func solved_set_visible(b):
	if b:
		$Solved.show()
	else:
		$Solved.hide()
func _on_Button_pressed():
	emit_signal("pressed", number)
	pass # Replace with function body.
