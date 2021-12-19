extends Node2D

var autoScrolled = false
var panels = []

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
	g.load_nSolved()
	for i in range(16):
		var btn = QuestPanel.instance()
		panels.push_back(btn)
		if i <= g.nSolved[g.qLevel]:
			btn.set_enabled(true)
		else:
			btn.set_enabled(false)
			btn.set_icon($LockOpen.texture)
		btn.set_q_number(i + 1)
		$ScrollContainer/VBoxContainer.add_child(btn)
		btn.connect("pressed", self, "_on_QuestButton_pressed")
	
func _process(delta):
	if !autoScrolled:
		autoScrolled = true
		var ix = g.nSolved[g.qLevel] + 1		# +1 for 次の問題まで表示
		print(ix)	
		$ScrollContainer.ensure_control_visible(panels[ix])
		#$ScrollContainer.set_v_scroll(ix * 90)

func _on_BackButton_pressed():
	get_tree().change_scene("res://TopScene.tscn")
	pass # Replace with function body.
func _on_QuestButton_pressed(num):
	g.qNumber = num
	get_tree().change_scene("res://MainScene.tscn")
	pass # Replace with function body.
