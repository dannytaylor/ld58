extends Node3D

@onready var trinkets = $rigid/trinkets
const MAT_TRINKET = preload("uid://ln2l5comkdpa")
var trinket:MeshInstance3D

var picked_up = false
var active = false
var player:Node
@onready var pickup_area = $pickup_area
@onready var icon = $icon
@onready var rigid = $rigid

@onready var sfx = $sfx

func _ready():
	var children = trinkets.get_children()
	trinket = children.pick_random()
	trinket.visible = true
	trinket.set_surface_override_material(0,MAT_TRINKET)
	
func _unhandled_input(event):
	if player:
		#if not is_multiplayer_authority(): return
		if !picked_up and active:
			if event.is_action_released('mouse_left'):
				if !player.holding_trinket:
					#print('pickup')
					sfx.play()
					attach_to_player()
			

func attach_to_player():
	active = false
	pickup_area.monitoring = false
	picked_up = true
	icon.visible = false
	
	var target = player.find_child("trinket_target")
	global_position = target.global_position
	global_rotation = target.global_rotation
	reparent(target)
	trinket.set_surface_override_material(0,null)
	
	player.active_trinket = self
	player.pickup_trinket()

func _on_pickup_area_body_exited(body):
	if body.is_in_group("player"):
		#print('exited')
		player = body
		active = false
		icon.visible = false

func _on_pickup_area_body_entered(body):
	if body.is_in_group("player"):
		#print('entered')
		player = body
		active = true
		if !player.holding_trinket:
			icon.visible = true
