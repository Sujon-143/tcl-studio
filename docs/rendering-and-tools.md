# Rendering and supporting tools

## Shaders

`library/Shaders/` contains reusable Godot shader sources for stylized space,
sky, moon, Earth and cloud layers, mountains, and 2D drawing effects. Assign
them through a `ShaderMaterial` and adjust their exposed uniforms in the
Inspector.

## Presentation tools

`library/Indications/indicator_box.gd` and the indication utilities under
`library/misc/` support visual emphasis. Other miscellaneous tools include:

- `easyCam.gd` and `camera_lense_2d.gd` for camera behaviour
- `timeline_maker.gd` and `timeline_event_data.gd` for timed presentation logic
- `util.gd` for shared helpers
- `vintage_monitor.gd`, cursor tools, dialogue bubbles, and character elements
  for presentation styling

## Rendering notes

The project is configured for Godot's Forward Plus renderer with Direct3D 12 on
Windows. Scene-specific lighting, camera choices, post-processing, and export
settings are intentionally left to the creator, since visual requirements vary
between videos.
