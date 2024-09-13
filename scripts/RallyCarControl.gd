extends RigidBody3D

var tire_facing = 0.0
var accel_input = 0.0
var turn_input = 0.0
var frame_gravity = 0.0
var on_ground = true
var brake_input = false
var handbrake_input = false
@export var max_accel = 75.0
@export var max_speed = 20.0
@export var turn_coefficient = 0.35
@export var friction = 0.01
@export var skid_friction_mult = 0.5
@export var brake_friction_mult = 10
@export var angular_friction = 0.015
@export var gravity = -30
@export var ground_distance = 0.3

var audio_node
var peelout_sound1 = preload("res://audio/peel out 1.wav")
var peelout_sound2 = preload("res://audio/peel out 2.wav")
var peelout_sound3 = preload("res://audio/peel out 2.wav")
var skid_audio_state = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	audio_node = $AudioStreamPlayer3D
	pass # Replace with function body.

func _physics_process(delta):
	# Get inputs
	accel_input = (int(Input.is_action_pressed("Forward")) + int(Input.is_action_pressed("Backward")) * -1) * max_accel * delta
	if(accel_input < 0):
		accel_input *= 0.75
	turn_input = (int(Input.is_action_pressed("Left")) + int(Input.is_action_pressed("Right")) * -1) * turn_coefficient * delta
	brake_input = int(Input.is_action_pressed("Brake")) * brake_friction_mult * delta
	handbrake_input = int(Input.is_action_pressed(("Handbrake")))
	
	# Get distance from ground below
	var space_state = get_world_3d().direct_space_state
	var raycast_target = global_position + Vector3(0, -100, 0)
	var query = PhysicsRayQueryParameters3D.create(global_position, raycast_target)
	query.exclude = [self]
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	on_ground = true
	# No ground?
	if !result:
		return
	var collision_point = result["position"]
	var collision_distance = global_position.distance_to(collision_point)
	# If we're off the ground, apply gravity.
	if(collision_distance > ground_distance):
		on_ground = false
		frame_gravity = gravity * delta

func _integrate_forces(state):
	# Apply car physics only if we're grounded.
	if(on_ground):
		# Calculate forces based on inputs
		var forward_force = accel_input * 0.5
		tire_facing = clamp(tire_facing * 0.8 + turn_input, -0.05, 0.05)
		state.transform.basis = state.transform.basis.rotated(Vector3.UP,tire_facing)
		var temp_friction = friction * (1 + brake_input)
		# Skid if we're moving quickly enough and we're either not moving where we're pointed or we're handbraking.
		var move_angle_vs_facing = rad_to_deg(abs(state.linear_velocity.normalized().signed_angle_to(state.transform.basis.x, Vector3.UP)))
		print(move_angle_vs_facing)
		if(handbrake_input || (move_angle_vs_facing > 40 && move_angle_vs_facing < 140)):
			temp_friction *= skid_friction_mult
			if !audio_node.is_playing() || skid_audio_state == 0:
				audio_node.volume_db = 1 / (state.linear_velocity.length() / max_speed) * -5 - 10
				if(skid_audio_state == 0):
					audio_node.stream = peelout_sound1
					skid_audio_state = 1
				else:
					audio_node.stream = peelout_sound2
				audio_node.play()
		else:
			if(skid_audio_state > 0):
				skid_audio_state = 0
				audio_node.volume_db = 1 / (state.linear_velocity.length() / max_speed) * -5 - 10
				audio_node.stream = peelout_sound3
				audio_node.play()
		# Apply forces to the car.
		state.linear_velocity.x = lerp(state.linear_velocity.x, 0.0, temp_friction)
		state.linear_velocity.z = lerp(state.linear_velocity.z, 0.0, temp_friction)
		state.linear_velocity += state.transform.basis.x * forward_force
		state.angular_velocity = lerp(state.angular_velocity, Vector3.ZERO, angular_friction)
	# If we're not grounded, just do gravity.
	else:
		state.linear_velocity.y += frame_gravity
