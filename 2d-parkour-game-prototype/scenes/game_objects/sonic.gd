extends CharacterBody2D

const SPEED = 500.0
const acceleration = 20
const deceleration = 50
const JUMP_VELOCITY = -600.0
const MAX_JUMP_VELOCITY = -800.0
const JUMP_HOLD_TIME = 0.3
const top_speed = 2500
const skid_deceleration = 60
const roll_deceleration = 10
@onready var sonic_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_idle: CollisionShape2D = $CollisionShape2D_idle
@onready var collision_run: CollisionShape2D = $CollisionShape2D_run
@onready var collision_jump: CollisionShape2D = $CollisionShape2D_jump
@onready var collision_spin_dash_release: CollisionShape2D = $CollisionShape2D_spindash_release
@onready var path_2d: Path2D = $"../Path/Path2D"

var offset = 0.0


var is_spindashing = false
var spin_charge = 1000 # add a base velocity so that one charge isnt underwhelming
var last_direction = 1
var jump_time = 0.0
var jump_pressed = false

func jump():
	velocity.y = JUMP_VELOCITY

func jump_slide(x):
	velocity.y = JUMP_VELOCITY
	velocity.x = x
	
func enable_collision(active_collision): #doesnt work rn
	collision_idle.set_deferred("disabled", true)
	active_collision.set_deferred("disabled", false)
	
func release_spin_dash():
	if spin_charge > 0:	
		velocity.x += spin_charge * last_direction 
		velocity.x = clamp(velocity.x, -top_speed, top_speed)
		spin_charge = 1000
		
func is_spin_dashing():
	return sonic_sprite.animation == "spin_dash_release" or sonic_sprite.animation == "spin_dash_charge"

	
func _physics_process(delta: float) -> void:
	var current_animation = sonic_sprite.animation

#
	collision_run.set_deferred("disabled", true)
	collision_jump.set_deferred("disabled", true)
	collision_spin_dash_release.set_deferred("disabled", true)
	#
	var delta_time = 60 * delta
	var input_horizontal = (1 if Input.is_action_pressed("right") else 0) - (1 if Input.is_action_pressed("left") else 0)
	var input_down = (1 if Input.is_action_pressed("crouch") else 0)
	var jumpy = Input.is_action_just_pressed("jump")
	
	if input_horizontal < 0: # telling the game which way sonic should be facing when idle
		last_direction = -1
	elif input_horizontal >0:
		last_direction = 1
	sonic_sprite.flip_h = (last_direction == -1)
	
	if input_down == 1 and is_on_floor(): # Crouch and spindash logic
		if jumpy:
			is_spindashing = true
			sonic_sprite.animation = "spin_dash_charge"
			spin_charge += 1000
		elif is_spindashing:		
			sonic_sprite.animation = "spin_dash_charge"
		elif velocity.x >1 || velocity.x < -1:
			sonic_sprite.animation = "spin_dash_release"
			velocity.x -= roll_deceleration * delta_time * last_direction
		elif velocity.x < -1:
			velocity.x += roll_deceleration * delta_time * last_direction
		else:
			sonic_sprite.animation = "crouching"
	elif spin_charge > 1000:
		is_spindashing = false
		sonic_sprite.animation = "spin_dash_release"
		release_spin_dash()
	else: # All movement when not crouching
		is_spindashing = false
		if not is_on_floor(): # Add the gravity.
			velocity += get_gravity() * delta
			sonic_sprite.animation = "jump"
		elif (velocity.x >1 || velocity.x < -1):
			if abs(velocity.x) > 600:
				sonic_sprite.animation = "sprinting"
			else:
				sonic_sprite.animation = "running"
		else:
			sonic_sprite.animation = "idle"
	
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			jump_pressed = true
			jump_time = 0.0
			velocity.y = JUMP_VELOCITY
		if jump_pressed:	
			jump_time += delta
			if jump_time < JUMP_HOLD_TIME and Input.is_action_pressed("jump"):
				velocity.y = lerp(JUMP_VELOCITY, MAX_JUMP_VELOCITY, jump_time / JUMP_HOLD_TIME)
			else:
				jump_pressed = false
		else:
			if Input.is_action_just_released("jump"):
				jump_pressed = false
				
		# Handle ground movement
		if input_horizontal < 0: # moving left
			if velocity.x > 400:
				sonic_sprite.animation = "skid"
				sonic_sprite.flip_h = false
				velocity.x -= skid_deceleration * delta_time
			elif velocity.x > 0: # decelerating from moving right
				velocity.x -= deceleration * delta_time
				if velocity.x <= 0:
					velocity.x = 0
			elif velocity.x > - top_speed: # accelerating left
				velocity.x -= acceleration * delta_time
				if velocity.x <= -top_speed:
					velocity.x = -top_speed
		elif input_horizontal > 0: # moving right
			if velocity.x < -400:
				sonic_sprite.animation = "skid"
				sonic_sprite.flip_h = true
				velocity.x += skid_deceleration * delta_time
			elif velocity.x < 0: # decelerating from moving left
				velocity.x += deceleration * delta_time
				if velocity.x >= 0:
					velocity.x = 0
			elif velocity.x < top_speed:
				velocity.x += acceleration * delta_time
				if velocity.x >= top_speed:
					velocity.x = top_speed
		elif velocity.x != 0: # Apply friction on no input
			if velocity.x > 0: # moving right
				velocity.x -= deceleration * delta_time
				if velocity.x < 0: # stop decelerating when reaching 0
					velocity.x = 0
			if velocity.x < 0: # moving left
				velocity.x += deceleration * delta_time
				if velocity.x > 0:
					velocity.x = 0

	move_and_slide()
