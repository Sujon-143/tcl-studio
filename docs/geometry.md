# Geometry and visual primitives

## 2D components

`library/shapes-2d/` contains diagram and presentation nodes, including:

- `axis.gd`, `function_plot_2d.gd`, and `parametric_curve2d.gd` for plotted
  functions and coordinate systems
- `arrow_2d.gd`, `line_from_path.gd`, `bracket_line_2d.gd`, and `angle_2d.gd`
  for annotations
- `circle2d.gd`, `rect_2d.gd`, `triangle_2d.gd`, `dot_2d.gd`, and
  `sliced_circle.gd` for diagrams
- `table_2d.gd`, `title_maker.gd`, `stopwatch.gd`, and `info_graph.gd` for
  explanatory overlays

## 3D components

`library/shapes-derived/` and `library/shapes-derived-quad/` provide 3D
visualization forms such as parametric curves and surfaces, grid planes,
arrows, angle arcs, circles, dashed lines, dimension lines, brackets, trails,
and regions. The `*-quad` variants use render-oriented quad-based primitives;
`shapes-derived-RSBased/` contains specialized rendering-server-based dashed
line variants.

## Mesh wrappers and base nodes

`library/mesh-premitive-wrapper/` exposes common meshes—box, sphere, capsule,
cylinder, plane, prism, torus, quad, point, and trail meshes—as configurable
Godot components. `library/base/` provides shared foundations for visual nodes,
labels, backgrounds, meshes, and animation-player scenes.

All components are designed to be configured through the Inspector first. For
their exact exported properties, select a node in Godot or inspect the matching
source script.
