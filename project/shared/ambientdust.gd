extends GPUParticles3D

var player

func _physics_process(_delta):
	if player:
		position = player.position - player.position.posmod(2.0)
	else:
		var players = get_tree().get_nodes_in_group("player")
		if len(players) > 0:
			player = players[0]
			
