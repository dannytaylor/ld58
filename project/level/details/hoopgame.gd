extends Node3D

@export var prize:int = 1
@export var timeout:float = 3.0

@export var hoops:Array[Node3D]
@onready var resettimer = $resettimer
var total = 0
var score = 0

func _ready():
	total = len(hoops)
	for hoop in hoops:
		hoop.hoop_triggered.connect(next_hoop)
	reset_hoops()
	
func reset_hoops():
	score = 0
	for hoop in hoops:
		hoop.reset(false)
	hoops[0].reset(true)

func _on_resettimer_timeout():
	if score < total:
		hoops[score].sfx_lose.play()
	resettimer.stop()
	reset_hoops()
		
func next_hoop():
	score += 1
	resettimer.start(timeout)
	if score == total:
		resettimer.stop()
		hoops[score-1].sfx_win.play()
		reset_hoops()
		var p = get_tree().get_nodes_in_group("player")[0]
		p.money += prize
		p.money_label.text = str(p.money)
		
	else:
		hoops[score].anim.play('activate')
		hoops[score].sfx.pitch_scale = 1.0 + score/total
