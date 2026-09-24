@tool
extends RefCounted

## Only scene-ready, user-facing TCL Studio nodes belong here.
## Base nodes, data objects, helpers, and animation handlers are deliberately excluded.
const NODES: Array[Dictionary] = [
	# 2D shapes and diagrams
	{"class_name": "Angle2D", "base": "Node2D", "path": "res://library/shapes-2d/angle_2d.gd", "category": "2D Shapes"},
	{"class_name": "Arrow2D", "base": "Node2D", "path": "res://library/shapes-2d/arrow_2d.gd", "category": "2D Shapes"},
	{"class_name": "AxisGrid2D", "base": "Node2D", "path": "res://library/shapes-2d/axis.gd", "category": "2D Shapes"},
	{"class_name": "BracketLine2D", "base": "Node2D", "path": "res://library/shapes-2d/bracket_line_2d.gd", "category": "2D Shapes"},
	{"class_name": "Circle2D", "base": "Node2D", "path": "res://library/shapes-2d/circle2d.gd", "category": "2D Shapes"},
	{"class_name": "CrossMark", "base": "Node2D", "path": "res://library/shapes-2d/cross_mark.gd", "category": "2D Shapes"},
	{"class_name": "Dot2D", "base": "Node2D", "path": "res://library/shapes-2d/dot_2d.gd", "category": "2D Shapes"},
	{"class_name": "LineFromPath", "base": "Node2D", "path": "res://library/shapes-2d/line_from_path.gd", "category": "2D Shapes"},
	{"class_name": "MultiArrow", "base": "Node2D", "path": "res://library/misc/muti_arrow.gd", "category": "2D Shapes"},
	{"class_name": "ParametricCurve2D", "base": "Node2D", "path": "res://library/shapes-2d/parametric_curve2d.gd", "category": "2D Shapes"},
	{"class_name": "RandomGeoShapes", "base": "Node2D", "path": "res://library/shapes-2d/random_geometrical_shapes.gd", "category": "2D Shapes"},
	{"class_name": "Rect2D", "base": "Node2D", "path": "res://library/shapes-2d/rect_2d.gd", "category": "2D Shapes"},
	{"class_name": "SlicedCircle", "base": "Node2D", "path": "res://library/shapes-2d/sliced_circle.gd", "category": "2D Shapes"},
	{"class_name": "Table", "base": "Node2D", "path": "res://library/shapes-2d/table_2d.gd", "category": "2D Shapes"},
	{"class_name": "Triangle2D", "base": "Node2D", "path": "res://library/shapes-2d/triangle_2d.gd", "category": "2D Shapes"},
	{"class_name": "ValueTracker", "base": "Label", "path": "res://library/shapes-2d/value_tracker2d.gd", "category": "2D Shapes"},
	{"class_name": "Wiper", "base": "Node2D", "path": "res://library/shapes-2d/wiper.gd", "category": "2D Shapes"},

	# 3D scientific shapes
	{"class_name": "AngleArc", "base": "Node3D", "path": "res://library/shapes-derived/angle_arc.gd", "category": "3D Shapes"},
	{"class_name": "Arrow3D", "base": "MeshInstance3D", "path": "res://library/shapes-derived/arrow_3d.gd", "category": "3D Shapes"},
	{"class_name": "BracketLine", "base": "Node3D", "path": "res://library/shapes-derived/bracket_line.gd", "category": "3D Shapes"},
	{"class_name": "CircleSector", "base": "Node3D", "path": "res://library/shapes-derived/circle_sector.gd", "category": "3D Shapes"},
	{"class_name": "DashedCircle", "base": "Node3D", "path": "res://library/shapes-derived/dashed_circle.gd", "category": "3D Shapes"},
	{"class_name": "DashedLine", "base": "Node3D", "path": "res://library/shapes-derived/dashed_line.gd", "category": "3D Shapes"},
	{"class_name": "DashedLineFromPath", "base": "Node3D", "path": "res://library/shapes-derived/dashed_line_from_path.gd", "category": "3D Shapes"},
	{"class_name": "DimensionLine", "base": "Node3D", "path": "res://library/shapes-derived/dimension_line.gd", "category": "3D Shapes"},
	{"class_name": "GridPlane", "base": "Node3D", "path": "res://library/shapes-derived/grid_plane.gd", "category": "3D Shapes"},
	{"class_name": "ParametricCurve", "base": "Node3D", "path": "res://library/shapes-derived/parametric_curve.gd", "category": "3D Shapes"},
	{"class_name": "ParametricSurface", "base": "Node3D", "path": "res://library/shapes-derived/parametric_surface.gd", "category": "3D Shapes"},
	{"class_name": "SolidCircle", "base": "MeshInstance3D", "path": "res://library/shapes-derived/solid_circle.gd", "category": "3D Shapes"},

	# Mesh primitives
	{"class_name": "BoxMesh3D", "base": "MeshInstance3D", "path": "res://library/mesh-premitive-wrapper/BoxMesh3D.gd", "category": "3D Primitives"},
	{"class_name": "CapsuleMesh3D", "base": "MeshInstance3D", "path": "res://library/mesh-premitive-wrapper/CapsuleMesh3D.gd", "category": "3D Primitives"},
	{"class_name": "CylinderMesh3D", "base": "MeshInstance3D", "path": "res://library/mesh-premitive-wrapper/CylinderMesh3D.gd", "category": "3D Primitives"},
	{"class_name": "PlaneMesh3D", "base": "MeshInstance3D", "path": "res://library/mesh-premitive-wrapper/PlaneMesh3D.gd", "category": "3D Primitives"},
	{"class_name": "PrismMesh3D", "base": "MeshInstance3D", "path": "res://library/mesh-premitive-wrapper/PrismMesh3D.gd", "category": "3D Primitives"},
	{"class_name": "SphereMesh3D", "base": "MeshInstance3D", "path": "res://library/mesh-premitive-wrapper/SphereMesh3D.gd", "category": "3D Primitives"},
	{"class_name": "TorusMesh3D", "base": "MeshInstance3D", "path": "res://library/mesh-premitive-wrapper/TorusMesh3D.gd", "category": "3D Primitives"},

	# Science and scene tools
	{"class_name": "Atom3D", "base": "MeshInstance3D", "path": "res://library/Chemical Elements/Atom3D.gd", "category": "Science"},
	{"class_name": "Bond3D", "base": "MeshInstance3D", "path": "res://library/Chemical Elements/Bond3D.gd", "category": "Science"},
	{"class_name": "Molecule3D", "base": "Node3D", "path": "res://library/Chemical Elements/Molecule3D.gd", "category": "Science"},
	{"class_name": "EasyCam", "base": "Camera3D", "path": "res://library/misc/easyCam.gd", "category": "Scene Tools"},
	{"class_name": "Earth", "base": "MeshInstance3D", "path": "res://library/misc/earth/earth.gd", "category": "Scene Tools"},
	{"class_name": "ProceduralHouseGenerator", "base": "Node3D", "path": "res://library/environmental entities/procedural_house_generator.gd", "category": "Scene Tools"},
	{"class_name": "ProceduralTreeGenerator", "base": "Node3D", "path": "res://library/environmental entities/procedural_trees.gd", "category": "Scene Tools"},

	# Control elements (hand-drawn, bindable GUI controls)
	{"class_name": "Slider2D", "base": "Control", "path": "res://addons/tcl-gui/slider_2d.gd", "category": "Control Elements"},
	{"class_name": "CircularSlider2D", "base": "Control", "path": "res://addons/tcl-gui/circular_slider_2d.gd", "category": "Control Elements"},
	{"class_name": "RangeSlider2D", "base": "Control", "path": "res://addons/tcl-gui/range_slider_2d.gd", "category": "Control Elements"},
	{"class_name": "Stepper2D", "base": "Control", "path": "res://addons/tcl-gui/stepper_2d.gd", "category": "Control Elements"},
	{"class_name": "Toggle2D", "base": "Control", "path": "res://addons/tcl-gui/toggle_2d.gd", "category": "Control Elements"},
	{"class_name": "Button2D", "base": "Control", "path": "res://addons/tcl-gui/button_2d.gd", "category": "Control Elements"},
	{"class_name": "LevelMeter2D", "base": "Control", "path": "res://addons/tcl-gui/level_meter_2d.gd", "category": "Control Elements"},

]
