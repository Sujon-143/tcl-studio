# tcl-studio documentation

This index describes the reusable systems in `library/`. The toolkit is meant
for editor-first scientific visualization: add a component to a Godot scene,
adjust its exported properties in the Inspector, and animate those properties
with `AnimationPlayer` or `ProcAnim`.

## Guides

- [Getting started](docs/getting-started.md) — requirements and the basic
  editor workflow
- [Animation](docs/animation.md) — `ProcAnim` and timeline-driven scenes
- [Geometry and visual primitives](docs/geometry.md) — 2D/3D shapes, meshes,
  plots, labels, and annotations
- [Scientific components](docs/science.md) — chemistry, mathematical TeX, and
  environmental generators
- [Rendering and supporting tools](docs/rendering-and-tools.md) — shaders,
  cameras, backgrounds, and utilities

## Library map

| Area | Location | Purpose |
| --- | --- | --- |
| Base nodes | `library/base/` | Reusable Node2D, Node3D, label, mesh, background, and animation-player foundations. |
| Animation | `library/animation_handlers/` | High-level transitions and tween helpers. |
| 2D geometry | `library/shapes-2d/` | Axes, graphs, curves, diagrams, labels, and annotations. |
| 3D geometry | `library/shapes-derived*/` | Curves, grids, arrows, dimension lines, dashed forms, and surfaces. |
| Mesh wrappers | `library/mesh-premitive-wrapper/` | Inspector-friendly wrappers around Godot mesh primitives. |
| Science | `library/Chemical Elements/`, `library/GodoTeX/` | Molecular structures and TeX-style mathematical labels. |
| Rendering | `library/Shaders/`, `library/environmental entities/` | Shader effects and procedural environments. |
| Supporting tools | `library/misc/`, `library/Indications/` | Cameras, plots, timelines, pointers, and presentation effects. |

The source itself is the definitive API reference: exported properties appear
in the Godot Inspector, and each component can be opened from the FileSystem
dock to inspect its implementation.
