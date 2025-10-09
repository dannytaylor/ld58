extends Node3D

@onready var sfx = $sfx
@onready var sfx_lose = $sfx_lose
@onready var sfx_win = $sfx_win
@onready var arrow = $arrow

@onready var area = $Area3D
@onready var anim = $AnimationPlayer

signal hoop_triggered()

func reset(state = false):
	area.monitoring = state
	visible = state
	sfx.pitch_scale = 1.0
	if state:
		arrow.visible = true
		anim.play("activate")
	else:
		arrow.visible = false

func _on_area_3d_body_exited(body):
	if area.monitoring:
		if body.is_in_group("player"):
			anim.play("deactivate")
			hoop_triggered.emit()
