extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var MI = get_node("MeshInstance")
onready var Camera = get_node("Camera")

# Called when the node enters the scene tree for the first time.
func _ready():
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts = PoolVector3Array()
	var colors = PoolColorArray()
	var s = 1e3
	
	verts.resize(s)
	colors.resize(s)
	
	for n in range(s):
		verts[n] = Vector3(100.0 * n / s, 0, 0).rotated(Vector3(0,1,0), n)
		colors[n] = Color(1, 1, 1, 1)
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	get_node("MeshInstance").mesh = mesh;

var from = Vector3(5, 1, 0)
func _process(delta):
	from = from.rotated(Vector3(0, 1, 0), delta / 10.0)
	Camera.translation = from
	Camera.look_at(Vector3(0, 0, 0), Vector3(0, 1, 0))
