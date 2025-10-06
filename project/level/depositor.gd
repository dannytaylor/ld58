extends Node3D

var active = false
var player
@onready var icon = $depo_area/icon
@onready var spawnpoint = $depositor2/spawnpoint
@onready var sfx = $sfx

func _unhandled_input(event):
	if active:
		if event.is_action_released('mouse_left'):
			if player.holding_trinket:
				var trinket = player.active_trinket
				player.dropoff_trinket()
				
				trinket.reparent(spawnpoint)
				trinket.global_position = spawnpoint.global_position
				trinket.trinkets.scale = Vector3(0.5,0.5,0.5)
				trinket.rigid.freeze = false
				trinket.rigid.set_collision_layer_value(2,true)
				trinket.rigid.set_collision_mask_value(2,true)
				sfx.play()
				icon.visible = false

func _on_depo_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		active = true
		if player.holding_trinket:
			icon.visible = true

func _on_depo_area_body_exited(body):
	if body.is_in_group("player"):
		player = body
		active = false
		icon.visible = false
