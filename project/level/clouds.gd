extends MeshInstance3D

var mat:StandardMaterial3D

func _ready():
	mat = get_surface_override_material(0)

func _process(delta):
	mat.uv1_offset.x += delta/400.0
	mat.uv1_offset.y += delta/600.0
