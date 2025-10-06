extends Node3D

@onready var mesh = $crow
#@onready var player_mesh = $player2/Rig/Skeleton3D/player
#@onready var physical_bone_simulator_3d = %PhysicalBoneSimulator3D
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

@onready var lookat_head = $crow/Armature/Skeleton3D/lookat_head
@onready var head_target = $head_target
@onready var y_target = $y_target

@onready var hat_glasses = $"crow/Armature/Skeleton3D/hat-glasses"
@onready var hat_earrings = $"crow/Armature/Skeleton3D/hat-earrings"
@onready var hat_shindigs = $"crow/Armature/Skeleton3D/hat-shindigs"
@onready var hat_cowboy = $"crow/Armature/Skeleton3D/hat-cowboy"

signal footstep(intensity : float)

func _ready():
	pass
	
func set_state(state_name : String,insta : bool = false) -> void:
	if insta:
		state_machine.start(state_name)
	else:
		state_machine.travel(state_name)
		
@onready var skeleton_3d = $crow/Armature/Skeleton3D
func toggle_vis_layers():
	for child in skeleton_3d.get_children():
		if child is MeshInstance3D:
			child.set_layer_mask_value(2,true)

func emit_footstep(intensity : float = 1.0) -> void:
	footstep.emit(intensity)

func hide_hats():
	hat_glasses.visible = false
	hat_earrings.visible = false
	hat_shindigs.visible = false
	hat_cowboy.visible = false	

func toggle_hat(id):
	hide_hats()
	match id:
		1:
			hat_glasses.visible = true
		2:
			hat_earrings.visible = true
		3:
			hat_shindigs.visible = true
		4:
			hat_cowboy.visible = true
