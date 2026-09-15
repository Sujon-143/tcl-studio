# Getting started

## Requirements

- Godot 4.7 with .NET support
- .NET SDK 8 or a compatible SDK for the chosen target platform
- NuGet dependencies restored from `tcl-studio.csproj`

Open `project.godot` in the Godot editor. The project uses the Forward Plus
renderer and Jolt Physics.

## First scene

`test.tscn` is a small working example. It combines `function_plot_2d.gd` and
`axis.gd`, then uses an `AnimationPlayer` to animate their exported
`draw_progress` and `popup_progress` properties.

1. Open `test.tscn`.
2. Select the graph or axis node and review its Inspector properties.
3. Open the Animation panel and play `scene1`.
4. Duplicate the scene or add components from `library/` to start a new shot.

## Intended workflow

1. Add a reusable component to a 2D or 3D scene.
2. Configure its appearance and data through exported Inspector properties.
3. Animate those properties with `AnimationPlayer`, or call `ProcAnim` from a
   scene script for timed actions.
4. Compose the scene with Godot cameras, lighting, and rendering tools.
5. Capture or export the finished sequence using your chosen Godot video
   workflow.

Components in this repository are source assets, rather than a packaged
installable plugin. Keep the `library/` directory and the .NET configuration
when reusing them in another Godot project.
