@tool
extends RichTextLabel
class_name BaseRichTextLabel

# ---------- Font ----------
var font_bng := preload("res://Themes/bangla_fonts/Alinur/Unicode/Li Alinur Sangbadpatra2 Unicode.ttf")
var font_eng:= preload('res://Themes/font/fonts/ttf/JetBrainsMono-Medium.ttf')

enum langs{
	ENG,
	BNG
}

@export var lang:langs=langs.BNG:
	set(value):
		lang= value
		update_font()
	get:
		return lang

# ---------- Appearance Animation ----------
@export_category("Appearance Animations")

# Private backing variable for the popup progress
var _popup_progress: float = 0.0

@export_range(0.0, 1.0, 0.01) var popup_progress: float = 0.0:
	set(value):
		_popup_progress = value
		if not is_inside_tree():
			return
		print("applying: ", value)
		if value <= 0.05:
			hide()
			return
		show()
		var t = TransitionFunctions.ease_out(TransitionFunctions.trans_back, value)
		scale = Vector2.ONE * t
	get:
		return _popup_progress


# ---------- Default Properties ----------
@export_category("Default Properties")

var _font_size: int = 50

@export var font_size: int = 50:
	set(value):
		_font_size = value
		if is_inside_tree():
			add_theme_font_size_override("font_size", value)
	get:
		return _font_size


@export var underline:bool=false:
	set(value):
		underline= value
		queue_redraw()
	get:return underline

@export var underline_thickness:int=2:
	set(value):
		underline_thickness= value
		queue_redraw()
	get:return underline_thickness

@export var underline_offset:int=0:
	set(value):
		underline_offset= value
		queue_redraw()
	get:return underline_offset
@export var length_offset:int= 0:
	set(value):
		length_offset= value
		queue_redraw()
	get:return length_offset

# ---------- Engine Callbacks ----------
func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_CANVAS:
		update_font()
		offset_transform_pivot_ratio= Vector2(0.5,0.5)

func update_font():
	if lang== langs.BNG:
			add_theme_font_override("font", font_bng)
	elif lang==langs.ENG:
		add_theme_font_override('font',font_eng)	

func _enter_tree():
	add_theme_font_size_override("font_size",font_size)
	pivot_offset_ratio= Vector2(0.5,0.5)
	horizontal_alignment= HORIZONTAL_ALIGNMENT_LEFT
	vertical_alignment= VERTICAL_ALIGNMENT_CENTER


func _draw():
	if not underline:
		return
	draw_line(
	Vector2(-length_offset,size.y+underline_offset),
	 size +Vector2(length_offset,underline_offset),modulate,underline_thickness,false
	)
