@tool
extends Resource
class_name RenderJob

## A single render task: one scene rendered to one video file through
## Godot's Movie Maker mode (``--write-movie``).

## Where the job currently is in its lifecycle.
enum Status {
	QUEUED, ## Waiting to be rendered.
	RENDERING, ## A Godot process is currently writing this job.
	DONE, ## Finished successfully.
	FAILED, ## The process exited non-zero or the output is missing.
	SKIPPED, ## Disabled at queue time.
}

## Output container / codec, chosen from the file extension.
enum Format {
	OGV, ## Theora + Vorbis in an OGV container. Best balance, editor builds only.
	AVI, ## MJPEG + uncompressed audio. Fast, capped around 4 GB.
	PNG, ## PNG image sequence + WAV. Lossless, supports transparency.
}

## Human-readable label shown in the dock list.
@export var title: String = "Untitled shot"

## Scene to run. Recorded as a res:// path so the queue is portable.
@export_file("*.tscn") var scene_path: String = ""

## Destination movie file. Absolute path, or relative to the project root.
@export var output_path: String = ""

## Container / codec for the output file.
@export var format: Format = Format.OGV

## Render resolution, e.g. Vector2i(1920, 1080).
@export var resolution: Vector2i = Vector2i(1920, 1080)

## Frames per second baked into the movie (``--fixed-fps``).
@export_range(1, 240, 1) var fps: int = 30

## Stop after this many frames. 0 means "let the scene decide" (rely on
## AnimationPlayer's Movie Quit On Finish, or the scene calling quit()).
@export_range(0, 100000, 1) var quit_after_frames: int = 0

## Master on/off switch so a job can sit in the list but be skipped.
@export var enabled: bool = true

## Runtime-only status; not meaningful across editor sessions.
var status: Status = Status.QUEUED

## Populated after a run: short human-readable result (error text or a note).
var last_message: String = ""


## Extension implied by the selected format, including the leading dot.
func get_extension() -> String:
	match format:
		Format.AVI:
				return ".avi"
		Format.PNG:
				return ".png"
		_:
				return ".ogv"


## Output path with the correct extension for the chosen format, replacing
## whatever extension the user may have typed.
func resolved_output_path() -> String:
	var path := output_path.strip_edges()
	if path.is_empty():
		# Sensible default so a job is always runnable even if the user
		# never typed an output path.
		var base := scene_path.get_file().get_basename()
		path = "res://renders/%s%s" % [base, get_extension()]
	else:
		# Force the extension to match the format so the CLI flag is unambiguous.
		path = path.get_basename() + get_extension()
	return path


## Absolute filesystem path for the output, resolved against the project root
## when the path is given as res:// or project-relative.
func absolute_output_path() -> String:
	return ProjectSettings.globalize_path(resolved_output_path())


## Build the argument list passed to the Godot executable for this job.
func build_cli_args() -> PackedStringArray:
	var args := PackedStringArray()
	args.append("--path")
	args.append(ProjectSettings.globalize_path("res://"))
	args.append("--resolution")
	args.append("%dx%d" % [resolution.x, resolution.y])
	args.append("--fixed-fps")
	args.append(str(fps))
	args.append("--write-movie")
	args.append(absolute_output_path())
	if quit_after_frames > 0:
		args.append("--quit-after")
		args.append(str(quit_after_frames))
	# The scene must be the last positional argument so Godot runs it directly.
	args.append(ProjectSettings.globalize_path(scene_path))
	return args

## A single copy-pasteable command line, useful for the "Copy command" button.
func build_cli_string(godot_executable: String) -> String:
	var parts := PackedStringArray([godot_executable])
	for arg: String in build_cli_args():
		if arg.contains(" "):
			parts.append("\"%s\"" % arg)
		else:
			parts.append(arg)
	return " ".join(parts)
