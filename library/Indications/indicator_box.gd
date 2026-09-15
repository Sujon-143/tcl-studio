@tool
extends BaseNode3D
class_name IndicatorBox

@export_category("Indication Settings")
@export var indication_targets: Array[NodePath]:
	set(value):
		indication_targets = value
		if Engine.is_editor_hint():
			call_deferred("_rebuild")

@export var box_color: Color = Color(0.784, 0.259, 0.349, 0.25):
	set(value):
		box_color = value
		if Engine.is_editor_hint():
			call_deferred("_rebuild")

var _boxes: Array[MeshInstance3D] = []

# ─────────────────────────────────────────────
#  Lifecycle
# ─────────────────────────────────────────────

func _ready() -> void:
	if Engine.is_editor_hint():
		_rebuild()

# ─────────────────────────────────────────────
#  Build / Destroy
# ─────────────────────────────────────────────

func _rebuild() -> void:
	_clear_boxes()
	for path in indication_targets:
		if path == NodePath("") or not has_node(path):
			continue
		var node := get_node(path) as Node3D
		if node == null:
			continue
		_build_box_for(node)

func _clear_boxes() -> void:
	for b in _boxes:
		if is_instance_valid(b):
			b.queue_free()
	_boxes.clear()

func _build_box_for(node: Node3D) -> void:
	var aabb := _get_global_aabb(node)
	if aabb.size == Vector3.ZERO:
		return

	var mesh_instance := MeshInstance3D.new()

	var box := BoxMesh.new()
	box.size = aabb.size
	mesh_instance.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = box_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mesh_instance.material_override = mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(mesh_instance)
	#mesh_instance.owner = get_tree().edited_scene_root

	# Place in global space AFTER entering the tree
	mesh_instance.global_position = aabb.get_center()

	_boxes.append(mesh_instance)

# ─────────────────────────────────────────────
#  AABB Helpers
# ─────────────────────────────────────────────

func _get_global_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var found := false

	# Walk the entire subtree
	var stack: Array[Node3D] = [node]
	while not stack.is_empty():
		var current = stack.pop_back()

		var local_aabb := _get_node_local_aabb(current)
		if local_aabb.size != Vector3.ZERO:
			var global_aabb: AABB = current.global_transform * local_aabb
			if not found:
				result = global_aabb
				found = true
			else:
				result = result.merge(global_aabb)

		for child in current.get_children():
			if child is Node3D:
				stack.push_back(child as Node3D)

	return result

func _get_node_local_aabb(node: Node3D) -> AABB:
	# VisualInstance3D covers MeshInstance3D, CSGShape3D, GPUParticles3D, etc.
	if node is VisualInstance3D:
		return (node as VisualInstance3D).get_aabb()
	# Fallback: honour a custom aabb() method (e.g. your BoxMesh3D)
	if node.has_method("aabb"):
		return node.call("aabb") as AABB
	return AABB()
