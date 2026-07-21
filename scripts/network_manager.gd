extends Node

signal server_started
signal client_connected
signal client_connection_failed(error_message: String)

const DEFAULT_IP_ADDRESS: String = "localhost"
const PORT = 56767

var peer: ENetMultiplayerPeer

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	server_started.emit()

func start_client(address: String = DEFAULT_IP_ADDRESS) -> void:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, PORT)
	if error != OK:
		peer = null
		var error_message := "Can't connect to host."
		GameState.error(error_message)
		client_connection_failed.emit(error_message)
		return
	multiplayer.multiplayer_peer = peer

func _on_connected_to_server() -> void:
	client_connected.emit()

func _on_connection_failed() -> void:
	peer = null
	multiplayer.multiplayer_peer = null
	var error_message := "Can't connect to host."
	GameState.error(error_message)
	client_connection_failed.emit(error_message)

func _on_server_disconnected() -> void:
	GameState.error("Lost connection to host.")
	peer = null
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()
