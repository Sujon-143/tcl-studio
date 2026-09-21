@tool
class_name BindTargetPropertyPicker
extends EditorProperty
## Renders BindTarget.target_property as a dropdown of the actual
## properties (or methods, if call_as_method is on) found on the node at
## BindTarget.target_node, instead of a free-typed string field.
##
## Limitation: this only sees nodes inside the currently edited scene, and
## only refreshes when target_node changes through the inspector (via the
## resource's `changed` signal) or when you press the refresh button.

var _target: BindTarget
var _option: OptionButton
var _refresh_button: Button
var _row: HBoxContainer


func _init() -> void:
	_row = HBoxContainer.new()
	_option = OptionButton.new()
	_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_option.item_selected.connect(_on_selected)
	_row.add_child(_option)

	_refresh_button = Button.new()
	_refresh_button.icon = get_theme_icon("Reload", "EditorIcons") if has_theme_icon("Reload", "EditorIcons") else null
	_refresh_button.text = "" if _refresh_button.icon else "Refresh"
	_refresh_button.tooltip_text = "Refresh property list from target_node"
	_refresh_button.pressed.connect(_refresh_options)
	_row.add_child(_refresh_button)

	add_child(_row)
	add_focusable(_option)


func setup(target: BindTarget) -> void:
	_target = target
	if not _target.changed.is_connected(_refresh_options):
		_target.changed.connect(_refresh_options)
	_refresh_options()


func _update_property() -> void:
	_refresh_options()


func _refresh_options() -> void:
	if _target == null:
		return
	_option.clear()

	if _target.target_node.is_empty():
		_option.add_item("<set target_node first>")
		_option.disabled = true
		return

	# BindTarget.apply() resolves target_node relative to the GuiElement2D
	# that owns the bind_to array (i.e. self.get_node_or_null(...)), NOT
	# relative to the scene root. So we must resolve it the same way here:
	# relative to whichever node is currently selected in the Scene dock
	# (that node stays selected while you edit its bind_to array).
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.is_empty():
		_option.add_item("<select the control node in the Scene dock>")
		_option.disabled = true
		return

	var owner_node: Node = selected[0]
	var node := owner_node.get_node_or_null(_target.target_node)
	if node == null:
		# Fall back to resolving from the edited scene root, in case
		# target_node was set as an absolute/scene-relative path.
		var root := EditorInterface.get_edited_scene_root()
		if root != null:
			node = root.get_node_or_null(_target.target_node)
	if node == null:
		_option.add_item("<node not found: %s>" % _target.target_node)
		_option.disabled = true
		return

	var names: Array[String] = []
	if _target.call_as_method:
		for m in node.get_method_list():
			var mn: String = m.name
			if not mn.begins_with("_"):
				names.append(mn)
	else:
		for p in node.get_property_list():
			var pn: String = p.name
			var usage: int = p.usage
			var is_relevant := (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 \
				or (usage & PROPERTY_USAGE_EDITOR) != 0
			if is_relevant and pn != "" and not pn.begins_with("_"):
				names.append(pn)

	names.sort()
	_option.disabled = names.is_empty()
	if names.is_empty():
		_option.add_item("<no matching properties found>")
		return

	var current := String(_target.target_property)
	var current_idx := 0
	for i in names.size():
		_option.add_item(names[i])
		if names[i] == current:
			current_idx = i
	if not names.is_empty():
		_option.select(current_idx)
		if current == "":
			_target.target_property = StringName(names[current_idx])


func _on_selected(index: int) -> void:
	if _target == null:
		return
	var picked := _option.get_item_text(index)
	if picked.begins_with("<"):
		return
	_target.target_property = StringName(picked)
	emit_changed("target_property", picked)
