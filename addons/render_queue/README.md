# Render Queue add-on

Queue scenes and render them to video using Godot's **Movie Maker mode**,
without babysitting each run. It adds a **Render Queue** tab to the editor's
bottom panel.

## Why it exists

Godot's Movie Maker mode renders high-quality non-real-time video with perfect
frame pacing, but it is a *one scene → one file per run* tool with no queue and
no persistence. This add-on wraps it: build a list of shots, set them up once,
and render them sequentially in the background.

## How it works

Each time you press **Render queue**, the dock launches a **separate Godot
process** with Movie Maker flags:

```
godot --path <project> --resolution 1920x1080 --fixed-fps 30 \
      --write-movie <output> [--quit-after N] <scene>
```

Movie Maker mode cannot be toggled while a project is already running, so a
fresh process per job is the correct approach (this is also what the official
docs recommend). The dock polls each process, then advances to the next job.

## Usage

1. Enable **Render Queue** from **Project > Project Settings > Plugins**.
2. Open the scene you want to render and press **Add current scene**.
3. Adjust the job's output path, resolution, FPS, and format in the details
   panel on the right. Edits are saved automatically.
4. Set the **Godot exe** path if it was not auto-detected (it defaults to the
   running editor's own executable).
5. Press **Render queue** to render every enabled job in order.

## Output formats

| Format | Codec | Notes |
| --- | --- | --- |
| **OGV** | Theora + Vorbis | Best quality/size balance. Editor builds only. |
| **AVI** | MJPEG | Fast encoding, capped near 4 GB. |
| **PNG** | Lossless sequence + WAV | Supports transparency; post-process with FFmpeg. |

## Stopping a render

- Set **Quit after (frames)** on a job to stop it after N frames, or
- enable **Movie Quit On Finish** on the scene's `AnimationPlayer` (for a
  non-looping animation), or
- have the scene call `get_tree().quit()` when it is finished.

## Files

| File | Purpose |
| --- | --- |
| `plugin.cfg` | Plugin manifest. |
| `plugin.gd` | Registers the dock with the editor. |
| `render_dock.gd` | The dock UI and the sequential process runner. |
| `render_queue.gd` | Job list model and JSON persistence. |
| `render_job.gd` | A typed helper describing one job and its CLI args. |
| `render_queue.json` | The saved queue (created on first use). |

## Notes and limitations

- Rendering blocks the *queue*, not the editor: the editor stays responsive
  while jobs run in separate processes.
- Because each job is a separate process, jobs render one at a time. Parallel
  rendering could be added later but would compete for GPU resources.
- `render_job.gd` is provided as a typed reference for the CLI construction;
  the dock currently builds args inline from the dictionary job model.
