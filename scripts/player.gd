extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var camera: Camera3D

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	if GameState.in_menu: return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if velocity.length_squared() >= 0.1:
			var look_position := global_position + Vector3(velocity.x, 0, velocity.z)
			var current_rotation = $Model.global_transform.basis.get_rotation_quaternion()
			$Model.look_at(look_position, Vector3.UP) 
			var target_rotation = $Model.global_transform.basis.get_rotation_quaternion()

			var smoothed_rotation = current_rotation.slerp(target_rotation, 10.0 * delta)
			$Model.global_transform.basis = Basis(smoothed_rotation)
			#$Model.look_at(look_position, Vector3.UP) 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
