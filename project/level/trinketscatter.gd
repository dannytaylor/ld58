extends Node3D

const TRINKET = preload("uid://bcq72stfb7t3v")
@export var scatter_count: int = 128
@export var scatter_area: Vector2 = Vector2(-150, 150)  # X and Z bounds
@export var height_offset: float = 24.0  # plus/minus
@export var surface_normal_threshold: float = 0.7

func _ready():
	scatter_objects()

func scatter_objects():
	var space_state = get_world_3d().direct_space_state

	for i in scatter_count:
		# Generate random X,Z position within scatter area
		var random_x = randf_range(-scatter_area.x, scatter_area.x)
		var random_z = randf_range(-scatter_area.y, scatter_area.y)

		# Cast ray downward from high above
		var from = Vector3(random_x, height_offset, random_z)
		var to = Vector3(random_x, -height_offset, random_z)

		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)

		if result:
			var surface_normal = result.normal
			if surface_normal.y >= surface_normal_threshold:
				spawn_object_at_position(result.position, surface_normal)

func spawn_object_at_position(position: Vector3, normal: Vector3):
	var instance = TRINKET.instantiate()
	add_child(instance)
	instance.scale = Vector3.ONE*0.35
	
	instance.global_position = position
	#instance.look_at(position + normal, Vector3.UP)
