extends RefCounted
class_name Util



static func draw_centered_string(canvas:CanvasItem,font: Font, pos: Vector2, text: String, width: float = -1, font_size: int = 16, modulate: Color = Color(1, 1, 1, 1)):
	var text_size= font.get_string_size(
		text,HORIZONTAL_ALIGNMENT_CENTER,-1,font_size
	)
	pos.x-= text_size.x/2
	pos.y+= text_size.y/4
	canvas.draw_string(
		font,pos,text,0,width,font_size,modulate
	)
