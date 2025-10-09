extends Node3D


# for godot networking
var PORT = 11999
var SERVER = "127.0.0.1"
const MAX_CONNECTIONS = 24
const RETRY_INTERVAL = 5.0  # seconds
const MAX_RETRIES = 2

var player_ids = []
var enet_peer = ENetMultiplayerPeer.new()
var offline_player = null
var offline_mode = false

@onready var spawner = $SubViewportContainer/SubViewport/spawner
@onready var spawnpoint = $SubViewportContainer/SubViewport/spawnpoint
const PLAYER = preload("uid://bk2otpj8llnek")
const TRINKET = preload("uid://bcq72stfb7t3v")

@onready var network_debug = $SubViewportContainer/SubViewport/network_debug

func _ready():
	var config = ConfigFile.new()
	var err = config.load("res://shared/server.cfg")
	SERVER = config.get_value("SERVER","IP")
	PORT = config.get_value("SERVER","PORT")
	
	var args = OS.get_cmdline_args()
	var is_server = "--server" in args
	spawner.spawn_function = _spawn_player
	
	if is_server:
		multiplayer_host()
		return
	
	multiplayer_join(SERVER)
	

@rpc("call_remote")
func update_debug_text(count):
	network_debug.text = '(%s)' % str(count)

func _spawn_player(id: int):
	var player := PLAYER.instantiate()
	player.set_multiplayer_authority(id)
	player.peer_id = id
	return player
		
func multiplayer_host():
	# create enet server
	if offline_mode:
		enet_peer.create_server(PORT+1,1)
	else:
		enet_peer.create_server(PORT,MAX_CONNECTIONS)
	multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(despawn_player)
	
	# server crow
	if offline_mode:
		spawner.spawn(1)
	
func multiplayer_join(address):
	# client connect to host at IP
	enet_peer.create_client(address,PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	#var id = multiplayer.get_unique_id()
	#local_player.set_multiplayer_authority(id)
	#spawner.spawn(id)
	await get_tree().create_timer(0.5).timeout
	if enet_peer.get_connection_status() != ENetMultiplayerPeer.CONNECTION_CONNECTED:
		enet_peer.close()
		multiplayer.multiplayer_peer = null
		var my_id = multiplayer.get_unique_id()
		offline_player = spawner.spawn(my_id)
		player_ids.append(my_id)
		
		offline_mode = true
		multiplayer_host()
		
		network_debug.text = "offline"
	else:
		multiplayer.peer_connected.connect(_on_peer_connected)



func _on_peer_connected(id):
	print('Peer connected: %s' % str(id))
	# only the server should handle spawning
	if not multiplayer.is_server():
		return
	
	if id not in player_ids:
		player_ids.append(id)
	
	# spawn the new player
	spawner.spawn(id)
	rpc("update_debug_text",len(multiplayer.get_peers()))
	
func despawn_player(id):
	print('Peer disconnected: %s' % str(id))
	var active_players = get_tree().get_nodes_in_group('players')
	print('Remaining players: %s' % str(len(active_players)))
	
	# only server handles despawning
	if not multiplayer.is_server():
		return
		
	player_ids.erase(id)

	for p in active_players:
		print(p.get_multiplayer_authority())
		if p.get_multiplayer_authority() == id:
			p.queue_free()
	
	rpc("update_debug_text",len(multiplayer.get_peers()))
