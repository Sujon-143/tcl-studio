@tool
extends VBoxContainer

## The Render Queue dock: author the queue, then render it sequentially.
##
## Rendering each job launches a separate Godot process with Movie Maker
## flags, because Movie Maker mode cannot be toggled while a project is
## already running. See the docs: creating_movies.html.

const MODEL_SCRIPT := preload("res://addons/render_queue/render_queue.gd")

var editor_interface: EditorInterface

var model := MODEL_SCRIPT.new()

## Path to the Godot executable used to spawn render processes.
var godot_executable: String = ""

## Index of the job currently being rendered, or -1 when idle.
var _active_index: int = -1

## Popen handle for the running render process, or null when idle.
var _process: int = -1

## Queue of indices still waiting to be rendered this run.
var _pending: Array[int] = []


# --- UI references -------------------------
var job_list: ItemList
var status_label: Label
var exe_field: LineEdit
var render_button: Button
var add_scene_button: Button
var details_box: VBoxContainer
var title_field: LineEdit
var output_field: LineEdit
var format_picker: OptionButton
var width_spin: SpinBox
var height_spin: SpinBox
var fps_spin: SpinBox
var quit_spin: SpinBox
var enabled_check: CheckBox


func _ready() -> void:
	custom_minimum_size = Vector2(0, 260)
	name = "Render Queue"

	_build_ui()
	godot_executable = _detect_godot_executable()
	exe_field.text = godot_executable
	model.load_from_disk()
	_refresh_list()


# --- UI construction -------------------------

func _build_ui() -> void:
	var heading := Label.new()
	heading.text = "Render Queue"
	heading.add_theme_font_size_override("font_size", 18)
	add_child(heading)

	var help := Label.new()
	help.text = "Queue scenes and render them to video with Movie Maker mode."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)

	# Executable row -----------------------------------------------------------
	var exe_row := HBoxContainer.new()
	add_child(exe_row)
	var exe_label := Label.new()
	exe_label.text = "Godot exe:"
	exe_row.add_child(exe_label)
	exe_field = LineEdit.new()
	exe_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exe_field.placeholder_text = "Path to the Godot executable"
	exe_field.text_changed.connect(_on_executable_changed)
	exe_row.add_child(exe_field)

	# Toolbar ------------------------------------------------------------------
	var toolbar := HBoxContainer.new()
	add_child(toolbar)

	add_scene_button = Button.new()
	add_scene_button.text = "Add current scene"
	add_scene_button.tooltip_text = "Add the scene open in the editor to the queue."
	add_scene_button.pressed.connect(_on_add_current_scene)
	toolbar.add_child(add_scene_button)

	var up_button := Button.new()
	up_button.text = "Up"
	up_button.pressed.connect(func() -> void: _move_selected(-1))
	toolbar.add_child(up_button)

	var down_button := Button.new()
	down_button.text = "Down"
	down_button.pressed.connect(func() -> void: _move_selected(1))
	toolbar.add_child(down_button)

	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(_on_remove_selected)
	toolbar.add_child(remove_button)

	render_button = Button.new()
	render_button.text = "Render queue"
	render_button.tooltip_text = "Render every enabled job, one after another."
	render_button.pressed.connect(_on_render_queue)
	toolbar.add_child(render_button)

	# Job list + details split -------------------------------------------------
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)

	job_list = ItemList.new()
	job_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	job_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	job_list.item_selected.connect(_on_job_selected)
	job_list.custom_minimum_size = Vector2(260, 140)
	split.add_child(job_list)

	details_box = VBoxContainer.new()
	details_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(details_box)

	title_field = _add_text_field(details_box, "Title", _on_field_changed)
	output_field = _add_text_field(details_box, "Output", _on_field_changed)

	var format_row := HBoxContainer.new()
	details_box.add_child(format_row)
	var format_label := Label.new()
	format_label.text = "Format"
	format_label.custom_minimum_size = Vector2(90, 0)
	format_row.add_child(format_label)
	format_picker = OptionButton.new()
	format_picker.add_item("OGV (Theora)", 0)
	format_picker.add_item("AVI (MJPEG)", 1)
	format_picker.add_item("PNG sequence", 2)
	format_picker.item_selected.connect(_on_format_selected)
	format_row.add_child(format_picker)

	width_spin = _add_spin(details_box, "Width", 16, 16384, 1)
	height_spin = _add_spin(details_box, "Height", 16, 16384, 1)
	fps_spin = _add_spin(details_box, "FPS", 1, 240, 1)
	quit_spin = _add_spin(details_box, "Quit after (frames, 0 = auto)", 0, 1000000, 1)

	enabled_check = CheckBox.new()
	enabled_check.text = "Enabled"
	enabled_check.toggled.connect(_on_enabled_toggled)
	details_box.add_child(enabled_check)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.72, 0.72, 0.72)
	add_child(status_label)


func _add_text_field(parent: VBoxContainer, label_text: String, on_change: Callable) -> LineEdit:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(90, 0)
	row.add_child(label)
	var field := LineEdit.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.text_changed.connect(on_change)
	row.add_child(field)
	return field


func _add_spin(parent: VBoxContainer, label_text: String, min_value: float, max_value: float, step: float) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(90, 0)
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value_changed.connect(_on_spin_changed)
	row.add_child(spin)
	return spin


# --- Queue list rendering -------------------------

func _refresh_list() -> void:
	if not is_instance_valid(job_list):
		return
	var previous := job_list.get_selected_items()
	job_list.clear()
	if model.jobs.is_empty():
		status_label.text = "Queue is empty. Open a scene and use \"Add current scene\"."
		_update_details(-1)
		return

	var done := 0
	for index: int in model.jobs.size():
		var job: Dictionary = model.jobs[index]
		var prefix := ""
		if not bool(job.get("enabled", true)):
			prefix = "[disabled] "
		job_list.add_item("%s%s  (%dx%d @ %d fps)" % [
			prefix,
			String(job.get("title", "Untitled")),
			int(job.get("width", 1920)),
			int(job.get("height", 1080)),
			int(job.get("fps", 30)),
		])
		if bool(job.get("enabled", true)):
			done += 1

	status_label.text = "%d job(s); %d enabled." % [model.jobs.size(), done]

	if not previous.is_empty() and previous[0] < model.jobs.size():
		job_list.select(previous[0])
		_update_details(previous[0])
	else:
		_update_details(-1)

## Populate the details editor for the selected job.
func _update_details(index: int) -> void:
	_set_details_enabled(index >= 0)
	if index < 0 or index >= model.jobs.size():
		return
	var job: Dictionary = model.jobs[index]
	title_field.text = String(job.get("title", ""))
	output_field.text = String(job.get("output_path", ""))
	format_picker.select(_format_index_from_string(String(job.get("format", "OGV"))))
	width_spin.value = int(job.get("width", 1920))
	height_spin.value = int(job.get("height", 1080))
	fps_spin.value = int(job.get("fps", 30))
	quit_spin.value = int(job.get("quit_after_frames", 0))
	enabled_check.button_pressed = bool(job.get("enabled", true))


func _set_details_enabled(enabled: bool) -> void:
	title_field.editable = enabled
	output_field.editable = enabled
	format_picker.disabled = not enabled
	width_spin.editable = enabled
	height_spin.editable = enabled
	fps_spin.editable = enabled
	quit_spin.editable = enabled
	enabled_check.disabled = not enabled


func _format_index_from_string(value: String) -> int:
	match value:
		"AVI":
			return 1
		"PNG":
			return 2
		_:
			return 0


func _format_string_from_index(index: int) -> String:
	match index:
		1:
			return "AVI"
		2:
			return "PNG"
		_:
			return "OGV"


# --- Selection / editing callbacks -------------------------

func _selected_index() -> int:
	var selected := job_list.get_selected_items()
	return selected[0] if not selected.is_empty() else -1


func _on_job_selected(index: int) -> void:
	_update_details(index)


func _on_field_changed(_unused: String) -> void:
	_apply_details_to_job()


func _on_spin_changed(_value: float) -> void:
	_apply_details_to_job()


func _on_format_selected(index: int) -> void:
	_apply_details_to_job()


func _on_enabled_toggled(_pressed: bool) -> void:
	_apply_details_to_job()


## Push the details widgets back into the selected job and persist.
func _apply_details_to_job() -> void:
	var index := _selected_index()
	if index < 0 or index >= model.jobs.size():
		return
	var job: Dictionary = model.jobs[index]
	job["title"] = title_field.text
	job["output_path"] = output_field.text
	job["format"] = _format_string_from_index(format_picker.selected)
	job["width"] = int(width_spin.value)
	job["height"] = int(height_spin.value)
	job["fps"] = int(fps_spin.value)
	job["quit_after_frames"] = int(quit_spin.value)
	job["enabled"] = enabled_check.button_pressed
	model.jobs[index] = job
	model.save_to_disk()
	_refresh_list()


func _on_executable_changed(text: String) -> void:
	godot_executable = text


# --- Toolbar actions -------------------------

func _on_add_current_scene() -> void:
	if editor_interface == null:
		return
	var root := editor_interface.get_edited_scene_root()
	if root == null:
		status_label.text = "No scene is open."
		return
	var scene_path := root.scene_file_path
	if scene_path.is_empty():
		status_label.text = "Save the scene before queueing it."
		return
	model.add_job(model.make_job(scene_path))
	model.save_to_disk()
	_refresh_list()
	job_list.select(model.jobs.size() - 1)
	_update_details(model.jobs.size() - 1)


func _on_remove_selected() -> void:
	var index := _selected_index()
	if index < 0:
		return
	model.remove_job(index)
	model.save_to_disk()
	_refresh_list()


func _move_selected(delta: int) -> void:
	var index := _selected_index()
	if index < 0:
		return
	if not model.move_job(index, delta):
		return
	model.save_to_disk()
	_refresh_list()
	job_list.select(index + delta)


# --- Rendering -------------------------

## Kick off a sequential render of every enabled job.
func _on_render_queue() -> void:
	if _process != -1:
		status_label.text = "Already rendering. Please wait."
		return
	if godot_executable.is_empty() or not FileAccess.file_exists(godot_executable):
		status_label.text = "Set a valid Godot executable path first."
		return

	_pending.clear()
	for index: int in model.jobs.size():
		if bool(model.jobs[index].get("enabled", true)):
			if String(model.jobs[index].get("scene_path", "")).is_empty():
				continue
			_pending.append(index)

	if _pending.is_empty():
		status_label.text = "No enabled jobs with a scene to render."
		return

	render_button.disabled = true
	_render_next()


## Start the next pending job, or finish the run when the list is empty.
func _render_next() -> void:
	if _pending.is_empty():
		_finish_run()
		return

	_active_index = _pending.pop_front()
	var job: Dictionary = model.jobs[_active_index]
	var scene_path := String(job.get("scene_path", ""))
	var output_abs := _absolute_output_for(job)

	_process = OS.create_process(godot_executable, _build_args(job, scene_path, output_abs), false)
	if _process <= 0:
		model.jobs[_active_index]["_last_result"] = "failed to spawn process"
		status_label.text = "Failed to launch Godot for %s." % String(job.get("title", ""))
		_render_next()
		return

	status_label.text = "Rendering \"%s\" -> %s ..." % [String(job.get("title", "")), output_abs]
	_render_button_poll()


## Poll the child process until it exits, then advance the queue.
## Uses a SceneTree timer so the editor stays responsive.
func _render_button_poll() -> void:
	if _process == -1:
		return
	if _process_is_alive():
		get_tree().create_timer(0.5).timeout.connect(_render_button_poll)
		return

	_process = -1
	var job: Dictionary = model.jobs[_active_index]
	var output_abs := _absolute_output_for(job)
	var ok := FileAccess.file_exists(output_abs)
	model.jobs[_active_index]["_last_result"] = "done" if ok else "no output file"

	status_label.text = "%s \"%s\"." % ["Rendered" if ok else "Finished (no file)", String(job.get("title", ""))]
	_active_index = -1
	# Small gap between jobs so the OS reclaims the previous window cleanly.
	get_tree().create_timer(0.3).timeout.connect(_render_next)


func _finish_run() -> void:
	render_button.disabled = false
	status_label.text = "Render queue finished."


## Whether the spawned process is still running.
func _process_is_alive() -> bool:
	if _process == -1:
		return false
	# OS.is_process_running exists in Godot 4.3+; fall back to exit code probe.
	if OS.has_method("is_process_running"):
		return OS.is_process_running(_process)
	return true


## Absolute path for a job's output, honouring res:// project-relative paths.
func _absolute_output_for(job: Dictionary) -> String:
	var output := String(job.get("output_path", ""))
	if output.is_empty():
		var base := String(job.get("scene_path", "")).get_file().get_basename()
		output = "res://renders/%s%s" % [base, _extension_for(job)]
	output = output.get_basename() + _extension_for(job)
	return ProjectSettings.globalize_path(output)


func _extension_for(job: Dictionary) -> String:
	match String(job.get("format", "OGV")):
		"AVI":
			return ".avi"
		"PNG":
			return ".png"
		_:
			return ".ogv"


## Build the Godot CLI argument list for a single job.
func _build_args(job: Dictionary, scene_path: String, output_abs: String) -> PackedStringArray:
	var args := PackedStringArray()
	args.append("--path")
	args.append(ProjectSettings.globalize_path("res://"))
	args.append("--resolution")
	args.append("%dx%d" % [int(job.get("width", 1920)), int(job.get("height", 1080))])
	args.append("--fixed-fps")
	args.append(str(int(job.get("fps", 30))))
	args.append("--write-movie")
	args.append(output_abs)
	var quit_frames := int(job.get("quit_after_frames", 0))
	if quit_frames > 0:
		args.append("--quit-after")
		args.append(str(quit_frames))
	# Run the requested scene directly by passing it as the positional scene.
	args.append(ProjectSettings.globalize_path(scene_path))
	return args


# --- Executable detection -------------------------

## Best-effort discovery of a Godot executable so the field is usable at once.
func _detect_godot_executable() -> String:
	var os_exec := OS.get_executable_path()
	# When running inside the editor, this IS the Godot binary.
	if not os_exec.is_empty() and FileAccess.file_exists(os_exec):
		return os_exec
	return ""
