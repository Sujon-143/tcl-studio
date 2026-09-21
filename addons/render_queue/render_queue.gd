@tool
extends RefCounted
class_name RenderQueueModel

## Holds the ordered list of render jobs and knows how to persist them.
##
## Jobs are stored as a plain Array of Dictionaries rather than typed
## Resources so the queue file stays readable, diffable, and easy to extend
## without migration code.

const SAVE_PATH := "res://addons/render_queue/render_queue.json"
const BUILD_DIR := "res://renders"

## Ordered jobs. Each entry is a plain Dictionary mirroring RenderJob fields.
var jobs: Array[Dictionary] = []


## Load the queue from disk, returning an empty queue if the file is missing
## or malformed.
func load_from_disk() -> void:
	jobs.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		for entry: Variant in parsed:
			if entry is Dictionary:
				jobs.append(_normalize(entry))


## Write the current queue to disk, creating the directory if needed.
func save_to_disk() -> Error:
	var dir := DirAccess.open("res://addons/render_queue")
	if dir == null:
		return ERR_CANT_OPEN
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(jobs, "\t"))
	file.close()
	return OK


## Create a new job Dictionary from a scene path, with sensible defaults.
func make_job(scene_path: String, title: String = "") -> Dictionary:
	var base := scene_path.get_file().get_basename()
	return {
	"title": title if not title.is_empty() else base,
	"scene_path": scene_path,
	"output_path": "%s/%s.ogv" % [BUILD_DIR, base],
	"format": "OGV",
	"width": 1920,
	"height": 1080,
	"fps": 30,
	"quit_after_frames": 0,
	"enabled": true,
	}


## Append a job to the queue.
func add_job(job: Dictionary) -> void:
	jobs.append(_normalize(job))


## Remove a job by index, ignoring out-of-range indices.
func remove_job(index: int) -> void:
	if index >= 0 and index < jobs.size():
		jobs.remove_at(index)


## Move a job one slot up or down. Returns true if the move happened.
func move_job(index: int, delta: int) -> bool:
	var target := index + delta
	if index < 0 or index >= jobs.size() or target < 0 or target >= jobs.size():
		return false
	var job := jobs[index]
	jobs.remove_at(index)
	jobs.insert(target, job)
	return true


## Jobs that are enabled, in order, ready to render.
func enabled_jobs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for job: Dictionary in jobs:
		if bool(job.get("enabled", true)):
			result.append(job)
	return result


## Ensure an entry has every field, filling defaults for anything missing.
## This keeps old queue files forward-compatible.
func _normalize(entry: Dictionary) -> Dictionary:
	var scene_path := String(entry.get("scene_path", ""))
	var base := scene_path.get_file().get_basename()
	var normalized := {
	"title": String(entry.get("title", base)),
	"scene_path": scene_path,
	"output_path": String(entry.get("output_path", "%s/%s.ogv" % [BUILD_DIR, base])),
	"format": String(entry.get("format", "OGV")),
	"width": int(entry.get("width", 1920)),
	"height": int(entry.get("height", 1080)),
	"fps": int(entry.get("fps", 30)),
	"quit_after_frames": int(entry.get("quit_after_frames", 0)),
	"enabled": bool(entry.get("enabled", true)),
	}
	return normalized
