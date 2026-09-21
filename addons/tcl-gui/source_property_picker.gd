@tool
class_name SourcePropertyPicker
extends EditorProperty
## Renders LevelMeter2D.source_property as a dropdown of the actual
## numeric-looking properties found on the node at source_node. Simpler
## than BindTargetPropertyPicker because the edited object IS the owning
## node, so source_node can be resolved directly (no Scene-dock-selection
## workaround needed).

var _meter: LevelMeter2D
var _option: OptionButton


func _init() -> void:
	_option = OptionButton.new()
	_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_option.item_selected.connect(_on_selected)
	add_child(_option)
	add_focusable(_option)


func setup(meter: LevelMeter2D) -> void:
	_meter = meter
	if not _meter.changed.is_connected(_refresh_options):
		_meter.changed.connect(_refresh_options)
	_refresh_options()


func _update_property() -> void:
	_refresh_options()


func _refresh_options() -> void:
	if _meter == null:
		return
	_option.clear()

	if _meter.source_node.is_empty():
		_option.add_item("<set source_node first>")
		_option.disabled = true
		return

	var node := _meter.get_node_or_null(_meter.source_node)
	if node == null:
		_option.add_item("<node not found: %s>" % _meter.source_node)
		_option.disabled = true
		return

	var names: Array[String] = []
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

	var current := String(_meter.source_property)
	var current_idx := 0
	for i in names.size():
		_option.add_item(names[i])
		if names[i] == current:
			current_idx = i
	_option.select(current_idx)
	if current == "":
		_meter.source_property = StringName(names[current_idx])


func _on_selected(index: int) -> void:
	if _meter == null:
		return
	var picked := _option.get_item_text(index)
	if picked.begins_with("<"):
		return
	_meter.source_property = StringName(picked)
	emit_changed("source_property", picked)
