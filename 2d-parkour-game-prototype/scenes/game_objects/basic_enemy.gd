extends RigidBody2D

@onready var game_manager: Node = %GameManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "CharacterBody2D":
		if body.is_spin_dashing():
			print("made it")
			var sonic_velocity = body.velocity.x
			queue_free() # destroy enemy
			body.velocity.x = -sonic_velocity * 0.5 # send sonic back the opposite way
			return
			
		var y_delta = position.y - body.position.y
		var x_delta = body.position.x - position.x
		if y_delta > 35:
			queue_free()
			body.jump()
		else:
			game_manager.decrease_health()
			if (x_delta > 0):
				body.jump_slide(500)
			else:
				body.jump_slide(-500)
