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
@onready var ray_cast_2d: RayCast2D = $RayCast2D

var offset = 0.0

var spin_dash_release_timer = 0

var spin_dash_released = false 

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
		spin_dash_release_timer = 60
		spin_dash_released = true 
		
func is_spin_dashing():
	return sonic_sprite.animation == "spin_dash_release" or sonic_sprite.animation == "spin_dash_charge"
	
func adjust_ray_cast():
	if is_on_floor() and ray_cast_2d.get_collision_normal().y < 1:
		ray_cast_2d.target_position.y = 200.0
	else:
		ray_cast_2d.target_position.y = 10.0

	
func _physics_process(delta: float) -> void:
	var current_animation = sonic_sprite.animation
	var ground_normal = ray_cast_2d.get_collision_normal()
	var ground_angle = fmod(720 - rad_to_deg(atan2(ground_normal.x, -ground_normal.y)), 360)

	
	if ray_cast_2d.is_colliding():
		$AnimatedSprite2D.rotation = -deg_to_rad(ground_angle)
		$CollisionShape2D_idle.rotation = -deg_to_rad(ground_angle)
		if ground_angle > 180 and ground_angle < 360:
			velocity.y += 200 
	else:
		$AnimatedSprite2D.rotation = 0
		$CollisionShape2D_idle.rotation = 0

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
		if not is_on_floor(): # slope stuff
			if ground_angle > 180 and ground_angle < 360:
				if jumpy:
					print("made it")
					velocity += get_gravity() * delta
					sonic_sprite.animation = "jump"
				else: 
					# Change Velocity based on slope
					var slope_radians = deg_to_rad(ground_angle - 270)
					var slope_speed = velocity.length()
					
					var new_velocity_y = slope_speed * sin(slope_radians)
					var new_velocity_x = slope_speed * cos(slope_radians)
					
					velocity.x = lerp(velocity.x, new_velocity_x, 0.1)
					velocity.y = lerp(velocity.y, new_velocity_y, 2)
					
					velocity.x += 50 * delta * sign(velocity.x)
					velocity.y += 50 * delta
					
					velocity.y = clamp(velocity.y, -top_speed, top_speed)
					
					sonic_sprite.position.y = -20

				if (velocity.x >1 || velocity.x < -1):
					if abs(velocity.x) > 600:
						sonic_sprite.animation = "sprinting"
					else:
						sonic_sprite.animation = "running"
				else:
					sonic_sprite.animation = "idle"
			else:
				sonic_sprite.position.y = 0
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
	if spin_dash_release_timer > 0:
		spin_dash_release_timer -= 1
		if spin_dash_release_timer <= 0:
			sonic_sprite.animation = "running"
			spin_dash_released = false

	move_and_slide()
