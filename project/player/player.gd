extends RigidBody3D

@export var v_hop : float = 2.4
@export var a_hop : float = 0.2
@export var v_fly : float = 8.0
@export var a_fly : float = 0.02

var gravity : float = 8.0
var turn_speed : float = 4.0
var jump_velocity : float = -1.6
var speed : float = 0.0
var hop_blend = 0.0
const MAXHEIGHT = 24.0

@onready var money_label = $ui/money/money
var money = 15
var holding_trinket = false # trinket in mouth
var active_trinket = null
var active_hat = 0

@onready var visual_root = $visual_root
@onready var crow = $visual_root/crow
@onready var target_head = $cam_arm/cam/target_head
@onready var movement_dust = $visual_root/movement_dust

@onready var hop = $sfx/hop
@onready var fly = $sfx/fly
@onready var caw = $sfx/caw
@onready var land = $sfx/land

@onready var collision_shape_3d = $collisionshape
@onready var cam_arm = $cam_arm
@onready var cam = $cam_arm/cam
var env

const LAND_PARTICLES = preload("uid://clufifu3bdsfu")
const JUMP_PARTICLES = preload("uid://c2dp4v0sqt3fp")

var movement_input : Vector2 = Vector2.ZERO
var target_angle : float = 0.0
var last_movement_input : Vector2 = Vector2.ZERO

var _is_on_floor : bool = false
var _was_on_floor : bool = false
var _is_perched : bool = false
var _is_flying : bool = false
var _action_lock : bool = false
var _takeoff_lock : bool = false
var _landing_lock : bool = false

var birdhouse
@onready var hatmenu = $hatmenu
@onready var cam_2_arm = $hatmenu/SubViewportContainer/SubViewport/cam2_arm
@onready var ui = $ui
@onready var pause_ui = $pause
@onready var hostlabel = $hostlabel
var local_id
var init_state = false # for capturing mouse and other on client

@onready var raycast_landing = $raycast_landing

func _ready():
	#await get_tree().process_frame
	local_id = multiplayer.get_unique_id()
	#rpc("sync_hat",active_hat) # POSTJAM
	
	if get_multiplayer_authority() == local_id:
		
		var birdhouses = get_tree().get_nodes_in_group("birdhouse")
		for birdhouse in birdhouses:
			birdhouse.player_lookat.set_target_node(self.get_path())
		
		cam.make_current()
		crow.toggle_vis_layers()
		add_to_group("player")
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		env = get_tree().get_nodes_in_group("env")[0]
		# for quad shaders if we use	
		#quad_depth_material = quad_depth.get_active_material(0)
		#quad_depth_material.set_shader_parameter("depth_factor",fps_zoom)
		#camera_emission_material = quad_depth.get_active_material(3)
	else:
		cam.current = false
		movement_dust.visible = false
		ui.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	#if multiplayer.is_server() and not(multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		#hostlabel.visible = true
	
func _unhandled_input(event):
	#if not is_multiplayer_authority(): return
	if get_multiplayer_authority() != local_id: return
	if _action_lock:
		if event.is_action_pressed("e"):
			if hatmenu.visible:
				init_state = true
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				hatmenu.visible = false
				_action_lock = false
		
		if pause_ui.visible:
			if event.is_action_pressed("f1"):
				get_tree().quit()
		
	if event.is_action_pressed("esc"):
		init_state = true
		if hatmenu.visible:
			pass
		else:
			pause_ui.visible = !pause_ui.visible
			if pause_ui.visible:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				_action_lock = true
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				_action_lock = false
			
	
	if !_action_lock:
		if _is_on_floor:
			if event.is_action_pressed("e"):
				var birdhouses = get_tree().get_nodes_in_group("birdhouse")
				for birdhouse in birdhouses:
					if birdhouse.active:
						init_state = true
						birdhouse.active = false
						birdhouse.icon.visible = false
						hatmenu.visible = true
						_action_lock = true
						Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
						return
					
				
	if event.is_action_pressed("q"):
		if !_is_flying and (!_action_lock or hatmenu.visible):
			rpc("caw_emote")
			
			
func _process(_delta):
	sync_data()
	if get_multiplayer_authority() != local_id: return
	if not init_state and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		init_state = true
	crow.head_target.global_position = target_head.global_position
	cam_2_arm.global_position = global_position
	cam_2_arm.global_rotation = global_rotation
	
	if env:
		if _is_flying:
			env.environment.fog_depth_end = lerp (env.environment.fog_depth_end,64.0,0.002)
		else:
			env.environment.fog_depth_end = lerp (env.environment.fog_depth_end,32.0,0.016)

func _integrate_forces(state : PhysicsDirectBodyState3D):
	if get_multiplayer_authority() != local_id: return
	#if !ui.visible:
	var camera : Camera3D = get_viewport().get_camera_3d()
	if camera == null: return
	
	if !_action_lock:
		movement_input = Input.get_vector("left", "right", "up", "down").rotated(-camera.global_rotation.y)		
	else:
		movement_input = Vector2.ZERO
		
	var vel_2d = Vector2(state.linear_velocity.x, state.linear_velocity.z)
	var is_moving : bool = movement_input != Vector2.ZERO
	
	_is_on_floor = _get_is_on_floor(state)
		
	if _is_on_floor:
		if is_moving:
			speed = lerp(speed,v_hop,a_hop)
			vel_2d += movement_input * speed * 8.0 * state.step
			vel_2d = vel_2d.limit_length(speed)
			state.linear_velocity.x = vel_2d.x
			state.linear_velocity.z = vel_2d.y
			target_angle = -movement_input.orthogonal().angle()
			hop_blend = lerp(hop_blend,1.0,0.1)
		else:
			if _is_on_floor:
				crow.set_state("idle")
				speed = lerp(speed,0.0,a_hop)
				hop_blend = lerp(hop_blend,0.0,0.15)
		crow.animation_tree.set("parameters/hop/blend_amount", hop_blend)
				
	elif _is_flying:
		speed = lerp(speed,v_fly,a_fly)
		vel_2d += movement_input * speed * 4.0 * state.step
		vel_2d = vel_2d.limit_length(v_fly)
		state.linear_velocity.x = vel_2d.x
		state.linear_velocity.z = vel_2d.y
		target_angle = -vel_2d.orthogonal().angle()
		
	# takeoff and flap wings
	if Input.is_action_just_pressed("space") and !_action_lock:
		if _is_on_floor:
			takeoff()
			
			var direction = -visual_root.global_transform.basis.z  # forward direction
			var result_vector = direction.normalized()*v_hop*0.5
			state.linear_velocity.x = -result_vector.x
			state.linear_velocity.z = -result_vector.z
			
			
		elif _is_flying:
			crow.set_state("flap")
			
		var jump_particles = JUMP_PARTICLES.instantiate()
		add_sibling(jump_particles)
		jump_particles.global_transform = global_transform
		
		state.linear_velocity.y = -jump_velocity*2.0
		_is_flying = true
		_is_on_floor = false
		gravity = 1.0
		fly.play()

	var turn_rate = turn_speed if _is_on_floor else turn_speed*2.0
	visual_root.rotation.y = rotate_toward(visual_root.rotation.y, target_angle, turn_rate * state.step)
	
	# tilting
	if _is_flying and !_action_lock:
		if !is_moving:
			movement_input != Vector2.ZERO
			crow.rotation.z = lerp(crow.rotation.z,0.0,2.0*state.step)
		else:
			var move_angle = -movement_input.orthogonal().angle()
			var angle_diff = -angle_difference(visual_root.rotation.y, move_angle)/2.0
			crow.rotation.z = lerp(crow.rotation.z, angle_diff, 2.0 * state.step)
	else:
		crow.rotation.z = lerp(crow.rotation.z, 0.0, 4.0 * state.step)

	movement_dust.emitting = is_moving && !_is_on_floor
	
	if _is_flying:
		speed = lerp(speed,v_hop,a_hop)
	else:
		speed = lerp(speed,0.0,a_hop)


	# Add ground friction
	physics_material_override.friction = 0.0 if is_moving else 2.0

	if _is_flying:
		#state.linear_velocity.y -= gravity * state.step
		state.linear_velocity = state.linear_velocity.limit_length(v_fly)
		state.linear_velocity.y -= 1/(max(Vector2(linear_velocity.x,linear_velocity.z).length(),gravity))*state.step
		if Input.is_action_pressed("ctrl"):
			state.linear_velocity.y -= v_fly/2*state.step
		crow.y_target.position.y = lerp(crow.y_target.position.y,0.8+state.linear_velocity.y,0.1)
		if _takeoff_lock:
			state.linear_velocity.y = lerp(state.linear_velocity.y,0.0,0.01)
			
		

			
	else:
		state.linear_velocity.y -= gravity * state.step
		state.linear_velocity = state.linear_velocity.limit_length(gravity)
	
	
	cam_arm.spring_length = lerp(cam_arm.spring_length,2.0 + state.linear_velocity.length()/6,0.02)
	cam.fov = lerp(cam.fov,50 + state.linear_velocity.length()*3,0.02)
	
	# landing logic
	if _is_flying and !_landing_lock and !_takeoff_lock:
		if raycast_landing.is_colliding():
			var ray_normal = raycast_landing.get_collision_normal()
			if ray_normal.y > 0.75:
				#state.linear_velocity.x = v_hop*1.5
				state.linear_velocity.y = -3.0
				landing()
	elif _landing_lock:
		state.linear_velocity.y = lerp(state.linear_velocity.y,-gravity,0.08)
	#elif _takeoff_lock:
		#state.linear_velocity.y = lerp(state.linear_velocity.y,-jump_velocity,0.08)
		
	

	# Add ground collision feedback
	if !_was_on_floor && _is_on_floor:
		_on_hit_floor(state.linear_velocity.y)
		_is_flying = false
	_was_on_floor = _is_on_floor
	
	position.y = min(position.y,MAXHEIGHT)

func _get_is_on_floor(state : PhysicsDirectBodyState3D) -> bool:
	for col_idx in state.get_contact_count():
		var col_normal = state.get_contact_local_normal(col_idx)
		if col_normal.y > 0.2:
			return col_normal.dot(Vector3.UP) > -0.5
	return false

func _on_hit_floor(y_vel : float):
	y_vel = clamp(abs(y_vel), 0.0, gravity)
	var land_particles = LAND_PARTICLES.instantiate()
	add_sibling(land_particles)
	land_particles.global_transform = global_transform
	gravity = 7.0
	crow.y_target.position.y = 1.0

	
func pickup_trinket():
	#_action_lock = true
	holding_trinket = true
	crow.animation_tree.set("parameters/open/blend_amount", 1.0)
	crow.state_machine.start("pickup")
	
func dropoff_trinket():
	holding_trinket = false
	active_trinket = null
	crow.animation_tree.set("parameters/open/blend_amount", 0.0)
	money += 1
	money_label.text = str(money)
	
func takeoff():
	_action_lock = true
	_takeoff_lock = true
	var timer = Timer.new()
	timer.wait_time = 0.8 # seconds
	timer.one_shot = true  # timer runs once
	add_child(timer) 
	timer.timeout.connect(_on_takeoff_timeout)
	timer.start()
	
	position.y += 0.02
	crow.set_state("takeoff")
	
	hop_blend = 0.0
	crow.animation_tree.set("parameters/hop/blend_amount", hop_blend)
	
func _on_takeoff_timeout():
	_action_lock = false
	_takeoff_lock = false
	
func landing():
	_action_lock = true
	_landing_lock = true
	var timer = Timer.new()
	timer.wait_time = 0.6  # seconds
	timer.one_shot = true  # timer runs once
	add_child(timer)
	timer.timeout.connect(_on_landing_timeout)
	timer.start()
	
	crow.set_state("land")

func _on_landing_timeout():
	_action_lock = false
	_landing_lock = false
	crow.set_state("idle")
	if !land.playing:
		land.play()

@rpc("any_peer", "call_local", "reliable")
func caw_emote():
	crow.animation_tree.set("parameters/caw/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	caw.play()
	
@rpc("any_peer", "call_local", "reliable")
func sync_hat(id):
	#active_hat = 0 # POSTJAM
	crow.toggle_hat(id)

# sync data
const SYNC_LERP = 0.1 # lerp speed for all float variable syncing to reduce jagged movement
@onready var syncdata = $syncdata
var peer_id: int
func sync_data():
	if get_multiplayer_authority() != local_id:
		self.global_position = lerp(global_position,syncdata.pos,SYNC_LERP)
		self.global_rotation = lerp(self.global_rotation,syncdata.rot1,SYNC_LERP)
		visual_root.global_rotation = lerp(visual_root.global_rotation,syncdata.rot2,SYNC_LERP)
		crow.head_target.global_position = lerp(crow.head_target.global_position,syncdata.lookat,SYNC_LERP)
		
		hop_blend = syncdata.hop
		crow.animation_tree.set("parameters/hop/blend_amount", hop_blend)
		
		crow.set_state(syncdata.animation)

	else:
		syncdata.pos = global_position
		syncdata.rot1 = global_rotation
		syncdata.rot2 = visual_root.global_rotation
		syncdata.lookat = crow.head_target.global_position
		syncdata.hop = hop_blend
		syncdata.animation = crow.state_machine.get_current_node()
