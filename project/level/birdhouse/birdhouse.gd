extends Node3D
@onready var player_lookat = $birdhouse/eyebone/Skeleton3D/player_lookat

var player
@onready var icon = $buy_area/icon
var active

#func _ready():
	#var players = get_tree().get_nodes_in_group("player")
	#player = players[0]
	#player_lookat.set_target_node(player.get_path())


func _on_buy_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		active = true
		icon.visible = true


func _on_buy_area_body_exited(body):
	if body.is_in_group("player"):
		player = body
		active = false
		icon.visible = false
