@tool
extends VBoxContainer

## The visible, curated component palette. The catalog deliberately excludes
## base nodes, resources, and other implementation-only classes.

var editor_interface: EditorInterface
var undo_redo: EditorUndoRedoManager
var catalog_entries: Array[Dictionary] = []

signal node_drag_started(node_class: String)

const COMPONENT_BUTTON := preload("res://addons/components_browser/component_button.gd")

var search_box: LineEdit
var category_picker: OptionButton
var component_list: GridContainer
var status_label: Label
var entries: Array[Dictionary] = []


func _ready() -> void:
	custom_minimum_size = Vector2(0, 240)
	name = "Components"

	var heading := Label.new()
	heading.text = "Components"
	heading.add_theme_font_size_override("font_size", 18)
	add_child(heading)

	var help := Label.new()
	help.text = "Click a component to add it, or drag it onto the 2D or 3D editor."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Search components"
	search_box.clear_button_enabled = true
	search_box.text_changed.connect(_refresh_components)
	add_child(search_box)

	category_picker = OptionButton.new()
	category_picker.item_selected.connect(_refresh_components)
	add_child(category_picker)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	component_list = GridContainer.new()
	component_list.columns = 4
	component_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(component_list)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.72, 0.72, 0.72)
	add_child(status_label)

	_load_catalog()


func _load_catalog() -> void:
	entries = catalog_entries.duplicate(true)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["class_name"].naturalnocasecmp_to(b["class_name"]) < 0)
	category_picker.clear()
	category_picker.add_item("All categories")
	var categories: Array[String] = []
	for entry: Dictionary in entries:
		var category: String = entry["category"]
		if not categories.has(category):
			categories.append(category)
	categories.sort()
	for category: String in categories:
		category_picker.add_item(category)
	_refresh_components()


func _refresh_components(_unused: Variant = null) -> void:
	if not is_instance_valid(component_list):
		return
	for child: Node in component_list.get_children():
		child.queue_free()

	var query := search_box.text.strip_edges().to_lower()
	var chosen_category := ""
	if category_picker.selected > 0:
		chosen_category = category_picker.get_item_text(category_picker.selected)

	var visible_count := 0
	for entry: Dictionary in entries:
		var node_class: String = entry["class_name"]
		if not chosen_category.is_empty() and entry["category"] != chosen_category:
			continue
		if not query.is_empty() and not node_class.to_lower().contains(query):
			continue

		var component_button = COMPONENT_BUTTON.new()
		component_button.node_class = node_class
		component_button.text = node_class
		component_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		component_button.custom_minimum_size = Vector2(112, 66)
		component_button.add_theme_font_size_override("font_size", 12)
		component_button.expand_icon = true
		component_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		component_button.tooltip_text = "%s\n%s\nClick to add, or drag to the 2D/3D editor." % [entry["category"], entry["path"]]
		var icon := get_theme_icon(String(entry["base"]), "EditorIcons")
		if icon == null:
			icon = get_theme_icon("Node", "EditorIcons")
		component_button.icon = icon
		component_button.pressed.connect(add_node_by_class.bind(node_class))
		component_button.component_drag_started.connect(_on_component_drag_started)
		component_list.add_child(component_button)
		visible_count += 1

	status_label.text = "%d components available" % visible_count


func _on_component_drag_started(node_class: String) -> void:
	node_drag_started.emit(node_class)


func add_node_by_class(node_class: String) -> void:
	if editor_interface == null or node_class.is_empty():
		return
	var entry := _find_entry(node_class)
	if entry.is_empty():
		_show_message("%s is not in the Components catalog." % node_class)
		return
	var scene_root: Node = editor_interface.get_edited_scene_root()
	if scene_root == null:
		_show_message("Open or create a scene before adding a component.")
		return

	var parent: Node = scene_root
	var scene_selection: Array[Node] = editor_interface.get_selection().get_selected_nodes()
	if not scene_selection.is_empty():
		parent = scene_selection[0]

	var component_script := load(String(entry["path"])) as Script
	if component_script == null:
		_show_message("Could not load %s. Check the script for editor errors." % node_class)
		return
	var new_node := component_script.new() as Node
	if new_node == null:
		_show_message("Could not create %s." % node_class)
		return

	new_node.name = node_class
	if undo_redo == null:
		_show_message("The editor undo/redo manager is not available.")
		return
	undo_redo.create_action("Add %s" % node_class)
	undo_redo.add_do_method(parent, "add_child", new_node, true)
	undo_redo.add_do_method(new_node, "set_owner", scene_root)
	undo_redo.add_do_method(editor_interface.get_selection(), "clear")
	undo_redo.add_do_method(editor_interface.get_selection(), "add_node", new_node)
	undo_redo.add_undo_method(parent, "remove_child", new_node)
	undo_redo.add_do_reference(new_node)
	undo_redo.commit_action()
	_show_message("Added %s" % node_class)


func _show_message(message: String) -> void:
	status_label.text = message


func _find_entry(node_class: String) -> Dictionary:
	for entry: Dictionary in entries:
		if entry["class_name"] == node_class:
			return entry
	return {}
