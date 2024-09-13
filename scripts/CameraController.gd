extends Camera3D

@export var custom_offset := Vector3(-15.0, 8.0, 0.0)
@export var follow_distance = 20
@export var rotation_speed = 0.1
@export var car_object: RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	#global_position = car_object.global_position + custom_offset
	#look_at(car_object.global_position)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var target_position = car_object.global_position + (Vector3(0.0, -0.5, 0.0) + car_object.transform.basis.x) * -follow_distance
	target_position.y = car_object.global_position.y + 8
	global_position = lerp(global_position, target_position, rotation_speed)
	look_at(car_object.global_position)
	pass
