extends Placeable

class_name Plank

@onready var collision: CollisionShape2D = self.get_node("CollisionShape2D")
@onready var visual: MeshInstance2D = self.get_node("MeshInstance2D")

var base_height = 300.0

func set_height(input: float):
	collision.shape.height = input
	visual.mesh.height = input
	
func set_bounce(input: float):
	var mat = physics_material_override
	mat.bounce = input
