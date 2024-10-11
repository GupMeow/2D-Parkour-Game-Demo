extends Area2D
@onready var game_manager: Node = %GameManager
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "CharacterBody2D":
		queue_free()
		game_manager.add_ring()
