# Animation

## Editor timelines

For most shots, use Godot's `AnimationPlayer`. Keyframe exported properties
such as visibility, position, color, `draw_progress`, or `popup_progress`.
This keeps the final motion editable without writing a custom animation script.

`test.tscn` demonstrates this approach by revealing an axis/grid and a
function plot over time.

## ProcAnim

`library/animation_handlers/ProcAnim.gd` is a facade over the animation helper
nodes. Add it to a scene when scripted sequencing is useful. Its API includes:

- parallel actions and waits
- popup/show and hide transitions
- fade in/out
- shake and pulse effects
- 2D and 3D movement, rotation, and camera transforms
- 3D indication and broadcast rings
- object-creation effects
- sequential, parallel, and staggered property tweens

The helper scripts are organized by concern:

| Helper | Role |
| --- | --- |
| `ProcAnimMove` / `ProcAnimTransform` | Movement, rotation, object and camera transforms. |
| `ProcAnimFade` / `ProcAnimPopup` / `ProcAnimDraw` | Visibility and creation transitions. |
| `ProcAnimFX` / `ProcAnimIndicate` | Emphasis effects. |
| `ProcAnimProperty` / `ProcAnimParallel` | Property tweening, sequencing, parallel actions, and waits. |

Use `await` when calling its asynchronous methods so the next action begins
only after the current animation completes.
