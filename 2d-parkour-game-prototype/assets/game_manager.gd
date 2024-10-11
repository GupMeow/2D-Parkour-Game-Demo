extends Node
@onready var rings_label: Label = %PointsLabel

var rings = 0

func add_ring():
	rings += 1
	rings_label.text = "Rings: " + str(rings)

func decrease_health():
	if rings == 0:
		get_tree().reload_current_scene()
	else:
		rings -= 1
		print(rings)
	
	
