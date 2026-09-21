@tool
extends EditorPlugin

## Registers the Render Queue dock in the editor's bottom panel.

const RENDER_DOCK = preload('res://addons/render_queue/render_dock.gd')

var dock: Control


func _enter_tree() -> void:
	dock = RENDER_DOCK.new()
	dock.editor_interface = get_editor_interface()
	add_control_to_bottom_panel(dock, "Render Queue")

func _exit_tree() -> void:
	if is_instance_valid(dock):
		remove_control_from_bottom_panel(dock)
		dock.queue_free()
