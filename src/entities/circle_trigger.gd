extends Control

signal pressed

var is_animating := false:
	set(value):
		is_animating = value
		queue_redraw()

func _ready():
	mouse_filter = MOUSE_FILTER_PASS
	set_process_input(true)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("pressed")

func _draw():
	var radius := 8
	var center := Vector2(size.x / 2, size.y / 2)
	
	var color := Color.GREEN
	if(is_animating):
		color = Color.RED
	
	draw_circle(center, radius, color)
