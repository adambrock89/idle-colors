extends Node2D
class_name GhostPreview

var source_node: StaticBody2D
var sprite: Node2D
var collision_node: Node

var grab_offset := Vector2.ZERO
var grab_offset_local := Vector2.ZERO
var current_rotation_degrees := 0.0

@export var rotation_step_degrees := 15.0
@export var valid_color := Color(1, 1, 1, 0.5)
@export var invalid_color := Color(1, 0.3, 0.3, 0.5)
var initialized := false


func _ready():
	# Duplicate visuals + polygon
	for child in source_node.get_children():
		if child is CollisionPolygon2D or child is CollisionShape2D:
			collision_node = child.duplicate()
			collision_node.visible = false
			add_child(collision_node)
		elif child is Node2D and not (child is CollisionPolygon2D or child is CollisionShape2D):
			sprite = child.duplicate()
			sprite.visible = false
			add_child(sprite)
	

	var click_global := get_global_mouse_position()
	grab_offset_local = source_node.to_local(click_global)

	current_rotation_degrees = rad_to_deg(source_node.rotation)
	
	set_process_input(true)
	set_physics_process(true)


func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _placement_is_valid():
			_place_real_object()

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_rotation_degrees += rotation_step_degrees
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_rotation_degrees -= rotation_step_degrees
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if(!source_node.just_purchased):
				source_node.set_deferred("is_being_placed",false)
				queue_free()


func _physics_process(_delta):
	var mouse := get_global_mouse_position()
	var angle_rad := deg_to_rad(current_rotation_degrees)

	# Rotate the local grab offset
	var rotated_local := Vector2(
		grab_offset_local.x * cos(angle_rad) - grab_offset_local.y * sin(angle_rad),
		grab_offset_local.x * sin(angle_rad) + grab_offset_local.y * cos(angle_rad)
	)

	# Place ghost so clicked point stays under cursor
	global_position = mouse - rotated_local
	rotation = angle_rad

	if not initialized:
		sprite.visible = true
		collision_node.visible = true
		initialized = true
		
	# Tint
	if _placement_is_valid():
		sprite.modulate = valid_color
	else:
		sprite.modulate = invalid_color


func _place_real_object():
	source_node.global_transform = global_transform
	
	source_node.set_deferred("is_being_placed",false)
	source_node.set_deferred("just_purchased",false)
	
	queue_free()


func _placement_is_valid() -> bool:
	var space := get_world_2d().direct_space_state

	var params := PhysicsShapeQueryParameters2D.new()
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.collision_mask = source_node.collision_layer

	var shape: Shape2D
	var xform: Transform2D

	if collision_node is Polygon2D and collision_node.polygon.size() >= 3:
		var poly = collision_node.polygon
		var concave := ConcavePolygonShape2D.new()
		concave.segments = _polygon_to_segments(poly)

		shape = concave
		xform = global_transform * collision_node.transform

	elif collision_node is CollisionShape2D and collision_node.shape:
		shape = collision_node.shape
		xform = global_transform * collision_node.transform

	else:
		return true

	params.shape = shape
	params.transform = xform

	var results := space.intersect_shape(params, 32)

	for hit in results:
		if hit.collider == source_node:
			continue
		return false

	return true



func _polygon_to_segments(poly: PackedVector2Array) -> PackedVector2Array:
	var segs := PackedVector2Array()
	for i in range(poly.size()):
		var a = poly[i]
		var b = poly[(i + 1) % poly.size()]
		segs.append(a)
		segs.append(b)
	return segs
