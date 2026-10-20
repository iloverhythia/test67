extends Node
# Web-only fixes. Does nothing in desktop builds.
#
# The web page uses the GLES2 renderer on iPhone/iPad, because Godot 3's GLES3
# renderer crashes there ("WebGL context lost"). GLES2 can't draw GPU particles,
# so the scenes below get CPU particles instead.

const PARTICLE_SCENES = [
	"res://assets/notefx/miss/miss.tscn",
	"res://assets/notefx/shards/shards.tscn",
	"res://assets/notefx/ripple/ripple.tscn",
	"res://assets/worlds/event_horizon/event_horizon.tscn",
	"res://assets/worlds/space/rainbow_road.tscn",
	"res://assets/worlds/grid/cube.tscn",
	"res://assets/worlds/reality_dismissed/reality_dismissed.tscn",
	"res://assets/worlds/reality_dismissed/reality_dismissed_dark.tscn",
]

# Converted scenes stay referenced so the resource cache keeps serving them
var _converted:Array = []

func _ready():
	if !OS.has_feature("HTML5"): return
	if OS.get_current_video_driver() != OS.VIDEO_DRIVER_GLES2: return
	for path in PARTICLE_SCENES:
		if ResourceLoader.exists(path):
			_convert_scene(path)
	print("WebCompat: using CPU particles in ", _converted.size(), " scenes")

func _convert_scene(path:String):
	var ps:PackedScene = load(path)
	if ps == null: return
	var state:SceneState = ps.get_state()
	var root:Node = ps.instance()
	var changed:bool = false
	for i in range(state.get_node_count()):
		var node:Node = root.get_node_or_null(state.get_node_path(i))
		if (node is Particles or node is Particles2D) and node.get_script() == null:
			var cpu:Node = _replace(node, root, _scene_emitting(state, i))
			if node == root: root = cpu
			changed = true
	if changed:
		var out:PackedScene = PackedScene.new()
		if out.pack(root) == OK:
			# Detach the original first. Otherwise, when it is freed, it removes
			# the converted scene from the resource cache too.
			ps.resource_path = ""
			out.take_over_path(path)
			_converted.append(out)
		else:
			print("WebCompat: could not repack ", path)
	root.free()

# GLES2 can't report a GPU particle node's emitting state, so read it from the scene file
func _scene_emitting(state:SceneState, idx:int) -> bool:
	for p in range(state.get_node_property_count(idx)):
		if state.get_node_property_name(idx, p) == "emitting":
			return bool(state.get_node_property_value(idx, p))
	return true # Godot's default

# Swaps a GPU particle node for a CPU one and returns the new node
func _replace(old:Node, root:Node, emitting:bool) -> Node:
	var cpu:Node
	if old is Particles:
		cpu = CPUParticles.new()
		cpu.convert_from_particles(old)
		cpu.transform = old.transform
		cpu.material_override = old.material_override
		cpu.cast_shadow = old.cast_shadow
	else:
		cpu = CPUParticles2D.new()
		cpu.convert_from_particles(old)
		cpu.transform = old.transform
		cpu.material = old.material
		cpu.z_index = old.z_index
	cpu.visible = old.visible
	cpu.emitting = emitting
	var is_root:bool = old == root
	var new_owner:Node = cpu if is_root else root
	var kids:Array = old.get_children()
	cpu.name = old.name
	if !is_root:
		var parent:Node = old.get_parent()
		var idx:int = old.get_index()
		parent.remove_child(old)
		parent.add_child(cpu)
		parent.move_child(cpu, idx)
		cpu.owner = root
	for k in kids:
		old.remove_child(k)
		cpu.add_child(k)
		_set_owner_recursive(k, new_owner)
	old.free()
	return cpu

func _set_owner_recursive(n:Node, root:Node):
	n.owner = root
	for c in n.get_children():
		if c.filename == "": _set_owner_recursive(c, root)
		else: c.owner = root
