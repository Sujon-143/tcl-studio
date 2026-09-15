class_name BaseNode2D
extends Node2D

@export var animation_names:Array[StringName]=[]
@export var player:AnimationPlayer= null
@export var animation_id:int= 0
@export var quit_on_escape:bool=true

func _ready():
	Input.mouse_mode= Input.MOUSE_MODE_HIDDEN

func _input(event):
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_P:
				if player!=null and animation_id>=0 and animation_id<= animation_names.size():
					player.play(animation_names[animation_id])
			KEY_ESCAPE:
				if quit_on_escape:
					get_tree().quit()
			KEY_SPACE:
				if player != null:
					if player.is_playing():
						player.pause()
					else:
						player.play()  # resumes from where it paused
						
