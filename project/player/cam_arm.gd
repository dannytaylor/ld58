extends SpringArm3D

var active : bool = true : set = set_active
@onready var player = $".."

@export_range(-90.0, 90.0, 0.1, "radians") var min_limit_x : float
@export_range(-90.0, 90.0, 0.1, "radians") var max_limit_x : float

func _ready():
	if get_multiplayer_authority() != player.local_id: return
	Input.set_use_accumulated_input(false)
	set_active(active)

func set_active(state : bool):
	if get_multiplayer_authority() != player.local_id: return
	active = state
	set_process_input(active)
	set_process(active)

func _input(event):
	if get_multiplayer_authority() != player.local_id: return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	if event is InputEventMouseMotion: 
		var viewport_transform: Transform2D = get_tree().root.get_final_transform()
		var mouse_motion = event.xformed_by(viewport_transform).relative
		rotate_from_vector(mouse_motion * 0.0025)

#func _process(delta):
	#var joy_dir = Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	#rotate_from_vector(joy_dir * Vector2(1.0, 0.5) * 2.0 * delta)

func rotate_from_vector(v : Vector2):
	if v.length() == 0: return
	rotation.y -= v.x
	rotation.x -= v.y
	rotation.x = clamp(rotation.x, min_limit_x, max_limit_x)
