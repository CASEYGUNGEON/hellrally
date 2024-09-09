extends RigidBody3D

var tire_facing = 0.0
var accel_input = 0.0
var turn_input = 0.0
var frame_gravity = 0.0
var on_ground = true
var brake_input = 0.0
@export var max_accel = 75.0
@export var max_speed = 20.0
@export var turn_coefficient = 0.35
@export var friction = 0.01
@export var skid_friction_mult = 3
@export var angular_friction = 0.015
@export var gravity = -30
@export var ground_distance = 0.3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	accel_input = (int(Input.is_action_pressed("Forward")) + int(Input.is_action_pressed("Backward")) * -1) * max_accel * delta
	if(accel_input < 0):
		accel_input *= 0.75
	turn_input = (int(Input.is_action_pressed("Left")) + int(Input.is_action_pressed("Right")) * -1) * turn_coefficient * delta
	brake_input = max(int(Input.is_action_pressed("Brake")), int(Input.is_action_pressed("Handbrake"))*2)
	var space_state = get_world_3d().direct_space_state
	var raycast_target = global_position + Vector3(0, -100, 0)
	var query = PhysicsRayQueryParameters3D.create(global_position, raycast_target)
	query.exclude = [self]
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	on_ground = true
	if !result:
		return
	var collision_point = result["position"]
	var collision_distance = global_position.distance_to(collision_point)
	if(collision_distance > ground_distance):
		on_ground = false
		frame_gravity = gravity * delta

func _integrate_forces(state):
	if(on_ground):
		var forward_force = accel_input * 0.5
		tire_facing = clamp(tire_facing * 0.8 + turn_input, -0.05, 0.05)
		state.transform.basis = state.transform.basis.rotated(Vector3.UP,tire_facing)
		var temp_friction = friction * (1 + brake_input)
		if(abs(state.linear_velocity.normalized().signed_angle_to(state.transform.basis.get_euler(), Vector3.UP)) > 45):
			temp_friction *= skid_friction_mult
		state.linear_velocity.x = lerp(state.linear_velocity.x, 0.0, temp_friction)
		state.linear_velocity.z = lerp(state.linear_velocity.z, 0.0, temp_friction)
		state.linear_velocity += state.transform.basis.x * forward_force
		state.angular_velocity = lerp(state.angular_velocity, Vector3.ZERO, angular_friction)
	else:
		state.linear_velocity.y += frame_gravity
