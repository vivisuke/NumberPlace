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
	var ix0 = max(0, g.nSolved[g.qLevel] - 9)
	for i in range(16):
		var btn = QuestPanel.instance()
		panels.push_back(btn)
		if ix0 + i <= g.nSolved[g.qLevel]:
			btn.set_enabled(true)
			btn.set_icon($LockOpen.texture)
			btn.solved_set_visible(ix0 + i < g.nSolved[g.qLevel])
		else:
			btn.set_enabled(false)
			btn.solved_set_visible(false)
		btn.set_q_number(ix0 + i + 1)
		$ScrollContainer/VBoxContainer.add_child(btn)
		btn.connect("pressed", self, "_on_QuestButton_pressed")
	
func _process(delta):
	if !autoScrolled:
		autoScrolled = true
		var ix0 = max(0, g.nSolved[g.qLevel] - 9)
		var ix = g.nSolved[g.qLevel] - ix0 + 1		# +1 for 次の問題まで表示
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
