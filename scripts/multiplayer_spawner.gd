extends MultiplayerSpawner

@export var network_player: PackedScene

var pending_spawn_ids: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(despawn_player)
	NetworkManager.server_started.connect(spawn_host)
	
func spawn_player(id: int) -> void:
	if !multiplayer.is_server(): return

	var root := get_node_or_null(spawn_path)
	if root == null:
		return

	var player_name := str(id)
	if root.get_node_or_null(NodePath(player_name)) != null or pending_spawn_ids.has(id):
		return

	pending_spawn_ids[id] = true
	
	var player: Node = network_player.instantiate()
	player.name = player_name
	call_deferred("_add_player", root, player, id)

func _add_player(root: Node, player: Node, id: int) -> void:
	if !is_instance_valid(root):
		pending_spawn_ids.erase(id)
		return

	if root.get_node_or_null(NodePath(str(player.name))) != null:
		pending_spawn_ids.erase(id)
		player.queue_free()
		return
	
	root.add_child(player)
	pending_spawn_ids.erase(id)

func despawn_player(id: int) -> void:
	pending_spawn_ids.erase(id)

	var root := get_node_or_null(spawn_path)
	if root == null:
		return

	var player := root.get_node_or_null(str(id))
	if player != null:
		player.queue_free()

func spawn_host() -> void:
	spawn_player(1)
