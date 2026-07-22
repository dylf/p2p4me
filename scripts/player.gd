extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const WALK_ANIMATION: StringName = &"Walk"
const MEEPLE_COLORS: Array[Color] = [
	Color("#ef4444"),
	Color("#f59e0b"),
	Color("#eab308"),
	Color("#22c55e"),
	Color("#06b6d4"),
	Color("#3b82f6"),
	Color("#8b5cf6"),
	Color("#ec4899"),
]

@onready var animation_player: AnimationPlayer = $Meeple/AnimationPlayer
@onready var footstep_player: AudioStreamPlayer3D = $FootstepAudio
@onready var jump_audio_player: AudioStreamPlayer3D = $JumpAudio

@export var camera: Camera3D

@export var is_walking: bool = false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	_apply_meeple_color()

	if footstep_player != null:
		footstep_player.finished.connect(_on_footstep_audio_finished)

	if is_multiplayer_authority():
		camera.current = true
		is_walking = false

func _apply_meeple_color() -> void:
	var peer_id := name.to_int()
	if peer_id <= 0:
		return

	var color := MEEPLE_COLORS[peer_id % MEEPLE_COLORS.size()]
	for mesh_instance in $Meeple.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_instance as MeshInstance3D
		var base_material := mesh.material_override
		if base_material == null and mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
			base_material = mesh.mesh.surface_get_material(0)

		var material := (base_material.duplicate() if base_material != null else StandardMaterial3D.new()) as BaseMaterial3D
		material.albedo_color = color
		mesh.material_override = material

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority() and !GameState.is_menu() and !GameState.is_error():
		var jump_started := false

		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			jump_started = true
			velocity.y = JUMP_VELOCITY
			if jump_audio_player != null:
				jump_audio_player.play()

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		_set_walking_state(input_dir != Vector2.ZERO and is_on_floor() and !jump_started)
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			if velocity.length_squared() >= 0.1:
				var look_position := global_position + Vector3(velocity.x, 0, velocity.z)
				var current_rotation = $Meeple.global_transform.basis.get_rotation_quaternion()
				$Meeple.look_at(look_position, Vector3.UP) 
				var target_rotation = $Meeple.global_transform.basis.get_rotation_quaternion()

				var smoothed_rotation = current_rotation.slerp(target_rotation, 10.0 * delta)
				$Meeple.global_transform.basis = Basis(smoothed_rotation)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

		move_and_slide()
	elif GameState.is_menu() or GameState.is_error():
		if is_multiplayer_authority():
			_set_walking_state(false)

	_update_walk_presentation()

func _set_walking_state(walking: bool) -> void:
	if is_walking == walking:
		return

	is_walking = walking
	if is_multiplayer_authority():
		_sync_walk_state.rpc(walking)

@rpc("authority", "call_remote", "unreliable")
func _sync_walk_state(walking: bool) -> void:
	is_walking = walking

func _on_footstep_audio_finished() -> void:
	if footstep_player != null and is_walking:
		footstep_player.play()


func _update_walk_presentation() -> void:
	var should_walk := is_walking and !GameState.is_menu() and !GameState.is_error()

	if should_walk:
		if !animation_player.is_playing() or animation_player.current_animation != WALK_ANIMATION:
			animation_player.play(WALK_ANIMATION)
		if footstep_player != null and !footstep_player.playing:
			footstep_player.play()
	else:
		if animation_player.is_playing():
			animation_player.stop()
		if footstep_player != null and footstep_player.playing:
			footstep_player.stop()
